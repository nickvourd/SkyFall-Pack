#!/bin/bash

# Initialize variables
LOCATION=""
USERNAME=""
PREFIX=""
SSH_KEY=""
DNS_NAME=""
PROJECT_ROOT="../"  # Navigate up from Script-Pack/ to SkyFall-Pack
TFVARS_PATH="${PROJECT_ROOT}Terraform-Pack/terraform.tfvars"

# Function to check if Azure CLI is installed
CheckAzureCLI() {
   if ! command -v az &> /dev/null; then
       echo -e "\n[!] Error: Azure CLI is not installed\n"
       echo -e "[*] Please install Azure CLI using one of these methods:"
       echo "    1. Linux (apt): sudo apt install azure-cli -y"
       echo "    2. Linux (yum): sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc"
       echo "    3. MacOS: brew install azure-cli"
       echo "    4. Download from: https://docs.microsoft.com/cli/azure/install-azure-cli"
       echo ""
       exit 1
   fi

   # Check if user is logged in to Azure
   if ! az account show &> /dev/null; then
       echo -e "\n[!] Error: Not logged in to Azure\n"
       echo -e "[*] Please login to Azure using:"
       echo "    az login"
       echo ""
       exit 1
   fi
}

# Function to check if Terraform is installed
CheckTerraform() {
   if ! command -v terraform &> /dev/null; then
       echo -e "\n[!] Error: Terraform is not installed\n"
       echo -e "[*] Please install Terraform using one of these methods:"
       echo "    1. Linux (apt): sudo apt install terraform -y"
       echo "    2. Linux (yum): sudo yum install terraform"
       echo "    3. MacOS: brew install terraform"
       echo "    4. Download from: https://www.terraform.io/downloads"
       echo ""
       exit 1
   fi
}

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
   
   echo -e "\n[!] Error: Invalid Azure location provided\n"
   echo -e "[*] Valid locations are:\n"
   printf '%s\n' "${valid_locations[@]}"
   echo ""
   exit 1
}

# Function to display usage
usage() {
   echo "Usage: $0 [-l|-location <value>] [-u|-username <value>] [-n|-name <value>] [-s|-ssh <value>] [-d|-dns <value>]"
   echo "All arguments are mandatory!"
   echo ""
   echo "Arguments:"
   echo "  -l, -location    Azure region location"
   echo "  -u, -username    VM username"
   echo "  -n, -name        Resource name prefix"
   echo "  -s, -ssh         SSH key name"
   echo "  -d, -dns         DNS name prefix for public IP"
   echo ""
   echo "Example with full flags:"
   echo "  $0 -location westus2 -username nickvourd -name rt -ssh my-ssh-key -dns skyfall"
   echo ""
   echo "Example with short flags:"
   echo "  $0 -l westus2 -u nickvourd -n rt -s my-ssh-key -d skyfall"
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
       -d|-dns)
           DNS_NAME="$2"
           shift 2
           ;;
       *)
           echo "Error: Unknown parameter $1"
           usage
           ;;
   esac
done

# Check if all required parameters are provided
if [ -z "$LOCATION" ] || [ -z "$USERNAME" ] || [ -z "$PREFIX" ] || [ -z "$SSH_KEY" ] || [ -z "$DNS_NAME" ]; then
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
dns_name              = "$DNS_NAME"
EOF

# Move temporary file to terraform.tfvars in Terraform-Pack
mv "$TMP_FILE" "$TFVARS_PATH"

echo -e "[+] terraform.tfvars in SkyFall-Pack/Terraform-Pack has been updated with:\n"
echo "VM-Location: $LOCATION"
echo "Username: $USERNAME"
echo "Resource Prefix: $PREFIX"
echo "SSH Key Name: $SSH_KEY"
echo "DNS Name: $DNS_NAME"
echo ""

# Store current location
CURRENT_DIR=$(pwd)

# Change to Terraform directory
cd "${PROJECT_ROOT}Terraform-Pack" || exit

# Initialize Terraform
echo -e "[*] Initializing Terraform...\n"
terraform init

# Run Terraform plan
echo -e "\n[*] Planning Terraform deployment...\n"
terraform plan

# Applying Terraform configuration
echo -e "\n[*] Applying Terraform configuration...\n"
terraform apply -auto-approve

# Get connection information
echo -e "\n[*] Getting connection information...\n"
echo -e "[*] Connection String:"
terraform output connection_string
echo -e "\n[*] FQDN:"
terraform output fqdn
echo -e "\n[*] Public IP:"
terraform output public_ip
echo -e "\n[*] Username:"
terraform output username
echo ""

# Return to original directory
cd "$CURRENT_DIR" || exit
