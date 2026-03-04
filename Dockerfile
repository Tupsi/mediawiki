FROM alpine AS extensions
RUN mkdir -p /tmp/extensions /tmp/skins \
    && apk update \
    && apk add git \
    # Extensions
    && git clone -b REL1_43 --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/Disambiguator /tmp/extensions/Disambiguator \
    && git clone -b REL1_43 --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/NoTitle /tmp/extensions/NoTitle \
    # Citizen Skin hinzufügen
    && git clone https://github.com/StarCitizenTools/mediawiki-skins-Citizen.git /tmp/skins/Citizen

FROM composer:2 AS composer

FROM mediawiki:1.43
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
COPY composer.local.json /var/www/html/composer.local.json

# Kopieren der Extensions
COPY --chown=www-data:www-data --from=extensions /tmp/extensions /var/www/html/extensions/
# Kopieren des Skins in das skins-Verzeichnis
COPY --chown=www-data:www-data --from=extensions /tmp/skins/Citizen /var/www/html/skins/Citizen

WORKDIR /var/www/html

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apt-get update && apt-get -y install zip unzip \
    && composer config --global audit.block-insecure false \
    && composer update --no-dev --no-audit --optimize-autoloader \
    && chown -R www-data:www-data /var/www/html/extensions /var/www/html/skins/Citizen
