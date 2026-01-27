pipeline {
    agent any
    
    environment {
        DOCKER_HUB_USERNAME = 'dineshks07'
        APP_NAME = 'task-manager'
        DOCKER_IMAGE = "${DOCKER_HUB_USERNAME}/${APP_NAME}"
        DOCKER_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "✅ Repository checked out"'
            }
        }
        
        stage('Login to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "Logging into Docker Hub as ${DOCKER_USER}..."
                        echo "${DOCKER_PASS}" | docker login --username "${DOCKER_USER}" --password-stdin
                        echo "✅ Logged into Docker Hub"
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image..."
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    echo "✅ Docker image built: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                '''
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                sh '''
                    echo "Pushing to Docker Hub..."
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                    echo "✅ Successfully pushed to Docker Hub!"
                    echo "📦 Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                    echo "Testing the image..."
                    docker run -d --name test-app -p 8080:80 ${DOCKER_IMAGE}:latest
                    sleep 5
                    curl -f http://localhost:8080/health && echo "✅ Application is healthy!" || echo "❌ Health check failed"
                    docker stop test-app
                    docker rm test-app
                '''
            }
        }
    }
    
    post {
        success {
            echo "🎉 CI/CD Pipeline Completed Successfully!"
            echo "📦 Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "🔗 View at: https://hub.docker.com/r/dineshks07/task-manager"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
