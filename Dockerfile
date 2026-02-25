FROM alpine AS extensions
RUN mkdir /tmp/extensions \
    && apk update \
    && apk add git \
    && git clone -b REL1_43 --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/Disambiguator /tmp/extensions/Disambiguator \
    && git clone -b REL1_43 --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/NoTitle /tmp/extensions/NoTitle

FROM composer:2 AS composer

FROM mediawiki:1.43
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
COPY composer.local.json /var/www/html/composer.local.json
COPY --chown=www-data:www-data --from=extensions /tmp/extensions /var/www/html/extensions/

WORKDIR /var/www/html

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apt-get update && apt-get -y install zip unzip \
    && composer config --global audit.block-insecure false \
    && composer update --no-dev --no-audit --optimize-autoloader \
    && chown -R www-data:www-data /var/www/html/extensions
