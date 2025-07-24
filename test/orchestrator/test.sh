#!/bin/bash

# Test basic orchestrator functionality

set -e

# Import test library
source dev-container-features-test-lib

# Test orchestrator command exists and is executable
check "orchestrator command exists" bash -c "command -v orchestrator"

# Test orchestrator directory structure
check "orchestrator config directory" test -d "/opt/orchestrator"
check "orchestrator templates directory" test -d "/opt/orchestrator/templates"
check "orchestrator tools directory" test -d "/opt/orchestrator/tools"

# Test Python dependencies are available (may be mocked)
check "python3 available" command -v python3

# Test Docker Compose template exists
check "compose template" test -f "/opt/orchestrator/templates/membrane-hierarchy.yml"

# Test Dockerfile template exists
check "dockerfile template" test -f "/opt/orchestrator/templates/Dockerfile.membrane"

# Test Python orchestrator tool exists
check "python orchestrator tool" test -x "/opt/orchestrator/tools/membrane-compose.py"

# Test example configuration exists
check "example config" test -f "/opt/orchestrator/configs/simple-hierarchy.json"

# Test orchestrator CLI help
check "orchestrator help" bash -c "orchestrator --help | grep -q 'P-System Membrane Orchestrator' || orchestrator | grep -q 'Commands:'"

# Test status command
check "orchestrator status" bash -c "orchestrator status"

# Test examples command
check "orchestrator examples" bash -c "orchestrator examples"

# Report results
reportResults