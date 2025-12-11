# ==============================================================================
# PHP-FPM - Dockerfile (STIG Compliant)
# ==============================================================================
# Modular PHP-FPM container for Ahab
#
# Build:
#   docker build -t ahab/php:1.0.0 .
#
# Run with Apache:
#   See docker-compose.yml (generated from MODULE.yml)
#
# Dependencies:
#   - Apache (webserver)
#
# STIG Compliance:
#   V-235783: Runs as www-data (non-root)
#   V-235790: Uses Alpine (minimal base image)
#   V-235792: Health check configured
# ==============================================================================

FROM php:8.2-fpm-alpine

LABEL maintainer="Ahab Project"
LABEL com.ahab.module="php"
LABEL com.ahab.version="1.0.0"
LABEL com.ahab.description="PHP-FPM"

# Install PHP extensions and tools (as root)
RUN apk add --no-cache \
    curl \
    bash \
    && docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    opcache

# Install additional PHP extensions
RUN apk add --no-cache \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Copy PHP configuration
COPY config/php.ini /usr/local/etc/php/php.ini 2>/dev/null || \
    echo "memory_limit = 256M\nupload_max_filesize = 64M\npost_max_size = 64M\nmax_execution_time = 30" > /usr/local/etc/php/php.ini

# Create application directory with correct ownership
RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

# Copy test PHP file
COPY app/index.php /var/www/html/index.php 2>/dev/null || \
    echo '<?php phpinfo(); ?>' > /var/www/html/index.php

# Switch to non-root user (STIG V-235783)
# Note: PHP-FPM already runs as www-data by default, but we make it explicit
USER www-data

# Health check (STIG V-235792)
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=10s \
    CMD php-fpm -t || exit 1

# Expose PHP-FPM port
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm"]
