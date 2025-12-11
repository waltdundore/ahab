"""
Configuration management for the audit system.

This module handles loading and validating audit configuration from YAML files.
"""

from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional
import yaml


@dataclass
class AuditConfig:
    """
    Configuration for audit execution.
    
    Attributes:
        original_repo: Path or URL to original repository
        current_repo: Path to current repository (default: current directory)
        modules: List of audit modules to run (default: all)
        severity_threshold: Minimum severity to report (default: MEDIUM)
        parallel_execution: Whether to run modules in parallel (default: True)
        cache_enabled: Whether to cache file reads (default: True)
        output_file: Path to output report file (default: audit-report.md)
    """
    original_repo: str
    current_repo: str = "."
    modules: List[str] = field(default_factory=lambda: [
        "documentation",
        "principles",
        "features",
        "quality"
    ])
    severity_threshold: str = "MEDIUM"
    parallel_execution: bool = True
    cache_enabled: bool = True
    output_file: str = "audit-report.md"
    
    @classmethod
    def from_yaml(cls, config_path: str) -> 'AuditConfig':
        """
        Load configuration from YAML file.
        
        Args:
            config_path: Path to YAML configuration file
            
        Returns:
            AuditConfig instance
            
        Raises:
            FileNotFoundError: If config file doesn't exist
            ValueError: If config is invalid
        """
        path = Path(config_path)
        if not path.exists():
            raise FileNotFoundError(f"Config file not found: {config_path}")
        
        with open(path, 'r') as f:
            data = yaml.safe_load(f)
        
        # Extract audit section
        if 'audit' not in data:
            raise ValueError("Config file must contain 'audit' section")
        
        audit_data = data['audit']
        
        # Validate required fields
        if 'original_repo' not in audit_data:
            raise ValueError("Config must specify 'original_repo'")
        
        return cls(
            original_repo=audit_data['original_repo'],
            current_repo=audit_data.get('current_repo', '.'),
            modules=audit_data.get('modules', cls.modules),
            severity_threshold=audit_data.get('severity_threshold', 'MEDIUM'),
            parallel_execution=audit_data.get('parallel_execution', True),
            cache_enabled=audit_data.get('cache_enabled', True),
            output_file=audit_data.get('output_file', 'audit-report.md')
        )
    
    @classmethod
    def default(cls) -> 'AuditConfig':
        """
        Create default configuration.
        
        Returns:
            AuditConfig with default values
        """
        return cls(
            original_repo="https://github.com/waltdundore/ansible-control"
        )
