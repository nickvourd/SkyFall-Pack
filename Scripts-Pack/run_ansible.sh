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
    echo "Usage: $0 [-f|--file <keystore_filename>] [-p|--password <keystore_password>] [--port <teamserver_port>] [-c|--custom-header <header_name>] [-s|--custom-secret <secret_value>] [-l|--license <license_key>] [--cs-install-dir <remote_path>] [--http]"
    echo "Arguments -f and -p are mandatory!"
    echo ""
    echo "Arguments:"
    echo "  -f, --file <string>            Set a keystore filename"
    echo "  -p, --password <string>        Set a keystore password"
    echo "  --port <int>                   Teamserver port (default: 8443)"
    echo "  -c, --custom-header <string>   Custom header name (default: X-CSRF-TOKEN)"
    echo "  -s, --custom-secret <string>   Custom secret value (default: MySecretValue)"
    echo "  -l, --license <string>         Cobalt Strike license key (triggers CS download)"
    echo "  --cs-install-dir <string>      Remote install directory for Cobalt Strike (default: /opt)"
    echo "  --http                         Use HTTP instead of HTTPS (default: false)"
    echo ""
    echo "Example with full flags:"
    echo "  $0 --file nickvourd --password mysecretpass --custom-header X-CUSTOM-HEADER --custom-secret SuperSecretValue --port 9443 --license XXXX-XXXX-XXXX-0001 --cs-install-dir /opt [--http]"
    echo ""
    echo "Example with short flags:"
    echo "  $0 -f nickvourd -p mysecretpass -c X-CUSTOM-HEADER -s SuperSecretValue --port 9443 -l XXXX-XXXX-XXXX-0001 [--http]"
    echo ""
    exit 1
}

# Function to download Cobalt Strike Linux package
download_cobalt_strike() {
    local license_key="$1"
    local download_base="https://download.cobaltstrike.com"
    local cookie_jar
    cookie_jar=$(mktemp)

    echo -e "\n[*] Starting Cobalt Strike download with license key: $license_key"

    # Temp file to capture the POST response body
    local post_body
    post_body=$(mktemp)

    # GET the download page first to establish a session cookie.
    echo "[*] Establishing session with download portal..."
    curl -s \
        --cookie-jar "$cookie_jar" \
        --cookie "$cookie_jar" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
        -H "Accept-Language: en-US,en;q=0.5" \
        -o /dev/null \
        "${download_base}/download"

    # Step 2: POST the license key using the established session cookie.
    # Capture both the response body and status/final URL.
    echo "[*] Submitting license key to download portal..."
    local post_meta
    post_meta=$(curl -s -L \
        --cookie-jar "$cookie_jar" \
        --cookie "$cookie_jar" \
        -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
        -H "Accept-Language: en-US,en;q=0.5" \
        -H "Origin: ${download_base}" \
        -H "Referer: ${download_base}/download" \
        --data-urlencode "dlkey=${license_key}" \
        -w "%{http_code}|%{url_effective}" \
        -o "$post_body" \
        "${download_base}/download")

    local http_code
    local effective_url
    http_code=$(echo "$post_meta" | cut -d'|' -f1)
    effective_url=$(echo "$post_meta" | cut -d'|' -f2)

    if [ "$http_code" -ne 200 ] && [ "$http_code" -ne 302 ]; then
        echo -e "\n[!] Error: License key submission failed (HTTP $http_code)"
        echo "[!] Please verify your license key is valid and active."
        rm -f "$cookie_jar" "$post_body"
        return 1
    fi

    echo "[+] License key accepted (HTTP $http_code)"

    # Extract the session-specific download base path from the POST response.
    local download_base_path
    download_base_path=$(grep -oE '/downloads/[a-f0-9]+/latest[0-9]+/' "$post_body" | head -n1)

    rm -f "$post_body"

    if [ -z "$download_base_path" ]; then
        echo -e "\n[!] Error: Could not extract download path from server response."
        echo "[!] Please verify your license key is valid and active."
        rm -f "$cookie_jar"
        return 1
    fi

    local download_url="${download_base}${download_base_path}cobaltstrike-dist-linux.tgz"

    # Step 4: Download the Linux package directly using the session-specific URL.
    echo "[*] Downloading Cobalt Strike Linux package..."
    local output_file="${PROJECT_ROOT}/cobaltstrike-dist-linux.tgz"

    curl -L \
        --cookie-jar "$cookie_jar" \
        --cookie "$cookie_jar" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" \
        -H "Referer: ${download_base}/download" \
        --progress-bar \
        -o "$output_file" \
        "$download_url"

    local curl_exit=$?
    rm -f "$cookie_jar"

    if [ $curl_exit -ne 0 ]; then
        echo -e "\n[!] Error: Download failed (curl exit code: $curl_exit)"
        return 1
    fi

    # Verify the downloaded file is a valid gzip/tgz archive
    if ! file "$output_file" | grep -qiE 'gzip|tar'; then
        echo -e "\n[!] Error: Downloaded file does not appear to be a valid archive."
        echo "[!] It may be an error page. Check your license key and try again."
        rm -f "$output_file"
        return 1
    fi

    echo -e "\n[+] Cobalt Strike downloaded successfully: $output_file"
    export CS_DIST_PATH="$output_file"
    return 0
}

