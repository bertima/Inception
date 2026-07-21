#!/bin/bash
set -e


DB_USER=$(cat /run/secrets/db_user)
DB_USER_PASSWORD=$(cat /run/secrets/db_user_password)
ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
ADMIN_NAME=$(cat /run/secrets/wp_admin_name)
ADMIN_MAIL=$(cat /run/secrets/wp_admin_email)
USER_PASSWORD=$(cat /run/secrets/wp_user_password)
USER_NAME=$(cat /run/secrets/wp_user)
USER_MAIL=$(cat /run/secrets/wp_user_email)
SITE_URL=""

COUNT=0
MAX_RETRIES=60

if [ -z "$DB_USER" ] || [ -z "$DB_USER_PASSWORD" ] \
	|| [ -z "$ADMIN_PASSWORD" ] || [ -z "$ADMIN_NAME" ] || [ -z "$ADMIN_MAIL" ] \
	|| [ -z "$USER_PASSWORD" ] || [ -z "$USER_NAME" ] || [ -z "$USER_MAIL" ] \
	|| [ -z "$WORDPRESS_DB_HOST" ] || [ -z "$WORDPRESS_DB_NAME" ] || [ -z "$WP_TITLE" ] || [ -z "$DOMAIN_NAME" ] \
    || [ -z "$DB_PORT" ] || [ -z "$WP_PORT" ]; then
	echo "Variables in environnement missing"; 
	exit 1; 
fi

if [ "$NGINX_PORT" = "443" ]; then
    SITE_URL="https://${DOMAIN_NAME}"
else
    SITE_URL="https://${DOMAIN_NAME}:${NGINX_PORT}"
fi

while ! mariadb-admin ping -h "$WORDPRESS_DB_HOST" --port="${DB_PORT}" -u"$DB_USER" -p"$DB_USER_PASSWORD" --silent 2>/dev/null; do
    COUNT=$((COUNT+1))
	if [ $COUNT -ge $MAX_RETRIES ]; then
        echo "Error : No responses of MariaDB after $MAX_RETRIES sec. Stopping."
        exit 1 
    fi
    sleep 1
done

if [ ! -f /var/www/html/wp-settings.php ]; then
	php83 /usr/local/bin/wp core download --path=/var/www/html --allow-root
	php83 /usr/local/bin/wp config create \
        --dbname=$WORDPRESS_DB_NAME \
        --dbuser=$DB_USER \
        --dbpass=$DB_USER_PASSWORD \
        --dbhost="${WORDPRESS_DB_HOST}:${DB_PORT}" \
        --path=/var/www/html \
        --allow-root
	php83 /usr/local/bin/wp core install \
        --url=$SITE_URL \
        --title=$WP_TITLE \
        --admin_user=$ADMIN_NAME \
        --admin_password=$ADMIN_PASSWORD \
        --admin_email=$ADMIN_MAIL \
        --path=/var/www/html \
        --allow-root
	php83 /usr/local/bin/wp user create $USER_NAME $USER_MAIL \
        --user_pass=$USER_PASSWORD \
        --role=author \
        --path=/var/www/html \
        --allow-root
fi

chown -R nobody:nobody /var/www/html
chmod -R 755 /var/www/html
chmod 600 /var/www/html/wp-config.php

sed -i "s/listen = 127.0.0.1:9000/listen = ${WP_PORT}/g" /etc/php83/php-fpm.d/www.conf

exec php-fpm83 -F