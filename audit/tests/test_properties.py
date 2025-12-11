"""
Property-based tests for audit system.

Feature: repo-comparison-audit
These tests validate universal properties that should hold across all inputs.
Each property test runs 100 iterations with randomly generated data.
"""

import pytest
from hypothesis import given, strategies as st, settings
from audit.models import Finding, Severity, Category, AuditReport, AuditSummary, Repository
from datetime import datetime
from pathlib import Path
from typing import List


# Strategy for generating valid severity values
severity_strategy = st.sampled_from(list(Severity))

# Strategy for generating valid category values
category_strategy = st.sampled_from(list(Category))

# Strategy for generating valid effort estimates
effort_strategy = st.sampled_from([
    "15 minutes", "30 minutes", "1 hour", "2 hours", "4 hours",
    "1 day", "2 days", "1 week"
])


@pytest.mark.property
@settings(max_examples=100)
@given(
    severity=severity_strategy,
    category=category_strategy,
    title=st.text(min_size=1, max_size=100),
    description=st.text(min_size=1, max_size=500),
    recommendation=st.text(min_size=1, max_size=200),
    effort=effort_strategy,
    requirement=st.text(min_size=1, max_size=20)
)
def test_property_11_finding_has_all_required_fields(
    severity, category, title, description, recommendation, effort, requirement
):
    """
    Property 11: Report Completeness
    
    For any Finding, all required fields must be populated and accessible.
    This ensures every finding has enough information to be actionable.
    
    Validates: Requirements 7.1, 7.2, 7.3, 7.4, 7.5
    """
    # Create finding with all required fields
    finding = Finding(
        severity=severity,
        category=category,
        title=title,
        description=description,
        recommendation=recommendation,
        effort_estimate=effort,
        related_requirement=requirement
    )
    
    # Verify all required fields are present and match input
    assert finding.severity == severity
    assert finding.category == category
    assert finding.title == title
    assert finding.description == description
    assert finding.recommendation == recommendation
    assert finding.effort_estimate == effort
    assert finding.related_requirement == requirement
    
    # Verify optional fields default to None
    assert finding.file_path is None
    assert finding.line_number is None
    assert finding.related_principle is None


@pytest.mark.property
@settings(max_examples=100)
@given(
    severity=severity_strategy,
    category=category_strategy,
    title=st.text(min_size=1, max_size=100),
    description=st.text(min_size=1, max_size=500),
    recommendation=st.text(min_size=1, max_size=200),
    effort=effort_strategy,
    requirement=st.text(min_size=1, max_size=20),
    file_path=st.one_of(st.none(), st.text(min_size=1, max_size=100)),
    line_number=st.one_of(st.none(), st.integers(min_value=1, max_value=10000)),
    principle=st.one_of(st.none(), st.text(min_size=1, max_size=50))
)
def test_property_11_finding_with_optional_fields(
    severity, category, title, description, recommendation, effort, requirement,
    file_path, line_number, principle
):
    """
    Property 11: Report Completeness (with optional fields)
    
    For any Finding with optional fields, all fields must be accessible
    and maintain their values.
    
    Validates: Requirements 7.1, 7.2, 7.3, 7.4, 7.5
    """
    finding = Finding(
        severity=severity,
        category=category,
        title=title,
        description=description,
        recommendation=recommendation,
        effort_estimate=effort,
        related_requirement=requirement,
        file_path=file_path,
        line_number=line_number,
        related_principle=principle
    )
    
    # Verify all fields match input
    assert finding.severity == severity
    assert finding.category == category
    assert finding.title == title
    assert finding.description == description
    assert finding.recommendation == recommendation
    assert finding.effort_estimate == effort
    assert finding.related_requirement == requirement
    assert finding.file_path == file_path
    assert finding.line_number == line_number
    assert finding.related_principle == principle


