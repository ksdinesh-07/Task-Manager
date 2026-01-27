resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_groups
  iam_instance_profile   = var.iam_instance_profile
  
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }
  
  user_data = var.user_data
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}"
  })
}

resource "aws_eip" "main" {
  instance = aws_instance.main.id
  domain   = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-eip"
  })
}

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
