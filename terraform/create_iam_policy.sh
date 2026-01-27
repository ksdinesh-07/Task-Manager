#!/bin/bash
# Create IAM policy
aws iam create-policy \
  --policy-name "task-manager-dev-ec2-policy" \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:*",
          "dynamodb:*"
        ],
        "Resource": "*"
      }
    ]
  }' \
  --description "Policy for Task Manager EC2 instance"
