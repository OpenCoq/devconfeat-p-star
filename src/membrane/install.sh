#!/bin/bash
set -e

echo "Activating P-System Membrane Computing feature"

# Extract options
MEMBRANE_ID=${MEMBRANEID:-membrane-1}
PARENT_MEMBRANE=${PARENTMEMBRANE:-}
ENABLE_SCHEME=${ENABLESCHEME:-true}
ENABLE_MONITORING=${ENABLEMONITORING:-true}
COMMUNICATION_MODE=${COMMUNICATIONMODE:-shared-volume}
ENABLE_REGISTRY=${ENABLEREGISTRY:-false}
REGISTRY_URL=${REGISTRYURL:-http://localhost:8500}
NAMESPACE_ID=${NAMESPACEID:-default}

echo "Configuring membrane: $MEMBRANE_ID"
echo "Parent membrane: ${PARENT_MEMBRANE:-'(root)'}"
echo "Communication mode: $COMMUNICATION_MODE"
echo "Registry enabled: $ENABLE_REGISTRY"
echo "Registry URL: $REGISTRY_URL"

# Create membrane directory structure
mkdir -p /opt/membrane
mkdir -p /opt/membrane/config
mkdir -p /opt/membrane/rules
mkdir -p /opt/membrane/communication
mkdir -p /opt/membrane/state
mkdir -p /opt/membrane/logs

# Install required system packages
echo "Installing system packages..."
if apt-get update && apt-get install -y inotify-tools jq curl; then
    echo "Successfully installed system packages"
else
    echo "Warning: Failed to install some packages, using minimal setup"
    # Create dummy commands if packages are not available
    if ! command -v jq >/dev/null 2>&1; then
        cat > /usr/local/bin/jq << 'EOF'
#!/bin/bash
echo "jq not available - returning mock JSON"
echo '{"id": "mock", "status": "jq_unavailable"}'
EOF
        chmod +x /usr/local/bin/jq
    fi
    
    if ! command -v inotifywait >/dev/null 2>&1; then
        cat > /usr/local/bin/inotifywait << 'EOF'
#!/bin/bash
echo "inotifywait not available - monitoring disabled"
sleep infinity
EOF
        chmod +x /usr/local/bin/inotifywait
    fi
fi

# Install Scheme interpreter if enabled
if [ "$ENABLE_SCHEME" = "true" ]; then
    echo "Installing Guile Scheme interpreter..."
    if apt-get install -y guile-3.0 guile-3.0-dev; then
        echo "Guile installed successfully"
    else
        echo "Warning: Failed to install Guile, creating minimal Scheme setup"
        cat > /usr/local/bin/guile << 'EOF'
#!/bin/bash
echo "Guile Scheme not available - using minimal implementation"
echo "Guile mock interpreter ready"
EOF
        chmod +x /usr/local/bin/guile
    fi
    
    # Create basic hypergraph representation library
    cat > /opt/membrane/hypergraph.scm << 'EOF'
;;; Basic P-System Membrane Hypergraph Representation

(use-modules (ice-9 format))

;; Define membrane container node
(define (create-membrane-node membrane-id)
  `(EvaluationLink
     (PredicateNode "MembraneContainer")
     (ListLink (ConceptNode ,membrane-id))))

;; Define nesting relationship
(define (create-nesting-link child parent)
  `(InheritanceLink
     (ConceptNode ,child)
     (ConceptNode ,parent)))

;; Define evolution rule
(define (create-evolution-rule membrane-id action script)
  `(EvaluationLink
     (PredicateNode "EvolutionRule")
     (ListLink
       (ConceptNode ,membrane-id)
       (ConceptNode ,action)
       (ConceptNode ,script))))

;; Define communication rule
(define (create-communication-rule source target message)
  `(EvaluationLink
     (PredicateNode "CommunicationRule")
     (ListLink
       (ConceptNode ,source)
       (ConceptNode ,target)
       (ConceptNode ,message))))

;; Export membrane state to JSON
(define (membrane-to-json membrane-id parent-id)
  (format #t "{\"id\": \"~a\", \"parent\": \"~a\", \"timestamp\": \"~a\"}\n"
          membrane-id 
          (if (string=? parent-id "") "null" parent-id)
          (current-time)))

(display "P-System Hypergraph Library Loaded\n")
EOF

    chmod +x /opt/membrane/hypergraph.scm
fi

# Create membrane configuration
cat > /opt/membrane/config/membrane.json << EOF
{
  "id": "$MEMBRANE_ID",
  "parent": "${PARENT_MEMBRANE:-null}",
  "communication_mode": "$COMMUNICATION_MODE",
  "state": "active",
  "created_at": "$(date -Iseconds)",
  "features": {
    "scheme_enabled": $ENABLE_SCHEME,
    "monitoring_enabled": $ENABLE_MONITORING,
    "registry_enabled": $ENABLE_REGISTRY
  },
  "registry": {
    "enabled": $ENABLE_REGISTRY,
    "url": "$REGISTRY_URL",
    "namespace_id": "$NAMESPACE_ID",
    "registered": false
  }
}
EOF

# Create basic evolution rules
cat > /opt/membrane/rules/evolution.sh << 'EOF'
#!/bin/bash
# Basic evolution rule engine for P-System membranes

source /opt/membrane/lib/membrane-utils.sh

# Rule: On file creation in /tmp, log event
handle_file_creation() {
    local file="$1"
    log_event "file_created" "$file"
    
    # Example evolution: create response file
    echo "Response to: $(basename "$file")" > "/opt/membrane/state/response_$(date +%s).txt"
}

# Rule: On external signal, trigger action
handle_signal() {
    local signal="$1"
    log_event "signal_received" "$signal"
    
    case "$signal" in
        "division")
            log_event "membrane_division" "triggered"
            ;;
        "communication")
            log_event "communication_request" "received"
            ;;
    esac
}

