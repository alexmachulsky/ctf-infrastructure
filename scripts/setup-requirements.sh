#!/bin/bash
#
# Universal Setup Script - Install All Requirements
#
# This script detects your operating system and installs all required tools:
# - Terraform
# - AWS CLI
# - Docker & Docker Compose
# - Git
# - Other dependencies
#
# Supported OS: Ubuntu, Debian, RHEL/CentOS, Amazon Linux, macOS
#
# Usage: ./setup-requirements.sh
#

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  CTF Infrastructure - Requirements Setup                ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[→]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            VER=$VERSION_ID
        elif [ -f /etc/redhat-release ]; then
            OS="rhel"
        else
            OS="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    
    print_info "Detected OS: $OS"
}

# Check if running as root
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi
}

# Install on Ubuntu/Debian
install_ubuntu_debian() {
    print_step "Installing requirements for Ubuntu/Debian..."
    
    # Update package list
    print_step "Updating package list..."
    $SUDO apt-get update -qq
    
    # Install basic tools
    print_step "Installing basic tools..."
    $SUDO apt-get install -y curl wget git unzip jq apt-transport-https ca-certificates gnupg lsb-release > /dev/null 2>&1
    
    # Install Terraform
    if ! command -v terraform &> /dev/null; then
        print_step "Installing Terraform..."
        wget -O- https://apt.releases.hashicorp.com/gpg | $SUDO gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | $SUDO tee /etc/apt/sources.list.d/hashicorp.list
        $SUDO apt-get update -qq
        $SUDO apt-get install -y terraform > /dev/null 2>&1
        print_info "Terraform installed: $(terraform version | head -1)"
    else
        print_info "Terraform already installed: $(terraform version | head -1)"
    fi
    
    # Install AWS CLI
    if ! command -v aws &> /dev/null; then
        print_step "Installing AWS CLI..."
        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
        unzip -q /tmp/awscliv2.zip -d /tmp
        $SUDO /tmp/aws/install > /dev/null 2>&1
        rm -rf /tmp/aws /tmp/awscliv2.zip
        print_info "AWS CLI installed: $(aws --version)"
    else
        print_info "AWS CLI already installed: $(aws --version)"
    fi
    
    # Install Docker
    if ! command -v docker &> /dev/null; then
        print_step "Installing Docker..."
        $SUDO apt-get install -y docker.io > /dev/null 2>&1
        $SUDO systemctl start docker
        $SUDO systemctl enable docker
        $SUDO usermod -aG docker $USER || true
        print_info "Docker installed: $(docker --version)"
        print_warning "You may need to log out and back in for Docker group permissions"
    else
        print_info "Docker already installed: $(docker --version)"
    fi
    
    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_step "Installing Docker Compose..."
        $SUDO apt-get install -y docker-compose > /dev/null 2>&1
        print_info "Docker Compose installed: $(docker-compose --version)"
    else
        print_info "Docker Compose already installed: $(docker-compose --version)"
    fi
}

# Install on RHEL/CentOS/Amazon Linux
install_rhel() {
    print_step "Installing requirements for RHEL/CentOS/Amazon Linux..."
    
    # Determine package manager
    if command -v dnf &> /dev/null; then
        PKG_MGR="dnf"
    else
        PKG_MGR="yum"
    fi
    
    # Install basic tools
    print_step "Installing basic tools..."
    $SUDO $PKG_MGR install -y curl wget git unzip jq > /dev/null 2>&1
    
    # Install Terraform
    if ! command -v terraform &> /dev/null; then
        print_step "Installing Terraform..."
        $SUDO $PKG_MGR install -y yum-utils > /dev/null 2>&1
        $SUDO $PKG_MGR-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
        $SUDO $PKG_MGR install -y terraform > /dev/null 2>&1
        print_info "Terraform installed: $(terraform version | head -1)"
    else
        print_info "Terraform already installed: $(terraform version | head -1)"
    fi
    
    # Install AWS CLI
    if ! command -v aws &> /dev/null; then
        print_step "Installing AWS CLI..."
        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
        unzip -q /tmp/awscliv2.zip -d /tmp
        $SUDO /tmp/aws/install > /dev/null 2>&1
        rm -rf /tmp/aws /tmp/awscliv2.zip
        print_info "AWS CLI installed: $(aws --version)"
    else
        print_info "AWS CLI already installed: $(aws --version)"
    fi
    
    # Install Docker
    if ! command -v docker &> /dev/null; then
        print_step "Installing Docker..."
        $SUDO $PKG_MGR install -y docker > /dev/null 2>&1
        $SUDO systemctl start docker
        $SUDO systemctl enable docker
        $SUDO usermod -aG docker $USER || true
        print_info "Docker installed: $(docker --version)"
        print_warning "You may need to log out and back in for Docker group permissions"
    else
        print_info "Docker already installed: $(docker --version)"
    fi
    
    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_step "Installing Docker Compose..."
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        $SUDO curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        $SUDO chmod +x /usr/local/bin/docker-compose
        print_info "Docker Compose installed: $(docker-compose --version)"
    else
        print_info "Docker Compose already installed: $(docker-compose --version)"
    fi
}

