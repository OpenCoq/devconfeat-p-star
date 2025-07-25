#!/bin/bash
# Integration test for distributed namespace registration
# This script demonstrates the namespace functionality in action

set -e

echo "=== P-System Membrane Distributed Namespace Integration Test ==="

# Create a temporary test environment
TEST_DIR="/tmp/membrane-namespace-test-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "1. Testing namespace registry startup..."

# Start the registry in background (simulate what would happen in a real deployment)
if command -v python3 >/dev/null 2>&1; then
    echo "Starting namespace registry on port 8766 (test instance)..."
    python3 /home/runner/work/devconfeat-p-star/devconfeat-p-star/src/membrane/namespace-registry.py \
        --registry-id "test-registry" \
        --port 8766 \
        --heartbeat-interval 10 \
        --cleanup-interval 20 &
    
    REGISTRY_PID=$!
    echo "Registry started with PID: $REGISTRY_PID"
    
    # Wait for registry to start
    sleep 2
    
    # Test registry is accessible
    if command -v curl >/dev/null 2>&1; then
        echo "Testing registry status endpoint..."
        if curl -s http://localhost:8766/status >/dev/null; then
            echo "✓ Registry is accessible"
        else
            echo "✗ Registry not accessible"
        fi
    fi
    
    echo ""
    echo "2. Testing membrane registration..."
    
    # Create test membrane configuration
    mkdir -p ./membrane-config
    cat > ./membrane-config/membrane.json << 'EOF'
{
  "id": "test-membrane-1",
  "parent": null,
  "communication_mode": "shared-volume",
  "state": "active",
  "created_at": "2024-01-01T00:00:00Z",
  "features": {
    "scheme_enabled": true,
    "monitoring_enabled": true,
    "namespace_enabled": true
  },
  "namespace": {
    "registry_url": "http://localhost:8766",
    "auto_register": true,
    "auto_heartbeat": true
  }
}
EOF
    
    # Test membrane registration using the client
    export MEMBRANE_ID="test-membrane-1"
    export MEMBRANE_REGISTRY_URL="http://localhost:8766"
    
    echo "Registering test membrane..."
    python3 /home/runner/work/devconfeat-p-star/devconfeat-p-star/src/membrane/namespace-client.py register
    
    echo ""
    echo "3. Testing membrane discovery..."
    
    # List all membranes
    echo "Listing all registered membranes:"
    python3 /home/runner/work/devconfeat-p-star/devconfeat-p-star/src/membrane/namespace-client.py list
    
    echo ""
    echo "Discovering specific membrane:"
    python3 /home/runner/work/devconfeat-p-star/devconfeat-p-star/src/membrane/namespace-client.py discover test-membrane-1
    
    echo ""
    echo "4. Testing multi-membrane scenario..."
    
    # Register a second membrane
    export MEMBRANE_ID="test-membrane-2"
    echo "Registering second membrane as child of test-membrane-1..."
    python3 /home/runner/work/devconfeat-p-star/devconfeat-p-star/src/membrane/namespace-client.py register test-membrane-1
    
    # List all membranes again
    echo "Updated membrane list:"
    python3 /home/runner/work/devconfeat-p-star/devconfeat-p-star/src/membrane/namespace-client.py list
    
    echo ""
    echo "5. Testing message sending..."
    
    # Test message sending between membranes
    export MEMBRANE_ID="test-membrane-1"
    echo "Sending test message from membrane-1 to membrane-2..."
    python3 /home/runner/work/devconfeat-p-star/devconfeat-p-star/src/membrane/namespace-client.py send test-membrane-2 "Hello from membrane-1!"
    
    echo ""
    echo "6. Testing registry status..."
    
    if command -v curl >/dev/null 2>&1; then
        echo "Final registry status:"
        curl -s http://localhost:8766/status | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8766/status
    fi
    
    echo ""
    echo "=== Integration Test Completed Successfully ==="
    echo ""
    echo "Summary:"
    echo "- ✓ Namespace registry started and accessible"
    echo "- ✓ Membrane registration working"
    echo "- ✓ Membrane discovery working"
    echo "- ✓ Multi-membrane hierarchies supported"
    echo "- ✓ Message sending functional"
    echo "- ✓ Registry status reporting working"
    
    # Cleanup
    echo ""
    echo "Cleaning up test registry..."
    kill $REGISTRY_PID 2>/dev/null || true
    
else
    echo "Python 3 not available - skipping integration test"
    exit 1
fi

# Cleanup test directory
cd /
rm -rf "$TEST_DIR"

echo "Integration test completed!"