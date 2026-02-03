#!/bin/bash
#
# Jenkins Testing Script
# Tests that Jenkins is properly installed and can run the CTF pipeline
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}          Jenkins Installation & Testing                   ${BLUE}║${NC}"
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

# Test 1: Check Jenkins is installed
test_jenkins_installed() {
    print_step "Test 1: Checking if Jenkins is installed..."
    
    if command -v jenkins &> /dev/null || [ -f /usr/share/java/jenkins.war ]; then
        print_info "Jenkins is installed"
        JENKINS_VERSION=$(java -jar /usr/share/java/jenkins.war --version 2>/dev/null || echo "unknown")
        print_info "Version: $JENKINS_VERSION"
        return 0
    else
        print_error "Jenkins is NOT installed"
        return 1
    fi
}

# Test 2: Check Jenkins service status
test_jenkins_running() {
    print_step "Test 2: Checking if Jenkins service is running..."
    
    if systemctl is-active --quiet jenkins; then
        print_info "Jenkins service is active"
        UPTIME=$(systemctl show jenkins --property=ActiveEnterTimestamp --value)
        print_info "Started: $UPTIME"
        return 0
    else
        print_error "Jenkins service is NOT running"
        print_warning "Start with: sudo systemctl start jenkins"
        return 1
    fi
}

# Test 3: Check Jenkins port
test_jenkins_port() {
    print_step "Test 3: Checking if Jenkins is listening on port 8080..."
    
    if netstat -tuln 2>/dev/null | grep -q ":8080 " || ss -tuln 2>/dev/null | grep -q ":8080 "; then
        print_info "Jenkins is listening on port 8080"
        return 0
    else
        print_error "Jenkins is NOT listening on port 8080"
        return 1
    fi
}

# Test 4: Check Jenkins responds to HTTP
test_jenkins_http() {
    print_step "Test 4: Checking if Jenkins HTTP interface responds..."
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 403 ]; then
        print_info "Jenkins HTTP interface is responding (HTTP $HTTP_CODE)"
        return 0
    else
        print_error "Jenkins HTTP interface is NOT responding (HTTP $HTTP_CODE)"
        return 1
    fi
}

# Test 5: Check required tools for pipeline
test_pipeline_tools() {
    print_step "Test 5: Checking required tools for CTF pipeline..."
    
    local all_good=true
    
    if command -v terraform &> /dev/null; then
        print_info "Terraform: $(terraform version -json 2>/dev/null | jq -r .terraform_version || terraform version | head -1)"
    else
        print_error "Terraform: NOT FOUND"
        all_good=false
    fi
    
    if command -v aws &> /dev/null; then
        print_info "AWS CLI: $(aws --version | cut -d' ' -f1 | cut -d'/' -f2)"
    else
        print_error "AWS CLI: NOT FOUND"
        all_good=false
    fi
    
    if command -v docker &> /dev/null; then
        print_info "Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    else
        print_error "Docker: NOT FOUND"
        all_good=false
    fi
    
    if command -v git &> /dev/null; then
        print_info "Git: $(git --version | cut -d' ' -f3)"
    else
        print_error "Git: NOT FOUND"
        all_good=false
    fi
    
    if command -v jq &> /dev/null; then
        print_info "jq: $(jq --version | cut -d'-' -f2)"
    else
        print_warning "jq: NOT FOUND (optional but recommended)"
    fi
    
    [ "$all_good" = true ] && return 0 || return 1
}

# Test 6: Validate Jenkinsfile syntax
test_jenkinsfile_syntax() {
    print_step "Test 6: Validating Jenkinsfile syntax..."
    
    JENKINSFILE="$(dirname "$0")/../Jenkinsfile"
    
    if [ ! -f "$JENKINSFILE" ]; then
        print_error "Jenkinsfile not found at: $JENKINSFILE"
        return 1
    fi
    
    # Basic syntax checks
    if grep -q "^pipeline {" "$JENKINSFILE" && \
       grep -q "agent any" "$JENKINSFILE" && \
       grep -q "stages {" "$JENKINSFILE"; then
        print_info "Jenkinsfile has valid declarative pipeline structure"
        
        STAGE_COUNT=$(grep -c "stage(" "$JENKINSFILE" || true)
        print_info "Found $STAGE_COUNT stages in pipeline"
        return 0
    else
        print_error "Jenkinsfile has invalid structure"
        return 1
    fi
}

# Test 7: Check Jenkins configuration directory
test_jenkins_config() {
    print_step "Test 7: Checking Jenkins configuration directory..."
    
    if [ -d /var/lib/jenkins ]; then
        print_info "Jenkins home directory exists"
        
        JOBS_COUNT=$(ls -1 /var/lib/jenkins/jobs 2>/dev/null | wc -l || echo "0")
        print_info "Configured jobs: $JOBS_COUNT"
        
        if [ -d /var/lib/jenkins/plugins ]; then
            PLUGINS_COUNT=$(ls -1 /var/lib/jenkins/plugins 2>/dev/null | grep -c "\.jpi$" || echo "0")
            print_info "Installed plugins: $PLUGINS_COUNT"
        fi
        
        return 0
    else
        print_error "Jenkins home directory not found"
        return 1
    fi
}

# Display summary
display_summary() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}                    TEST SUMMARY                           ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo "Tests Passed: $TESTS_PASSED / $TESTS_TOTAL"
    
    if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
        echo ""
        print_info "All tests passed! Jenkins is ready to use."
        echo ""
        echo -e "${GREEN}Next Steps:${NC}"
        echo "  1. Access Jenkins: http://localhost:8080"
        echo "  2. Create a new Pipeline job"
        echo "  3. Point it to your GitHub repository"
        echo "  4. Use the Jenkinsfile from the repo"
        echo ""
    else
        echo ""
        print_warning "Some tests failed. Review the output above."
        echo ""
        echo "Common fixes:"
        echo "  - Start Jenkins: sudo systemctl start jenkins"
        echo "  - Install tools: ./scripts/setup-requirements.sh"
        echo "  - Check logs: sudo journalctl -u jenkins -f"
        echo ""
    fi
}

# Main execution
main() {
    print_header
    
    TESTS_TOTAL=7
    TESTS_PASSED=0
    
    test_jenkins_installed && ((TESTS_PASSED++)) || true
    echo ""
    
    test_jenkins_running && ((TESTS_PASSED++)) || true
    echo ""
    
    test_jenkins_port && ((TESTS_PASSED++)) || true
    echo ""
    
    test_jenkins_http && ((TESTS_PASSED++)) || true
    echo ""
    
    test_pipeline_tools && ((TESTS_PASSED++)) || true
    echo ""
    
    test_jenkinsfile_syntax && ((TESTS_PASSED++)) || true
    echo ""
    
    test_jenkins_config && ((TESTS_PASSED++)) || true
    
    display_summary
    
    # Return 0 if all tests passed
    [ $TESTS_PASSED -eq $TESTS_TOTAL ]
}

main "$@"
