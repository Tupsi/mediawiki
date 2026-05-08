ARG MEDIAWIKI_BRANCH=REL1_43
ARG MEDIAWIKI_VERSION=1.43.8

# Stage 1: Fetch extensions and skins
FROM alpine AS fetcher
ARG MEDIAWIKI_BRANCH
RUN mkdir -p /tmp/extensions /tmp/skins \
    && apk update \
    && apk add git \
    && git clone -b ${MEDIAWIKI_BRANCH} --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/Disambiguator /tmp/extensions/Disambiguator \
    && git clone -b ${MEDIAWIKI_BRANCH} --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/NoTitle /tmp/extensions/NoTitle \
    && git clone https://github.com/StarCitizenTools/mediawiki-skins-Citizen.git /tmp/skins/Citizen

# Stage 2: Composer Builder
FROM mediawiki:${MEDIAWIKI_VERSION} AS builder
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# Install necessary tools for composer
RUN apt-get update && apt-get install -y zip unzip git && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Copy extensions and skins from fetcher
COPY --from=fetcher /tmp/extensions /var/www/html/extensions/
COPY --from=fetcher /tmp/skins/Citizen /var/www/html/skins/Citizen/

# Copy composer config
COPY composer.local.json /var/www/html/composer.local.json

# Run composer with security audits enabled
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer update --no-dev --optimize-autoloader

# Stage 3: Final Production Image
FROM mediawiki:${MEDIAWIKI_VERSION}

WORKDIR /var/www/html

# Copy generated and downloaded code from builder
COPY --chown=www-data:www-data --from=builder /var/www/html/extensions /var/www/html/extensions/
COPY --chown=www-data:www-data --from=builder /var/www/html/skins/Citizen /var/www/html/skins/Citizen/
COPY --chown=www-data:www-data --from=builder /var/www/html/vendor /var/www/html/vendor/
COPY --chown=www-data:www-data --from=builder /var/www/html/composer.local.json /var/www/html/composer.local.json
