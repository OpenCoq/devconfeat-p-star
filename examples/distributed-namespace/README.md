# Distributed Namespace Example

This example demonstrates a complete distributed P-System membrane hierarchy with namespace registration capabilities.

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

## Configuration

The system is configured through `distributed-hierarchy.json`:

- **Namespace Registry**: Dedicated container running the registry service
- **Membrane Hierarchy**: 6 membranes in a 3-level hierarchy
- **Communication Mode**: Shared volume with namespace resolution
- **Monitoring**: Enabled on all membranes for observability

## Usage

### 1. Deploy the System

```bash
# Generate Docker Compose configuration
orchestrator generate examples/distributed-namespace/distributed-hierarchy.json docker-compose.yml

# Deploy the membrane hierarchy
orchestrator deploy docker-compose.yml
```

### 2. Interact with Membranes

```bash
# Access the cognitive root membrane
docker exec -it membrane-cognitive-root bash

# List all registered membranes
membrane list

# Discover a specific membrane
membrane discover visual-worker-1

# Send a message to a worker
membrane send visual-worker-1 "Process image: /data/image.jpg"
```

### 3. Monitor the System

```bash
# Check namespace registry status
curl http://localhost:8765/status

# View membrane hierarchy
orchestrator visualize
# Open http://localhost:8080 in browser
```

### 4. Test Fault Tolerance

```bash
# Stop a worker membrane
docker stop membrane-visual-worker-2

# List membranes (should show worker as unhealthy)
membrane list

# Registry will automatically clean up after timeout
```

## Key Benefits

1. **No Static Configuration**: Membranes discover each other dynamically
2. **Fault Tolerance**: Failed membranes are automatically detected and cleaned up
3. **Scalability**: Easy to add new membrane instances
4. **Observability**: Central registry provides system-wide view
5. **Flexibility**: Support for different communication modes

## Advanced Usage

### Adding New Membranes

```bash
# Start a new visual worker
docker run -d --name membrane-visual-worker-3 \
  --network membrane-net \
  -v membrane-comm:/opt/membrane/communication \
  -e MEMBRANE_ID=visual-worker-3 \
  -e PARENT_MEMBRANE=perception \
  -e MEMBRANE_REGISTRY_URL=http://namespace-registry:8765 \
  membrane:latest

# The new membrane will auto-register and be discoverable immediately
```

### Cross-Container Communication

```bash
# From one container, send to another
membrane send motor-worker "Execute movement: forward 10cm"

# The message will be routed through the namespace registry
# and delivered to the motor-worker's communication endpoint
```

### Health Monitoring

```bash
# Check which membranes are healthy
curl http://localhost:8765/list | jq '.[] | select(.status == "active")'

# View unhealthy membranes
curl http://localhost:8765/list | jq '.[] | select(.status == "unhealthy")'
```

## Files

- `distributed-hierarchy.json`: System configuration
- `docker-compose.yml`: Generated deployment configuration (after running orchestrator generate)
- `README.md`: This documentation

## Troubleshooting

### Registry Not Accessible
```bash
# Check if registry is running
docker ps | grep namespace-registry

# Check registry logs
docker logs membrane-namespace-registry
```

### Membrane Registration Failures
```bash
# Check membrane logs
docker logs membrane-cognitive-root

# Verify network connectivity
docker exec membrane-cognitive-root curl http://namespace-registry:8765/status
```

### Communication Issues
```bash
# List registered membranes
membrane list

# Test discovery
membrane discover target-membrane-id

# Check communication volumes
docker volume ls | grep membrane
```