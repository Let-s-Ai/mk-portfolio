# Personal CV/Resume Website

A sleek, responsive personal website built with **Flask** to showcase professional background, technical skills, and career roadmap. Designed as a digital CV, the site reflects a cybersecurity-focused profile with modern UI elements and dark theme aesthetics.

## Purpose

This project serves as a personal portfolio and CV hub, tailored for cybersecurity, IT infrastructure, and software engineering professionals. It presents key competencies, certifications, and experience in a clean and interactive layout.

## Key Features

- **Two-page layout**:
  - **Home Page**: Includes About Me, Contact Info, and Skills
  - **Resume Page**: Displays Education, Work Experience, and Certifications

- **Professional Design**:
  - Dark-themed UI with minimalist card components
  - Clearly structured content sections for easy readability

- **Technologies**:
  - Python + Flask Application Deployment with Terraform and Kubernetes

This project sets up a Flask application on AWS EC2 using Terraform and deploys it using Kubernetes (k3s).

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads.html) installed on your local machine
2. [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
3. An SSH key pair (public/private key) for EC2 instance access
4. Docker Hub account (to pull your application image)

## Setup Instructions

1. **Prepare SSH Key Pair**
   ```bash
   # Generate a new SSH key pair if you don't have one
   ssh-keygen -t rsa -b 4096 -f id_rsa
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review the Terraform Plan**
   ```bash
   terraform plan
   ```

4. **Apply the Terraform Configuration**
   ```bash
   terraform apply
   ```

5. **Access Your Application**
   After the deployment completes, Terraform will output the public IP address of your EC2 instance. Access your application at:
   ```
   http://<EC2_PUBLIC_IP>
   ```

## Infrastructure Details

- **EC2 Instance**: t2.micro (free tier eligible)
- **Networking**: VPC with public subnet, internet gateway, and route tables
- **Security**: Security group allowing HTTP (80) and SSH (22) access
- **Kubernetes**: k3s lightweight Kubernetes distribution
- **Application**: Deployed as a Kubernetes pod with NodePort service and Ingress

## Files

- `main.tf`: Main Terraform configuration
- `prepareEC2.bash`: Bootstrap script for EC2 instance
- `pod.yaml`: Kubernetes pod and service definitions
- `ingress.yaml`: Kubernetes ingress configuration

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

## Notes

- The EC2 instance will be accessible via SSH using the key pair specified in the Terraform configuration
- The Kubernetes dashboard is not enabled by default for security reasons
- All resources are created in the us-east-1 region by default (can be changed in `main.tf`)

## Highlights

- Contact section with email, phone, location, and website
- Skills grid featuring Automation, Full Stack Development, Security, and Investing
- Timeline of certifications and academic goals
- Logos and visual elements to highlight key achievements
