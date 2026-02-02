# Jenkins Setup and Configuration Guide

## Overview

This guide explains how to set up Jenkins for the CTF Infrastructure automation pipeline.

## Installation

1. **Run the installation script:**
   ```bash
   sudo ./scripts/install-jenkins.sh
   ```

2. **Access Jenkins:**
   - Open your browser to `http://localhost:8080` (or `http://YOUR_SERVER_IP:8080`)
   - You'll see the "Unlock Jenkins" page

3. **Get the initial admin password:**
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

4. **Complete the setup wizard:**
   - Paste the initial admin password
   - Click "Install suggested plugins"
   - Create your first admin user
   - Configure Jenkins URL (keep default or change if needed)

## Configure AWS Credentials

Jenkins needs AWS credentials to provision infrastructure via Terraform.

1. **Go to:** Manage Jenkins → Manage Credentials
2. **Click:** (global) domain → Add Credentials
3. **Fill in:**
   - Kind: `Secret text` (for access key ID) or `Username with password`
   - Scope: `Global`
   - Username: Your AWS Access Key ID
   - Password: Your AWS Secret Access Key
   - ID: `aws-credentials` (must match Jenkinsfile)
   - Description: AWS credentials for Terraform

**Alternative: Use AWS CLI credentials file**
```bash
# Jenkins will use the credentials from the jenkins user's home
sudo cp ~/.aws/credentials /var/lib/jenkins/.aws/
sudo chown -R jenkins:jenkins /var/lib/jenkins/.aws
```

## Configure SSH Key

The pipeline needs SSH access to deploy to EC2 instances.

1. **Copy your SSH key to Jenkins user:**
   ```bash
   sudo mkdir -p /var/lib/jenkins/.ssh
   sudo cp ~/.ssh/ctf-infrastructure-key.pem /var/lib/jenkins/.ssh/
   sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh
   sudo chmod 600 /var/lib/jenkins/.ssh/ctf-infrastructure-key.pem
   ```

## Install Required Tools

Jenkins needs Terraform and AWS CLI installed on the system.

### Install Terraform

```bash
# Download and install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Install AWS CLI

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Install jq (for JSON parsing)

```bash
sudo apt-get install -y jq
```

## Create Jenkins Pipeline Job

1. **Go to:** Jenkins Dashboard → New Item
2. **Enter:**
   - Name: `CTF-Infrastructure-Pipeline`
   - Type: Pipeline
3. **Click:** OK
4. **Configure:**
   - Description: "Automated CTF infrastructure deployment pipeline"
   - Under "Pipeline":
     - Definition: `Pipeline script from SCM`
     - SCM: `Git`
     - Repository URL: `https://github.com/alexmachulsky/ctf-infrastructure.git`
     - Branch: `*/main`
     - Script Path: `Jenkinsfile`
5. **Save**

## Pipeline Parameters

The Jenkinsfile includes several parameters you can configure:

- **ACTION**: Choose between `apply` (deploy) or `destroy` (teardown)
- **AUTO_APPROVE**: Skip manual approval step (default: false)
- **DEPLOY_CTFD**: Automatically deploy CTFd after infrastructure provisioning (default: true)
- **RUN_VERIFICATION**: Run vulnerability verification script (default: true)

## Running the Pipeline

### First Deployment

1. Click "Build with Parameters"
2. Select:
   - ACTION: `apply`
   - AUTO_APPROVE: `false` (review plan first)
   - DEPLOY_CTFD: `true`
   - RUN_VERIFICATION: `true`
3. Click "Build"
4. When prompted, review the Terraform plan
5. Click "Apply Changes" to proceed

### Subsequent Deployments

You can enable AUTO_APPROVE for faster deployments after you're comfortable with the pipeline.

### Destroying Infrastructure

1. Click "Build with Parameters"
2. Select:
   - ACTION: `destroy`
   - AUTO_APPROVE: `false` (confirm before destroying)
3. Click "Build"
4. Confirm when prompted

## Pipeline Stages

The pipeline executes the following stages:

1. **Checkout**: Clone the Git repository
2. **Setup**: Verify required tools and AWS credentials
3. **Terraform Init**: Initialize Terraform working directory
4. **Terraform Plan**: Create execution plan (apply only)
5. **Approval**: Manual approval gate (if AUTO_APPROVE=false)
6. **Terraform Apply**: Provision infrastructure (apply only)
7. **Wait for Instance**: Wait for EC2 instance to be ready
8. **Deploy CTFd**: Deploy CTFd using Docker Compose
9. **Verify Vulnerability**: Run vulnerability verification script
10. **Terraform Destroy**: Destroy all infrastructure (destroy only)

## Viewing Logs

### Jenkins Build Logs
- Click on the build number in the build history
- Click "Console Output" to see full logs

### Jenkins System Logs
```bash
sudo journalctl -u jenkins -f
```

### CTFd Logs (on EC2)
```bash
ssh -i ~/.ssh/ctf-infrastructure-key.pem ubuntu@INSTANCE_IP
sudo docker-compose -f ~/docker/docker-compose.yml logs -f ctfd
```

## Troubleshooting

### Pipeline Fails at Terraform Stage

**Issue**: AWS credentials not configured
```
Error: error configuring Terraform AWS Provider: no valid credential sources
```

**Solution**: 
- Verify AWS credentials in Jenkins (Manage Credentials)
- Or copy AWS credentials to Jenkins user home:
  ```bash
  sudo cp -r ~/.aws /var/lib/jenkins/
  sudo chown -R jenkins:jenkins /var/lib/jenkins/.aws
  ```

### Pipeline Fails at Deploy CTFd Stage

**Issue**: SSH key permission denied
```
Permission denied (publickey)
```

**Solution**:
```bash
sudo cp ~/.ssh/ctf-infrastructure-key.pem /var/lib/jenkins/.ssh/
sudo chown jenkins:jenkins /var/lib/jenkins/.ssh/ctf-infrastructure-key.pem
sudo chmod 600 /var/lib/jenkins/.ssh/ctf-infrastructure-key.pem
```

### Pipeline Fails with "terraform: command not found"

**Issue**: Terraform not installed or not in PATH for Jenkins user

**Solution**:
```bash
# Verify Terraform is installed
which terraform

# If not installed, install it (see "Install Required Tools" section)

# Make sure Jenkins can find it
sudo -u jenkins terraform version
```

### Build Stuck at "Waiting for manual approval"

**Issue**: Approval notification not visible

**Solution**:
- Go to the build page
- Look for blue "Input Required" prompt
- Click on it and approve/reject

## Security Considerations

1. **Credentials Management**:
   - Never commit AWS credentials to Git
   - Use Jenkins credentials store
   - Rotate credentials regularly

2. **SSH Keys**:
   - Protect SSH private keys (600 permissions)
   - Use separate keys for different environments

3. **Auto-Approve**:
   - Only use AUTO_APPROVE in trusted environments
   - Always review Terraform plans in production

4. **Access Control**:
   - Configure Jenkins user authentication
   - Set up role-based access control (RBAC)
   - Limit who can approve deployments

## Useful Commands

```bash
# Start Jenkins
sudo systemctl start jenkins

# Stop Jenkins
sudo systemctl stop jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# Check Jenkins status
sudo systemctl status jenkins

# View Jenkins logs
sudo journalctl -u jenkins -f

# Jenkins configuration directory
ls -la /var/lib/jenkins/

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Terraform in CI/CD](https://www.terraform.io/docs/cloud/run/cli.html)
- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
