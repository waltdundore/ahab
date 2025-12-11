#!/usr/bin/env bash
# Library file - sourced by tests, no cleanup needed
# ==============================================================================
# Test Configuration
# ==============================================================================
# Shared configuration for all tests
# NASA Rule 2: All timeouts are bounded
# ==============================================================================

# Timeouts (NASA Rule 2: Bounded loops)
readonly MAX_VM_START_TIME=900        # 15 minutes
readonly MAX_PROVISION_TIME=1800      # 30 minutes
readonly MAX_RETRY_ATTEMPTS=3         # Maximum retries
readonly MAX_WAIT_VM_READY=60         # 1 minute for VM to be ready
readonly MAX_WAIT_SERVICE=30          # 30 seconds for service to start

# Paths
readonly TEST_TEMP_DIR="/tmp/ahab-tests"
readonly TEST_LOG_DIR="$TEST_TEMP_DIR/logs"

# VM naming
readonly TEST_VM_PREFIX="ahab-test"

# Create temp directories if they don't exist
mkdir -p "$TEST_TEMP_DIR" 2>/dev/null || true
mkdir -p "$TEST_LOG_DIR" 2>/dev/null || true
