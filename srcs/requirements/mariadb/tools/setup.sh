#!/bin/bash

# Load MariaDB secrets from /run/secrets if present
if [ -z "${MYSQL_ROOT_PASSWORD:-}" ] && [ -f /run/secrets/mariadb_root_password ]; then
	MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mariadb_root_password)
fi
if [ -z "${MYSQL_PASSWORD:-}" ] && [ -f /run/secrets/mariadb_password ]; then
	MYSQL_PASSWORD=$(cat /run/secrets/mariadb_password)
fi

# Start MariaDB in background to initialize
mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Start MariaDB in foreground
exec mysqld --user=mysql
