# Initialize script location
$SCRIPT_DIR = $PSScriptRoot
$PROJECT_ROOT = Join-Path $SCRIPT_DIR "../../"

# Function to check if Ansible is installed
function Check-Ansible {
    try {
        $null = Get-Command ansible
        return $true
    }
    catch {
        Write-Host "`n[!] Error: Ansible is not installed" -ForegroundColor Red
        Write-Host "`n[*] Please install Ansible using one of these methods:"
        Write-Host "    1. Install WSL2 and Ubuntu"
        Write-Host "    2. In WSL2 Ubuntu: sudo apt install ansible"
        Write-Host "    3. Or use Windows Package Manager: winget install RedHat.Ansible"
        Write-Host ""
        exit 1
    }
}

# Check if Ansible is installed
Check-Ansible

# Store current location
$currentLocation = Get-Location

# Change to Terraform directory to get outputs
Set-Location (Join-Path $PROJECT_ROOT "Terraform-Pack")

# Set environment variables from terraform output
$env:VM_IP = terraform output -raw public_ip
$env:VM_USER = terraform output -raw username
$env:SSH_KEY_PATH = Join-Path (Get-Location) "$(terraform output -raw ssh_privkey).pem"

# Change to Ansible directory
Set-Location (Join-Path $PROJECT_ROOT "Ansible-Pack")

# Check if the SSH key exists
if (-not (Test-Path $env:SSH_KEY_PATH)) {
    Write-Host "`n[!] Error: SSH key not found at $($env:SSH_KEY_PATH)" -ForegroundColor Red
    exit 1
}

# Set correct permissions for SSH key using icacls
icacls $env:SSH_KEY_PATH /inheritance:r
icacls $env:SSH_KEY_PATH /grant:r "$($env:USERNAME):(R)"

Write-Host "`n[*] Running Ansible playbook with:" -ForegroundColor Yellow
Write-Host "VM IP: $($env:VM_IP)"
Write-Host "Username: $($env:VM_USER)"
Write-Host "SSH Key: $($env:SSH_KEY_PATH)"
Write-Host ""

# Run ansible playbook
ansible-playbook -i inventory/hosts.yml setup.yml -v

# Return to original directory
Set-Location $currentLocation
