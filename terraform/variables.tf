variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "task-manager"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "vpc-0b92e1eb58c1614fb"
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
  default     = ["subnet-033169dd5587e429c"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"  # CHANGED from t2.micro to t3.micro
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "task-manager-key"
}

variable "allowed_ips" {
  description = "List of allowed IP CIDR blocks for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 3000
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 8  # CHANGED from 20 to 8 (actual size)
}

variable "allocate_eip" {
  description = "Whether to allocate Elastic IP"
  type        = bool
  default     = false
}

variable "docker_image" {
  description = "Docker image for the application"
  type        = string
  default     = "dineshks07/task-manager:latest"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-026992d753d5622bc"
}
variable "domain_name" { default = "" }
