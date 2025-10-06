# https://hub.docker.com/_/mediawiki
FROM alpine AS extensions
RUN mkdir /tmp/extensions \
    && apk update \
    && apk add git \
#    && git clone -b REL1_43 --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/Elastica /tmp/extensions/Elastica \
#    && git clone -b REL1_43 --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/CirrusSearch /tmp/extensions/CirrusSearch \
    && git clone -b REL1_43 --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/Disambiguator /tmp/extensions/Disambiguator \
    && git clone -b REL1_43 --single-branch https://gerrit.wikimedia.org/r/mediawiki/extensions/NoTitle /tmp/extensions/NoTitle
FROM composer:2.7.7 AS composer
FROM mediawiki:1.43
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
COPY composer.local.json /var/www/html/composer.local.json
COPY --chown=www-data:www-data --from=extensions /tmp/extensions /var/www/html/extensions/
#RUN pecl install redis \
#    && chown 1000:1000 /var/www/html/composer.local.json \
#    && docker-php-ext-enable redis \
RUN composer update --no-interaction --no-dev --prefer-source -d /var/www/html/ \
#    && composer update --no-dev -d /var/www/html/extensions/CirrusSearch/ \
#    && composer update --no-dev -d /var/www/html/extensions/Elastica/ \
#    && rm -f /tmp/*.tar.gz \
    && chown -R www-data:www-data /var/www/html/extensions
WORKDIR /var/www/html
