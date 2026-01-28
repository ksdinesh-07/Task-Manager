#!/bin/bash
# Update Terraform Setup stage
sed -i '/stage("Terraform Setup")/,/}/c\
        stage("Terraform Setup") {\
            steps {\
                timeout(time: 2, unit: "MINUTES") {\
                    withCredentials([\
                        aws(\
                            credentialsId: "aws-credentials",\
                            accessKeyVariable: "AWS_ACCESS_KEY_ID",\
                            secretKeyVariable: "AWS_SECRET_ACCESS_KEY"\
                        )\
                    ]) {\
                        dir("terraform") {\
                            sh """\
                                echo "Initializing Terraform..."\
                                terraform init -input=false -backend=false\
                                echo "Using default workspace"\
                            """\
                        }\
                    }\
                }\
            }\
        }' Jenkinsfile
