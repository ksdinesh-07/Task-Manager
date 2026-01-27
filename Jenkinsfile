pipeline {
    agent any
    
    environment {
        // Docker Hub configuration
        DOCKER_HUB_USERNAME = 'dineshks07'
        APP_NAME = 'task-manager'
        DOCKER_IMAGE = "${DOCKER_HUB_USERNAME}/${APP_NAME}"
        DOCKER_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        
        // Terraform configuration
        AWS_REGION = 'us-east-1'
        TF_VAR_environment = 'dev'
        TF_VAR_project_name = 'task-manager'
        
        // Application configuration
        APP_PORT = '3000'
    }
    
    stages {
        // Stage 1: Checkout code
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        // Stage 2: Run tests
        stage('Test') {
            steps {
                sh '''
                    echo "Installing dependencies..."
                    npm install
                    echo "Running tests..."
                    npm test
                    echo "Tests completed!"
                '''
            }
            post {
                always {
                    junit 'reports/**/*.xml'  // If using Jest/Mocha test reporters
                }
            }
        }
        
        // Stage 3: Security Scan
        stage('Security Scan') {
            steps {
                sh '''
                    echo "Running security scan..."
                    # Run npm audit
                    npm audit --audit-level=high || true
                    # Docker security scan (if Trivy/Snyk available)
                    # trivy image --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${DOCKER_TAG}
                '''
            }
        }
        
        // Stage 4: Build Docker Image
        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image..."
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                '''
            }
        }
        
        // Stage 5: Login to Docker Hub
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
        
        // Stage 6: Push to Docker Hub
        stage('Push to Docker Hub') {
            steps {
                sh '''
                    echo "Pushing Docker image to Docker Hub..."
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                '''
            }
        }
        
        // Stage 7: Terraform Plan
        stage('Terraform Plan') {
            when {
                branch 'main'  // Only run on main branch
            }
            steps {
                withCredentials([
                    aws(
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    dir('terraform') {
                        sh '''
                            echo "Initializing Terraform..."
                            terraform init
                            echo "Running Terraform plan..."
                            terraform plan -out=tfplan
                        '''
                    }
                }
            }
        }
        
        // Stage 8: Manual Approval for Production
        stage('Approve Production Deployment') {
            when {
                branch 'main'
            }
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    input(
                        message: 'Deploy to production?',
                        ok: 'Deploy'
                    )
                }
            }
        }
        
        // Stage 9: Terraform Apply
        stage('Terraform Apply') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([
                    aws(
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    dir('terraform') {
                        sh '''
                            echo "Applying Terraform configuration..."
                            terraform apply -auto-approve tfplan
                            
                            # Get outputs
                            INSTANCE_IP=$(terraform output -raw instance_public_ip)
                            echo "Instance Public IP: $INSTANCE_IP"
                            echo "INSTANCE_IP=$INSTANCE_IP" > instance_ip.env
                        '''
                    }
                }
            }
        }
        
        // Stage 10: Deploy to EC2
        stage('Deploy to EC2') {
            when {
                branch 'main'
            }
            steps {
                script {
                    // Read instance IP from previous stage
                    def instanceIP = readFile('instance_ip.env').trim().split('=')[1]
                    
                    withCredentials([
                        sshUserPrivateKey(
                            credentialsId: 'ec2-ssh-key',
                            keyFileVariable: 'SSH_KEY_FILE',
                            usernameVariable: 'SSH_USER'
                        )
                    ]) {
                        sh """
                            echo "Deploying to EC2 instance: ${instanceIP}"
                            
                            # Create deployment script
                            cat > deploy.sh << 'EOF'
                            #!/bin/bash
                            # Stop existing container
                            docker stop \$(docker ps -q --filter ancestor=${DOCKER_IMAGE}) 2>/dev/null || true
                            docker rm \$(docker ps -aq --filter ancestor=${DOCKER_IMAGE}) 2>/dev/null || true
                            
                            # Pull new image
                            docker pull ${DOCKER_IMAGE}:${DOCKER_TAG}
                            
                            # Run new container
                            docker run -d \\
                                --name task-manager-app \\
                                -p 80:${APP_PORT} \\
                                -p 443:443 \\
                                --restart always \\
                                ${DOCKER_IMAGE}:${DOCKER_TAG}
                            
                            # Cleanup old images
                            docker image prune -f
                            EOF
                            
                            chmod +x deploy.sh
                            
                            # Copy and execute deployment script on EC2
                            scp -o StrictHostKeyChecking=no -i ${SSH_KEY_FILE} deploy.sh ${SSH_USER}@${instanceIP}:/tmp/
                            ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_FILE} ${SSH_USER}@${instanceIP} 'bash /tmp/deploy.sh'
                            
                            echo "Deployment completed!"
                        """
                    }
                }
            }
        }
        
        // Stage 11: Smoke Test
        stage('Smoke Test') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def instanceIP = readFile('instance_ip.env').trim().split('=')[1]
                    sh """
                        echo "Running smoke tests on ${instanceIP}..."
                        sleep 30  # Wait for application to start
                        
                        # Test HTTP endpoint
                        HTTP_STATUS=\$(curl -s -o /dev/null -w "%{http_code}" http://${instanceIP}/health)
                        if [ "\$HTTP_STATUS" = "200" ]; then
                            echo "✅ Application is running correctly!"
                        else
                            echo "❌ Application health check failed (HTTP: \$HTTP_STATUS)"
                            exit 1
                        fi
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "🎉 SUCCESS! Full CI/CD Pipeline Completed!"
            echo "📦 Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "🌐 Application URL: http://\$(cat instance_ip.env | cut -d'=' -f2)"
            echo "🔗 Docker Hub: https://hub.docker.com/r/dineshks07/task-manager"
        }
        failure {
            echo "❌ Pipeline Failed!"
            // Optional: Send notification (Slack, Email, etc.)
            // slackSend channel: '#devops', message: "Pipeline failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
        always {
            // Cleanup
            sh 'rm -f instance_ip.env deploy.sh || true'
            cleanWs()
            
            // Archive artifacts if needed
            archiveArtifacts artifacts: 'terraform/tfplan', allowEmptyArchive: true
        }
    }
}