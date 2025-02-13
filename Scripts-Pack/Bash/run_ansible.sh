#!/bin/bash

# Initialize script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../../"

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo -e "\n[!] Error: Ansible is not installed\n"
    echo -e "[*] Please install Ansible using one of these methods:"
    echo "    1. Linux (apt): sudo apt install ansible"
    echo "    2. Linux (yum): sudo yum install ansible"
    echo "    3. MacOS: brew install ansible"
    echo ""
    exit 1
fi

# Change to Terraform directory to get outputs
cd "$PROJECT_ROOT/Terraform-Pack" || exit

# Set environment variables from terraform output
export VM_IP=$(terraform output -raw public_ip)
export VM_USER=$(terraform output -raw username)
export SSH_KEY_PATH="$(pwd)/$(terraform output -raw ssh_privkey).pem"

# Change to Ansible directory
cd "$PROJECT_ROOT/Ansible-Pack" || exit

# Check if the SSH key exists and has correct permissions
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "\n[!] Error: SSH key not found at $SSH_KEY_PATH"
    exit 1
fi

# Set correct permissions for SSH key
chmod 600 "$SSH_KEY_PATH"

echo -e "\n[*] Running Ansible playbook with:"
echo "VM IP: $VM_IP"
echo "Username: $VM_USER"
echo "SSH Key: $SSH_KEY_PATH"
echo ""

# Run ansible playbook
ansible-playbook -i inventory/hosts.yml setup.yml -v
