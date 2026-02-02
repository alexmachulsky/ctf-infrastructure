#!/bin/bash
#
# CTFd Deployment Script
# Deploys CTFd platform using Docker Compose
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  CTFd Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root or with docker permissions
if ! docker ps &>/dev/null; then
    echo -e "${RED}[ERROR]${NC} Cannot access Docker. Please run with sudo or ensure user is in docker group."
    echo -e "To add user to docker group: ${YELLOW}sudo usermod -aG docker \$USER${NC}"
    echo -e "Then log out and back in."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${YELLOW}[WARN]${NC} Docker Compose not found. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}[SUCCESS]${NC} Docker Compose installed"
else
    echo -e "${GREEN}[INFO]${NC} Docker Compose is installed"
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "${BLUE}[STEP 1]${NC} Pulling Docker images..."
docker-compose pull

echo ""
echo -e "${BLUE}[STEP 2]${NC} Starting CTFd services..."
docker-compose up -d

echo ""
echo -e "${BLUE}[STEP 3]${NC} Waiting for services to be ready..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}[SUCCESS]${NC} CTFd is running!"
else
    echo -e "${RED}[ERROR]${NC} Some services failed to start"
    docker-compose ps
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  CTFd Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Get server IP
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')

echo -e "${BLUE}Access CTFd:${NC}"
echo -e "  Local: ${YELLOW}http://localhost:8000${NC}"
echo -e "  Public: ${YELLOW}http://${SERVER_IP}:8000${NC}"
echo ""
echo -e "${BLUE}Initial Setup:${NC}"
echo -e "  1. Open the URL in your browser"
echo -e "  2. Complete the setup wizard:"
echo -e "     - Set admin username and password"
echo -e "     - Configure CTF name and details"
echo -e "     - Choose CTF mode (Jeopardy recommended)"
echo -e "  3. Login with your admin credentials"
echo ""
echo -e "${BLUE}Management Commands:${NC}"
echo -e "  View logs: ${YELLOW}docker-compose logs -f ctfd${NC}"
echo -e "  Stop CTFd: ${YELLOW}docker-compose stop${NC}"
echo -e "  Start CTFd: ${YELLOW}docker-compose start${NC}"
echo -e "  Restart: ${YELLOW}docker-compose restart${NC}"
echo -e "  Remove all: ${YELLOW}docker-compose down -v${NC} (deletes data!)"
echo ""
echo -e "${BLUE}Container Status:${NC}"
docker-compose ps
echo ""
