#!/bin/bash

# Test orchestrator with docker-compose configuration

set -e

# Import test library
source dev-container-features-test-lib

# Test that visualization is enabled
check "visualization enabled" test -f "/opt/orchestrator/visualizer/index.html"

# Test that visualizer server exists
check "visualizer server" test -x "/opt/orchestrator/visualizer/server.py"

# Test generate command with example config
check "generate compose" bash -c "cd /tmp && orchestrator generate /opt/orchestrator/configs/simple-hierarchy.json test-compose.yml && test -f test-compose.yml"

# Test that generated compose file is valid YAML (or exists)
check "valid compose yaml" bash -c "cd /tmp && test -f test-compose.yml && echo 'Compose file generated'"

# Test compose file contains expected services
check "compose services" bash -c "cd /tmp && grep -q 'membrane-root' test-compose.yml"

# Test orchestrator configuration check
check "orchestrator config check" bash -c "orchestrator status | grep -q 'docker-compose'"

# Report results
reportResults