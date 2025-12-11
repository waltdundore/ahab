#!/usr/bin/env python3
"""
==============================================================================
Ahab Docker Compose Generator
==============================================================================
Generates docker-compose.yml files from module.yml metadata

Usage:
    ./generate-docker-compose.py apache
    ./generate-docker-compose.py apache mysql
    ./generate-docker-compose.py --all
    ./generate-docker-compose.py --output custom-compose.yml apache mysql

Features:
    - Reads module.yml from ahab-modules submodule
    - Resolves dependencies automatically
    - Generates complete docker-compose.yml
    - Includes networks, volumes, services
    - Validates module compatibility
    - Handles dependency order

==============================================================================
"""

import yaml
import sys
import os
import argparse
from pathlib import Path
from typing import Dict, List, Set

class ModuleLoader:
    """Loads and validates module metadata"""
    
    def __init__(self, modules_dir: Path):
        self.modules_dir = modules_dir
        self.modules = {}
    
    def load_module(self, module_name: str) -> Dict:
        """Load a single module's metadata"""
        module_file = self.modules_dir / module_name / "module.yml"
        
        if not module_file.exists():
            raise FileNotFoundError(f"Module {module_name} not found at {module_file}")
        
        with open(module_file, 'r') as f:
            data = yaml.safe_load(f)
        
        self.modules[module_name] = data
        return data
    
    def load_all_modules(self) -> Dict:
        """Load all available modules"""
        for module_dir in self.modules_dir.iterdir():
            if module_dir.is_dir() and not module_dir.name.startswith('.'):
                module_file = module_dir / "module.yml"
                if module_file.exists():
                    self.load_module(module_dir.name)
        return self.modules
    
    def get_dependencies(self, module_name: str) -> List[str]:
        """Get list of module dependencies"""
        if module_name not in self.modules:
            self.load_module(module_name)
        
        module = self.modules[module_name]
        deps = module.get('dependencies', [])
        
        return deps if isinstance(deps, list) else []
    
    def resolve_dependencies(self, modules: List[str]) -> List[str]:
        """Resolve all dependencies in correct order"""
        resolved = []
        seen = set()
        
        def resolve(module_name: str):
            if module_name in seen:
                return
            seen.add(module_name)
            
            # Load module if not already loaded
            if module_name not in self.modules:
                self.load_module(module_name)
            
            # Resolve dependencies first
            for dep in self.get_dependencies(module_name):
                resolve(dep)
            
            resolved.append(module_name)
        
        for module in modules:
            resolve(module)
        
        return resolved


