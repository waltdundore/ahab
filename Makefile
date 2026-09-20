# ==============================================================================
# Ahab Control - Makefile
# ==============================================================================
# Single source of truth: ahab.conf
# Core command: make install [modules...]
# ==============================================================================

# Makefile.common removed per BLUEPRINT D-18 (single Makefile; helpers are no-ops)

# Include safety system (optional - for advanced safety checks)
-include docs/development/Makefile.safety

.PHONY: help install clean status ssh test test-security test-security-standards test-integration-simple test-refs test-nasa audit bootstrap check-prerequisites install-prerequisites network-switches network-switches-version network-switches-test milestone-1 milestone-2 milestone-3 milestone-4 milestone-5 milestone-6 milestone-7 milestone-8 milestone-status milestone-reset

# Default target
all: help

help:
	$(call HELP_HEADER,Ahab Control)
	@echo "Setup Commands:"
	@echo "  make check-prerequisites   - Check if required tools are installed"
	@echo "  make install-prerequisites - Install Vagrant, VirtualBox, Ansible, Docker"
	@echo "  make bootstrap            - Set up repository structure"
	@echo ""
	@echo "Network Switch Commands:"
	@echo "  make network-switches       - Run all switch tasks"
	@echo "  make network-switches-version - Version info only"
	@echo "  make network-switches-test  - Connectivity test"
	@echo ""
	@echo "Core Commands:"
	@echo "  make install              - Create workstation VM"
	@echo "  make status               - Show system status"
	@echo "  make ssh                  - SSH into workstation"
	@echo "  make clean                - Destroy workstation VM"
	@echo ""
	@echo "Development Commands:"
	@echo "  make test                 - Run all tests"
	@echo "  make test-workstation     - Test workstation VM environment (⚠️ Run before physical deployment)"
	@echo "  make audit                - Run accountability audit"
	@echo ""
	@echo "Secrets Management Commands:"
	@echo "  make setup-secrets        - Set up private secrets repository integration"
	@echo "  make check-secrets-access - Check access to private secrets repository"
	@echo "  make test-security-real   - Run security tests with real patterns"
	@echo "  make test-security-sanitized - Run security tests with sanitized examples"
	@echo ""
	@echo "Milestone Commands (8-Step Deployment Pipeline):"
	@echo "  make milestone-1          - Verify workstation installation"
	@echo "  make milestone-2..8       - (not yet implemented; fail loudly)"
	@echo "  make milestone-status     - Show progress (all 8 steps)"
	@echo "  make milestone-reset      - (not yet implemented; fails loudly)"
	@echo ""
	@echo "Examples:"
	@echo "  make install              # Just the workstation"
	@echo "  make test                 # Run all tests"
	$(call HELP_FOOTER)

# Extract module arguments (everything after 'install' or 'generate-compose')
MODULES := $(filter-out install generate-compose deploy,$(MAKECMDGOALS))

# ==============================================================================
# Setup Commands
# ==============================================================================

bootstrap:
	$(call SHOW_SECTION,Ahab Bootstrap - Repository Setup)
	@echo "→ Running: ./bootstrap.sh"
	@echo "   Purpose: Set up four-repository structure with proper symlinks"
	@./bootstrap.sh
	@echo "✅ Bootstrap Complete"

check-prerequisites:
	$(call SHOW_SECTION,Checking Ahab Prerequisites)
	@echo "→ Running: ./scripts/check-prerequisites.sh"
	@echo "   Purpose: Verify all required tools are installed"
	@./scripts/check-prerequisites.sh

install-prerequisites:
	$(call SHOW_SECTION,Installing Ahab Prerequisites)
	@echo "→ Running: ansible-playbook playbooks/install-prerequisites.yml --ask-become-pass"
	@echo "   Purpose: Install Vagrant, VirtualBox, Ansible, Docker on the control node"
	@ansible-playbook playbooks/install-prerequisites.yml --ask-become-pass

# ==============================================================================
# Network Switch Commands (HP Aruba / Ruckus)
# ==============================================================================
# Inventory is copied from the committed example before first use:
#   cp inventory/dev/network-switches.yml.example inventory/dev/network-switches.yml

network-switches:
	$(call SHOW_SECTION,Network Switches - All Tasks)
	@echo "→ Running: ansible-playbook -i inventory/dev/network-switches.yml playbooks/network-switches.yml"
	@ansible-playbook -i inventory/dev/network-switches.yml playbooks/network-switches.yml

