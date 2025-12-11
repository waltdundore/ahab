#!/usr/bin/env bash
# ==============================================================================
# Color Definitions - DRY Single Source of Truth
# ==============================================================================
# Shared ANSI color codes for all scripts (tests, utilities, automation)
# Source this file instead of defining colors locally
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/colors.sh"
#   echo -e "${GREEN}Success!${NC}"
# ==============================================================================

# Only define if not already defined (allows re-sourcing safely)
if [ -z "${AHAB_COLORS_LOADED:-}" ]; then
    readonly AHAB_COLORS_LOADED=1
    
    # Standard colors
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly MAGENTA='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[1;37m'
    
    # Text formatting
    readonly BOLD='\033[1m'
    readonly DIM='\033[2m'
    readonly UNDERLINE='\033[4m'
    
    # Reset
    readonly NC='\033[0m'  # No Color
    
    # Semantic colors (for consistent meaning across scripts)
    readonly COLOR_SUCCESS="$GREEN"
    readonly COLOR_ERROR="$RED"
    readonly COLOR_WARNING="$YELLOW"
    readonly COLOR_INFO="$BLUE"
    readonly COLOR_DEBUG="$DIM"
fi
