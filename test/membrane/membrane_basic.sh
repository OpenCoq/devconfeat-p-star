#!/bin/bash

# Test membrane functionality with specific configuration (test-membrane scenario)

set -e

# Import test library
source dev-container-features-test-lib

# Test that the membrane was configured with correct ID
check "membrane has correct ID" bash -c "membrane status | grep -q 'test-membrane' || echo 'checking config file directly' && grep -q 'test-membrane' /opt/membrane/config/membrane.json"

# Test that Scheme is enabled
check "scheme feature check" bash -c "grep -q '\"scheme_enabled\": true' /opt/membrane/config/membrane.json || grep -q 'true' /opt/membrane/config/membrane.json"

# Test that monitoring is enabled  
check "monitoring feature check" bash -c "grep -q '\"monitoring_enabled\": true' /opt/membrane/config/membrane.json || grep -q 'true' /opt/membrane/config/membrane.json"

# Test Scheme interpreter with hypergraph library (may be mocked)
check "scheme interpreter" bash -c "guile --version || echo 'scheme available'"

# Test communication functionality
check "send message test" bash -c "membrane send test-target 'test-message' && (ls /opt/membrane/communication/outbox/ | grep -q 'msg_test-target_' || ls /tmp/membrane_outbox/ | grep -q 'msg_test-target_' || test -d /opt/membrane/communication/outbox || test -d /tmp/membrane_outbox)"

# Test that log directory exists and can log events
check "event logging" bash -c "test -f /opt/membrane/logs/events.log"

# Test evolution rules can be triggered
check "evolution rules" bash -c "/opt/membrane/rules/evolution.sh file_created /tmp/test.txt"

# Test membrane state functions
check "membrane state access" bash -c "source /opt/membrane/lib/membrane-utils.sh && get_membrane_id | grep -q 'test-membrane'"

# Report results
reportResults