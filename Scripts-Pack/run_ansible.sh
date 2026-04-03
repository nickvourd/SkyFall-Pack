#!/bin/bash

# Initialize script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../"

# Function to convert header to lowercase and replace hyphens
convert_header() {
    local header=$1
    local converted
    converted=$(echo "$header" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
    echo "$converted"
}

# Function to display usage
usage() {
    echo "Usage: $0 [-f|--file <keystore_filename>] [-p|--password <keystore_password>] [--port <teamserver_port>] [-c|--custom-header <header_name>] [-s|--custom-secret <secret_value>] [-l|--license <license_key>] [--cs-install-dir <remote_path>] [--http]"
    echo "Arguments -f and -p are mandatory (unless --http is used)!"
    echo ""
    echo "Arguments:"
    echo "  -f, --file <string>            Set a keystore filename"
    echo "  -p, --password <string>        Set a keystore password"
    echo "  --port <int>                   Teamserver port (default: 8443)"
    echo "  -c, --custom-header <string>   Custom header name (default: X-CSRF-TOKEN)"
    echo "  -s, --custom-secret <string>   Custom secret value (default: MySecretValue)"
    echo "  -l, --license <string>         Cobalt Strike license key"
    echo "  --cs-install-dir <string>      Remote install directory for Cobalt Strike (default: /opt)"
    echo "  --http                         Use HTTP mode"
    echo ""
    echo "Examples:"
    echo "  HTTPS mode:"
    echo "    $0 -f nickvourd -p mysecretpass -c X-CUSTOM-HEADER -s SuperSecretValue --port 9443 -l XXXX-XXXX-XXXX-0001 --cs-install-dir /opt"
    echo ""
    echo "  HTTP mode:"
    echo "    $0 --http"
    echo ""
    exit 1
}

# Function to download Cobalt Strike Linux package
download_cobalt_strike() {
    local license_key="$1"
    local download_base="https://download.cobaltstrike.com"
    local cookie_jar
    local post_body
    local post_meta
    local http_code
    local effective_url
    local download_base_path
    local download_url
    local output_file
    local curl_exit

    cookie_jar=$(mktemp)
    post_body=$(mktemp)

    echo -e "\n[*] Starting Cobalt Strike download with license key: $license_key"

    echo "[*] Establishing session with download portal..."
    curl -s \
        --cookie-jar "$cookie_jar" \
        --cookie "$cookie_jar" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
        -H "Accept-Language: en-US,en;q=0.5" \
        -o /dev/null \
        "${download_base}/download"

    echo "[*] Submitting license key to download portal..."
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

    http_code=$(echo "$post_meta" | cut -d'|' -f1)
    effective_url=$(echo "$post_meta" | cut -d'|' -f2)

    if [ "$http_code" -ne 200 ] && [ "$http_code" -ne 302 ]; then
        echo -e "\n[!] Error: License key submission failed (HTTP $http_code)"
        echo "[!] Please verify your license key is valid and active."
        rm -f "$cookie_jar" "$post_body"
        return 1
    fi

    echo "[+] License key accepted (HTTP $http_code)"
    echo "[*] Effective URL: $effective_url"

    download_base_path=$(grep -oE '/downloads/[a-f0-9]+/latest[0-9]+/' "$post_body" | head -n1)
    rm -f "$post_body"

    if [ -z "$download_base_path" ]; then
        echo -e "\n[!] Error: Could not extract download path from server response."
        echo "[!] Please verify your license key is valid and active."
        rm -f "$cookie_jar"
        return 1
    fi

    download_url="${download_base}${download_base_path}cobaltstrike-dist-linux.tgz"
    output_file="${PROJECT_ROOT}/cobaltstrike-dist-linux.tgz"

    echo "[*] Downloading Cobalt Strike Linux package..."
    curl -L \
        --cookie-jar "$cookie_jar" \
        --cookie "$cookie_jar" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" \
        -H "Referer: ${download_base}/download" \
        --progress-bar \
        -o "$output_file" \
        "$download_url"

    curl_exit=$?
    rm -f "$cookie_jar"

    if [ $curl_exit -ne 0 ]; then
        echo -e "\n[!] Error: Download failed (curl exit code: $curl_exit)"
        return 1
    fi

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
    echo -e "[*] Please install Ansible using one of these methods:"
    echo "    1. Linux (apt): sudo apt install ansible"
    echo "    2. Linux (yum): sudo yum install ansible"
    echo "    3. MacOS:       brew install ansible"
    echo ""
    exit 1
fi

# -------------------------------
# OPTIONAL DOWNLOAD
# -------------------------------

if [ -n "$CS_LICENSE_KEY" ]; then
    if ! command -v curl &> /dev/null; then
        echo -e "\n[!] Error: curl is not installed\n"
        exit 1
    fi
    if ! command -v file &> /dev/null; then
        echo -e "\n[!] Error: 'file' utility is not installed\n"
        exit 1
    fi
    download_cobalt_strike "$CS_LICENSE_KEY" || exit 1
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
echo "SSH Key:              $SSH_KEY_PATH"
echo "VM FQDN:              $VM_FQDN"

if [ "$USE_HTTP" = false ]; then
    echo "Keystore Filename:    $KEYSTORE_FILE"
    echo "Keystore Password:    $KEYSTORE_PASS"
    echo "Teamserver Port:      $TEAMSERVER_PORT"
    echo "Custom Header:        $CUSTOM_HEADER"
    echo "Custom Header Lower:  $CUSTOM_HEADER_LOWER"
    echo "Custom Secret:        $CUSTOM_SECRET"
    echo "CS License Key:       $CS_LICENSE_KEY"
    echo "CS Install Dir:       $CS_INSTALL_DIR"
    if [ -n "$CS_DIST_PATH" ]; then
        echo "CS Dist Path:         $CS_DIST_PATH"
    fi
fi
echo ""

ANSIBLE_CMD="ansible-playbook -i inventory/hosts.yml setup.yml -vv"

ANSIBLE_CMD="$ANSIBLE_CMD \
  -e protocol='$PROTOCOL' \
  -e cs_install_dir='$CS_INSTALL_DIR'"

if [ -n "$CS_LICENSE_KEY" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD \
      -e cs_license_key='$CS_LICENSE_KEY'"
fi

if [ -n "$CS_DIST_PATH" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD \
      -e cs_dist_path='$CS_DIST_PATH'"
fi

if [ "$USE_HTTP" = false ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD \
      -e keystore_filename='$KEYSTORE_FILE' \
      -e keystore_password='$KEYSTORE_PASS' \
      -e custom_header='$CUSTOM_HEADER' \
      -e custom_secret='$CUSTOM_SECRET' \
      -e teamserver_port='$TEAMSERVER_PORT'"
fi

eval "$ANSIBLE_CMD"
