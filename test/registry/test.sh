#!/bin/bash

set -e

# The 'test/_global' folder is a special test folder that is not tied to a single feature.
#
# This folder can contain additional tests, one common use case is to test user scenarios or
# integration tests that utilize multiple features.

source dev-container-features-test-lib

# Registry basic functionality test
check "registry command exists" registry --help
check "registry config exists" test -f "/opt/registry/config/registry.json"
check "registry database schema" test -f "/opt/registry/lib/schema.sql"
check "registry service script" test -f "/opt/registry/api/registry_service.py"
check "registry client library" test -f "/opt/registry/lib/registry_client.py"

# Web UI test
check "registry web ui" test -f "/opt/registry/web/index.html"

# Start registry service in background
registry start &
sleep 5

# Test basic health check
check "registry health check" curl -f http://localhost:8500/health

# Test API endpoints
check "registry stats endpoint" curl -f http://localhost:8500/api/stats
check "registry namespaces endpoint" curl -f http://localhost:8500/api/namespaces

# Test namespace creation
check "create test namespace" curl -X POST http://localhost:8500/api/namespaces \
  -H "Content-Type: application/json" \
  -d '{"name": "test-namespace", "description": "Test namespace"}' \
  -f

# Report result
reportResults