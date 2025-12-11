#!/usr/bin/env python3
"""
Property-Based Tests for Requirements Parser

**Feature: open-source-attribution, Property 1: Requirements File Completeness**
**Validates: Requirements 1.1, 1.4**

Property: For any requirements.txt file in the project, all packages listed 
should appear in the generated component documentation.
"""

import os
import sys
import tempfile
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from lib.requirements_parser import RequirementsParser, Requirement
from hypothesis import given, strategies as st, settings, example
import pytest


# Strategy for generating valid package names
# Package names must follow PEP 508: start with letter/digit, contain only letters, digits, hyphens, underscores, dots
# Must start and end with alphanumeric
package_name_strategy = st.text(
    alphabet='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.',
    min_size=2,
    max_size=30
).filter(lambda x: x[0].isalnum() and x[-1].isalnum() and not x.startswith('-') and not x.startswith('_') and not x.startswith('.'))

# Strategy for generating version specifiers
# Valid version numbers like 1.0.0, 2.3, etc.
version_number_strategy = st.builds(
    lambda major, minor, patch: f"{major}.{minor}.{patch}",
    st.integers(min_value=0, max_value=10),
    st.integers(min_value=0, max_value=20),
    st.integers(min_value=0, max_value=50)
)

version_specifier_strategy = st.one_of(
    st.just(""),  # No version
    st.builds(lambda v: f"=={v}", version_number_strategy),
    st.builds(lambda v: f">={v}", version_number_strategy),
    st.builds(lambda v: f"~={v}", version_number_strategy),
)

# Strategy for generating extras
# Extras are like [tests], [security], etc.
# Must start and end with alphanumeric
extras_strategy = st.lists(
    st.text(alphabet='abcdefghijklmnopqrstuvwxyz0123456789-_', min_size=1, max_size=15).filter(
        lambda x: x[0].isalnum() and x[-1].isalnum()
    ),
    max_size=3
)


@st.composite
def requirement_line_strategy(draw):
    """Generate a valid requirement line"""
    name = draw(package_name_strategy)
    version = draw(version_specifier_strategy)
    extras = draw(extras_strategy)
    
    if extras:
        extras_str = f"[{','.join(extras)}]"
        return f"{name}{extras_str}{version}"
    else:
        return f"{name}{version}"


@st.composite
def requirements_file_strategy(draw):
    """Generate a complete requirements.txt file content"""
    num_requirements = draw(st.integers(min_value=1, max_value=20))
    lines = []
    
    # Add some comments and blank lines
    if draw(st.booleans()):
        lines.append("# This is a comment")
    
    for _ in range(num_requirements):
        req_line = draw(requirement_line_strategy())
        lines.append(req_line)
        
        # Occasionally add blank lines or comments
        if draw(st.booleans()):
            lines.append("")
        if draw(st.booleans()):
            lines.append(f"# Comment about {req_line}")
    
    return "\n".join(lines)


