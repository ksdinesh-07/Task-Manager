# Security Group for Web Server
resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Allow HTTP/HTTPS traffic"
  vpc_id      = var.vpc_id
  
  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# Ingress rules
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP from anywhere"
  
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS from anywhere"
  
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id
  description       = "SSH from allowed IPs"
  
  cidr_ipv4   = join(",", var.allowed_ips)
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "jenkins" {
  security_group_id = aws_security_group.web.id
  description       = "Jenkins web interface"
  
  cidr_ipv4   = join(",", var.allowed_ips)
  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
}

# Egress rules
resource "aws_vpc_security_group_egress_rule" "all_traffic" {
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound traffic"
  
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
}
