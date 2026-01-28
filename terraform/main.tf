terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.28.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Simple security group that matches existing
resource "aws_security_group" "app" {
  name_prefix = "task-manager-"
  vpc_id      = "vpc-0b92e1eb58c1614fb"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Simple instance that matches existing
resource "aws_instance" "app" {
  ami           = "ami-026992d753d5622bc"
  instance_type = "t3.micro"
  
  key_name               = "task-manager-key"
  subnet_id              = "subnet-033169dd5587e429c"
  vpc_security_group_ids = [aws_security_group.app.id]
  
  associate_public_ip_address = true

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
    encrypted   = false
  }

  tags = {
    Name = "task-manager-dev"
  }
}

output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}

output "ec2_public_dns" {
  value = aws_instance.app.public_dns
}

output "application_url" {
  value = "http://${aws_instance.app.public_dns}"
}
