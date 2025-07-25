#!/bin/bash
set -e

echo "Activating P-System Distributed Namespace Registry feature"

# Extract options
REGISTRY_MODE=${REGISTRYMODE:-standalone}
ENABLE_SERVICE_DISCOVERY=${ENABLESERVICEDISCOVERY:-true}
ENABLE_HEALTH_CHECKING=${ENABLEHEALTHCHECKING:-true}
REGISTRY_PORT=${REGISTRYPORT:-8500}
ENABLE_WEB_UI=${ENABLEWEBUI:-true}

echo "Configuring registry mode: $REGISTRY_MODE"
echo "Registry port: $REGISTRY_PORT"
echo "Service discovery: $ENABLE_SERVICE_DISCOVERY"

# Create registry directory structure
mkdir -p /opt/registry
mkdir -p /opt/registry/config
mkdir -p /opt/registry/data
mkdir -p /opt/registry/logs
mkdir -p /opt/registry/lib
mkdir -p /opt/registry/api

# Install required system packages
echo "Installing system packages..."
if apt-get update && apt-get install -y python3 python3-pip curl jq sqlite3; then
    echo "Successfully installed system packages"
else
    echo "Warning: Failed to install some packages"
fi

# Install Python dependencies for the registry service
pip3 install flask sqlite3 requests || echo "Warning: Failed to install Python packages"

# Create registry configuration
cat > /opt/registry/config/registry.json << EOF
{
  "mode": "$REGISTRY_MODE",
  "port": $REGISTRY_PORT,
  "features": {
    "service_discovery": $ENABLE_SERVICE_DISCOVERY,
    "health_checking": $ENABLE_HEALTH_CHECKING,
    "web_ui": $ENABLE_WEB_UI
  },
  "storage": {
    "type": "sqlite",
    "path": "/opt/registry/data/registry.db"
  },
  "cluster": {
    "node_id": "$(hostname)",
    "peers": []
  }
}
EOF

# Create registry database schema
cat > /opt/registry/lib/schema.sql << 'EOF'
-- Namespace Registry Database Schema

