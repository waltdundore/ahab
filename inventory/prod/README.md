# Production Inventory

This directory contains inventory files for production environments.

## ⚠️ CRITICAL SECURITY WARNING ⚠️

**Production inventories contain sensitive information:**
- Real production IP addresses
- Production hostnames
- Production credentials
- Production network topology

**NEVER commit `hosts.yml` to version control!**

## Quick Start

1. **Copy the example file:**
   ```bash
   cp hosts.yml.example hosts.yml
   ```

2. **Edit with your actual production information:**
   ```bash
   vim hosts.yml
   ```

3. **Verify syntax before deploying:**
   ```bash
   cd ../..  # Back to ahab directory
   ansible-inventory -i inventory/prod/hosts.yml --list
   ```

4. **Test connectivity (carefully!):**
   ```bash
   ansible all -i inventory/prod/hosts.yml -m ping
   ```

## Security Best Practices

- ✅ `hosts.yml.example` - Committed to git (sanitized example)
- ❌ `hosts.yml` - NOT committed (contains real production IPs)
- ✅ Use Ansible Vault for credentials
- ✅ Restrict file permissions: `chmod 600 hosts.yml`
- ✅ Use SSH key authentication (not passwords)
- ✅ Test changes in dev environment first

## Production Deployment Checklist

Before deploying to production:

- [ ] Tested in dev environment
- [ ] Reviewed all changes
- [ ] Backed up current configuration
- [ ] Verified connectivity with `ansible ping`
- [ ] Scheduled maintenance window
- [ ] Notified stakeholders
- [ ] Have rollback plan ready

## File Structure

```
prod/
├── README.md              # This file
├── hosts.yml.example      # Example (committed to git)
└── hosts.yml              # Actual inventory (NOT in git)
```

## Support

For production issues:
- See: `ahab/docs/TROUBLESHOOTING.md`
- See: `ahab/docs/PRODUCTION_DEPLOYMENT.md`
- Contact: System administrator

## Related Documentation

- [Production Setup Guide](../../docs/PRODUCTION_SETUP.md)
- [Security Model](../../docs/SECURITY_MODEL.md)
- [Troubleshooting](../../TROUBLESHOOTING.md)
