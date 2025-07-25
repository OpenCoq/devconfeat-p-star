# Distributed Namespace Example

This example demonstrates a complete distributed P-System membrane hierarchy with namespace registration capabilities.

## 🎯 Overview

The distributed namespace registration system enables:
- **Dynamic Discovery**: Membranes can find each other without static configuration
- **Service Registration**: Automatic registration with health monitoring  
- **Namespace Isolation**: Logical separation of membrane groups
- **Fault Tolerance**: Stale resource cleanup and heartbeat monitoring
- **Hierarchical Communication**: Parent-child relationships maintained in the namespace

## Architecture

The example creates a multi-level membrane hierarchy:

```
namespace-registry (central registry service)
└── cognitive-root (root membrane)
    ├── perception (perception processing)
    │   ├── visual-worker-1 (visual processing instance 1)
    │   └── visual-worker-2 (visual processing instance 2)
    └── action (action planning)
        └── motor-worker (motor control)
```

## Features Demonstrated

1. **Central Namespace Registry**: Dedicated service for membrane registration and discovery
2. **Auto-Registration**: All membranes automatically register themselves on startup
3. **Dynamic Discovery**: Membranes can discover and communicate with others without static configuration
4. **Hierarchical Communication**: Parent-child relationships maintained in the namespace
5. **Load Distribution**: Multiple visual workers for parallel processing

## 🚀 Quick Start

### 1. Registry-Enabled Environment

```json
{
  "name": "P-System with Distributed Registry",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/opencoq/devconfeat-p-star/registry:1": {
      "registryMode": "standalone",
      "enableServiceDiscovery": true,
      "enableWebUI": true
    },
    "ghcr.io/opencoq/devconfeat-p-star/membrane:1": {
      "membraneId": "cognitive-root",
      "enableRegistry": true,
      "namespaceId": "cognitive-system"
    },
    "ghcr.io/opencoq/devconfeat-p-star/orchestrator:1": {
      "enableRegistry": true,
      "enableVisualization": true
    }
  }
}
```

### 2. Deploy the System

```bash
# Generate Docker Compose configuration
orchestrator generate examples/distributed-namespace/distributed-hierarchy.json docker-compose.yml

# Deploy the membrane hierarchy
orchestrator deploy docker-compose.yml
```

### 3. Start the System

```bash
# 1. Start the registry service
registry start

# 2. Create a namespace for our cognitive system
registry create-namespace "cognitive-system" "AI cognitive architecture"

# 3. Register the current membrane
membrane register

# 4. Check registration status
membrane status

# 5. Discover other membranes in the namespace
membrane discover
```

### 4. Add More Membranes

Create additional containers with different membrane IDs:

```json
{
  "features": {
    "ghcr.io/opencoq/devconfeat-p-star/membrane:1": {
      "membraneId": "perception-processor",
      "parentMembrane": "cognitive-root",
      "enableRegistry": true,
      "namespaceId": "cognitive-system"
    }
  }
}
```

```json
{
  "features": {
    "ghcr.io/opencoq/devconfeat-p-star/membrane:1": {
      "membraneId": "visual-worker",
      "parentMembrane": "perception-processor",
      "enableRegistry": true,
      "namespaceId": "cognitive-system"
    }
  }
}
```

### 5. Interact with the System

```bash
# Check all registered membranes
membrane discover

# Send a message to a specific membrane
membrane send visual-worker "Process image data from camera 1"

# View membrane hierarchy
membrane status

# Monitor activity logs
membrane log
```

## Configuration

The system is configured through `distributed-hierarchy.json`:

- **Namespace Registry**: Dedicated container running the registry service
- **Membrane Hierarchy**: 6 membranes in a 3-level hierarchy
- **Communication Mode**: Shared volume with namespace resolution
- **Monitoring**: Enabled on all membranes for observability

## Advanced Features

### Registry Web Interface

Access the registry's web interface at `http://localhost:8765` to:
- View all registered membranes
- Monitor health status
- Visualize membrane hierarchy
- Debug communication issues

### Distributed Deployment

Deploy across multiple hosts:

```bash
# Host 1: Registry + Root membrane
docker-compose -f registry.yml up -d

# Host 2: Perception membranes
docker-compose -f perception.yml up -d

# Host 3: Action membranes  
docker-compose -f action.yml up -d
```

### Fault Tolerance

The system handles:
- **Registry Failures**: Membranes cache discovered information
- **Membrane Failures**: Automatic cleanup of stale registrations
- **Network Partitions**: Graceful degradation and reconnection

## Monitoring and Debugging

```bash
# Check registry health
curl http://localhost:8765/status

# View all registered membranes
curl http://localhost:8765/api/membranes

# Monitor membrane events
membrane log | grep registry

# Debug communication
membrane send --debug visual-worker "test message"
```

This example demonstrates how P-System membranes can form dynamic, distributed computing systems with automatic discovery and fault tolerance.