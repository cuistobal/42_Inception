#!/bin/bash

# Load FTP password from Docker Compose secrets if not provided in env
if [ -z "${FTP_PASSWORD:-}" ] && [ -f /run/secrets/ftp_password ]; then
    FTP_PASSWORD=$(cat /run/secrets/ftp_password)
fi

# Create FTP user if not exists
if ! id -u ${FTP_USER} > /dev/null 2>&1; then
    useradd -m ${FTP_USER}
    echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
fi

# Set FTP user home to WordPress directory
usermod -d /var/www/html ${FTP_USER}
chown -R ${FTP_USER}:${FTP_USER} /var/www/html

# Ensure secure_chroot_dir exists and has correct permissions
# vsftpd requires this directory to exist and be owned by root
mkdir -p /var/run/vsftpd/empty
chown root:root /var/run/vsftpd/empty || true
chmod 755 /var/run/vsftpd/empty || true

# Start vsftpd in foreground
exec /usr/sbin/vsftpd /etc/vsftpd.conf
