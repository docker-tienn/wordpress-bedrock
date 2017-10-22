FROM php:7-fpm-alpine

MAINTAINER Tien Nhan <nhantien.ca@gmail.com>

# alpine-sdk and autoconf to be able to install iconv & xdebug
# icu-dev to be able to install intl
# zip to allow Composer to download dependencies from dist

ENV TERM xterm

WORKDIR /var/www/html

RUN apk add --update --no-cache alpine-sdk bash autoconf curl freetype-dev gdb git htop icu-dev libmcrypt-dev libtool libltdl \
      libjpeg-turbo-dev libpng-dev make re2c strace tzdata zip pcre-dev libxml2-dev supervisor nginx pwgen \
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/  --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) gd intl mysqli pdo_mysql zip bcmath mcrypt exif soap \
    && docker-php-ext-enable opcache \

    # install mariadb
    && apk add mariadb mariadb-client \

    # install nginx
    && mkdir -p /etc/nginx \
    && mkdir -p /var/www/app \
    && mkdir -p /run/nginx \
    && mkdir -p /var/log/supervisor

    # xdebug install for local env (disabled by default)
    # && set -xe \
    # && curl -sSL https://github.com/xdebug/xdebug/archive/XDEBUG_2_5_0.tar.gz | tar xz -C /tmp \
    # && cd /tmp/xdebug-XDEBUG_2_5_0 && phpize && ./configure --enable-xdebug && make && make install \
    # && apk del --purge alpine-sdk autoconf libtool re2c tzdata \
    # && rm -rf /usr/src/php.tar* /var/cache/apk/*

COPY conf/app.ini /usr/local/etc/php/conf.d/

RUN composer create-project roots/bedrock app

WORKDIR /var/www/html/app

RUN chown -R www-data:www-data web/app/uploads

COPY conf/supervisord.conf /etc/supervisord.conf

# nginx site conf
RUN mkdir -p /etc/nginx/sites-available/ \
    && mkdir -p /etc/nginx/sites-enabled/ \
    && mkdir -p /etc/nginx/ssl/

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY conf/nginx-site.conf /etc/nginx/sites-available/default.conf

RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

COPY docker-entrypoint.sh /

RUN chmod 755 /docker-entrypoint.sh

CMD ["/docker-entrypoint.sh"]
