output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = try(aws_instance.task_manager.id, "")
}

output "ec2_public_ip" {
  description = "EC2 public IP address"
  value       = try(aws_eip.task_manager.public_ip, "")
}

output "ec2_public_dns" {
  description = "EC2 public DNS name"
  value       = try(aws_instance.task_manager.public_dns, "")
}

output "security_group_id" {
  description = "Web security group ID"
  value       = try(aws_security_group.web.id, "")
}

output "s3_bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = try(aws_s3_bucket.terraform_state.bucket, "")
}

output "route53_record" {
  description = "Route53 record name (if created)"
  value       = try(aws_route53_record.app[0].name, "")
  sensitive   = false
}

output "ssh_connection_string" {
  description = "SSH connection string"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ubuntu@${try(aws_eip.task_manager.public_ip, "")}"
}

output "application_url" {
  description = "Application URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${try(aws_eip.task_manager.public_ip, "")}"
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}:8080" : "http://${try(aws_eip.task_manager.public_ip, "")}:8080"
}
