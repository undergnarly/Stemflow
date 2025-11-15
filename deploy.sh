#!/bin/bash

# ============================================================================
# Production Tracker - Automated Deployment Script
# ============================================================================
#
# This script automates the deployment of Production Tracker backend
# on a production server.
#
# Usage: ./deploy.sh
#
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should NOT be run as root"
   echo "Please run as a regular user with sudo privileges"
   exit 1
fi

# ============================================================================
# WELCOME
# ============================================================================

clear
print_header "Production Tracker - Automated Deployment"
echo "This script will deploy the Production Tracker backend to production."
echo ""
echo "What this script will do:"
echo "  1. Check system requirements"
echo "  2. Install dependencies (Docker, Nginx, etc.)"
echo "  3. Configure environment variables"
echo "  4. Set up SSL certificate"
echo "  5. Deploy services with Docker Compose"
echo "  6. Configure Nginx reverse proxy"
echo "  7. Run database migrations"
echo "  8. Create systemd service"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# ============================================================================
# CONFIGURATION
# ============================================================================

print_header "Configuration"

# Domain name
read -p "Enter your domain name (e.g., api.yourdomain.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    print_error "Domain name is required"
    exit 1
fi
print_success "Domain: $DOMAIN"

# Email for SSL
read -p "Enter your email for SSL certificate: " EMAIL
if [ -z "$EMAIL" ]; then
    print_error "Email is required"
    exit 1
fi
print_success "Email: $EMAIL"

# Generate secrets
print_info "Generating secure secrets..."
JWT_SECRET=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -base64 32)
print_success "Secrets generated"

# Anthropic API Key
read -p "Enter your Anthropic API key: " ANTHROPIC_KEY
if [ -z "$ANTHROPIC_KEY" ]; then
    print_warning "No API key provided - AI features will not work"
fi

# ============================================================================
# SYSTEM REQUIREMENTS CHECK
# ============================================================================

print_header "Checking System Requirements"

# Check OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    print_success "OS: $PRETTY_NAME"
else
    print_error "Unable to detect OS"
    exit 1
fi

# Check if running Ubuntu/Debian
if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
    print_warning "This script is optimized for Ubuntu/Debian"
    print_warning "Other distributions may require manual installation"
fi

# Check disk space
AVAILABLE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 10 ]; then
    print_error "Insufficient disk space. Need at least 10GB, have ${AVAILABLE_SPACE}GB"
    exit 1
fi
print_success "Disk space: ${AVAILABLE_SPACE}GB available"

# Check RAM
TOTAL_RAM=$(free -g | awk 'NR==2 {print $2}')
if [ "$TOTAL_RAM" -lt 2 ]; then
    print_warning "Low RAM detected (${TOTAL_RAM}GB). Recommended: 4GB+"
else
    print_success "RAM: ${TOTAL_RAM}GB"
fi

# ============================================================================
# INSTALL DEPENDENCIES
# ============================================================================

print_header "Installing Dependencies"

# Update system
print_info "Updating system packages..."
sudo apt update
sudo apt upgrade -y
print_success "System updated"

# Install Docker
if ! command -v docker &> /dev/null; then
    print_info "Installing Docker..."
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker $USER
    print_success "Docker installed"
else
    print_success "Docker already installed"
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_info "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed"
else
    print_success "Docker Compose already installed"
fi

# Install Nginx
if ! command -v nginx &> /dev/null; then
    print_info "Installing Nginx..."
    sudo apt install -y nginx
    sudo systemctl enable nginx
    print_success "Nginx installed"
else
    print_success "Nginx already installed"
fi

# Install Certbot
if ! command -v certbot &> /dev/null; then
    print_info "Installing Certbot..."
    sudo apt install -y certbot python3-certbot-nginx
    print_success "Certbot installed"
else
    print_success "Certbot already installed"
fi

# Install other utilities
sudo apt install -y git curl wget htop

# ============================================================================
# CONFIGURE ENVIRONMENT
# ============================================================================

print_header "Configuring Environment"

# Create .env file
print_info "Creating backend/.env file..."
cat > backend/.env << EOF
# Database
DATABASE_URL=postgresql://postgres:${DB_PASSWORD}@postgres:5432/production_tracker

# JWT
JWT_SECRET=${JWT_SECRET}
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=7

# Anthropic API
ANTHROPIC_API_KEY=${ANTHROPIC_KEY}
ANTHROPIC_MODEL=claude-sonnet-4-20250514

# File Upload
UPLOAD_DIR=/app/uploads
MAX_FILE_SIZE_MB=100

# CORS
CORS_ORIGINS=https://${DOMAIN},https://www.${DOMAIN}

# Application
LOG_LEVEL=INFO
ENVIRONMENT=production
WORKERS=4
EOF

print_success "Environment file created"

# Create uploads directory
mkdir -p backend/uploads
mkdir -p backend/logs
print_success "Upload directories created"

# ============================================================================
# CONFIGURE NGINX
# ============================================================================

print_header "Configuring Nginx"

print_info "Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/production-tracker > /dev/null << EOF
# Production Tracker Nginx Configuration

# Rate limiting
limit_req_zone \$binary_remote_addr zone=api_limit:10m rate=10r/s;

