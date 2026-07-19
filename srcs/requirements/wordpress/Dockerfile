FROM alpine:3.23


RUN apk add --no-cache \
	wget \
    tar \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-phar \
    php83-mbstring \
    php83-json \
    php83-gd \
    php83-curl \
    mariadb-client

RUN echo "memory_limit = 256M" >> /etc/php83/php.ini && \
	sed -i 's/;clear_env = no/clear_env = no/g' /etc/php83/php-fpm.d/www.conf

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar &&\
	chmod +x wp-cli.phar &&\
	mv wp-cli.phar /usr/local/bin/wp

COPY tools/entrypoint_wordpress.sh /entrypoint_wordpress.sh
RUN chmod +x /entrypoint_wordpress.sh

ENTRYPOINT ["sh", "/entrypoint_wordpress.sh"]