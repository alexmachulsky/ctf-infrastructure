# Network Module - VPC, Subnets, Security Groups

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
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

variable "availability_zone" {
  description = "AWS availability zone"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_icmp_cidr" {
  description = "CIDR blocks allowed to ping instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
