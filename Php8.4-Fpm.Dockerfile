# Image PHP 8.4 + FPM, dùng cho 9189.vn (Laravel 12) và các app chạy nginx + php-fpm.
#
# Phiên bản pin cứng 8.4.27 và ext-mongodb 1.21.1 vì composer.json của 9189 khai
# config.platform đúng hai giá trị đó - lệch là `composer install` fail ở platform check.
# mongodb giữ ở dòng 1.x: userland mongodb/mongodb ^1.21 không chạy với ext 2.x.
FROM php:8.4.27-fpm-bookworm

# Ext cài bằng install-php-extensions: tự cài gói -dev, biên dịch xong gỡ đi, chỉ giữ thư viện runtime.
COPY --from=mlocati/php-extension-installer:2.13.1 /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions \
        pdo_mysql mbstring gd zip bcmath intl exif pcntl opcache soap \
        mongodb-1.21.1 redis excimer

# openssh-client bắt buộc: composer kéo gói private qua SSH.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip openssh-client \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

# Code được bind-mount từ host nên owner của repo không phải user chạy trong container (root), và
# git từ 2.35.2 từ chối đọc repo "lạ chủ":
#   fatal: detected dubious ownership in repository at '/var/www/html'
# Composer gọi git để đọc version info, nên mỗi lần `composer install` lại in cảnh báo đó.
# Trong container, repo là thứ người vận hành tự mount vào, không có chủ nào khác để phân biệt.
RUN git config --system --add safe.directory '*'

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

WORKDIR /var/www/html
