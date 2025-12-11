# Ahab Inventory

![Ahab Logo](docs/images/ahab-logo.png)

This repository contains your computer and server inventory - the list of machines Ahab will manage.

**📖 For complete documentation, see the [main README](../README.md)**

## What's in This Repo

- **dev/** - Development/testing inventory
- **prod/** - Production inventory (real computers)
- **workstation/** - Personal workstation inventory
- **vagrant.py** - Dynamic inventory for Vagrant VMs

## Structure

```
inventory/
├── dev/
│   └── hosts.yml          # Test computers
├── prod/
│   └── hosts.yml          # Production computers
└── workstation/
    └── hosts.yml          # Your personal machines
```

## Quick Start

1. Copy the example file:
   ```bash
   cp dev/hosts.yml.example dev/hosts.yml
   ```

2. Edit `dev/hosts.yml` with your computers:
   ```yaml
   all:
     children:
       lab_computers:
         hosts:
           lab-pc-01:
             ansible_host: 192.168.1.101
           lab-pc-02:
             ansible_host: 192.168.1.102
   ```

3. Test connection:
   ```bash
   ansible all -i dev/hosts.yml -m ping
   ```

## Links

- **[Main Documentation](../README.md)** - Start here
- **[Inventory Guide](../docs/inventory.md)** - How to organize your computers
- **[Workflow Guide](../docs/workflow.md)** - Dev → Prod promotion
