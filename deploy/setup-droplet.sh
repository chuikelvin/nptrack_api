#!/bin/bash

# NPTrack API - Digital Ocean Droplet Setup Script
# This script sets up a fresh Ubuntu droplet for NPTrack API deployment

set -e

echo "🚀 Setting up NPTrack API on Digital Ocean Droplet..."

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install essential packages
echo "🔧 Installing essential packages..."
apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    htop \
    nano \
    ufw

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
usermod -aG docker $USER

# Install Docker Compose
echo "📋 Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
echo "📁 Creating application directory..."
mkdir -p /opt/nptrack-api
mkdir -p /opt/nptrack-api/logs
mkdir -p /opt/nptrack-api/nginx/ssl
mkdir -p /var/www/static

# Set up firewall
echo "🔥 Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 6446/tcp

# Create environment file
echo "⚙️ Creating environment configuration..."
cat > /opt/nptrack-api/.env << EOF
# Database Configuration
DATABASE_PASSWORD=YourStr0ng!Pass
DATABASE_NAME=NpTrack
DATABASE_SERVER_TIME_ZONE=EAT

# Docker Configuration
DOCKER_USERNAME=your-docker-username

# Application Configuration
SYSTEM_HOST=0.0.0.0
SYSTEM_PORT=6446
LOGS_PATH=logs
DATABASE_DRIVER=com.microsoft.sqlserver.jdbc.SQLServerDriver
EOF

# Create SSL certificates (self-signed for development)
echo "🔒 Creating SSL certificates..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /opt/nptrack-api/nginx/ssl/key.pem \
    -out /opt/nptrack-api/nginx/ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Set proper permissions
chmod 600 /opt/nptrack-api/nginx/ssl/key.pem
chmod 644 /opt/nptrack-api/nginx/ssl/cert.pem

# Create deployment script
echo "📜 Creating deployment script..."
cat > /opt/nptrack-api/deploy.sh << 'EOF'
#!/bin/bash

set -e

echo "🚀 Deploying NPTrack API..."

# Load environment variables
source .env

# Pull latest images
docker-compose -f docker-compose.prod.yml pull

# Stop existing containers
docker-compose -f docker-compose.prod.yml down

# Start services
docker-compose -f docker-compose.prod.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 30

# Health check
if curl -f http://localhost:6446/health; then
    echo "✅ Deployment successful! Application is healthy."
else
    echo "❌ Deployment failed! Application health check failed."
    docker-compose -f docker-compose.prod.yml logs
    exit 1
fi
EOF

chmod +x /opt/nptrack-api/deploy.sh

# Create monitoring script
echo "📊 Creating monitoring script..."
cat > /opt/nptrack-api/monitor.sh << 'EOF'
#!/bin/bash

echo "=== NPTrack API Status ==="
echo "Docker containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n=== Application Health ==="
if curl -s -f http://localhost:6446/health > /dev/null; then
    echo "✅ Application is healthy"
else
    echo "❌ Application health check failed"
fi

echo -e "\n=== System Resources ==="
echo "Memory usage:"
free -h

echo -e "\nDisk usage:"
df -h /

echo -e "\n=== Recent Logs ==="
docker-compose -f docker-compose.prod.yml logs --tail=20
EOF

chmod +x /opt/nptrack-api/monitor.sh

# Create backup script
echo "💾 Creating backup script..."
cat > /opt/nptrack-api/backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Creating backup: $DATE"

# Backup database
docker exec nptrack-mssql /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P $DATABASE_PASSWORD \
    -Q "BACKUP DATABASE [NpTrack] TO DISK = N'/var/opt/mssql/backup.bak' WITH FORMAT"

docker cp nptrack-mssql:/var/opt/mssql/backup.bak $BACKUP_DIR/nptrack_db_$DATE.bak

# Backup logs
tar -czf $BACKUP_DIR/nptrack_logs_$DATE.tar.gz -C /opt/nptrack-api logs/

echo "Backup completed: $BACKUP_DIR/nptrack_*_$DATE.*"
EOF

chmod +x /opt/nptrack-api/backup.sh

# Set up log rotation
echo "📝 Setting up log rotation..."
cat > /etc/logrotate.d/nptrack-api << EOF
/opt/nptrack-api/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        docker-compose -f /opt/nptrack-api/docker-compose.prod.yml restart nptrack-app
    endscript
}
EOF

# Create systemd service for auto-restart
echo "🔧 Creating systemd service..."
cat > /etc/systemd/system/nptrack-api.service << EOF
[Unit]
Description=NPTrack API
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/nptrack-api
ExecStart=/opt/nptrack-api/deploy.sh
ExecStop=/usr/local/bin/docker-compose -f /opt/nptrack-api/docker-compose.prod.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nptrack-api.service

echo "✅ Droplet setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Copy your application files to /opt/nptrack-api/"
echo "2. Update the .env file with your configuration"
echo "3. Run: cd /opt/nptrack-api && ./deploy.sh"
echo ""
echo "🔧 Useful commands:"
echo "- Monitor: ./monitor.sh"
echo "- Backup: ./backup.sh"
echo "- View logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "- Restart: systemctl restart nptrack-api" 