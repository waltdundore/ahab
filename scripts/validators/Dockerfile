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
RUN pip3 install --no-cache-dir flake8 pyyaml

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
