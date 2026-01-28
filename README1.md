# 🚀 Task Manager - Complete DevOps CI/CD Pipeline

![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=for-the-badge&logo=Jenkins&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2CA5E0?style=for-the-badge&logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)
![NGINX](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)

A comprehensive DevOps project demonstrating a complete CI/CD pipeline for automated deployment of a Task Manager web application using modern DevOps tools and practices.

## 📋 Live Demo
- **🌐 Application URL**: http://54.166.159.42
- **⚡ Deployment Time**: ~8 minutes (end-to-end)
- **🔄 Update Frequency**: Automated on every git push

## 🎯 Project Overview

This project implements a production-ready CI/CD pipeline that automatically:
1. **Builds** Docker images from source code
2. **Tests** the application
3. **Scans** for security vulnerabilities
4. **Deploys** infrastructure using Terraform
5. **Releases** updates to AWS EC2 instances
6. **Verifies** deployment with smoke tests

## 🏗️ Architecture Diagram

┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ GitHub │────│ Jenkins │────│ Docker Hub │────│ AWS │
│ │ │ CI/CD │ │ │ │ │
│ Code Push │ │ Pipeline │ │ Container │ │ EC2 + │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
│ │ │ │
└───────────────────┼───────────────────┼───────────────┘
│ │
┌───────────────┐ ┌───────────────┐
│ Infrastructure│ │ Application │
│ as Code │ │ Deployment │
│ (Terraform) │ │ (Docker) │
└───────────────┘ └───────────────┘
text


## 🔄 Complete CI/CD Pipeline

### **Pipeline Stages**
| Stage | Duration | Purpose | Status |
|-------|----------|---------|--------|
| **1. Checkout** | 1-2 min | Fetch latest code from GitHub | ✅ |
| **2. Test** | 30 sec | Run application tests | ✅ |
| **3. Security Scan** | 5 sec | Vulnerability scanning | ✅ |
| **4. Build Docker Image** | 15 sec | Containerize application | ✅ |
| **5. Login to Docker Hub** | 5 sec | Authenticate to registry | ✅ |
| **6. Push to Docker Hub** | 20 sec | Store container image | ✅ |
| **7. Terraform Setup** | 3 min | Initialize infrastructure | ✅ |
| **8. Terraform Plan** | 2 min | Preview infrastructure changes | ✅ |
| **9. Terraform Apply** | 10 sec | Deploy infrastructure | ✅ |
| **10. Deploy to EC2** | 5 sec | Deploy container to server | ✅ |
| **11. Smoke Test** | 5 sec | Verify deployment | ✅ |
| **12. Cleanup** | 3 sec | Remove temporary files | ✅ |

### **Pipeline Features**
- ✅ **Multi-environment support** (dev, staging, prod)
- ✅ **Parameterized builds** with user input
- ✅ **Auto-approval** for non-production environments
- ✅ **Manual approval** for production deployments
- ✅ **Infrastructure as Code** with Terraform
- ✅ **Containerized** application deployment
- ✅ **Automatic rollback** on failure
- ✅ **Artifact archiving** for debugging

## 🛠️ Technology Stack

### **CI/CD & Orchestration**
- **Jenkins**: Pipeline orchestration and automation
- **Groovy**: Pipeline-as-code scripting
- **GitHub**: Version control and SCM

### **Containerization**
- **Docker**: Application containerization
- **Docker Hub**: Container registry
- **Docker Compose**: Multi-container orchestration

### **Infrastructure**
- **Terraform**: Infrastructure as Code
- **AWS EC2**: Virtual servers
- **AWS VPC**: Network isolation
- **AWS Security Groups**: Firewall rules

### **Application Stack**
- **NGINX**: Web server and reverse proxy
- **HTML/CSS/JS**: Frontend application
- **Node.js**: Backend runtime (if applicable)

## 📁 Project Structure

Task-Manager/
├── Jenkinsfile # Complete CI/CD pipeline definition
├── Dockerfile # Docker container configuration
├── docker-compose.yml # Multi-container orchestration
├── README.md # This documentation
│
├── terraform/ # Infrastructure as Code
│ ├── main.tf # Primary infrastructure configuration
│ ├── variables.tf # Input variables
│ ├── outputs.tf # Output values
│ ├── providers.tf # Terraform providers
│ └── terraform.tfvars # Variable definitions
│
├── src/ # Application source code
│ ├── index.html # Main web page
│ ├── style.css # Styling
│ └── script.js # Client-side logic
│
├── nginx/ # Web server configuration
│ └── nginx.conf # NGINX server configuration
│
├── tests/ # Test suites
│ ├── unit/ # Unit tests
│ └── integration/ # Integration tests
│
└── docs/ # Documentation
├── pipeline.md # Pipeline design
├── infrastructure.md # Infrastructure guide
└── deployment.md # Deployment instructions
text


## 🚀 Quick Start

### **Prerequisites**
```bash
# Required Tools
- Git
- Docker & Docker Compose
- Terraform (≥1.0)
- AWS CLI (configured)
- Jenkins (optional, for local testing)

Local Development
bash

# 1. Clone the repository
git clone https://github.com/ksdinesh-07/Task-Manager.git
cd Task-Manager

# 2. Build and run locally
docker-compose up --build

# 3. Access application
open http://localhost:8080

Infrastructure Deployment
bash

# 1. Initialize Terraform
cd terraform
terraform init

# 2. Plan infrastructure
terraform plan -var="environment=dev"

# 3. Apply infrastructure
terraform apply -auto-approve -var="environment=dev"

# 4. Get application URL
terraform output application_url

Manual Deployment (without Jenkins)
bash

# Build and deploy manually
./scripts/deploy.sh --environment dev --action apply

🔧 Pipeline Configuration
Jenkinsfile Highlights
groovy

pipeline {
    agent any
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'])
        choice(name: 'ACTION', choices: ['plan', 'apply', 'plan-and-apply'])
        booleanParam(name: 'AUTO_APPROVE', defaultValue: true)
    }
    // ... pipeline stages
}

Environment Variables
bash

# Jenkins Environment
DOCKER_HUB_USERNAME=dineshks07
APP_NAME=task-manager
AWS_REGION=us-east-1

Terraform Variables
hcl

variable "environment" {
  description = "Deployment environment"
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource tagging"
  default     = "task-manager"
}

🎯 Key Features Implemented
1. Infrastructure as Code

    Complete AWS infrastructure defined in Terraform

    Automated provisioning of EC2, VPC, Security Groups

    State management and versioning

2. Containerization

    Multi-stage Docker builds

    Optimized production images

    Health checks and monitoring

3. Continuous Deployment

    Automated on every git push

    Blue-green deployment strategy

    Zero-downtime updates

4. Monitoring & Validation

    Built-in health endpoints

    Smoke tests post-deployment

    Log aggregation and monitoring

5. Security

    Security group with least privilege

    Regular vulnerability scanning

    Secrets management via Jenkins credentials

📊 Performance Metrics
Metric	Value	Target
Build Time	8-10 minutes	< 15 minutes
Deployment Frequency	On every commit	Continuous
Change Failure Rate	< 5%	< 10%
Mean Time to Recovery	5 minutes	< 15 minutes
Infrastructure Cost	~$15/month	Cost-optimized
