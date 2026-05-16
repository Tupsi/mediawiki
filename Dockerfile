ARG MEDIAWIKI_BRANCH=REL1_43

FROM alpine AS fetcher
ARG MEDIAWIKI_BRANCH
RUN mkdir -p /tmp/extensions /tmp/skins \
    && apk update \
    && apk add git \
    && git clone -b ${MEDIAWIKI_BRANCH} --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/Disambiguator /tmp/extensions/Disambiguator \
    && git clone -b ${MEDIAWIKI_BRANCH} --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/NoTitle /tmp/extensions/NoTitle \
    && git clone https://github.com/StarCitizenTools/mediawiki-skins-Citizen.git /tmp/skins/Citizen

FROM mediawiki:1.43.8-fpm-alpine AS builder
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
USER root
RUN apk update && apk add --no-cache zip unzip git
WORKDIR /var/www/html
COPY --from=fetcher /tmp/extensions /var/www/html/extensions/
COPY --from=fetcher /tmp/skins/Citizen /var/www/html/skins/Citizen/
COPY composer.json /var/www/html/composer.local.json
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer update --no-dev --optimize-autoloader

FROM dunglas/frankenphp:1-php8.3-alpine
RUN apk add --no-cache imagemagick && \
    install-php-extensions intl mysqli mbstring gd opcache
RUN chown -R www-data:www-data /data/caddy /config/caddy
WORKDIR /app/public
COPY ./web/Caddyfile /etc/caddy/Caddyfile
COPY ./web/Caddyfile /etc/frankenphp/Caddyfile
# fix formatting of Caddyfiles (remove tabs, ensure consistent indentation) to prevent Caddy from complaining about it
RUN frankenphp fmt --overwrite /etc/caddy/Caddyfile && \
    frankenphp fmt --overwrite /etc/frankenphp/Caddyfile
# Copy the built MediaWiki files from the builder stage to the final image (/app/public is the document root for FrankenPHP)
COPY --chown=www-data:www-data --from=builder /var/www/html/ /app/public/
USER www-data