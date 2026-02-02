output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "vulnerable_sg_id" {
  description = "ID of the security group for vulnerable instances"
  value       = aws_security_group.vulnerable_instance.id
}

output "ctfd_sg_id" {
  description = "ID of the security group for CTFd instance"
  value       = aws_security_group.ctfd_instance.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}
