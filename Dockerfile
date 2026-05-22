# syntax=docker/dockerfile:1

### Stage 1: build client
FROM node:24 AS client-builder
WORKDIR /client-builder

# Install node packages
COPY selfoss/package.json .
COPY selfoss/client/package.json client/
COPY selfoss/client/package-lock.json client/
RUN npm run install-dependencies:client

# Build client
COPY selfoss/client/ client/
RUN npm run build


### Stage 2: final container
FROM php:8.5-apache

# Install runtime & development package dependencies & php extensions
# then clean-up dev package dependencies
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      unzip \
      libjpeg62-turbo libpng16-16 libpq5 libonig5 libtidy58 \
      libjpeg62-turbo-dev libpng-dev libpq-dev libonig-dev libtidy-dev \
    && update-ca-certificates --fresh \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install gd mbstring pdo_pgsql pdo_mysql tidy \
    && apt-get remove -y libjpeg62-turbo-dev libpng-dev libpq-dev libonig-dev libtidy-dev \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Apache modules
RUN a2enmod headers rewrite

RUN touch /usr/local/etc/php/conf.d/php-session.ini \
  && chown www-data:root /usr/local/etc/php/conf.d/php-session.ini \
  && chmod 644 /usr/local/etc/php/conf.d/php-session.ini
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Install Selfoss PHP dependencies
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY selfoss/composer.json .
COPY selfoss/composer.lock .
RUN COMPOSER_ALLOW_SUPERUSER=1 composer install --optimize-autoloader --no-dev
RUN rm /usr/bin/composer

# Install Selfoss and copy frontend from the first stage
WORKDIR /var/www/html
COPY selfoss/ .
COPY --from=client-builder /client-builder/public /var/www/html/public

# Use www-data user as owner and drop root user
RUN chown -R www-data:www-data /var/www/html/data \
  && sed -i 's/80/8080/g' /etc/apache2/ports.conf \
  && sed -i 's/:80/:8080/g' /etc/apache2/sites-enabled/000-default.conf
EXPOSE 8080
USER www-data

VOLUME /var/www/html/data
