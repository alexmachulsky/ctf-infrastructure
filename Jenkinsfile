pipeline {
    agent any
    
    environment {
        // AWS Region
        AWS_REGION = 'ap-south-1'
        
        // Terraform variables
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
        TF_CLI_ARGS = '-no-color'
        
        // Workspace paths
        TERRAFORM_DIR = "${WORKSPACE}/terraform"
        SCRIPTS_DIR = "${WORKSPACE}/scripts"
        DOCKER_DIR = "${WORKSPACE}/docker"
        PLUGIN_DIR = "${WORKSPACE}/ctfd-plugin"
        
        // Output file for Terraform outputs
        INFRASTRUCTURE_JSON = "${WORKSPACE}/infrastructure.json"
    }
    
    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Terraform action to perform'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Auto-approve Terraform changes (skip manual approval)'
        )
        booleanParam(
            name: 'DEPLOY_CTFD',
            defaultValue: true,
            description: 'Deploy CTFd after infrastructure provisioning'
        )
        booleanParam(
            name: 'RUN_VERIFICATION',
            defaultValue: true,
            description: 'Run vulnerability verification script after deployment'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📥 Checking out code from repository...'
                checkout scm
                
                sh '''
                    echo "Repository checked out successfully"
                    echo "Branch: ${GIT_BRANCH}"
                    echo "Commit: ${GIT_COMMIT}"
                '''
            }
        }
        
        stage('Setup') {
            steps {
                echo '🔧 Setting up build environment...'
                
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'aws-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )]) {
                        // Verify required tools
                        sh '''
                            echo "Checking required tools..."
                            terraform version
                            aws --version
                            
                            echo ""
                            echo "Validating AWS credentials..."
                            aws sts get-caller-identity
                        '''
                    }
                }
            }
        }
        
        stage('Terraform Init') {
            steps {
                echo '🏗️ Initializing Terraform...'
                
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir("${TERRAFORM_DIR}") {
                        sh '''
                            terraform init -upgrade
                            terraform validate
                        '''
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                echo '📋 Creating Terraform execution plan...'
                
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir("${TERRAFORM_DIR}") {
                        sh '''
                            terraform plan -var="key_name=ctf-infrastructure-key" -var="aws_region=ap-south-1" -out=tfplan
                            
                            echo ""
                            echo "Plan saved to: terraform/tfplan"
                            echo "Resources to be created/modified/destroyed:"
                            terraform show -json tfplan | jq -r '.resource_changes[] | "  - \\(.change.actions[0]) \\(.type).\\(.name)"'
                        '''
                    }
                }
            }
        }
        
        stage('Approval') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.AUTO_APPROVE == false }
                }
            }
            steps {
                script {
                    echo '⏸️ Waiting for manual approval...'
                    
                    // Read the plan summary
                    def planSummary = sh(
                        script: "cd ${TERRAFORM_DIR} && terraform show tfplan | tail -20",
                        returnStdout: true
                    ).trim()
                    
                    input(
                        message: 'Review the Terraform plan and approve to proceed',
                        ok: 'Apply Changes',
                        submitter: 'admin',
                        parameters: [
                            text(
                                name: 'PLAN_SUMMARY',
                                defaultValue: planSummary,
                                description: 'Terraform Plan Summary'
                            )
                        ]
                    )
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                echo '🚀 Applying Terraform configuration...'
                
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir("${TERRAFORM_DIR}") {
                    sh '''
                        terraform apply -auto-approve tfplan
                        
                        echo ""
                        echo "✓ Infrastructure provisioned successfully"
                        
                        # Export outputs to JSON
                        terraform output -json > "${INFRASTRUCTURE_JSON}"
                        echo "✓ Infrastructure outputs saved to: ${INFRASTRUCTURE_JSON}"
                        
                        # Display key outputs
                        echo ""
                        echo "Key Infrastructure Details:"
                        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        
                        VULNERABLE_IP=$(terraform output -raw vulnerable_instance_public_ip 2>/dev/null || echo "N/A")
                        VULNERABLE_ID=$(terraform output -raw vulnerable_instance_id 2>/dev/null || echo "N/A")
                        VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "N/A")
                        
                        echo "Vulnerable Instance IP: ${VULNERABLE_IP}"
                        echo "Vulnerable Instance ID: ${VULNERABLE_ID}"
                        echo "VPC ID: ${VPC_ID}"
                        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    '''
                    
                    // Store outputs for later stages
                    script {
                        def infraJson = readJSON file: "${INFRASTRUCTURE_JSON}"
                        env.VULNERABLE_INSTANCE_IP = infraJson.vulnerable_instance.value.public_ip
                        env.VULNERABLE_INSTANCE_ID = infraJson.vulnerable_instance.value.id
                        env.VPC_ID = infraJson.vpc_id.value
                    }
                    }
                }
            }
        }
        
        stage('Wait for Instance') {
            when {
                expression { params.ACTION == 'apply' && params.DEPLOY_CTFD == true }
            }
            steps {
                echo '⏳ Waiting for EC2 instance to be ready...'
                
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    script {
                    sh """
                        echo "Waiting for instance ${env.VULNERABLE_INSTANCE_ID} to pass status checks..."
                        
                        for i in {1..30}; do
                            STATUS=\$(aws ec2 describe-instance-status \\
                                --instance-ids ${env.VULNERABLE_INSTANCE_ID} \\
                                --region ${AWS_REGION} \\
                                --query 'InstanceStatuses[0].InstanceStatus.Status' \\
                                --output text)
                            
                            if [ "\$STATUS" = "ok" ]; then
                                echo "✓ Instance is ready!"
                                break
                            fi
                            
                            echo "Instance status: \$STATUS (attempt \$i/30)"
                            sleep 10
                        done
                        
                        # Wait additional time for user-data script
                        echo "Waiting 60 seconds for user-data script to complete..."
                        sleep 60
                    """
                    }
                }
            }
        }
        
        stage('Deploy CTFd') {
            when {
                expression { params.ACTION == 'apply' && params.DEPLOY_CTFD == true }
            }
            steps {
                echo '🐳 Deploying CTFd with Docker Compose...'
                
                script {
                    sh """
                        # Copy infrastructure.json to plugin directory
                        cp ${INFRASTRUCTURE_JSON} ${PLUGIN_DIR}/infrastructure.json
                        
                        # Create deployment package
                        DEPLOY_PKG=\$(mktemp -d)
                        cp -r ${DOCKER_DIR}/* \${DEPLOY_PKG}/
                        cp -r ${PLUGIN_DIR} \${DEPLOY_PKG}/ctfd-plugin
                        
                        # Upload to EC2
                        echo "Uploading files to ${env.VULNERABLE_INSTANCE_IP}..."
                        ssh -i ~/.ssh/ctf-infrastructure-key.pem \\
                            -o StrictHostKeyChecking=no \\
                            ubuntu@${env.VULNERABLE_INSTANCE_IP} \\
                            'mkdir -p ~/docker'
                        
                        scp -i ~/.ssh/ctf-infrastructure-key.pem \\
                            -o StrictHostKeyChecking=no \\
                            -r \${DEPLOY_PKG}/* \\
                            ubuntu@${env.VULNERABLE_INSTANCE_IP}:~/docker/
                        
                        # Deploy on EC2
                        echo "Starting CTFd services..."
                        ssh -i ~/.ssh/ctf-infrastructure-key.pem \\
                            -o StrictHostKeyChecking=no \\
                            ubuntu@${env.VULNERABLE_INSTANCE_IP} \\
                            'cd ~/docker && sudo docker-compose up -d'
                        
                        echo "✓ CTFd deployed successfully"
                        echo "Access CTFd at: http://${env.VULNERABLE_INSTANCE_IP}:8000"
                        
                        rm -rf \${DEPLOY_PKG}
                    """
                }
            }
        }
        
        stage('Verify Vulnerability') {
            when {
                expression { params.ACTION == 'apply' && params.RUN_VERIFICATION == true }
            }
            steps {
                echo '🔍 Verifying vulnerable system configuration...'
                
                script {
                    sh """
                        # Copy verification script to EC2
                        scp -i ~/.ssh/ctf-infrastructure-key.pem \\
                            -o StrictHostKeyChecking=no \\
                            ${SCRIPTS_DIR}/verify-vulnerability.sh \\
                            ubuntu@${env.VULNERABLE_INSTANCE_IP}:/tmp/
                        
                        # Run verification
                        echo "Running verification checks..."
                        ssh -i ~/.ssh/ctf-infrastructure-key.pem \\
                            -o StrictHostKeyChecking=no \\
                            ubuntu@${env.VULNERABLE_INSTANCE_IP} \\
                            'chmod +x /tmp/verify-vulnerability.sh && sudo /tmp/verify-vulnerability.sh'
                        
                        if [ \$? -eq 0 ]; then
                            echo "✓ All verification checks passed!"
                        else
                            echo "✗ Verification failed"
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
                echo '🗑️ Destroying infrastructure...'
                
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    script {
                    if (params.AUTO_APPROVE == false) {
                        input(
                            message: 'Are you sure you want to destroy all infrastructure?',
                            ok: 'Destroy',
                            submitter: 'admin'
                        )
                    }
                    
                    dir("${TERRAFORM_DIR}") {
                        sh '''
                            terraform destroy -var="key_name=ctf-infrastructure-key" -var="aws_region=ap-south-1" -auto-approve
                            echo "✓ Infrastructure destroyed successfully"
                        '''
                    }
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completed successfully!'
            
            script {
                if (params.ACTION == 'apply') {
                    echo """
                    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    🎉 CTF Infrastructure Deployment Complete
                    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    
                    Vulnerable Instance: ${env.VULNERABLE_INSTANCE_IP}
                    Instance ID: ${env.VULNERABLE_INSTANCE_ID}
                    VPC ID: ${env.VPC_ID}
                    
                    CTFd Access: http://${env.VULNERABLE_INSTANCE_IP}:8000
                    Plugin Admin: http://${env.VULNERABLE_INSTANCE_IP}:8000/env-validator/admin
                    
                    SSH Access:
                      ssh -i ~/.ssh/ctf-infrastructure-key.pem ubuntu@${env.VULNERABLE_INSTANCE_IP}
                    
                    CTF Challenge:
                      Username: ctf
                      Password: ctfpassword123
                      Goal: Escalate to root and capture the flag
                    
                    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    """
                } else {
                    echo "Infrastructure destroyed successfully"
                }
            }
        }
        
        failure {
            echo '❌ Pipeline failed!'
            echo 'Check the logs above for error details.'
        }
        
        always {
            echo '🧹 Cleaning up...'
            
            // Archive artifacts
            archiveArtifacts artifacts: 'terraform/tfplan', allowEmptyArchive: true
            archiveArtifacts artifacts: 'infrastructure.json', allowEmptyArchive: true
            
            // Clean workspace
            sh '''
                rm -f terraform/tfplan
                rm -f infrastructure.json
            '''
        }
    }
}
