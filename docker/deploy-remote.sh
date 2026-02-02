#!/bin/bash
#
# Script to deploy CTFd on the vulnerable EC2 instance
# Run this script from your local machine
#

set -e

# Configuration
INSTANCE_IP="${1:-}"
SSH_KEY="${2:-$HOME/.ssh/ctf-infrastructure-key.pem}"

if [ -z "$INSTANCE_IP" ]; then
    echo "Usage: $0 <instance-ip> [ssh-key-path]"
    echo "Example: $0 13.235.27.225"
    exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
    echo "Error: SSH key not found at $SSH_KEY"
    exit 1
fi

echo "========================================="
echo "  Remote CTFd Deployment"
echo "========================================="
echo "Instance: $INSTANCE_IP"
echo "SSH Key: $SSH_KEY"
echo ""

# Copy docker directory to instance
echo "[1/4] Copying Docker files to instance..."
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no -r ../docker ubuntu@$INSTANCE_IP:~/

# Make deploy script executable
echo "[2/4] Setting permissions..."
ssh -i "$SSH_KEY" ubuntu@$INSTANCE_IP 'chmod +x ~/docker/deploy-ctfd.sh'

# Install Docker Compose if needed and deploy
echo "[3/4] Deploying CTFd..."
ssh -i "$SSH_KEY" ubuntu@$INSTANCE_IP 'cd ~/docker && ./deploy-ctfd.sh'

echo ""
echo "[4/4] Deployment complete!"
echo ""
echo "========================================="
echo "  Access CTFd:"
echo "  http://$INSTANCE_IP:8000"
echo "========================================="
echo ""
echo "To manage CTFd on the instance:"
echo "  ssh -i $SSH_KEY ubuntu@$INSTANCE_IP"
echo "  cd ~/docker"
echo "  docker-compose logs -f"
echo ""
