variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ctf-infrastructure"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into instances"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production!
}

variable "allowed_icmp_cidr" {
  description = "CIDR blocks allowed to ping instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Name of the SSH key pair to use for instances"
  type        = string
}

variable "vulnerable_instance_type" {
  description = "EC2 instance type for vulnerable instances"
  type        = string
  default     = "t2.micro"
}

variable "ctfd_instance_type" {
  description = "EC2 instance type for CTFd instance"
  type        = string
  default     = "t2.small"
}

variable "create_vulnerable_ami" {
  description = "Whether to create an AMI from the vulnerable instance (bonus)"
  type        = bool
  default     = false
}

variable "deploy_from_ami" {
  description = "Whether to deploy an instance from the created AMI (bonus)"
  type        = bool
  default     = false
}

variable "deploy_ctfd" {
  description = "Whether to deploy CTFd instance"
  type        = bool
  default     = true
}
