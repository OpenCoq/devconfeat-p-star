# P-System Membrane Computing

This feature enables dev containers to function as P-system membranes, implementing a hierarchical membrane computing architecture with evolution rules, communication channels, and event-driven behavior.

## Overview

The membrane feature transforms a dev container into a P-system membrane that can:

- **Hierarchical Nesting**: Support parent-child membrane relationships
- **Evolution Rules**: Execute rule-based actions on events and state changes
- **Communication**: Exchange messages with other membranes via multiple modes
- **Event Monitoring**: Watch for file system changes and external signals
- **Hypergraph Representation**: Use Scheme for representing membrane structures
- **State Management**: Track membrane state and event history

## Usage

### Basic Configuration

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/opencoq/devconfeat-p-star/membrane:1": {
            "membraneId": "root-membrane",
            "enableScheme": true,
            "enableMonitoring": true
        }
    }
}
```

### Nested Membrane Configuration

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu", 
    "features": {
        "ghcr.io/opencoq/devconfeat-p-star/membrane:1": {
            "membraneId": "child-membrane-1",
            "parentMembrane": "root-membrane",
            "communicationMode": "shared-volume"
        }
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `membraneId` | string | "membrane-1" | Unique identifier for this membrane |
| `parentMembrane` | string | "" | Parent membrane ID for nested hierarchies |
| `enableScheme` | boolean | true | Install Scheme interpreter for hypergraph representation |
| `enableMonitoring` | boolean | true | Enable event monitoring and rule execution |
| `communicationMode` | string | "shared-volume" | Communication method: shared-volume, network, or ipc |

## Commands

Once installed, the `membrane` command provides access to membrane functionality:

```bash
# Check membrane status
membrane status

# Send message to another membrane
membrane send target-membrane "Hello from membrane"

# Check for incoming messages
membrane receive

# View recent events
membrane log

# List available evolution rules
membrane rules

# Start monitoring service
membrane monitor start

# Access Scheme interpreter with hypergraph library
membrane scheme
```

## Architecture

### Directory Structure

```
/opt/membrane/
├── config/
│   └── membrane.json          # Membrane configuration
├── rules/
│   └── evolution.sh           # Evolution rules engine
├── communication/
│   ├── send.sh               # Message sending
│   ├── receive.sh            # Message receiving
│   ├── inbox/                # Incoming messages
│   └── outbox/               # Outgoing messages
├── state/                    # Membrane state files
├── logs/
│   └── events.log            # Event history
├── lib/
│   └── membrane-utils.sh     # Utility functions
├── hypergraph.scm            # Scheme hypergraph library
└── monitor.sh                # Monitoring service
```

### Hypergraph Representation

The feature includes a Scheme library for representing membrane structures as hypergraphs:

```scheme
;; Create membrane node
(create-membrane-node "membrane-1")

;; Define nesting relationship
(create-nesting-link "child" "parent")

;; Define evolution rule
(create-evolution-rule "membrane-1" "file-change" "process.sh")

;; Define communication rule
(create-communication-rule "source" "target" "message")
```

### Evolution Rules

Evolution rules are triggered by events and can modify membrane state:

- **File Creation**: Automatically triggered when files are created in monitored directories
- **External Signals**: Custom signals can trigger specific evolution rules
- **Communication Events**: Message reception can trigger rule execution

### Communication Modes

- **Shared Volume**: Messages exchanged via shared file system (default)
- **Network**: TCP/UDP communication between membranes (future)
- **IPC**: Inter-process communication (future)

## Examples

### Simple Membrane with Monitoring

```json
{
    "features": {
        "ghcr.io/opencoq/devconfeat-p-star/membrane:1": {
            "membraneId": "monitor-membrane",
            "enableMonitoring": true
        }
    }
}
```

### Nested Cognitive System

```json
{
    "features": {
        "ghcr.io/opencoq/devconfeat-p-star/membrane:1": {
            "membraneId": "cognitive-agent",
            "parentMembrane": "cognitive-root",
            "enableScheme": true,
            "communicationMode": "shared-volume"
        }
    }
}
```

## Integration with Docker Compose

For complex nested membrane systems, use Docker Compose to orchestrate multiple containers:

```yaml
version: '3.8'
services:
  root-membrane:
    build: .
    environment:
      - MEMBRANE_ID=root
    volumes:
      - membrane-comm:/opt/membrane/communication
      
  child-membrane:
    build: .
    environment:
      - MEMBRANE_ID=child-1
      - PARENT_MEMBRANE=root
    volumes:
      - membrane-comm:/opt/membrane/communication

volumes:
  membrane-comm:
```

## Future Extensions

- **Membrane Division**: Dynamic creation of new membranes
- **Tensor Mapping**: Integration with ggml for tensor-based computation
- **Visualization Dashboard**: Web-based membrane hierarchy viewer
- **Advanced Communication**: Network and IPC protocols
- **OpenCog Integration**: Full AtomSpace hypergraph support