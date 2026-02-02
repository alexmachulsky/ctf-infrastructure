# CTF Infrastructure - Sudo Privilege Escalation Challenge

This project implements an end-to-end Capture The Flag (CTF) environment demonstrating a sudo-based privilege escalation vulnerability on Ubuntu, deployed in AWS with CTFd integration and Jenkins automation.

## Architecture Overview

The infrastructure consists of:
- **Vulnerable Ubuntu EC2 Instance**: Intentionally misconfigured with sudo find privilege escalation
- **CTFd Platform**: Deployed on Docker for challenge management
- **Jenkins CI/CD**: Automated deployment pipeline
- **AWS Infrastructure**: VPC, subnets, security groups, EC2 instances

## Vulnerability: Sudo Find Privilege Escalation

This CTF demonstrates a real-world privilege escalation technique where the `find` binary can be abused when allowed via sudo. The `find` command has the ability to execute other commands, which can be leveraged to gain root access.

**References:**
- [GTFOBins - find](https://gtfobins.github.io/gtfobins/find/)
- [Sudo Privilege Escalation](https://vickieli.dev/system%20security/sudo-privesc/)
- [Abusing Sudo](https://bad-glitch.github.io/posts/privilege-escalation/sudo/abusing-sudo)

## Project Structure

```
ctf-infrastructure/
├── scripts/              # Vulnerable system configuration
│   ├── setup-vulnerable-system.sh
│   └── verify-vulnerability.sh
├── terraform/           # AWS infrastructure as code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── network/
│       └── compute/
├── ctfd-plugin/        # CTFd environment validation plugin
│   ├── __init__.py
│   └── plugin.py
├── jenkins/            # CI/CD automation
│   ├── Jenkinsfile
│   └── install-jenkins.sh
├── docker/             # CTFd deployment
│   └── docker-compose.yml
└── README.md
```

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform >= 1.0
- Docker and Docker Compose
- Jenkins (installation script provided)
- Python 3.8+
- Git

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ctf-infrastructure
```

### 2. Configure AWS Credentials

```bash
aws configure
```

### 3. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. Install and Configure Jenkins

```bash
cd jenkins
./install-jenkins.sh
```

### 5. Deploy CTFd

```bash
cd docker
docker-compose up -d
```

## Detailed Setup Instructions

(To be completed with specific steps for each component)

## Verification

### Testing the Vulnerability

(Instructions for verifying the sudo find privilege escalation)

### CTFd Plugin Validation

(Instructions for testing the environment reachability validation)

## Jenkins Pipeline

The Jenkins pipeline automates the entire deployment process:
1. Checkout code from Git
2. Initialize and apply Terraform
3. Deploy vulnerable EC2 instances
4. Configure CTFd integration
5. Optional destroy stage

## Security Notice

⚠️ **WARNING**: This infrastructure is intentionally vulnerable for educational purposes. Do NOT deploy this in production environments or expose it to the public internet without proper security controls.

## License

MIT License

## Authors

Created for CTF Infrastructure Home Assignment
