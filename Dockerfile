FROM mediawiki:1.39
COPY /extras /var/www/html/
RUN pecl install redis \
      && chown 1000:1000 /var/www/html/composer.local.json \
      && docker-php-ext-enable redis \
      && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
      && php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
      && php composer-setup.php \
      && php -r "unlink('composer-setup.php');" \
      && mv composer.phar /usr/local/bin/composer \
      && chmod +x /usr/local/bin/composer \
      && composer update --no-dev -d /var/www/html/ \
      && composer update --no-dev -d /var/www/html/extensions/Elastica \
      && composer update --no-dev -d /var/www/html/extensions/CirrusSearch \
      && chown -R www-data:www-data /var/www/html/extensions \
      && rm -rf \
         /tmp/* \
         /var/lib/apt/lists/*
WORKDIR /var/www/html
