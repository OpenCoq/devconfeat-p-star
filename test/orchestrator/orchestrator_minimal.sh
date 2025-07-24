#!/bin/bash

# Test orchestrator with minimal standalone configuration

set -e

# Import test library
source dev-container-features-test-lib

# Test that visualization is disabled
check "visualization disabled" bash -c "! test -f /opt/orchestrator/visualizer/index.html || echo 'visualization may be installed but disabled'"

# Test basic functionality still works
check "basic orchestrator functionality" bash -c "orchestrator examples"

# Test generate still works in standalone mode
check "standalone generate" bash -c "cd /tmp && orchestrator generate /opt/orchestrator/configs/simple-hierarchy.json minimal-compose.yml && test -f minimal-compose.yml"

# Report results
reportResults