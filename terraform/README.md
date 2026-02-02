# Terraform AWS Infrastructure

This directory contains Terraform configuration for deploying the CTF infrastructure to AWS.

## Architecture

The infrastructure consists of:

- **VPC**: Isolated network environment (10.0.0.0/16)
- **Public Subnet**: For internet-accessible instances (10.0.1.0/24)
- **Internet Gateway**: Enables internet connectivity
- **Security Groups**: 
  - Vulnerable instance SG (SSH + ICMP)
  - CTFd instance SG (SSH + HTTP/HTTPS + port 8000)
- **EC2 Instances**:
  - Vulnerable Ubuntu 22.04 instance with sudo find escalation
  - CTFd platform instance (optional)
- **AMI Creation** (Bonus): Creates AMI from configured vulnerable instance

## Modules

### Network Module (`modules/network/`)
Manages VPC, subnets, internet gateway, route tables, and security groups.

### Compute Module (`modules/compute/`)
Manages EC2 instances and optional AMI creation.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** >= 1.0 installed
4. **SSH Key Pair** created in AWS

### Create SSH Key Pair

```bash
# Create key pair in AWS (replace 'us-east-1' with your region)
aws ec2 create-key-pair \
  --key-name ctf-infrastructure-key \
  --region us-east-1 \
  --query 'KeyMaterial' \
  --output text > ctf-infrastructure-key.pem

# Set correct permissions
chmod 400 ctf-infrastructure-key.pem
```

## Quick Start

### 1. Configure Variables

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

**Important variables to set:**
- `key_name`: Your AWS SSH key pair name
- `aws_region`: Your preferred AWS region
- `allowed_ssh_cidr`: Restrict SSH access (default: 0.0.0.0/0)

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan Deployment

```bash
terraform plan
```

### 4. Deploy Infrastructure

```bash
terraform apply
```

Review the plan and type `yes` to proceed.

### 5. Get Outputs

```bash
# Get all outputs
terraform output

# Get specific output
terraform output vulnerable_instance_public_ip

# Get CTF credentials
terraform output -json ctf_credentials

# Get infrastructure info for CTFd plugin
terraform output -raw infrastructure_info > ../ctfd-plugin/infrastructure.json
```

## Connecting to Instances

### Connect to Vulnerable Instance as Ubuntu

```bash
ssh -i <your-key>.pem ubuntu@$(terraform output -raw vulnerable_instance_public_ip)
```

### Connect as CTF User (after setup completes)

Wait ~2-3 minutes for user-data script to complete, then:

```bash
ssh -i <your-key>.pem ctf@$(terraform output -raw vulnerable_instance_public_ip)
# Password: ctfpassword123
```

### Verify Vulnerability Setup

```bash
# SSH as ubuntu user
ssh -i <your-key>.pem ubuntu@<instance-ip>

# Check setup log
sudo cat /var/log/ctf-setup.log

# Manually verify vulnerability
sudo /tmp/setup-vulnerable-system.sh
```

## Bonus: AMI Creation and Deployment

To enable AMI creation and deployment from AMI:

```bash
# Edit terraform.tfvars
create_vulnerable_ami = true
deploy_from_ami       = true

# Apply changes
terraform apply
```

This will:
1. Create the vulnerable instance
2. Create an AMI from that instance
3. Deploy a new instance from the created AMI

## Outputs

Key outputs for integration with CTFd plugin:

| Output | Description |
|--------|-------------|
| `vulnerable_instance_id` | EC2 instance ID |
| `vulnerable_instance_public_ip` | Public IP address |
| `vulnerable_instance_public_dns` | Public DNS name |
| `vulnerable_instance_private_ip` | Private IP address |
| `ctfd_instance_public_ip` | CTFd public IP |
| `ctfd_url` | CTFd access URL |
| `infrastructure_info` | JSON with all info for CTFd plugin |

## Exporting for CTFd Plugin

```bash
# Export infrastructure information for CTFd plugin
terraform output -raw infrastructure_info > ../ctfd-plugin/infrastructure.json
```

## Resource Tagging

All resources are tagged with:
- `Project`: Project name from variables
- `Environment`: Environment name
- `ManagedBy`: "Terraform"

## Cleaning Up

To destroy all infrastructure:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources!

## Cost Estimation

Approximate AWS costs (us-east-1):
- t2.micro (vulnerable): ~$0.0116/hour (~$8.50/month)
- t2.small (CTFd): ~$0.023/hour (~$17/month)
- Data transfer: ~$0.09/GB (outbound)

**Total: ~$25-30/month** for running both instances 24/7

## Security Notes

⚠️ **IMPORTANT**:
- Default configuration allows SSH from anywhere (0.0.0.0/0)
- Vulnerable instance is **intentionally insecure**
- CTF password is hardcoded and publicly visible
- Do NOT use in production environments
- Restrict `allowed_ssh_cidr` to your IP range
- Terminate instances after CTF events

## Troubleshooting

### Instance Not Accessible
- Check security group rules
- Verify key pair name matches
- Ensure instance is in "running" state
- Check VPC/subnet route tables

### User Data Not Running
- SSH to instance and check: `sudo cat /var/log/cloud-init-output.log`
- Manually run setup script: `sudo /tmp/setup-vulnerable-system.sh`

### AMI Creation Fails
- Ensure instance is running
- Check IAM permissions for AMI creation
- AMI creation takes 5-10 minutes

## Module Documentation

See individual module README files:
- [Network Module](modules/network/README.md)
- [Compute Module](modules/compute/README.md)
