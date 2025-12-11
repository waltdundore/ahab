"""
Core data models for the audit system.

This module defines the fundamental data structures used throughout the audit:
- Finding: Represents a single audit finding with severity and recommendations
- Repository: Abstraction for accessing repository files and metadata
- AuditReport: Aggregated results from all audit modules
- Severity and Category enums for classification
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional
import subprocess


class Severity(Enum):
    """
    Severity levels for audit findings.
    
    CRITICAL: Blocks core functionality or violates critical principles
    HIGH: Important but not blocking
    MEDIUM: Should fix but not urgent
    LOW: Nice to have
    """
    CRITICAL = "Critical"
    HIGH = "High"
    MEDIUM = "Medium"
    LOW = "Low"


class Category(Enum):
    """
    Categories for classifying audit findings.
    
    DOCUMENTATION: Issues with documentation completeness or quality
    PRINCIPLES: Violations of core principles
    FEATURE: Missing or incomplete features
    QUALITY: Code quality issues
    IMPROVEMENT: Opportunities for enhancement
    """
    DOCUMENTATION = "Documentation"
    PRINCIPLES = "Principles"
    FEATURE = "Feature"
    QUALITY = "Quality"
    IMPROVEMENT = "Improvement"


@dataclass
class Finding:
    """
    Represents a single audit finding.
    
    A finding captures a specific issue or opportunity discovered during the audit,
    with enough context to understand and address it.
    
    Attributes:
        severity: How critical this finding is
        category: What type of finding this is
        title: Brief description of the finding
        description: Detailed explanation of what was found
        file_path: Optional path to the file where issue was found
        line_number: Optional line number in the file
        recommendation: Specific actionable recommendation
        effort_estimate: Estimated time to address (e.g., "2 hours", "1 day")
        related_principle: Optional reference to violated core principle
        related_requirement: Reference to requirement this validates
    """
    severity: Severity
    category: Category
    title: str
    description: str
    recommendation: str
    effort_estimate: str
    related_requirement: str
    file_path: Optional[str] = None
    line_number: Optional[int] = None
    related_principle: Optional[str] = None


@dataclass
class AuditSummary:
    """
    Summary statistics for an audit report.
    
    Attributes:
        total_findings: Total number of findings
        by_severity: Count of findings by severity level
        by_category: Count of findings by category
        estimated_total_effort: Total estimated effort to address all findings
    """
    total_findings: int
    by_severity: Dict[Severity, int]
    by_category: Dict[Category, int]
    estimated_total_effort: str


@dataclass
class AuditReport:
    """
    Complete audit report with all findings and metadata.
    
    Attributes:
        timestamp: When the audit was run
        original_repo: Path or URL to original repository
        current_repo: Path to current repository
        findings: List of all findings from all modules
        summary: Aggregated statistics
    """
    timestamp: datetime
    original_repo: str
    current_repo: str
    findings: List[Finding]
    summary: AuditSummary


class Repository:
    """
    Abstraction for accessing repository files and metadata.
    
    This class provides a consistent interface for reading files, parsing
    Makefiles, and accessing repository structure regardless of whether
    the repository is local or remote.
    
    Attributes:
        path: Path to the repository root
    """
    
    def __init__(self, path: str):
        """
        Initialize repository at given path.
        
        Args:
            path: Path to repository root directory
            
        Raises:
            ValueError: If path doesn't exist or isn't a directory
        """
        self.path = Path(path)
        if not self.path.exists():
            raise ValueError(f"Repository path does not exist: {path}")
        if not self.path.is_dir():
            raise ValueError(f"Repository path is not a directory: {path}")
    
    def get_files(self, pattern: str = "*") -> List[Path]:
        """
        Get all files matching pattern.
        
        Args:
            pattern: Glob pattern to match files (default: all files)
            
        Returns:
            List of Path objects for matching files
        """
        # Use rglob for recursive search
        return list(self.path.rglob(pattern))
    
    def read_file(self, file_path: Path) -> str:
        """
        Read file contents.
        
        Args:
            file_path: Path to file (relative to repository root or absolute)
            
        Returns:
            File contents as string
            
        Raises:
            FileNotFoundError: If file doesn't exist
            IOError: If file can't be read
        """
        # Handle both absolute and relative paths
        if not file_path.is_absolute():
            file_path = self.path / file_path
        
        return file_path.read_text(encoding='utf-8')
    
    def get_makefile_targets(self) -> List[str]:
        """
        Parse Makefile and return all targets.
        
        Returns:
            List of target names found in Makefile
            
        Raises:
            FileNotFoundError: If Makefile doesn't exist
        """
        makefile_path = self.path / "Makefile"
        if not makefile_path.exists():
            raise FileNotFoundError(f"Makefile not found at {makefile_path}")
        
        targets = []
        content = makefile_path.read_text(encoding='utf-8')
        
        for line in content.split('\n'):
            # Target lines start at column 0 and contain ':'
            # Skip comments, variable assignments, and special targets
            line = line.strip()
            if line and not line.startswith('#') and not line.startswith('\t'):
                if ':' in line and '=' not in line.split(':')[0]:
                    target = line.split(':')[0].strip()
                    # Skip special targets like .PHONY
                    if not target.startswith('.'):
                        targets.append(target)
        
        return targets
    
    def get_scripts(self) -> List[Path]:
        """
        Get all scripts in scripts/ directory.
        
        Returns:
            List of Path objects for script files
        """
        scripts_dir = self.path / "scripts"
        if not scripts_dir.exists():
            return []
        
        # Get all .sh, .py, and executable files
        scripts = []
        for ext in ['*.sh', '*.py']:
            scripts.extend(scripts_dir.glob(ext))
        
        return scripts
    
    def get_roles(self) -> List[str]:
        """
        Get all Ansible roles.
        
        Returns:
            List of role names
        """
        roles_dir = self.path / "roles"
        if not roles_dir.exists():
            return []
        
        # Each subdirectory in roles/ is a role
        return [d.name for d in roles_dir.iterdir() if d.is_dir()]
    
    def get_playbooks(self) -> List[Path]:
        """
        Get all Ansible playbooks.
        
        Returns:
            List of Path objects for playbook files
        """
        playbooks_dir = self.path / "playbooks"
        if not playbooks_dir.exists():
            return []
        
        # Get all .yml and .yaml files
        playbooks = []
        for ext in ['*.yml', '*.yaml']:
            playbooks.extend(playbooks_dir.glob(ext))
        
        return playbooks