# Main rule processing
case "${1:-}" in
    "file_created")
        handle_file_creation "$2"
        ;;
    "signal")
        handle_signal "$2"
        ;;
    *)
        echo "Unknown rule trigger: $1"
        ;;
esac
EOF

chmod +x /opt/membrane/rules/evolution.sh

# Create communication utilities
cat > /opt/membrane/communication/send.sh << 'EOF'
#!/bin/bash
# Send message to another membrane

TARGET_MEMBRANE="$1"
MESSAGE="$2"
COMMUNICATION_MODE="${3:-shared-volume}"

if [ -z "$TARGET_MEMBRANE" ] || [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <target_membrane> <message> [communication_mode]"
    exit 1
fi

case "$COMMUNICATION_MODE" in
    "shared-volume")
        if mkdir -p "/opt/membrane/communication/outbox" 2>/dev/null; then
            echo "$MESSAGE" > "/opt/membrane/communication/outbox/msg_${TARGET_MEMBRANE}_$(date +%s).json"
        else
            echo "Warning: Cannot create outbox directory, using /tmp"
            mkdir -p "/tmp/membrane_outbox"
            echo "$MESSAGE" > "/tmp/membrane_outbox/msg_${TARGET_MEMBRANE}_$(date +%s).json"
        fi
        ;;
    "network")
        # Placeholder for network communication
        echo "Network communication not yet implemented"
        ;;
    "ipc")
        # Placeholder for IPC communication  
        echo "IPC communication not yet implemented"
        ;;
esac

echo "Message sent to $TARGET_MEMBRANE via $COMMUNICATION_MODE"
EOF

chmod +x /opt/membrane/communication/send.sh

cat > /opt/membrane/communication/receive.sh << 'EOF'
#!/bin/bash
# Receive messages from other membranes

COMMUNICATION_MODE="${1:-shared-volume}"

case "$COMMUNICATION_MODE" in
    "shared-volume")
        if [ -d "/opt/membrane/communication/inbox" ]; then
            for msg_file in /opt/membrane/communication/inbox/msg_*.json; do
                if [ -f "$msg_file" ]; then
                    echo "Received message: $(cat "$msg_file")"
                    rm "$msg_file"
                fi
            done
        fi
        ;;
    *)
        echo "Communication mode $COMMUNICATION_MODE not implemented"
        ;;
esac
EOF

chmod +x /opt/membrane/communication/receive.sh

# Initialize membrane state - create lib directory first
mkdir -p /opt/membrane/lib

# Create utility library
cat > /opt/membrane/lib/membrane-utils.sh << 'EOF'
#!/bin/bash
# Membrane utility functions

get_membrane_id() {
    if command -v jq >/dev/null 2>&1; then
        jq -r '.id' /opt/membrane/config/membrane.json 2>/dev/null || echo "unknown"
    else
        grep '"id"' /opt/membrane/config/membrane.json 2>/dev/null | cut -d'"' -f4 || echo "unknown"
    fi
}

