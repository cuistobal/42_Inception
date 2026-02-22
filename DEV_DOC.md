# DEV_DOC.md - Developer Documentation

This documentation explains how to set up, build, and develop the Inception project from scratch.

## Table of Contents

1. [Environment Setup](#environment-setup)
2. [Building the Project](#building-the-project)
3. [Project Architecture](#project-architecture)
4. [Container Management](#container-management)
5. [Volume and Data Persistence](#volume-and-data-persistence)
6. [Debugging and Troubleshooting](#debugging-and-troubleshooting)
7. [Development Workflow](#development-workflow)
8. [Best Practices](#best-practices)

---

## Environment Setup

### Prerequisites

Install the following on your development machine:

```bash
# Docker (https://docs.docker.com/get-docker/)
docker --version

# Docker Compose (included with Docker Desktop, or install separately)
docker-compose --version

# Make (usually pre-installed on Linux/Mac)
make --version

# Git
git --version

# Optional: Text editor or IDE
# VS Code, Sublime Text, Vim, Nano, etc.
```

### Clone the Repository

```bash
# Clone the project
git clone <repository-url>
cd 42_Inception

# Verify structure
ls -la
```

### Create Configuration Files

1. **Create `.env` file in `srcs/` directory (non-sensitive values only)**:

```bash
cat > srcs/.env << EOF
# Domain Configuration
DOMAIN_NAME=<your_login>.42.fr

# Database Configuration (do NOT store passwords here)
DB_NAME=wordpress_db
DB_USER=wordpress_user

# WordPress Configuration (do NOT store admin/passwords here)
WP_ADMIN_USER=<admin_username_not_containing_admin>
WP_ADMIN_EMAIL=admin@example.com
WP_DB_HOST=mariadb
WP_DB_PORT=3306
WP_DB_NAME=${DB_NAME}
WP_DB_USER=${DB_USER}

# Optional: Bonus Services
REDIS_HOST=redis
REDIS_PORT=6379
FTP_USER=<ftp_user_if_enabled>
EOF
```

2. **Create Docker secret files for passwords** (stored locally, do not commit):

```bash
mkdir -p srcs/secrets
cat > srcs/secrets/mariadb_root_password << 'SECRET'
<strong_root_password_here>
SECRET
cat > srcs/secrets/mariadb_password << 'SECRET'
<strong_db_password_here>
SECRET
cat > srcs/secrets/wordpress_admin_password << 'SECRET'
<wp_admin_password_here>
SECRET
cat > srcs/secrets/wordpress_user_password << 'SECRET'
<wp_user_password_here>
SECRET
cat > srcs/secrets/ftp_password << 'SECRET'
<ftp_password_here>
SECRET
```

The `docker-compose.yml` is configured to mount these files as Docker secrets (available at `/run/secrets/<name>` inside containers). The service entrypoints/readme have been updated to read secrets from `/run/secrets/` when environment variables are not present.

2. **Update `/etc/hosts` for domain resolution**:

```bash
# Edit hosts file
sudo nano /etc/hosts

# Add this line
127.0.0.1    <your_login>.42.fr

# Save and exit (Ctrl+O, Enter, Ctrl+X)
```

3. **Create `.env` in project root (optional, for overrides)**:

```bash
# Create example .env in root
cat > .env.example << EOF
# This is an example. Create actual .env in srcs/ directory
DOMAIN_NAME=login.42.fr
DB_PASSWORD=secure_password_here
DB_ROOT_PASSWORD=secure_root_password_here
WP_ADMIN_PASSWORD=secure_admin_password_here
EOF
```

### Verify Setup

```bash
# Check Docker daemon is running
docker info

# Test Docker Compose
docker-compose --version

# Check Make is available
make --version

# Verify file structure
tree -L 2 srcs/
```

---

## Building the Project

### Using Makefile

The `Makefile` at the project root automates the entire build process:

```bash
# Build and start all services
make

# This command:
# 1. Builds Docker images from Dockerfiles
# 2. Creates Docker volumes
# 3. Starts containers using docker-compose
# 4. Initializes the database
# 5. Configures WordPress

# Build and start (verbose output)
make all

# Stop services (keep data)
make stop

# Start stopped services
make start

# Restart all services
make restart

# Clean up everything (DELETE DATA)
make clean

# Remove stopped containers
make fclean

# Rebuild from scratch
make re
```

### Manual Build (Without Makefile)

If you prefer to build manually:

```bash
# Navigate to project directory
cd srcs/

# Build images
docker-compose build

# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Verify Build Success

```bash
# Check if all containers are running
docker-compose -f srcs/docker-compose.yml ps

# Expected output:
# NAME          COMMAND        STATUS
# nginx         "nginx..."     Up 2 minutes
# wordpress     "php-fpm..."   Up 2 minutes
# mariadb       "mysql..."     Up 2 minutes

# Check if website is accessible
curl -k https://localhost.42.fr

# View container logs for errors
docker-compose -f srcs/docker-compose.yml logs
```

---

## Project Architecture

### Docker Compose Structure

```yaml
# srcs/docker-compose.yml defines:

services:
  nginx:
    # Web server and reverse proxy
    # Handles HTTPS on port 443
    # Routes traffic to WordPress
    
  wordpress:
    # PHP application server
    # Runs PHP-FPM (FastCGI Process Manager)
    # Communicates with MariaDB
    
  mariadb:
    # Database server
    # Stores WordPress data
    # Internal communication only

networks:
  inception_network:
    # Custom Docker network for inter-container communication
    # Isolated from host network (per requirements)

volumes:
  db_volume:
    # Persists MariaDB data
    # Location: /home/login/data/db/
    
  wordpress_volume:
    # Persists WordPress files
    # Location: /home/login/data/wordpress/
```

### Dockerfile Structure

Each service has its own Dockerfile:

```
srcs/requirements/
├── nginx/
│   ├── Dockerfile              # NGINX configuration
│   ├── conf/
│   │   └── nginx.conf          # NGINX configuration file
│   └── tools/
│       └── setup.sh            # Setup script for NGINX
│
├── wordpress/
│   ├── Dockerfile              # WordPress + PHP-FPM configuration
│   ├── conf/
│   │   └── www.conf            # PHP-FPM configuration
│   └── tools/
│       └── setup.sh            # WordPress setup script
│
└── mariadb/
    ├── Dockerfile              # MariaDB configuration
    ├── conf/
    │   └── my.cnf              # MySQL configuration
    └── tools/
        └── setup.sh            # Database initialization script
```

### Network Diagram

```
┌─────────────────────────────────────────────────┐
│             Docker Network (inception)          │
│                                                 │
│  ┌──────────┐     ┌──────────┐     ┌────────┐  │
│  │  NGINX   │────▶│ WordPress │────▶│ MariaDB│  │
│  │  :443    │     │  :9000   │     │ :3306  │  │
│  └──────────┘     └──────────┘     └────────┘  │
│                                                 │
│  Volumes:                                       │
│  - wordpress_volume ◀── WordPress files        │
│  - db_volume ◀────────── Database files        │
│                                                 │
└─────────────────────────────────────────────────┘
         ▲
         │ HTTPS Port 443
         │ (Host Machine)
```

---

## Container Management

### View Container Information

```bash
# List running containers
docker-compose -f srcs/docker-compose.yml ps

# List all containers (including stopped)
docker ps -a

# View container details
docker-compose -f srcs/docker-compose.yml ps nginx

# Show container resource usage
docker stats
```

### Access Container Shell

```bash
# Enter WordPress container shell
docker exec -it wordpress_container bash

# Enter MariaDB container shell
docker exec -it mariadb_container bash

# Enter NGINX container shell
docker exec -it nginx_container sh

# Run a specific command in container
docker exec nginx_container nginx -t  # Test NGINX configuration
```

### View Container Logs

```bash
# View all logs
docker-compose -f srcs/docker-compose.yml logs

# View specific service logs
docker-compose -f srcs/docker-compose.yml logs wordpress

# Follow logs in real-time
docker-compose -f srcs/docker-compose.yml logs -f mariadb

# Show last 100 lines
docker-compose -f srcs/docker-compose.yml logs --tail=100 nginx

# Exit log viewing: Ctrl+C
```

### Restart Containers

```bash
# Restart single service
docker-compose -f srcs/docker-compose.yml restart nginx

# Restart all services
docker-compose -f srcs/docker-compose.yml restart

# Stop and start (harder restart)
docker-compose -f srcs/docker-compose.yml stop wordpress
docker-compose -f srcs/docker-compose.yml start wordpress

# Rebuild and restart
docker-compose -f srcs/docker-compose.yml up -d --build nginx
```

### Check Container Processes

```bash
# View running processes in container
docker exec wordpress_container ps aux

# View environment variables
docker exec wordpress_container env

# Check if service is listening on port
docker exec nginx_container netstat -tlnp
```

---

## Volume and Data Persistence

### Volumes Management

```bash
# List all volumes
docker volume ls

# Inspect volume (see mount path)
docker volume inspect inception_db_volume

# Get volume mount point
docker volume inspect inception_db_volume --format='{{.Mountpoint}}'
```

### Access Volume Data on Host

```bash
# Data is stored in: /home/login/data/

# View WordPress files
ls -la /home/login/data/wordpress/

# View database files
ls -la /home/login/data/db/

# Check permissions
stat /home/login/data/

# Change permissions if needed
sudo chown -R $(whoami):$(whoami) /home/login/data/
chmod -R 755 /home/login/data/
```

### Backup and Restore

**Backup Database**:

```bash
# Create backup directory
mkdir -p ~/backups

# Dump database from container
docker exec mariadb_container mysqldump \
  -u <DB_USER> -p<DB_PASSWORD> <DB_NAME> \
  > ~/backups/wordpress_db_$(date +%Y%m%d).sql

# Or backup entire volume
docker run --rm \
  -v inception_db_volume:/data \
  -v ~/backups:/backup \
  alpine tar czf /backup/db_$(date +%Y%m%d).tar.gz -C /data .
```

**Restore Database**:

```bash
# Restore from SQL dump
docker exec -i mariadb_container mysql \
  -u <DB_USER> -p<DB_PASSWORD> <DB_NAME> \
  < ~/backups/wordpress_db_20231201.sql

# Or restore from tar backup
docker run --rm \
  -v inception_db_volume:/data \
  -v ~/backups:/backup \
  alpine tar xzf /backup/db_20231201.tar.gz -C /data
```

**Backup WordPress Files**:

```bash
# Backup WordPress volume
docker run --rm \
  -v inception_wordpress_volume:/data \
  -v ~/backups:/backup \
  alpine tar czf /backup/wordpress_$(date +%Y%m%d).tar.gz -C /data .

# Restore WordPress
docker run --rm \
  -v inception_wordpress_volume:/data \
  -v ~/backups:/backup \
  alpine tar xzf /backup/wordpress_20231201.tar.gz -C /data
```

### Persistent Data Locations

```
Host Machine                Docker Container              Purpose
─────────────────────────────────────────────────────────────────
/home/login/data/          ◀── Mounted as volumes
├── wordpress/             ◀── /var/www/html          WordPress files
├── db/                    ◀── /var/lib/mysql         Database files
└── (ftp if enabled)       ◀── /ftp_home              FTP root
```

---

## Debugging and Troubleshooting

### Common Issues and Solutions

#### Issue: Build Fails - "Permission Denied"

```bash
# Solution: Check Docker daemon access
sudo usermod -aG docker $USER
newgrp docker
docker ps

# If still failing:
sudo systemctl restart docker
```

#### Issue: Port Already in Use

```bash
# Find process using port 443
sudo lsof -i :443

# Kill the process
sudo kill -9 <PID>

# Or change port in docker-compose.yml
# ports:
#   - "8443:443"
```

#### Issue: Database Connection Failed

```bash
# Check if MariaDB container is running
docker ps | grep mariadb

# View MariaDB logs
docker-compose -f srcs/docker-compose.yml logs mariadb

# Test database connection from WordPress container
docker exec -it wordpress_container bash
mysql -h mariadb -u <DB_USER> -p<DB_PASSWORD> <DB_NAME>
```

#### Issue: NGINX Configuration Error

```bash
# Test NGINX configuration
docker exec nginx_container nginx -t

# View NGINX error logs
docker exec nginx_container cat /var/log/nginx/error.log

# View NGINX access logs
docker exec nginx_container cat /var/log/nginx/access.log
```

#### Issue: WordPress Shows Blank Page

```bash
# Check WordPress error logs
docker exec wordpress_container cat /var/log/php-fpm.log

# Check PHP-FPM status
docker exec wordpress_container php-fpm -i

# Verify WordPress files exist
docker exec wordpress_container ls -la /var/www/html/
```

### Debug Mode

Enable detailed logging:

```bash
# View Docker Compose debug output
docker-compose -f srcs/docker-compose.yml up --verbose

# Enable WordPress debug mode (edit wp-config.php)
docker exec -it wordpress_container bash
echo "define('WP_DEBUG', true);" >> /var/www/html/wp-config.php
```

### Network Debugging

```bash
# Test container connectivity
docker exec wordpress_container ping mariadb

# Check DNS resolution
docker exec wordpress_container nslookup mariadb

# Inspect network
docker network inspect inception_network

# Check port accessibility
docker exec wordpress_container curl http://nginx:80/

# View container IP address
docker inspect inception_nginx | grep IPAddress
```

### Performance Analysis

```bash
# Monitor resource usage
docker stats

# View container memory limits
docker inspect inception_wordpress | grep Memory

# Check disk usage of volumes
du -sh /home/login/data/*

# View slow queries (if enabled in MariaDB)
docker exec mariadb_container mysql \
  -u <DB_USER> -p<DB_PASSWORD> -e \
  "SHOW SLOW LOGS;"
```

---

## Development Workflow

### Making Changes to Dockerfiles

```bash
# Edit a Dockerfile
nano srcs/requirements/nginx/Dockerfile

# Rebuild that specific service
docker-compose -f srcs/docker-compose.yml build --no-cache nginx

# Restart the service
docker-compose -f srcs/docker-compose.yml up -d nginx

# Check the changes
docker-compose -f srcs/docker-compose.yml logs nginx
```

### Making Changes to Configuration Files

```bash
# Edit NGINX configuration
nano srcs/requirements/nginx/conf/nginx.conf

# Rebuild and restart
make clean
make
# Or:
docker-compose -f srcs/docker-compose.yml build --no-cache nginx
docker-compose -f srcs/docker-compose.yml up -d nginx

# Verify configuration
docker exec nginx_container nginx -t
```

### Making Changes to Setup Scripts

```bash
# Edit setup script
nano srcs/requirements/wordpress/tools/setup.sh

# Rebuild the image
docker-compose -f srcs/docker-compose.yml build --no-cache wordpress

# Remove old container and start new one
docker-compose -f srcs/docker-compose.yml rm -f wordpress
docker-compose -f srcs/docker-compose.yml up -d wordpress

# Check logs
docker-compose -f srcs/docker-compose.yml logs -f wordpress
```

### Adding a Bonus Service

1. **Create directory structure**:
```bash
mkdir -p srcs/requirements/bonus/redis
cd srcs/requirements/bonus/redis

# Create Dockerfile
touch Dockerfile
mkdir -p conf tools
touch conf/redis.conf tools/setup.sh
```

2. **Write Dockerfile and setup script**

3. **Add to docker-compose.yml**:
```yaml
redis:
  build: ./requirements/bonus/redis
  container_name: inception_redis
  networks:
    - inception
  environment:
    - REDIS_PASSWORD=${REDIS_PASSWORD}
  volumes:
    - redis_data:/data
```

4. **Build and test**:
```bash
docker-compose build redis
docker-compose up -d redis
docker-compose logs -f redis
```

---

## Best Practices

### Docker Best Practices

1. **Use .dockerignore** to exclude unnecessary files:
```bash
cat > srcs/.dockerignore << EOF
.git
.gitignore
*.md
.vscode
.idea
EOF
```

2. **Minimize layer count** by combining RUN commands:
```dockerfile
# Bad: Multiple RUN commands
RUN apt-get update
RUN apt-get install -y nginx
RUN apt-get clean

# Good: Single RUN command
RUN apt-get update && apt-get install -y nginx && apt-get clean
```

3. **Use specific base image versions**:
```dockerfile
# Bad
FROM alpine:latest

# Good
FROM alpine:3.18
```

4. **Run as non-root user**:
```dockerfile
RUN addgroup www && adduser -D -G www www
USER www
```

5. **Handle signals properly** (PID 1):
```dockerfile
# Use exec form for entrypoint
ENTRYPOINT ["executable", "param1", "param2"]

# Not shell form
ENTRYPOINT executable param1 param2
```

### Security Best Practices

1. **Never hardcode secrets**:
```dockerfile
# Bad
ENV DB_PASSWORD=secret123

# Good
ENV DB_PASSWORD=
# Pass via --env or .env file
```

2. **Use Docker secrets for sensitive data**:
```yaml
services:
  wordpress:
    secrets:
      - db_password
      - db_root_password
```

3. **Scan images for vulnerabilities**:
```bash
docker scan inception_wordpress:latest
```

4. **Keep images small**:
```bash
# Use Alpine Linux instead of Ubuntu
FROM alpine:3.18

# Or use slim variants
FROM python:3.11-slim
```

### Logging Best Practices

1. **Log to stdout/stderr**:
```dockerfile
# Use tail -f logs to stdout
CMD ["nginx", "-g", "daemon off;"]
```

2. **Use structured logging**:
```bash
# Instead of random echo messages
echo "$(date) - Service started successfully"
```

3. **Capture logs**:
```bash
# Redirect to files that are mounted as volumes
docker-compose -f srcs/docker-compose.yml logs > logs/compose.log
```

### Documentation Best Practices

1. **Document each Dockerfile**:
```dockerfile
# Description of what this image does
# Base image and why
# Ports exposed
# Volumes used
# Environment variables
```

2. **Keep README updated**:
   - Update versions
   - Document new features
   - Include examples

3. **Add inline comments**:
```bash
# Explain complex commands
RUN apt-get update && \
    # Install base packages
    apt-get install -y curl && \
    # Install nginx
    apt-get install -y nginx && \
    # Clean up package manager cache
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

---

## Useful Commands Reference

```bash
# Building
make                           # Build and start
make clean                     # Clean everything
docker-compose build           # Build images
docker-compose build --no-cache # Force rebuild

# Running
make start/stop/restart        # Control services
docker-compose up -d           # Start in background
docker-compose down            # Stop and remove

# Debugging
docker ps                      # List containers
docker logs <container>        # View logs
docker exec -it <container> bash # Access shell
docker stats                   # Resource usage
docker network inspect         # Network info

# Volumes
docker volume ls               # List volumes
docker volume inspect          # Volume details
docker run --rm -v vol:/data alpine tar czf ...  # Backup

# Images
docker images                  # List images
docker rmi <image>            # Remove image
docker pull <image>           # Download image
```

---

## Next Steps

- Read [README.md](README.md) for project overview
- See [USER_DOC.md](USER_DOC.md) for end-user guide
- Review `Inception.pdf` for full specifications
- Implement the bonus services
- Test thoroughly before submission

---

**Last Updated**: December 2024  
**Version**: 5.0  
**Project**: Inception - 42 School
