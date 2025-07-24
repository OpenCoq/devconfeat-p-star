# P-System Membrane Orchestrator

This feature enables orchestration of nested membrane containers, implementing hierarchical P-system architectures with Docker Compose and Kubernetes support. It provides tools for generating, deploying, and visualizing complex membrane hierarchies.

## Overview

The orchestrator feature adds advanced capabilities to membrane computing:

- **Nested Container Management**: Generate Docker Compose configurations for complex membrane hierarchies
- **Kubernetes Integration**: Deploy P-system membranes as Kubernetes resources
- **Visualization**: Web-based dashboard for viewing membrane hierarchies and communication
- **Auto-scaling**: Dynamic membrane division and scaling capabilities
- **Template System**: Pre-built configurations for common P-system patterns

## Usage

### Basic Configuration

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/opencoq/devconfeat-p-star/membrane:1": {},
        "ghcr.io/opencoq/devconfeat-p-star/orchestrator:1": {
            "orchestrationType": "docker-compose",
            "enableVisualization": true
        }
    }
}
```

### Advanced Kubernetes Configuration

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/opencoq/devconfeat-p-star/membrane:1": {},
        "ghcr.io/opencoq/devconfeat-p-star/orchestrator:1": {
            "orchestrationType": "kubernetes",
            "maxNestingDepth": "5",
            "enableAutoScaling": true,
            "enableVisualization": true
        }
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `orchestrationType` | string | "docker-compose" | Container orchestration system (docker-compose, kubernetes, standalone) |
| `maxNestingDepth` | string | "3" | Maximum depth for nested membrane hierarchies |
| `enableVisualization` | boolean | true | Enable web-based membrane hierarchy visualization |
| `enableAutoScaling` | boolean | false | Enable automatic membrane division and scaling |

## Commands

The `orchestrator` command provides comprehensive membrane hierarchy management:

```bash
# Generate Docker Compose from membrane configuration
orchestrator generate config.json output.yml

# Deploy membrane hierarchy
orchestrator deploy docker-compose.yml

# Tear down membrane hierarchy  
orchestrator teardown docker-compose.yml

# Check orchestrator status
orchestrator status

# Start visualization server
orchestrator visualize

# View example configurations
orchestrator examples
```

## Membrane Hierarchy Configuration

Define complex P-system hierarchies using JSON configuration:

```json
{
  "name": "Cognitive P-System",
  "description": "Multi-layer cognitive architecture with nested membranes",
  "membranes": [
    {
      "id": "root",
      "parent": null,
      "enable_scheme": true,
      "enable_monitoring": true
    },
    {
      "id": "perception",
      "parent": "root",
      "enable_scheme": true,
      "enable_monitoring": true
    },
    {
      "id": "cognition",
      "parent": "root", 
      "enable_scheme": true,
      "enable_monitoring": true
    },
    {
      "id": "action",
      "parent": "root",
      "enable_scheme": false,
      "enable_monitoring": true
    },
    {
      "id": "visual-proc",
      "parent": "perception",
      "enable_scheme": false,
      "enable_monitoring": true
    },
    {
      "id": "audio-proc",
      "parent": "perception",
      "enable_scheme": false,
      "enable_monitoring": true
    }
  ]
}
```

## Docker Compose Integration

The orchestrator automatically generates Docker Compose configurations:

```yaml
version: '3.8'

services:
  membrane-root:
    build:
      context: .
      dockerfile: Dockerfile.membrane
    environment:
      - MEMBRANE_ID=root
      - PARENT_MEMBRANE=
      - ENABLE_SCHEME=true
      - ENABLE_MONITORING=true
    volumes:
      - membrane-comm:/opt/membrane/communication
      - membrane-state:/opt/membrane/state
    networks:
      - membrane-net

  membrane-perception:
    build:
      context: .
      dockerfile: Dockerfile.membrane
    environment:
      - MEMBRANE_ID=perception
      - PARENT_MEMBRANE=root
      - ENABLE_SCHEME=true
      - ENABLE_MONITORING=true
    volumes:
      - membrane-comm:/opt/membrane/communication
      - membrane-state:/opt/membrane/state
    networks:
      - membrane-net
    depends_on:
      - membrane-root

volumes:
  membrane-comm:
  membrane-state:

networks:
  membrane-net:
    driver: bridge
```

## Kubernetes Deployment

For production deployments, the orchestrator provides Kubernetes manifests:

```bash
# Generate Kubernetes manifests
orchestrator generate --k8s config.json

# Deploy to Kubernetes
kubectl apply -f membrane-system.yml
```

## Visualization Dashboard

Access the web-based visualization at `http://localhost:8080`:

- **Interactive Hierarchy View**: Explore membrane nesting relationships
- **Real-time Communication**: Monitor message passing between membranes
- **State Visualization**: View membrane states and evolution rules
- **Performance Metrics**: Track membrane resource usage and events

## Workflow Examples

### 1. Simple Cognitive Architecture

```bash
# Use built-in example
orchestrator generate /opt/orchestrator/configs/simple-hierarchy.json

# Deploy the system
orchestrator deploy

# Start visualization
orchestrator visualize

# Monitor status
orchestrator status
```

### 2. Custom Multi-Agent System

```json
{
  "name": "Multi-Agent P-System",
  "membranes": [
    {
      "id": "coordinator",
      "parent": null,
      "enable_scheme": true,
      "enable_monitoring": true
    },
    {
      "id": "agent-1",
      "parent": "coordinator",
      "enable_scheme": false,
      "enable_monitoring": true
    },
    {
      "id": "agent-2", 
      "parent": "coordinator",
      "enable_scheme": false,
      "enable_monitoring": true
    }
  ]
}
```

### 3. Hierarchical Processing Pipeline

```bash
# Generate complex pipeline
orchestrator generate pipeline-config.json pipeline-compose.yml

# Deploy with scaling
orchestrator deploy pipeline-compose.yml

# Monitor pipeline performance
orchestrator status
```

## Advanced Features

### Auto-Scaling

When enabled, the orchestrator can automatically:
- Create new membrane instances based on load
- Scale down underutilized membranes
- Rebalance membrane hierarchies for optimal performance

### Kubernetes Integration

Full Kubernetes support includes:
- Pod auto-scaling based on membrane metrics
- Persistent volume management for membrane state
- Service mesh integration for communication
- Rolling updates for membrane evolution

### Visualization Features

The web dashboard provides:
- Real-time membrane hierarchy visualization
- Communication flow animation
- Event timeline and logging
- Resource usage monitoring
- Interactive rule editor

## Templates and Examples

The orchestrator includes several pre-built templates:

- **Simple Hierarchy**: Basic parent-child relationships
- **Cognitive Architecture**: Multi-layer cognitive system
- **Processing Pipeline**: Linear processing chain
- **Multi-Agent System**: Collaborative agent network
- **Distributed Computing**: High-performance computing cluster

## Integration with Membrane Features

The orchestrator works seamlessly with the base membrane feature:

```json
{
    "features": {
        "ghcr.io/opencoq/devconfeat-p-star/membrane:1": {
            "membraneId": "orchestrated-membrane",
            "enableScheme": true,
            "enableMonitoring": true
        },
        "ghcr.io/opencoq/devconfeat-p-star/orchestrator:1": {
            "orchestrationType": "docker-compose",
            "enableVisualization": true
        }
    }
}
```

This enables both local membrane functionality and orchestrated multi-container deployments.