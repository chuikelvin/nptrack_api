#!/bin/bash

# NPTrack API Health Check Script
# This script performs comprehensive health checks on the application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_URL="http://localhost:6446"
HEALTH_ENDPOINT="$APP_URL/health"
TIMEOUT=30
RETRIES=3

# Logging
LOG_FILE="/opt/nptrack-api/logs/health-check.log"
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

# Check if Docker is running
check_docker() {
    log "Checking Docker service..."
    if systemctl is-active --quiet docker; then
        print_status "OK" "Docker service is running"
        return 0
    else
        print_status "ERROR" "Docker service is not running"
        return 1
    fi
}

# Check if containers are running
check_containers() {
    log "Checking container status..."
    local containers=("nptrack-app" "nptrack-mssql" "nptrack-nginx")
    local all_running=true
    
    for container in "${containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^$container$"; then
            local status=$(docker ps --format "{{.Status}}" --filter "name=$container")
            print_status "OK" "Container $container is running: $status"
        else
            print_status "ERROR" "Container $container is not running"
            all_running=false
        fi
    done
    
    if [ "$all_running" = true ]; then
        return 0
    else
        return 1
    fi
}

# Check application health endpoint
check_application_health() {
    log "Checking application health endpoint..."
    
    for i in $(seq 1 $RETRIES); do
        if curl -f -s --max-time $TIMEOUT "$HEALTH_ENDPOINT" > /dev/null; then
            print_status "OK" "Application health check passed"
            return 0
        else
            if [ $i -eq $RETRIES ]; then
                print_status "ERROR" "Application health check failed after $RETRIES attempts"
                return 1
            else
                print_status "WARNING" "Health check attempt $i failed, retrying..."
                sleep 5
            fi
        fi
    done
}

# Check database connectivity
check_database() {
    log "Checking database connectivity..."
    
    if docker exec nptrack-mssql /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$DATABASE_PASSWORD" \
        -C -Q "SELECT 1" > /dev/null 2>&1; then
        print_status "OK" "Database connection successful"
        return 0
    else
        print_status "ERROR" "Database connection failed"
        return 1
    fi
}

# Check system resources
check_system_resources() {
    log "Checking system resources..."
    
    # Memory usage
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    if (( $(echo "$mem_usage < 80" | bc -l) )); then
        print_status "OK" "Memory usage: ${mem_usage}%"
    else
        print_status "WARNING" "Memory usage: ${mem_usage}% (high)"
    fi
    
    # Disk usage
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 80 ]; then
        print_status "OK" "Disk usage: ${disk_usage}%"
    else
        print_status "WARNING" "Disk usage: ${disk_usage}% (high)"
    fi
    
    # CPU load
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    print_status "INFO" "CPU load: $cpu_load"
}

# Check network connectivity
check_network() {
    log "Checking network connectivity..."
    
    # Check if ports are listening
    local ports=(80 443 6446)
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            print_status "OK" "Port $port is listening"
        else
            print_status "ERROR" "Port $port is not listening"
        fi
    done
    
    # Check external connectivity
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        print_status "OK" "External connectivity is working"
    else
        print_status "WARNING" "External connectivity issues detected"
    fi
}

# Check logs for errors
check_logs() {
    log "Checking application logs for errors..."
    
    local error_count=$(docker-compose -f /opt/nptrack-api/docker-compose.prod.yml logs --tail=100 | grep -i "error\|exception\|failed" | wc -l)
    
    if [ "$error_count" -eq 0 ]; then
        print_status "OK" "No recent errors found in logs"
    else
        print_status "WARNING" "Found $error_count recent errors in logs"
        docker-compose -f /opt/nptrack-api/docker-compose.prod.yml logs --tail=20 | grep -i "error\|exception\|failed"
    fi
}

# Check SSL certificate
check_ssl() {
    log "Checking SSL certificate..."
    
    local cert_file="/opt/nptrack-api/nginx/ssl/cert.pem"
    if [ -f "$cert_file" ]; then
        local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry_date" +%s)
        local current_epoch=$(date +%s)
        local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
        
        if [ "$days_until_expiry" -gt 30 ]; then
            print_status "OK" "SSL certificate expires in $days_until_expiry days"
        else
            print_status "WARNING" "SSL certificate expires in $days_until_expiry days"
        fi
    else
        print_status "ERROR" "SSL certificate file not found"
    fi
}

# Main health check function
main() {
    log "Starting comprehensive health check..."
    echo "=================================="
    echo "NPTrack API Health Check Report"
    echo "=================================="
    echo ""
    
    local exit_code=0
    
    # Load environment variables
    if [ -f "/opt/nptrack-api/.env" ]; then
        source "/opt/nptrack-api/.env"
    else
        print_status "ERROR" "Environment file not found"
        exit_code=1
    fi
    
    # Run all checks
    check_docker || exit_code=1
    echo ""
    
    check_containers || exit_code=1
    echo ""
    
    check_application_health || exit_code=1
    echo ""
    
    check_database || exit_code=1
    echo ""
    
    check_system_resources
    echo ""
    
    check_network
    echo ""
    
    check_logs
    echo ""
    
    check_ssl
    echo ""
    
    # Summary
    echo "=================================="
    if [ $exit_code -eq 0 ]; then
        print_status "OK" "All critical checks passed"
        log "Health check completed successfully"
    else
        print_status "ERROR" "Some critical checks failed"
        log "Health check completed with errors"
    fi
    echo "=================================="
    
    return $exit_code
}

# Run main function
main "$@" 