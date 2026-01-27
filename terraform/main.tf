# Main Terraform configuration for Task Manager

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Local variables
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Terraform   = "true"
  }
}

# Use existing VPC (from variables) instead of creating new one
data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_ids)
  id    = var.public_subnet_ids[count.index]
}

# Security groups using existing VPC
module "security_groups" {
  source = "./modules/sg"
  
  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = var.vpc_id  # Use existing VPC
  allowed_ips      = var.allowed_ips
  additional_ports = [80, 443, 3000]
}

# EC2 Instance using existing VPC subnets
module "ec2_instance" {
  source = "./modules/ec2"
  
  project_name    = var.project_name
  environment     = var.environment
  instance_type   = var.instance_type
  ssh_key_name    = var.ssh_key_name
  subnet_id       = var.public_subnet_ids[0]  # Use existing subnet
  security_groups = [module.security_groups.web_sg_id]
  user_data       = file("${path.module}/scripts/ec2-user-data.sh")
  
  tags = local.common_tags
}

# IAM module for EC2 instance profile
module "iam" {
  source = "./modules/iam"
  
  project_name = var.project_name
  environment  = var.environment
}

# S3 bucket for Terraform state and artifacts
module "s3" {
  source = "./modules/s3"
  
  project_name = var.project_name
  environment  = var.environment
  region       = var.aws_region
}
