# Repository Comparison Audit System

![Ahab Logo](docs/images/ahab-logo.png)

**Systematic comparison of current repository against original to identify gaps and opportunities.**

## Overview

This audit system compares the current ahab repository against the original GitHub repository to:

1. **Identify gaps** - Missing files, features, documentation
2. **Validate principles** - Check adherence to all 11 core principles
3. **Assess quality** - NASA standards, DRY violations, test coverage
4. **Find improvements** - Areas where we're better than original
5. **Generate actionable report** - Prioritized findings feeding into IMPROVEMENTS.md

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run audit with default configuration
python -m audit.cli

# Run audit with custom configuration
python -m audit.cli --config audit-config.yml

# Run specific modules only
python -m audit.cli --modules documentation principles

# Set severity threshold
python -m audit.cli --severity HIGH
```

## Architecture

```
audit/
├── __init__.py           # Package initialization
├── models.py             # Core data models (Finding, Repository, AuditReport)
├── base.py               # Abstract base class for audit modules
├── config.py             # Configuration management
├── orchestrator.py       # Audit coordination and execution
├── report.py             # Report generation
├── cli.py                # Command-line interface
│
├── auditors/             # Audit module implementations
│   ├── __init__.py
│   ├── documentation.py  # Documentation completeness auditor
│   ├── principles.py     # Core principles adherence auditor
│   ├── features.py       # Feature completeness auditor
│   └── quality.py        # Code quality auditor
│
├── tests/                # Test suite
│   ├── test_models.py
│   ├── test_auditors.py
│   └── test_properties.py
│
├── requirements.txt      # Python dependencies
├── pytest.ini            # Pytest configuration
├── audit-config.yml      # Default configuration
└── README.md             # This file
```

## Audit Modules

### Documentation Auditor
- Compares documentation files between repositories
- Validates documentation structure and organization
- Checks cross-references and internal links
- Identifies missing or outdated content
- Verifies documentation follows DRY principles

### Principles Auditor
- Validates adherence to all 11 core principles
- Checks for "Eat Your Own Dog Food" violations (direct tool usage)
- Verifies Single Source of Truth (ahab.conf usage)
- Validates NASA Power of 10 compliance
- Checks for teaching mindset in comments and documentation

### Features Auditor
- Compares Makefile targets
- Verifies all scripts, roles, and playbooks exist
- Checks test suite completeness
- Validates directory structure
- Identifies missing functionality

### Quality Auditor
- Runs NASA Power of 10 validation
- Identifies DRY violations
- Checks test coverage
- Validates error handling
- Measures code quality metrics

## Configuration

Edit `audit-config.yml` to customize:

```yaml
audit:
  original_repo: "https://github.com/waltdundore/ahab"
  current_repo: "."
  modules:
    - documentation
    - principles
    - features
    - quality
  severity_threshold: "MEDIUM"
  parallel_execution: true
  cache_enabled: true
  output_file: "audit-report.md"
```

## Output

The audit generates a markdown report with:

- **Executive Summary** - Total findings by severity and category
- **Critical Findings** - Issues that block core functionality
- **High Findings** - Important issues to address
- **Medium Findings** - Should fix but not urgent
- **Low Findings** - Nice to have improvements
- **Improvement Opportunities** - Areas where current is better
- **Recommendations Summary** - Prioritized action items with effort estimates

## Testing

```bash
# Run all tests
pytest

# Run unit tests only
pytest -m unit

# Run property tests only
pytest -m property

# Run with coverage
pytest --cov=audit --cov-report=html
```

## Integration with Workflow

Add to Makefile:

```makefile
audit-repo:
	@python -m audit.cli
	@echo "Audit complete. See audit-report.md"
```

Add to pre-release checklist:

```bash
make audit-repo
# Review audit-report.md
# Address critical and high findings
# Update IMPROVEMENTS.md with findings
```

## Development

### Adding a New Audit Module

1. Create new file in `auditors/` directory
2. Inherit from `AuditModule` base class
3. Implement `audit()` and `get_name()` methods
4. Add module name to config
5. Write tests

Example:

```python
from audit.base import AuditModule
from audit.models import Finding, Repository, Severity, Category

class MyAuditor(AuditModule):
    def audit(self, original: Repository, current: Repository) -> List[Finding]:
        findings = []
        # Implement audit logic
        return findings
    
    def get_name(self) -> str:
        return "My Auditor"
```

### Writing Property Tests

Use hypothesis for property-based testing:

```python
from hypothesis import given, strategies as st
from audit.models import Finding, Severity, Category

@given(st.text(), st.text())
def test_finding_has_required_fields(title, description):
    finding = Finding(
        severity=Severity.HIGH,
        category=Category.QUALITY,
        title=title,
        description=description,
        recommendation="Fix it",
        effort_estimate="1 hour",
        related_requirement="1.1"
    )
    assert finding.title == title
    assert finding.description == description
```

## Troubleshooting

**Import errors**:
```bash
# Ensure you're in the ahab directory
cd ahab
python -m audit.cli
```

**Missing dependencies**:
```bash
pip install -r audit/requirements.txt
```

**Permission errors**:
```bash
# Ensure audit directory is readable
chmod -R 755 audit/
```

## Future Enhancements

- [ ] Web dashboard for viewing results
- [ ] Continuous monitoring (run on every commit)
- [ ] Trend analysis (track findings over time)
- [ ] AI-powered suggestions
- [ ] Auto-remediation for simple issues

## License

Same as parent project (CC BY-NC-SA 4.0)
