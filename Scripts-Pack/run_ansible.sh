#!/bin/bash

# Initialize script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../"

# Function to display usage
usage() {
    echo "Usage: $0 [-f|--file <keystore_filename>] [-p|--password <keystore_password>]"
    echo "All arguments are mandatory!"
    echo ""
    echo "Arguments:"
    echo "  -f, --file      Keystore filename"
    echo "  -p, --password  Keystore password"
    echo ""
    echo "Example with full flags:"
    echo "  $0 --file nickvourd --password mysecretpass"
    echo ""
    echo "Example with short flags:"
    echo "  $0 -f nickvourd -p mysecretpass"
    echo ""
    exit 1
}

# Parse command line arguments
KEYSTORE_FILE=""
KEYSTORE_PASS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            KEYSTORE_FILE="$2"
            shift 2
            ;;
        -p|--password)
            KEYSTORE_PASS="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown parameter $1"
            usage
            ;;
    esac
done

# Check if all required parameters are provided
if [ -z "$KEYSTORE_FILE" ] || [ -z "$KEYSTORE_PASS" ]; then
    echo "Error: All parameters are required!"
    usage
fi

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
export VM_FQDN=$(terraform output -raw fqdn)
export KEYSTORE_FILENAME=$KEYSTORE_FILE
export KEYSTORE_PASSWORD=$KEYSTORE_PASS

# Change to Ansible directory
cd "$PROJECT_ROOT/Ansible-Pack" || exit

# Check if the SSH key exists and has correct permissions
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "\n[!] Error: SSH key not found at $SSH_KEY_PATH"
    exit 1
fi

# Set correct permissions for SSH key
chmod 600 "$SSH_KEY_PATH"

echo -e "\n[+] Running Ansible playbook with:"
echo "VM IP: $VM_IP"
echo "Username: $VM_USER"
echo "SSH Key: $SSH_KEY_PATH"
echo "VM FQDN: $VM_FQDN"
echo "Keystore File: $KEYSTORE_FILENAME"
echo "Keystore Password: $KEYSTORE_PASS"
echo ""

# Run ansible playbook
ansible-playbook -i inventory/hosts.yml setup.yml -vv
