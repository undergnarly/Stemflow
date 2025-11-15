# Production Tracker - Deployment Guide

Complete guide for deploying Production Tracker backend to a production server.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Deploy](#quick-deploy)
- [Manual Deployment](#manual-deployment)
- [Docker Deployment](#docker-deployment)
- [Database Setup](#database-setup)
- [Environment Configuration](#environment-configuration)
- [SSL/HTTPS Setup](#sslhttps-setup)
- [Systemd Services](#systemd-services)
- [Monitoring](#monitoring)
- [Backup Strategy](#backup-strategy)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Server Requirements

- **OS:** Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- **RAM:** 2GB minimum (4GB recommended)
- **CPU:** 2 cores minimum
- **Disk:** 20GB minimum
- **Network:** Static IP or domain name

### Software Requirements

- **Docker:** 20.10+
- **Docker Compose:** 2.0+
- **Git:** 2.0+
- **Nginx:** 1.18+ (for reverse proxy)
- **Certbot:** For SSL certificates (optional but recommended)

### Domain Setup

- Domain or subdomain pointing to your server IP
- DNS A record configured
- Ports 80 and 443 accessible

---

## Quick Deploy

**For servers with Claude Code installed:**

```bash
# 1. Clone repository
git clone <repository-url>
cd Stemflow

# 2. Run automated deployment script
chmod +x deploy.sh
./deploy.sh

# 3. Follow prompts to configure:
# - Domain name
# - SSL certificate
# - Database password
# - API keys

# 4. Done! API will be available at https://your-domain.com
```

**The script will:**
- ✅ Install dependencies
- ✅ Configure environment variables
- ✅ Set up PostgreSQL database
- ✅ Configure Nginx reverse proxy
- ✅ Set up SSL with Let's Encrypt
- ✅ Start services with Docker Compose
- ✅ Run database migrations
- ✅ Create systemd service for auto-restart

---

## Manual Deployment

### Step 1: Install Docker

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker

# Add your user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Step 2: Clone Repository

```bash
cd /opt
sudo git clone <repository-url> production-tracker
cd production-tracker
sudo chown -R $USER:$USER .
```

### Step 3: Configure Environment

```bash
# Copy production environment template
cp .env.production backend/.env

# Edit configuration
nano backend/.env
```

**Required variables:**
```bash
# Database
DATABASE_URL=postgresql://postgres:CHANGE_THIS_PASSWORD@postgres:5432/production_tracker

# Security
JWT_SECRET=GENERATE_RANDOM_SECRET_HERE  # Use: openssl rand -hex 32
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=7

# Anthropic API
ANTHROPIC_API_KEY=sk-ant-your-actual-key-here
ANTHROPIC_MODEL=claude-sonnet-4-20250514

# File Upload
UPLOAD_DIR=/app/uploads
MAX_FILE_SIZE_MB=100

# CORS
CORS_ORIGINS=https://your-domain.com,https://www.your-domain.com

# Application
LOG_LEVEL=INFO
ENVIRONMENT=production
```

### Step 4: Configure Docker Compose

Use the production Docker Compose file:

```bash
# Use production configuration
docker-compose -f docker-compose.prod.yml up -d
```

### Step 5: Run Database Migrations

```bash
# Enter backend container
docker-compose -f docker-compose.prod.yml exec backend bash

# Run migrations
prisma migrate deploy

# Exit container
exit
```

### Step 6: Configure Nginx

```bash
# Install Nginx
sudo apt install -y nginx

# Copy Nginx configuration
sudo cp deployment/nginx.conf /etc/nginx/sites-available/production-tracker
sudo ln -s /etc/nginx/sites-available/production-tracker /etc/nginx/sites-enabled/

# Edit configuration with your domain
sudo nano /etc/nginx/sites-available/production-tracker

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

### Step 7: Set Up SSL with Let's Encrypt

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Certbot will automatically configure Nginx for HTTPS
# Certificates auto-renew via systemd timer
```

### Step 8: Verify Deployment

```bash
# Check services
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs -f backend

# Test API
curl https://your-domain.com/health

# Should return: {"status":"healthy"}
```

---

## Docker Deployment

### Production Docker Compose

File: `docker-compose.prod.yml`

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: production_tracker_db
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: production_tracker
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: production_tracker_api
    restart: unless-stopped
    env_file:
      - ./backend/.env
    volumes:
      - ./backend/uploads:/app/uploads
      - ./backend/logs:/app/logs
    ports:
      - "127.0.0.1:8000:8000"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - backend
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:

networks:
  backend:
    driver: bridge
```

### Running Production Stack

```bash
# Start services
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Stop services
docker-compose -f docker-compose.prod.yml down

# Restart services
docker-compose -f docker-compose.prod.yml restart

# Update and restart
git pull
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

---

## Database Setup

### PostgreSQL Configuration

**Create production database:**

```bash
# Enter PostgreSQL container
docker-compose -f docker-compose.prod.yml exec postgres psql -U postgres

# Create database (if not auto-created)
CREATE DATABASE production_tracker;

# Create dedicated user (recommended)
CREATE USER pt_user WITH PASSWORD 'secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE production_tracker TO pt_user;

# Exit
\q
```

### Database Migrations

```bash
# Run migrations
docker-compose -f docker-compose.prod.yml exec backend prisma migrate deploy

# Check migration status
docker-compose -f docker-compose.prod.yml exec backend prisma migrate status

# Generate Prisma client
docker-compose -f docker-compose.prod.yml exec backend prisma generate
```

### Database Backup

```bash
# Create backup script
cat > /opt/production-tracker/backup-db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/production-tracker/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

docker-compose -f docker-compose.prod.yml exec -T postgres \
  pg_dump -U postgres production_tracker | \
  gzip > $BACKUP_DIR/backup_$DATE.sql.gz

# Keep only last 7 days
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete
EOF

chmod +x /opt/production-tracker/backup-db.sh

# Add to crontab (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/production-tracker/backup-db.sh") | crontab -
```

---

## Environment Configuration

### Production Environment Variables

Create `.env.production`:

```bash
# ============================================================================
# PRODUCTION CONFIGURATION
# ============================================================================

# Database
DATABASE_URL=postgresql://postgres:STRONG_PASSWORD_HERE@postgres:5432/production_tracker

# JWT Configuration
JWT_SECRET=USE_openssl_rand_hex_32_TO_GENERATE
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=7

# Anthropic API
ANTHROPIC_API_KEY=sk-ant-your-production-key
ANTHROPIC_MODEL=claude-sonnet-4-20250514

# File Upload
UPLOAD_DIR=/app/uploads
MAX_FILE_SIZE_MB=100

# CORS - UPDATE WITH YOUR DOMAIN
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Application
LOG_LEVEL=INFO
ENVIRONMENT=production
WORKERS=4

# Optional: Sentry for error tracking
# SENTRY_DSN=https://your-sentry-dsn

# Optional: Email notifications
# SMTP_HOST=smtp.gmail.com
# SMTP_PORT=587
# SMTP_USER=your-email@gmail.com
# SMTP_PASSWORD=your-app-password
```

### Generating Secrets

```bash
# Generate JWT secret
openssl rand -hex 32

# Generate database password
openssl rand -base64 32

# Generate API key
openssl rand -hex 16
```

---

## SSL/HTTPS Setup

### Option 1: Let's Encrypt (Free, Recommended)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx \
  -d yourdomain.com \
  -d www.yourdomain.com \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email

# Certificates auto-renew via systemd timer
# Check renewal
sudo certbot renew --dry-run
```

### Option 2: Custom SSL Certificate

```bash
# If you have your own SSL certificate
sudo mkdir -p /etc/nginx/ssl

# Copy certificate files
sudo cp your-cert.crt /etc/nginx/ssl/
sudo cp your-key.key /etc/nginx/ssl/

# Update Nginx configuration
sudo nano /etc/nginx/sites-available/production-tracker

# Add SSL configuration
ssl_certificate /etc/nginx/ssl/your-cert.crt;
ssl_certificate_key /etc/nginx/ssl/your-key.key;
```

### SSL Best Practices

```nginx
# In nginx.conf
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_stapling on;
ssl_stapling_verify on;
add_header Strict-Transport-Security "max-age=31536000" always;
```

---

## Systemd Services

### Create Systemd Service

```bash
# Create service file
sudo nano /etc/systemd/system/production-tracker.service
```

```ini
[Unit]
Description=Production Tracker Backend
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/production-tracker
ExecStart=/usr/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/bin/docker-compose -f docker-compose.prod.yml down
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable production-tracker
sudo systemctl start production-tracker

# Check status
sudo systemctl status production-tracker
```

---

## Monitoring

### Health Checks

```bash
# API health check
curl https://yourdomain.com/health

# Database health
docker-compose -f docker-compose.prod.yml exec postgres pg_isready

# Container status
docker-compose -f docker-compose.prod.yml ps
```

### Log Management

```bash
# View logs
docker-compose -f docker-compose.prod.yml logs -f backend

# Export logs
docker-compose -f docker-compose.prod.yml logs backend > backend.log

# Rotate logs (add to logrotate)
sudo nano /etc/logrotate.d/production-tracker
```

```
/opt/production-tracker/backend/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
}
```

### Resource Monitoring

```bash
# Install monitoring tools
sudo apt install -y htop

# Monitor Docker resources
docker stats

# Monitor disk usage
df -h
du -sh /opt/production-tracker/*
```

---

## Backup Strategy

### Automated Backups

```bash
# Create comprehensive backup script
cat > /opt/production-tracker/backup-all.sh << 'EOF'
#!/bin/bash
set -e

BACKUP_DIR="/opt/production-tracker/backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Database backup
docker-compose -f /opt/production-tracker/docker-compose.prod.yml exec -T postgres \
  pg_dump -U postgres production_tracker | gzip > $BACKUP_DIR/database.sql.gz

# Upload files backup
tar -czf $BACKUP_DIR/uploads.tar.gz /opt/production-tracker/backend/uploads/

# Configuration backup
cp /opt/production-tracker/backend/.env $BACKUP_DIR/
cp /etc/nginx/sites-available/production-tracker $BACKUP_DIR/nginx.conf

# Keep only last 30 days
find /opt/production-tracker/backups -type d -mtime +30 -exec rm -rf {} +

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x /opt/production-tracker/backup-all.sh

# Schedule daily backups at 3 AM
(crontab -l 2>/dev/null; echo "0 3 * * * /opt/production-tracker/backup-all.sh") | crontab -
```

### Restore from Backup

```bash
# Restore database
gunzip < backup_20240115.sql.gz | \
  docker-compose -f docker-compose.prod.yml exec -T postgres \
  psql -U postgres production_tracker

# Restore uploads
tar -xzf uploads.tar.gz -C /opt/production-tracker/backend/
```

---

## Troubleshooting

### Common Issues

**1. Cannot connect to database**
```bash
# Check PostgreSQL is running
docker-compose -f docker-compose.prod.yml ps postgres

# Check logs
docker-compose -f docker-compose.prod.yml logs postgres

# Verify DATABASE_URL in .env
```

**2. SSL certificate errors**
```bash
# Renew certificate
sudo certbot renew

# Check Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

**3. High memory usage**
```bash
# Check Docker stats
docker stats

# Restart services
docker-compose -f docker-compose.prod.yml restart

# Clear logs
docker-compose -f docker-compose.prod.yml logs --tail=0 -f
```

**4. API not responding**
```bash
# Check backend logs
docker-compose -f docker-compose.prod.yml logs backend

# Restart backend
docker-compose -f docker-compose.prod.yml restart backend

# Check Nginx
sudo systemctl status nginx
```

### Debug Mode

```bash
# Enable debug logging
docker-compose -f docker-compose.prod.yml exec backend \
  sh -c 'export LOG_LEVEL=DEBUG && python -m uvicorn app.main:app'

# View real-time logs
docker-compose -f docker-compose.prod.yml logs -f --tail=100
```

---

## Security Checklist

- [ ] Firewall configured (UFW or iptables)
- [ ] Only ports 80, 443, and SSH open
- [ ] Strong database password set
- [ ] JWT secret is random and secure
- [ ] SSL certificate installed and valid
- [ ] CORS origins properly configured
- [ ] File upload limits set
- [ ] Regular backups scheduled
- [ ] System updates automated
- [ ] Fail2ban installed for SSH protection
- [ ] Docker containers run as non-root (if possible)
- [ ] API rate limiting enabled

---

## Maintenance

### Regular Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d

# Update application
cd /opt/production-tracker
git pull
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

### Performance Tuning

**PostgreSQL:**
```bash
# Edit postgresql.conf in Docker volume
# Or use environment variables in docker-compose.prod.yml

# Example optimizations:
POSTGRES_SHARED_BUFFERS=256MB
POSTGRES_EFFECTIVE_CACHE_SIZE=1GB
POSTGRES_MAINTENANCE_WORK_MEM=64MB
```

**Nginx:**
```nginx
# Worker processes
worker_processes auto;

# Gzip compression
gzip on;
gzip_types text/plain text/css application/json application/javascript;

# Caching
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m;
```

---

## Support

For issues or questions:
- Check logs: `docker-compose -f docker-compose.prod.yml logs`
- GitHub Issues: [repository-url]/issues
- Documentation: Review README.md and API docs

---

**Production Tracker is now deployed!** 🚀

Access your API at: `https://yourdomain.com`
API Documentation: `https://yourdomain.com/docs`
