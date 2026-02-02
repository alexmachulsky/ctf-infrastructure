#!/bin/bash
#
# Jenkins Installation Script for Ubuntu 22.04
# 
# This script installs Jenkins with all required dependencies and configures it
# to start automatically on boot. It follows official Jenkins installation guide.
#
# Requirements:
# - Ubuntu 22.04 LTS
# - Internet connectivity
# - Root privileges (script will use sudo)
#
# Usage: sudo ./install-jenkins.sh
#

set -e  # Exit on error
set -u  # Exit on undefined variable

echo "=================================="
echo "Jenkins Installation Script"
echo "=================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root"
    SUDO=""
else
    print_info "Running with sudo privileges"
    SUDO="sudo"
fi

# Step 1: Update system packages
print_info "Updating system packages..."
$SUDO apt-get update -qq

# Step 2: Install Java (Jenkins requires Java 11 or 17)
print_info "Installing OpenJDK 17..."
$SUDO apt-get install -y openjdk-17-jdk > /dev/null 2>&1

# Verify Java installation
JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
print_info "Installed Java version: ${JAVA_VERSION}"

# Step 3: Add Jenkins repository key
print_info "Adding Jenkins repository GPG key..."
$SUDO wget -q -O /usr/share/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# Step 4: Add Jenkins repository
print_info "Adding Jenkins apt repository..."
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
    $SUDO tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Step 5: Update package index with Jenkins repo
print_info "Updating package index..."
$SUDO apt-get update -qq

# Step 6: Install Jenkins
print_info "Installing Jenkins..."
$SUDO apt-get install -y jenkins > /dev/null 2>&1

# Step 7: Enable Jenkins service
print_info "Enabling Jenkins to start on boot..."
$SUDO systemctl enable jenkins > /dev/null 2>&1

# Step 8: Start Jenkins service
print_info "Starting Jenkins service..."
$SUDO systemctl start jenkins

# Wait for Jenkins to start
print_info "Waiting for Jenkins to initialize (30 seconds)..."
sleep 30

# Step 9: Check Jenkins status
if $SUDO systemctl is-active --quiet jenkins; then
    print_info "Jenkins is running successfully!"
else
    print_error "Jenkins failed to start"
    $SUDO systemctl status jenkins --no-pager
    exit 1
fi

# Step 10: Get Jenkins version
JENKINS_VERSION=$($SUDO apt-cache policy jenkins | grep Installed | awk '{print $2}')
print_info "Installed Jenkins version: ${JENKINS_VERSION}"

# Step 11: Display initial admin password
echo ""
echo "=================================="
echo "Installation Complete!"
echo "=================================="
echo ""
print_info "Jenkins is installed and running on http://localhost:8080"
echo ""
print_info "Initial Admin Password:"
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo ""
    echo "----------------------------------------"
    $SUDO cat /var/lib/jenkins/secrets/initialAdminPassword
    echo "----------------------------------------"
    echo ""
else
    print_warning "Initial admin password file not found yet. Wait a few moments and check:"
    echo "    sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
fi
echo ""
print_info "Setup Instructions:"
echo "  1. Open http://localhost:8080 (or http://YOUR_SERVER_IP:8080)"
echo "  2. Enter the initial admin password shown above"
echo "  3. Install suggested plugins"
echo "  4. Create your first admin user"
echo ""
print_info "Useful Commands:"
echo "  - Check status:  sudo systemctl status jenkins"
echo "  - Stop Jenkins:  sudo systemctl stop jenkins"
echo "  - Start Jenkins: sudo systemctl start jenkins"
echo "  - Restart:       sudo systemctl restart jenkins"
echo "  - View logs:     sudo journalctl -u jenkins -f"
echo ""
echo "=================================="
