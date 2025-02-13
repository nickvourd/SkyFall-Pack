#!/bin/bash

# Initialize variables
LOCATION=""
USERNAME=""
PREFIX=""
SSH_KEY=""
PROJECT_ROOT="../../"  # Navigate up from Script-Pack/Bash to SkyFall-Pack
TFVARS_PATH="${PROJECT_ROOT}Terraform-Pack/terraform.tfvars"

# Function to check if location is valid
CheckLocation() {
    local location=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    
    # Array of valid Azure locations
    valid_locations=(
        "eastus"
        "eastus2"
        "westus"
        "westus2"
        "westus3"
        "northeurope"
        "westeurope"
        "southeastasia"
        "eastasia"
        "australiaeast"
        "australiasoutheast"
        "japaneast"
        "japanwest"
    )

    # Check if provided location exists in valid_locations
    for valid_location in "${valid_locations[@]}"; do
        if [ "$location" == "$valid_location" ]; then
            LOCATION="$location"
            return 0
        fi
    done

    echo -e "[!] Error: Invalid Azure location provided\n"
    echo -e "[*] Valid locations are:\n"
    printf '%s\n' "${valid_locations[@]}"
    exit 1
}

# Function to display usage
usage() {
    echo "Usage: $0 [-l|-location <value>] [-u|-username <value>] [-n|-name <value>] [-s|-ssh <value>]"
    echo "All arguments are mandatory!"
    echo ""
    echo "Arguments:"
    echo "  -l, -location    Azure region location"
    echo "  -u, -username    VM username"
    echo "  -n, -name        Resource name prefix"
    echo "  -s, -ssh         SSH key name"
    echo ""
    echo "Example with full flags:"
    echo "  $0 -location westus2 -username nickvourd -name my-vm -ssh my-ssh-key"
    echo ""
    echo "Example with short flags:"
    echo "  $0 -l westus2 -u nickvourd -n my-vm -s my-ssh-key"
    echo ""
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|-location)
            CheckLocation "$2"
            shift 2
            ;;
        -u|-username)
            USERNAME="$2"
            shift 2
            ;;
        -n|-name)
            PREFIX="$2"
            shift 2
            ;;
        -s|-ssh)
            SSH_KEY="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown parameter $1"
            usage
            ;;
    esac
done

# Check if all required parameters are provided
if [ -z "$LOCATION" ] || [ -z "$USERNAME" ] || [ -z "$PREFIX" ] || [ -z "$SSH_KEY" ]; then
    echo "Error: All parameters are required!"
    usage
fi

# Check if Terraform-Pack directory exists
if [ ! -d "${PROJECT_ROOT}Terraform-Pack" ]; then
    echo "Error: Terraform-Pack directory not found in SkyFall-Pack"
    exit 1
fi

# Check if terraform.tfvars exists in Terraform-Pack
if [ ! -f "$TFVARS_PATH" ]; then
    echo "Error: terraform.tfvars file not found in SkyFall-Pack/Terraform-Pack directory"
    exit 1
fi

# Create a temporary file
TMP_FILE=$(mktemp)

# Replace values in terraform.tfvars
cat > "$TMP_FILE" << EOF
resource_group_location = "$LOCATION"
username               = "$USERNAME"
prefix                 = "$PREFIX"
ssh_privkey           = "$SSH_KEY"
EOF

# Move temporary file to terraform.tfvars in Terraform-Pack
mv "$TMP_FILE" "$TFVARS_PATH"

echo -e "[+] terraform.tfvars in SkyFall-Pack/Terraform-Pack has been updated with:\n"
echo "VM-Location: $LOCATION"
echo "Username: $USERNAME"
echo "Resource Prefix: $PREFIX"
echo "SSH Key Name: $SSH_KEY"
echo ""