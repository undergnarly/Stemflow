#!/bin/bash

# ============================================================================
# Production Tracker - Backup Script
# ============================================================================
#
# This script creates backups of:
# - PostgreSQL database
# - Uploaded files
# - Configuration files
#
# Usage: ./backup.sh [backup_name]
#
# ============================================================================

set -e

# Configuration
BACKUP_ROOT="/opt/production-tracker/backups"
BACKUP_NAME="${1:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="$BACKUP_ROOT/$BACKUP_NAME"
PROJECT_DIR="/opt/production-tracker"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Creating backup: $BACKUP_NAME${NC}"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# 1. Backup database
echo "Backing up database..."
docker-compose -f "$PROJECT_DIR/docker-compose.prod.yml" exec -T postgres \
  pg_dump -U postgres production_tracker | gzip > "$BACKUP_DIR/database.sql.gz"
echo -e "${GREEN}✓ Database backup completed${NC}"

# 2. Backup uploaded files
echo "Backing up uploaded files..."
if [ -d "$PROJECT_DIR/backend/uploads" ]; then
  tar -czf "$BACKUP_DIR/uploads.tar.gz" -C "$PROJECT_DIR/backend" uploads/
  echo -e "${GREEN}✓ Uploads backup completed${NC}"
else
  echo "No uploads directory found, skipping..."
fi

# 3. Backup configuration files
echo "Backing up configuration..."
mkdir -p "$BACKUP_DIR/config"
cp "$PROJECT_DIR/backend/.env" "$BACKUP_DIR/config/backend.env" 2>/dev/null || true
cp "$PROJECT_DIR/docker-compose.prod.yml" "$BACKUP_DIR/config/" 2>/dev/null || true
cp "/etc/nginx/sites-available/production-tracker" "$BACKUP_DIR/config/nginx.conf" 2>/dev/null || true
echo -e "${GREEN}✓ Configuration backup completed${NC}"

# 4. Create backup info file
cat > "$BACKUP_DIR/backup_info.txt" << EOF
Backup Information
==================
Date: $(date)
Hostname: $(hostname)
Backup Name: $BACKUP_NAME

Contents:
- database.sql.gz: PostgreSQL database dump
- uploads.tar.gz: Uploaded files
- config/: Configuration files

Restore Instructions:
=====================
1. Database:
   gunzip < database.sql.gz | docker-compose -f docker-compose.prod.yml exec -T postgres psql -U postgres production_tracker

2. Uploads:
   tar -xzf uploads.tar.gz -C /opt/production-tracker/backend/

3. Configuration:
   cp config/backend.env /opt/production-tracker/backend/.env
   cp config/nginx.conf /etc/nginx/sites-available/production-tracker
EOF

# 5. Calculate sizes
DB_SIZE=$(du -h "$BACKUP_DIR/database.sql.gz" | cut -f1)
if [ -f "$BACKUP_DIR/uploads.tar.gz" ]; then
  UPLOADS_SIZE=$(du -h "$BACKUP_DIR/uploads.tar.gz" | cut -f1)
else
  UPLOADS_SIZE="0"
fi
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

# 6. Cleanup old backups (keep last 7 days)
find "$BACKUP_ROOT" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true

# Summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Backup Completed Successfully              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Backup Location: $BACKUP_DIR"
echo "Database Size: $DB_SIZE"
echo "Uploads Size: $UPLOADS_SIZE"
echo "Total Size: $TOTAL_SIZE"
echo ""
echo "To restore this backup:"
echo "  ./deployment/restore.sh $BACKUP_NAME"
echo ""
