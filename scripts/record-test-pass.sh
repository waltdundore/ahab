#!/usr/bin/env bash
# Record successful test run

set -euo pipefail

STATUS_FILE=".test-status"
COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Update status file
cat > "$STATUS_FILE" << EOF
# Test Status Tracking
# Last passing test is the promotable version

LAST_TEST_DATE="$DATE"
LAST_TEST_STATUS="PASS"
LAST_TEST_COMMIT="$COMMIT"
LAST_PASSING_DATE="$DATE"
LAST_PASSING_COMMIT="$COMMIT"
PROMOTABLE_VERSION="$COMMIT"
EOF

echo "✓ Test status recorded: PASS"
echo "✓ Promotable version: $COMMIT"
