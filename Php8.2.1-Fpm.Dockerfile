FROM php:8.2.1-fpm
RUN apt update
RUN apt-get install -y libmcrypt-dev zip unzip libzip-dev libssl-dev
RUN apt-get install -y \
                libfreetype6-dev \
                libjpeg62-turbo-dev \
                libpng-dev \
        && docker-php-ext-install -j$(nproc) iconv \
        && docker-php-ext-configure gd --with-freetype --with-jpeg \
        && docker-php-ext-install -j$(nproc) gd \ 
        && docker-php-ext-install pdo pdo_mysql \
        && docker-php-ext-install zip \
        && docker-php-ext-install mysqli \
        && docker-php-ext-install exif \
        && docker-php-ext-install ctype \
        && docker-php-ext-install bcmath \
        && docker-php-ext-install exif && pecl install mongodb && echo "extension=mongodb.so" > $PHP_INI_DIR/conf.d/mongodb.ini \
        && docker-php-ext-install opcache
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer
RUN apt-get install -y git