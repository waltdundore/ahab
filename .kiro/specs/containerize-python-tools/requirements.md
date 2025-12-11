# Requirements: Containerize Python Tools

![Ahab Logo](../../docs/images/ahab-logo.png)

## Introduction

This specification addresses violations found by the dependency minimization audit. Currently, Python and PyYAML are installed via pip in the workstation VM, violating the "no package manager installations" principle. All Python tools should run in Docker containers instead.

## Glossary

- **Control Node**: The machine running Ansible commands (user's Mac)
- **Managed Node**: The VM being provisioned (workstation VM)
- **System Tool**: Built-in Unix/Linux utilities that don't require installation
- **Docker Container**: Isolated application runtime environment
- **generate-compose.py**: Python script that generates docker-compose.yml from module definitions

## Requirements

### Requirement 1: Containerize Python Script Execution

**User Story:** As a developer, I want Python scripts to run in Docker containers, so that I don't need to install Python packages via pip.

#### Acceptance Criteria

1. WHEN running generate-compose.py THEN the system SHALL execute it in a Docker container
2. WHEN the Docker container runs THEN it SHALL have Python and PyYAML pre-installed
3. WHEN the script executes THEN it SHALL have access to the modules directory
4. WHEN the script completes THEN it SHALL write output to the generated directory
5. WHEN using the container THEN the system SHALL use a minimal Python base image

### Requirement 2: Remove pip Dependencies

**User Story:** As a security engineer, I want to eliminate pip installations, so that the attack surface is minimized.

#### Acceptance Criteria

1. WHEN provisioning the workstation THEN the system SHALL NOT install python3-pip
2. WHEN provisioning the workstation THEN the system SHALL NOT run pip install commands
3. WHEN checking the repository THEN there SHALL be no requirements.txt at the root
4. WHEN running the audit THEN there SHALL be zero pip-related violations
5. WHEN the workstation is provisioned THEN Python MAY be installed as a system package (for Ansible)

### Requirement 3: Update Make Commands

**User Story:** As a user, I want Make commands to work transparently with Docker, so that I don't need to know about the containerization.

#### Acceptance Criteria

1. WHEN running make install THEN the system SHALL use Docker to generate compose files
2. WHEN the Docker command runs THEN it SHALL mount necessary directories
3. WHEN the command completes THEN the user SHALL see the same output as before
4. WHEN errors occur THEN the system SHALL display clear error messages
5. WHEN the container is not available THEN the system SHALL pull it automatically

### Requirement 4: Maintain Backward Compatibility

**User Story:** As a user, I want existing workflows to continue working, so that I don't need to change my commands.

#### Acceptance Criteria

1. WHEN running make install apache THEN the system SHALL deploy Apache successfully
2. WHEN running make install apache mysql THEN the system SHALL deploy both modules
3. WHEN the script generates output THEN it SHALL be in the same format as before
4. WHEN errors occur THEN they SHALL be as informative as before
5. WHEN the system runs THEN performance SHALL be comparable to the previous implementation
