#!/bin/bash
#
# Jenkins Testing Script
# Tests the complete Jenkins installation and pipeline
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $1${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}[→]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Test 1: Install Jenkins
test_jenkins_installation() {
    print_header "TEST 1: Jenkins Installation"
    
    if systemctl is-active --quiet jenkins; then
        print_success "Jenkins is already installed and running"
        JENKINS_VERSION=$(sudo apt-cache policy jenkins | grep Installed | awk '{print $2}')
        print_success "Version: $JENKINS_VERSION"
        return 0
    fi
    
    print_step "Installing Jenkins..."
    sudo ./scripts/install-jenkins.sh
    
    sleep 5
    
    if systemctl is-active --quiet jenkins; then
        print_success "Jenkins installed and running"
        return 0
    else
        print_error "Jenkins installation failed"
        return 1
    fi
}

# Test 2: Verify Jenkins is accessible
test_jenkins_accessibility() {
    print_header "TEST 2: Jenkins Accessibility"
    
    print_step "Checking Jenkins port 8080..."
    
    for i in {1..30}; do
        if curl -s http://localhost:8080 > /dev/null 2>&1; then
            print_success "Jenkins is accessible at http://localhost:8080"
            return 0
        fi
        echo -n "."
        sleep 2
    done
    
    print_error "Jenkins is not accessible"
    return 1
}

# Test 3: Get initial admin password
test_get_admin_password() {
    print_header "TEST 3: Jenkins Initial Setup"
    
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
        print_success "Initial admin password retrieved"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Initial Admin Password:"
        echo "$ADMIN_PASSWORD"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        return 0
    else
        print_warning "Initial password file not found (Jenkins may still be starting)"
        return 1
    fi
}

# Test 4: Verify Jenkins plugins directory
test_jenkins_structure() {
    print_header "TEST 4: Jenkins Directory Structure"
    
    print_step "Checking Jenkins home directory..."
    if [ -d /var/lib/jenkins ]; then
        print_success "Jenkins home exists: /var/lib/jenkins"
    else
        print_error "Jenkins home not found"
        return 1
    fi
    
    print_step "Checking Jenkins logs..."
    if [ -d /var/log/jenkins ]; then
        print_success "Jenkins logs directory exists"
    else
        print_warning "Jenkins logs directory not found"
    fi
    
    print_step "Checking Jenkins config..."
    if [ -f /var/lib/jenkins/config.xml ]; then
        print_success "Jenkins configuration exists"
    else
        print_warning "Jenkins config not found (may still be initializing)"
    fi
    
    return 0
}

# Test 5: Test Jenkins service
test_jenkins_service() {
    print_header "TEST 5: Jenkins Service Status"
    
    print_step "Checking systemd service..."
    sudo systemctl status jenkins --no-pager | head -15
    
    if systemctl is-enabled --quiet jenkins; then
        print_success "Jenkins is enabled (will start on boot)"
    else
        print_warning "Jenkins is not enabled for auto-start"
    fi
    
    return 0
}

# Test 6: Test Jenkins CLI
test_jenkins_cli() {
    print_header "TEST 6: Jenkins CLI Test"
    
    print_step "Attempting to download Jenkins CLI..."
    
    if curl -s http://localhost:8080/jnlpJars/jenkins-cli.jar -o /tmp/jenkins-cli.jar; then
        print_success "Jenkins CLI jar downloaded"
        ls -lh /tmp/jenkins-cli.jar
        rm -f /tmp/jenkins-cli.jar
        return 0
    else
        print_warning "Could not download Jenkins CLI (Jenkins may not be fully initialized)"
        return 1
    fi
}

# Display next steps
display_next_steps() {
    echo ""
    print_header "Next Steps"
    
    echo "1. Open Jenkins in your browser:"
    echo "   http://localhost:8080"
    echo ""
    echo "2. Complete the setup wizard:"
    echo "   - Enter the initial admin password (shown above)"
    echo "   - Install suggested plugins"
    echo "   - Create first admin user"
    echo ""
    echo "3. Configure AWS credentials:"
    echo "   - Go to: Manage Jenkins → Manage Credentials"
    echo "   - Add AWS credentials with ID 'aws-credentials'"
    echo ""
    echo "4. Copy SSH key for Jenkins:"
    echo "   sudo mkdir -p /var/lib/jenkins/.ssh"
    echo "   sudo cp ~/.ssh/ctf-infrastructure-key.pem /var/lib/jenkins/.ssh/"
    echo "   sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh"
    echo "   sudo chmod 600 /var/lib/jenkins/.ssh/ctf-infrastructure-key.pem"
    echo ""
    echo "5. Create pipeline job:"
    echo "   - New Item → Pipeline"
    echo "   - Name: CTF-Infrastructure-Pipeline"
    echo "   - Pipeline script from SCM → Git"
    echo "   - Repository: https://github.com/alexmachulsky/ctf-infrastructure.git"
    echo "   - Script Path: Jenkinsfile"
    echo ""
    echo "6. See detailed guide:"
    echo "   cat docs/JENKINS_SETUP.md"
    echo ""
}

# Main test execution
main() {
    echo ""
    print_header "Jenkins Testing Suite"
    echo "This will test the Jenkins installation and configuration"
    echo ""
    
    read -p "Press Enter to continue (Ctrl+C to cancel)..."
    echo ""
    
    # Run tests
    test_jenkins_installation
    test_jenkins_accessibility
    test_get_admin_password
    test_jenkins_structure
    test_jenkins_service
    test_jenkins_cli
    
    # Summary
    echo ""
    print_header "Test Summary"
    
    if systemctl is-active --quiet jenkins; then
        print_success "Jenkins is running successfully!"
        display_next_steps
    else
        print_error "Jenkins tests failed. Check the errors above."
        echo ""
        echo "Troubleshooting:"
        echo "  - Check logs: sudo journalctl -u jenkins -n 50"
        echo "  - Check status: sudo systemctl status jenkins"
        echo "  - Restart: sudo systemctl restart jenkins"
    fi
}

main "$@"
