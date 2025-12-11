# Contributing to Ahab

Thank you for your interest in contributing to Ahab! This document provides guidelines for contributing to the project.

## Ways to Contribute

### 🐛 Report Bugs
- Use the [Bug Report template](https://github.com/waltdundore/ahab/issues/new?template=bug_report.yml)
- Include detailed steps to reproduce the issue
- Provide system information (OS, virtualization provider, etc.)
- Include command output and error messages

### 💡 Suggest Features
- Use the [Feature Request template](https://github.com/waltdundore/ahab/issues/new?template=feature_request.yml)
- Explain the problem your feature would solve
- Describe your proposed solution
- Consider the impact on different user types (students, teachers, admins)

### ❓ Ask Questions
- Use the [Question template](https://github.com/waltdundore/ahab/issues/new?template=question.yml) for specific help
- Check [Discussions](https://github.com/waltdundore/ahab/discussions) for community Q&A
- Review the [documentation](https://waltdundore.github.io) first

### 🔧 Code Contributions
- Fork the repository
- Create a feature branch
- Follow our coding standards (see below)
- Add tests for new functionality
- Update documentation as needed
- Submit a pull request

## Development Guidelines

### Before Contributing Code

1. **Read the development rules**: Check `DEVELOPMENT_RULES.md` for core principles
2. **Use make commands**: Always use `make test`, `make install`, etc. (never run scripts directly)
3. **Test immediately**: Run `make test` after any code change
4. **Follow security standards**: All code must pass security audits

### Coding Standards

- **Shell scripts**: Must pass `shellcheck` validation
- **Python code**: Follow PEP 8, use type hints
- **Ansible playbooks**: Must pass `ansible-lint`
- **Functions**: Maximum 60 lines (NASA Rule #4)
- **No hardcoded secrets**: Use environment variables
- **No root containers**: All Docker containers run as non-root

### Testing Requirements

- All changes must pass: `make test`
- Add tests for new functionality
- Test on the target platform (workstation VM, not host)
- Verify security compliance: `make audit`

### Documentation

- Update relevant documentation for any changes
- Use clear, educational language
- Include examples and use cases
- Follow the transparency principle (show what commands do)

## Pull Request Process

1. **Create an issue first** (unless it's a trivial fix)
2. **Fork and branch**: Create a feature branch from `dev`
3. **Make changes**: Follow the guidelines above
4. **Test thoroughly**: Ensure all tests pass
5. **Update docs**: Include documentation updates
6. **Submit PR**: Target the `dev` branch, not `main`

### PR Requirements

- [ ] All tests pass (`make test`)
- [ ] Security audit passes (`make audit`)
- [ ] Documentation updated
- [ ] Clear commit messages
- [ ] Linked to relevant issue

## Code Review Process

1. **Automated checks**: CI/CD runs tests and security scans
2. **Manual review**: Maintainers review code and approach
3. **Testing**: Changes tested on multiple platforms
4. **Merge**: Approved changes merged to `dev`, then promoted to `main`

## Community Guidelines

### Be Respectful
- Use inclusive language
- Be patient with beginners
- Provide constructive feedback
- Help others learn

### Be Educational
- Explain your reasoning
- Share knowledge and resources
- Help others understand the "why" behind decisions
- Remember that many users are students learning infrastructure

### Be Collaborative
- Discuss ideas openly
- Consider different perspectives
- Work together to find the best solutions
- Share credit and celebrate contributions

## Getting Help

- **Questions**: Use [GitHub Issues](https://github.com/waltdundore/ahab/issues/new?template=question.yml)
- **Discussions**: Join [GitHub Discussions](https://github.com/waltdundore/ahab/discussions)
- **Documentation**: Check [waltdundore.github.io](https://waltdundore.github.io)
- **Security**: Report privately via [Security Advisories](https://github.com/waltdundore/ahab/security/advisories/new)

## Recognition

Contributors are recognized in:
- Release notes
- Contributors section in README
- Special thanks for significant contributions

Thank you for helping make infrastructure education better for everyone! 🚀