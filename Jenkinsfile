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
                        echo "Logging into Docker Hub..."
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
                '''
            }
        }
        
        stage('Clean Previous Containers') {
            steps {
                sh '''
                    echo "Cleaning up any previous containers..."
                    docker stop test-app 2>/dev/null || true
                    docker rm test-app 2>/dev/null || true
                    echo "✅ Cleanup completed"
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                    echo "Testing the image..."
                    # Use random port to avoid conflicts
                    TEST_PORT=$((8080 + RANDOM % 100))
                    echo "Using port: $TEST_PORT"
                    
                    docker run -d --name test-app -p ${TEST_PORT}:80 ${DOCKER_IMAGE}:latest
                    sleep 5
                    
                    if curl -f http://localhost:${TEST_PORT}/health; then
                        echo "✅ Application is healthy!"
                    else
                        echo "❌ Health check failed"
                    fi
                    
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
        always {
            sh '''
                echo "Final cleanup..."
                docker stop test-app 2>/dev/null || true
                docker rm test-app 2>/dev/null || true
            '''
        }
    }
}
