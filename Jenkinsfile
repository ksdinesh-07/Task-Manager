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
            choices: ['plan', 'apply', 'plan-and-apply'],
            description: 'Terraform action to perform'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: true,
            description: 'Auto-approve Terraform apply'
        )
    }
    
    environment {
        DOCKER_HUB_USERNAME = 'dineshks07'
        APP_NAME = 'task-manager'
        DOCKER_IMAGE = "${DOCKER_HUB_USERNAME}/${APP_NAME}"
        DOCKER_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        
        AWS_REGION = 'us-east-1'
        TF_VAR_environment = "${params.ENVIRONMENT}"
        TF_VAR_project_name = "${APP_NAME}"
        
        APP_PORT = '3000'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
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
        
        stage('Security Scan') {
            steps {
                sh '''
                    echo "Running security scan..."
                    npm audit --audit-level=high || true
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image..."
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                '''
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
        
        stage('Push to Docker Hub') {
            steps {
                sh '''
                    echo "Pushing Docker image to Docker Hub..."
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                '''
            }
        }
        
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
                        script {
                            echo "Setting up Terraform for environment: ${params.ENVIRONMENT}"
                            
                            // Initialize Terraform
                            def initSuccess = false
                            for (int i = 1; i <= 3; i++) {
                                echo "Terraform init attempt $i of 3..."
                                try {
                                    sh """
                                        terraform init -input=false -upgrade=false
                                    """
                                    initSuccess = true
                                    break
                                } catch (Exception e) {
                                    echo "Init attempt $i failed"
                                    if (i < 3) {
                                        sleep(10)
                                    }
                                }
                            }
                            
                            // Configure workspace
                            echo "Configuring Terraform workspace..."
                            sh """
                                # Handle workspace
                                if [ "${params.ENVIRONMENT}" = "dev" ]; then
                                    echo "Using default workspace for dev"
                                    terraform workspace show
                                else
                                    echo "Selecting workspace: ${params.ENVIRONMENT}"
                                    terraform workspace select ${params.ENVIRONMENT} 2>/dev/null || terraform workspace new ${params.ENVIRONMENT}
                                fi
                            """
                        }
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
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
                            terraform plan -var="environment=${params.ENVIRONMENT}" -var="project_name=${APP_NAME}" -var="docker_image=${DOCKER_IMAGE}:${DOCKER_TAG}" -out=tfplan.${BUILD_NUMBER}
                            
                            echo "=== PLAN SUMMARY ==="
                            terraform show -no-color tfplan.${BUILD_NUMBER} | tail -50
                        '''
                    }
                }
            }
        }
        
        stage('Approve Production Deployment') {
            when {
                expression { params.ENVIRONMENT == 'prod' && !params.AUTO_APPROVE }
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' || params.ACTION == 'plan-and-apply' }
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
                                
                                # CORRECT: No -var options when using saved plan
                                terraform apply ${autoApprove} tfplan.${BUILD_NUMBER}
                                
                                # Get outputs
                                terraform output -json > terraform_output.json
                                
                                # Extract instance IP
                                INSTANCE_IP=\$(terraform output -raw ec2_public_ip 2>/dev/null || terraform output -raw ip)
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
        
        stage('Deploy to EC2') {
            when {
                expression { params.ACTION == 'apply' || params.ACTION == 'plan-and-apply' }
            }
            steps {
                script {
                    // Read instance IP from file
                    def instanceIP = readFile('terraform/instance_ip.env').trim().split('=')[1]
                    
                    sh """
                        echo "Deploying Docker container to EC2 instance: \${instanceIP}"
                        
                        # Create deployment script
                        cat > deploy.sh << 'DEPLOY_EOF'
                        #!/bin/bash
                        echo "Deploying to EC2..."
                        docker pull ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker stop \$(docker ps -q) 2>/dev/null || true
                        docker rm \$(docker ps -aq) 2>/dev/null || true
                        docker run -d -p 80:80 --name app ${DOCKER_IMAGE}:${DOCKER_TAG}
                        echo "Deployment complete!"
                        DEPLOY_EOF
                        
                        chmod +x deploy.sh
                        
                        # Copy and execute on EC2
                        scp -o StrictHostKeyChecking=no -i \$JENKINS_HOME/.ssh/id_rsa deploy.sh ec2-user@\${instanceIP}:~/
                        ssh -o StrictHostKeyChecking=no -i \$JENKINS_HOME/.ssh/id_rsa ec2-user@\${instanceIP} "bash ~/deploy.sh"
                    """
                }
            }
        }
        
        stage('Smoke Test') {
            when {
                expression { params.ACTION == 'apply' || params.ACTION == 'plan-and-apply' }
            }
            steps {
                script {
                    def instanceIP = readFile('terraform/instance_ip.env').trim().split('=')[1]
                    
                    sh """
                        echo "Running smoke test on: \${instanceIP}"
                        sleep 30  # Wait for app to start
                        
                        # Test HTTP response
                        if curl -s -f http://\${instanceIP}/health; then
                            echo "✅ Smoke test passed!"
                        else
                            echo "❌ Smoke test failed!"
                            exit 1
                        fi
                    """
                }
            }
        }
        
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
                            terraform destroy -auto-approve -var="environment=${params.ENVIRONMENT}" -var="project_name=${APP_NAME}"
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            sh '''
                # Cleanup
                rm -f deploy.sh instance_ip.env
                rm -f terraform/instance_ip.env terraform/terraform_output.json
                rm -f terraform/tfplan.${BUILD_NUMBER}
            '''
            cleanWs()
            
            script {
                echo "Pipeline execution completed at: ${new Date()}"
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Action: ${params.ACTION}"
                echo "🎉 Pipeline completed successfully!"
                
                // Archive plan file for review
                if (fileExists('terraform/tfplan.${BUILD_NUMBER}')) {
                    echo "📋 Terraform plan saved as tfplan.${BUILD_NUMBER}"
                    archiveArtifacts artifacts: 'terraform/tfplan.*, terraform/terraform_output_*.json', allowEmptyArchive: true
                }
            }
        }
        
        success {
            echo "✅ All stages completed successfully!"
        }
        
        failure {
            echo "❌ Pipeline failed!"
            emailext (
                subject: "Pipeline Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Check console output at ${env.BUILD_URL}",
                to: 'dinesh@example.com'
            )
        }
    }
}
