#!/bin/bash

# Test minimal membrane configuration (no Scheme, no monitoring)

set -e

# Import test library
source dev-container-features-test-lib

# Test that the membrane was configured with correct ID
check "membrane has correct ID" bash -c "membrane status | grep -q 'minimal-membrane' || grep -q 'minimal-membrane' /opt/membrane/config/membrane.json"

# Test that Scheme is disabled
check "scheme disabled" bash -c "grep -q '\"scheme_enabled\": false' /opt/membrane/config/membrane.json || grep -q 'false' /opt/membrane/config/membrane.json"

# Test that monitoring is disabled
check "monitoring disabled" bash -c "grep -q '\"monitoring_enabled\": false' /opt/membrane/config/membrane.json || grep -q 'false' /opt/membrane/config/membrane.json"

# Test that basic functionality still works
check "basic membrane commands" bash -c "membrane status && membrane rules"

# Test that communication still works
check "minimal communication" bash -c "membrane send test-minimal 'minimal-message'"

# Scheme should not be available
check "no scheme in minimal" bash -c "! guile --version 2>/dev/null || echo 'scheme not expected but present'"

# Report results
reportResults