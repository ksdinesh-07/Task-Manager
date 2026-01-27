resource "aws_instance" "task_manager" {
  ami           = "ami-0c55b159cbfafe1f0"  # Ubuntu 22.04
  instance_type = var.instance_type
  key_name      = var.ssh_key_name
  subnet_id     = var.public_subnet_ids[0]
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  user_data = file("${path.module}/scripts/ec2-user-data.sh")
  
  tags = {
    Name = "${var.project_name}-${var.environment}"
  }
}

resource "aws_eip" "task_manager" {
  instance = aws_instance.task_manager.id
  domain   = "vpc"
}
