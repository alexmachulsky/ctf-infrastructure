#!/bin/bash
#
# Vulnerable Ubuntu Setup Script
# Configures a sudo find privilege escalation vulnerability for CTF purposes
#
# This script intentionally creates a security vulnerability for educational purposes.
# DO NOT use this in production environments.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CTF_USER="ctf"
CTF_PASSWORD="ctfpassword123"  # Default password - should be changed
SUDOERS_FILE="/etc/sudoers.d/ctf-find"
FLAG_FILE="/root/flag.txt"
FLAG_CONTENT="CTF{sud0_f1nd_pr1v3sc_c0mpl3t3}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  CTF Vulnerable System Setup${NC}"
echo -e "${BLUE}  Sudo Find Privilege Escalation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR]${NC} This script must be run as root (use sudo)"
   exit 1
fi

echo -e "${YELLOW}[INFO]${NC} Starting vulnerable system configuration..."
echo ""

# Step 1: Create CTF user
echo -e "${BLUE}[STEP 1]${NC} Creating CTF user..."
if id "$CTF_USER" &>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC} User '$CTF_USER' already exists. Skipping user creation."
else
    # Create user with home directory
    useradd -m -s /bin/bash "$CTF_USER"
    
    # Set password
    echo "$CTF_USER:$CTF_PASSWORD" | chpasswd
    
    echo -e "${GREEN}[SUCCESS]${NC} User '$CTF_USER' created successfully"
    echo -e "${GREEN}[INFO]${NC} Password: $CTF_PASSWORD"
fi
echo ""

# Step 2: Configure sudoers
echo -e "${BLUE}[STEP 2]${NC} Configuring sudoers for privilege escalation..."

# Create sudoers file with minimal permissions for find
cat > "$SUDOERS_FILE" << EOF
# CTF Challenge: Sudo Find Privilege Escalation
# Allow ctf user to run /usr/bin/find as root without password
$CTF_USER ALL=(root) NOPASSWD: /usr/bin/find
EOF

# Set correct permissions (must be 0440 or 0640)
chmod 0440 "$SUDOERS_FILE"

# Validate sudoers file syntax
if visudo -c -f "$SUDOERS_FILE" &>/dev/null; then
    echo -e "${GREEN}[SUCCESS]${NC} Sudoers file created and validated: $SUDOERS_FILE"
else
    echo -e "${RED}[ERROR]${NC} Sudoers file syntax error!"
    rm -f "$SUDOERS_FILE"
    exit 1
fi
echo ""

# Step 3: Create flag file
echo -e "${BLUE}[STEP 3]${NC} Creating flag file..."
echo "$FLAG_CONTENT" > "$FLAG_FILE"
chmod 600 "$FLAG_FILE"
chown root:root "$FLAG_FILE"
echo -e "${GREEN}[SUCCESS]${NC} Flag created at $FLAG_FILE (root only)"
echo ""

# Step 4: Verification
echo -e "${BLUE}[STEP 4]${NC} Verifying vulnerability configuration..."
echo ""

echo -e "${YELLOW}[CHECK 1]${NC} Checking if user exists..."
if id "$CTF_USER" &>/dev/null; then
    echo -e "${GREEN}✓${NC} User '$CTF_USER' exists"
else
    echo -e "${RED}✗${NC} User '$CTF_USER' does not exist"
    exit 1
fi

echo -e "${YELLOW}[CHECK 2]${NC} Checking sudoers configuration..."
if [ -f "$SUDOERS_FILE" ]; then
    echo -e "${GREEN}✓${NC} Sudoers file exists: $SUDOERS_FILE"
    echo -e "${BLUE}    Content:${NC}"
    grep -v '^#' "$SUDOERS_FILE" | grep -v '^$' | sed 's/^/    /'
else
    echo -e "${RED}✗${NC} Sudoers file does not exist"
    exit 1
fi

echo -e "${YELLOW}[CHECK 3]${NC} Checking sudo permissions for '$CTF_USER'..."
# Run sudo -l as the ctf user to show what they can execute
sudo_rules=$(sudo -l -U "$CTF_USER" 2>/dev/null | grep -A 10 "User $CTF_USER")
if echo "$sudo_rules" | grep -q "/usr/bin/find"; then
    echo -e "${GREEN}✓${NC} User '$CTF_USER' can execute /usr/bin/find via sudo"
    echo -e "${BLUE}    Sudo rules:${NC}"
    echo "$sudo_rules" | sed 's/^/    /'
else
    echo -e "${RED}✗${NC} Sudo rule not properly configured"
    exit 1
fi

echo -e "${YELLOW}[CHECK 4]${NC} Testing sudo find execution (without exploitation)..."
# Test that sudo find works without password (using -quit to not actually search)
if sudo -u "$CTF_USER" sudo -n /usr/bin/find /tmp -maxdepth 0 -quit &>/dev/null; then
    echo -e "${GREEN}✓${NC} sudo find can be executed without password"
else
    echo -e "${RED}✗${NC} sudo find execution failed"
    exit 1
fi

echo -e "${YELLOW}[CHECK 5]${NC} Checking flag file..."
if [ -f "$FLAG_FILE" ]; then
    echo -e "${GREEN}✓${NC} Flag file exists at $FLAG_FILE"
    echo -e "${BLUE}    Permissions:${NC} $(ls -l $FLAG_FILE | awk '{print $1, $3, $4}')"
else
    echo -e "${RED}✗${NC} Flag file does not exist"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Configuration Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Vulnerability Information:${NC}"
echo -e "  Target User: ${YELLOW}$CTF_USER${NC}"
echo -e "  Password: ${YELLOW}$CTF_PASSWORD${NC}"
echo -e "  Vulnerable Binary: ${YELLOW}/usr/bin/find${NC}"
echo -e "  Sudoers File: ${YELLOW}$SUDOERS_FILE${NC}"
echo -e "  Flag Location: ${YELLOW}$FLAG_FILE${NC}"
echo ""
echo -e "${BLUE}How to exploit:${NC}"
echo -e "  1. SSH as user: ssh $CTF_USER@<host>"
echo -e "  2. Verify sudo rights: sudo -l"
echo -e "  3. Exploit via find: sudo find /etc -exec /bin/bash \\;"
echo -e "  4. Capture the flag: cat $FLAG_FILE"
echo ""
echo -e "${BLUE}Reference:${NC}"
echo -e "  https://gtfobins.github.io/gtfobins/find/#sudo"
echo ""
echo -e "${YELLOW}[NOTE]${NC} This system is intentionally vulnerable for CTF purposes only!"
