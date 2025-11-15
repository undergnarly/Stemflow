#!/bin/bash

# ============================================================================
# Production Tracker - Monitoring Script
# ============================================================================
#
# Quick health check and monitoring of Production Tracker services
#
# Usage: ./monitor.sh [--watch]
#
# Options:
#   --watch    Continuous monitoring (updates every 5 seconds)
#
# ============================================================================

PROJECT_DIR="/opt/production-tracker"
WATCH_MODE=false

# Check for watch mode
if [ "$1" = "--watch" ]; then
  WATCH_MODE=true
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to display status
show_status() {
  clear
  echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║     Production Tracker - System Status Monitor            ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${BLUE}Timestamp:${NC} $(date)"
  echo ""

  # 1. Docker Services Status
  echo -e "${BLUE}━━━ Docker Services ━━━${NC}"
  cd "$PROJECT_DIR"

  if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo -e "${GREEN}✓ Services Running${NC}"
    docker-compose -f docker-compose.prod.yml ps --format table
  else
    echo -e "${RED}✗ Services Not Running${NC}"
    docker-compose -f docker-compose.prod.yml ps
  fi
  echo ""

  # 2. API Health Check
  echo -e "${BLUE}━━━ API Health Check ━━━${NC}"
  API_HEALTH=$(curl -s -f https://$(grep server_name /etc/nginx/sites-available/production-tracker | head -1 | awk '{print $2}' | tr -d ';')/health 2>/dev/null || echo "failed")

  if [ "$API_HEALTH" != "failed" ]; then
    echo -e "${GREEN}✓ API Responding${NC}"
    echo "  Response: $API_HEALTH"
  else
    echo -e "${RED}✗ API Not Responding${NC}"
  fi
  echo ""

  # 3. Database Status
  echo -e "${BLUE}━━━ Database Status ━━━${NC}"
  DB_STATUS=$(docker-compose -f docker-compose.prod.yml exec -T postgres pg_isready -U postgres 2>/dev/null || echo "failed")

  if echo "$DB_STATUS" | grep -q "accepting connections"; then
    echo -e "${GREEN}✓ Database Connected${NC}"

    # Database size
    DB_SIZE=$(docker-compose -f docker-compose.prod.yml exec -T postgres psql -U postgres -d production_tracker -t -c "SELECT pg_size_pretty(pg_database_size('production_tracker'));" 2>/dev/null | tr -d ' ')
    echo "  Size: $DB_SIZE"

    # Active connections
    CONNECTIONS=$(docker-compose -f docker-compose.prod.yml exec -T postgres psql -U postgres -t -c "SELECT count(*) FROM pg_stat_activity WHERE state != 'idle';" 2>/dev/null | tr -d ' ')
    echo "  Active Connections: $CONNECTIONS"
  else
    echo -e "${RED}✗ Database Not Connected${NC}"
  fi
  echo ""

  # 4. System Resources
  echo -e "${BLUE}━━━ System Resources ━━━${NC}"

  # CPU
  CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
  echo -e "  CPU Usage: ${CPU_USAGE}%"

  # Memory
  MEM_TOTAL=$(free -h | awk 'NR==2 {print $2}')
  MEM_USED=$(free -h | awk 'NR==2 {print $3}')
  MEM_PERCENT=$(free | awk 'NR==2 {printf "%.1f", $3/$2*100}')
  echo -e "  Memory: $MEM_USED / $MEM_TOTAL (${MEM_PERCENT}%)"

  # Disk
  DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
  DISK_AVAILABLE=$(df -h / | awk 'NR==2 {print $4}')
  echo -e "  Disk: $DISK_USAGE used, $DISK_AVAILABLE available"
  echo ""

  # 5. Docker Resource Usage
  echo -e "${BLUE}━━━ Container Resources ━━━${NC}"
  docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -n 5
  echo ""

  # 6. Recent Logs (errors)
  echo -e "${BLUE}━━━ Recent Errors (last 5) ━━━${NC}"
  ERRORS=$(docker-compose -f docker-compose.prod.yml logs --tail=100 2>/dev/null | grep -i "error\|exception\|failed" | tail -n 5)
  if [ -z "$ERRORS" ]; then
    echo -e "${GREEN}  No recent errors${NC}"
  else
    echo "$ERRORS"
  fi
  echo ""

  # 7. SSL Certificate
  echo -e "${BLUE}━━━ SSL Certificate ━━━${NC}"
  DOMAIN=$(grep server_name /etc/nginx/sites-available/production-tracker | head -1 | awk '{print $2}' | tr -d ';')
  if [ -f "/etc/letsencrypt/live/$DOMAIN/cert.pem" ]; then
    CERT_EXPIRY=$(openssl x509 -in "/etc/letsencrypt/live/$DOMAIN/cert.pem" -noout -enddate | cut -d= -f2)
    echo -e "${GREEN}✓ Certificate Active${NC}"
    echo "  Expires: $CERT_EXPIRY"
  else
    echo -e "${YELLOW}⚠ Certificate not found${NC}"
  fi
  echo ""

  # 8. Nginx Status
  echo -e "${BLUE}━━━ Nginx Status ━━━${NC}"
  if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx Running${NC}"

    # Connection stats
    CONNECTIONS=$(ss -tn | grep ':443 ' | wc -l)
    echo "  Active HTTPS Connections: $CONNECTIONS"
  else
    echo -e "${RED}✗ Nginx Not Running${NC}"
  fi
  echo ""

  # 9. Backup Status
  echo -e "${BLUE}━━━ Backup Status ━━━${NC}"
  LATEST_BACKUP=$(ls -1t /opt/production-tracker/backups/ 2>/dev/null | head -1)
  if [ -n "$LATEST_BACKUP" ]; then
    BACKUP_SIZE=$(du -sh "/opt/production-tracker/backups/$LATEST_BACKUP" 2>/dev/null | cut -f1)
    echo "  Latest: $LATEST_BACKUP ($BACKUP_SIZE)"
  else
    echo -e "${YELLOW}  No backups found${NC}"
  fi
  echo ""

  # 10. Quick Actions
  if [ "$WATCH_MODE" = false ]; then
    echo -e "${BLUE}━━━ Quick Actions ━━━${NC}"
    echo "  View logs:    docker-compose -f docker-compose.prod.yml logs -f"
    echo "  Restart:      docker-compose -f docker-compose.prod.yml restart"
    echo "  Backup:       ./deployment/backup.sh"
    echo "  Watch mode:   ./deployment/monitor.sh --watch"
    echo ""
  fi
}

# Main loop
if [ "$WATCH_MODE" = true ]; then
  while true; do
    show_status
    sleep 5
  done
else
  show_status
fi
