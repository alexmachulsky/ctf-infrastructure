# EC2 Instance
resource "aws_instance" "main" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name
  user_data              = var.user_data

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }

  tags = {
    Name    = var.instance_name
    Project = var.project_name
  }

  # Ensure instance is ready before proceeding
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

# AMI from Instance (Optional - for bonus requirement)
resource "aws_ami_from_instance" "vulnerable_ami" {
  count                   = var.create_ami ? 1 : 0
  name                    = var.ami_name
  source_instance_id      = aws_instance.main.id
  snapshot_without_reboot = false

  tags = {
    Name    = var.ami_name
    Project = var.project_name
  }

  depends_on = [aws_instance.main]
}
