#!/bin/bash

# Initialize script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../"

# Function to convert header to lowercase and replace hyphens
convert_header() {
    local header=$1
    # Convert to lowercase and replace hyphens with underscores
    local converted=$(echo "$header" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
    echo "$converted"
}

# Function to display usage
usage() {
    echo "Usage: $0 [-f|--file <keystore_filename>] [-p|--password <keystore_password>] [--port <teamserver_port>] [-c|--custom-header <header_name>] [-s|--custom-secret <secret_value>]"
    echo "Arguments -f and -p are mandatory!"
    echo ""
    echo "Arguments:"
    echo "  -f, --file           Set a keystore filename"
    echo "  -p, --password       Set a keystore password"
    echo "      --port           Teamserver port (default: 8443)"
    echo "  -c, --custom-header  Custom header name (default: X-CSRF-TOKEN)"
    echo "  -s, --custom-secret  Custom secret value (default: MySecretValue)"
    echo ""
    echo "Example with full flags:"
    echo "  $0 --file nickvourd --password mysecretpass --port 9443 --custom-header X-Custom-Header --custom-secret MySecret123"
    echo ""
    echo "Example with short flags:"
    echo "  $0 -f nickvourd -p mysecretpass -c X-Custom-Header -s MySecret123"
    echo ""
    exit 1
}

# Parse command line arguments
KEYSTORE_FILE=""
KEYSTORE_PASS=""
TEAMSERVER_PORT="8443"  # Default port
CUSTOM_HEADER="X-CSRF-TOKEN"  # Default header
CUSTOM_SECRET="MySecretValue"  # Default secret

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
        --port)
            TEAMSERVER_PORT="$2"
            shift 2
            ;;
        -c|--custom-header)
            CUSTOM_HEADER="$2"
            shift 2
            ;;
        -s|--custom-secret)
            CUSTOM_SECRET="$2"
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
    echo "Error: Keystore file and password parameters are required!"
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

# Convert and export the custom header
export CUSTOM_HEADER_LOWER=$(convert_header "$CUSTOM_HEADER")

# Set environment variables from terraform output
export VM_IP=$(terraform output -raw public_ip)
export VM_USER=$(terraform output -raw username)
export SSH_KEY_PATH="$(pwd)/$(terraform output -raw ssh_privkey).pem"
export VM_FQDN=$(terraform output -raw fqdn)
export KEYSTORE_FILENAME=$KEYSTORE_FILE
export KEYSTORE_PASSWORD=$KEYSTORE_PASS
export TEAMSERVER_PORT=$TEAMSERVER_PORT
export CUSTOM_HEADER=$CUSTOM_HEADER
export CUSTOM_SECRET=$CUSTOM_SECRET

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
echo "Keystore Filename: $KEYSTORE_FILENAME"
echo "Keystore Password: $KEYSTORE_PASS"
echo "Teamserver Port: $TEAMSERVER_PORT"
echo "Custom Header: $CUSTOM_HEADER"
echo "Custom Header Lower: $CUSTOM_HEADER_LOWER"
echo "Custom Secret: $CUSTOM_SECRET"
echo ""

# Run ansible playbook
ansible-playbook -i inventory/hosts.yml setup.yml -vv
