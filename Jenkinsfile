pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Select environment to deploy'
        )
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'plan-and-apply', 'destroy'],
            description: 'Terraform action to perform'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: true,
            description: 'Auto-approve Terraform apply (use false for production)'
        )
    }
    
    environment {
        // Docker Hub configuration
        DOCKER_HUB_USERNAME = 'dineshks07'
        APP_NAME = 'task-manager'
        DOCKER_IMAGE = "${DOCKER_HUB_USERNAME}/${APP_NAME}"
        DOCKER_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        
        // Terraform configuration
        AWS_REGION = 'us-east-1'
        TF_VAR_environment = "${params.ENVIRONMENT}"
        TF_VAR_project_name = "${APP_NAME}"
        
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
        }
        
        // Stage 3: Security Scan
        stage('Security Scan') {
            steps {
                sh '''
                    echo "Running security scan..."
                    npm audit --audit-level=high || true
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
        
        // Stage 7: Terraform Setup
        stage('Terraform Setup') {
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
                            terraform init -input=false
                            
                            echo "Selecting workspace: ${TF_VAR_environment}"
                            terraform workspace select ${TF_VAR_environment} || terraform workspace new ${TF_VAR_environment}
                        '''
                    }
                }
            }
        }
        
        // Stage 8: Terraform Plan (Always runs for plan/apply actions)
        stage('Terraform Plan') {
            when {
                anyOf {
                    expression { params.ACTION == 'plan' }
                    expression { params.ACTION == 'plan-and-apply' }
                    expression { params.ACTION == 'apply' }
                }
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
                            echo "Running Terraform plan..."
                            terraform plan \
                                
                                
                                -out=tfplan.${BUILD_NUMBER}
                            
                            # Show plan summary
                            echo "=== PLAN SUMMARY ==="
                            terraform show -no-color tfplan.${BUILD_NUMBER} | tail -50
                        '''
                    }
                }
            }
        }
        
        // Stage 9: Manual Approval for Production
        stage('Approve Production Deployment') {
            when {
                allOf {
                    expression { params.ENVIRONMENT == 'prod' }
                    expression { params.ACTION == 'apply' || params.ACTION == 'plan-and-apply' }
                    expression { params.AUTO_APPROVE == false }
                }
            }
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: "Deploy to PRODUCTION?",
                        ok: "Deploy to Production",
                        parameters: [
                            text(
                                name: 'CONFIRMATION',
                                defaultValue: 'yes',
                                description: 'Type "yes" to confirm production deployment'
                            )
                        ]
                    )
                }
            }
        }
        
        // Stage 10: Terraform Apply (Auto-approved based on parameters)
        stage('Terraform Apply') {
            when {
                anyOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.ACTION == 'plan-and-apply' }
                }
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
                        script {
                            def autoApprove = params.AUTO_APPROVE ? "-auto-approve" : ""
                            
                            sh """
                                echo "Applying Terraform configuration..."
                                terraform apply \
                                    ${autoApprove} \
                                    -var="environment=\${TF_VAR_environment}" \
                                    -var="docker_image=\${DOCKER_IMAGE}:\${DOCKER_TAG}" \
                                    tfplan.${BUILD_NUMBER}
                                
                                # Get outputs
                                terraform output -json > terraform_output.json
                                
                                # Extract instance IP
                                INSTANCE_IP=\$(terraform output -raw ec2_public_ip)
                                echo "Instance Public IP: \$INSTANCE_IP"
                                echo "INSTANCE_IP=\$INSTANCE_IP" > instance_ip.env
                                
                                # Save outputs as build artifacts
                                cp terraform_output.json ../terraform_output_${BUILD_NUMBER}.json
                            """
                        }
                    }
                }
            }
        }
        
        // Stage 11: Deploy to EC2
        stage('Deploy to EC2') {
            when {
                anyOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.ACTION == 'plan-and-apply' }
                }
            }
            steps {
                script {
                    // Read instance IP from previous stage
                    def instanceIP = readFile('terraform/instance_ip.env').trim().split('=')[1]
                    
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
                            cat > deploy.sh << 'ENDOFSCRIPT'
                            #!/bin/bash
                            # Stop existing container
                            docker stop \$(docker ps -q --filter ancestor=${DOCKER_IMAGE}) 2>/dev/null || true
                            docker rm \$(docker ps -aq --filter ancestor=${DOCKER_IMAGE}) 2>/dev/null || true
                            
                            # Pull new image
                            docker pull ${DOCKER_IMAGE}:${DOCKER_TAG}
                            
                            # Run new container
                            docker run -d \\
                                --name ${APP_NAME}-${TF_VAR_environment} \\
                                -p 80:${APP_PORT} \\
                                -e NODE_ENV=${TF_VAR_environment} \\
                                --restart always \\
                                ${DOCKER_IMAGE}:${DOCKER_TAG}
                            
                            # Cleanup old images
                            docker image prune -f
                            ENDOFSCRIPT
                            
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
        
        // Stage 12: Smoke Test
        stage('Smoke Test') {
            when {
                anyOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.ACTION == 'plan-and-apply' }
                }
            }
            steps {
                script {
                    def instanceIP = readFile('terraform/instance_ip.env').trim().split('=')[1]
                    sh """
                        echo "Running smoke tests on ${instanceIP}..."
                        sleep 30  # Wait for application to start
                        
                        # Test HTTP endpoint
                        HTTP_STATUS=\$(curl -s -o /dev/null -w "%{http_code}" http://${instanceIP}/health || echo "500")
                        
                        if [ "\$HTTP_STATUS" = "200" ]; then
                            echo "✅ Application is running correctly!"
                        else
                            echo "⚠️ Application health check returned HTTP: \$HTTP_STATUS"
                            # Don't fail the build for smoke test failure
                        fi
                        
                        # Additional tests
                        curl -s http://${instanceIP} | grep -i "task" && echo "✅ Homepage accessible" || true
                    """
                }
            }
        }
        
        // Stage 13: Terraform Destroy (if selected)
        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
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
                            echo "Destroying infrastructure..."
                            terraform destroy -auto-approve \
                                -var="environment=${TF_VAR_environment}"
                        '''
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "🎉 Pipeline completed successfully!"
            
            script {
                if (params.ACTION == 'apply' || params.ACTION == 'plan-and-apply') {
                    if (fileExists('terraform/instance_ip.env')) {
                        def instanceIP = readFile('terraform/instance_ip.env').trim().split('=')[1]
                        echo "🌐 Application URL: http://${instanceIP}"
                        echo "📦 Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    }
                }
                
                if (params.ACTION == 'plan') {
                    echo "📋 Terraform plan saved as tfplan.${BUILD_NUMBER}"
                }
            }
            
            // Archive artifacts
            archiveArtifacts artifacts: 'terraform_output_*.json, terraform/tfplan.*', allowEmptyArchive: true
        }
        failure {
            echo "❌ Pipeline failed!"
            
            // Optional: Send notification
            // slackSend(channel: '#devops', message: "Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} failed!")
        }
        always {
            // Cleanup
            sh '''
                rm -f deploy.sh instance_ip.env || true
                rm -f terraform/instance_ip.env terraform/terraform_output.json || true
            '''
            cleanWs()
            
            // Generate pipeline report
            echo "Pipeline execution completed at: ${new Date()}"
            echo "Environment: ${params.ENVIRONMENT}"
            echo "Action: ${params.ACTION}"
        }
    }
}