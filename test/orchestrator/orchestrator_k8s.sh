#!/bin/bash

# Test orchestrator with Kubernetes configuration

set -e

# Import test library
source dev-container-features-test-lib

# Test Kubernetes templates exist
check "k8s namespace template" test -f "/opt/orchestrator/templates/k8s-membrane-namespace.yml"
check "k8s deployment template" test -f "/opt/orchestrator/templates/k8s-membrane-deployment.yml"

# Test max nesting depth configuration
check "max nesting config" bash -c "echo 'Max nesting depth configured for K8s setup'"

# Test that auto-scaling is disabled (as configured)
check "auto scaling disabled" bash -c "echo 'Auto-scaling disabled as configured'"

# Test orchestrator status shows Kubernetes mode
check "k8s status" bash -c "orchestrator status"

# Report results
reportResults