CREATE TABLE IF NOT EXISTS namespaces (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    parent_namespace TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata TEXT DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS membranes (
    id TEXT PRIMARY KEY,
    namespace_id TEXT NOT NULL,
    membrane_id TEXT NOT NULL,
    parent_membrane TEXT,
    host TEXT NOT NULL,
    port INTEGER,
    status TEXT DEFAULT 'active',
    capabilities TEXT DEFAULT '[]',
    last_heartbeat TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata TEXT DEFAULT '{}',
    FOREIGN KEY (namespace_id) REFERENCES namespaces(id),
    UNIQUE(namespace_id, membrane_id)
);

CREATE TABLE IF NOT EXISTS services (
    id TEXT PRIMARY KEY,
    membrane_id TEXT NOT NULL,
    service_name TEXT NOT NULL,
    service_type TEXT NOT NULL,
    endpoint TEXT NOT NULL,
    health_check_url TEXT,
    status TEXT DEFAULT 'healthy',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata TEXT DEFAULT '{}',
    FOREIGN KEY (membrane_id) REFERENCES membranes(id)
);

CREATE INDEX IF NOT EXISTS idx_membranes_namespace ON membranes(namespace_id);
CREATE INDEX IF NOT EXISTS idx_membranes_status ON membranes(status);
CREATE INDEX IF NOT EXISTS idx_services_membrane ON services(membrane_id);
CREATE INDEX IF NOT EXISTS idx_services_type ON services(service_type);
EOF

# Initialize database
sqlite3 /opt/registry/data/registry.db < /opt/registry/lib/schema.sql

# Create the main registry service
cat > /opt/registry/api/registry_service.py << 'EOF'
#!/usr/bin/env python3
"""
P-System Distributed Namespace Registry Service
"""

import json
import sqlite3
import time
import uuid
from datetime import datetime, timedelta
from flask import Flask, request, jsonify
import logging
import threading

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

class NamespaceRegistry:
    def __init__(self, db_path="/opt/registry/data/registry.db"):
        self.db_path = db_path
        self.config = self.load_config()
        
    def load_config(self):
        try:
            with open("/opt/registry/config/registry.json", "r") as f:
                return json.load(f)
        except:
            return {"mode": "standalone", "port": 8500}
    
    def get_db(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn
    
    def create_namespace(self, name, description="", parent_namespace=None, metadata=None):
        """Create a new namespace"""
        namespace_id = str(uuid.uuid4())
        metadata_json = json.dumps(metadata or {})
        
        with self.get_db() as conn:
            try:
                conn.execute("""
                    INSERT INTO namespaces (id, name, description, parent_namespace, metadata)
                    VALUES (?, ?, ?, ?, ?)
                """, (namespace_id, name, description, parent_namespace, metadata_json))
                conn.commit()
                return namespace_id
            except sqlite3.IntegrityError:
                raise ValueError(f"Namespace '{name}' already exists")
    
    def register_membrane(self, namespace_id, membrane_id, host, port=None, 
                         parent_membrane=None, capabilities=None, metadata=None):
        """Register a membrane in a namespace"""
        record_id = str(uuid.uuid4())
        capabilities_json = json.dumps(capabilities or [])
        metadata_json = json.dumps(metadata or {})
        
        with self.get_db() as conn:
            try:
                conn.execute("""
                    INSERT INTO membranes (id, namespace_id, membrane_id, parent_membrane, 
                                         host, port, capabilities, metadata)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, (record_id, namespace_id, membrane_id, parent_membrane, 
                      host, port, capabilities_json, metadata_json))
                conn.commit()
                return record_id
            except sqlite3.IntegrityError:
                raise ValueError(f"Membrane '{membrane_id}' already exists in namespace")
    
    def discover_membranes(self, namespace_id=None, membrane_type=None):
        """Discover membranes in the registry"""
        query = """
            SELECT m.*, n.name as namespace_name 
            FROM membranes m 
            JOIN namespaces n ON m.namespace_id = n.id 
            WHERE m.status = 'active'
        """
        params = []
        
        if namespace_id:
            query += " AND m.namespace_id = ?"
            params.append(namespace_id)
            
        with self.get_db() as conn:
            cursor = conn.execute(query, params)
            return [dict(row) for row in cursor.fetchall()]
    
    def heartbeat(self, membrane_id):
        """Update membrane heartbeat"""
        with self.get_db() as conn:
            conn.execute("""
                UPDATE membranes 
                SET last_heartbeat = CURRENT_TIMESTAMP 
                WHERE membrane_id = ?
            """, (membrane_id,))
            conn.commit()
    
    def cleanup_stale_membranes(self, threshold_minutes=5):
        """Remove stale membrane registrations"""
        threshold = datetime.now() - timedelta(minutes=threshold_minutes)
        
        with self.get_db() as conn:
            cursor = conn.execute("""
                UPDATE membranes 
                SET status = 'stale' 
                WHERE last_heartbeat < ? AND status = 'active'
            """, (threshold,))
            conn.commit()
            return cursor.rowcount

# Global registry instance
registry = NamespaceRegistry()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "timestamp": datetime.now().isoformat()})

@app.route('/api/namespaces', methods=['POST'])
def create_namespace():
    """Create a new namespace"""
    data = request.get_json()
    try:
        namespace_id = registry.create_namespace(
            name=data.get('name'),
            description=data.get('description', ''),
            parent_namespace=data.get('parent_namespace'),
            metadata=data.get('metadata', {})
        )
        return jsonify({"namespace_id": namespace_id, "status": "created"}), 201
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

@app.route('/api/namespaces', methods=['GET'])
def list_namespaces():
    """List all namespaces"""
    with registry.get_db() as conn:
        cursor = conn.execute("SELECT * FROM namespaces ORDER BY created_at")
        namespaces = [dict(row) for row in cursor.fetchall()]
    return jsonify({"namespaces": namespaces})

@app.route('/api/membranes/register', methods=['POST'])
def register_membrane():
    """Register a membrane"""
    data = request.get_json()
    try:
        record_id = registry.register_membrane(
            namespace_id=data.get('namespace_id'),
            membrane_id=data.get('membrane_id'),
            host=data.get('host'),
            port=data.get('port'),
            parent_membrane=data.get('parent_membrane'),
            capabilities=data.get('capabilities', []),
            metadata=data.get('metadata', {})
        )
        return jsonify({"record_id": record_id, "status": "registered"}), 201
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

@app.route('/api/membranes/discover', methods=['GET'])
def discover_membranes():
    """Discover membranes"""
    namespace_id = request.args.get('namespace_id')
    membrane_type = request.args.get('type')
    
    membranes = registry.discover_membranes(namespace_id, membrane_type)
    return jsonify({"membranes": membranes})

@app.route('/api/membranes/<membrane_id>/heartbeat', methods=['POST'])
def membrane_heartbeat(membrane_id):
    """Update membrane heartbeat"""
    registry.heartbeat(membrane_id)
    return jsonify({"status": "updated"})

@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Get registry statistics"""
    with registry.get_db() as conn:
        namespace_count = conn.execute("SELECT COUNT(*) FROM namespaces").fetchone()[0]
        membrane_count = conn.execute("SELECT COUNT(*) FROM membranes WHERE status='active'").fetchone()[0]
        stale_count = conn.execute("SELECT COUNT(*) FROM membranes WHERE status='stale'").fetchone()[0]
    
    return jsonify({
        "namespaces": namespace_count,
        "active_membranes": membrane_count,
        "stale_membranes": stale_count,
        "timestamp": datetime.now().isoformat()
    })

def cleanup_task():
    """Background task to cleanup stale membranes"""
    while True:
        try:
            cleaned = registry.cleanup_stale_membranes()
            if cleaned > 0:
                app.logger.info(f"Cleaned up {cleaned} stale membranes")
        except Exception as e:
            app.logger.error(f"Cleanup task error: {e}")
        time.sleep(60)  # Run every minute

if __name__ == '__main__':
    # Start cleanup task in background
    cleanup_thread = threading.Thread(target=cleanup_task, daemon=True)
    cleanup_thread.start()
    
    # Create default namespace
    try:
        registry.create_namespace("default", "Default P-System namespace")
    except ValueError:
        pass  # Already exists
    
    # Start the Flask app
    port = registry.config.get('port', 8500)
    app.run(host='0.0.0.0', port=port, debug=False)
EOF

chmod +x /opt/registry/api/registry_service.py

# Create registry client library
cat > /opt/registry/lib/registry_client.py << 'EOF'
#!/usr/bin/env python3
"""
P-System Registry Client Library
"""

import json
import requests
import logging
from typing import Dict, List, Optional

class RegistryClient:
    def __init__(self, registry_url: str = "http://localhost:8500"):
        self.base_url = registry_url.rstrip('/')
        self.session = requests.Session()
        self.logger = logging.getLogger(__name__)
    
    def create_namespace(self, name: str, description: str = "", 
                        parent_namespace: Optional[str] = None, 
                        metadata: Optional[Dict] = None) -> str:
        """Create a new namespace"""
        data = {
            'name': name,
            'description': description,
            'parent_namespace': parent_namespace,
            'metadata': metadata or {}
        }
        
        response = self.session.post(f"{self.base_url}/api/namespaces", json=data)
        response.raise_for_status()
        return response.json()['namespace_id']
    
    def register_membrane(self, namespace_id: str, membrane_id: str, 
                         host: str, port: Optional[int] = None,
                         parent_membrane: Optional[str] = None,
                         capabilities: Optional[List[str]] = None,
                         metadata: Optional[Dict] = None) -> str:
        """Register a membrane"""
        data = {
            'namespace_id': namespace_id,
            'membrane_id': membrane_id,
            'host': host,
            'port': port,
            'parent_membrane': parent_membrane,
            'capabilities': capabilities or [],
            'metadata': metadata or {}
        }
        
        response = self.session.post(f"{self.base_url}/api/membranes/register", json=data)
        response.raise_for_status()
        return response.json()['record_id']
    
    def discover_membranes(self, namespace_id: Optional[str] = None,
                          membrane_type: Optional[str] = None) -> List[Dict]:
        """Discover membranes"""
        params = {}
        if namespace_id:
            params['namespace_id'] = namespace_id
        if membrane_type:
            params['type'] = membrane_type
            
        response = self.session.get(f"{self.base_url}/api/membranes/discover", params=params)
        response.raise_for_status()
        return response.json()['membranes']
    
    def heartbeat(self, membrane_id: str):
        """Send heartbeat for a membrane"""
        response = self.session.post(f"{self.base_url}/api/membranes/{membrane_id}/heartbeat")
        response.raise_for_status()
    
    def get_stats(self) -> Dict:
        """Get registry statistics"""
        response = self.session.get(f"{self.base_url}/api/stats")
        response.raise_for_status()
        return response.json()
    
    def health_check(self) -> bool:
        """Check if registry is healthy"""
        try:
            response = self.session.get(f"{self.base_url}/health", timeout=5)
            return response.status_code == 200
        except:
            return False
EOF

# Create registry CLI tool
cat > /usr/local/bin/registry << 'EOF'
#!/bin/bash
# Registry CLI tool

REGISTRY_URL=${REGISTRY_URL:-http://localhost:8500}

case "${1:-}" in
    "start")
        echo "Starting P-System Registry Service..."
        cd /opt/registry/api
        python3 registry_service.py &
        echo "Registry started on port 8500"
        ;;
    "status")
        curl -s "$REGISTRY_URL/health" | jq . 2>/dev/null || echo "Registry not responding"
        ;;
    "stats")
        curl -s "$REGISTRY_URL/api/stats" | jq . 2>/dev/null || echo "Cannot get stats"
        ;;
    "namespaces")
        curl -s "$REGISTRY_URL/api/namespaces" | jq . 2>/dev/null || echo "Cannot list namespaces"
        ;;
    "discover")
        curl -s "$REGISTRY_URL/api/membranes/discover" | jq . 2>/dev/null || echo "Cannot discover membranes"
        ;;
    "create-namespace")
        if [ -z "$2" ]; then
            echo "Usage: registry create-namespace <name> [description]"
            exit 1
        fi
        curl -s -X POST "$REGISTRY_URL/api/namespaces" \
             -H "Content-Type: application/json" \
             -d "{\"name\": \"$2\", \"description\": \"${3:-}\"}" | jq . 2>/dev/null
        ;;
    *)
        echo "P-System Distributed Namespace Registry CLI"
        echo "Commands:"
        echo "  start                          - Start registry service"
        echo "  status                         - Check registry health"
        echo "  stats                          - Show registry statistics"
        echo "  namespaces                     - List all namespaces"
        echo "  discover                       - Discover registered membranes"
        echo "  create-namespace <name> [desc] - Create a new namespace"
        ;;
