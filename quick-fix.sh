#!/bin/bash
cd ~/Documents/devops/Task\ Manager

# Replace Terraform Plan stage with simpler version
sed -i '/stage.*Terraform Plan/,/^[[:space:]]*stage/{/stage.*Terraform Plan/{p;n;:loop; /^[[:space:]]*stage/!{N;b loop}; s/.*/        steps {\n            withCredentials([\n                aws(\n                    credentialsId: \x27aws-credentials\x27,\n                    accessKeyVariable: \x27AWS_ACCESS_KEY_ID\x27,\n                    secretKeyVariable: \x27AWS_SECRET_ACCESS_KEY\x27\n                )\n            ]) {\n                dir(\x27terraform\x27) {\n                    script {\n                        sh """\n                            echo "Running Terraform plan..."\n                            terraform plan -var=\\"environment=${params.ENVIRONMENT}\\" -var=\\"project_name=${APP_NAME}\\" -var=\\"docker_image=${DOCKER_IMAGE}:${DOCKER_TAG}\\" -out=tfplan.${BUILD_NUMBER}\n                            \n                            echo "=== PLAN SUMMARY ===\n                            terraform show -no-color tfplan.${BUILD_NUMBER} | tail -50\n                        """\n                    }\n                }\n            }\n        }/;}}' Jenkinsfile

echo "✅ Fixed!"
