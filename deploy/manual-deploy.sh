#!/bin/bash

# NPTrack API - Manual Direct Deployment Script
# Run this script on your Digital Ocean droplet for manual deployments

set -e

echo "🚀 NPTrack API - Manual Deployment"
echo "=================================="

# Configuration
APP_DIR="/opt/nptrack-api"
IMAGE_NAME="nptrack-api:latest"

# Check if we're in the right directory
if [ ! -f "docker-compose.prod.yml" ]; then
    echo "❌ Error: docker-compose.prod.yml not found in current directory"
    echo "Please run this script from the deploy directory or copy the necessary files"
    exit 1
fi

# Create application directory structure
echo "📁 Setting up application directory..."
sudo mkdir -p $APP_DIR/{logs,nginx/ssl}

# Copy files to application directory
echo "📋 Copying configuration files..."
sudo cp docker-compose.prod.yml $APP_DIR/docker-compose.yml
sudo cp -r nginx $APP_DIR/ 2>/dev/null || echo "nginx directory not found, skipping..."
sudo cp -r ../sql $APP_DIR/ 2>/dev/null || echo "sql directory not found, skipping..."
sudo cp -r ../appconfig $APP_DIR/ 2>/dev/null || echo "appconfig directory not found, skipping..."

# Set up environment file
echo "⚙️ Setting up environment..."
if [ ! -f "$APP_DIR/.env" ]; then
    sudo tee $APP_DIR/.env > /dev/null << EOF
# Database Configuration
DATABASE_PASSWORD=YourStr0ng!Pass
DATABASE_NAME=NpTrack
DATABASE_SERVER_TIME_ZONE=EAT

# Application Configuration
SYSTEM_HOST=0.0.0.0
SYSTEM_PORT=6446
LOGS_PATH=logs
DATABASE_DRIVER=com.microsoft.sqlserver.jdbc.SQLServerDriver

# Local deployment
REGISTRY_NAME=local
EOF
    echo "✅ Created .env file with default values"
    echo "⚠️  Please edit $APP_DIR/.env to update passwords and configuration"
else
    echo "✅ .env file already exists"
fi

# Check if Docker image exists locally
echo "🐳 Checking Docker image..."
if ! docker image inspect $IMAGE_NAME > /dev/null 2>&1; then
    echo "❌ Docker image $IMAGE_NAME not found locally"
    echo ""
    echo "Please build or load the image first:"
    echo "  Option 1 - Build from source:"
    echo "    docker build -t $IMAGE_NAME /path/to/source"
    echo ""
    echo "  Option 2 - Load from tar file:"
    echo "    docker load < nptrack-api.tar.gz"
    echo ""
    echo "  Option 3 - Pull from registry:"
    echo "    docker pull your-registry/$IMAGE_NAME"
    echo "    docker tag your-registry/$IMAGE_NAME $IMAGE_NAME"
    exit 1
fi

echo "✅ Docker image found: $IMAGE_NAME"

# Change to application directory
cd $APP_DIR

# Update docker-compose to use local image
echo "📝 Updating docker-compose configuration..."
sudo sed -i "s|image: registry\.digitalocean\.com/.*nptrack-api.*|image: $IMAGE_NAME|g" docker-compose.yml
sudo sed -i "s|image: .*nptrack-api.*|image: $IMAGE_NAME|g" docker-compose.yml

# Stop existing services
echo "🛑 Stopping existing services..."
sudo docker-compose down || true

# Start services
echo "🚀 Starting services..."
sudo docker-compose up -d

# Wait and perform health check
echo "🏥 Performing health check..."
sleep 30

for i in {1..10}; do
    if curl -f http://localhost:6446/health 2>/dev/null; then
        echo "✅ Application is healthy!"
        echo ""
        echo "🎉 Deployment completed successfully!"
        echo ""
        echo "Access your application:"
        echo "  - API: http://$(hostname -I | awk '{print $1}'):6446"
        echo "  - Health: http://$(hostname -I | awk '{print $1}'):6446/health"
        echo ""
        echo "Useful commands:"
        echo "  - View logs: sudo docker-compose logs -f"
        echo "  - Restart: sudo docker-compose restart"
        echo "  - Stop: sudo docker-compose down"
        exit 0
    fi
    echo "⏳ Waiting for application... (attempt $i/10)"
    sleep 10
done

# Health check failed
echo "❌ Health check failed after 10 attempts"
echo ""
echo "📋 Container status:"
sudo docker-compose ps
echo ""
echo "📋 Application logs:"
sudo docker-compose logs nptrack-app
echo ""
echo "📋 Database logs:"
sudo docker-compose logs mssql-server

exit 1 