#!/usr/bin/env bash
# milestone-not-implemented.sh — loud-fail for unimplemented pipeline steps
#
# The 8-step deployment pipeline (see scripts/milestone-status.sh, which
# reports all 8) is only partially built today: milestone-1 and
# milestone-status are implemented. Steps 2-8 and the reset command are not.
#
# Rather than point at scripts that do not exist (which fails with a
# confusing "No such file or directory"), the corresponding Makefile targets
# call this helper so they fail LOUDLY and name the gap (BLUEPRINT law 11 /
# D-39: a command may only report what it just proved; no fabricated success).
#
# Usage: milestone-not-implemented.sh <step-number> <step-name>
set -euo pipefail

step="${1:-?}"
name="${2:-unknown}"

echo "=========================================="
echo "Milestone ${step} (${name}): NOT IMPLEMENTED"
echo "=========================================="
echo ""
echo "The 8-step deployment pipeline is only partially built today."
echo "Implemented: milestone-1 (workstation verification), milestone-status."
echo ""
echo "To implement this step:"
echo "  1. Write scripts/milestone-${step}-<verb>.sh"
echo "  2. Point the 'milestone-${step}' Makefile target at it"
echo ""
echo "See 'make milestone-status' for the full pipeline overview."
echo ""
exit 1
