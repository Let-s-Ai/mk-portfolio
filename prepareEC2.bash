#!/bin/bash
set -euxo pipefail

# Update system
yum update -y

# Install Cloudflare
curl -fsSl https://pkg.cloudflare.com/cloudflared-ascii.repo | sudo tee /etc/yum.repos.d/cloudflared.repo
sudo yum update -y
sudo yum install cloudflared -y
sudo cloudflared service install eyJhIjoiY2RhNzc4ODRiMzkzMjBiYzU2M2IwYTFhNThhMzY5ODAiLCJ0IjoiYTZkMzU0MDktNzc0OC00ZDMyLTlhMDktZjNmZWY2NjcwNDg2IiwicyI6Ik9HSXlNVGN6TnpRdE16RXpPUzAwTVRVeUxXSTVabVV0TUdNek9UY3dZakprWkRnMSJ9


# Install Monitoring
curl -sL https://get.beszel.dev -o /tmp/install-agent.sh && chmod +x /tmp/install-agent.sh && /tmp/install-agent.sh -p 45876 -k "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO3sXiwf0H/myF5KrhbpNHGakZXnd76QJz+mKYEmVDp+"
yum install -y jq
# === Configuration ===
ZONE_NAME="kickala.com"
RECORD_NAME="aws-ddns.kickala.com"
API_TOKEN="EGZWZuM8bkBgpZv5SXACiEoypl-LuUzyyDGBTbNF"

# === Get current external IP ===
IP=$(curl -s https://api.ipify.org)

# === Get Zone ID ===
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${ZONE_NAME}" \
     -H "Authorization: Bearer ${API_TOKEN}" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')

# === Get Record ID ===
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?name=${RECORD_NAME}" \
     -H "Authorization: Bearer ${API_TOKEN}" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')

# === Get current record IP ===
CURRENT_IP=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
     -H "Authorization: Bearer ${API_TOKEN}" \
     -H "Content-Type: application/json" | jq -r '.result.content')

# === Compare and update if different ===
if [ "$IP" != "$CURRENT_IP" ]; then
  echo "IP has changed. Updating Cloudflare record..."
  curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
       -H "Authorization: Bearer ${API_TOKEN}" \
       -H "Content-Type: application/json" \
       --data "{\"type\":\"A\",\"name\":\"${RECORD_NAME}\",\"content\":\"${IP}\",\"ttl\":120,\"proxied\":false}"
else
  echo "IP is unchanged. No update needed."
fi

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