get_parent_membrane() {
    if command -v jq >/dev/null 2>&1; then
        jq -r '.parent' /opt/membrane/config/membrane.json 2>/dev/null || echo "null"
    else
        grep '"parent"' /opt/membrane/config/membrane.json 2>/dev/null | cut -d'"' -f4 || echo "null"
    fi
}

log_event() {
    local event_type="$1"
    local event_data="$2"
    local timestamp=$(date -Iseconds 2>/dev/null || date)
    local membrane_id=$(get_membrane_id)
    
    echo "{\"timestamp\": \"$timestamp\", \"membrane\": \"$membrane_id\", \"event\": \"$event_type\", \"data\": \"$event_data\"}" >> /opt/membrane/logs/events.log
}

get_membrane_state() {
    cat /opt/membrane/config/membrane.json 2>/dev/null || echo "{}"
}

update_membrane_state() {
    local key="$1"
    local value="$2"
    
    if command -v jq >/dev/null 2>&1; then
        jq ".$key = \"$value\"" /opt/membrane/config/membrane.json > /tmp/membrane_config.tmp 2>/dev/null
        mv /tmp/membrane_config.tmp /opt/membrane/config/membrane.json 2>/dev/null
    else
        echo "State update requires jq - update not performed"
    fi
}

# Registry integration functions
is_registry_enabled() {
    if command -v jq >/dev/null 2>&1; then
        jq -r '.registry.enabled' /opt/membrane/config/membrane.json 2>/dev/null | grep -q "true"
    else
        grep -q '"enabled": true' /opt/membrane/config/membrane.json 2>/dev/null
    fi
}

get_registry_url() {
    if command -v jq >/dev/null 2>&1; then
        jq -r '.registry.url' /opt/membrane/config/membrane.json 2>/dev/null || echo "http://localhost:8500"
    else
        grep '"url"' /opt/membrane/config/membrane.json 2>/dev/null | cut -d'"' -f4 || echo "http://localhost:8500"
    fi
}

get_namespace_id() {
    if command -v jq >/dev/null 2>&1; then
        jq -r '.registry.namespace_id' /opt/membrane/config/membrane.json 2>/dev/null || echo "default"
    else
        grep '"namespace_id"' /opt/membrane/config/membrane.json 2>/dev/null | cut -d'"' -f4 || echo "default"
    fi
}

register_with_registry() {
    if ! is_registry_enabled; then
        return 0
    fi
    
    local registry_url=$(get_registry_url)
    local namespace_id=$(get_namespace_id)
    local membrane_id=$(get_membrane_id)
    local parent_membrane=$(get_parent_membrane)
    local host=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    local registration_data="{
    \"namespace_id\": \"$namespace_id\",
    \"membrane_id\": \"$membrane_id\",
    \"host\": \"$host\",
    \"parent_membrane\": $(if [ "$parent_membrane" = "null" ]; then echo "null"; else echo "\"$parent_membrane\""; fi),
    \"capabilities\": [\"p-system\", \"membrane-computing\"],
    \"metadata\": {
        \"started_at\": \"$(date -Iseconds)\",
        \"version\": \"1.0.0\"
    }
}"
    
    if command -v curl >/dev/null 2>&1; then
        local response=$(curl -s -X POST "$registry_url/api/membranes/register" \
                        -H "Content-Type: application/json" \
                        -d "$registration_data" 2>/dev/null)
        
        if echo "$response" | grep -q "registered"; then
            log_event "registry_registration" "success"
            update_membrane_state "registry.registered" "true"
            return 0
        else
            log_event "registry_registration" "failed: $response"
            return 1
        fi
    else
        log_event "registry_registration" "failed: curl not available"
        return 1
    fi
}

send_heartbeat() {
    if ! is_registry_enabled; then
        return 0
    fi
    
    local registry_url=$(get_registry_url)
    local membrane_id=$(get_membrane_id)
    
    if command -v curl >/dev/null 2>&1; then
        curl -s -X POST "$registry_url/api/membranes/$membrane_id/heartbeat" >/dev/null 2>&1
        log_event "registry_heartbeat" "sent"
    fi
}

discover_membranes() {
    if ! is_registry_enabled; then
        echo "Registry not enabled"
        return 1
    fi
    
    local registry_url=$(get_registry_url)
    local namespace_id=$(get_namespace_id)
    
    if command -v curl >/dev/null 2>&1; then
        curl -s "$registry_url/api/membranes/discover?namespace_id=$namespace_id" 2>/dev/null
    else
        echo "curl not available for discovery"
        return 1
    fi
}
EOF

