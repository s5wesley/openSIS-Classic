# Use an official PHP image with Apache
FROM php:7.4-apache

# Set the working directory inside the container
WORKDIR /var/www/html

# Install required PHP extensions
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd mysqli pdo pdo_mysql zip \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

# Copy OpenSIS application files to the container
COPY . .

# Set correct permissions (Adjust as needed)
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose the default web server port
EXPOSE 80

# Start Apache in foreground mode
CMD ["apache2-foreground"]
