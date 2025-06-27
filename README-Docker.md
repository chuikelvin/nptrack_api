# NPTrack API - Docker Setup

This guide explains how to dockerize and run the NPTrack API application with MSSQL Server 2019.

## Prerequisites

- Docker Desktop installed and running
- Docker Compose (usually included with Docker Desktop)
- At least 4GB of available RAM for MSSQL Server

## Project Structure

```
nptrack api/
├── NPTrack.jar                 # Your Java application
├── appconfig/                  # Configuration files
│   ├── configurations.properties          # Local development config
│   └── configurations-docker.properties   # Docker template with env vars
├── sql/                        # Database initialization scripts
│   └── init-database.sql
├── Dockerfile                  # Java application container
├── docker-compose.yml          # Multi-container orchestration
├── .dockerignore              # Files to exclude from build
└── README-Docker.md           # This file
```

## Quick Start

1. **Build and run the entire stack:**
   ```bash
   docker-compose up --build
   ```

2. **Run in detached mode:**
   ```bash
   docker-compose up -d --build
   ```

3. **Stop the services:**
   ```bash
   docker-compose down
   ```

## Services

### 1. MSSQL Server 2019
- **Container Name:** `nptrack-mssql`
- **Port:** 15435 (mapped to host) → 1433 (container)
- **Credentials:**
  - Username: `sa`
  - Password: `YourStr0ng!Pass`
  - Database: `NpTrack`

### 2. NPTrack Java Application
- **Container Name:** `nptrack-app`
- **Port:** 6446 (mapped to host)
- **Health Check:** Available at `http://localhost:6446/health`

## Configuration Management

### Environment Variables (Docker Compose)

All database and application configuration is managed through environment variables in `docker-compose.yml`:

```yaml
environment:
  - DATABASE_IP=mssql-server          # Docker service name
  - DATABASE_PORT=1433                # MSSQL port (internal)
  - DATABASE_NAME=NpTrack             # Database name
  - DATABASE_USER=sa                  # Database user
  - DATABASE_PASSWORD=YourStr0ng!Pass # Database password
  - SYSTEM_HOST=0.0.0.0              # Application host
  - SYSTEM_PORT=6446                  # Application port
  - LOGS_PATH=logs                    # Logs directory
  - DATABASE_DRIVER=com.microsoft.sqlserver.jdbc.SQLServerDriver
  - DATABASE_SERVER_TIME_ZONE=EAT
```

### Configuration File Processing

The application uses a template-based configuration system:

1. **`configurations-docker.properties`** - Template with environment variable placeholders
2. **`configurations.properties`** - Generated at runtime with actual values
3. **Environment variable substitution** - Happens automatically when the container starts

This ensures:
- ✅ **Consistent configuration** across all environments
- ✅ **No hardcoded values** in the application
- ✅ **Easy deployment** to different environments
- ✅ **Secure credential management**

## Database Setup

The `sql/init-database.sql` file contains a robust database initialization script that:

- ✅ **Works with any new MSSQL instance**
- ✅ **Handles existing databases gracefully**
- ✅ **Creates all required tables**
- ✅ **Inserts initial data**
- ✅ **Prevents conflicts** with existing objects

### Key Features:

1. **Idempotent Operations** - Can be run multiple times safely
2. **Error Handling** - Checks for existing objects before creating
3. **Flexible File Paths** - Uses default MSSQL file locations
4. **Database Property Management** - Only sets properties for new databases

## Troubleshooting

### 1. MSSQL Server Issues

**Check if MSSQL is running:**
```bash
docker-compose logs mssql-server
```

**Connect to database manually:**
```bash
docker exec -it nptrack-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P YourStr0ng!Pass -C
```

**Connect from host (if needed):**
```bash
# Using sqlcmd or any SQL client
sqlcmd -S localhost,15435 -U sa -P YourStr0ng!Pass -C
```

### 2. Application Issues

**Check application logs:**
```bash
docker-compose logs nptrack-app
```

**Check application health:**
```bash
curl http://localhost:6446/health
```

**Verify configuration:**
```bash
docker exec -it nptrack-app cat /app/appconfig/configurations.properties
```

### 3. Port Conflicts

If ports 15435 or 6446 are already in use:

1. **Stop existing services:**
   ```bash
   docker-compose down
   ```

2. **Modify ports in docker-compose.yml:**
   ```yaml
   ports:
     - "15436:1433"  # Change host port
   ```

### 4. Memory Issues

MSSQL Server requires at least 2GB RAM. If you encounter memory issues:

1. **Increase Docker memory limit** in Docker Desktop settings
2. **Add memory limits** to docker-compose.yml:
   ```yaml
   services:
     mssql-server:
       deploy:
         resources:
           limits:
             memory: 2G
   ```

## Development Workflow

### 1. Making Changes to SQL Script

1. Edit `sql/init-database.sql`
2. Rebuild and restart:
   ```bash
   docker-compose down -v  # Remove volumes to reset database
   docker-compose up --build
   ```

### 2. Updating Application Configuration

