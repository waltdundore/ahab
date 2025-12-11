# ==============================================================================
# Apache HTTP Server - Dockerfile (STIG Compliant)
# ==============================================================================
# Modular Apache container for Ahab
#
# Build:
#   docker build -t ahab/apache:1.0.0 .
#
# Run standalone:
#   docker run -d -p 80:80 --name apache ahab/apache:1.0.0
#
# Run with docker-compose:
#   See docker-compose.yml (generated from MODULE.yml)
#
# STIG Compliance:
#   V-235783: Runs as www-data (non-root)
#   V-235790: Uses Alpine (minimal base image)
#   V-235792: Health check configured
#
# Note: Apache needs NET_BIND_SERVICE capability to bind to port 80
#       Add in docker-compose.yml: cap_add: [NET_BIND_SERVICE]
# ==============================================================================

FROM httpd:2.4-alpine

LABEL maintainer="Ahab Project"
LABEL com.ahab.module="apache"
LABEL com.ahab.version="1.0.0"
LABEL com.ahab.description="Apache HTTP Server"

# Install additional tools (as root)
RUN apk add --no-cache \
    curl \
    bash

# Create directories with correct ownership
RUN mkdir -p /usr/local/apache2/htdocs \
    && mkdir -p /usr/local/apache2/conf/extra \
    && chown -R www-data:www-data /usr/local/apache2/htdocs

# Copy custom configuration (if exists)
COPY config/httpd.conf /usr/local/apache2/conf/httpd.conf 2>/dev/null || true

# Copy default index page
COPY html/index.html /usr/local/apache2/htdocs/index.html 2>/dev/null || \
    echo '<html><body><h1>Apache is running!</h1><p>Powered by Ahab</p></body></html>' > /usr/local/apache2/htdocs/index.html

# Switch to non-root user (STIG V-235783)
# Note: Apache httpd-foreground script handles user switching internally
# But we make it explicit for STIG compliance
USER www-data

# Health check (STIG V-235792)
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=10s \
    CMD httpd -t || exit 1

# Expose ports
EXPOSE 80 443

# Start Apache
CMD ["httpd-foreground"]
