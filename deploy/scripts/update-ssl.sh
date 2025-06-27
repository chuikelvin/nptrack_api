#!/bin/bash

# NPTrack API SSL Certificate Update Script
# This script automates SSL certificate renewal using Let's Encrypt

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="${1:-}"
EMAIL="${2:-admin@example.com}"
CERTBOT_DIR="/etc/letsencrypt"
NGINX_SSL_DIR="/opt/nptrack-api/nginx/ssl"
BACKUP_DIR="/opt/backups/ssl"

# Logging
LOG_FILE="/opt/nptrack-api/logs/ssl-update.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_status() {
    local status=$1
    local message=$2
    
    case $status in
        "OK")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_status "ERROR" "This script must be run as root"
        exit 1
    fi
}

# Check if domain is provided
check_domain() {
    if [ -z "$DOMAIN" ]; then
        print_status "ERROR" "Domain name is required"
        echo "Usage: $0 <domain> [email]"
        echo "Example: $0 api.example.com admin@example.com"
        exit 1
    fi
}

# Install Certbot if not installed
install_certbot() {
    log "Checking Certbot installation..."
    
    if ! command -v certbot &> /dev/null; then
        print_status "INFO" "Installing Certbot..."
        apt update
        apt install -y certbot python3-certbot-nginx
        print_status "OK" "Certbot installed successfully"
    else
        print_status "OK" "Certbot is already installed"
    fi
}

# Create backup of current certificates
backup_certificates() {
    log "Creating backup of current certificates..."
    
    mkdir -p "$BACKUP_DIR"
    local backup_name="ssl_backup_$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$NGINX_SSL_DIR/cert.pem" ] || [ -f "$NGINX_SSL_DIR/key.pem" ]; then
        tar -czf "$BACKUP_DIR/$backup_name.tar.gz" -C "$NGINX_SSL_DIR" .
        print_status "OK" "Certificates backed up to $BACKUP_DIR/$backup_name.tar.gz"
    else
        print_status "INFO" "No existing certificates to backup"
    fi
}

# Stop Nginx temporarily for certificate renewal
stop_nginx() {
    log "Stopping Nginx for certificate renewal..."
    
    if docker ps --format "{{.Names}}" | grep -q "nptrack-nginx"; then
        docker stop nptrack-nginx
        print_status "OK" "Nginx container stopped"
    else
        print_status "INFO" "Nginx container not running"
    fi
}

# Start Nginx for domain validation
start_nginx_validation() {
    log "Starting Nginx for domain validation..."
    
    # Create temporary Nginx config for validation
    cat > /tmp/nginx-validation.conf << EOF
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name $DOMAIN;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 301 https://\$host\$request_uri;
        }
    }
}
EOF
    
    # Start Nginx with validation config
    docker run -d --name nginx-validation \
        -p 80:80 \
        -v /tmp/nginx-validation.conf:/etc/nginx/nginx.conf:ro \
        -v /var/www/certbot:/var/www/certbot \
        nginx:alpine
    
    print_status "OK" "Nginx validation container started"
}

# Obtain SSL certificate
obtain_certificate() {
    log "Obtaining SSL certificate for $DOMAIN..."
    
    # Create webroot directory
    mkdir -p /var/www/certbot
    
    # Stop validation container
    docker stop nginx-validation
    docker rm nginx-validation
    
    # Obtain certificate
    if certbot certonly --webroot \
        --webroot-path=/var/www/certbot \
        --email="$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --domains="$DOMAIN" \
        --non-interactive; then
        
        print_status "OK" "SSL certificate obtained successfully"
        return 0
    else
        print_status "ERROR" "Failed to obtain SSL certificate"
        return 1
    fi
}

# Copy certificates to Nginx directory
copy_certificates() {
    log "Copying certificates to Nginx directory..."
    
    local cert_path="$CERTBOT_DIR/live/$DOMAIN"
    
    if [ -f "$cert_path/fullchain.pem" ] && [ -f "$cert_path/privkey.pem" ]; then
        cp "$cert_path/fullchain.pem" "$NGINX_SSL_DIR/cert.pem"
        cp "$cert_path/privkey.pem" "$NGINX_SSL_DIR/key.pem"
        
        # Set proper permissions
        chmod 644 "$NGINX_SSL_DIR/cert.pem"
        chmod 600 "$NGINX_SSL_DIR/key.pem"
        
        print_status "OK" "Certificates copied to Nginx directory"
        return 0
    else
        print_status "ERROR" "Certificate files not found"
        return 1
    fi
}

# Restart Nginx with new certificates
restart_nginx() {
    log "Restarting Nginx with new certificates..."
    
    # Start the main Nginx container
    cd /opt/nptrack-api
    docker-compose -f docker-compose.prod.yml up -d nginx
    
    # Wait for Nginx to start
    sleep 10
    
    if docker ps --format "{{.Names}}" | grep -q "nptrack-nginx"; then
        print_status "OK" "Nginx restarted successfully"
        return 0
    else
        print_status "ERROR" "Failed to restart Nginx"
        return 1
    fi
}

# Test SSL certificate
test_certificate() {
    log "Testing SSL certificate..."
    
    if curl -f -s --max-time 30 "https://$DOMAIN" > /dev/null; then
        print_status "OK" "SSL certificate is working correctly"
        return 0
    else
        print_status "ERROR" "SSL certificate test failed"
        return 1
    fi
}

# Set up auto-renewal
setup_auto_renewal() {
    log "Setting up auto-renewal..."
    
    # Create renewal script
    cat > /opt/nptrack-api/scripts/renew-ssl.sh << 'EOF'
#!/bin/bash

# Auto-renewal script for SSL certificates
cd /opt/nptrack-api

# Stop Nginx
docker-compose -f docker-compose.prod.yml stop nginx

# Renew certificates
certbot renew --quiet

# Copy new certificates
cp /etc/letsencrypt/live/*/fullchain.pem nginx/ssl/cert.pem
cp /etc/letsencrypt/live/*/privkey.pem nginx/ssl/key.pem

# Set permissions
chmod 644 nginx/ssl/cert.pem
chmod 600 nginx/ssl/key.pem

# Restart Nginx
docker-compose -f docker-compose.prod.yml up -d nginx

# Test certificate
sleep 10
curl -f -s --max-time 30 "https://$(hostname)" > /dev/null && echo "SSL renewal successful" || echo "SSL renewal failed"
EOF
    
    chmod +x /opt/nptrack-api/scripts/renew-ssl.sh
    
    # Add to crontab (run twice daily)
    (crontab -l 2>/dev/null; echo "0 2,14 * * * /opt/nptrack-api/scripts/renew-ssl.sh >> /opt/nptrack-api/logs/ssl-renewal.log 2>&1") | crontab -
    
    print_status "OK" "Auto-renewal configured (runs at 2 AM and 2 PM daily)"
}

# Main function
main() {
    log "Starting SSL certificate update process..."
    echo "=================================="
    echo "SSL Certificate Update"
    echo "=================================="
    echo ""
    
    check_root
    check_domain
    install_certbot
    backup_certificates
    stop_nginx
    start_nginx_validation
    obtain_certificate
    copy_certificates
    restart_nginx
    test_certificate
    setup_auto_renewal
    
    echo ""
    echo "=================================="
    print_status "OK" "SSL certificate update completed successfully"
    echo "=================================="
    
    log "SSL certificate update completed successfully"
}

# Run main function
main "$@" 