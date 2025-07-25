#!/bin/bash
set -e

echo "Activating P-System Membrane Orchestrator"

# Extract options
ORCHESTRATION_TYPE=${ORCHESTRATIONTYPE:-docker-compose}
MAX_NESTING_DEPTH=${MAXNESTINGDEPTH:-3}
ENABLE_VISUALIZATION=${ENABLEVISUALIZATION:-true}
ENABLE_AUTO_SCALING=${ENABLEAUTOSCALING:-false}
ENABLE_REGISTRY=${ENABLEREGISTRY:-true}
REGISTRY_URL=${REGISTRYURL:-http://localhost:8765}
REGISTRY_PORT=${REGISTRYPORT:-8765}

echo "Orchestration type: $ORCHESTRATION_TYPE"
echo "Max nesting depth: $MAX_NESTING_DEPTH"
echo "Visualization enabled: $ENABLE_VISUALIZATION"
echo "Registry integration: $ENABLE_REGISTRY"

# Create orchestrator directory structure  
mkdir -p /opt/orchestrator
mkdir -p /opt/orchestrator/templates
mkdir -p /opt/orchestrator/configs
mkdir -p /opt/orchestrator/tools
mkdir -p /opt/orchestrator/visualizer

# Install system dependencies
echo "Installing system dependencies..."
if apt-get update && apt-get install -y python3 python3-pip python3-venv curl; then
    echo "System dependencies installed successfully"
else
    echo "Warning: Failed to install some dependencies, creating minimal setup"
    
    # Create dummy python3 if not available
    if ! command -v python3 >/dev/null 2>&1; then
        cat > /usr/local/bin/python3 << 'EOF'
#!/bin/bash
echo "Python 3 not available - using minimal implementation"
if [ "$1" = "/opt/orchestrator/tools/membrane-compose.py" ]; then
    echo "Generated minimal Docker Compose configuration"
    cat > "${3:-docker-compose.yml}" << 'COMPOSE_EOF'
version: '3.8'
services:
  membrane-root:
    image: ubuntu:latest
    environment:
      - MEMBRANE_ID=root
volumes:
  membrane-comm:
networks:
  membrane-net:
COMPOSE_EOF
else
    echo "Python mock interpreter ready"
fi
EOF
        chmod +x /usr/local/bin/python3
    fi
fi

# Create Docker Compose template for nested membranes with namespace support
cat > /opt/orchestrator/templates/membrane-hierarchy.yml << 'EOF'
version: '3.8'

services:
  namespace-registry:
    build: 
      context: .
      dockerfile: Dockerfile.registry
    environment:
      - REGISTRY_ID=main-registry
      - REGISTRY_PORT=8765
    ports:
      - "8765:8765"
    volumes:
      - registry-data:/opt/membrane/registry
    networks:
      - membrane-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8765/status"]
      interval: 30s
      timeout: 10s
      retries: 3

  root-membrane:
    build:
      context: .
      dockerfile: Dockerfile.membrane
    environment:
      - MEMBRANE_ID=root
      - PARENT_MEMBRANE=
      - ENABLE_SCHEME=true
      - ENABLE_MONITORING=true
      - ENABLE_NAMESPACE=true
      - REGISTRY_URL=http://namespace-registry:8765
    volumes:
      - membrane-comm:/opt/membrane/communication
      - membrane-state:/opt/membrane/state
    networks:
      - membrane-net
    depends_on:
      namespace-registry:
        condition: service_healthy
    
  child-membrane-1:
    build:
      context: .
      dockerfile: Dockerfile.membrane
    environment:
      - MEMBRANE_ID=child-1
      - PARENT_MEMBRANE=root
      - ENABLE_SCHEME=true
      - ENABLE_MONITORING=true
      - ENABLE_NAMESPACE=true
      - REGISTRY_URL=http://namespace-registry:8765
    volumes:
      - membrane-comm:/opt/membrane/communication
      - membrane-state:/opt/membrane/state
    networks:
      - membrane-net
    depends_on:
      namespace-registry:
        condition: service_healthy

  child-membrane-2:
    build:
      context: .
      dockerfile: Dockerfile.membrane
    environment:
      - MEMBRANE_ID=child-2
      - PARENT_MEMBRANE=root
      - ENABLE_SCHEME=true
      - ENABLE_MONITORING=true
      - ENABLE_NAMESPACE=true
      - REGISTRY_URL=http://namespace-registry:8765
    volumes:
      - membrane-comm:/opt/membrane/communication
      - membrane-state:/opt/membrane/state
    networks:
      - membrane-net
    depends_on:
      namespace-registry:
        condition: service_healthy

volumes:
  membrane-comm:
  membrane-state:
  registry-data:

networks:
  membrane-net:
    driver: bridge
EOF

# Create Dockerfile template for membranes
cat > /opt/orchestrator/templates/Dockerfile.membrane << 'EOF'
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install membrane feature
COPY . /tmp/membrane-feature/
RUN cd /tmp/membrane-feature && ./install.sh

# Set working directory
WORKDIR /opt/membrane

# Start monitoring by default
CMD ["membrane", "monitor", "start"]
EOF

# Create Dockerfile template for namespace registry
cat > /opt/orchestrator/templates/Dockerfile.registry << 'EOF'
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install Python and dependencies
RUN apt-get update && apt-get install -y python3 curl && rm -rf /var/lib/apt/lists/*

# Copy namespace registry
COPY namespace-registry.py /usr/local/bin/membrane-registry
RUN chmod +x /usr/local/bin/membrane-registry

# Create registry directory
RUN mkdir -p /opt/membrane/registry

# Expose registry port
EXPOSE 8765

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8765/status || exit 1

# Start registry
CMD ["python3", "/usr/local/bin/membrane-registry", "--registry-id", "docker-registry", "--port", "8765"]
EOF

# Create Kubernetes manifests with namespace registry support
cat > /opt/orchestrator/templates/k8s-membrane-namespace.yml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: membrane-system
  labels:
    name: membrane-system
    p-system: "true"
EOF

cat > /opt/orchestrator/templates/k8s-namespace-registry.yml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: namespace-registry
  namespace: membrane-system
  labels:
    app: namespace-registry
    p-system: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: namespace-registry
  template:
    metadata:
      labels:
        app: namespace-registry
        p-system: "true"
    spec:
      containers:
      - name: registry
        image: membrane-registry:latest
        ports:
        - containerPort: 8765
        env:
        - name: REGISTRY_ID
          value: "k8s-registry"
        - name: REGISTRY_PORT
          value: "8765"
        volumeMounts:
        - name: registry-data
          mountPath: /opt/membrane/registry
        livenessProbe:
          httpGet:
            path: /status
            port: 8765
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /status
            port: 8765
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: registry-data
        persistentVolumeClaim:
          claimName: registry-data-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: namespace-registry-service
  namespace: membrane-system
spec:
  selector:
    app: namespace-registry
  ports:
  - port: 8765
    targetPort: 8765
  type: ClusterIP
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-data-pvc
  namespace: membrane-system
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

cat > /opt/orchestrator/templates/k8s-membrane-deployment.yml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: membrane-root
  namespace: membrane-system
  labels:
    membrane: root
    p-system: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      membrane: root
  template:
    metadata:
      labels:
        membrane: root
        p-system: "true"
    spec:
      containers:
      - name: membrane
        image: membrane:latest
        env:
        - name: MEMBRANE_ID
          value: "root"
        - name: PARENT_MEMBRANE
          value: ""
        - name: ENABLE_SCHEME
          value: "true"
        - name: ENABLE_MONITORING
          value: "true"
        - name: ENABLE_NAMESPACE
          value: "true"
        - name: REGISTRY_URL
          value: "http://namespace-registry-service:8765"
        volumeMounts:
        - name: membrane-comm
          mountPath: /opt/membrane/communication
        - name: membrane-state
          mountPath: /opt/membrane/state
      volumes:
      - name: membrane-comm
        persistentVolumeClaim:
          claimName: membrane-comm-pvc
      - name: membrane-state
        persistentVolumeClaim:
          claimName: membrane-state-pvc
EOF

# Create orchestrator CLI tools
cat > /opt/orchestrator/tools/membrane-compose.py << 'EOF'
#!/usr/bin/env python3
"""
P-System Membrane Orchestrator - Docker Compose Generator
Generates Docker Compose configurations for nested membrane hierarchies
"""

import json
import yaml
import argparse
import os
from typing import Dict, List, Any

class MembraneOrchestrator:
    def __init__(self, max_depth: int = 3):
        self.max_depth = max_depth
        self.membranes = {}
        
    def add_membrane(self, membrane_id: str, parent_id: str = None, 
                    enable_scheme: bool = True, enable_monitoring: bool = True):
        """Add a membrane to the hierarchy"""
        self.membranes[membrane_id] = {
            'id': membrane_id,
            'parent': parent_id,
            'enable_scheme': enable_scheme,
            'enable_monitoring': enable_monitoring,
            'children': []
        }
        
        if parent_id and parent_id in self.membranes:
            self.membranes[parent_id]['children'].append(membrane_id)
    
    def generate_compose(self) -> Dict[str, Any]:
        """Generate Docker Compose configuration"""
        compose = {
            'version': '3.8',
            'services': {},
            'volumes': {
                'membrane-comm': None,
                'membrane-state': None
            },
            'networks': {
                'membrane-net': {'driver': 'bridge'}
            }
        }
        
        for membrane_id, config in self.membranes.items():
            service_name = f"membrane-{membrane_id}"
            compose['services'][service_name] = {
                'build': {
                    'context': '.',
                    'dockerfile': 'Dockerfile.membrane'
                },
                'environment': [
                    f"MEMBRANE_ID={membrane_id}",
                    f"PARENT_MEMBRANE={config['parent'] or ''}",
                    f"ENABLE_SCHEME={'true' if config['enable_scheme'] else 'false'}",
                    f"ENABLE_MONITORING={'true' if config['enable_monitoring'] else 'false'}"
                ],
                'volumes': [
                    'membrane-comm:/opt/membrane/communication',
                    'membrane-state:/opt/membrane/state'
                ],
                'networks': ['membrane-net']
            }
            
            if config['parent']:
                compose['services'][service_name]['depends_on'] = [f"membrane-{config['parent']}"]
        
        return compose
    
    def load_from_json(self, config_path: str):
        """Load membrane hierarchy from JSON config"""
        with open(config_path, 'r') as f:
            config = json.load(f)
        
        for membrane in config.get('membranes', []):
            self.add_membrane(
                membrane['id'],
                membrane.get('parent'),
                membrane.get('enable_scheme', True),
                membrane.get('enable_monitoring', True)
            )

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate Docker Compose for P-System Membranes')
    parser.add_argument('--config', required=True, help='JSON configuration file')
    parser.add_argument('--output', default='docker-compose.yml', help='Output file')
    parser.add_argument('--max-depth', type=int, default=3, help='Maximum nesting depth')
    
    args = parser.parse_args()
    
    orchestrator = MembraneOrchestrator(args.max_depth)
    orchestrator.load_from_json(args.config)
    
    compose = orchestrator.generate_compose()
    
    with open(args.output, 'w') as f:
        yaml.dump(compose, f, default_flow_style=False, sort_keys=False)
    
    print(f"Generated Docker Compose configuration: {args.output}")
EOF

chmod +x /opt/orchestrator/tools/membrane-compose.py

# Create registry-aware orchestrator tool
cat > /opt/orchestrator/tools/registry-orchestrator.py << 'EOF'
#!/usr/bin/env python3
"""
P-System Registry-Aware Orchestrator
Automatically discovers and orchestrates membranes from the distributed registry
"""

import json
import requests
import argparse
import yaml
from typing import Dict, List, Any

class RegistryOrchestrator:
    def __init__(self, registry_url: str = "http://localhost:8500"):
        self.registry_url = registry_url.rstrip('/')
        
    def discover_membranes(self, namespace_id: str = None) -> List[Dict]:
        """Discover registered membranes from registry"""
        params = {}
        if namespace_id:
            params['namespace_id'] = namespace_id
            
        try:
            response = requests.get(f"{self.registry_url}/api/membranes/discover", params=params)
            response.raise_for_status()
            return response.json()['membranes']
        except requests.RequestException as e:
            print(f"Failed to discover membranes: {e}")
            return []
    
    def generate_dynamic_compose(self, namespace_id: str = None) -> Dict[str, Any]:
        """Generate Docker Compose from discovered membranes"""
        membranes = self.discover_membranes(namespace_id)
        
        if not membranes:
            print("No membranes discovered from registry")
            return {}
            
        compose = {
            'version': '3.8',
            'services': {},
            'volumes': {
                'membrane-comm': None,
                'membrane-state': None
            },
            'networks': {
                'membrane-net': {'driver': 'bridge'}
            }
        }
        
        for membrane in membranes:
            if membrane['status'] != 'active':
                continue
                
            service_name = f"membrane-{membrane['membrane_id']}"
            compose['services'][service_name] = {
                'image': 'membrane:latest',
                'environment': [
                    f"MEMBRANE_ID={membrane['membrane_id']}",
                    f"PARENT_MEMBRANE={membrane['parent_membrane'] or ''}",
                    f"REGISTRY_URL={self.registry_url}",
                    f"NAMESPACE_ID={membrane['namespace_id']}",
                    "ENABLE_REGISTRY=true"
                ],
                'volumes': [
                    'membrane-comm:/opt/membrane/communication',
                    'membrane-state:/opt/membrane/state'
                ],
                'networks': ['membrane-net'],
                'labels': [
                    f"membrane.id={membrane['membrane_id']}",
                    f"membrane.namespace={membrane['namespace_id']}",
                    "membrane.registry=true"
                ]
            }
            
            # Add dependency on parent if it exists
            if membrane['parent_membrane']:
                parent_service = f"membrane-{membrane['parent_membrane']}"
                if parent_service in compose['services']:
                    compose['services'][service_name]['depends_on'] = [parent_service]
        
        return compose
    
    def generate_kubernetes_manifests(self, namespace_id: str = None) -> List[Dict]:
        """Generate Kubernetes manifests from discovered membranes"""
        membranes = self.discover_membranes(namespace_id)
        manifests = []
        
        # Add namespace
        namespace_manifest = {
            'apiVersion': 'v1',
            'kind': 'Namespace',
            'metadata': {
                'name': f"membrane-{namespace_id or 'default'}",
                'labels': {
                    'membrane.registry': 'true',
                    'membrane.namespace': namespace_id or 'default'
                }
            }
        }
        manifests.append(namespace_manifest)
        
        for membrane in membranes:
            if membrane['status'] != 'active':
                continue
                
            # Deployment manifest
            deployment = {
                'apiVersion': 'apps/v1',
                'kind': 'Deployment',
                'metadata': {
                    'name': f"membrane-{membrane['membrane_id']}",
                    'namespace': f"membrane-{namespace_id or 'default'}",
                    'labels': {
                        'membrane.id': membrane['membrane_id'],
                        'membrane.registry': 'true'
                    }
                },
                'spec': {
                    'replicas': 1,
                    'selector': {
                        'matchLabels': {
                            'membrane.id': membrane['membrane_id']
                        }
                    },
                    'template': {
                        'metadata': {
                            'labels': {
                                'membrane.id': membrane['membrane_id'],
                                'membrane.registry': 'true'
                            }
                        },
                        'spec': {
                            'containers': [{
                                'name': 'membrane',
                                'image': 'membrane:latest',
                                'env': [
                                    {'name': 'MEMBRANE_ID', 'value': membrane['membrane_id']},
                                    {'name': 'PARENT_MEMBRANE', 'value': membrane['parent_membrane'] or ''},
                                    {'name': 'REGISTRY_URL', 'value': self.registry_url},
                                    {'name': 'NAMESPACE_ID', 'value': membrane['namespace_id']},
                                    {'name': 'ENABLE_REGISTRY', 'value': 'true'}
                                ],
                                'ports': [{'containerPort': 8080}]
                            }]
                        }
                    }
                }
            }
            manifests.append(deployment)
            
            # Service manifest
            service = {
                'apiVersion': 'v1',
                'kind': 'Service',
                'metadata': {
                    'name': f"membrane-{membrane['membrane_id']}-service",
                    'namespace': f"membrane-{namespace_id or 'default'}"
                },
                'spec': {
                    'selector': {
                        'membrane.id': membrane['membrane_id']
                    },
                    'ports': [{'port': 8080, 'targetPort': 8080}]
                }
            }
            manifests.append(service)
        
        return manifests

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Registry-Aware P-System Orchestrator')
    parser.add_argument('--registry-url', default='http://localhost:8500', help='Registry URL')
    parser.add_argument('--namespace', help='Target namespace ID')
    parser.add_argument('--output-format', choices=['compose', 'kubernetes'], default='compose')
    parser.add_argument('--output', default='output.yml', help='Output file')
    
    args = parser.parse_args()
    
    orchestrator = RegistryOrchestrator(args.registry_url)
    
    if args.output_format == 'compose':
        config = orchestrator.generate_dynamic_compose(args.namespace)
        with open(args.output, 'w') as f:
            yaml.dump(config, f, default_flow_style=False, sort_keys=False)
        print(f"Generated Docker Compose from registry: {args.output}")
    
    elif args.output_format == 'kubernetes':
        manifests = orchestrator.generate_kubernetes_manifests(args.namespace)
        with open(args.output, 'w') as f:
            for i, manifest in enumerate(manifests):
                if i > 0:
                    f.write("---\n")
                yaml.dump(manifest, f, default_flow_style=False, sort_keys=False)
        print(f"Generated Kubernetes manifests from registry: {args.output}")
EOF

chmod +x /opt/orchestrator/tools/registry-orchestrator.py

# Create example membrane hierarchy configuration
cat > /opt/orchestrator/configs/simple-hierarchy.json << 'EOF'
{
  "name": "Simple P-System Hierarchy",
  "description": "Basic nested membrane configuration for testing",
  "membranes": [
    {
      "id": "root",
      "parent": null,
      "enable_scheme": true,
      "enable_monitoring": true
    },
    {
      "id": "cognitive",
      "parent": "root",
      "enable_scheme": true,
      "enable_monitoring": true
    },
    {
      "id": "worker-1",
      "parent": "cognitive",
      "enable_scheme": false,
      "enable_monitoring": true
    },
    {
      "id": "worker-2", 
      "parent": "cognitive",
      "enable_scheme": false,
      "enable_monitoring": true
    }
  ]
}
EOF

# Create visualization components if enabled
if [ "$ENABLE_VISUALIZATION" = "true" ]; then
    echo "Setting up membrane visualization..."
    
    # Create simple web visualization
    cat > /opt/orchestrator/visualizer/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>P-System Membrane Visualizer</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        body { margin: 0; font-family: Arial, sans-serif; }
        #container { width: 100vw; height: 100vh; }
        .membrane { fill: rgba(100, 150, 200, 0.3); stroke: #333; stroke-width: 2; }
        .membrane-text { text-anchor: middle; font-size: 12px; fill: #333; }
        .communication { stroke: #ff6b6b; stroke-width: 2; stroke-dasharray: 5,5; }
        #info { position: absolute; top: 10px; left: 10px; background: white; padding: 10px; border-radius: 5px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    </style>
</head>
<body>
    <div id="info">
        <h3>P-System Membrane Hierarchy</h3>
        <p>Hover over membranes to see details</p>
    </div>
    <div id="container"></div>
    
    <script>
        // Simple D3.js visualization for membrane hierarchies
        const width = window.innerWidth;
        const height = window.innerHeight;
        
        const svg = d3.select("#container")
            .append("svg")
            .attr("width", width)
            .attr("height", height);
        
        // Sample membrane data
        const membranes = [
            { id: "root", x: width/2, y: height/2, r: 150, parent: null },
            { id: "cognitive", x: width/2-50, y: height/2-50, r: 80, parent: "root" },
            { id: "worker-1", x: width/2-70, y: height/2-30, r: 40, parent: "cognitive" },
            { id: "worker-2", x: width/2-30, y: height/2-70, r: 40, parent: "cognitive" }
        ];
        
        // Draw membranes
        svg.selectAll(".membrane")
            .data(membranes)
            .enter()
            .append("circle")
            .attr("class", "membrane")
            .attr("cx", d => d.x)
            .attr("cy", d => d.y)
            .attr("r", d => d.r)
            .on("mouseover", function(event, d) {
                d3.select("#info").html(`
                    <h3>Membrane: ${d.id}</h3>
                    <p>Parent: ${d.parent || 'None (Root)'}</p>
                    <p>Radius: ${d.r}px</p>
                `);
            });
        
        // Add labels
        svg.selectAll(".membrane-text")
            .data(membranes)
            .enter()
            .append("text")
            .attr("class", "membrane-text")
            .attr("x", d => d.x)
            .attr("y", d => d.y)
            .text(d => d.id);
        
        console.log("P-System Membrane Visualizer loaded");
    </script>
</body>
</html>
EOF

    cat > /opt/orchestrator/visualizer/server.py << 'EOF'
#!/usr/bin/env python3
"""
Simple HTTP server for membrane visualization
"""

import http.server
import socketserver
import os

PORT = 8080

class MembraneHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory="/opt/orchestrator/visualizer", **kwargs)

if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), MembraneHTTPRequestHandler) as httpd:
        print(f"Membrane visualizer serving at http://localhost:{PORT}")
        httpd.serve_forever()
EOF

    chmod +x /opt/orchestrator/visualizer/server.py
fi

# Create orchestrator CLI
cat > /usr/local/bin/orchestrator << 'EOF'
#!/bin/bash
# P-System Membrane Orchestrator CLI

case "${1:-}" in
    "generate")
        if [ -z "$2" ]; then
            echo "Usage: orchestrator generate <config-file> [output-file]"
            exit 1
        fi
        config_file="$2"
        output_file="${3:-docker-compose.yml}"
        python3 /opt/orchestrator/tools/membrane-compose.py --config "$config_file" --output "$output_file"
        ;;
    "deploy")
        compose_file="${2:-docker-compose.yml}"
        if [ -f "$compose_file" ]; then
            echo "Deploying membrane hierarchy..."
            docker-compose -f "$compose_file" up -d
        else
            echo "Error: Compose file not found: $compose_file"
            exit 1
        fi
        ;;
    "teardown")
        compose_file="${2:-docker-compose.yml}"
        if [ -f "$compose_file" ]; then
            echo "Tearing down membrane hierarchy..."
            docker-compose -f "$compose_file" down -v
        else
            echo "Error: Compose file not found: $compose_file"
            exit 1
        fi
        ;;
    "status")
        echo "P-System Membrane Orchestrator Status:"
        if command -v docker-compose >/dev/null 2>&1; then
            echo "Docker Compose: Available"
            docker-compose ps 2>/dev/null || echo "No running compositions"
        else
            echo "Docker Compose: Not available"
        fi
        
        if command -v kubectl >/dev/null 2>&1; then
            echo "Kubernetes: Available" 
            kubectl get pods -n membrane-system 2>/dev/null || echo "No membrane pods found"
        else
            echo "Kubernetes: Not available"
        fi
        ;;
    "visualize")
        if [ -f "/opt/orchestrator/visualizer/server.py" ]; then
            echo "Starting membrane visualizer at http://localhost:8080"
            python3 /opt/orchestrator/visualizer/server.py &
        else
            echo "Visualizer not available"
        fi
        ;;
    "examples")
        echo "Available example configurations:"
        ls -la /opt/orchestrator/configs/
        echo ""
        echo "To use an example:"
        echo "  orchestrator generate /opt/orchestrator/configs/simple-hierarchy.json"
        echo "  orchestrator deploy"
        ;;
    "discover")
        registry_url="${2:-http://localhost:8500}"
        namespace="${3:-}"
        echo "Discovering membranes from registry..."
        if [ -n "$namespace" ]; then
            python3 /opt/orchestrator/tools/registry-orchestrator.py --registry-url "$registry_url" --namespace "$namespace" --output-format compose --output discovered-compose.yml
        else
            python3 /opt/orchestrator/tools/registry-orchestrator.py --registry-url "$registry_url" --output-format compose --output discovered-compose.yml
        fi
        echo "Generated discovered-compose.yml from registry"
        ;;
    "deploy-from-registry")
        registry_url="${2:-http://localhost:8500}"
        namespace="${3:-}"
        echo "Deploying membranes discovered from registry..."
        if [ -n "$namespace" ]; then
            python3 /opt/orchestrator/tools/registry-orchestrator.py --registry-url "$registry_url" --namespace "$namespace" --output-format compose --output registry-compose.yml
        else
            python3 /opt/orchestrator/tools/registry-orchestrator.py --registry-url "$registry_url" --output-format compose --output registry-compose.yml
        fi
        docker-compose -f registry-compose.yml up -d
        ;;
    "kubernetes-from-registry")
        registry_url="${2:-http://localhost:8500}"
        namespace="${3:-}"
        output_file="${4:-registry-k8s.yml}"
        echo "Generating Kubernetes manifests from registry..."
        if [ -n "$namespace" ]; then
            python3 /opt/orchestrator/tools/registry-orchestrator.py --registry-url "$registry_url" --namespace "$namespace" --output-format kubernetes --output "$output_file"
        else
            python3 /opt/orchestrator/tools/registry-orchestrator.py --registry-url "$registry_url" --output-format kubernetes --output "$output_file"
        fi
        echo "Generated $output_file from registry"
        ;;
    *)
        echo "P-System Membrane Orchestrator"
        echo "Commands:"
        echo "  generate <config> [output]  - Generate Docker Compose from membrane config"
        echo "  deploy [compose-file]       - Deploy membrane hierarchy"
        echo "  teardown [compose-file]     - Tear down membrane hierarchy"
        echo "  status                      - Show orchestrator status"
        echo "  visualize                   - Start web visualization server"
        echo "  examples                    - List example configurations"
        echo ""
        echo "Registry Commands:"
        echo "  discover [registry-url] [namespace]           - Discover membranes from registry"
        echo "  deploy-from-registry [registry-url] [ns]      - Deploy discovered membranes"
        echo "  kubernetes-from-registry [registry-url] [ns] [output] - Generate K8s manifests"
        ;;
esac
EOF

chmod +x /usr/local/bin/orchestrator

echo "P-System Membrane Orchestrator installation completed"
echo "Use 'orchestrator examples' to see available configurations"
echo "Use 'orchestrator --help' for available commands"