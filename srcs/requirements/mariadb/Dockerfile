FROM alpine:3.23

RUN apk add --no-cache mariadb mariadb-client

COPY tools/entrypoint_mariadb.sh /entrypoint_mariadb.sh
COPY conf/maria-server.cnf /etc/my.cnf.d/mariadb-server.cnf
RUN chmod +x /entrypoint_mariadb.sh

ENTRYPOINT ["sh", "/entrypoint_mariadb.sh"]