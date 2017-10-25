FROM php:7-fpm-alpine

MAINTAINER Tien Nhan <nhantien.ca@gmail.com>

ENV TERM xterm

WORKDIR /var/www/html

# install neccesary package
RUN apk add --update --no-cache alpine-sdk bash autoconf curl freetype-dev gdb git htop icu-dev libmcrypt-dev libtool libltdl \
      libjpeg-turbo-dev libpng-dev make re2c strace tzdata zip pcre-dev libxml2-dev pwgen

# install stack component
RUN apk add --update --no-cache supervisor nginx varnish

# install composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# install wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# install and configure some php extension
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/  --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) gd intl mysqli pdo_mysql zip bcmath mcrypt exif soap \
    && docker-php-ext-enable opcache

RUN mkdir -p /etc/nginx/sites-available/ \
    && mkdir -p /etc/nginx/sites-enabled/ \
    && mkdir -p /etc/nginx/ssl/ \
    && mkdir -p /var/www/app \
    && mkdir -p /run/nginx \
    && mkdir -p /var/log/supervisor

COPY conf/app.ini /usr/local/etc/php/conf.d/

COPY conf/supervisord.conf /etc/supervisord.conf

COPY conf/varnish-default.vcl /etc/varnish/default.vcl

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY conf/nginx-site.conf /etc/nginx/sites-available/default.conf

RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

RUN composer create-project roots/bedrock app

WORKDIR /var/www/html/app

RUN chown -R www-data:www-data web/app/uploads

COPY docker-entrypoint.sh /

RUN chmod 755 /docker-entrypoint.sh

CMD ["/docker-entrypoint.sh"]