# Upstream backend
upstream backend {
    server 127.0.0.1:8000;
}

# HTTP server - redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${DOMAIN};

    # SSL certificates (will be configured by Certbot)
    # ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling on;
    ssl_stapling_verify on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/production-tracker-access.log;
    error_log /var/log/nginx/production-tracker-error.log;

    # Max upload size
    client_max_body_size 100M;

    # Proxy settings
    location / {
        limit_req zone=api_limit burst=20 nodelay;

        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket support
    location /ws {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket timeouts
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/production-tracker /etc/nginx/sites-enabled/

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
if sudo nginx -t; then
    print_success "Nginx configuration valid"
    sudo systemctl restart nginx
    print_success "Nginx restarted"
else
    print_error "Nginx configuration invalid"
    exit 1
fi

# ============================================================================
# OBTAIN SSL CERTIFICATE
# ============================================================================

print_header "Obtaining SSL Certificate"

print_info "Requesting SSL certificate from Let's Encrypt..."
sudo certbot --nginx -d ${DOMAIN} --email ${EMAIL} --agree-tos --no-eff-email --non-interactive

if [ $? -eq 0 ]; then
    print_success "SSL certificate obtained"
else
    print_error "Failed to obtain SSL certificate"
    print_info "You may need to manually run: sudo certbot --nginx -d ${DOMAIN}"
fi

# ============================================================================
# DEPLOY WITH DOCKER COMPOSE
# ============================================================================

print_header "Deploying Services"

# Build and start services
print_info "Building Docker images..."
docker-compose -f docker-compose.prod.yml build

print_info "Starting services..."
docker-compose -f docker-compose.prod.yml up -d

# Wait for services to be ready
print_info "Waiting for services to start..."
sleep 10

# Check if services are running
if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    print_success "Services are running"
else
    print_error "Services failed to start"
    docker-compose -f docker-compose.prod.yml logs
    exit 1
fi

# ============================================================================
# RUN DATABASE MIGRATIONS
# ============================================================================

print_header "Running Database Migrations"

print_info "Generating Prisma client..."
docker-compose -f docker-compose.prod.yml exec -T backend prisma generate

print_info "Running migrations..."
docker-compose -f docker-compose.prod.yml exec -T backend prisma migrate deploy

print_success "Database migrations completed"

# ============================================================================
# CREATE SYSTEMD SERVICE
# ============================================================================

print_header "Creating Systemd Service"

sudo tee /etc/systemd/system/production-tracker.service > /dev/null << EOF
[Unit]
Description=Production Tracker Backend
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/bin/docker-compose -f docker-compose.prod.yml down
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable production-tracker
print_success "Systemd service created and enabled"

# ============================================================================
# SETUP BACKUPS
# ============================================================================

print_header "Setting Up Backups"

# Create backup script
mkdir -p backups
cat > backup-db.sh << 'BACKUP_SCRIPT'
#!/bin/bash
BACKUP_DIR="$(dirname "$0")/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

docker-compose -f docker-compose.prod.yml exec -T postgres \
  pg_dump -U postgres production_tracker | \
  gzip > $BACKUP_DIR/backup_$DATE.sql.gz

# Keep only last 7 days
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/backup_$DATE.sql.gz"
BACKUP_SCRIPT

chmod +x backup-db.sh

# Add to crontab
(crontab -l 2>/dev/null | grep -v backup-db.sh; echo "0 2 * * * $(pwd)/backup-db.sh") | crontab -
print_success "Daily backups configured (2 AM)"

# ============================================================================
# VERIFY DEPLOYMENT
# ============================================================================

print_header "Verifying Deployment"

sleep 5

# Test health endpoint
print_info "Testing API health endpoint..."
if curl -s -f https://${DOMAIN}/health > /dev/null; then
    print_success "API is responding"
else
    print_warning "API health check failed - may take a moment to start"
fi

# ============================================================================
# COMPLETION
# ============================================================================

print_header "Deployment Complete!"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║  🎉  Production Tracker Successfully Deployed! 🎉           ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✓ API URL:${NC} https://${DOMAIN}"
echo -e "${GREEN}✓ API Docs:${NC} https://${DOMAIN}/docs"
echo -e "${GREEN}✓ Health Check:${NC} https://${DOMAIN}/health"
echo ""
echo -e "${BLUE}Important Information:${NC}"
echo "  • JWT Secret: [generated and saved in backend/.env]"
echo "  • Database Password: [generated and saved in backend/.env]"
echo "  • SSL Certificate: Auto-renews via systemd timer"
echo "  • Backups: Daily at 2 AM in ./backups/"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  • View logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "  • Restart: docker-compose -f docker-compose.prod.yml restart"
echo "  • Stop: docker-compose -f docker-compose.prod.yml down"
echo "  • Status: docker-compose -f docker-compose.prod.yml ps"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Test the API at https://${DOMAIN}/docs"
echo "  2. Create your first user account"
echo "  3. Configure the frontend to point to this API"
echo "  4. Install the Max4Live device and connect"
echo ""
echo -e "${YELLOW}⚠ Important:${NC} Save the .env file - it contains secrets!"
echo ""
print_success "Deployment script completed successfully"
