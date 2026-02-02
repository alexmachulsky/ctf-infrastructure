output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.main.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.main.public_dns
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.main.private_ip
}

output "ami_id" {
  description = "ID of the created AMI (if create_ami is true)"
  value       = var.create_ami ? aws_ami_from_instance.vulnerable_ami[0].id : null
}

output "ami_name" {
  description = "Name of the created AMI (if create_ami is true)"
  value       = var.create_ami ? aws_ami_from_instance.vulnerable_ami[0].name : null
}
