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
                        echo "${DOCKER_PASS}" | docker login --username "${DOCKER_USER}" --password-stdin
                    '''
                }
            }
        }
        
        stage('Build & Push') {
            steps {
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                '''
            }
        }
    }
    
    post {
        success {
            echo "🎉 SUCCESS! Docker image pushed to Docker Hub!"
            echo "📦 Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "🔗 https://hub.docker.com/r/dineshks07/task-manager"
        }
    }
}
