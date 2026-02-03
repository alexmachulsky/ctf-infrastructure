terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data source to get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source to get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Network Module
module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = data.aws_availability_zones.available.names[0]
  allowed_ssh_cidr   = var.allowed_ssh_cidr
  allowed_icmp_cidr  = var.allowed_icmp_cidr
}

# Read vulnerable system setup script
data "local_file" "setup_script" {
  filename = "${path.module}/../scripts/setup-vulnerable-system.sh"
}

# User data for vulnerable instance
locals {
  vulnerable_user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    
    # Install required packages including Docker
    apt-get install -y curl wget vim net-tools docker.io
    
    # Enable and start Docker
    systemctl enable docker
    systemctl start docker
    
    # Add ubuntu user to docker group
    usermod -aG docker ubuntu
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Enable SSH password authentication for CTF participants
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
    
    # Copy and execute vulnerable system setup script
    cat > /tmp/setup-vulnerable-system.sh << 'SCRIPT'
    ${data.local_file.setup_script.content}
    SCRIPT
    
    chmod +x /tmp/setup-vulnerable-system.sh
    /tmp/setup-vulnerable-system.sh
    
    # Log completion
    echo "CTF vulnerable instance setup complete" > /var/log/ctf-setup.log
    EOF
}

# Vulnerable EC2 Instance
module "vulnerable_instance" {
  source = "./modules/compute"

  project_name       = var.project_name
  instance_name      = "${var.project_name}-vulnerable-instance"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.vulnerable_instance_type
  subnet_id          = module.network.public_subnet_id
  security_group_ids = [module.network.vulnerable_sg_id]
  key_name           = var.key_name
  user_data          = base64encode(local.vulnerable_user_data)

  # Set to true to create AMI (bonus requirement)
  create_ami = var.create_vulnerable_ami
  ami_name   = "${var.project_name}-vulnerable-ami-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
}

# Optional: Deploy instance from created AMI (bonus requirement)
module "vulnerable_from_ami" {
  source = "./modules/compute"
  count  = var.deploy_from_ami && var.create_vulnerable_ami ? 1 : 0

  project_name       = var.project_name
  instance_name      = "${var.project_name}-vulnerable-from-ami"
  ami_id             = module.vulnerable_instance.ami_id
  instance_type      = var.vulnerable_instance_type
  subnet_id          = module.network.public_subnet_id
  security_group_ids = [module.network.vulnerable_sg_id]
  key_name           = var.key_name

  create_ami = false

  depends_on = [module.vulnerable_instance]
}

# CTFd Instance
module "ctfd_instance" {
  source = "./modules/compute"
  count  = var.deploy_ctfd ? 1 : 0

  project_name       = var.project_name
  instance_name      = "${var.project_name}-ctfd"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.ctfd_instance_type
  subnet_id          = module.network.public_subnet_id
  security_group_ids = [module.network.ctfd_sg_id]
  key_name           = var.key_name
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    apt-get install -y docker.io docker-compose git
    
    # Enable and start Docker
    systemctl enable docker
    systemctl start docker
    
    # Add ubuntu user to docker group
    usermod -aG docker ubuntu
    
    # Log completion
    echo "CTFd instance Docker setup complete" > /var/log/ctfd-setup.log
    EOF
  )

  create_ami = false
}
