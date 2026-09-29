# ==============================================================================
# Validators Container - STIG Compliant
# ==============================================================================
# STIG V-235783: Non-root user
# STIG V-235790: Minimal base image (Alpine)
# STIG V-235792: Health check
# ==============================================================================

FROM bash:5.2-alpine3.19

# Install required tools (as root)
RUN apk add --no-cache \
    git \
    grep \
    findutils \
    shellcheck \
    python3 \
    py3-pip \
    docker-cli

# Install Python tools
# --only-binary :all: forbids running setup.py of an sdist at install time
# (arbitrary code execution as root in this build stage). Both packages ship
# wheels for this image: flake8 is py2.py3-none-any, PyYAML ships
# musllinux_1_2 cp311 wheels (Alpine 3.19 ships Python 3.11 / musl 1.2.5).
# Versions are unpinned: no exact pin exists in this repo (see
# docs/audits/2026-09-29-static-analysis-triage.md).
RUN pip3 install --no-cache-dir --only-binary :all: flake8 pyyaml

# Create non-root user (STIG V-235783)
RUN adduser -D -u 1000 validator

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER validator

# Health check (STIG V-235792)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD bash --version || exit 1

# Default command
CMD ["/bin/bash"]
