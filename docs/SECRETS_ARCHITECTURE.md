# Secrets Architecture - MANDATORY

**Status**: MANDATORY  
**Applies To**: All files containing secrets, secret patterns, or security tests  
**Last Updated**: December 11, 2025

---

## Core Principle

**Separate real secrets/patterns from sanitized examples. Never commit actual secret patterns to public repositories.**

This architecture solves GitHub push protection issues while maintaining security testing capabilities by using a private repository for real patterns and public sanitized examples.

---

## Repository Structure

### Public Repository (ahab)
- Contains sanitized examples with PLACEHOLDER patterns
- Provides setup scripts for private repository integration
- Includes documentation and architecture specifications

### Private Repository (ahab-secrets)
- Contains real secret patterns for testing
- Integrated as git submodule
- Requires authorized access

---

## Setup Instructions

1. Run: `make setup-secrets` to integrate private repository
2. Or manually replace PLACEHOLDER patterns in example files
3. See documentation for complete setup process

---

## Benefits

- No real secret patterns in public repository
- GitHub push protection never triggered
- Controlled access to real patterns
- Easy setup process for developers

---

**This architecture ensures security while maintaining functionality.**
