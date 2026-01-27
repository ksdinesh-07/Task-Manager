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
  default     = ""
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
  default     = []
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "task-manager-key"
}

variable "allowed_ips" {
  description = "List of IPs allowed to access SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "docker_image" {
  description = "Docker image for the application"
  type        = string
  default     = "nginx:alpine"
}
