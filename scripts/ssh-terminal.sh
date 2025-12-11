#!/usr/bin/env bash
# ==============================================================================
# SSH Terminal Launcher
# ==============================================================================
# Opens a new terminal window and SSHs into a Vagrant VM as root
#
# Platform Support:
#   - macOS: Uses Terminal.app (via osascript)
#   - Linux: Uses gnome-terminal, xterm, or konsole (auto-detected)
#
# Usage:
#   ./ssh-terminal.sh <vm-name> [vagrantfile]
#
# Arguments:
#   vm-name      - Name of the VM (required)
#                  Examples: "default", "fedora", "debian"
#   vagrantfile  - Path to Vagrantfile (optional)
#                  Examples: "Vagrantfile.multi"
#                  Default: Uses default Vagrantfile
#
# Examples:
#   ./ssh-terminal.sh default
#   ./ssh-terminal.sh fedora Vagrantfile.multi
#   ./ssh-terminal.sh debian Vagrantfile.multi
#
# Exit Codes:
#   0 - Success
#   1 - Error (missing arguments, unsupported platform, no terminal found)
#
# ==============================================================================

# Exit on any error
set -e

#------------------------------------------------------------------------------
# Parse Arguments
#------------------------------------------------------------------------------
VM_NAME="$1"
VAGRANTFILE="${2:-}"
WORK_DIR="$(pwd)"

# Validate required arguments
if [ -z "$VM_NAME" ]; then
    echo "Error: VM name required"
    echo ""
    echo "Usage: $0 <vm-name> [vagrantfile]"
    echo ""
    echo "Examples:"
    echo "  $0 default"
    echo "  $0 fedora Vagrantfile.multi"
    exit 1
fi

# Validate VM name format (security: prevent command injection)
# Only allow alphanumeric characters, hyphens, and underscores
if ! [[ "$VM_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Invalid VM name format"
    echo ""
    echo "VM name must contain only:"
    echo "  - Letters (a-z, A-Z)"
    echo "  - Numbers (0-9)"
    echo "  - Hyphens (-)"
    echo "  - Underscores (_)"
    echo ""
    echo "Invalid name: $VM_NAME"
    exit 1
fi

#------------------------------------------------------------------------------
# Build Vagrant SSH Command
#------------------------------------------------------------------------------
# Validate VM name to prevent command injection
# Only allow alphanumeric characters, hyphens, and underscores
if ! [[ "$VM_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Invalid VM name. Use only letters, numbers, hyphens, and underscores."
    exit 1
fi

# Build the command to SSH into the VM as root
# Uses VAGRANT_VAGRANTFILE environment variable if custom Vagrantfile specified
if [ -n "$VAGRANTFILE" ]; then
    VAGRANT_CMD="cd '$WORK_DIR' && VAGRANT_VAGRANTFILE='$VAGRANTFILE' vagrant ssh '$VM_NAME' -c 'sudo -E -s su'"
else
    VAGRANT_CMD="cd '$WORK_DIR' && vagrant ssh '$VM_NAME' -c 'sudo -E -s su'"
fi

#------------------------------------------------------------------------------
# Platform Detection and Terminal Launch
#------------------------------------------------------------------------------
# Detect the operating system and launch appropriate terminal emulator
case "$(uname -s)" in
    Darwin)
        # macOS - use Terminal.app via AppleScript
        # Opens a new Terminal window and runs the SSH command
        osascript -e "tell application \"Terminal\" to do script \"$VAGRANT_CMD\""
        ;;
    
    Linux)
        # Linux - try common terminal emulators in order of preference
        
        # Try gnome-terminal (GNOME desktop environment)
        if command -v gnome-terminal >/dev/null 2>&1; then
            gnome-terminal -- bash -c "${VAGRANT_CMD}; exec bash"
        
        # Try xterm (universal fallback, usually available)
        elif command -v xterm >/dev/null 2>&1; then
            xterm -e bash -c "${VAGRANT_CMD}; exec bash" &
        
        # Try konsole (KDE desktop environment)
        elif command -v konsole >/dev/null 2>&1; then
            konsole -e bash -c "${VAGRANT_CMD}; exec bash" &
        
        # No supported terminal found
        else
            echo "Error: No supported terminal emulator found"
            echo ""
            echo "Please install one of the following:"
            echo "  - gnome-terminal (GNOME)"
            echo "  - xterm (universal)"
            echo "  - konsole (KDE)"
            echo ""
            echo "Installation examples:"
            echo "  Ubuntu/Debian: sudo apt install gnome-terminal"
            echo "  Fedora/RHEL:   sudo dnf install gnome-terminal"
            exit 1
        fi
        ;;
    
    *)
        # Unsupported operating system
        echo "Error: Unsupported platform: $(uname -s)"
        echo ""
        echo "Supported platforms:"
        echo "  - macOS (Darwin)"
        echo "  - Linux"
        echo ""
        echo "Current platform: $(uname -s)"
        exit 1
        ;;
esac
