pipeline {
    agent any
    
    environment {
        APP_NAME = 'task-manager'
        DOCKER_IMAGE = 'task-manager'
        DOCKER_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        DOCKER_HUB_USER = credentials('docker-hub-credentials').username
        DOCKER_HUB_PASS = credentials('docker-hub-credentials').password
    }
    
    stages {
        // STAGE 1: Checkout
        stage('Checkout Code') {
            steps {
                checkout scm
                sh 'echo "✅ Repository checked out"'
            }
        }
        
        // STAGE 2: Login to Docker Hub
        stage('Login to Docker Hub') {
            steps {
                sh '''
                    echo "Logging into Docker Hub..."
                    echo "${DOCKER_HUB_PASS}" | docker login --username "${DOCKER_HUB_USER}" --password-stdin
                    docker info
                    echo "✅ Logged into Docker Hub"
                '''
            }
        }
        
        // STAGE 3: Build Docker
        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image..."
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    
                    # Tag with Docker Hub namespace
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_HUB_USER}/${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_HUB_USER}/${DOCKER_IMAGE}:latest
                    
                    echo "✅ Docker image built"
                '''
            }
        }
        
        // STAGE 4: Push to Docker Hub
        stage('Push to Docker Hub') {
            steps {
                sh '''
                    echo "Pushing to Docker Hub..."
                    docker push ${DOCKER_HUB_USER}/${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_HUB_USER}/${DOCKER_IMAGE}:latest
                    echo "✅ Pushed to Docker Hub: ${DOCKER_HUB_USER}/${DOCKER_IMAGE}:${DOCKER_TAG}"
                '''
            }
        }
        
        // STAGE 5: Test Locally
        stage('Test Locally') {
            steps {
                sh '''
                    echo "Testing Docker container..."
                    docker run -d --name ${APP_NAME}-test -p 8080:80 ${DOCKER_HUB_USER}/${DOCKER_IMAGE}:latest
                    sleep 5
                    
                    if curl -f http://localhost:8080/health; then
                        echo "✅ Health check passed!"
                    else
                        echo "❌ Health check failed"
                    fi
                    
                    docker stop ${APP_NAME}-test
                    docker rm ${APP_NAME}-test
                '''
            }
        }
    }
    
    post {
        success {
            echo "🎉 CI Pipeline Successful!"
            echo "📦 Docker Image: ${DOCKER_HUB_USER}/${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "🔗 Docker Hub: https://hub.docker.com/r/${DOCKER_HUB_USER}/${DOCKER_IMAGE}"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}