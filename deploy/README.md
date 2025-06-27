# NPTrack API - CI/CD Deployment to Digital Ocean

This guide explains how to set up continuous deployment of the NPTrack API to a Digital Ocean droplet using GitHub Actions.

## 🏗️ Architecture Overview

```
GitHub Repository
       ↓
GitHub Actions (CI/CD)
       ↓
Docker Hub Registry
       ↓
Digital Ocean Droplet
       ↓
Docker Containers (NPTrack API + MSSQL + Nginx)
```

## 📋 Prerequisites

### 1. Digital Ocean Account
- Create a Digital Ocean account
- Create a droplet (recommended: Ubuntu 22.04, 2GB RAM, 1 CPU)
- Note down the droplet's IP address

### 2. Docker Hub Account
- Create a Docker Hub account
- Note down your username

### 3. GitHub Repository
- Push your code to a GitHub repository
- Ensure you have admin access to set up secrets

## 🔧 Setup Instructions

### Step 1: Prepare Your Droplet

1. **Connect to your droplet:**
   ```bash
   ssh root@your-droplet-ip
   ```

2. **Run the setup script:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/your-username/your-repo/main/deploy/setup-droplet.sh | bash
   ```

3. **Copy application files:**
   ```bash
   # From your local machine
   scp -r . root@your-droplet-ip:/opt/nptrack-api/
   ```

### Step 2: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DOCKER_USERNAME` | Your Docker Hub username | `johndoe` |
| `DOCKER_PASSWORD` | Your Docker Hub password/token | `your-password` |
| `DROPLET_HOST` | Your droplet's IP address | `123.456.789.012` |
| `DROPLET_USERNAME` | SSH username (usually `root`) | `root` |
| `DROPLET_SSH_KEY` | Your private SSH key | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `DROPLET_PORT` | SSH port (usually 22) | `22` |

### Step 3: Configure Environment Variables

1. **On your droplet, edit the environment file:**
   ```bash
   nano /opt/nptrack-api/.env
   ```

2. **Update with your values:**
   ```bash
   # Database Configuration
   DATABASE_PASSWORD=YourSecurePassword123!
   DATABASE_NAME=NpTrack
   DATABASE_SERVER_TIME_ZONE=EAT

   # Docker Configuration
   DOCKER_USERNAME=your-docker-username

   # Application Configuration
   SYSTEM_HOST=0.0.0.0
   SYSTEM_PORT=6446
   LOGS_PATH=logs
   DATABASE_DRIVER=com.microsoft.sqlserver.jdbc.SQLServerDriver
   ```

### Step 4: Initial Deployment

1. **On your droplet:**
   ```bash
   cd /opt/nptrack-api
   ./deploy.sh
   ```

2. **Verify deployment:**
   ```bash
   ./monitor.sh
   ```

## 🚀 CI/CD Workflow

### How It Works

1. **Push to main/master branch** triggers the workflow
2. **GitHub Actions** builds and tests the Docker image
3. **Docker image** is pushed to Docker Hub
4. **SSH connection** to droplet pulls the latest image
5. **Docker Compose** restarts services with new image
6. **Health check** verifies successful deployment

### Workflow Steps

1. **Test Job:**
   - Builds Docker image
   - Runs basic tests
   - Ensures image is valid

2. **Deploy Job:**
   - Pushes image to Docker Hub
   - Connects to droplet via SSH
   - Updates and restarts services
   - Performs health check

## 🔍 Monitoring and Maintenance

### Health Monitoring

```bash
# Check application status
./monitor.sh

# View real-time logs
docker-compose -f docker-compose.prod.yml logs -f

# Check system resources
htop
df -h
free -h
```

### Backup and Recovery

```bash
# Create backup
./backup.sh

# List backups
ls -la /opt/backups/

# Restore from backup (manual process)
docker exec -it nptrack-mssql /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P $DATABASE_PASSWORD \
    -Q "RESTORE DATABASE [NpTrack] FROM DISK = N'/var/opt/mssql/backup.bak'"
```

### Troubleshooting

#### Common Issues

1. **Application won't start:**
   ```bash
   docker-compose -f docker-compose.prod.yml logs nptrack-app
   ```

2. **Database connection issues:**
   ```bash
   docker-compose -f docker-compose.prod.yml logs mssql-server
   ```

3. **Port conflicts:**
   ```bash
   netstat -tulpn | grep :6446
   ```

4. **SSL certificate issues:**
   ```bash
   openssl x509 -in /opt/nptrack-api/nginx/ssl/cert.pem -text -noout
   ```

#### Service Management

```bash
# Restart all services
systemctl restart nptrack-api

# Stop services
docker-compose -f docker-compose.prod.yml down

# Start services
docker-compose -f docker-compose.prod.yml up -d

# View service status
systemctl status nptrack-api
```

## 🔒 Security Considerations

### SSL/TLS Configuration

For production, replace self-signed certificates with Let's Encrypt:

```bash
# Install Certbot
apt install certbot python3-certbot-nginx

# Get certificate
certbot --nginx -d your-domain.com

# Auto-renewal
crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Firewall Rules

The setup script configures UFW with:
- SSH (port 22)
- HTTP (port 80)
- HTTPS (port 443)
- Application (port 6446)

### Environment Variables

- Never commit sensitive data to version control
- Use strong passwords for database
- Rotate credentials regularly
- Use Docker secrets for production

## 📊 Performance Optimization

### Resource Limits

The production compose file includes:
- MSSQL: 2GB memory limit
- Application: 1GB memory limit
- Nginx: Minimal resource usage

### Monitoring

Consider adding:
- Prometheus for metrics
- Grafana for visualization
- AlertManager for notifications

## 🔄 Rollback Strategy

### Manual Rollback

```bash
# List available images
docker images | grep nptrack-api

# Rollback to previous version
docker tag your-username/nptrack-api:previous-commit your-username/nptrack-api:latest
docker-compose -f docker-compose.prod.yml up -d
```

### Automated Rollback

The workflow includes health checks that can trigger rollback:
- If health check fails, deployment is marked as failed
- Previous version remains running
- Manual intervention required for rollback

## 📞 Support

For issues with:
- **CI/CD Pipeline:** Check GitHub Actions logs
- **Droplet Setup:** Review setup script output
- **Application:** Check Docker logs
- **Database:** Connect directly to MSSQL container

## 🎯 Next Steps

1. **Set up monitoring** with Prometheus/Grafana
2. **Configure SSL certificates** with Let's Encrypt
3. **Set up automated backups** to cloud storage
4. **Implement blue-green deployment** for zero downtime
5. **Add load balancing** for high availability 