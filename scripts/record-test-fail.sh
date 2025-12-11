#!/usr/bin/env bash
# Record failed test run

set -euo pipefail

STATUS_FILE=".test-status"
COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Load previous passing version
LAST_PASSING_COMMIT="unknown"
LAST_PASSING_DATE="never"
if [ -f "$STATUS_FILE" ]; then
    # shellcheck source=/dev/null
    source "$STATUS_FILE" 2>/dev/null || true
fi

# Update status file - keep last passing version
cat > "$STATUS_FILE" << EOF
# Test Status Tracking
# Last passing test is the promotable version

LAST_TEST_DATE="$DATE"
LAST_TEST_STATUS="FAIL"
LAST_TEST_COMMIT="$COMMIT"
LAST_PASSING_DATE="$LAST_PASSING_DATE"
LAST_PASSING_COMMIT="$LAST_PASSING_COMMIT"
PROMOTABLE_VERSION="$LAST_PASSING_COMMIT"
EOF

echo "✗ Test status recorded: FAIL"
echo "✓ Promotable version remains: $LAST_PASSING_COMMIT"
