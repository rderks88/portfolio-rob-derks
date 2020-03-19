FROM php:7.2.12-fpm

ENV COMPOSER_ALLOW_SUPERUSER=1

# Install PHP extensions
RUN apt-get update \
    && apt-get install -y sudo zip unzip git curl gnupg libpq-dev libzip-dev libpng-dev mysql-client \
        libwebp-dev libjpeg62-turbo-dev libxpm-dev libfreetype6-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-configure gd \
        --with-gd \
        --with-webp-dir \
        --with-jpeg-dir \
        --with-png-dir \
        --with-zlib-dir \
        --with-xpm-dir \
        --with-freetype-dir \
        --enable-gd-native-ttf \
    && docker-php-ext-install pdo pdo_pgsql pgsql zip pdo_mysql bcmath sockets gd

# Install nodejs and yarn
RUN curl -sL https://deb.nodesource.com/setup_11.x | bash - && sudo apt-get install -y nodejs && curl -o- -L https://yarnpkg.com/install.sh | bash

# Configure xdebug
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug

# Install composer
RUN curl --silent --show-error https://getcomposer.org/installer | php \
&& mv composer.phar /usr/local/bin/composer

# Configure entry point
ADD docker-php-entrypoint.sh /opt/docker-php-entrypoint.sh
RUN chmod a+x /opt/docker-php-entrypoint.sh

ADD www.conf /usr/local/etc/php-fpm.d/www.conf

# Add a file that changes php ini values
ADD custom-php-conf.ini /usr/local/etc/php/conf.d/uploads.ini

ENTRYPOINT ["/opt/docker-php-entrypoint.sh"]

CMD ["php-fpm"]
