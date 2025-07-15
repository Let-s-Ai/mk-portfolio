# Create VPC using the official AWS VPC module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  
  version = "~> 5.0"

  name = "flask-app-vpc"
  cidr = "10.0.0.0/16"
  
  # Use only one AZ for cost optimization in this example
  azs             = ["us-east-1a"]
  public_subnets  = ["10.0.1.0/24"]
  private_subnets = []
  
  # Enable NAT Gateway (not strictly needed for this example but good practice)
  enable_nat_gateway = false
  single_nat_gateway = true
  
  # Enable DNS hostnames and DNS support
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Tags
  public_subnet_tags = {
    Name = "flask-app-public-subnet"
  }
  
  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}

# Get the public subnet ID for the EC2 instance
locals {
  public_subnet_id = module.vpc.public_subnets[0]
}

# Create security group with HTTP/HTTPS/SSH access
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow HTTP, HTTPS and SSH traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Monitoring"
    from_port   = 45876
    to_port     = 45876
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# Create an EC2 instance
resource "aws_instance" "flask_app" {
  ami           = "ami-0f3f13f145e66a0a3"
  instance_type = "t2.micro"
  key_name      = "dontdeleteawskey"  # Replace with your existing key pair name
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id     = local.public_subnet_id
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              set -x
              
              # Run the bootstrap script
              ${file("${path.module}/../prepareEC2.bash")}
              
              # Create Kubernetes manifests
              cat > /home/ec2-user/pod.yaml << 'EOL'
              ${file("${path.module}/../pod.yaml")}
              EOL
              
              cat > /home/ec2-user/ingress.yaml << 'EOL'
              ${file("${path.module}/../ingress.yaml")}
              EOL
              
              # Wait for k3s to be ready with a timeout (10 minutes max)
              echo "Checking if k3s is ready..."
              MAX_RETRIES=60
              COUNT=0
              
              while [ $COUNT -lt $MAX_RETRIES ]; do
                if sudo /usr/local/bin/kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get nodes 2>&1 | grep -q ' Ready '; then
                  echo "k3s is ready!"
                  break
                fi
                echo "Waiting for k3s to be ready... (Attempt $((COUNT+1))/$MAX_RETRIES)"
                COUNT=$((COUNT+1))
                sleep 10
              done
              
              if [ $COUNT -eq $MAX_RETRIES ]; then
                echo "Warning: k3s readiness check timed out. Continuing anyway..."
              fi
              
              # Set up kubeconfig for ec2-user
              mkdir -p /home/ec2-user/.kube
              sudo cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
              sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube
              
              # Replace localhost with instance private IP in kubeconfig
              PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
              sed -i "s/127.0.0.1/$PRIVATE_IP/" /home/ec2-user/.kube/config
              
              # Apply Kubernetes manifests
              export KUBECONFIG=/home/ec2-user/.kube/config
              export PATH=$PATH:/usr/local/bin
              
              # Wait for the default service account to be created
              while ! kubectl get serviceaccount default 2>/dev/null; do
                echo "Waiting for default service account..."
                sleep 5
              done
              
              # Apply the manifests
              kubectl apply -f /home/ec2-user/pod.yaml
              kubectl apply -f /home/ec2-user/ingress.yaml
              
              echo "Kubernetes manifests applied successfully!"
              EOF

  tags = {
    Name = "flask-app-server"
  }
}