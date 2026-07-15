FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libpq-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Configure GD extension
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# Install PHP extensions
RUN docker-php-ext-install -j$(nproc) \
    pgsql \
    pdo_pgsql \
    mysqli \
    pdo_mysql \
    gd \
    xml \
    zip \
    intl \
    bcmath \
    opcache \
    ftp

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Use production php.ini base config
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Copy custom configurations
COPY ./docker/php/php.ini /usr/local/etc/php/conf.d/ojs-production.ini
COPY ./docker/php/www.conf /usr/local/etc/php-fpm.d/www.conf

# Set working directory
WORKDIR /var/www/html

# Copy application files (excluding those in .dockerignore)
COPY . /var/www/html

# Run composer installation inside build context for dependencies
RUN composer install --no-dev --optimize-autoloader --no-plugins -d lib/pkp

# Create OJS files directory and set ownership/permissions
RUN mkdir -p /var/www/files && chown -R www-data:www-data /var/www/files \
    && chown -R www-data:www-data /var/www/html/cache /var/www/html/public

# Run container as non-root user (least privilege)
USER www-data

EXPOSE 9000
