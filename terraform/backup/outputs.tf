output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2_instance.instance_id
}

output "ec2_public_ip" {
  description = "EC2 instance public IP"
  value       = module.ec2_instance.public_ip
}

output "ec2_public_dns" {
  description = "EC2 instance public DNS"
  value       = module.ec2_instance.public_dns
}

output "ec2_private_ip" {
  description = "EC2 instance private IP"
  value       = module.ec2_instance.private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.security_groups.web_sg_id
}

output "security_group_name" {
  description = "Security group name"
  value       = module.security_groups.web_sg_name
}

output "application_url" {
  description = "Application URL"
  value       = "http://${module.ec2_instance.public_ip}"
}

output "ssh_connection_string" {
  description = "SSH connection string"
  value       = "ssh -i ${var.ssh_key_name}.pem ec2-user@${module.ec2_instance.public_ip}"
}

output "s3_state_bucket" {
  description = "S3 bucket name for Terraform state"
  value       = module.s3.state_bucket
}

output "s3_artifacts_bucket" {
  description = "S3 bucket name for artifacts"
  value       = module.s3.artifacts_bucket
}

output "dynamodb_lock_table" {
  description = "DynamoDB lock table name"
  value       = module.s3.lock_table
}

output "route53_record" {
  description = "Route53 record (if domain was configured)"
  value       = var.domain_name != "" ? "${var.domain_name} -> ${module.ec2_instance.public_ip}" : "No domain configured"
}

output "jenkins_url" {
  description = "Jenkins URL (if Jenkins was deployed)"
  value       = var.deploy_jenkins ? "http://${module.ec2_instance.public_ip}:8080" : "Jenkins not deployed"
}
