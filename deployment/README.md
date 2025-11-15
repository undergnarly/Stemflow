# Production Tracker - Deployment Files

This directory contains configuration files and scripts for deploying Production Tracker to production.

## Files Overview

### Configuration Files

**`nginx.conf`**
- Nginx reverse proxy configuration
- Includes SSL settings, rate limiting, and WebSocket support
- Copy to `/etc/nginx/sites-available/production-tracker`

**`postgres-init.sql`**
- PostgreSQL initialization script
- Runs automatically when database is first created
- Sets up extensions, functions, and views

### Scripts

**`backup.sh`**
- Creates full backup of database, uploads, and configuration
- Usage: `./deployment/backup.sh [backup_name]`
- Backups stored in `/opt/production-tracker/backups/`
- Automatically removes backups older than 7 days

**`restore.sh`**
- Restores from a previous backup
- Usage: `./deployment/restore.sh <backup_name>`
- ⚠️ WARNING: Overwrites current data!

**`monitor.sh`**
- Real-time monitoring dashboard
- Shows service status, resources, errors
- Usage: `./deployment/monitor.sh [--watch]`
- Use `--watch` for continuous monitoring

## Quick Reference

### Daily Operations

```bash
# Check status
./deployment/monitor.sh

# Watch status continuously
./deployment/monitor.sh --watch

# View logs
docker-compose -f docker-compose.prod.yml logs -f backend

# Restart services
docker-compose -f docker-compose.prod.yml restart
```

### Backup & Restore

```bash
# Create backup
./deployment/backup.sh

# Create named backup
./deployment/backup.sh my_backup

# List backups
ls -lh /opt/production-tracker/backups/

# Restore backup
./deployment/restore.sh 20240115_120000
```

### Troubleshooting

```bash
# Check service status
docker-compose -f docker-compose.prod.yml ps

# Check API health
curl https://yourdomain.com/health

# View recent errors
docker-compose -f docker-compose.prod.yml logs --tail=50 | grep ERROR

# Restart a specific service
docker-compose -f docker-compose.prod.yml restart backend

# Database access
docker-compose -f docker-compose.prod.yml exec postgres psql -U postgres production_tracker
```

### Updates

```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# Run migrations
docker-compose -f docker-compose.prod.yml exec backend prisma migrate deploy
```

## Monitoring Checklist

Daily:
- [ ] Check service status (`monitor.sh`)
- [ ] Review error logs
- [ ] Verify API is responding

Weekly:
- [ ] Check disk space
- [ ] Review database size
- [ ] Test backup/restore

Monthly:
- [ ] Update system packages
- [ ] Review SSL certificate expiry
- [ ] Audit access logs
- [ ] Performance optimization

## Emergency Procedures

### Service Down

1. Check status: `docker-compose -f docker-compose.prod.yml ps`
2. View logs: `docker-compose -f docker-compose.prod.yml logs`
3. Restart: `docker-compose -f docker-compose.prod.yml restart`
4. If still down, check Nginx: `sudo systemctl status nginx`

### Database Issues

1. Check connection: `docker-compose -f docker-compose.prod.yml exec postgres pg_isready`
2. View logs: `docker-compose -f docker-compose.prod.yml logs postgres`
3. Restart database: `docker-compose -f docker-compose.prod.yml restart postgres`
4. If corrupted, restore from backup

### High CPU/Memory

1. Check resource usage: `docker stats`
2. Identify culprit: `./deployment/monitor.sh`
3. Restart heavy service: `docker-compose -f docker-compose.prod.yml restart <service>`
4. If persistent, scale resources or optimize queries

### SSL Certificate Expiry

1. Check expiry: `sudo certbot certificates`
2. Renew: `sudo certbot renew`
3. Test renewal: `sudo certbot renew --dry-run`
4. Certificates auto-renew via systemd timer

## Security

### Firewall (UFW)

```bash
# Enable firewall
sudo ufw enable

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Check status
sudo ufw status
```

### Fail2Ban

```bash
# Install
sudo apt install fail2ban

# Configure for Nginx
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
# Edit [nginx-http-auth] and [nginx-noscript] sections

# Restart
sudo systemctl restart fail2ban

# Check status
sudo fail2ban-client status
```

### Security Audit

```bash
# Check for security updates
sudo apt update
sudo apt list --upgradable

# Scan for vulnerabilities
docker scan production_tracker_api

# Review access logs
sudo tail -f /var/log/nginx/production-tracker-access.log

# Check failed login attempts
sudo journalctl -u ssh | grep Failed
```

## Performance Tuning

### PostgreSQL

```sql
-- Connect to database
\c production_tracker

-- Check slow queries
SELECT * FROM slow_queries;

-- Check table sizes
SELECT * FROM table_sizes;

-- Check active connections
SELECT * FROM active_connections;

-- Analyze tables
ANALYZE;

-- Vacuum
VACUUM VERBOSE ANALYZE;
```

### Nginx

```bash
# Test configuration
sudo nginx -t

# Reload (zero downtime)
sudo systemctl reload nginx

# View error log
sudo tail -f /var/log/nginx/error.log

# Check access log patterns
sudo awk '{print $1}' /var/log/nginx/production-tracker-access.log | sort | uniq -c | sort -nr | head -20
```

## Support

For issues not covered here, see main [DEPLOYMENT.md](../DEPLOYMENT.md) documentation.
