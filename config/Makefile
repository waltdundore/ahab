# ==============================================================================
# Ahab Config - Makefile
# ==============================================================================
# Configuration management for Ahab infrastructure
#
# IMPORTANT: This is a configuration directory within ahab.
# For infrastructure commands (install, deploy, test), use:
#   cd .. && make <command>
#
# This Makefile only provides git workflow commands for this directory.
# ==============================================================================

# Include shared configuration and common targets
include ../Makefile.config
include ../Makefile.common

.PHONY: help install deploy test ssh clean

help:
	$(call SUBDIR_HELP,Config,configuration)

# Catch common commands and redirect to ahab
install deploy test ssh clean:
	$(call SUBDIR_REDIRECT,config,configuration)
