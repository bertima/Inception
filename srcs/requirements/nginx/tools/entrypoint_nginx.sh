set -e

if [ -z "$DOMAIN_NAME" ] || [ -z "$WP_PORT" ]; then
    echo "DOMAIN_NAME or WP_PORT variable missing"
    exit 1
fi

if [ ! -f /etc/nginx/ssl/inception.crt ] || [ ! -f /etc/nginx/ssl/inception.key ]; then
    echo "SSL certificate missing in /etc/nginx/ssl"
    exit 1
fi

# Substitution du nom de domaine dans la conf
sed -i "s/\${DOMAIN_NAME}/${DOMAIN_NAME}/g" /etc/nginx/http.d/default.conf
sed -i "s/\${WP_PORT}/${WP_PORT}/g" /etc/nginx/http.d/default.conf

exec nginx -g "daemon off;"