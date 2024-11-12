FROM mediawiki:lts
COPY composer.local.json /var/www/html/composer.local.json
COPY *.tar.gz /tmp/
WORKDIR /var/www/html
RUN pecl install redis \
        && chown 1000:1000 composer.local.json \
        && docker-php-ext-enable redis \
        && apt update && apt install wget zip -y \
        && wget -cO - https://getcomposer.org/composer-2.phar > /usr/local/bin/composer \
        && chmod +x /usr/local/bin/composer \
        && apt remove --purge wget -y \
        && composer update --no-dev \
        && for f in /tmp/*.tar.gz; do tar -xvf "$f" -C /var/www/html/extensions/ ; done \
        && rm -f /tmp/*.tar.gz \
        && chown -R www-data:www-data /var/www/html/extensions
