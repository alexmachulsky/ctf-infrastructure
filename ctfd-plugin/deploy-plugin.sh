#!/bin/bash
#
# Deploy CTFd Plugin to EC2 Instance
# Run from local machine
#

set -e

INSTANCE_IP="${1:-}"
SSH_KEY="${2:-$HOME/.ssh/ctf-infrastructure-key.pem}"

if [ -z "$INSTANCE_IP" ]; then
    echo "Usage: $0 <instance-ip> [ssh-key-path]"
    echo "Example: $0 13.235.27.225"
    exit 1
fi

echo "========================================="
echo "  CTFd Plugin Deployment"
echo "========================================="
echo "Instance: $INSTANCE_IP"
echo ""

# Copy plugin directory to instance
echo "[1/3] Copying plugin files..."
ssh -i "$SSH_KEY" ubuntu@$INSTANCE_IP 'rm -rf ~/docker/ctfd-plugin && mkdir -p ~/docker/ctfd-plugin'
scp -i "$SSH_KEY" -r ../ctfd-plugin/* ubuntu@$INSTANCE_IP:~/docker/ctfd-plugin/

# Update docker-compose.yml to mount the plugin
echo "[2/3] Updating docker-compose.yml..."
ssh -i "$SSH_KEY" ubuntu@$INSTANCE_IP 'cd ~/docker && sed -i "s|# - ./ctfd-plugin|- ./ctfd-plugin|g" docker-compose.yml'

# Restart CTFd with plugin
echo "[3/3] Restarting CTFd with plugin..."
ssh -i "$SSH_KEY" ubuntu@$INSTANCE_IP 'cd ~/docker && sudo docker-compose restart ctfd'

echo ""
echo "========================================="
echo "  Plugin Deployed Successfully!"
echo "========================================="
echo ""
echo "Access the plugin:"
echo "  http://$INSTANCE_IP:8000/env-validator/admin"
echo ""
echo "Wait ~10 seconds for CTFd to restart, then login as admin."
echo ""
