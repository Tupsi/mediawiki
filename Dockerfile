ARG MEDIAWIKI_BRANCH=REL1_43
ARG MEDIAWIKI_VERSION=1.43.8

FROM alpine AS fetcher
ARG MEDIAWIKI_BRANCH
RUN mkdir -p /tmp/extensions /tmp/skins \
    && apk update \
    && apk add git \
    && git clone -b ${MEDIAWIKI_BRANCH} --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/Disambiguator /tmp/extensions/Disambiguator \
    && git clone -b ${MEDIAWIKI_BRANCH} --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/NoTitle /tmp/extensions/NoTitle \
    && git clone https://github.com/StarCitizenTools/mediawiki-skins-Citizen.git /tmp/skins/Citizen

FROM mediawiki:${MEDIAWIKI_VERSION}-fpm-alpine AS builder
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
USER root
RUN apk update && apk add --no-cache zip unzip git
WORKDIR /var/www/html
COPY --from=fetcher /tmp/extensions /var/www/html/extensions/
COPY --from=fetcher /tmp/skins/Citizen /var/www/html/skins/Citizen/
COPY composer.local.json /var/www/html/composer.local.json
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer update --no-dev --optimize-autoloader

FROM dunglas/frankenphp:1-php8.3-alpine
RUN install-php-extensions intl mysqli mbstring gd opcache
WORKDIR /app/public
COPY ./web/Caddyfile /etc/caddy/Caddyfile
COPY ./web/Caddyfile /etc/frankenphp/Caddyfile
COPY --chown=www-data:www-data --from=builder /var/www/html/extensions /app/public/extensions/
COPY --chown=www-data:www-data --from=builder /var/www/html/skins/Citizen /app/public/skins/Citizen/
COPY --chown=www-data:www-data --from=builder /var/www/html/vendor /app/public/vendor/
COPY --chown=www-data:www-data --from=builder /var/www/html/composer.local.json /app/public/composer.local.json