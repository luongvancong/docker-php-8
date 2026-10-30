# Image PHP 8.2 + Apache dùng chung cho các dự án (xemboi, ...).
# - Vá PHP2Shell (CVE-2026-109618/109619): bản vá có từ PHP 8.2.35.
# - PHP 8.0 đã hết hỗ trợ, không còn nhận bản vá bảo mật.
# - Laravel 9 chỉ chạy tới PHP 8.2 nên dừng ở 8.2.
FROM php:8.2.35-apache-bookworm

# Ext cài bằng install-php-extensions: tự cài gói -dev, biên dịch xong gỡ đi, chỉ giữ thư viện runtime.
COPY --from=mlocati/php-extension-installer:2.13.1 /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions gd pdo_mysql mysqli zip exif bcmath opcache mongodb-2.5.5

# openssh-client bắt buộc: composer kéo gói private qua SSH.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip openssh-client \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && a2enmod rewrite headers http2
