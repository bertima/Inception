FROM alpine:3.23

RUN apk add --no-cache nginx

RUN mkdir -p /run/nginx

COPY conf/nginx.conf /etc/nginx/http.d/default.conf
COPY tools/entrypoint_nginx.sh /entrypoint_nginx.sh
RUN chmod +x /entrypoint_nginx.sh

ENTRYPOINT ["sh", "/entrypoint_nginx.sh"]