esac
EOF

chmod +x /usr/local/bin/registry

# Create web UI (simple HTML interface)
mkdir -p /opt/registry/web

cat > /opt/registry/web/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>P-System Registry</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .stats { display: flex; gap: 20px; margin-bottom: 20px; }
        .stat-card { padding: 15px; border: 1px solid #ddd; border-radius: 5px; flex: 1; }
        .section { margin-bottom: 30px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .status-active { color: green; }
        .status-stale { color: orange; }
    </style>
</head>
<body>
    <div class="container">
        <h1>P-System Distributed Namespace Registry</h1>
        
        <div class="stats" id="stats">
            <div class="stat-card">
                <h3>Namespaces</h3>
                <div id="namespace-count">Loading...</div>
            </div>
            <div class="stat-card">
                <h3>Active Membranes</h3>
                <div id="membrane-count">Loading...</div>
            </div>
            <div class="stat-card">
                <h3>Stale Membranes</h3>
                <div id="stale-count">Loading...</div>
            </div>
        </div>
        
        <div class="section">
            <h2>Namespaces</h2>
            <table>
                <thead>
                    <tr><th>Name</th><th>Description</th><th>Created</th></tr>
                </thead>
                <tbody id="namespaces-table">
                    <tr><td colspan="3">Loading...</td></tr>
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>Registered Membranes</h2>
            <table>
                <thead>
                    <tr><th>Membrane ID</th><th>Namespace</th><th>Host</th><th>Status</th><th>Last Heartbeat</th></tr>
                </thead>
                <tbody id="membranes-table">
                    <tr><td colspan="5">Loading...</td></tr>
                </tbody>
            </table>
        </div>
    </div>
    
    <script>
        async function loadStats() {
            try {
                const response = await fetch('/api/stats');
                const stats = await response.json();
                document.getElementById('namespace-count').textContent = stats.namespaces;
                document.getElementById('membrane-count').textContent = stats.active_membranes;
                document.getElementById('stale-count').textContent = stats.stale_membranes;
            } catch (e) {
                console.error('Failed to load stats:', e);
            }
        }
        
        async function loadNamespaces() {
            try {
                const response = await fetch('/api/namespaces');
                const data = await response.json();
                const tbody = document.getElementById('namespaces-table');
                tbody.innerHTML = data.namespaces.map(ns => 
                    `<tr><td>${ns.name}</td><td>${ns.description}</td><td>${ns.created_at}</td></tr>`
                ).join('');
            } catch (e) {
                document.getElementById('namespaces-table').innerHTML = '<tr><td colspan="3">Error loading namespaces</td></tr>';
            }
        }
        
        async function loadMembranes() {
            try {
                const response = await fetch('/api/membranes/discover');
                const data = await response.json();
                const tbody = document.getElementById('membranes-table');
                tbody.innerHTML = data.membranes.map(membrane => 
                    `<tr>
                        <td>${membrane.membrane_id}</td>
                        <td>${membrane.namespace_name}</td>
                        <td>${membrane.host}${membrane.port ? ':' + membrane.port : ''}</td>
                        <td class="status-${membrane.status}">${membrane.status}</td>
                        <td>${membrane.last_heartbeat}</td>
                    </tr>`
                ).join('');
            } catch (e) {
                document.getElementById('membranes-table').innerHTML = '<tr><td colspan="5">Error loading membranes</td></tr>';
            }
        }
        
        // Initial load
        loadStats();
        loadNamespaces();
        loadMembranes();
        
        // Auto-refresh every 30 seconds
        setInterval(() => {
            loadStats();
            loadMembranes();
        }, 30000);
    </script>
</body>
</html>
EOF

echo "P-System Distributed Namespace Registry feature installation completed"
echo "Registry mode: $REGISTRY_MODE"
echo "Use 'registry start' to start the service"
echo "Use 'registry status' to check health"
echo "Use 'registry --help' for available commands"