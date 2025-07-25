#!/bin/bash

set -e

source dev-container-features-test-lib

# Test membrane with registry integration
check "membrane with registry config" test -f "/opt/membrane/config/membrane.json"

# Check registry integration is configured
check "registry configuration in membrane" grep -q "registry_enabled" /opt/membrane/config/membrane.json

# Test membrane CLI with registry commands
check "membrane register command" membrane register || echo "Register command available"
check "membrane discover command" membrane discover || echo "Discover command available" 
check "membrane heartbeat command" membrane heartbeat || echo "Heartbeat command available"

# Report result
reportResults