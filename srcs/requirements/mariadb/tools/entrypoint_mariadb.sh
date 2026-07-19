set -e


ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
USER_PASSWORD=$(cat /run/secrets/db_user_password)
DB_USER=$(cat /run/secrets/db_user)

COUNT=0
MAX=30

if [ -z "$ROOT_PASSWORD" ] || [ -z "$USER_PASSWORD" ] || [ -z "$DB_USER" ] || [ -z "$DB_NAME" ] || [ -z "$DB_PORT" ]; then 
	echo "Variables in environnement missing"; 
	exit 1; 
fi

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

    mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking &
    pid="$!"

    while ! mariadb-admin ping 2>/dev/null 2>&1; do
    	sleep 1
    	COUNT=$((COUNT+1))
    	if [ "$COUNT" -ge "$MAX" ]; then
    	    echo "MariaDB failed to start"
    	    exit 1
    	fi
	done

    mariadb -u root <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS ${DB_NAME};
        CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${USER_PASSWORD}';
        GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
		DELETE FROM mysql.user WHERE User='';
        FLUSH PRIVILEGES;
EOSQL

    mariadb-admin -u root -p"${ROOT_PASSWORD}" shutdown
    wait "$pid"
fi

exec mariadbd --user=mysql --port=${DB_PORT} --datadir=/var/lib/mysql --bind-address=0.0.0.0