# Inception

*This project has been created as part of the 42 curriculum by chrleroy.*

## Description

Inception is a System Administration project that broadens knowledge of containerization through Docker. The goal is to set up a mini-infrastructure with multiple services (NGINX, WordPress, MariaDB) running in separate Docker containers, orchestrated using Docker Compose and configured via a Makefile.

This project teaches best practices for:
- Docker containerization
- Container networking and volumes
- SSL/TLS configuration
- Environment-based configuration
- Infrastructure as Code (IaC)

## Instructions

### Prerequisites

- Docker and Docker Compose installed
- A Linux-based Virtual Machine (as per project requirements)
- Make installed

### Compilation, Installation & Execution

1. **Clone the repository** (if not already done):
   ```bash
   git clone https://github.com/cuistobal/42_Inception.git
   cd 42_Inception
   ```

2. **Configure your environment**:
   - Create a `.env` file in the `srcs/` directory (see example below)
   - Update your `/etc/hosts` file to point `login.42.fr` to your local IP

   Example `.env` file:
   ```
   DOMAIN_NAME=<your_login>.42.fr
   DB_NAME=wordpress_db
   DB_USER=wordpress_user
   DB_PASSWORD=<secure_password>
   DB_ROOT_PASSWORD=<secure_root_password>
   WP_ADMIN_USER=admin_user
   WP_ADMIN_PASSWORD=<secure_password>
   WP_ADMIN_EMAIL=admin@example.com
   ```

3. **Build and start the project**:
   ```bash
   make
   ```

4. **Access the services**:
   - WordPress: https://<your_login>.42.fr
   - Adminer (if bonus enabled): https://<your_login>.42.fr:8080 (or configured port)

5. **Stop the project**:
   ```bash
   make down
   ```

6. **Clean up everything**:
   ```bash
   make clean
   ```

### Project Structure

```
.
├── README.md                 # This file
├── USER_DOC.md              # User documentation
├── DEV_DOC.md               # Developer documentation
├── Makefile                 # Build automation
├── docker-compose.yml       # Docker services orchestration
├── Inception.pdf            # Project specification (v5.0)
└── srcs/
    ├── requirements/
    │   ├── nginx/
    │   │   ├── Dockerfile
    │   │   ├── conf/
    │   │   │   └── nginx.conf
    │   │   └── tools/
    │   │       └── setup.sh
    │   ├── mariadb/
    │   │   ├── Dockerfile
    │   │   ├── conf/
    │   │   │   └── my.cnf
    │   │   └── tools/
    │   │       └── setup.sh
    │   ├── wordpress/
    │   │   ├── Dockerfile
    │   │   ├── conf/
    │   │   │   └── www.conf
    │   │   └── tools/
    │   │       └── setup.sh
    │   └── bonus/
    │       ├── redis/
    │       ├── ftp/
    │       ├── adminer/
    │       ├── portainer/
    │       └── website/
    └── .env.example          # Environment variables template
```

## Resources

### Docker & Containerization
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [PID 1 in Docker Containers](https://docs.docker.com/config/containers/multi-service_container/)

### Web Services
- [NGINX Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt & SSL/TLS](https://letsencrypt.org/)
- [WordPress Installation Guide](https://wordpress.org/support/article/how-to-install-wordpress/)
- [MariaDB Official Documentation](https://mariadb.com/docs/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.php)

### Security & Secrets Management
- [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/)
- [Environment Variables Best Practices](https://12factor.net/config)
- [OWASP Guide to Secure Secrets Management](https://owasp.org/)

### AI Usage in this Project

This project has been fully generated with AI

**Important**: All AI-generated content has been reviewed, tested, and validated before implementation. No content is used without full understanding and responsibility.

## Technical Choices & Comparisons

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|------------------|-------------------|
| **Overhead** | High (full OS) | Low (shared kernel) |
| **Performance** | Slower startup (minutes) | Fast startup (seconds) |
| **Resource Usage** | Heavy (GBs per VM) | Lightweight (MBs per container) |
| **Use Case** | Full isolation, legacy systems | Microservices, rapid deployment |
| **Project Choice** | Docker for efficiency | - |

**Why Docker for Inception**: Reduced resource usage, faster iteration, industry-standard for microservices.

### Secrets vs Environment Variables

| Feature | Environment Variables | Docker Secrets |
|---------|----------------------|----------------|
| **Security** | Visible in processes | Encrypted, isolated |
| **Persistence** | In files (easy to leak) | Never written to disk |
| **Use Case** | Non-sensitive config | Passwords, API keys |
| **Complexity** | Simple | Requires Swarm/Compose |
| **Project Usage** | Configuration (domain, DB name) | Passwords, credentials |

**Best Practice**: I used `.env` for non-sensitive variables and Docker secrets for passwords.

### Docker Network vs Host Network

| Feature | Docker Network | Host Network |
|---------|----------------|--------------|
| **Isolation** | Container isolated | Direct host access |
| **Security** | Better (less exposed) | Lower (full exposure) |
| **Port Mapping** | Yes (NAT) | Direct binding |
| **Performance** | Slight overhead | Minimal overhead |
| **Project Rules** | ✅ Required | ❌ Forbidden |

**Why Host Network is Forbidden**: To enforce proper network design and security best practices.

### Docker Volumes vs Bind Mounts

| Feature | Volumes | Bind Mounts |
|---------|---------|------------|
| **Management** | Docker-managed | Host-managed |
| **Portability** | High (platform-agnostic) | Low (path-dependent) |
| **Performance** | Optimized | Variable |
| **Backup/Restore** | Easy with docker commands | Manual process |
| **Use Case** | Databases, persistent data | Development, debugging |
| **Project Usage** | ✅ Required for DB & WP files | - |

**Why Volumes**: Better portability, easier management, and official Docker best practices.

## General Guidelines

- The entire project must run on a Virtual Machine
- All mandatory containers use Alpine or Debian (previous stable version)
- Custom Dockerfiles required (no pre-built images except base OS)
- No pre-made Docker Hub images allowed
- Containers must restart on crash
- No infinite loops or background hacks (tail -f, sleep infinity, etc.)
- Proper daemon configuration with PID 1 handling
- NGINX is the only entry point (port 443, TLS 1.2/1.3)
- All credentials must be managed securely (Docker secrets or `.env`)
- Git repository must not contain exposed credentials

## Support & Documentation

For detailed user and developer documentation, see:
- **[USER_DOC.md](USER_DOC.md)** - End-user guide
- **[DEV_DOC.md](DEV_DOC.md)** - Developer guide

## License

42 School Project - All rights reserved

## Acknowledgments

- 42 School curriculum
- Docker community and documentation
- Open-source projects referenced in this implementation