# Parse command line arguments
KEYSTORE_FILE=""
KEYSTORE_PASS=""
TEAMSERVER_PORT="8443"       # Default port
CUSTOM_HEADER="X-CSRF-TOKEN" # Default header
CUSTOM_SECRET="MySecretValue" # Default secret
USE_HTTP=false               # Default to HTTPS
CS_LICENSE_KEY=""            # Optional Cobalt Strike license key
CS_INSTALL_DIR="/opt"        # Default remote install directory for Cobalt Strike

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

# Check if all required parameters are provided
if [ -z "$KEYSTORE_FILE" ] || [ -z "$KEYSTORE_PASS" ]; then
    echo "Error: Keystore file and password parameters are required!"
    usage
fi

# Set protocol based on USE_HTTP flag
if [ "$USE_HTTP" = true ]; then
    PROTOCOL="http"
else
    PROTOCOL="https"
fi

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo -e "\n[!] Error: Ansible is not installed\n"
    echo -e "[*] Please install Ansible using one of these methods:"
    echo "    1. Linux (apt): sudo apt install ansible"
    echo "    2. Linux (yum): sudo yum install ansible"
    echo "    3. MacOS:       brew install ansible"
    echo ""
    exit 1
fi

# If a license key was provided, download Cobalt Strike before proceeding
if [ -n "$CS_LICENSE_KEY" ]; then
    if ! command -v curl &> /dev/null; then
        echo -e "\n[!] Error: curl is not installed (required for Cobalt Strike download)\n"
        exit 1
    fi
    if ! command -v file &> /dev/null; then
        echo -e "\n[!] Error: 'file' utility is not installed (required for archive validation)\n"
        exit 1
    fi
    download_cobalt_strike "$CS_LICENSE_KEY" || exit 1
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
export PROTOCOL=$PROTOCOL
export CS_INSTALL_DIR=$CS_INSTALL_DIR

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
echo "VM IP:                $VM_IP"
echo "Username:             $VM_USER"
echo "SSH Key:              $SSH_KEY_PATH"
echo "VM FQDN:              $VM_FQDN"
echo "Keystore Filename:    $KEYSTORE_FILENAME"
echo "Keystore Password:    $KEYSTORE_PASS"
echo "Teamserver Port:      $TEAMSERVER_PORT"
echo "Custom Header:        $CUSTOM_HEADER"
echo "Custom Header Lower:  $CUSTOM_HEADER_LOWER"
echo "Custom Secret:        $CUSTOM_SECRET"
echo "Protocol:             $PROTOCOL"
if [ -n "$CS_LICENSE_KEY" ]; then
echo "CS Dist Path:         $CS_DIST_PATH"
echo "CS Install Dir:       $CS_INSTALL_DIR"
fi
echo ""

# Build the ansible-playbook command
ANSIBLE_CMD="ansible-playbook -i inventory/hosts.yml setup.yml -vv"

# If a CS archive was downloaded, pass its path and the remote install dir as extra vars
if [ -n "$CS_DIST_PATH" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e cs_dist_path='$CS_DIST_PATH' -e cs_install_dir='$CS_INSTALL_DIR'"
fi

# Run ansible playbook
eval "$ANSIBLE_CMD"
