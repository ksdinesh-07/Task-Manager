aws_region = "us-east-1"
environment = "dev"
project_name = "task-manager"
instance_type = "t2.micro"
ssh_key_name = "task-manager-key"

vpc_id = "vpc-0b92e1eb58c1614fb"
public_subnet_ids = ["subnet-033169dd5587e429c", "subnet-051cd7a2d21af2227"]
allowed_ips = ["0.0.0.0/0"]  # Allow all for testing

domain_name = ""
docker_image = "nginx:alpine"
