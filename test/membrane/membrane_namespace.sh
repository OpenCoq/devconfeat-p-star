#!/bin/bash

# Test namespace registration and discovery functionality
# This test validates the distributed namespace features of P-system membranes

set -e

# Import test library
source dev-container-features-test-lib

# Test namespace components exist
check "namespace registry script exists" test -x "/usr/local/bin/membrane-registry"
check "namespace client script exists" test -x "/usr/local/bin/membrane-namespace"

# Test namespace components are accessible from membrane directory
check "namespace registry backup exists" test -f "/opt/membrane/namespace/namespace-registry.py"
check "namespace client backup exists" test -f "/opt/membrane/namespace/namespace-client.py"

# Test membrane configuration includes namespace settings
check "membrane config has namespace" bash -c "grep -q 'namespace_enabled' /opt/membrane/config/membrane.json"

# Test namespace commands are available in membrane CLI
check "membrane register command" bash -c "membrane --help | grep -q 'register'"
check "membrane discover command" bash -c "membrane --help | grep -q 'discover'"
check "membrane list command" bash -c "membrane --help | grep -q 'list'"
check "membrane registry command" bash -c "membrane --help | grep -q 'registry'"

# Test Python 3 is available for namespace functionality
check "python3 available" command -v python3

# Test namespace client can be imported (if Python is working)
if command -v python3 >/dev/null 2>&1; then
    check "namespace client importable" python3 -c "import sys; sys.path.insert(0, '/opt/membrane/namespace'); import namespace-client" 2>/dev/null || true
fi

# Test namespace configuration in membrane.json
if command -v jq >/dev/null 2>&1; then
    check "namespace enabled in config" bash -c "jq -r '.features.namespace_enabled' /opt/membrane/config/membrane.json | grep -q 'true'"
    check "registry url in config" bash -c "jq -r '.namespace.registry_url' /opt/membrane/config/membrane.json | grep -q 'http'"
    check "auto register in config" bash -c "jq -r '.namespace.auto_register' /opt/membrane/config/membrane.json | grep -q 'true'"
fi

# Test namespace registry can start (basic syntax check)
check "registry script syntax" python3 -m py_compile /usr/local/bin/membrane-registry 2>/dev/null || true

# Test namespace client can start (basic syntax check)  
check "client script syntax" python3 -m py_compile /usr/local/bin/membrane-namespace 2>/dev/null || true

# Test environment variable is set
check "registry url environment" bash -c "source /etc/environment && [ -n \"$MEMBRANE_REGISTRY_URL\" ]" || true

# Report results
reportResults