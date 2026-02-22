FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php-fpm \
    php-cli \
    php-mysql \
    php-curl \
    php-gd \
    php-intl \
    php-mbstring \
    php-soap \
    php-xml \
    php-xmlrpc \
    php-zip \
    php-redis \
    curl \
    wget \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Some Debian packages install versioned php-fpm binaries (e.g. php-fpm8.2).
# Create a generic `php-fpm` symlink so healthchecks and scripts invoking `php-fpm` find it.
RUN if [ -x "/usr/sbin/php-fpm8.2" ]; then ln -sf /usr/sbin/php-fpm8.2 /usr/sbin/php-fpm; fi || true

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

RUN mkdir -p /run/php && \
    chown -R www-data:www-data /run/php

WORKDIR /var/www/html

EXPOSE 9000

CMD ["/usr/local/bin/setup.sh"]
