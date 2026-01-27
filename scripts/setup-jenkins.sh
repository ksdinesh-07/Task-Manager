#!/bin/bash
# scripts/setup-jenkins.sh
echo "Setting up Jenkins for Task Manager..."

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create Jenkins pipeline directory
mkdir -p /var/jenkins_home/jobs/task-manager-pipeline

echo "✅ Setup completed!"
echo "Next steps:"
echo "1. Restart shell or logout/login for Docker group changes"
echo "2. Configure Jenkins pipeline with the provided Jenkinsfile"
echo "3. Set up credentials in Jenkins:"
echo "   - Docker Hub credentials"
echo "   - AWS credentials"
echo "   - SSH keys for EC2 deployment"