#!/bin/bash
echo "🔧 Running Terraform..."
cd terraform
terraform init
terraform apply -auto-approve

echo "⌛ Waiting for EC2 to be ready..."
sleep 30

echo "🚀 Running Ansible..."
cd ../ansible
ansible-playbook -i hosts.ini playbook.yml