class DockerComposeGenerator:
    """Generates docker-compose.yml from module metadata"""
    
    def __init__(self, loader: ModuleLoader):
        self.loader = loader
        self.compose = {
            'services': {},
            'networks': {},
            'volumes': {}
        }
    
    def generate_service(self, module_name: str) -> Dict:
        """Generate docker-compose service definition from module"""
        module = self.loader.modules[module_name]
        docker_config = module.get('docker', {})
        
        service = {}
        
        # Image (required)
        if 'image' in docker_config:
            service['image'] = docker_config['image']
        else:
            raise ValueError(f"Module {module_name} missing required 'docker.image' field")
        
        # Container name
        if 'container_name' in docker_config:
            service['container_name'] = docker_config['container_name']
        
        # Restart policy
        if 'restart' in docker_config:
            service['restart'] = docker_config['restart']
        
        # Ports
        if 'ports' in docker_config:
            service['ports'] = docker_config['ports']
        
        # Volumes
        if 'volumes' in docker_config:
            service['volumes'] = docker_config['volumes']
        
        # Environment variables
        env_vars = docker_config.get('environment', {})
        
        # Add service discovery environment variables
        service_env = self.generate_service_discovery_env(module_name, env_vars)
        if service_env:
            service['environment'] = service_env
        
        # Networks
        if 'networks' in docker_config:
            service['networks'] = docker_config['networks']
        
        # Dependencies
        deps = self.loader.get_dependencies(module_name)
        if deps:
            service['depends_on'] = deps
        
        # STIG-Compliant Security Options (STIG-DKER-EE-003010)
        service['security_opt'] = [
            'no-new-privileges:true'   # Prevent privilege escalation
            # Docker uses default seccomp profile automatically
        ]
        
        # Drop all capabilities, add only what's needed (STIG-DKER-EE-003010)
        service['cap_drop'] = ['ALL']
        
        # Add necessary capabilities for web servers
        if module_name in ['apache', 'nginx'] or 'ports' in docker_config:
            service['cap_add'] = [
                'NET_BIND_SERVICE',  # Bind to privileged ports
                'SETUID',           # Change user ID (Apache needs this)
                'SETGID',           # Change group ID (Apache needs this)
                'DAC_OVERRIDE'      # Bypass file permission checks
            ]
        
        # Resource Limits (STIG-DKER-EE-003020)
        # Default limits - can be overridden in module.yml
        default_limits = {
            'cpus': '0.5',
            'memory': '512M'
        }
        default_reservations = {
            'cpus': '0.25',
            'memory': '256M'
        }
        
        # Check if module specifies custom limits
        if 'resources' in docker_config:
            limits = docker_config['resources'].get('limits', default_limits)
            reservations = docker_config['resources'].get('reservations', default_reservations)
        else:
            limits = default_limits
            reservations = default_reservations
        
        service['deploy'] = {
            'resources': {
                'limits': limits,
                'reservations': reservations
            }
        }
        
        # Labels
        service['labels'] = {
            'com.ahab.module': module_name,
            'com.ahab.version': module.get('version', '1.0.0'),
            'com.ahab.description': module.get('description', ''),
            'com.ahab.stig-compliant': 'true'
        }
        
        return service
    
    def generate_service_discovery_env(self, module_name: str, base_env: Dict) -> Dict:
        """Generate environment variables for service discovery"""
        env_vars = dict(base_env) if base_env else {}
        
        # Add service discovery for common database connections
        if module_name in ['php', 'apache'] and 'mysql' in self.loader.modules:
            env_vars.update({
                'DB_HOST': 'ahab_mysql',
                'DB_PORT': '3306',
                'DB_NAME': '${MYSQL_DATABASE:-webapp}',
                'DB_USER': '${MYSQL_USER:-webapp}',
                'DB_PASSWORD': '${MYSQL_PASSWORD:-webapp123}'
            })
        
        # Add Redis connection if available
        if module_name in ['php', 'apache'] and 'redis' in self.loader.modules:
            env_vars.update({
                'REDIS_HOST': 'ahab_redis',
                'REDIS_PORT': '6379'
            })
        
        # Add service URLs for reverse proxy configuration
        if module_name == 'nginx':
            if 'php' in self.loader.modules:
                env_vars['PHP_UPSTREAM'] = 'ahab_php:80'
            if 'apache' in self.loader.modules:
                env_vars['APACHE_UPSTREAM'] = 'ahab_apache:80'
        
        return env_vars
    
    def generate_networks(self, modules: List[str]):
        """Generate network definitions"""
        networks = set()
        
        for module_name in modules:
            module = self.loader.modules[module_name]
            docker_config = module.get('docker', {})
            module_networks = docker_config.get('networks', [])
            networks.update(module_networks)
        
        # Always include default ahab_network for inter-service communication
        networks.add('ahab_network')
        
        for network in networks:
            self.compose['networks'][network] = {
                'driver': 'bridge',
                'name': network,
                'labels': {
                    'com.ahab.network': 'true',
                    'com.ahab.created': 'auto-generated'
                }
            }
    
    def generate_volumes(self, modules: List[str]):
        """Generate volume definitions"""
        volumes = set()
        
        for module_name in modules:
            module = self.loader.modules[module_name]
            module_volumes = module.get('volumes', [])
            volumes.update(module_volumes)
        
        for volume in volumes:
            self.compose['volumes'][volume] = {
                'driver': 'local',
                'labels': {
                    'com.ahab.volume': 'true',
                    'com.ahab.created': 'auto-generated'
                }
            }
    
    def generate(self, modules: List[str]) -> Dict:
        """Generate complete docker-compose.yml"""
        # Resolve dependencies
        resolved_modules = self.loader.resolve_dependencies(modules)
        
        print(f"Generating docker-compose.yml for modules: {', '.join(resolved_modules)}")
        
        # Generate services
        for module_name in resolved_modules:
            print(f"  → Adding service: {module_name}")
            self.compose['services'][module_name] = self.generate_service(module_name)
        
        # Generate networks and volumes
        self.generate_networks(resolved_modules)
        self.generate_volumes(resolved_modules)
        
        # Remove empty sections
        if not self.compose['networks']:
            del self.compose['networks']
        if not self.compose['volumes']:
            del self.compose['volumes']
        
        return self.compose
    
    def save(self, output_file: Path):
        """Save docker-compose.yml to file"""
        with open(output_file, 'w') as f:
            yaml.dump(self.compose, f, default_flow_style=False, sort_keys=False)
        print(f"\n✓ Generated: {output_file}")