class TestRequirementsCompleteness:
    """
    Property 1: Requirements File Completeness
    
    For any requirements.txt file in the project, all packages listed 
    should appear in the parsed output.
    """
    
    @given(requirements_file_strategy())
    @settings(max_examples=100)
    @example("flask==3.0.0\nrequests>=2.31.0")
    @example("hypothesis[tests]>=6.0.0")
    @example("# Comment\npackaging==23.0\n\n# Another comment\nPyYAML>=6.0")
    def test_all_packages_are_parsed(self, requirements_content: str):
        """
        **Feature: open-source-attribution, Property 1: Requirements File Completeness**
        
        Property: For any requirements.txt file, all non-comment, non-blank 
        package lines should be successfully parsed and included in the output.
        """
        parser = RequirementsParser()
        
        # Create a temporary requirements file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write(requirements_content)
            temp_file = f.name
        
        try:
            # Parse the file
            parsed_requirements = parser.parse_file(temp_file)
            
            # Extract expected package names from content
            # (lines that are not comments or blank)
            expected_packages = set()
            for line in requirements_content.split('\n'):
                line = line.strip()
                if line and not line.startswith('#') and not line.startswith('-'):
                    # Extract package name (before any [, ==, >=, etc.)
                    pkg_name = line.split('[')[0].split('=')[0].split('>')[0].split('<')[0].split('~')[0].strip()
                    if pkg_name:
                        expected_packages.add(pkg_name.lower())
            
            # Extract parsed package names
            parsed_packages = {req.name.lower() for req in parsed_requirements}
            
            # Property: All expected packages should be in parsed output
            assert expected_packages == parsed_packages, \
                f"Missing packages: {expected_packages - parsed_packages}, " \
                f"Extra packages: {parsed_packages - expected_packages}"
            
            # Additional property: Each requirement should have a name
            for req in parsed_requirements:
                assert req.name, "Requirement must have a name"
                assert req.source_file == temp_file, "Source file must be tracked"
        
        finally:
            # Clean up temp file
            os.unlink(temp_file)
    
    def test_real_requirements_files_are_complete(self):
        """
        Test that real requirements files in the project are parsed completely.
        
        This is not a property test, but validates the property holds for 
        actual project files.
        """
        parser = RequirementsParser()
        
        # Find project root (go up from tests directory)
        test_dir = Path(__file__).parent
        project_root = test_dir.parent.parent.parent.parent.parent  # Up to workspace root
        
        # Discover all requirements files
        all_requirements = parser.discover_all_requirements(str(project_root))
        
        # Property: Should find at least the known requirements files
        assert len(all_requirements) >= 2, \
            f"Expected at least 2 requirements files, found {len(all_requirements)}"
        
        # Property: Each file should have at least one requirement
        for filepath, requirements in all_requirements.items():
            assert len(requirements) > 0, \
                f"Requirements file {filepath} should have at least one requirement"
            
            # Property: Each requirement should have required fields
            for req in requirements:
                assert req.name, f"Requirement in {filepath} must have a name"
                assert req.source_file == filepath, \
                    f"Requirement source_file should match {filepath}"
    
    @given(st.lists(requirement_line_strategy(), min_size=2, max_size=10))
    @settings(max_examples=50)
    def test_discovery_finds_all_files(self, requirement_lines: list):
        """
        Property: discover_all_requirements should find all requirements.txt 
        files in a directory tree that contain at least one valid requirement.
        """
        parser = RequirementsParser()
        
        # Create a temporary directory structure
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create multiple requirements files in different subdirectories
            files_with_content = []
            
            # Root level - ensure at least one valid requirement
            root_req = os.path.join(tmpdir, "requirements.txt")
            with open(root_req, 'w') as f:
                f.write('\n'.join(requirement_lines[:max(3, len(requirement_lines)//2)]))
            # Parse to check if it has valid requirements
            if parser.parse_file(root_req):
                files_with_content.append(root_req)
            
            # Subdirectory - ensure at least one valid requirement
            subdir = os.path.join(tmpdir, "subproject")
            os.makedirs(subdir)
            sub_req = os.path.join(subdir, "requirements-dev.txt")
            remaining_lines = requirement_lines[max(3, len(requirement_lines)//2):]
            if remaining_lines:  # Only create if we have lines
                with open(sub_req, 'w') as f:
                    f.write('\n'.join(remaining_lines))
                # Parse to check if it has valid requirements
                if parser.parse_file(sub_req):
                    files_with_content.append(sub_req)
            
            # Discover all requirements
            discovered = parser.discover_all_requirements(tmpdir)
            
            # Property: All files with valid content should be discovered
            discovered_paths = set(discovered.keys())
            expected_paths = set(files_with_content)
            
            assert discovered_paths == expected_paths, \
                f"Missing files: {expected_paths - discovered_paths}, Extra files: {discovered_paths - expected_paths}"
            
            # Property: Each discovered file should have requirements
            for filepath, requirements in discovered.items():
                assert len(requirements) > 0, \
                    f"Discovered file {filepath} should have requirements"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
