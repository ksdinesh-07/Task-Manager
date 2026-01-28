#!/bin/bash
echo "🔧 Fixing Jenkinsfile..."

# Backup
cp Jenkinsfile Jenkinsfile.bak

# Fix the apply command - TWO ways:

# Method 1: Remove ALL -var= parameters from apply command
sed -i '/terraform apply -auto-approve -var=.*tfplan\./s/-auto-approve -var=[^ ]* /-auto-approve /' Jenkinsfile

# Method 2: More specific fix
sed -i 's|terraform apply -auto-approve -var=environment=${params.ENVIRONMENT} -var=project_name=${APP_NAME} -var=docker_image=${DOCKER_IMAGE}:${DOCKER_TAG} tfplan.${BUILD_NUMBER}|terraform apply -auto-approve tfplan.${BUILD_NUMBER}|g' Jenkinsfile

echo "✅ Fixed!"
echo ""
echo "📝 New apply command:"
grep "terraform apply.*tfplan" Jenkinsfile
