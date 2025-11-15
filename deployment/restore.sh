#!/bin/bash

# ============================================================================
# Production Tracker - Restore Script
# ============================================================================
#
# This script restores a backup created by backup.sh
#
# Usage: ./restore.sh <backup_name>
#
# WARNING: This will overwrite current data!
#
# ============================================================================

set -e

# Check arguments
if [ -z "$1" ]; then
  echo "Usage: ./restore.sh <backup_name>"
  echo ""
  echo "Available backups:"
  ls -1 /opt/production-tracker/backups/
  exit 1
fi

BACKUP_NAME="$1"
BACKUP_DIR="/opt/production-tracker/backups/$BACKUP_NAME"
PROJECT_DIR="/opt/production-tracker"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if backup exists
if [ ! -d "$BACKUP_DIR" ]; then
  echo -e "${RED}Error: Backup not found: $BACKUP_DIR${NC}"
  exit 1
fi

# Confirmation
echo -e "${YELLOW}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║                  WARNING                              ║${NC}"
echo -e "${YELLOW}╠═══════════════════════════════════════════════════════╣${NC}"
echo -e "${YELLOW}║  This will OVERWRITE current data with backup:       ║${NC}"
echo -e "${YELLOW}║  $BACKUP_NAME${NC}"
echo -e "${YELLOW}║                                                       ║${NC}"
echo -e "${YELLOW}║  Current data will be lost!                           ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
read -p "Are you sure you want to continue? (type 'yes' to confirm): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Restore cancelled."
  exit 0
fi

echo ""
echo -e "${BLUE}Starting restore process...${NC}"
echo ""

# 1. Stop services
echo "Stopping services..."
cd "$PROJECT_DIR"
docker-compose -f docker-compose.prod.yml down
echo -e "${GREEN}✓ Services stopped${NC}"

# 2. Restore database
if [ -f "$BACKUP_DIR/database.sql.gz" ]; then
  echo "Restoring database..."

  # Start only PostgreSQL
  docker-compose -f docker-compose.prod.yml up -d postgres
  sleep 5

  # Drop and recreate database
  docker-compose -f docker-compose.prod.yml exec -T postgres psql -U postgres -c "DROP DATABASE IF EXISTS production_tracker;"
  docker-compose -f docker-compose.prod.yml exec -T postgres psql -U postgres -c "CREATE DATABASE production_tracker;"

  # Restore database
  gunzip < "$BACKUP_DIR/database.sql.gz" | \
    docker-compose -f docker-compose.prod.yml exec -T postgres \
    psql -U postgres production_tracker

  echo -e "${GREEN}✓ Database restored${NC}"
else
  echo -e "${YELLOW}⚠ No database backup found, skipping${NC}"
fi

# 3. Restore uploaded files
if [ -f "$BACKUP_DIR/uploads.tar.gz" ]; then
  echo "Restoring uploaded files..."

  # Backup current uploads just in case
  if [ -d "$PROJECT_DIR/backend/uploads" ]; then
    mv "$PROJECT_DIR/backend/uploads" "$PROJECT_DIR/backend/uploads.old.$(date +%s)"
  fi

  # Restore uploads
  tar -xzf "$BACKUP_DIR/uploads.tar.gz" -C "$PROJECT_DIR/backend/"

  echo -e "${GREEN}✓ Uploads restored${NC}"
else
  echo -e "${YELLOW}⚠ No uploads backup found, skipping${NC}"
fi

# 4. Restore configuration (optional - ask user)
if [ -d "$BACKUP_DIR/config" ]; then
  read -p "Restore configuration files? (y/n): " RESTORE_CONFIG

  if [ "$RESTORE_CONFIG" = "y" ]; then
    echo "Restoring configuration..."

    # Backend .env
    if [ -f "$BACKUP_DIR/config/backend.env" ]; then
      cp "$PROJECT_DIR/backend/.env" "$PROJECT_DIR/backend/.env.backup.$(date +%s)" 2>/dev/null || true
      cp "$BACKUP_DIR/config/backend.env" "$PROJECT_DIR/backend/.env"
      echo "  - backend/.env restored"
    fi

    # Nginx config
    if [ -f "$BACKUP_DIR/config/nginx.conf" ]; then
      sudo cp "/etc/nginx/sites-available/production-tracker" "/etc/nginx/sites-available/production-tracker.backup.$(date +%s)" 2>/dev/null || true
      sudo cp "$BACKUP_DIR/config/nginx.conf" "/etc/nginx/sites-available/production-tracker"
      sudo nginx -t && sudo systemctl reload nginx
      echo "  - nginx.conf restored"
    fi

    echo -e "${GREEN}✓ Configuration restored${NC}"
  fi
fi

# 5. Start services
echo "Starting services..."
docker-compose -f docker-compose.prod.yml up -d
sleep 10
echo -e "${GREEN}✓ Services started${NC}"

# 6. Verify
echo "Verifying services..."
if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
  echo -e "${GREEN}✓ Services are running${NC}"
else
  echo -e "${RED}✗ Services failed to start${NC}"
  docker-compose -f docker-compose.prod.yml logs
  exit 1
fi

# Summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Restore Completed Successfully             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Backup '$BACKUP_NAME' has been restored."
echo ""
echo "What was restored:"
[ -f "$BACKUP_DIR/database.sql.gz" ] && echo "  ✓ Database"
[ -f "$BACKUP_DIR/uploads.tar.gz" ] && echo "  ✓ Uploaded files"
[ "$RESTORE_CONFIG" = "y" ] && echo "  ✓ Configuration files"
echo ""
echo "Services are now running."
echo ""