@pytest.mark.property
@settings(max_examples=100)
@given(
    findings_count=st.integers(min_value=0, max_value=50)
)
def test_property_11_audit_report_aggregates_findings(findings_count):
    """
    Property 11: Report Completeness (aggregation)
    
    For any AuditReport, the summary statistics must accurately reflect
    the findings list.
    
    Validates: Requirements 7.1, 7.2, 7.5
    """
    # Generate random findings
    findings = []
    severity_counts = {s: 0 for s in Severity}
    category_counts = {c: 0 for c in Category}
    
    for i in range(findings_count):
        severity = list(Severity)[i % len(Severity)]
        category = list(Category)[i % len(Category)]
        
        finding = Finding(
            severity=severity,
            category=category,
            title=f"Finding {i}",
            description=f"Description {i}",
            recommendation=f"Fix {i}",
            effort_estimate="1 hour",
            related_requirement=f"{i}.1"
        )
        findings.append(finding)
        severity_counts[severity] += 1
        category_counts[category] += 1
    
    # Create summary
    summary = AuditSummary(
        total_findings=len(findings),
        by_severity=severity_counts,
        by_category=category_counts,
        estimated_total_effort=f"{findings_count} hours"
    )
    
    # Create report
    report = AuditReport(
        timestamp=datetime.now(),
        original_repo="https://github.com/test/repo",
        current_repo="/path/to/current",
        findings=findings,
        summary=summary
    )
    
    # Verify summary matches findings
    assert report.summary.total_findings == len(findings)
    assert report.summary.total_findings == findings_count
    
    # Verify severity counts
    for severity in Severity:
        expected_count = sum(1 for f in findings if f.severity == severity)
        assert report.summary.by_severity[severity] == expected_count
    
    # Verify category counts
    for category in Category:
        expected_count = sum(1 for f in findings if f.category == category)
        assert report.summary.by_category[category] == expected_count


@pytest.mark.property
@settings(max_examples=100)
@given(
    severity=severity_strategy,
    category=category_strategy
)
def test_property_11_finding_severity_and_category_are_enums(severity, category):
    """
    Property 11: Report Completeness (type safety)
    
    For any Finding, severity and category must be valid enum values,
    ensuring type safety and preventing invalid classifications.
    
    Validates: Requirements 7.2
    """
    finding = Finding(
        severity=severity,
        category=category,
        title="Test",
        description="Test description",
        recommendation="Fix it",
        effort_estimate="1 hour",
        related_requirement="1.1"
    )
    
    # Verify types
    assert isinstance(finding.severity, Severity)
    assert isinstance(finding.category, Category)
    
    # Verify values are in enum
    assert finding.severity in Severity
    assert finding.category in Category


# ==============================================================================
# Property Tests for Dependency Minimization Audit
# Feature: dependency-minimization-audit
# ==============================================================================

# System tools that are allowed in scripts (POSIX-compatible)
SYSTEM_TOOLS = {
    'bash', 'sh', 'echo', 'cat', 'grep', 'sed', 'awk', 'cut', 'tr', 'sort',
    'uniq', 'wc', 'head', 'tail', 'find', 'xargs', 'test', 'mkdir', 'rm',
    'cp', 'mv', 'chmod', 'chown', 'ls', 'pwd', 'cd', 'touch', 'date',
    'sleep', 'true', 'false', 'printf', 'read', 'expr', 'bc', 'tee',
    'diff', 'patch', 'tar', 'gzip', 'gunzip', 'zip', 'unzip', 'curl',
    'wget', 'ssh', 'scp', 'rsync', 'git', 'make', 'perl', 'python', 'python3'
}

# Package managers that should NOT be in scripts
PACKAGE_MANAGERS = {
    'dnf', 'yum', 'apt', 'apt-get', 'pip', 'pip3', 'npm', 'yarn',
    'gem', 'cargo', 'go'
}

# Docker commands that should be wrapped in Make targets
DOCKER_COMMANDS = {
    'docker', 'docker-compose', 'podman'
}


def extract_commands_from_script(script_content: str) -> List[str]:
    """
    Extract command invocations from a shell script.
    
    This is a simplified parser that looks for command patterns.
    It handles basic cases but may not catch all edge cases.
    
    Args:
        script_content: Content of the shell script
        
    Returns:
        List of command names found in the script
    """
    import re
    
    commands = []
    
    # Remove comments
    lines = []
    for line in script_content.split('\n'):
        # Remove inline comments (but preserve # in strings)
        if '#' in line:
            # Simple heuristic: if # is not in quotes, treat as comment
            comment_pos = line.find('#')
            line = line[:comment_pos]
        lines.append(line)
    
    content = '\n'.join(lines)
    
    # Pattern to match command invocations
    # Matches: command, ./command, /path/to/command
    # Handles: command args, command | command, command && command
    patterns = [
        r'\b([a-z][a-z0-9_-]*)\s+(?:install|get|add)',  # package manager patterns
        r'\b([a-z][a-z0-9_-]*)\s',  # basic commands
        r'\.\/([a-z][a-z0-9_-]*)',  # local scripts
    ]
    
    for pattern in patterns:
        matches = re.findall(pattern, content, re.IGNORECASE)
        commands.extend(matches)
    
    # Deduplicate
    return list(set(commands))


