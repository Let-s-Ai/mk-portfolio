#!/bin/bash
set -euxo pipefail

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Disable SELinux enforcement (avoids k3s-selinux dependency issues)
setenforce 0 || true
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# Install k3s without SELinux policy
curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_SELINUX_RPM=true sh -

# Set up kubectl for ec2-user
mkdir -p /home/ec2-user/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
sudo chown ec2-user:ec2-user /home/ec2-user/.kube/config

# Replace 127.0.0.1 with internal IP in kubeconfig
INTERNAL_IP=$(hostname -i)
sed -i "s/127.0.0.1/$INTERNAL_IP/" /home/ec2-user/.kube/config

# Add kubeconfig to ec2-user's shell environment
echo 'export KUBECONFIG=$HOME/.kube/config' >> /home/ec2-user/.bashrc