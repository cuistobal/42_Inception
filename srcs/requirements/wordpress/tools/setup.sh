#!/bin/bash

# Load secrets from Docker Compose secrets mounted at /run/secrets/
# Use PASS=$(cat /run/secrets/<name>) format as requested
if [ -z "${MYSQL_PASSWORD:-}" ] && [ -f /run/secrets/mariadb_password ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/mariadb_password)
fi
if [ -z "${WP_ADMIN_PASSWORD:-}" ] && [ -f /run/secrets/wordpress_admin_password ]; then
    WP_ADMIN_PASSWORD=$(cat /run/secrets/wordpress_admin_password)
fi
if [ -z "${WP_USER_PASSWORD:-}" ] && [ -f /run/secrets/wordpress_user_password ]; then
    WP_USER_PASSWORD=$(cat /run/secrets/wordpress_user_password)
fi

# Wait for MariaDB to be ready
until mysqladmin ping -h mariadb -u ${MYSQL_USER} -p${MYSQL_PASSWORD} &>/dev/null; do
    echo "Waiting for MariaDB..."
    sleep 3
done

# Download WordPress if not already present
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Installing WordPress..."
    
    # Download WordPress
    wp core download --allow-root
    
    # Create wp-config.php
    wp config create \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb \
        --allow-root
    
    # Install WordPress
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --allow-root
    
    # Create additional user
    wp user create ${WP_USER} ${WP_USER_EMAIL} \
        --user_pass=${WP_USER_PASSWORD} \
        --role=author \
        --allow-root
    
    # Configure Redis cache
    wp config set WP_REDIS_HOST ${REDIS_HOST} --allow-root
    wp config set WP_REDIS_PORT ${REDIS_PORT} --allow-root
    wp config set WP_CACHE true --raw --allow-root
    
    # Install and activate Redis Object Cache plugin
    wp plugin install redis-cache --activate --allow-root
    wp redis enable --allow-root
    
    # Set proper permissions
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
fi

# Ensure WordPress uses the correct site URL (force home/siteurl to DOMAIN_NAME)
# This fixes existing installations that may still point to a different host/port (e.g. :8081).
if wp core is-installed --allow-root >/dev/null 2>&1; then
    echo "🔧 Forcing WP siteurl/home to https://${DOMAIN_NAME}"
    wp option update home "https://${DOMAIN_NAME}" --allow-root || true
    wp option update siteurl "https://${DOMAIN_NAME}" --allow-root || true
fi

# Create an MU-plugin that makes WP use the current request Host (accepts IP or domain)
# This allows accessing the site via either chrleroy.42.fr or 192.168.56.101 without changing the DB.
if [ ! -d "/var/www/html/wp-content/mu-plugins" ]; then
    mkdir -p /var/www/html/wp-content/mu-plugins
fi
cat > /var/www/html/wp-content/mu-plugins/dynamic-siteurl.php <<'PHP'
<?php
// MU-plugin: dynamically set WP_HOME and WP_SITEURL to the current request host (supports IP or domain)
// Safe for local development/testing. Avoids permanent DB changes.
if ( ! defined( 'WP_CLI' ) && isset($_SERVER['HTTP_HOST']) ) {
    $host = $_SERVER['HTTP_HOST'];
    // Strip unexpected characters
    $host = preg_replace('/[^A-Za-z0-9\.\-:]/', '', $host);
    $scheme = ( (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || (isset($_SERVER['SERVER_PORT']) && $_SERVER['SERVER_PORT'] == '443') ) ? 'https' : 'http';
    if ( ! defined('WP_HOME') ) define('WP_HOME', $scheme . '://' . $host);
    if ( ! defined('WP_SITEURL') ) define('WP_SITEURL', $scheme . '://' . $host);
}
PHP

chown -R www-data:www-data /var/www/html/wp-content/mu-plugins || true
chmod -R 755 /var/www/html/wp-content/mu-plugins || true

echo "🔧 MU-plugin dynamic-siteurl installed (accepts IP or domain)"

# Start PHP-FPM in foreground
# Use the unversioned binary so it works with the PHP package installed by Debian Bookworm
exec php-fpm -F
