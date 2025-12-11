# ==============================================================================
# Ahab Control - Makefile
# ==============================================================================
# Single source of truth: ahab.conf
# Core command: make install [modules...]
# ==============================================================================

# Include common functions and patterns
include Makefile.common

# Include safety system (optional - for advanced safety checks)
-include docs/development/Makefile.safety

.PHONY: help install clean status ssh test test-security test-security-standards test-integration-simple test-nasa audit bootstrap check-prerequisites milestone-1 milestone-2 milestone-3 milestone-4 milestone-5 milestone-6 milestone-7 milestone-8 milestone-status milestone-reset

# Default target
all: help

help:
	$(call HELP_HEADER,Ahab Control)
	@echo "Setup Commands:"
	@echo "  make check-prerequisites  - Check if required tools are installed"
	@echo "  make bootstrap            - Set up repository structure"
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
	@echo "Git Publishing Commands:"
	@echo "  make publish              - Publish dev branch to GitHub"
	@echo "  make publish-all          - Publish all configured branches"
	@echo "  make publish-with-secrets - Publish all branches (handles GitHub push protection)"
	@echo "  make publish-now          - Immediately publish all branches (quick solution)"
	@echo "  make clean-and-publish    - Remove fake secrets, publish branches, restore sanitized"
	@echo "  make publish-status       - Show git publishing status"
	@echo ""
	@echo "Secrets Management Commands:"
	@echo "  make setup-secrets        - Set up private secrets repository integration"
	@echo "  make check-secrets-access - Check access to private secrets repository"
	@echo "  make test-security-real   - Run security tests with real patterns"
	@echo "  make test-security-sanitized - Run security tests with sanitized examples"
	@echo ""
	@echo "Milestone Commands (8-Step Deployment Pipeline):"
	@echo "  make milestone-1          - Verify workstation installation"
	@echo "  make milestone-2          - Define target servers"
	@echo "  make milestone-3          - Verify connectivity"
	@echo "  make milestone-4          - Test with Vagrant"
	@echo "  make milestone-5          - Verify playbooks"
	@echo "  make milestone-6          - Deploy to real server"
	@echo "  make milestone-7          - Final verification"
	@echo "  make milestone-8          - Production readiness"
	@echo "  make milestone-status     - Show progress"
	@echo "  make milestone-reset      - Reset progress"
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

# Allow module names as targets (prevents "No rule to make target" errors)
%:
	@:

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
	@echo ""
	@if $(MAKE) test-nasa && $(MAKE) test-security-standards && $(MAKE) test-integration-simple; then \
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

milestone-2:
	$(call SHOW_SECTION,Milestone 2 - Target Server Definition)
	@echo "→ Running: ./scripts/milestone-2-define-targets.sh"
	@echo "   Purpose: Guide user through defining target servers and inventory"
	@./scripts/milestone-2-define-targets.sh

milestone-3:
	$(call SHOW_SECTION,Milestone 3 - Connectivity Verification)
	@echo "→ Running: ./scripts/milestone-3-verify-connectivity.sh"
	@echo "   Purpose: Test SSH connectivity and credentials to target servers"
	@./scripts/milestone-3-verify-connectivity.sh

milestone-4:
	$(call SHOW_SECTION,Milestone 4 - Vagrant Test Deployment)
	@echo "→ Running: ./scripts/milestone-4-vagrant-test.sh"
	@echo "   Purpose: Test deployment on vanilla Vagrant VM"
	@./scripts/milestone-4-vagrant-test.sh

milestone-5:
	$(call SHOW_SECTION,Milestone 5 - Playbook Verification)
	@echo "→ Running: ./scripts/milestone-5-verify-playbooks.sh"
	@echo "   Purpose: Validate Ansible playbooks work correctly"
	@./scripts/milestone-5-verify-playbooks.sh

milestone-6:
	$(call SHOW_SECTION,Milestone 6 - Real Server Deployment)
	@echo "→ Running: ./scripts/milestone-6-deploy-real.sh"
	@echo "   Purpose: Deploy to actual target server using SSH"
	@./scripts/milestone-6-deploy-real.sh

milestone-7:
	$(call SHOW_SECTION,Milestone 7 - Final System Verification)
	@echo "→ Running: ./scripts/milestone-7-final-verification.sh"
	@echo "   Purpose: Comprehensive verification of deployed system"
	@./scripts/milestone-7-final-verification.sh

milestone-8:
	$(call SHOW_SECTION,Milestone 8 - Production Readiness)
	@echo "→ Running: ./scripts/milestone-8-production-ready.sh"
	@echo "   Purpose: Validate system is ready for production use"
	@./scripts/milestone-8-production-ready.sh

milestone-status:
	$(call SHOW_SECTION,Milestone Progress Status)
	@echo "→ Running: ./scripts/milestone-status.sh"
	@echo "   Purpose: Show current progress through deployment pipeline"
	@./scripts/milestone-status.sh

milestone-reset:
	$(call SHOW_SECTION,Reset Milestone Progress)
	@echo "→ Running: ./scripts/milestone-reset.sh"
	@echo "   Purpose: Reset milestone progress (start over)"
	@./scripts/milestone-reset.sh

# ==============================================================================
# Audit Commands
# ==============================================================================

audit:
	$(call SHOW_SECTION,Running Accountability Audit)
	@echo "→ Running: bash scripts/audit-accountability.sh"
	@echo "   Purpose: Audit code for accountability and empathy standards"
	@bash scripts/audit-accountability.sh
# ==============================================================================
# Git Publishing Commands
# ==============================================================================

.PHONY: publish publish-all publish-status publish-sync publish-with-secrets

publish:
	@echo "→ Running: ./scripts/git-publish $(filter-out publish,$(MAKECMDGOALS))"
	@echo "   Purpose: Publish branch to GitHub for collaboration and visibility"
	@./scripts/git-publish $(filter-out publish,$(MAKECMDGOALS))

publish-all:
	@echo "→ Running: ./scripts/git-publish all"
	@echo "   Purpose: Publish all configured branches to GitHub"
	@./scripts/git-publish all

publish-with-secrets:
	@echo "→ Running: ./scripts/git-publish-with-secrets all"
	@echo "   Purpose: Publish all branches while handling GitHub push protection for fake secrets"
	@./scripts/git-publish-with-secrets all

publish-now:
	@echo "→ Running: ./scripts/publish-now"
	@echo "   Purpose: Immediately publish all branches (handles GitHub push protection)"
	@./scripts/publish-now

clean-and-publish:
	@echo "→ Running: ./scripts/clean-and-publish"
	@echo "   Purpose: Remove fake secrets, publish all branches, restore with sanitized examples"
	@./scripts/clean-and-publish

publish-clean:
	@echo "→ Running: ./scripts/publish-clean-branch"
	@echo "   Purpose: Create clean branch without secret history and publish all branches"
	@./scripts/publish-clean-branch

publish-status:
	@echo "→ Running: ./scripts/git-publish status"
	@echo "   Purpose: Show current git publishing status and branch sync state"
	@./scripts/git-publish status

publish-sync:
	@echo "→ Running: ./scripts/git-publish sync"
	@echo "   Purpose: Sync dev branch with remote changes before publishing"
	@./scripts/git-publish sync

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

# Handle branch names as arguments to publish command
%:
	@: