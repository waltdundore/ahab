# Development Inventory

This directory contains inventory files for development and testing environments.

## Quick Start

1. **Copy the example file:**
   ```bash
   cp hosts.yml.example hosts.yml
   ```

2. **Edit with your actual device information:**
   ```bash
   vim hosts.yml
   ```

3. **Update IP addresses and hostnames** to match your dev environment

4. **Test connectivity:**
   ```bash
   cd ../..  # Back to ahab directory
   ansible all -i inventory/dev/hosts.yml -m ping
   ```

## Security

- ✅ `hosts.yml.example` - Committed to git (sanitized example)
- ❌ `hosts.yml` - NOT committed (contains real IPs)
- ❌ Never commit actual IP addresses or credentials

## Dynamic IP Addresses

For devices with dynamic IPs (like wcss-dev-asus):

**Current approach:**
- Manually update `hosts.yml` when IP changes
- Check current IP: `ip addr show` on the device

**Future enhancement (see FUTURE_DEVELOPMENT.md):**
- Device reports its IP to a central service
- Inventory auto-updates from device check-ins
- DNS-based discovery

## File Structure

```
dev/
├── README.md              # This file
├── hosts.yml.example      # Example (committed to git)
└── hosts.yml              # Actual inventory (NOT in git)
```

## Example Devices

The example file includes:
- **wcss-dev-asus** - Physical test device (dynamic IP)
- **lab-vm-01** - Example VM
- **test-workstation** - Example workstation

Replace these with your actual development devices.