network-switches-version:
	$(call SHOW_SECTION,Network Switches - Version Info)
	@ansible-playbook -i inventory/dev/network-switches.yml playbooks/network-switches.yml --tags show_version

network-switches-test:
	$(call SHOW_SECTION,Network Switches - Connectivity Test)
	@ansible-playbook -i inventory/dev/network-switches.yml playbooks/network-switches.yml --tags test

# ==============================================================================
# Core Commands
# ==============================================================================

install:
	$(call SHOW_SECTION,Ahab - Install)
	@if [ -n "$(MODULES)" ]; then \
		echo "Workstation + Modules: $(MODULES)"; \
	else \
		echo "Workstation only"; \
	fi
	@echo ""
	@echo "→ Running: vagrant up --no-destroy-on-error"
	@echo "   Purpose: Create Fedora 43 VM with Docker and Ansible"
	@vagrant up --no-destroy-on-error || exit 1
	@echo ""
	@echo "→ Running: vagrant ssh -c 'sudo chown -R vagrant:vagrant /home/vagrant/ahab 2>/dev/null || true'"
	@echo "   Purpose: Fix permissions"
	@vagrant ssh -c "sudo chown -R vagrant:vagrant /home/vagrant/ahab 2>/dev/null || true"
	@echo ""
	@if [ -n "$(MODULES)" ]; then \
		echo "→ Deploying modules: $(MODULES)"; \
		echo "→ Running: vagrant ssh -c 'cd /home/vagrant/ahab && python3 scripts/generate-docker-compose.py $(MODULES)'"; \
		echo "   Purpose: Generate docker-compose.yml for modules"; \
		vagrant ssh -c "cd /home/vagrant/ahab && python3 scripts/generate-docker-compose.py $(MODULES)" || exit 1; \
		echo "→ Running: vagrant ssh -c 'cd /home/vagrant/ahab/generated && docker-compose up -d'"; \
		echo "   Purpose: Start services in Docker containers"; \
		vagrant ssh -c "cd /home/vagrant/ahab/generated && docker-compose up -d" || exit 1; \
		echo ""; \
		echo "✅ Modules deployed: $(MODULES)"; \
	fi
	@echo ""
	@echo "✅ Ready - Access: vagrant ssh"

status:
	$(call SHOW_SECTION,System Status)
	@echo "→ Running: vagrant status"
	@echo "   Purpose: Check workstation VM status"
	@if vagrant status 2>/dev/null | grep -q "running"; then \
		echo "✓ Workstation: Running"; \
		echo ""; \
		echo "→ Checking services..."; \
		vagrant ssh -c "docker ps --format 'table {{.Names}}\t{{.Status}}'" 2>/dev/null || echo "  No services running"; \
	elif vagrant status 2>/dev/null | grep -q "poweroff\|saved\|aborted"; then \
		echo "⚠ Workstation: Stopped"; \
		echo "  Run: make install"; \
	else \
		echo "○ Workstation: Not Created"; \
		echo "  Run: make install"; \
	fi
	@echo ""
	@echo "✅ Status Check Complete"

ssh:
	@echo "→ Running: vagrant ssh"
	@echo "   Purpose: SSH into workstation VM"
	@vagrant ssh

clean:
	@echo "→ Running: vagrant destroy -f"
	@echo "   Purpose: Destroy workstation VM"
	@vagrant destroy -f 2>/dev/null || true
	@rm -rf .vagrant
	@echo "✓ Clean complete"

# ==============================================================================
# Testing Commands
# ==============================================================================

test:
	$(call SHOW_SECTION,Running Ahab Test Suite)
	@echo "This runs:"
	@echo "  1. NASA Power of 10 standards validation"
	@echo "  2. Security standards validation"
	@echo "  3. Simple integration tests (no VM required)"
	@echo "  4. Reference integrity (Makefile + playbooks point at real files/targets)"
	@echo ""
	@if $(MAKE) test-nasa && $(MAKE) test-security-standards && $(MAKE) test-integration-simple && $(MAKE) test-refs; then \
		echo ""; \
		echo "=========================================="; \
		echo "✅ All Tests Passed"; \
		echo "=========================================="; \
		echo ""; \
		echo "Additional test commands:"; \
		echo "  make audit             - Run accountability audit"; \
		bash scripts/record-test-pass.sh; \
	else \
		echo ""; \
		echo "=========================================="; \
		echo "❌ Tests Failed"; \
		echo "=========================================="; \
		echo ""; \
		bash scripts/record-test-fail.sh; \
		exit 1; \
	fi

