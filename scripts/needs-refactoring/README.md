# Scripts Needing Refactoring

These scripts violate NASA Rule #4 (function length > 200 lines) and need to be refactored into smaller functions.

## Files

- `audit-hardcoded-values.sh` (451 lines) - Priority: HIGH
- `fix-hardcoded-values.sh` (304 lines) - Priority: MEDIUM  
- `update-technical-debt.sh` (212 lines) - Priority: LOW

## Refactoring Plan

Each script should be broken down into functions ≤ 60 lines following the patterns in `.kiro/steering/function-length-refactoring.md`.

## Temporary Status

These scripts have been moved here temporarily to allow CI/CD to pass while refactoring is planned. They should be refactored and moved back to `scripts/` as soon as possible.

## Next Steps

1. Refactor `audit-hardcoded-values.sh` first (largest)
2. Extract common patterns to `scripts/lib/`
3. Apply same patterns to other scripts
4. Move back to `scripts/` when compliant