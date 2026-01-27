variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "allowed_ips" {
  description = "List of allowed IPs for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_ports" {
  description = "Additional ports to open"
  type        = list(number)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