# Install on macOS
install_macos() {
    print_step "Installing requirements for macOS..."
    
    # Check for Homebrew
    if ! command -v brew &> /dev/null; then
        print_step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        print_info "Homebrew already installed"
    fi
    
    # Install basic tools
    print_step "Installing basic tools..."
    brew install curl wget git jq > /dev/null 2>&1 || true
    
    # Install Terraform
    if ! command -v terraform &> /dev/null; then
        print_step "Installing Terraform..."
        brew tap hashicorp/tap
        brew install hashicorp/tap/terraform
        print_info "Terraform installed: $(terraform version | head -1)"
    else
        print_info "Terraform already installed: $(terraform version | head -1)"
    fi
    
    # Install AWS CLI
    if ! command -v aws &> /dev/null; then
        print_step "Installing AWS CLI..."
        brew install awscli
        print_info "AWS CLI installed: $(aws --version)"
    else
        print_info "AWS CLI already installed: $(aws --version)"
    fi
    
    # Install Docker Desktop
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not found. Please install Docker Desktop for Mac:"
        print_warning "  https://www.docker.com/products/docker-desktop"
    else
        print_info "Docker already installed: $(docker --version)"
    fi
}

# Verify installations
verify_installations() {
    echo ""
    print_step "Verifying installations..."
    
    local all_good=true
    
    # Check Terraform
    if command -v terraform &> /dev/null; then
        print_info "Terraform: $(terraform version -json | jq -r .terraform_version)"
    else
        print_error "Terraform: NOT FOUND"
        all_good=false
    fi
    
    # Check AWS CLI
    if command -v aws &> /dev/null; then
        print_info "AWS CLI: $(aws --version | cut -d' ' -f1 | cut -d'/' -f2)"
    else
        print_error "AWS CLI: NOT FOUND"
        all_good=false
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_info "Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    else
        print_error "Docker: NOT FOUND"
        all_good=false
    fi
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        print_info "Docker Compose: $(docker-compose --version | cut -d' ' -f4 | tr -d ',')"
    else
        print_error "Docker Compose: NOT FOUND"
        all_good=false
    fi
    
    # Check Git
    if command -v git &> /dev/null; then
        print_info "Git: $(git --version | cut -d' ' -f3)"
    else
        print_error "Git: NOT FOUND"
        all_good=false
    fi
    
    echo ""
    if [ "$all_good" = true ]; then
        print_info "All requirements installed successfully! ✓"
        return 0
    else
        print_error "Some requirements are missing. Please install them manually."
        return 1
    fi
}

# Generate SSH key if needed
setup_ssh_key() {
    echo ""
    print_step "Checking SSH key..."
    
    SSH_KEY_PATH="$HOME/.ssh/ctf-infrastructure-key.pem"
    
    if [ ! -f "$SSH_KEY_PATH" ]; then
        print_step "Generating SSH key..."
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -q
        chmod 600 "$SSH_KEY_PATH"
        print_info "SSH key generated: $SSH_KEY_PATH"
        print_info "Public key: ${SSH_KEY_PATH}.pub"
    else
        print_info "SSH key already exists: $SSH_KEY_PATH"
    fi
}

# Configure AWS
configure_aws() {
    echo ""
    print_step "Checking AWS configuration..."
    
    if [ ! -f "$HOME/.aws/credentials" ]; then
        print_warning "AWS credentials not configured"
        echo ""
        read -p "Would you like to configure AWS now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            aws configure
            print_info "AWS configured"
        else
            print_warning "Skipping AWS configuration. You can run 'aws configure' later."
        fi
    else
        print_info "AWS credentials already configured"
    fi
}

# Main
main() {
    print_header
    
    detect_os
    check_sudo
    
    echo ""
    
    case "$OS" in
        ubuntu|debian)
            install_ubuntu_debian
            ;;
        rhel|centos|rocky|almalinux|amzn)
            install_rhel
            ;;
        macos)
            install_macos
            ;;
        *)
            print_error "Unsupported operating system: $OS"
            print_error "Please install requirements manually:"
            echo "  - Terraform: https://www.terraform.io/downloads"
            echo "  - AWS CLI: https://aws.amazon.com/cli/"
            echo "  - Docker: https://docs.docker.com/get-docker/"
            exit 1
            ;;
    esac
    
    verify_installations
    setup_ssh_key
    configure_aws
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  Setup Complete!                                          ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_info "Next steps:"
    echo "  1. Import SSH key to AWS:"
    echo "     aws ec2 import-key-pair --key-name ctf-infrastructure-key \\"
    echo "       --public-key-material fileb://~/.ssh/ctf-infrastructure-key.pem.pub"
    echo ""
    echo "  2. Deploy infrastructure:"
    echo "     cd terraform"
    echo "     terraform init"
    echo "     terraform apply"
    echo ""
    
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        if groups | grep -q docker; then
            print_info "You're in the docker group"
        else
            print_warning "Log out and back in for Docker group permissions to take effect"
        fi
    fi
}

main "$@"
