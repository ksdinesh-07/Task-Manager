resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Security group for web server"
  vpc_id      = var.vpc_id
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-web-sg"
  })
}

# Default ingress rules
resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  description       = "HTTP access"
}

resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  description       = "HTTPS access"
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ips
  security_group_id = aws_security_group.web.id
  description       = "SSH access"
}

# Additional ports
resource "aws_security_group_rule" "additional_ports" {
  for_each = { for idx, port in var.additional_ports : idx => port }
  
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ips
  security_group_id = aws_security_group.web.id
  description       = "Port ${each.value} access"
}

# Egress rule
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound"
}
