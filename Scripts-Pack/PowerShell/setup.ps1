# Initialize variables
$LOCATION = ""
$USERNAME = ""
$PREFIX = ""
$SSH_KEY = ""
$DNS_NAME = ""
$PROJECT_ROOT = "../../"  # Navigate up from Script-Pack/Powershell to SkyFall-Pack
$TFVARS_PATH = Join-Path $PROJECT_ROOT "Terraform-Pack/terraform.tfvars"

# Function to check if location is valid
function Check-Location {
    param (
        [string]$location
    )
    
    $location = $location.ToLower()
    
    # Array of valid Azure locations
    $valid_locations = @(
        "eastus",
        "eastus2",
        "westus",
        "westus2",
        "westus3",
        "northeurope",
        "westeurope",
        "southeastasia",
        "eastasia",
        "australiaeast",
        "australiasoutheast",
        "japaneast",
        "japanwest"
    )
    
    # Check if provided location exists in valid_locations
    if ($valid_locations -contains $location) {
        $script:LOCATION = $location
        return $true
    }
    
    Write-Host "`n[!] Error: Invalid Azure location provided`n" -ForegroundColor Red
    Write-Host "[*] Valid locations are:`n" -ForegroundColor Yellow
    $valid_locations | ForEach-Object { Write-Host $_ }
    exit 1
}

# Function to display usage
function Show-Usage {
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) [-l|-location <value>] [-u|-username <value>] [-n|-name <value>] [-s|-ssh <value>] [-d|-dns <value>]"
    Write-Host "All arguments are mandatory!`n"
    Write-Host "Arguments:"
    Write-Host "  -l, -location    Azure region location"
    Write-Host "  -u, -username    VM username"
    Write-Host "  -n, -name        Resource name prefix"
    Write-Host "  -s, -ssh         SSH key name"
    Write-Host "  -d, -dns         DNS name prefix for public IP`n"
    Write-Host "Example with full flags:"
    Write-Host "  $($MyInvocation.MyCommand.Name) -location westus2 -username nickvourd -name my-vm -ssh my-ssh-key -dns skyfall`n"
    Write-Host "Example with short flags:"
    Write-Host "  $($MyInvocation.MyCommand.Name) -l westus2 -u nickvourd -n my-vm -s my-ssh-key -d skyfall`n"
    exit 1
}

# Parse command line arguments
$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        { $_ -in "-l","-location" } {
            Check-Location $args[$i+1]
            $i += 2
        }
        { $_ -in "-u","-username" } {
            $USERNAME = $args[$i+1]
            $i += 2
        }
        { $_ -in "-n","-name" } {
            $PREFIX = $args[$i+1]
            $i += 2
        }
        { $_ -in "-s","-ssh" } {
            $SSH_KEY = $args[$i+1]
            $i += 2
        }
        { $_ -in "-d","-dns" } {
            $DNS_NAME = $args[$i+1]
            $i += 2
        }
        default {
            Write-Host "Error: Unknown parameter $($args[$i])" -ForegroundColor Red
            Show-Usage
        }
    }
}

# Check if all required parameters are provided
if (-not $LOCATION -or -not $USERNAME -or -not $PREFIX -or -not $SSH_KEY -or -not $DNS_NAME) {
    Write-Host "Error: All parameters are required!" -ForegroundColor Red
    Show-Usage
}

# Check if Terraform-Pack directory exists
if (-not (Test-Path (Join-Path $PROJECT_ROOT "Terraform-Pack"))) {
    Write-Host "Error: Terraform-Pack directory not found in SkyFall-Pack" -ForegroundColor Red
    exit 1
}

# Check if terraform.tfvars exists in Terraform-Pack
if (-not (Test-Path $TFVARS_PATH)) {
    Write-Host "Error: terraform.tfvars file not found in SkyFall-Pack/Terraform-Pack directory" -ForegroundColor Red
    exit 1
}

# Create the content for terraform.tfvars
$content = @"
resource_group_location = "$LOCATION"
username               = "$USERNAME"
prefix                 = "$PREFIX"
ssh_privkey           = "$SSH_KEY"
dns_name              = "$DNS_NAME"
"@

# Write content to terraform.tfvars
Set-Content -Path $TFVARS_PATH -Value $content

Write-Host "`n[+] terraform.tfvars in SkyFall-Pack/Terraform-Pack has been updated with:`n" -ForegroundColor Green
Write-Host "VM-Location: $LOCATION"
Write-Host "Username: $USERNAME"
Write-Host "Resource Prefix: $PREFIX"
Write-Host "SSH Key Name: $SSH_KEY"
Write-Host "DNS Name: $DNS_NAME`n"

# Store current location
$currentLocation = Get-Location

# Change to Terraform directory
Set-Location (Join-Path $PROJECT_ROOT "Terraform-Pack")

# Initialize Terraform
Write-Host "[*] Initializing Terraform...`n" -ForegroundColor Yellow
terraform init

# Run Terraform plan
Write-Host "`n[*] Planning Terraform deployment...`n" -ForegroundColor Yellow
terraform plan

# Ask user for confirmation before applying
$confirm = Read-Host "`nDo you want to apply the Terraform configuration? (y/n)"
if ($confirm -match '^[yY]$|^[yY][eE][sS]$') {
    Write-Host "`n[*] Applying Terraform configuration...`n" -ForegroundColor Yellow
    terraform apply -auto-approve

    # Get connection information
    Write-Host "`n[*] Getting connection information...`n" -ForegroundColor Yellow
    Write-Host "[*] Connection String:"
    terraform output connection_string
    Write-Host "`n[*] FQDN:"
    terraform output fqdn
    Write-Host "`n[*] Public IP:"
    terraform output public_ip
}
else {
    Write-Host "`n[!] Terraform apply cancelled`n" -ForegroundColor Red
}

# Return to original directory
Set-Location -Path $currentLocation