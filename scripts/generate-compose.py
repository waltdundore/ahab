#!/usr/bin/env python3
"""
Generate docker-compose.yml from module array.

Usage: generate-compose.py apache mysql nginx
Output: generated/docker-compose.yml

Reads module.yml from each module in ahab-modules/
Combines into single docker-compose.yml
"""

import sys
import yaml
import os
from pathlib import Path

def load_module(module_name, modules_dir):
    """Load module.yml for a given module."""
    module_path = modules_dir / module_name / "module.yml"
    
    if not module_path.exists():
        print(f"ERROR: Module '{module_name}' not found at {module_path}", file=sys.stderr)
        sys.exit(1)
    
    with open(module_path, 'r') as f:
        return yaml.safe_load(f)

def generate_compose(modules, modules_dir, output_file):
    """Generate docker-compose.yml from module array."""
    
    compose = {
        'services': {},
        'networks': {},
        'volumes': {}
    }
    
    # Process each module
    for module_name in modules:
        print(f"→ Processing module: {module_name}")
        module_data = load_module(module_name, modules_dir)
        
        # Add services
        if 'services' in module_data:
            compose['services'].update(module_data['services'])
        
        # Add networks
        if 'networks' in module_data:
            compose['networks'].update(module_data['networks'])
        
        # Add volumes
        if 'volumes' in module_data:
            compose['volumes'].update(module_data['volumes'])
    
    # Remove empty sections
    if not compose['networks']:
        del compose['networks']
    if not compose['volumes']:
        del compose['volumes']
    
    # Write output
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, 'w') as f:
        yaml.dump(compose, f, default_flow_style=False, sort_keys=False)
    
    print(f"✓ Generated: {output_file}")
    print(f"✓ Services: {', '.join(compose['services'].keys())}")

def main():
    if len(sys.argv) < 2:
        print("Usage: generate-compose.py MODULE [MODULE...]", file=sys.stderr)
        print("Example: generate-compose.py apache mysql", file=sys.stderr)
        sys.exit(1)
    
    modules = sys.argv[1:]
    
    # Paths
    script_dir = Path(__file__).parent
    ahab_dir = script_dir.parent
    modules_dir = ahab_dir / "modules"
    output_file = ahab_dir / "generated" / "docker-compose.yml"
    
    # Verify modules directory exists
    if not modules_dir.exists():
        print(f"ERROR: Modules directory not found: {modules_dir}", file=sys.stderr)
        print("Run: git submodule update --init --recursive", file=sys.stderr)
        sys.exit(1)
    
    print("========================================")
    print("Ahab - Docker Compose Generator")
    print("========================================")
    print(f"Modules: {', '.join(modules)}")
    print("")
    
    generate_compose(modules, modules_dir, output_file)
    
    print("")
    print("Next steps:")
    print(f"  cd {ahab_dir}/generated")
    print("  docker-compose up -d")
    print("")

if __name__ == '__main__':
    main()