def is_system_tool(command: str) -> bool:
    """Check if a command is a system tool."""
    return command.lower() in SYSTEM_TOOLS


def is_package_manager(command: str) -> bool:
    """Check if a command is a package manager."""
    return command.lower() in PACKAGE_MANAGERS


def is_docker_command(command: str) -> bool:
    """Check if a command is a Docker command."""
    return command.lower() in DOCKER_COMMANDS


@pytest.mark.property
@settings(max_examples=100)
@given(
    script_lines=st.lists(
        st.one_of(
            # System tool commands (valid)
            st.sampled_from([
                'echo "Hello"',
                'grep pattern file.txt',
                'sed "s/old/new/" file.txt',
                'awk "{print $1}" file.txt',
                'find . -name "*.sh"',
                'make test',
                'git status',
                'curl https://example.com',
            ]),
            # Package manager commands (violations)
            st.sampled_from([
                'dnf install python3',
                'apt install nodejs',
                'pip install requests',
                'npm install express',
                'gem install rails',
            ]),
            # Docker commands (should be in Make)
            st.sampled_from([
                'docker run ubuntu',
                'docker-compose up',
            ]),
            # Comments and empty lines
            st.sampled_from([
                '# This is a comment',
                '',
                '  ',
            ]),
        ),
        min_size=1,
        max_size=20
    )
)
def test_property_15_script_tool_usage_validation(script_lines):
    """
    Feature: dependency-minimization-audit, Property 15: Script tool usage validation
    
    For any script file, the validation function should correctly identify
    whether tools used are system tools, package managers, or Docker commands.
    
    This property verifies that the scanner correctly classifies commands:
    1. System tools are identified as valid
    2. Package managers are identified as violations
    3. Docker commands are identified (should be wrapped in Make)
    
    Validates: Requirements 9.4
    """
    # Create script content
    script_content = '#!/bin/bash\n' + '\n'.join(script_lines)
    
    # Extract commands from script
    commands = extract_commands_from_script(script_content)
    
    # Check each command and categorize
    violations = []
    for command in commands:
        if is_package_manager(command):
            # Package managers are CRITICAL violations
            violations.append({
                'command': command,
                'type': 'package_manager',
                'severity': 'critical'
            })
        elif is_docker_command(command):
            # Docker commands should be in Make targets (HIGH violation if direct)
            violations.append({
                'command': command,
                'type': 'docker_direct',
                'severity': 'high'
            })
        elif not is_system_tool(command):
            # Unknown tools should be containerized (MEDIUM violation)
            violations.append({
                'command': command,
                'type': 'unknown_tool',
                'severity': 'medium'
            })
    
    # Property 1: Package manager detection is accurate
    # For any command in the script, if it's a known package manager,
    # it should be detected as a violation
    for line in script_lines:
        for pkg_mgr in PACKAGE_MANAGERS:
            if pkg_mgr in line.lower():
                # Verify this package manager was detected
                detected_pkg_mgrs = [v['command'] for v in violations if v['type'] == 'package_manager']
                assert pkg_mgr in detected_pkg_mgrs or any(pkg_mgr in cmd for cmd in detected_pkg_mgrs), \
                    f"Package manager '{pkg_mgr}' in line '{line}' was not detected"
    
    # Property 2: System tools are not flagged as violations
    # For any command that is a system tool, it should NOT appear in violations
    for command in commands:
        if is_system_tool(command):
            violation_commands = [v['command'] for v in violations]
            assert command not in violation_commands, \
                f"System tool '{command}' was incorrectly flagged as a violation"
    
    # Property 3: Classification is consistent
    # A command cannot be both a system tool and a package manager
    for command in commands:
        is_sys = is_system_tool(command)
        is_pkg = is_package_manager(command)
        is_docker = is_docker_command(command)
        
        # A command should be in at most one category
        categories_count = sum([is_sys, is_pkg, is_docker])
        assert categories_count <= 1, \
            f"Command '{command}' is in multiple categories: sys={is_sys}, pkg={is_pkg}, docker={is_docker}"
