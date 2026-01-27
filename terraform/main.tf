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

# VPC module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = local.name_prefix
  cidr = "10.0.0.0/16"
  
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  
  tags = local.common_tags
}

# Security Group module
module "security_groups" {
  source = "./modules/sg"
  
  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  allowed_ips      = var.allowed_ips
  additional_ports = [80, 443, 3000]
}

# EC2 Instance module
module "ec2_instance" {
  source = "./modules/ec2"
  
  project_name    = var.project_name
  environment     = var.environment
  instance_type   = var.instance_type
  ssh_key_name    = var.ssh_key_name
  subnet_id       = module.vpc.public_subnets[0]
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

# Route53 DNS record (if domain provided)
resource "aws_route53_record" "app" {
  count = var.domain_name != "" ? 1 : 0
  
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [module.ec2_instance.public_ip]
}

data "aws_route53_zone" "selected" {
  count = var.domain_name != "" ? 1 : 0
  
  name = var.domain_name
}
