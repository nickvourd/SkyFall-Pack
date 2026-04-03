#!/bin/bash

# Initialize script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../"

# Function to convert header to lowercase and replace hyphens
convert_header() {
    local header=$1
    local converted=$(echo "$header" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
    echo "$converted"
}

# Function to display usage
usage() {
    echo "Usage: $0 [-f|--file <keystore_filename>] [-p|--password <keystore_password>] [--port <teamserver_port>] [-c|--custom-header <header_name>] [-s|--custom-secret <secret_value>] [-l|--license <license_key>] [--cs-install-dir <remote_path>] [--http]"
    echo "Arguments -f and -p are mandatory (unless --http is used)!"
    echo ""
    exit 1
}

# -------------------------------
# ARGUMENT PARSING
# -------------------------------

KEYSTORE_FILE=""
KEYSTORE_PASS=""
TEAMSERVER_PORT="8443"
CUSTOM_HEADER="X-CSRF-TOKEN"
CUSTOM_SECRET="MySecretValue"
USE_HTTP=false
CS_LICENSE_KEY=""
CS_INSTALL_DIR="/opt"
CS_INSTALL_DIR_SET=false

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
        -l|--license)
            CS_LICENSE_KEY="$2"
            shift 2
            ;;
        --cs-install-dir)
            CS_INSTALL_DIR="$2"
            CS_INSTALL_DIR_SET=true
            shift 2
            ;;
        --http)
            USE_HTTP=true
            shift
            ;;
        *)
            echo "Error: Unknown parameter $1"
            usage
            ;;
    esac
done

# -------------------------------
# VALIDATION LOGIC
# -------------------------------

# If --http is used, forbid -f, -p, -l, --cs-install-dir
if [ "$USE_HTTP" = true ]; then
    if [ -n "$KEYSTORE_FILE" ] || \
       [ -n "$KEYSTORE_PASS" ] || \
       [ -n "$CS_LICENSE_KEY" ] || \
       [ "$CS_INSTALL_DIR_SET" = true ]; then

        echo -e "\n[!] Error: --http mode cannot be used with:"
        echo "    -f / --file"
        echo "    -p / --password"
        echo "    -l / --license"
        echo "    --cs-install-dir"
        echo ""
        exit 1
    fi
fi

# Require -f and -p only when NOT using HTTP
if [ "$USE_HTTP" = false ]; then
    if [ -z "$KEYSTORE_FILE" ] || [ -z "$KEYSTORE_PASS" ]; then
        echo "Error: Keystore file and password parameters are required!"
        usage
    fi
fi

# -------------------------------
# PROTOCOL
# -------------------------------

if [ "$USE_HTTP" = true ]; then
    PROTOCOL="http"
else
    PROTOCOL="https"
fi

# -------------------------------
# CHECK ANSIBLE
# -------------------------------

if ! command -v ansible &> /dev/null; then
    echo -e "\n[!] Error: Ansible is not installed\n"
    exit 1
fi

# -------------------------------
# TERRAFORM OUTPUT
# -------------------------------

cd "$PROJECT_ROOT/Terraform-Pack" || exit

export CUSTOM_HEADER_LOWER=$(convert_header "$CUSTOM_HEADER")

export VM_IP=$(terraform output -raw public_ip)
export VM_USER=$(terraform output -raw username)
export SSH_KEY_PATH="$(pwd)/$(terraform output -raw ssh_privkey).pem"
export VM_FQDN=$(terraform output -raw fqdn)

export KEYSTORE_FILENAME=$KEYSTORE_FILE
export KEYSTORE_PASSWORD=$KEYSTORE_PASS
export TEAMSERVER_PORT=$TEAMSERVER_PORT
export CUSTOM_HEADER=$CUSTOM_HEADER
export CUSTOM_SECRET=$CUSTOM_SECRET
export PROTOCOL=$PROTOCOL
export CS_INSTALL_DIR=$CS_INSTALL_DIR

# -------------------------------
# ANSIBLE
# -------------------------------

cd "$PROJECT_ROOT/Ansible-Pack" || exit

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "\n[!] Error: SSH key not found at $SSH_KEY_PATH"
    exit 1
fi

chmod 600 "$SSH_KEY_PATH"

echo -e "\n[+] Running Ansible playbook with:"
echo "Protocol:             $PROTOCOL"
echo "VM IP:                $VM_IP"
echo "Username:             $VM_USER"

if [ "$USE_HTTP" = false ]; then
    echo "Keystore Filename:    $KEYSTORE_FILE"
    echo "Keystore Password:    $KEYSTORE_PASS"
    echo "Teamserver Port:      $TEAMSERVER_PORT"
    echo "Custom Header:        $CUSTOM_HEADER"
    echo "Custom Header Lower:  $CUSTOM_HEADER_LOWER"
    echo "Custom Secret:        $CUSTOM_SECRET"
    echo "CS License Key:          $CS_LICENSE_KEY"
    echo "CS Install Dir:       $CS_INSTALL_DIR"
fi

echo ""

# Build command
ANSIBLE_CMD="ansible-playbook -i inventory/hosts.yml setup.yml -vv"

# Pass variables cleanly
ANSIBLE_CMD="$ANSIBLE_CMD \
  -e protocol='$PROTOCOL' \
  -e cs_install_dir='$CS_INSTALL_DIR'"

# Only pass CS license if present
if [ -n "$CS_LICENSE_KEY" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e cs_license_key='$CS_LICENSE_KEY'"
fi

# Only pass keystore if HTTPS mode
if [ "$USE_HTTP" = false ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD \
      -e keystore_filename='$KEYSTORE_FILE' \
      -e keystore_password='$KEYSTORE_PASS' \
      -e custom_header='$CUSTOM_HEADER' \
      -e custom_secret='$CUSTOM_SECRET' \
      -e teamserver_port='$TEAMSERVER_PORT'"
fi

# Execute
eval "$ANSIBLE_CMD"