1. Edit `appconfig/configurations-docker.properties` (for Docker)
2. Edit `appconfig/configurations.properties` (for local development)
3. Restart the application:
   ```bash
   docker-compose restart nptrack-app
   ```

### 3. Viewing Logs

**All services:**
```bash
docker-compose logs -f
```

**Specific service:**
```bash
docker-compose logs -f nptrack-app
```

## Production Considerations

1. **Security:**
   - Change default passwords
   - Use secrets management
   - Enable SSL/TLS

2. **Performance:**
   - Add resource limits
   - Configure connection pooling
   - Optimize database queries

3. **Monitoring:**
   - Add logging aggregation
   - Set up health checks
   - Configure alerts

## Cleanup

**Remove everything (including data):**
```bash
docker-compose down -v --rmi all
```

**Remove only containers:**
```bash
docker-compose down
```

## Support

If you encounter issues:

1. Check the logs: `docker-compose logs`
2. Verify Docker Desktop is running
3. Ensure sufficient system resources
4. Check port availability
5. Verify environment variables are set correctly

# NPTrack API - Docker Deployment Guide

This guide covers deploying NPTrack API using Docker without relying on Docker Hub.

## Deployment Options

### Option 1: Digital Ocean Container Registry (Recommended)

#### Prerequisites
1. Digital Ocean account with Container Registry enabled
2. GitHub repository with Actions enabled
3. Digital Ocean droplet set up

#### Setup Steps

1. **Create DO Container Registry:**
   ```bash
   # Create registry via doctl CLI
   doctl registry create your-registry-name --region nyc3
   ```

2. **Configure GitHub Secrets:**
   ```
   DIGITALOCEAN_ACCESS_TOKEN  # Your DO API token
   DROPLET_HOST              # Your droplet IP
   DROPLET_USERNAME          # SSH username (usually root)
   DROPLET_SSH_KEY           # Private SSH key for droplet access
   DROPLET_PORT              # SSH port (usually 22)
   ```

3. **Update Registry Name:**
   - Edit `.github/workflows/deploy.yml`
   - Replace `your-do-registry` with your actual registry name

4. **Deploy:**
   ```bash
   git push origin main
   ```

#### Benefits:
- ✅ No Docker Hub dependency
- ✅ Private registry
- ✅ Fast deployment
- ✅ Integrated with DO ecosystem

### Option 2: Direct Image Transfer (No Registry)

Use the `.github/workflows/deploy-direct.yml` workflow for deployments without any registry.

#### How it works:
1. Builds Docker image in GitHub Actions
2. Saves image as compressed tar file
3. Transfers file to droplet via SCP
4. Loads image directly on droplet
5. Starts services

#### Benefits:
- ✅ No registry required
- ✅ Complete control over images
- ✅ Works with any server

#### Drawbacks:
- ⚠️ Slower deployment (image transfer)
- ⚠️ Higher bandwidth usage

## Local Development

1. **Build the image:**
   ```bash
   docker build -t nptrack-api:latest .
   ```

2. **Run locally:**
   ```bash
   docker-compose up -d
   ```

3. **Access application:**
   - API: http://localhost:6446
   - Health check: http://localhost:6446/health

## Production Deployment

### Using DO Registry
```bash
# Copy environment template
cp deploy/env.example deploy/.env

# Edit with your values
nano deploy/.env

# Deploy via GitHub Actions
git push origin main
```

### Using Direct Transfer
```bash
# Enable the direct deployment workflow
mv .github/workflows/deploy-direct.yml .github/workflows/deploy.yml
mv .github/workflows/deploy.yml .github/workflows/deploy-registry.yml.disabled

# Deploy
git push origin main
```

## Monitoring

### Health Check
```bash
curl http://your-droplet-ip:6446/health
```

### View Logs
```bash
ssh root@your-droplet-ip
cd /opt/nptrack-api
docker-compose logs -f nptrack-app
```

### Monitor Resources
```bash
./monitor.sh
```

## Troubleshooting

### Common Issues

1. **Registry Login Failed:**
   ```bash
   # On droplet, test DO registry login
   doctl registry login
   ```

2. **Image Pull Failed:**
   ```bash
   # Check if image exists in registry
   doctl registry repository list-tags your-registry/nptrack-api
   ```

3. **Application Won't Start:**
   ```bash
   # Check application logs
   docker-compose logs nptrack-app
   
   # Check database connection
   docker-compose logs mssql-server
   ```

## Security Notes

- Never commit secrets to version control
- Use GitHub Secrets for sensitive data
- Regularly rotate access tokens
- Keep droplet OS updated
- Use SSL/TLS in production

## Cost Optimization

- DO Registry: Free tier includes 500MB storage
- Image layers are cached for faster builds
- Clean up old images regularly

## Migration from Docker Hub

If migrating from Docker Hub:

1. Update image references in `docker-compose.prod.yml`
2. Remove Docker Hub secrets from GitHub
3. Add DO secrets to GitHub
4. Update workflow file
5. Test deployment

## Support

For issues related to:
- Digital Ocean services: Contact DO support
- GitHub Actions: Check GitHub documentation
- Application issues: Check application logs 