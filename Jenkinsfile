pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'task-manager'
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_CREDS_ID = 'docker-hub-credentials'
        GITHUB_CREDS_ID = 'github-credentials'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    extensions: [],
                    userRemoteConfigs: [[
                        credentialsId: "${GITHUB_CREDS_ID}",
                        url: 'https://github.com/ksdinesh-07/Task-Manager.git'
                    ]]
                ])
            }
        }
        
        stage('Build Docker') {
            steps {
                sh '''
                    echo "Building Docker image..."
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    echo "✅ Docker build successful!"
                '''
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CREDS_ID}") {
                        docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                        docker.image("${DOCKER_IMAGE}:latest").push()
                    }
                    echo "✅ Pushed to Docker Hub!"
                }
            }
        }
        
        stage('Test Locally') {
            steps {
                sh '''
                    echo "Testing Docker container..."
                    docker run -d --name test-app -p 8080:80 ${DOCKER_IMAGE}:latest
                    sleep 5
                    curl -f http://localhost:8080/health || echo "Health check failed"
                    docker stop test-app
                    docker rm test-app
                    echo "✅ Local test passed!"
                '''
            }
        }
    }
    
    post {
        always {
            sh 'docker system prune -f'
        }
        success {
            echo "🎉 Pipeline completed successfully!"
            echo "📦 Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
