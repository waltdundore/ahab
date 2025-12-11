#!/usr/bin/env bash
# ==============================================================================
# Accountability Audit Script (NASA Rule #4 Compliant)
# ==============================================================================
# Self-auditing script that validates compliance with core principles
#
# Priority Order:
#   1. Human Empathy (above all else)
#   2. Core Principles (NASA, Idempotency, Simplicity, etc.)
#   3. Auditable Feedback (prove compliance)
#
# Usage:
#   ./scripts/audit-accountability.sh
#   make audit
#
# Exit Codes:
#   0 - All audits passed
#   1 - Violations found
# ==============================================================================

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=./lib/audit-common.sh
source "$SCRIPT_DIR/lib/audit-common.sh"

# Report file
TIMESTAMP=$(generate_audit_timestamp)
readonly REPORT_FILE="audit-report-${TIMESTAMP}.md"

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    print_header "ACCOUNTABILITY AUDIT"
    
    echo "Auditing compliance with core principles..."
    echo "Report will be saved to: $REPORT_FILE"
    echo ""
    
    # Run audit phases
    audit_self_compliance
    audit_human_empathy_phase
    audit_core_principles_phase
    audit_makefile_integration_phase
    
    # Generate final report
    generate_audit_summary "$REPORT_FILE"
}

#------------------------------------------------------------------------------
# Audit Phases (Orchestration)
#------------------------------------------------------------------------------

audit_self_compliance() {
    print_section "SELF-AUDIT: Validating This Script"
    
    local script_path="$0"
    
    audit_empathetic_language "$script_path"
    audit_error_handling "$script_path"
    audit_bounded_loops "$script_path"
    audit_documentation "$script_path"
    audit_makefile_integration "audit-accountability"
}

audit_human_empathy_phase() {
    print_section "PRIORITY 1: HUMAN EMPATHY AUDIT"
    
    audit_empathetic_error_messages
    audit_actionable_guidance
    audit_dismissive_language
}

audit_core_principles_phase() {
    print_section "PRIORITY 2: CORE PRINCIPLES AUDIT"
    
    audit_nasa_standards
    audit_idempotency
    audit_simplicity
    audit_documentation_standards
}

audit_makefile_integration_phase() {
    print_section "PRIORITY 3: MAKEFILE INTEGRATION AUDIT"
    
    echo "→ Checking critical scripts are integrated into Makefile..."
    
    local critical_scripts=(
        "validate-nasa-standards.sh"
        "audit-accountability.sh"
        "audit-dependencies.sh"
    )
    
    for script in "${critical_scripts[@]}"; do
        audit_makefile_integration "$script"
    done
}

#------------------------------------------------------------------------------
# Script Entry Point
#------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi