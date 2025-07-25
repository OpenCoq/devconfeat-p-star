# Distributed Namespace Registration

The P-System Membrane Computing implementation now includes a distributed namespace registration system that enables dynamic membrane discovery and communication across distributed environments.

## Overview

The namespace registration system consists of:

1. **Namespace Registry**: A distributed service that maintains a registry of active membranes
2. **Namespace Client**: A client library for membranes to register, discover, and communicate
3. **Auto-registration**: Automatic membrane registration on startup
4. **Health Monitoring**: Periodic health checks and cleanup of stale membranes

## Features

### Membrane Registration
- Membranes automatically register themselves with the namespace registry
- Registration includes membrane ID, parent relationship, communication endpoint, and metadata
- Support for different communication modes (shared-volume, network, ipc)

### Membrane Discovery
- Membranes can discover other membranes by ID
- Discovery returns communication endpoint and metadata
- Results are cached for performance

### Distributed Communication
- Send messages to remote membranes using their registered endpoints
- Automatic endpoint resolution based on communication mode
- Transparent routing across different communication protocols

### Health Monitoring
- Automatic heartbeat mechanism to track membrane health
- Cleanup of stale/dead membranes from registry
- Configurable heartbeat and cleanup intervals

## Configuration

### Membrane Feature Options

The membrane feature now supports additional namespace options:

```json
{
    "features": {
        "membrane": {
            "membraneId": "my-membrane",
            "enableNamespace": true,
            "autoRegister": true,
            "registryUrl": "http://localhost:8765"
        }
    }
}
```

### Environment Variables

- `MEMBRANE_REGISTRY_URL`: URL of the namespace registry service
- `MEMBRANE_ID`: Membrane identifier (auto-detected from config if not set)

## Usage

### Starting a Namespace Registry

```bash
# Start registry on default port (8765)
membrane registry start

# Check registry status
membrane registry status
```

### Membrane Registration

```bash
# Manual registration (auto-registration is enabled by default)
membrane register [parent-membrane-id]

# Check registration status
membrane status
```

### Membrane Discovery

```bash
# Discover a membrane by ID
membrane discover target-membrane-id

# List all registered membranes
membrane list
```

### Sending Messages

```bash
# Send message using namespace-aware communication
membrane send target-membrane-id "Hello, World!"
```

## API

### Registry HTTP API

- `POST /register`: Register a membrane
- `POST /deregister`: Deregister a membrane
- `POST /heartbeat`: Send heartbeat for a membrane
- `GET /discover/{membrane_id}`: Discover a membrane
- `GET /list`: List all membranes
- `GET /status`: Get registry status

### Python Client API

```python
from namespace_client import create_namespace_client

# Create client
client = create_namespace_client("my-membrane")

# Register membrane
client.register(parent="parent-membrane")

# Discover membrane
endpoint = client.discover("target-membrane")

# Send message
client.send_message("target-membrane", {"message": "Hello"})

# List membranes
membranes = client.list_membranes()
```

## Architecture

### Registry Service
- HTTP-based REST API for registration and discovery
- In-memory storage with disk persistence
- Background cleanup of stale entries
- Support for distributed registry peers

### Client Library
- Python-based client for easy integration
- Automatic endpoint detection based on communication mode
- Caching for improved performance
- Background heartbeat thread

### Communication Modes

1. **Shared Volume**: Messages written to shared filesystem locations
2. **Network**: HTTP-based message delivery
3. **IPC**: Unix socket communication (planned)

## Benefits

1. **Dynamic Discovery**: No need for static configuration of membrane relationships
2. **Fault Tolerance**: Automatic cleanup of failed membranes
3. **Scalability**: Support for large numbers of distributed membranes
4. **Flexibility**: Multiple communication modes supported
5. **Observability**: Registry provides system-wide view of membrane hierarchy

## Future Enhancements

- **Distributed Registry**: Multiple registry instances with peer-to-peer synchronization
- **Load Balancing**: Automatic load balancing across membrane replicas
- **Security**: Authentication and authorization for membrane registration
- **Monitoring**: Integration with monitoring systems (Prometheus, etc.)
- **Service Mesh**: Integration with service mesh technologies

## Examples

See the `examples/distributed-namespace/` directory for complete examples of:
- Multi-membrane distributed systems
- Cross-container communication
- Registry deployment patterns
- Fault tolerance scenarios

## Troubleshooting

### Common Issues

1. **Registry not accessible**: Check that the registry service is running and accessible
2. **Registration failures**: Verify network connectivity and registry URL
3. **Discovery returns no results**: Ensure target membrane is registered and healthy
4. **Message delivery failures**: Check communication mode compatibility

### Debug Commands

```bash
# Check membrane configuration
membrane status

# Check registry connectivity
curl http://localhost:8765/status

# View membrane logs
membrane log

# List registered membranes
membrane list
```