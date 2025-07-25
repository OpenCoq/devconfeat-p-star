# Technical Architecture Documentation

This document provides detailed technical architecture documentation for the P-System Membrane Computing Dev Container Features implementation.

## 📋 Table of Contents

- [System Overview](#system-overview)
- [Membrane Computing Fundamentals](#membrane-computing-fundamentals)
- [Container-Membrane Mapping](#container-membrane-mapping)
- [Component Architecture](#component-architecture)
- [Communication Protocols](#communication-protocols)
- [Evolution Engine](#evolution-engine)
- [Orchestration System](#orchestration-system)
- [Integration Patterns](#integration-patterns)
- [Performance & Scalability](#performance--scalability)
- [Security Model](#security-model)

## 🔭 System Overview

The P-System Membrane Computing implementation transforms container environments into computational membranes, creating a distributed computing framework based on biological membrane computing principles.

### High-Level Architecture

```mermaid
graph TB
    subgraph "Host Environment"
        HOS[Host Operating System]
        DOC[Docker Runtime]
        KUB[Kubernetes/Docker Compose]
    end
    
    subgraph "Membrane Layer"
        MEM1[Root Membrane Container]
        MEM2[Child Membrane Container]
        MEM3[Worker Membrane Container]
        
        subgraph "Membrane Core Components"
            ENG[Evolution Engine]
            COM[Communication Manager]
            MON[State Monitor]
            SCH[Scheme Interpreter]
        end
    end
    
    subgraph "Application Layer"
        APP1[User Application]
        APP2[Cognitive Kernel]
        APP3[Tensor Processing]
    end
    
    subgraph "External Integrations"
        GGM[ggml Framework]
        OPE[OpenCog AtomSpace]
        MLF[ML Frameworks]
    end
    
    HOS --> DOC
    DOC --> KUB
    KUB --> MEM1
    KUB --> MEM2
    KUB --> MEM3
    
    MEM1 --> ENG
    MEM1 --> COM
    MEM1 --> MON
    MEM1 --> SCH
    
    MEM1 --> APP1
    MEM2 --> APP2
    MEM3 --> APP3
    
    APP2 --> GGM
    APP2 --> OPE
    APP3 --> MLF
```

## 🧬 Membrane Computing Fundamentals

### P-System Mathematical Model

In formal terms, a P-System is defined as:

```
Π = (V, T, μ, w₁, w₂, ..., wₘ, R₁, R₂, ..., Rₘ, i₀)
```

Where:
- **V**: Alphabet of symbols
- **T**: Terminal alphabet (output symbols)
- **μ**: Membrane structure (tree hierarchy)
- **wᵢ**: Initial multiset in membrane i
- **Rᵢ**: Evolution rules for membrane i
- **i₀**: Output membrane designation

### Container Implementation Mapping

```mermaid
classDiagram
    class PSystem {
        +String membraneId
        +Set~String~ alphabet
        +Set~String~ terminalAlphabet
        +MembraneStructure hierarchy
        +Map~String,Object~ state
        +List~EvolutionRule~ rules
        +String outputMembrane
    }
    
    class MembraneContainer {
        +String containerId
        +String membraneId
        +String parentMembrane
        +List~String~ childMembranes
        +CommunicationManager comm
        +EvolutionEngine engine
        +StateMonitor monitor
    }
    
    class EvolutionRule {
        +String ruleId
        +Pattern trigger
        +Action action
        +Condition condition
        +Priority priority
        +execute()
    }
    
    class CommunicationManager {
        +sendMessage()
        +receiveMessage()
        +broadcastToChildren()
        +reportToParent()
    }
    
    PSystem --> MembraneContainer
    MembraneContainer --> EvolutionRule
    MembraneContainer --> CommunicationManager
```

## 🗂️ Container-Membrane Mapping

### Membrane Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Initializing
    Initializing --> Active: Setup Complete
    Active --> Processing: Evolution Rule Triggered
    Processing --> Active: Rule Execution Complete
    Active --> Communicating: Message Received/Sent
    Communicating --> Active: Communication Complete
    Active --> Dividing: Auto-scaling Triggered
    Dividing --> Active: New Child Created
    Active --> Dissolving: Shutdown Signal
    Dissolving --> [*]
    
    note right of Processing
        Multiple rules can execute
        concurrently within membrane
    end note
    
    note right of Dividing
        New child membrane inherits
        parent configuration
    end note
```

### Container Resource Mapping

```mermaid
graph LR
    subgraph "Container Resources"
        CPU[CPU Allocation]
        MEM[Memory Allocation]
        NET[Network Interfaces]
        VOL[Volume Mounts]
        ENV[Environment Variables]
    end
    
    subgraph "Membrane Properties"
        ACT[Activity Level]
        CAP[Processing Capacity]
        CON[Connectivity]
        STA[State Storage]
        CFG[Configuration]
    end
    
    CPU --> ACT
    MEM --> CAP
    NET --> CON
    VOL --> STA
    ENV --> CFG
```

## 🏗️ Component Architecture

### Membrane Core Components

#### 1. Evolution Engine

```mermaid
flowchart TB
    subgraph "Evolution Engine"
        EVT[Event Listener]
        RUL[Rule Matcher]
        EXE[Rule Executor]
        SCH[Scheduler]
        LOG[Activity Logger]
    end
    
    subgraph "Rule Types"
        FIL[File System Rules]
        NET[Network Rules]
        TIM[Timer Rules]
        MSG[Message Rules]
        STA[State Rules]
    end
    
    subgraph "Execution Context"
        ENV[Environment]
        RES[Resources]
        STA2[State]
        COM[Communication]
    end
    
    EVT --> RUL
    RUL --> EXE
    EXE --> SCH
    SCH --> LOG
    
    RUL --> FIL
    RUL --> NET
    RUL --> TIM
    RUL --> MSG
    RUL --> STA
    
    EXE --> ENV
    EXE --> RES
    EXE --> STA2
    EXE --> COM
```

#### 2. Communication Manager

```mermaid
sequenceDiagram
    participant A as Membrane A
    participant CM as Communication Manager
    participant B as Membrane B
    participant P as Parent Membrane
    participant C as Child Membrane
    
    A->>CM: Send Message to B
    CM->>CM: Route Message
    CM->>B: Deliver Message
    B->>CM: Acknowledge Receipt
    CM->>A: Confirm Delivery
    
    Note over CM: Message routing based on<br/>membrane hierarchy
    
    A->>CM: Broadcast to Children
    CM->>C: Forward Message
    C->>CM: Process & Respond
    CM->>A: Aggregate Responses
    
    Note over CM: Hierarchical message<br/>propagation
```

#### 3. State Monitor

```mermaid
graph TB
    subgraph "State Monitor"
        COL[Data Collector]
        AGG[Aggregator]
        ANA[Analyzer]
        REP[Reporter]
        ALE[Alert Manager]
    end
    
    subgraph "Monitored Metrics"
        CPU2[CPU Usage]
        MEM2[Memory Usage]
        NET2[Network I/O]
        DIS[Disk I/O]
        MSG2[Message Rate]
        RUL2[Rule Executions]
    end
    
    subgraph "Output Destinations"
        LOG2[Log Files]
        MET[Metrics Service]
        DAS[Dashboard]
        TEN[Tensor Export]
    end
    
    COL --> AGG
    AGG --> ANA
    ANA --> REP
    REP --> ALE
    
    CPU2 --> COL
    MEM2 --> COL
    NET2 --> COL
    DIS --> COL
    MSG2 --> COL
    RUL2 --> COL
    
    REP --> LOG2
    REP --> MET
    REP --> DAS
    REP --> TEN
```

## 📡 Communication Protocols

### Message Structure

```json
{
  "messageId": "uuid-v4",
  "timestamp": "2024-01-01T12:00:00Z",
  "sender": {
    "membraneId": "cognitive-root",
    "containerId": "container-123"
  },
  "receiver": {
    "membraneId": "perception",
    "containerId": "container-456"
  },
  "messageType": "evolution_trigger|state_update|command|response",
  "priority": "high|medium|low",
  "payload": {
    "action": "process_image",
    "data": { ... },
    "metadata": { ... }
  },
  "routing": {
    "path": ["cognitive-root", "perception"],
    "ttl": 300,
    "retryCount": 0
  }
}
```

### Communication Modes

```mermaid
graph TB
    subgraph "Shared Volume Mode"
        SV1[Membrane A] --> SVM[Shared Volume]
        SVM --> SV2[Membrane B]
        SVM --> SV3[Membrane C]
    end
    
    subgraph "Network Mode"
        NM1[Membrane A] --> NMQ[Message Queue]
        NMQ --> NM2[Membrane B]
        NMQ --> NM3[Membrane C]
    end
    
    subgraph "IPC Mode"
        IM1[Membrane A] --> IPC[IPC Channel]
        IPC --> IM2[Membrane B]
        IPC --> IM3[Membrane C]
    end
```

### Routing Algorithm

```python
def route_message(message, membrane_hierarchy):
    """
    Route message through membrane hierarchy
    """
    sender = message.sender.membrane_id
    receiver = message.receiver.membrane_id
    
    # Find common ancestor
    sender_path = get_path_to_root(sender, membrane_hierarchy)
    receiver_path = get_path_to_root(receiver, membrane_hierarchy)
    
    common_ancestor = find_common_ancestor(sender_path, receiver_path)
    
    # Route up to common ancestor, then down to receiver
    route = []
    
    # Up phase: sender to common ancestor
    for membrane in reversed(sender_path[:sender_path.index(common_ancestor)]):
        route.append(membrane)
    
    # Add common ancestor
    route.append(common_ancestor)
    
    # Down phase: common ancestor to receiver
    receiver_descent = receiver_path[receiver_path.index(common_ancestor)+1:]
    route.extend(receiver_descent)
    
    return route
```

## ⚙️ Evolution Engine

### Rule Definition Language

Evolution rules are defined using a declarative syntax:

```scheme
;; File system evolution rule
(define-evolution-rule "file-processor"
  :trigger (file-created "/opt/membrane/inbox/*.json")
  :condition (lambda (event) 
               (> (file-size (event-file event)) 0))
  :action (lambda (event)
            (let ((data (parse-json (event-file event))))
              (send-message "processor" data)
              (log-activity "file-processed" (event-file event))))
  :priority high)

;; Network evolution rule  
(define-evolution-rule "message-responder"
  :trigger (message-received "process-request")
  :condition (lambda (message)
               (valid-request? (message-payload message)))
  :action (lambda (message)
            (let ((result (process-request (message-payload message))))
              (reply-to-sender message result)))
  :priority medium)

;; Timer evolution rule
(define-evolution-rule "heartbeat"
  :trigger (timer-expired "heartbeat" 30) ; 30 seconds
  :condition (lambda (timer)
               (membrane-active?))
  :action (lambda (timer)
            (send-status-update)
            (restart-timer "heartbeat" 30))
  :priority low)
```

### Rule Execution Engine

```mermaid
flowchart TB
    subgraph "Rule Engine"
        ET[Event Trigger]
        RM[Rule Matcher]
        PC[Precondition Check]
        RE[Rule Executor]
        PS[Post-processing]
    end
    
    subgraph "Event Types"
        FS[File System Events]
        NE[Network Events]
        TE[Timer Events]
        ME[Message Events]
        SE[State Events]
    end
    
    subgraph "Execution Context"
        EE[Execution Environment]
        RL[Resource Limits]
        ST[State Access]
        CM[Communication]
        LG[Logging]
    end
    
    FS --> ET
    NE --> ET
    TE --> ET
    ME --> ET
    SE --> ET
    
    ET --> RM
    RM --> PC
    PC --> RE
    RE --> PS
    
    RE --> EE
    RE --> RL
    RE --> ST
    RE --> CM
    RE --> LG
```

### Rule Priority & Scheduling

```mermaid
gantt
    title Rule Execution Scheduling
    dateFormat X
    axisFormat %L
    
    section High Priority
    File Processing    :crit, high1, 0, 100
    Emergency Response :crit, high2, 50, 150
    
    section Medium Priority
    Message Handling   :active, med1, 25, 175
    State Updates      :med2, 100, 200
    
    section Low Priority
    Heartbeat         :low1, 0, 300
    Cleanup Tasks     :low2, 200, 300
```

## 🎼 Orchestration System

### Docker Compose Generation

The orchestrator generates Docker Compose configurations from membrane hierarchy definitions:

```yaml
# Generated docker-compose.yml
version: '3.8'

services:
  cognitive-root:
    image: mcr.microsoft.com/devcontainers/base:ubuntu
    container_name: membrane-cognitive-root
    environment:
      - MEMBRANE_ID=cognitive-root
      - PARENT_MEMBRANE=
      - ENABLE_SCHEME=true
      - ENABLE_MONITORING=true
    volumes:
      - membrane-comm:/opt/membrane/communication
      - membrane-state:/opt/membrane/state
    networks:
      - membrane-net
    depends_on:
      - membrane-registry

  perception:
    image: mcr.microsoft.com/devcontainers/base:ubuntu
    container_name: membrane-perception
    environment:
      - MEMBRANE_ID=perception
      - PARENT_MEMBRANE=cognitive-root
      - ENABLE_SCHEME=true
    volumes:
      - membrane-comm:/opt/membrane/communication:ro
      - perception-state:/opt/membrane/state
    networks:
      - membrane-net
    depends_on:
      - cognitive-root

  visual-worker:
    image: mcr.microsoft.com/devcontainers/base:ubuntu
    container_name: membrane-visual-worker
    environment:
      - MEMBRANE_ID=visual-worker
      - PARENT_MEMBRANE=perception
      - ENABLE_SCHEME=false
    volumes:
      - membrane-comm:/opt/membrane/communication:ro
      - visual-data:/opt/membrane/data
    networks:
      - membrane-net
    depends_on:
      - perception
    deploy:
      replicas: 2
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

volumes:
  membrane-comm:
  membrane-state:
  perception-state:
  visual-data:

networks:
  membrane-net:
    driver: bridge
```

### Kubernetes Deployment

```yaml
# Generated kubernetes deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cognitive-root
  labels:
    app: membrane
    membrane-id: cognitive-root
spec:
  replicas: 1
  selector:
    matchLabels:
      app: membrane
      membrane-id: cognitive-root
  template:
    metadata:
      labels:
        app: membrane
        membrane-id: cognitive-root
    spec:
      containers:
      - name: membrane
        image: mcr.microsoft.com/devcontainers/base:ubuntu
        env:
        - name: MEMBRANE_ID
          value: "cognitive-root"
        - name: ENABLE_SCHEME
          value: "true"
        volumeMounts:
        - name: membrane-comm
          mountPath: /opt/membrane/communication
        - name: membrane-state
          mountPath: /opt/membrane/state
        resources:
          limits:
            memory: "1Gi"
            cpu: "500m"
          requests:
            memory: "512Mi"
            cpu: "250m"
      volumes:
      - name: membrane-comm
        persistentVolumeClaim:
          claimName: membrane-comm-pvc
      - name: membrane-state
        persistentVolumeClaim:
          claimName: membrane-state-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: cognitive-root-service
spec:
  selector:
    app: membrane
    membrane-id: cognitive-root
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
```

### Auto-scaling Logic

```mermaid
flowchart TD
    MON[Monitor Metrics] --> CHK{Check Thresholds}
    CHK -->|CPU > 80%| SCU[Scale Up]
    CHK -->|CPU < 20%| SCD[Scale Down]
    CHK -->|Memory > 85%| SCU
    CHK -->|Queue Length > 100| SCU
    CHK -->|All Low| SCD
    
    SCU --> CRE[Create New Instance]
    SCD --> REM[Remove Instance]
    
    CRE --> UPD[Update Configuration]
    REM --> UPD
    UPD --> MON
    
    style SCU fill:#e1f5fe
    style SCD fill:#fff3e0
    style CRE fill:#e8f5e8
    style REM fill:#ffebee
```

## 🔗 Integration Patterns

### ggml Tensor Integration

```mermaid
sequenceDiagram
    participant M as Membrane
    participant E as Evolution Engine
    participant T as Tensor Converter
    participant G as ggml Processing
    participant A as AI Application
    
    M->>E: Evolution Rule Triggered
    E->>T: Extract State Data
    T->>T: Convert to Tensor Format
    T->>G: Send Tensor Data
    G->>G: Process with Neural Network
    G->>A: Return Processed Results
    A->>M: Update Membrane State
    M->>E: Log Activity
```

### OpenCog AtomSpace Integration

```scheme
;; Membrane to AtomSpace mapping
(use-modules (opencog))

;; Define membrane as concept
(define membrane-concept
  (ConceptNode "membrane-cognitive-root"))

;; Map membrane state to atoms
(define (membrane-state->atomspace membrane-id state)
  (let ((membrane-atom (ConceptNode membrane-id)))
    ;; Create state predicates
    (EvaluationLink
      (PredicateNode "has-state")
      (ListLink
        membrane-atom
        (ConceptNode (format #f "~a" state))))
    
    ;; Create activity predicates
    (EvaluationLink
      (PredicateNode "activity-level")
      (ListLink
        membrane-atom
        (NumberNode (get-activity-level state))))
    
    ;; Create communication links
    (map (lambda (child)
           (InheritanceLink
             (ConceptNode child)
             membrane-atom))
         (get-child-membranes state))))

;; Evolution rule as ImplicationLink
(define evolution-rule-atom
  (ImplicationLink
    (AndLink
      (EvaluationLink
        (PredicateNode "file-created")
        (VariableNode "$file"))
      (EvaluationLink
        (PredicateNode "valid-json")
        (VariableNode "$file")))
    (ExecutionOutputLink
      (GroundedSchemaNode "scm:process-file")
      (VariableNode "$file"))))
```

## 📊 Performance & Scalability

### Performance Metrics

```mermaid
graph TB
    subgraph "Container Performance"
        CPU[CPU Utilization]
        MEM[Memory Usage]
        NET[Network Throughput]
        DIS[Disk I/O]
    end
    
    subgraph "Membrane Performance"
        MSG[Message Processing Rate]
        RUL[Rule Execution Time]
        STA[State Update Frequency]
        COM[Communication Latency]
    end
    
    subgraph "System Performance"
        THR[Overall Throughput]
        LAT[End-to-End Latency]
        SCA[Scalability Factor]
        REL[Reliability Score]
    end
    
    CPU --> MSG
    MEM --> RUL
    NET --> COM
    DIS --> STA
    
    MSG --> THR
    RUL --> LAT
    COM --> LAT
    STA --> REL
    
    THR --> SCA
    LAT --> SCA
    REL --> SCA
```

### Scalability Patterns

#### Horizontal Scaling

```mermaid
graph LR
    subgraph "Single Instance"
        M1[Membrane Instance 1]
    end
    
    subgraph "Load Balancer"
        LB[Load Balancer]
    end
    
    subgraph "Scaled Instances"
        M2[Membrane Instance 1]
        M3[Membrane Instance 2]
        M4[Membrane Instance 3]
        M5[Membrane Instance N]
    end
    
    M1 -->|Scale Out| LB
    LB --> M2
    LB --> M3
    LB --> M4
    LB --> M5
```

#### Vertical Scaling

```mermaid
graph TB
    subgraph "Resource Scaling"
        R1[CPU: 1 core → 4 cores]
        R2[Memory: 1GB → 8GB]
        R3[Network: 1Gbps → 10Gbps]
        R4[Storage: HDD → NVMe SSD]
    end
    
    subgraph "Performance Impact"
        P1[Faster Rule Execution]
        P2[Larger State Capacity]
        P3[Higher Message Throughput]
        P4[Faster State Persistence]
    end
    
    R1 --> P1
    R2 --> P2
    R3 --> P3
    R4 --> P4
```

### Optimization Strategies

1. **Message Batching**: Aggregate multiple small messages into larger batches
2. **Rule Caching**: Cache compiled evolution rules for faster execution
3. **State Compression**: Compress membrane state for efficient storage
4. **Connection Pooling**: Reuse network connections between membranes
5. **Lazy Loading**: Load components only when needed

## 🔒 Security Model

### Security Architecture

```mermaid
graph TB
    subgraph "Network Security"
        TLS[TLS Encryption]
        VPN[VPN Tunnels]
        FW[Firewall Rules]
    end
    
    subgraph "Container Security"
        ISO[Container Isolation]
        CAP[Capability Dropping]
        SEC[Security Contexts]
        SCA[Image Scanning]
    end
    
    subgraph "Application Security"
        AUTH[Authentication]
        AUTHZ[Authorization]
        AUD[Audit Logging]
        ENC[Data Encryption]
    end
    
    subgraph "Membrane Security"
        MID[Membrane Identity]
        MSG_SEC[Message Security]
        RUL_SEC[Rule Validation]
        STA_SEC[State Protection]
    end
    
    TLS --> MSG_SEC
    VPN --> MSG_SEC
    FW --> MSG_SEC
    
    ISO --> MID
    CAP --> RUL_SEC
    SEC --> STA_SEC
    SCA --> RUL_SEC
    
    AUTH --> MID
    AUTHZ --> MSG_SEC
    AUD --> RUL_SEC
    ENC --> STA_SEC
```

### Access Control Matrix

| Component | Read | Write | Execute | Admin |
|-----------|------|-------|---------|-------|
| Membrane State | Owner + Parent | Owner | Owner | Owner |
| Evolution Rules | Owner + Children | Owner | Owner | Owner |
| Communication | All Membranes | Sender | Receiver | Root |
| Configuration | Owner + Parent | Owner | Owner | Admin |
| Logs | Owner + Parent + Admin | System | System | Admin |

### Threat Model

```mermaid
graph TB
    subgraph "External Threats"
        EXT1[Network Attacks]
        EXT2[Container Escape]
        EXT3[Supply Chain]
    end
    
    subgraph "Internal Threats"
        INT1[Privilege Escalation]
        INT2[Data Exfiltration]
        INT3[Resource Exhaustion]
    end
    
    subgraph "Mitigation Strategies"
        MIT1[Network Segmentation]
        MIT2[Runtime Protection]
        MIT3[Image Verification]
        MIT4[RBAC + ABAC]
        MIT5[Encryption at Rest/Transit]
        MIT6[Resource Quotas]
    end
    
    EXT1 --> MIT1
    EXT2 --> MIT2
    EXT3 --> MIT3
    INT1 --> MIT4
    INT2 --> MIT5
    INT3 --> MIT6
```

## 📈 Monitoring & Observability

### Observability Stack

```mermaid
graph TB
    subgraph "Data Collection"
        MET[Metrics Collection]
        LOG[Log Aggregation]
        TRA[Distributed Tracing]
    end
    
    subgraph "Storage"
        PROM[Prometheus]
        ELK[ELK Stack]
        JAE[Jaeger]
    end
    
    subgraph "Visualization"
        GRAF[Grafana Dashboards]
        KIB[Kibana]
        JAE_UI[Jaeger UI]
    end
    
    subgraph "Alerting"
        ALERT[Alert Manager]
        HOOK[Webhooks]
        NOTIF[Notifications]
    end
    
    MET --> PROM
    LOG --> ELK
    TRA --> JAE
    
    PROM --> GRAF
    ELK --> KIB
    JAE --> JAE_UI
    
    PROM --> ALERT
    ALERT --> HOOK
    HOOK --> NOTIF
```

### Key Performance Indicators (KPIs)

```mermaid
graph LR
    subgraph "Membrane KPIs"
        A1[Message Processing Rate]
        A2[Rule Execution Time]
        A3[State Update Frequency]
        A4[Communication Latency]
    end
    
    subgraph "System KPIs"
        B1[Overall Throughput]
        B2[System Availability]
        B3[Resource Utilization]
        B4[Error Rate]
    end
    
    subgraph "Business KPIs"
        C1[Processing Accuracy]
        C2[Response Time SLA]
        C3[Cost per Transaction]
        C4[User Satisfaction]
    end
    
    A1 --> B1
    A2 --> B2
    A3 --> B3
    A4 --> B4
    
    B1 --> C1
    B2 --> C2
    B3 --> C3
    B4 --> C4
```

## 🚀 Deployment Patterns

### Blue-Green Deployment

```mermaid
graph TB
    subgraph "Load Balancer"
        LB[Load Balancer]
    end
    
    subgraph "Blue Environment (Current)"
        B1[Membrane Instance 1]
        B2[Membrane Instance 2]
        B3[Membrane Instance 3]
    end
    
    subgraph "Green Environment (New)"
        G1[Membrane Instance 1]
        G2[Membrane Instance 2]
        G3[Membrane Instance 3]
    end
    
    LB -->|100% Traffic| B1
    LB --> B2
    LB --> B3
    
    LB -.->|0% Traffic| G1
    LB -.-> G2
    LB -.-> G3
    
    style B1 fill:#e3f2fd
    style B2 fill:#e3f2fd
    style B3 fill:#e3f2fd
    style G1 fill:#e8f5e8
    style G2 fill:#e8f5e8
    style G3 fill:#e8f5e8
```

### Canary Deployment

```mermaid
graph TB
    subgraph "Traffic Split"
        LB[Load Balancer]
    end
    
    subgraph "Stable Version (90%)"
        S1[Membrane V1.0]
        S2[Membrane V1.0]
        S3[Membrane V1.0]
    end
    
    subgraph "Canary Version (10%)"
        C1[Membrane V1.1]
    end
    
    LB -->|90%| S1
    LB --> S2
    LB --> S3
    LB -->|10%| C1
    
    style S1 fill:#e3f2fd
    style S2 fill:#e3f2fd
    style S3 fill:#e3f2fd
    style C1 fill:#fff3e0
```

---

This architecture documentation provides a comprehensive technical foundation for understanding and implementing P-System Membrane Computing using container technologies. The modular design enables flexible deployment patterns while maintaining the theoretical rigor of membrane computing principles.