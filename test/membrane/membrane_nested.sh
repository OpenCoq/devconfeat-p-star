#!/bin/bash

# Test nested membrane configuration

set -e

# Import test library
source dev-container-features-test-lib

# Test that the membrane was configured with correct ID and parent
check "membrane has correct ID" bash -c "membrane status | grep -q 'child-membrane' || grep -q 'child-membrane' /opt/membrane/config/membrane.json"
check "membrane has correct parent" bash -c "membrane status | grep -q 'root-membrane' || grep -q 'root-membrane' /opt/membrane/config/membrane.json"

# Test communication mode is set correctly
check "communication mode" bash -c "membrane status | grep -q 'shared-volume' || grep -q 'shared-volume' /opt/membrane/config/membrane.json"

# Test that parent membrane ID can be retrieved
check "parent membrane access" bash -c "source /opt/membrane/lib/membrane-utils.sh && get_parent_membrane | grep -q 'root-membrane'"

# Test nested communication setup
check "nested communication" bash -c "membrane send root-membrane 'child-to-parent' && (ls /opt/membrane/communication/outbox/msg_root-membrane_*.json || ls /tmp/membrane_outbox/msg_root-membrane_*.json || test -d /opt/membrane/communication/outbox || test -d /tmp/membrane_outbox)"

# Report results
reportResults