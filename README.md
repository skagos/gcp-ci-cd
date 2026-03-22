# CI/CD Learning Project: Docker Deployment on Google Cloud VM

This project demonstrates a complete CI/CD pipeline for deploying a simple web application using Docker, GitHub Actions, Docker Hub, and Google Cloud Platform (GCP). The goal is to learn the full CI/CD lifecycle by automating the build, push, and deployment process.

## Overview

- **Infrastructure**: Free-tier VM on Google Cloud using Terraform
- **Containerization**: Docker for application packaging
- **Automation**: GitHub Actions for CI/CD
- **Registry**: Docker Hub for image storage
- **Deployment**: Watchtower for automatic updates on the VM
- **Domain**: Connecting VM public IP to a custom domain

## Prerequisites

- Google Cloud account (free tier)
- Docker Hub account
- GitHub repository
- Basic knowledge of Docker, Terraform, and Git

## Step-by-Step Guide

### Step 1: Create Free VM on Google Cloud with Terraform

1. **Create Google Cloud Account**: Sign up at [cloud.google.com](https://cloud.google.com) and enable free tier.

2. **Set up Google Cloud Shell**:
   ```bash
   gcloud iam service-accounts create terraform-sa --display-name="Terraform Service Account"
   ```

3. **Check Terraform Version**:
   ```bash
   terraform version
   ```

4. **Create Project Directory**:
   ```bash
   mkdir gcp-vm-terraform
   cd gcp-vm-terraform
   ```

5. **Create Terraform Configuration** (`main.tf`):
   ```hcl
   provider "google" {
     project = "YOUR_PROJECT_ID"  # Replace with your project ID
     region  = "us-central1"
     zone    = "us-central1-a"
   }

   resource "google_compute_instance" "vm_instance" {
     name         = "docker-vm"
     machine_type = "e2-micro"  # Free tier eligible

     boot_disk {
       initialize_params {
         image = "debian-cloud/debian-11"
       }
     }

     network_interface {
       network = "default"
       access_config {
         # Assigns a public IP
       }
     }

     metadata = {
       ssh-keys = "YOUR_USERNAME:YOUR_SSH_PUBLIC_KEY"  # Replace with your SSH key
     }

     tags = ["http-server", "https-server"]
   }
   ```

6. **Get Project ID**:
   ```bash
   gcloud config get-value project
   ```

7. **Generate SSH Key**:
   ```bash
   ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -N ""
   cat ~/.ssh/id_rsa.pub
   ```

8. **Update main.tf with SSH Key**:
   Replace `YOUR_USERNAME:YOUR_SSH_PUBLIC_KEY` with your username and the public key output.

9. **Initialize and Apply Terraform**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

10. **Enable Compute API if needed**:
    ```bash
    gcloud services enable compute.googleapis.com
    ```

11. **Verify VM Creation**:
    ```bash
    gcloud compute instances list
    ```

### Step 2: Enable SSH and Install Docker on VM

1. **SSH into VM**:
   ```bash
   ssh YOUR_USERNAME@VM_EXTERNAL_IP
   ```

2. **Update System**:
   ```bash
   sudo apt update
   sudo apt upgrade -y
   ```

3. **Install Docker**:
   ```bash
   sudo apt install -y docker.io
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo usermod -aG docker $USER
   ```

4. **Logout and Login Again** to apply Docker group changes.

5. **Test Docker**:
   ```bash
   docker run hello-world
   ```

### Step 3: Create Free Public Account on Docker Hub

1. Sign up at [hub.docker.com](https://hub.docker.com).
2. Create a public repository (e.g., `yourusername/your-app-name`).

### Step 4: Set Up GitHub Actions

1. **Create GitHub Repository**: Push your code to GitHub.

2. **Create GitHub Secrets**:
   - Go to repository Settings > Secrets and variables > Actions
   - Add `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`

3. **Create Workflow File** (`.github/workflows/docker.yml`):
   ```yaml
   name: Build and Push Docker Image

   on:
     push:
       tags:
         - 'v*.*.*'

   jobs:
     build-and-push:
       runs-on: ubuntu-latest

       steps:
       - name: Checkout code
         uses: actions/checkout@v3

       - name: Login to Docker Hub
         uses: actions/docker/login-action@v2
         with:
           username: ${{ secrets.DOCKERHUB_USERNAME }}
           password: ${{ secrets.DOCKERHUB_TOKEN }}

       - name: Build and push Docker image
         uses: actions/docker/build-push-action@v4
         with:
           context: .
           push: true
           tags: yourusername/your-app-name:latest,yourusername/your-app-name:${{ github.ref_name }}
   ```

### Step 5: Test Manual Deployment

1. **Tag and Push to GitHub**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Check GitHub Actions**: Ensure the workflow builds and pushes the image.

3. **Pull and Run on VM**:
   ```bash
   ssh YOUR_USERNAME@VM_EXTERNAL_IP
   docker pull yourusername/your-app-name:latest
   docker run -d -p 80:80 --name test-app yourusername/your-app-name:latest
   ```

4. **Open Firewall for HTTP**:
   ```bash
   gcloud compute firewall-rules create allow-http \
     --allow tcp:80 \
     --source-ranges=0.0.0.0/0 \
     --target-tags=http-server \
     --description="Allow HTTP traffic on port 80"

   gcloud compute instances add-tags docker-vm \
     --zone=us-central1-a \
     --tags=http-server
   ```

5. **Access App**: Visit `http://VM_EXTERNAL_IP` in browser.

### Step 6: Set Up Watchtower for Automation

1. **Run Watchtower on VM**:
   ```bash
   docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower yourusername/your-app-name --interval 30
   ```

2. **Create Update Script** (`~/scripts/update_container.sh`):
   ```bash
   #!/bin/bash

   CONTAINER_NAME="test-app"
   IMAGE_NAME="yourusername/your-app-name:latest"

   # Stop & remove if exists
   if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
     docker stop $CONTAINER_NAME
     docker rm $CONTAINER_NAME
   fi

   # Pull latest image
   docker pull $IMAGE_NAME

   # Run container
   docker run -d --name $CONTAINER_NAME -p 80:80 $IMAGE_NAME
   ```

3. **Make Script Executable**:
   ```bash
   chmod +x ~/scripts/update_container.sh
   ```

4. **Set Up Cron Job** (optional alternative to Watchtower):
   ```bash
   crontab -e
   # Add: */30 * * * * /home/YOUR_USERNAME/scripts/update_container.sh >> /home/YOUR_USERNAME/scripts/update.log 2>&1
   ```

### Step 7: Connect VM Public IP to Domain

1. **Purchase Domain**: Use a registrar like Namecheap or GoDaddy.

2. **Configure DNS**: Point your domain's A record to the VM's external IP.

3. **Test**: Access your app via the domain.

## Application Structure

- `Dockerfile`: Defines the Docker image for the web app
- `app/index.html`: Simple HTML page served by the app
- `.github/workflows/docker.yml`: GitHub Actions workflow

## Usage

1. Make changes to your app code.
2. Commit and tag a new version: `git tag v1.0.1 && git push origin v1.0.1`
3. GitHub Actions will build and push the Docker image.
4. Watchtower will automatically pull and deploy the new image on your VM.

## Troubleshooting

- Ensure firewall rules allow traffic on port 80.
- Check Docker Hub for image availability.
- Verify SSH keys are correctly configured.
- Monitor GitHub Actions logs for build issues.

## Cleanup

To destroy the VM:
```bash
terraform destroy
```

## Learning Outcomes

This project covers:
- Infrastructure as Code with Terraform
- Containerization with Docker
- CI/CD with GitHub Actions
- Automated deployment with Watchtower
- Cloud resource management on GCP
- Domain configuration