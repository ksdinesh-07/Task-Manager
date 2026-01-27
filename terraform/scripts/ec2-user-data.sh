#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
mkdir -p /opt/task-manager
cd /opt/task-manager

# Use variables passed from Terraform
DOCKER_IMAGE="${docker_image}"
DOMAIN_NAME="${domain_name}"

# Create docker-compose file
cat > docker-compose.yml << DOCKEREOF
version: '3.8'
services:
  web:
    image: ${DOCKER_IMAGE:-nginx:alpine}
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    restart: unless-stopped
DOCKEREOF

# Create nginx configuration
cat > nginx.conf << NGINXEOF
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name ${DOMAIN_NAME:-_};
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files \$uri \$uri/ /index.html;
        }
        
        location /health {
            return 200 'healthy\n';
            add_header Content-Type text/plain;
        }
    }
}
NGINXEOF

# Pull and run Docker image
docker-compose pull
docker-compose up -d

echo "EC2 setup completed!"
