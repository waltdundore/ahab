#!/usr/bin/env python3
"""
Requirements Parser Module

Parses requirements.txt files to extract package names, versions, and extras.
Uses the packaging library for robust requirement parsing.
"""

import os
from dataclasses import dataclass
from typing import List, Optional, Dict
from packaging.requirements import Requirement as PackagingRequirement
from packaging.requirements import InvalidRequirement


@dataclass
class Requirement:
    """Represents a parsed requirement from requirements.txt"""
    name: str
    version: str  # e.g., "==3.0.0" or ">=6.0" or "" for unpinned
    extras: List[str]  # e.g., ["security", "tests"]
    source_file: str  # Which requirements.txt it came from
    raw_line: str  # Original line from file


class RequirementsParser:
    """Parse requirements.txt files to extract component information"""
    
    def discover_all_requirements(self, root_dir: str) -> Dict[str, List[Requirement]]:
        """
        Find and parse all requirements files in project.
        
        Args:
            root_dir: Root directory to search from
            
        Returns:
            Dictionary mapping filepath to list of Requirements
        """
        all_requirements = {}
        
        # Search for requirements*.txt files
        for dirpath, dirnames, filenames in os.walk(root_dir):
            # Skip hidden directories and common ignore patterns
            dirnames[:] = [d for d in dirnames if not d.startswith('.') 
                          and d not in ['node_modules', '__pycache__', 'venv', 'env']]
            
            for filename in filenames:
                # Match requirements.txt, requirements-*.txt, etc.
                if filename.startswith('requirements') and filename.endswith('.txt'):
                    filepath = os.path.join(dirpath, filename)
                    try:
                        requirements = self.parse_file(filepath)
                        if requirements:  # Only include files with actual requirements
                            all_requirements[filepath] = requirements
                    except Exception as e:
                        print(f"Warning: Failed to parse {filepath}: {e}")
                        continue
        
        return all_requirements
    
    def parse_file(self, filepath: str) -> List[Requirement]:
        """
        Parse a requirements.txt file.
        
        Args:
            filepath: Path to requirements.txt file
            
        Returns:
            List of Requirement objects
            
        Raises:
            FileNotFoundError: If file doesn't exist
        """
        requirements = []
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                for line_num, line in enumerate(f, 1):
                    # Strip whitespace
                    line = line.strip()
                    
                    # Skip empty lines and comments
                    if not line or line.startswith('#'):
                        continue
                    
                    # Skip lines with -r or -e (include/editable)
                    if line.startswith('-r') or line.startswith('-e'):
                        continue
                    
                    # Try to parse the requirement
                    try:
                        req = self._parse_requirement(line, filepath)
                        if req:
                            requirements.append(req)
                    except InvalidRequirement as e:
                        # Log error but continue parsing
                        print(f"Warning: Invalid requirement at {filepath}:{line_num}: {line}")
                        print(f"  Error: {e}")
                        continue
                        
        except FileNotFoundError:
            raise FileNotFoundError(f"Requirements file not found: {filepath}")
        
        return requirements
    
    def _parse_requirement(self, line: str, source_file: str) -> Optional[Requirement]:
        """
        Parse a single requirement line.
        
        Args:
            line: Line from requirements.txt
            source_file: Path to source file
            
        Returns:
            Requirement object or None if line should be skipped
        """
        # Remove inline comments
        if '#' in line:
            line = line.split('#')[0].strip()
        
        if not line:
            return None
        
        # Parse using packaging library
        pkg_req = PackagingRequirement(line)
        
        # Extract version specifier
        version = ""
        if pkg_req.specifier:
            version = str(pkg_req.specifier)
        
        # Extract extras
        extras = list(pkg_req.extras) if pkg_req.extras else []
        
        return Requirement(
            name=pkg_req.name,
            version=version,
            extras=extras,
            source_file=source_file,
            raw_line=line
        )


def main():
    """Test the parser with a sample file or directory"""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python requirements_parser.py <requirements.txt|directory>")
        sys.exit(1)
    
    parser = RequirementsParser()
    path = sys.argv[1]
    
    if os.path.isfile(path):
        # Parse single file
        requirements = parser.parse_file(path)
        print(f"Found {len(requirements)} requirements in {path}:")
        for req in requirements:
            extras_str = f"[{','.join(req.extras)}]" if req.extras else ""
            print(f"  - {req.name}{extras_str}{req.version}")
    elif os.path.isdir(path):
        # Discover and parse all requirements files
        all_requirements = parser.discover_all_requirements(path)
        print(f"Found {len(all_requirements)} requirements files:")
        for filepath, requirements in all_requirements.items():
            print(f"\n{filepath} ({len(requirements)} packages):")
            for req in requirements:
                extras_str = f"[{','.join(req.extras)}]" if req.extras else ""
                print(f"  - {req.name}{extras_str}{req.version}")
    else:
        print(f"Error: {path} is not a file or directory")
        sys.exit(1)


if __name__ == "__main__":
    main()
