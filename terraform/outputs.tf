# Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.network.public_subnet_id
}

# Vulnerable Instance Outputs
output "vulnerable_instance_id" {
  description = "ID of the vulnerable EC2 instance"
  value       = module.vulnerable_instance.instance_id
}

output "vulnerable_instance_public_ip" {
  description = "Public IP address of the vulnerable instance"
  value       = module.vulnerable_instance.instance_public_ip
}

output "vulnerable_instance_public_dns" {
  description = "Public DNS name of the vulnerable instance"
  value       = module.vulnerable_instance.instance_public_dns
}

output "vulnerable_instance_private_ip" {
  description = "Private IP address of the vulnerable instance"
  value       = module.vulnerable_instance.instance_private_ip
}

# AMI Outputs (Bonus)
output "vulnerable_ami_id" {
  description = "ID of the created vulnerable AMI"
  value       = module.vulnerable_instance.ami_id
}

output "vulnerable_ami_name" {
  description = "Name of the created vulnerable AMI"
  value       = module.vulnerable_instance.ami_name
}

# Instance from AMI Outputs (Bonus)
output "vulnerable_from_ami_instance_id" {
  description = "ID of the instance deployed from AMI"
  value       = var.deploy_from_ami && var.create_vulnerable_ami ? module.vulnerable_from_ami[0].instance_id : null
}

output "vulnerable_from_ami_public_ip" {
  description = "Public IP of the instance deployed from AMI"
  value       = var.deploy_from_ami && var.create_vulnerable_ami ? module.vulnerable_from_ami[0].instance_public_ip : null
}

output "vulnerable_from_ami_public_dns" {
  description = "Public DNS of the instance deployed from AMI"
  value       = var.deploy_from_ami && var.create_vulnerable_ami ? module.vulnerable_from_ami[0].instance_public_dns : null
}

# CTFd Instance Outputs
output "ctfd_instance_id" {
  description = "ID of the CTFd EC2 instance"
  value       = var.deploy_ctfd ? module.ctfd_instance[0].instance_id : null
}

output "ctfd_instance_public_ip" {
  description = "Public IP address of the CTFd instance"
  value       = var.deploy_ctfd ? module.ctfd_instance[0].instance_public_ip : null
}

output "ctfd_instance_public_dns" {
  description = "Public DNS name of the CTFd instance"
  value       = var.deploy_ctfd ? module.ctfd_instance[0].instance_public_dns : null
}

output "ctfd_url" {
  description = "URL to access CTFd"
  value       = var.deploy_ctfd ? "http://${module.ctfd_instance[0].instance_public_ip}:8000" : null
}

# Connection Information
output "ssh_connection_vulnerable" {
  description = "SSH command to connect to vulnerable instance"
  value       = "ssh -i <your-key>.pem ubuntu@${module.vulnerable_instance.instance_public_ip}"
}

output "ssh_connection_ctf_user" {
  description = "SSH command to connect as CTF user (after setup completes)"
  value       = "ssh -i <your-key>.pem ctf@${module.vulnerable_instance.instance_public_ip}"
}

output "ctf_credentials" {
  description = "CTF user credentials"
  value = {
    username = "ctf"
    password = "ctfpassword123"
  }
  sensitive = true
}

# Terraform Outputs for CTFd Plugin (JSON format)
output "infrastructure_info" {
  description = "Infrastructure information for CTFd plugin consumption"
  value = jsonencode({
    vulnerable_instance = {
      id         = module.vulnerable_instance.instance_id
      public_ip  = module.vulnerable_instance.instance_public_ip
      public_dns = module.vulnerable_instance.instance_public_dns
      private_ip = module.vulnerable_instance.instance_private_ip
    }
    ctfd_instance = var.deploy_ctfd ? {
      id         = module.ctfd_instance[0].instance_id
      public_ip  = module.ctfd_instance[0].instance_public_ip
      public_dns = module.ctfd_instance[0].instance_public_dns
      url        = "http://${module.ctfd_instance[0].instance_public_ip}:8000"
    } : null
    vpc_id       = module.network.vpc_id
    subnet_id    = module.network.public_subnet_id
    region       = var.aws_region
    generated_at = timestamp()
  })
}