test-security:
	$(call SHOW_SECTION,Security Pattern Validation)
	@echo "→ Running: ./scripts/ci/validate-security-patterns.sh"
	@echo "   Purpose: Validate security patterns without false positives"
	@if [ -f "scripts/ci/validate-security-patterns.sh" ]; then \
		./scripts/ci/validate-security-patterns.sh; \
	else \
		echo "⚠ Security validation script not found"; \
		exit 1; \
	fi

test-security-standards:
	$(call SHOW_SECTION,Validating Security Standards)
	@echo "→ Running: bash scripts/validate-security-standards.sh"
	@echo "   Purpose: Validate security and code quality standards"
	@if [ -f "scripts/validate-security-standards.sh" ]; then \
		bash scripts/validate-security-standards.sh; \
	else \
		echo "⚠ Security standards validation script not found"; \
		exit 1; \
	fi

test-integration-simple:
	$(call SHOW_SECTION,Running Simple Integration Tests)
	@echo "→ Running: bash tests/integration/test-apache-simple.sh"
	@echo "   Purpose: Run simple integration tests"
	@if [ -f "tests/integration/test-apache-simple.sh" ]; then \
		bash tests/integration/test-apache-simple.sh || exit 1; \
		echo "✅ Simple integration tests passed"; \
	else \
		echo "⚠ No simple integration tests found"; \
	fi

test-refs:
	$(call SHOW_SECTION,Reference Integrity Check)
	@echo "→ Running: bash scripts/ci/check-file-refs.sh"
	@echo "   Purpose: Fail if the Makefile or playbooks reference missing files or make targets"
	@if [ -f "scripts/ci/check-file-refs.sh" ]; then \
		bash scripts/ci/check-file-refs.sh; \
	else \
		echo "❌ Reference check script not found"; \
		exit 1; \
	fi

test-nasa:
	$(call SHOW_SECTION,Validating NASA Power of 10 Standards)
	@echo "→ Running: bash scripts/validate-nasa-standards.sh"
	@echo "   Purpose: Validate code compliance with NASA safety-critical standards"
	@if [ -f "scripts/validate-nasa-standards.sh" ]; then \
		bash scripts/validate-nasa-standards.sh || exit 1; \
		echo "✅ NASA Power of 10 standards validation passed"; \
	else \
		echo "❌ NASA validation script not found"; \
		exit 1; \
	fi

test-workstation:
	$(call SHOW_SECTION,Testing Workstation VM Environment)
	@echo "→ Running: vagrant ssh -c 'cd /home/vagrant/ahab && make test-on-workstation'"
	@echo "   Purpose: Validate workstation environment before physical deployment"
	@if ! vagrant status 2>/dev/null | grep -q "running"; then \
		echo "❌ Workstation not running - Run: make install"; \
		exit 1; \
	fi
	@vagrant ssh -c "cd /home/vagrant/ahab && make test-on-workstation"
	@echo "✅ Workstation validation complete"

test-on-workstation:
	$(call SHOW_SECTION,Running Tests ON Workstation VM)
	@echo "This validates the actual deployment environment:"
	@echo "  1. Fedora 43 environment validation"
	@echo "  2. Docker functionality testing"
	@echo "  3. Service deployment testing"
	@echo "  4. Ansible execution testing"
	@echo "  5. Security validation"
	@echo ""
	@if [ -f "tests/workstation/test-environment.sh" ]; then \
		bash tests/workstation/test-environment.sh || exit 1; \
	else \
		echo "⚠ Workstation environment tests not found"; \
	fi
	@if [ -f "tests/workstation/test-docker.sh" ]; then \
		bash tests/workstation/test-docker.sh || exit 1; \
	else \
		echo "⚠ Workstation Docker tests not found"; \
	fi
	@echo "✅ All workstation tests passed"

# ==============================================================================
# Milestone Commands - 8-Step Deployment Pipeline
# ==============================================================================

milestone-1:
	$(call SHOW_SECTION,Milestone 1 - Workstation Installation Verification)
	@echo "→ Running: ./scripts/milestone-1-verify-workstation.sh"
	@echo "   Purpose: Verify workstation is properly installed and configured"
	@./scripts/milestone-1-verify-workstation.sh

