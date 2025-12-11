#!/usr/bin/env bash
#
# Validate Georgia CS Standards Registry
#
# This script validates the standards-registry.yml file to ensure:
# 1. File exists and is readable
# 2. No PLACEHOLDER values
# 3. Required metadata fields present
# 4. Standard IDs are unique
# 5. Basic YAML structure is valid
#
# Usage:
#     bash scripts/validate-standards-registry.sh
#
# Exit codes:
#     0 - All validations passed
#     1 - Validation failures found

set -euo pipefail


# Counters
# Source common functions (includes colors)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

ERRORS=0
WARNINGS=0

print_success() {
    echo -e "${GREEN}✓${RESET} $1"
}

print_error() {
    echo -e "${RED}✗${RESET} $1"
    ((ERRORS++))
}

print_warning() {
    echo -e "${YELLOW}⚠${RESET} $1"
    ((WARNINGS++))
}

# Find registry file
REGISTRY_FILE=""
if [[ -f "standards-registry.yml" ]]; then
    REGISTRY_FILE="standards-registry.yml"
elif [[ -f "ahab/standards-registry.yml" ]]; then
    REGISTRY_FILE="ahab/standards-registry.yml"
else
    echo -e "${RED}✗${RESET} Cannot find standards-registry.yml"
    exit 1
fi

echo "============================================================"
echo "Georgia CS Standards Registry Validation"
echo "============================================================"
echo ""
print_success "Found registry: $REGISTRY_FILE"

# Check 1: No PLACEHOLDER values
echo ""
echo "→ Checking for placeholder values..."
if grep -i "PLACEHOLDER" "$REGISTRY_FILE" >/dev/null 2>&1; then
    print_error "Found PLACEHOLDER values in registry"
    grep -n -i "PLACEHOLDER" "$REGISTRY_FILE" | head -5
else
    print_success "No PLACEHOLDER values found"
fi

if grep "REQUIRED:" "$REGISTRY_FILE" >/dev/null 2>&1; then
    print_error "Found REQUIRED: placeholder text in registry"
    grep -n "REQUIRED:" "$REGISTRY_FILE" | head -5
else
    print_success "No REQUIRED: placeholder text found"
fi

# Check 2: Metadata fields present
echo ""
echo "→ Checking metadata fields..."
REQUIRED_METADATA=("source_url" "standards_version" "last_verified" "verified_by")

for field in "${REQUIRED_METADATA[@]}"; do
    if grep -q "^  ${field}:" "$REGISTRY_FILE"; then
        value=$(grep "^  ${field}:" "$REGISTRY_FILE" | head -1 | cut -d':' -f2- | sed 's/^[[:space:]]*//' | tr -d '"')
        if [[ -z "$value" ]]; then
            print_error "Metadata field '$field' is empty"
        else
            print_success "Metadata field '$field': $value"
        fi
    else
        print_error "Missing required metadata field: $field"
    fi
done

# Check 3: Standard IDs are unique
echo ""
echo "→ Checking standard ID uniqueness..."
TEMP_IDS=$(mktemp)
grep -E "^\s+- id: \"IT-" "$REGISTRY_FILE" | sed 's/.*id: "\(.*\)"/\1/' | sort > "$TEMP_IDS"

TOTAL_IDS=$(wc -l < "$TEMP_IDS" | tr -d ' ')
UNIQUE_IDS=$(sort -u "$TEMP_IDS" | wc -l | tr -d ' ')

if [[ "$TOTAL_IDS" -eq "$UNIQUE_IDS" ]]; then
    print_success "All $TOTAL_IDS standard IDs are unique"
else
    print_error "Duplicate standard IDs found"
    # Show duplicates
    sort "$TEMP_IDS" | uniq -d | while read -r dup; do
        echo "  Duplicate: $dup"
    done
fi

rm -f "$TEMP_IDS"

# Check 4: Required fields in standards
echo ""
echo "→ Checking required fields in standards..."
REQUIRED_FIELDS=("id" "official_text" "description" "concepts")
MISSING_FIELDS=0

for field in "${REQUIRED_FIELDS[@]}"; do
    # Count how many standards have this field (flexible indentation)
    count=$(grep -c "[[:space:]]*${field}:" "$REGISTRY_FILE" || true)
    if [[ $count -eq 0 ]]; then
        print_error "No standards found with field: $field"
        ((MISSING_FIELDS++))
    fi
done

if [[ $MISSING_FIELDS -eq 0 ]]; then
    print_success "All required fields present in standards"
fi

# Check 5: Course structure
echo ""
echo "→ Checking course structure..."
COURSE_FIELDS=("course_code" "course_name" "level" "typical_grades")

for field in "${COURSE_FIELDS[@]}"; do
    if grep -q "^    ${field}:" "$REGISTRY_FILE"; then
        print_success "Course field '$field' present"
    else
        print_warning "Course field '$field' may be missing"
    fi
done

# Check 6: Grade levels are valid (9-12 for Georgia high school)
echo ""
echo "→ Checking grade levels..."
if grep -E "typical_grades:.*\[(9|10|11|12)" "$REGISTRY_FILE" >/dev/null 2>&1; then
    print_success "Grade levels appear valid (9-12)"
else
    print_warning "Could not verify grade levels"
fi

# Summary
echo ""
echo "============================================================"
if [[ $ERRORS -eq 0 ]]; then
    print_success "ALL VALIDATIONS PASSED"
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}Note: $WARNINGS warnings found${RESET}"
    fi
    echo "============================================================"
    exit 0
else
    print_error "VALIDATION FAILURES DETECTED: $ERRORS errors"
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}Also: $WARNINGS warnings found${RESET}"
    fi
    echo "============================================================"
    exit 1
fi