def main():
    parser = argparse.ArgumentParser(
        description='Generate docker-compose.yml from Ahab module metadata'
    )
    parser.add_argument(
        'modules',
        nargs='*',
        help='Module names to include (e.g., apache mysql)'
    )
    parser.add_argument(
        '--all',
        action='store_true',
        help='Include all available modules'
    )
    parser.add_argument(
        '--output', '-o',
        default='docker-compose.yml',
        help='Output file (default: docker-compose.yml)'
    )
    parser.add_argument(
        '--modules-dir',
        default='modules',
        help='Modules directory (default: modules)'
    )
    parser.add_argument(
        '--validate',
        action='store_true',
        help='Validate modules without generating compose file'
    )
    
    args = parser.parse_args()
    
    # Determine modules directory
    script_dir = Path(__file__).parent
    modules_dir = script_dir.parent / args.modules_dir
    
    if not modules_dir.exists():
        print(f"Error: Modules directory not found: {modules_dir}")
        print(f"Hint: Make sure ahab-modules submodule is initialized:")
        print(f"  git submodule update --init --recursive")
        sys.exit(1)
    
    # Load modules
    loader = ModuleLoader(modules_dir)
    
    if args.all:
        loader.load_all_modules()
        modules = list(loader.modules.keys())
        if not modules:
            print(f"Error: No modules found in {modules_dir}")
            sys.exit(1)
    elif args.modules:
        modules = args.modules
    else:
        print("Error: Specify modules or use --all")
        parser.print_help()
        sys.exit(1)
    
    # Validate modules
    print(f"Loading modules from: {modules_dir}")
    for module in modules:
        try:
            loader.load_module(module)
            print(f"  ✓ Loaded: {module}")
        except FileNotFoundError as e:
            print(f"  ✗ Error: {e}")
            sys.exit(1)
        except Exception as e:
            print(f"  ✗ Error loading {module}: {e}")
            sys.exit(1)
    
    if args.validate:
        print("\n✓ All modules validated successfully")
        sys.exit(0)
    
    # Generate docker-compose.yml
    print()
    generator = DockerComposeGenerator(loader)
    compose = generator.generate(modules)
    
    # Save to file
    output_file = Path(args.output)
    generator.save(output_file)
    
    # Print summary
    print(f"\nSummary:")
    print(f"  Services: {len(compose['services'])}")
    print(f"  Networks: {len(compose.get('networks', {}))}")
    print(f"  Volumes: {len(compose.get('volumes', {}))}")
    print()
    print(f"To start services:")
    print(f"  docker-compose -f {output_file} up -d")
    print()


if __name__ == '__main__':
    main()