# Create monitoring service if enabled
if [ "$ENABLE_MONITORING" = "true" ]; then
    cat > /opt/membrane/monitor.sh << 'EOF'
#!/bin/bash
# Membrane monitoring and event processing service

source /opt/membrane/lib/membrane-utils.sh

echo "Starting membrane monitoring service for $(get_membrane_id)"

# Register with registry if enabled
register_with_registry

# Start heartbeat task in background if registry is enabled
if is_registry_enabled; then
    (
        while true; do
            send_heartbeat
            sleep 30  # Send heartbeat every 30 seconds
        done
    ) &
fi

# Monitor file system changes
monitor_filesystem() {
    inotifywait -m -r /tmp --format '%w%f %e' |
    while read file event; do
        case "$event" in
            "CREATE")
                /opt/membrane/rules/evolution.sh "file_created" "$file"
                ;;
        esac
    done &
}

# Monitor communication directory
monitor_communication() {
    if [ -d "/opt/membrane/communication/inbox" ]; then
        inotifywait -m /opt/membrane/communication/inbox --format '%f %e' |
        while read file event; do
            if [[ "$event" == "CREATE" && "$file" == msg_*.json ]]; then
                /opt/membrane/communication/receive.sh
            fi
        done &
    fi
}

# Start monitoring
monitor_filesystem
monitor_communication

# Keep the script running
wait
EOF

    chmod +x /opt/membrane/monitor.sh
fi

# Create membrane command-line interface
cat > /usr/local/bin/membrane << 'EOF'
#!/bin/bash
# Membrane P-System CLI

case "${1:-}" in
    "status")
        echo "Membrane Status:"
        if command -v jq >/dev/null 2>&1 && [ -f /opt/membrane/config/membrane.json ]; then
            cat /opt/membrane/config/membrane.json | jq .
        else
            cat /opt/membrane/config/membrane.json 2>/dev/null || echo "Configuration file not found"
        fi
        ;;
    "send")
        /opt/membrane/communication/send.sh "$2" "$3" "$4"
        ;;
    "receive")
        /opt/membrane/communication/receive.sh "$2"
        ;;
    "log")
        echo "Recent membrane events:"
        if command -v jq >/dev/null 2>&1; then
            tail -n 10 /opt/membrane/logs/events.log 2>/dev/null | jq . || echo "No events logged yet"
        else
            tail -n 10 /opt/membrane/logs/events.log 2>/dev/null || echo "No events logged yet"
        fi
        ;;
    "rules")
        echo "Available evolution rules:"
        ls -la /opt/membrane/rules/ 2>/dev/null || echo "Rules directory not found"
        ;;
    "monitor")
        if [ "$2" = "start" ]; then
            /opt/membrane/monitor.sh &
            echo "Monitoring started"
        else
            echo "Use: membrane monitor start"
        fi
        ;;
    "scheme")
        if command -v guile >/dev/null 2>&1; then
            guile -l /opt/membrane/hypergraph.scm 2>/dev/null || guile
        else
            echo "Scheme interpreter not available"
        fi
        ;;
    "register")
        source /opt/membrane/lib/membrane-utils.sh
        register_with_registry
        ;;
    "heartbeat")
        source /opt/membrane/lib/membrane-utils.sh
        send_heartbeat
        ;;
    "discover")
        source /opt/membrane/lib/membrane-utils.sh
        echo "Discovering membranes in namespace:"
        discover_membranes | jq . 2>/dev/null || discover_membranes
        ;;
    *)
        echo "P-System Membrane CLI"
        echo "Commands:"
        echo "  status                    - Show membrane status"
        echo "  send <target> <message>   - Send message to target membrane"
        echo "  receive                   - Check for incoming messages"  
        echo "  log                       - Show recent events"
        echo "  rules                     - List evolution rules"
        echo "  monitor start             - Start monitoring service"
        echo "  scheme                    - Start Scheme interpreter"
        echo ""
        echo "Registry Commands:"
        echo "  register                  - Register with distributed registry"
        echo "  heartbeat                 - Send heartbeat to registry"
        echo "  discover                  - Discover other membranes in namespace"
        ;;
esac
EOF

chmod +x /usr/local/bin/membrane

# Source the utility library and log initialization
source /opt/membrane/lib/membrane-utils.sh
log_event "membrane_initialized" "$MEMBRANE_ID"

echo "P-System Membrane feature installation completed"
echo "Membrane ID: $MEMBRANE_ID"
echo "Use 'membrane status' to check configuration"
echo "Use 'membrane --help' for available commands"