# Milestones 2-8 are part of the 8-step pipeline (see milestone-status.sh)
# but are not yet implemented. They fail LOUDLY via a shared helper instead of
# pointing at scripts that do not exist (D-39: no fabricated success).
milestone-2:
	$(call SHOW_SECTION,Milestone 2 - Target Server Definition)
	@./scripts/lib/milestone-not-implemented.sh 2 "Target Server Definition"

milestone-3:
	$(call SHOW_SECTION,Milestone 3 - Connectivity Verification)
	@./scripts/lib/milestone-not-implemented.sh 3 "Connectivity Verification"

milestone-4:
	$(call SHOW_SECTION,Milestone 4 - Vagrant Test Deployment)
	@./scripts/lib/milestone-not-implemented.sh 4 "Vagrant Test Deployment"

milestone-5:
	$(call SHOW_SECTION,Milestone 5 - Playbook Verification)
	@./scripts/lib/milestone-not-implemented.sh 5 "Playbook Verification"

milestone-6:
	$(call SHOW_SECTION,Milestone 6 - Real Server Deployment)
	@./scripts/lib/milestone-not-implemented.sh 6 "Real Server Deployment"

milestone-7:
	$(call SHOW_SECTION,Milestone 7 - Final System Verification)
	@./scripts/lib/milestone-not-implemented.sh 7 "Final System Verification"

milestone-8:
	$(call SHOW_SECTION,Milestone 8 - Production Readiness)
	@./scripts/lib/milestone-not-implemented.sh 8 "Production Readiness"

milestone-status:
	$(call SHOW_SECTION,Milestone Progress Status)
	@echo "→ Running: ./scripts/milestone-status.sh"
	@echo "   Purpose: Show current progress through deployment pipeline"
	@./scripts/milestone-status.sh

milestone-reset:
	$(call SHOW_SECTION,Reset Milestone Progress)
	@./scripts/lib/milestone-not-implemented.sh reset "Reset Milestone Progress"

# ==============================================================================
# Audit Commands
# ==============================================================================

audit:
	$(call SHOW_SECTION,Running Accountability Audit)
	@echo "→ Running: bash scripts/audit-accountability.sh"
	@echo "   Purpose: Audit code for accountability and empathy standards"
	@bash scripts/audit-accountability.sh

# ==============================================================================
# Secrets Management Commands
# ==============================================================================

.PHONY: setup-secrets check-secrets-access test-security-real test-security-sanitized

setup-secrets:
	@echo "→ Running: ./scripts/setup-secrets-repo.sh"
	@echo "   Purpose: Set up private secrets repository integration"
	@./scripts/setup-secrets-repo.sh

check-secrets-access:
	@echo "→ Running: ./scripts/setup-secrets-repo.sh check"
	@echo "   Purpose: Check if private secrets repository is accessible"
	@./scripts/setup-secrets-repo.sh check

test-security-real:
	@echo "→ Running: ./tests/property/test-secret-detection.sh"
	@echo "   Purpose: Run security tests with real patterns (requires private repo)"
	@if [ -f tests/property/test-secret-detection.sh ]; then \
		./tests/property/test-secret-detection.sh; \
	else \
		echo "Real patterns not available. Run 'make setup-secrets' first."; \
		exit 1; \
	fi

test-security-sanitized:
	@echo "→ Running: ./tests/property/test-secret-detection.sh.example"
	@echo "   Purpose: Run security tests with sanitized patterns (public)"
	@if [ -f tests/property/test-secret-detection.sh.example ]; then \
		./tests/property/test-secret-detection.sh.example; \
	else \
		echo "Example file not found. Run 'make setup-secrets' to create it."; \
		exit 1; \
	fi

# D-39 / BLUEPRINT law 11: loud-failing catch-all (replaces the two silent
# `%: @:` no-ops that once let ANY unknown target "succeed" — a cheat vector:
# a model ran `make <anything>` and reported fabricated success). One
# authoritative rule, at the END of the file; real targets above always win.
# Module installs dispatch via `make install MODULES=<names>`, never via
# positional target words — a bare word here is a typo and must exit non-zero.
%: ; @echo "make: no such target: $@ — run 'make help' for real targets" >&2; exit 2