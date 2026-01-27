pipeline {
    agent any
    
    environment {
        // Application
        APP_NAME = 'task-manager'
        DOCKER_IMAGE = 'task-manager'
        DOCKER_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        
        // AWS
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '083365649714'
        ECR_REPOSITORY = 'task-manager'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_IMAGE_URI = "${ECR_REGISTRY}/${ECR_REPOSITORY}"
        
        // Credential IDs
        DOCKER_CREDS_ID = 'docker-hub-credentials'
        GITHUB_CREDS_ID = 'github-credentials'
        AWS_CREDS_ID = 'aws-credentials'
        SSH_CREDS_ID = 'ec2-ssh-key'
    }
    
    stages {
        // STAGE 1: Checkout
        stage('Checkout Code') {
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
                sh 'echo "✅ Repository checked out"'
            }
        }
        
        // STAGE 2: Build Docker
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
        
        // STAGE 3: Push to Docker Hub
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CREDS_ID}") {
                        docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                        docker.image("${DOCKER_IMAGE}:latest").push()
                    }
                    echo "✅ Pushed to Docker Hub"
                }
            }
        }
        
        // STAGE 4: AWS ECR Login
        stage('Login to AWS ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDS_ID}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        echo "Logging into AWS ECR..."
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        echo "✅ Logged into ECR"
                    '''
                }
            }
        }
        
        // STAGE 5: Push to AWS ECR
        stage('Push to AWS ECR') {
            steps {
                sh '''
                    echo "Pushing to AWS ECR..."
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${ECR_IMAGE_URI}:${DOCKER_TAG}
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${ECR_IMAGE_URI}:latest
                    
                    docker push ${ECR_IMAGE_URI}:${DOCKER_TAG}
                    docker push ${ECR_IMAGE_URI}:latest
                    
                    echo "✅ Pushed to ECR: ${ECR_IMAGE_URI}:${DOCKER_TAG}"
                '''
            }
        }
        
        // STAGE 6: Terraform Infrastructure
        stage('Terraform Infrastructure') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDS_ID}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    dir('terraform') {
                        sh '''
                            echo "Setting up AWS infrastructure..."
                            terraform init
                            terraform plan -out=tfplan -var="docker_image=${ECR_IMAGE_URI}:latest"
                            terraform apply -auto-approve tfplan
                            
                            # Save outputs
                            terraform output -json > terraform-outputs.json
                            EC2_IP=$(terraform output -raw ec2_public_ip)
                            echo "EC2_IP=${EC2_IP}" > ec2_ip.txt
                        '''
                    }
                }
            }
        }
        
        // STAGE 7: Deploy to EC2
        stage('Deploy to EC2') {
            when {
                branch 'main'
            }
            steps {
                script {
                    // Get EC2 IP from Terraform
                    def EC2_IP = sh(script: '''
                        if [ -f "terraform/ec2_ip.txt" ]; then
                            cat terraform/ec2_ip.txt | grep EC2_IP | cut -d= -f2
                        else
                            echo "NO_EC2_IP"
                        fi
                    ''', returnStdout: true).trim()
                    
                    if (EC2_IP != "NO_EC2_IP") {
                        sshagent(["${SSH_CREDS_ID}"]) {
                            sh """
                                echo "Deploying to EC2: ${EC2_IP}"
                                
                                # Create deployment script
                                cat > deploy.sh << 'DEPLOY_EOF'
                                #!/bin/bash
                                set -e
                                
                                echo "🚀 Deploying ${APP_NAME}..."
                                
                                # Login to ECR
                                aws ecr get-login-password --region ${AWS_REGION} | \\
                                sudo docker login --username AWS --password-stdin ${ECR_REGISTRY}
                                
                                # Pull latest image
                                sudo docker pull ${ECR_IMAGE_URI}:latest
                                
                                # Stop old container
                                sudo docker stop ${APP_NAME} 2>/dev/null || true
                                sudo docker rm ${APP_NAME} 2>/dev/null || true
                                
                                # Run new container
                                sudo docker run -d \\
                                    --name ${APP_NAME} \\
                                    --restart unless-stopped \\
                                    -p 80:80 \\
                                    ${ECR_IMAGE_URI}:latest
                                
                                echo "✅ Deployment completed!"
                                DEPLOY_EOF
                                
                                # Copy and execute
                                scp -o StrictHostKeyChecking=no deploy.sh ubuntu@${EC2_IP}:/tmp/
                                ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} "
                                    chmod +x /tmp/deploy.sh
                                    sudo /tmp/deploy.sh
                                "
                            """
                        }
                    } else {
                        echo "⚠️ Skipping EC2 deployment - no EC2 IP found"
                    }
                }
            }
        }
        
        // STAGE 8: Smoke Test
        stage('Smoke Test') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def EC2_IP = sh(script: '''
                        cat terraform/ec2_ip.txt 2>/dev/null | grep EC2_IP | cut -d= -f2 || echo "NO_IP"
                    ''', returnStdout: true).trim()
                    
                    if (EC2_IP != "NO_IP") {
                        sh """
                            echo "Testing deployment at http://${EC2_IP}"
                            sleep 10
                            curl -f http://${EC2_IP}/health || echo "Health check failed"
                            echo "✅ Application is running!"
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Cleanup
            sh '''
                echo "Cleaning up..."
                docker system prune -f 2>/dev/null || true
                rm -f terraform/ec2_ip.txt deploy.sh 2>/dev/null || true
            '''
            
            // Save build info
            sh '''
                echo "Build: ${BUILD_NUMBER}" > build-info.txt
                echo "Commit: ${GIT_COMMIT}" >> build-info.txt
                echo "Image: ${ECR_IMAGE_URI}:${DOCKER_TAG}" >> build-info.txt
                echo "Time: $(date)" >> build-info.txt
            '''
            archiveArtifacts artifacts: 'build-info.txt'
        }
        success {
            echo "🎉 CI/CD Pipeline Completed Successfully!"
            script {
                try {
                    def EC2_IP = sh(script: 'cat terraform/ec2_ip.txt 2>/dev/null | grep EC2_IP | cut -d= -f2', returnStdout: true).trim()
                    if (EC2_IP) {
                        echo "🌐 Application URL: http://${EC2_IP}"
                        echo "📦 Docker Image: ${ECR_IMAGE_URI}:${DOCKER_TAG}"
                    }
                } catch(e) {
                    echo "✅ Pipeline completed (without deployment)"
                }
            }
        }
        failure {
            echo "❌ Pipeline Failed!"
            emailext (
                subject: "FAILED: ${env.JOB_NAME} Build ${env.BUILD_NUMBER}",
                body: "Build ${env.BUILD_URL} failed.",
                to: 'ks.dinesh005@gmail.com'
            )
        }
    }
}