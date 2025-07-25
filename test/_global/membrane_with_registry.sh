#!/bin/bash

set -e

source dev-container-features-test-lib

echo "Testing P-System with distributed registry integration..."

# Test registry is installed and working
check "registry service available" registry status
check "registry command works" registry stats

# Test membrane is installed with registry integration
check "membrane available" membrane status
check "membrane registry integration" membrane discover

# Test that membrane can register with registry
# Start registry service first
registry start &
sleep 3

# Register membrane
check "membrane registration" membrane register

# Test discovery
check "membrane discovery" membrane discover

# Test heartbeat
check "membrane heartbeat" membrane heartbeat

echo "P-System distributed registry integration test completed"

# Report result
reportResults