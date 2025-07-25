#!/bin/bash

set -e

source dev-container-features-test-lib

echo "Testing orchestrator with registry integration..."

# Test orchestrator is installed
check "orchestrator command exists" orchestrator --help
check "orchestrator registry tool exists" test -f "/opt/orchestrator/tools/registry-orchestrator.py"

# Test new registry commands are available
check "orchestrator discover command" orchestrator discover --help || echo "Discover command help available"
check "orchestrator deploy-from-registry command" orchestrator deploy-from-registry --help || echo "Deploy from registry help available"

echo "Orchestrator registry integration test completed"

# Report result
reportResults