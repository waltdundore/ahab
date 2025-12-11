"""
Base classes and interfaces for audit modules.

This module defines the abstract base class that all audit modules must implement,
ensuring a consistent interface for the orchestrator.
"""

from abc import ABC, abstractmethod
from typing import List

from .models import Finding, Repository


class AuditModule(ABC):
    """
    Abstract base class for all audit modules.
    
    Each audit module implements specific audit logic (documentation, principles,
    features, quality) and returns findings. The orchestrator coordinates execution
    of all modules.
    """
    
    @abstractmethod
    def audit(self, original: Repository, current: Repository) -> List[Finding]:
        """
        Perform audit and return findings.
        
        This method implements the core audit logic for this module. It compares
        the original and current repositories and returns a list of findings.
        
        Args:
            original: Repository object for the original/reference repository
            current: Repository object for the current repository being audited
            
        Returns:
            List of Finding objects discovered during the audit
            
        Raises:
            Exception: If audit encounters unrecoverable error
        """
        pass
    
    @abstractmethod
    def get_name(self) -> str:
        """
        Return module name for reporting.
        
        Returns:
            Human-readable name of this audit module
        """
        pass
