# Implementation Plan: Containerize Python Tools

![Ahab Logo](../../docs/images/ahab-logo.png)

## Overview

Remove pip dependencies by running Python scripts in Docker containers. This eliminates the dependency minimization audit violations related to pip installations.

---

- [x] 1. Update Makefile to use Docker for Python scripts
  - Modify `install` target to run generate-compose.py in Docker container
  - Modify `deploy` target to run generate-compose.py in Docker container
  - Use `python:3.11-slim` base image
  - Mount workspace directory as volume
  - Install PyYAML in container at runtime
  - _Requirements: 1.1, 1.2, 1.3, 3.1, 3.2_

- [x] 2. Update provisioning playbook to remove pip
  - Remove `python3-pip` from workstation_packages list
  - Remove `python_packages` variable definition
  - Remove "Install Python dependencies" task
  - Keep `python3` system package (needed by Ansible)
  - Update installation summary to not mention pip
  - _Requirements: 2.1, 2.2, 2.5_

- [x] 3. Remove requirements.txt files
  - Delete `ahab/requirements.txt`
  - Keep `ahab/audit/requirements.txt` (used in Docker already)
  - Update documentation that references requirements.txt
  - _Requirements: 2.3_

- [x] 4. Test containerized Python execution
  - Test `make install` without modules
  - Test `make install apache`
  - Test `make install apache mysql`
  - Verify docker-compose.yml is generated correctly
  - Verify modules deploy successfully
  - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.2, 4.3_

- [x] 5. Run dependency audit and verify compliance
  - Run `make audit-dependencies`
  - Verify zero pip-related violations
  - Verify zero requirements.txt violations
  - Verify compliance score improves
  - Document before/after metrics
  - _Requirements: 2.4_

- [x] 6. Update documentation
  - Update README.md to remove pip installation instructions
  - Update TROUBLESHOOTING.md to remove pip references
  - Add note about Docker requirement for Python scripts
  - Update any other docs that mention requirements.txt
  - _Requirements: 4.4_

---

## Notes

- This is a quick remediation task, not part of the main audit implementation
- Focus on minimal changes to fix violations
- Maintain backward compatibility - users shouldn't notice the change
- Performance impact is minimal (2-3 seconds for pip install PyYAML)
- Future optimization: create custom Docker image with PyYAML pre-installed
