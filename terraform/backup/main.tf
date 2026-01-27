terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 4.0" }
  }
}

provider "aws" {
  region = var.aws_region
}

# Simple Security Group
resource "aws_security_group" "app" {
  name_prefix = "task-manager-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "app" {
  ami           = "ami-026992d753d5622bc"  # Amazon Linux 2
  instance_type = var.instance_type
  key_name      = var.ssh_key_name
  subnet_id     = var.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.app.id]

  tags = {
    Name = "${var.project_name}-${var.environment}"
  }
}

output "public_ip" {
  value = aws_instance.app.public_ip
}
