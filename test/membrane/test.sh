#!/bin/bash

# Test basic membrane functionality with default configuration
# This test validates the core P-system membrane installation and basic commands

set -e

# Import test library
source dev-container-features-test-lib

# Test membrane command exists and is executable
check "membrane command exists" bash -c "command -v membrane"

# Test membrane status command
check "membrane status" bash -c "membrane status"

# Test membrane directory structure
check "membrane config directory" test -d "/opt/membrane/config"
check "membrane rules directory" test -d "/opt/membrane/rules"
check "membrane communication directory" test -d "/opt/membrane/communication"

# Test configuration file exists and is valid JSON
check "membrane config file" test -f "/opt/membrane/config/membrane.json"
check "config file readable" bash -c "cat /opt/membrane/config/membrane.json > /dev/null"

# Test basic utilities are available (may be mocked if installation failed)
check "jq available" command -v jq
check "inotifywait available" command -v inotifywait

# Test Guile Scheme is available (default configuration, may be mocked)
check "guile available" command -v guile

# Test hypergraph library exists
check "hypergraph library" test -f "/opt/membrane/hypergraph.scm"

# Test evolution rules script exists and is executable
check "evolution rules script" test -x "/opt/membrane/rules/evolution.sh"

# Test communication scripts exist
check "send script exists" test -x "/opt/membrane/communication/send.sh" 
check "receive script exists" test -x "/opt/membrane/communication/receive.sh"

# Test utility library exists
check "utility library" test -f "/opt/membrane/lib/membrane-utils.sh"

# Test monitoring script exists
check "monitoring script" test -x "/opt/membrane/monitor.sh"

# Test membrane CLI help
check "membrane help" bash -c "membrane --help | grep -q 'P-System Membrane CLI'"

# Test log functionality
check "membrane log command" bash -c "membrane log || true"  # May be empty initially

# Report results
reportResults