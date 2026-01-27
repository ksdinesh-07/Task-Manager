output "state_bucket" {
  description = "Terraform state bucket name"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "artifacts_bucket" {
  description = "Artifacts bucket name"
  value       = aws_s3_bucket.artifacts.bucket
}

output "lock_table" {
  description = "DynamoDB lock table name"
  value       = aws_dynamodb_table.terraform_locks.name
}
