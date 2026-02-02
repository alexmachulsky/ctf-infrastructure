# Compute Module - EC2 Instances

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the instance (Ubuntu 22.04)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "Subnet ID where instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "key_name" {
  description = "Name of SSH key pair"
  type        = string
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = ""
}

variable "create_ami" {
  description = "Whether to create an AMI from this instance"
  type        = bool
  default     = false
}

variable "ami_name" {
  description = "Name for the created AMI"
  type        = string
  default     = ""
}
