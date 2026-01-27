# Backend configuration for Terraform state
# This should be configured AFTER initial terraform apply
# Uncomment and update after creating S3 bucket and DynamoDB table

/*
terraform {
  backend "s3" {
    bucket         = "task-manager-dev-tf-state"  # Update with your bucket name
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "task-manager-dev-tf-locks"  # Update with your DynamoDB table
  }
}
*/
