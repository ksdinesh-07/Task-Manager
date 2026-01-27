#!/bin/bash
# scripts/deploy.sh
set -e

echo "🚀 Starting deployment..."

# Configuration
APP_NAME="task-manager"
DOCKER_IMAGE="your-username/task-manager-web"
EC2_HOST="your-ec2-ip"
EC2_USER="ubuntu"
SSH_KEY="~/.ssh/your-key.pem"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function for error handling
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    command -v docker >/dev/null 2>&1 || error_exit "Docker is not installed"
    command -v docker-compose >/dev/null 2>&1 || error_exit "docker-compose is not installed"
    [ -f "Dockerfile" ] || error_exit "Dockerfile not found"
    [ -d "src" ] || error_exit "src directory not found"
    echo -e "${GREEN}✓ All prerequisites met${NC}"
}

# Build Docker image
build_image() {
    echo "Building Docker image..."
    docker build -t ${DOCKER_IMAGE}:latest -t ${DOCKER_IMAGE}:$(git rev-parse --short HEAD) . \
        || error_exit "Docker build failed"
    echo -e "${GREEN}✓ Docker image built successfully${NC}"
}

# Run tests
run_tests() {
    echo "Running tests..."
    
    # Start test container
    docker run -d --name ${APP_NAME}-test -p 8081:80 ${DOCKER_IMAGE}:latest \
        || error_exit "Failed to start test container"
    
    sleep 3
    
    # Test health endpoint
    curl -f http://localhost:8081/health || error_exit "Health check failed"
    
    # Test main page
    curl -f http://localhost:8081/ || error_exit "Main page not accessible"
    
    # Cleanup
    docker stop ${APP_NAME}-test && docker rm ${APP_NAME}-test
    
    echo -e "${GREEN}✓ All tests passed${NC}"
}

# Deploy to EC2
deploy_to_ec2() {
    echo "Deploying to EC2 instance..."
    
    # Push to Docker Hub (if needed)
    # docker push ${DOCKER_IMAGE}:latest
    
    # SSH to EC2 and deploy
    ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} << EOF
        echo "Pulling latest image..."
        docker pull ${DOCKER_IMAGE}:latest
        
        echo "Stopping existing container..."
        docker stop ${APP_NAME} || true
        docker rm ${APP_NAME} || true
        
        echo "Starting new container..."
        docker run -d \
            --name ${APP_NAME} \
            --restart unless-stopped \
            -p 80:80 \
            -p 443:443 \
            -v /opt/${APP_NAME}/nginx.conf:/etc/nginx/nginx.conf:ro \
            ${DOCKER_IMAGE}:latest
        
        echo "Cleaning up old images..."
        docker image prune -f
        
        echo "Checking deployment..."
        sleep 2
        docker ps | grep ${APP_NAME}
        curl -f http://localhost/health && echo "Deployment successful!"
EOF
    
    [ $? -eq 0 ] || error_exit "Deployment failed"
    echo -e "${GREEN}✓ Deployment completed successfully${NC}"
}

# Deploy to AWS ECS (alternative)
deploy_to_ecs() {
    echo "Deploying to AWS ECS..."
    
    # Update ECS service
    aws ecs update-service \
        --cluster ${APP_NAME}-cluster \
        --service ${APP_NAME}-service \
        --force-new-deployment \
        --region us-east-1 \
        || error_exit "ECS update failed"
    
    echo -e "${GREEN}✓ ECS service updated${NC}"
}

# Main execution
main() {
    check_prerequisites
    build_image
    run_tests
    
    # Choose deployment target
    if [ "$1" == "ec2" ]; then
        deploy_to_ec2
    elif [ "$1" == "ecs" ]; then
        deploy_to_ecs
    else
        echo "Usage: $0 {ec2|ecs}"
        exit 1
    fi
    
    echo -e "\n${GREEN}✅ Deployment completed!${NC}"
    echo "Application URL: http://${EC2_HOST}"
}

# Run main function with argument
main "$@"