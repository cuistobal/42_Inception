# USER_DOC.md - User Documentation

This documentation explains how to use the Inception project as an end-user or administrator.

## Table of Contents

1. [What is This Project?](#what-is-this-project)
2. [Services Provided](#services-provided)
3. [Quick Start](#quick-start)
4. [Accessing the Services](#accessing-the-services)
5. [Managing Credentials](#managing-credentials)
6. [Verifying Services](#verifying-services)
7. [Troubleshooting](#troubleshooting)
8. [Stopping and Starting](#stopping-and-starting)

---

## What is This Project?

Inception is a containerized WordPress infrastructure that includes:
- A web server (NGINX) with SSL/TLS encryption
- A WordPress CMS application with PHP-FPM
- A MariaDB database
- Optional bonus services (Redis cache, FTP server, Adminer, etc.)

The entire stack runs on Docker containers orchestrated by Docker Compose.

---

## Services Provided

### Core Services

| Service | Purpose | Port | Access |
|---------|---------|------|--------|
| **NGINX** | Web server, reverse proxy, SSL/TLS | 443 (HTTPS) | https://login.42.fr |
| **WordPress** | CMS and content management | Internal only | Via NGINX |
| **MariaDB** | Database server | Internal only | Only from WordPress container |

### Optional Bonus Services

| Service | Purpose | Port | Requires Setup |
|---------|---------|------|-----------------|
| **Redis** | Cache management | Internal | Yes |
| **FTP** | File transfer protocol | 21 (varies) | Yes |
| **Adminer** | Database GUI manager | 8080 (varies) | Yes |
| **Static Website** | Alternative website | 3000 (varies) | Yes |
| **Portainer** | Docker management UI | 9000 (varies) | Yes |

---

## Quick Start

### 1. Initial Setup

Before running the project, ensure you have:

```bash
# Check if Docker is installed
docker --version

# Check if Docker Compose is installed
docker-compose --version
```

### 2. Configure Domain Name

Edit your system's `/etc/hosts` file to point your domain to localhost:

```bash
# On Linux/Mac, edit /etc/hosts
sudo nano /etc/hosts

# Add this line (replace 'login' with your actual login):
127.0.0.1    login.42.fr
```

On Windows, edit `C:\Windows\System32\drivers\etc\hosts` similarly.

### 3. Start the Project

```bash
# Navigate to the project directory
cd 42_Inception

# Start all services
make

# Or manually:
docker-compose -f srcs/docker-compose.yml up -d
```

The first startup will:
- Build Docker images
- Create and initialize the MariaDB database
- Configure WordPress
- Start all containers
- Take 30-60 seconds depending on your system

### 4. Verify Services Are Running

```bash
# Check container status
docker ps

# Or check with docker-compose
docker-compose -f srcs/docker-compose.yml ps
```

All containers should show "Up" status.

---

## Accessing the Services

### WordPress Website

1. **Open your browser** and navigate to:
   ```
   https://login.42.fr
   ```
   (Replace `login` with your actual login)

2. **Accept the self-signed certificate** warning (normal for local HTTPS)

3. **WordPress will load** with your configured domain

> Note: WordPress now includes a small MU-plugin that makes the site use the current request host at runtime. This allows accessing the site using either `https://chrleroy.42.fr` or `https://192.168.56.101` for local testing (you may still see a TLS warning for the IP because the certificate is issued for the domain).

### WordPress Admin Dashboard

1. Navigate to:
   ```
   https://login.42.fr/wp-admin
   ```

2. **Login credentials**:
   - Username: Check your `srcs/.env` file for `WP_ADMIN_USER`
   - Password: Check the Docker secret `srcs/secrets/wordpress_admin_password` (not stored in `.env`)

### Adminer (if enabled)

1. Navigate to the Adminer port (configure in docker-compose.yml):
   ```
   https://login.42.fr:8080
   ```

2. **Login credentials**:
   - Server: `mariadb` (Docker service name)
   - Username: Check `srcs/.env` for `DB_USER`
   - Password: Check the Docker secret `srcs/secrets/mariadb_password`
   - Database: Check `srcs/.env` for `DB_NAME`

### FTP Server (if enabled)

```bash
# Connect using FTP client (e.g., FileZilla):
ftp.login.42.fr:21

# Username: Check your `srcs/.env`
# Password: Check the Docker secret in `srcs/secrets/` (e.g. `ftp_password`)
```

---

## Managing Credentials

### Where Are Credentials Stored?

Caveat: non-sensitive configuration values are stored in `srcs/.env`. Passwords and other secrets are stored as Docker secret files under `srcs/secrets/` and are NOT committed to the repository.

```bash
# Non-sensitive values
cat srcs/.env

# Secrets are stored in files under srcs/secrets/ (do not commit)
ls -l srcs/secrets/
```

### Viewing Credentials

```bash
Note: passwords are provided to containers via mounted secret files (available at `/run/secrets/`) and are not present in container environment variables by default. Use the secret files on the host to view/change them when needed.
```

### Changing Credentials

To change WordPress admin password:

1. **Access WordPress admin** at `https://login.42.fr/wp-admin`
2. Go to **Users** → **Your Profile**
3. Scroll to **Account Management**
4. Click **Set New Password**
5. Enter and save new password

### Updating Database Credentials

⚠️ **Warning**: Changing database credentials requires rebuilding containers:

```bash
# Stop services
docker-compose -f srcs/docker-compose.yml down

# Update .env file
nano srcs/.env

# Rebuild and restart
docker-compose -f srcs/docker-compose.yml up -d --build

# Or use Makefile:
make clean
make
```

---

## Verifying Services

### Check All Services Are Running

```bash
# Using Docker Compose
docker-compose -f srcs/docker-compose.yml ps

# Expected output:
# NAME          COMMAND             STATUS
# nginx         [start command]     Up X seconds
# wordpress     [start command]     Up X seconds
# mariadb       [start command]     Up X seconds
```

### Check NGINX/Web Server

```bash
# Check if NGINX is responding
curl -k https://login.42.fr

# You should see HTML output
```

### Check WordPress Database Connection

```bash
# Login to WordPress container
docker exec -it wordpress_container bash

# Inside container, try connecting to database:
mysql -h mariadb -u wordpress_user -p<password> wordpress_db

# If successful, you'll see: mysql>
```

### Check Container Logs

```bash
# View logs for a specific service
docker-compose -f srcs/docker-compose.yml logs nginx
docker-compose -f srcs/docker-compose.yml logs wordpress
docker-compose -f srcs/docker-compose.yml logs mariadb

# Follow logs in real-time
docker-compose -f srcs/docker-compose.yml logs -f wordpress

# Exit with Ctrl+C
```

### Check Volumes

```bash
# List all volumes
docker volume ls

# Inspect a volume
docker volume inspect inception_wordpress_volume

# View volume data on host
ls -la /home/login/data/
```

---

## Troubleshooting

### Issue: "Connection refused" when accessing https://login.42.fr

**Solution**:
1. Verify containers are running:
   ```bash
   docker ps
   ```
2. Check `/etc/hosts` configuration (see Quick Start section)
3. Restart NGINX container:
   ```bash
   docker-compose -f srcs/docker-compose.yml restart nginx
   ```
4. Check NGINX logs:
   ```bash
   docker-compose -f srcs/docker-compose.yml logs nginx
   ```

### Issue: WordPress shows "Error establishing a database connection"

**Solution**:
1. Verify MariaDB is running:
   ```bash
   docker-compose -f srcs/docker-compose.yml ps mariadb
   ```
2. Check database credentials in `.env` match wordpress config
3. Restart WordPress and MariaDB:
   ```bash
   docker-compose -f srcs/docker-compose.yml restart wordpress mariadb
   ```
4. Check logs:
   ```bash
   docker-compose -f srcs/docker-compose.yml logs mariadb
   ```

### Issue: Containers keep restarting

**Solution**:
1. Check container logs:
   ```bash
   docker-compose -f srcs/docker-compose.yml logs <service_name>
   ```
2. Look for error messages in logs
3. Verify `.env` file has correct values:
   ```bash
   cat srcs/.env
   ```
4. Rebuild containers:
   ```bash
   make clean
   make
   ```

### Issue: SSL Certificate Warning Persists

**Solution**:
This is **normal** for self-signed certificates. You can:
- Click "Advanced" → "Proceed" in your browser
- Add an exception for the domain
- Or install the certificate locally (optional)

### Issue: Port Already in Use

**Solution**:
```bash
# Find what's using port 443
sudo lsof -i :443

# Kill the process if it's conflicting
sudo kill -9 <PID>

# Or use a different port in docker-compose.yml
```

### Issue: Permission Denied on /home/login/data

**Solution**:
```bash
# Fix volume permissions
sudo chown -R $(whoami):$(whoami) /home/$(whoami)/data

# Or with Docker
docker exec nginx chown -R www-data:www-data /var/www/html
```

---

## Stopping and Starting

### Stop All Services (Keep Data)

```bash
# Using Makefile:
make stop

# Or manually:
docker-compose -f srcs/docker-compose.yml stop
```

The data persists in volumes and will be available when you restart.

### Start Services Again

```bash
# Using Makefile:
make start

# Or manually:
docker-compose -f srcs/docker-compose.yml start
```

### Restart Services

```bash
# Restart all services
docker-compose -f srcs/docker-compose.yml restart

# Restart specific service
docker-compose -f srcs/docker-compose.yml restart wordpress
```

### Full Cleanup (Delete Everything)

⚠️ **Warning**: This will delete all data!

```bash
# Using Makefile:
make clean

# Or manually:
docker-compose -f srcs/docker-compose.yml down -v
docker image prune -a
```

---

## Common Tasks

### Backup WordPress Files

```bash
# Copy volume to backup location
docker run --rm -v inception_wordpress_volume:/data -v $(pwd)/backup:/backup \
  alpine tar czf /backup/wordpress_backup.tar.gz -C /data .
```

### Restore WordPress Files

```bash
# Restore from backup
docker run --rm -v inception_wordpress_volume:/data -v $(pwd)/backup:/backup \
  alpine tar xzf /backup/wordpress_backup.tar.gz -C /data
```

### View WordPress Files

```bash
# These are stored in: /home/login/data/wordpress/
ls -la /home/login/data/wordpress/
```

### Update WordPress Plugins

1. Login to WordPress admin
2. Go to **Plugins**
3. Click **Update** on available plugins
4. Plugins update automatically in the container

### Add New WordPress User

1. Login as admin to `https://login.42.fr/wp-admin`
2. Go to **Users** → **Add New**
3. Fill in username, email, role
4. Click **Add New User**

---

## Performance Tips

1. **Enable Redis Cache** (bonus service):
   - Improves page load times significantly
   - Reduces database queries

2. **Use a CDN** (optional):
   - Serve static assets faster
   - Reduce server load

3. **Optimize Images**:
   - Use WordPress plugins like Shortpixel or Smush
   - Reduces bandwidth usage

4. **Regular Backups**:
   - Backup weekly using the scripts provided
   - Store backups on external storage

---

## Need Help?

- Check [README.md](README.md) for technical details
- See [DEV_DOC.md](DEV_DOC.md) for development information
- Review project specification: `Inception.pdf`
- Check Docker logs: `docker-compose logs <service>`

---

**Last Updated**: December 2024  
**Version**: 5.0  
**Project**: Inception - 42 School
