#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TFVARS_PATH = os.path.join(PROJECT_ROOT, "Terraform-Pack", "terraform.tfvars")

VALID_LOCATIONS = [
    "eastus", "eastus2", "westus", "westus2", "westus3",
    "northeurope", "westeurope", "southeastasia", "eastasia",
    "australiaeast", "australiasoutheast", "japaneast", "japanwest",
]

VALID_SIZES = [
    "standard_b1ms",
    "standard_b2s",
    "standard_b2ms",
]


def check_azure_cli():
    if subprocess.run(["which", "az"], capture_output=True).returncode != 0:
        print("\n[!] Error: Azure CLI is not installed\n")
        print("[*] Please install Azure CLI using one of these methods:")
        print("    1. Linux (apt): sudo apt install azure-cli -y")
        print("    2. Linux (yum): sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc")
        print("    3. MacOS: brew install azure-cli")
        print("    4. Download from: https://docs.microsoft.com/cli/azure/install-azure-cli")
        sys.exit(1)

    if subprocess.run(["az", "account", "show"], capture_output=True).returncode != 0:
        print("\n[!] Error: Not logged in to Azure\n")
        print("[*] Please login to Azure using:")
        print("    az login")
        sys.exit(1)


def check_terraform():
    if subprocess.run(["which", "terraform"], capture_output=True).returncode != 0:
        print("\n[!] Error: Terraform is not installed\n")
        print("[*] Please install Terraform using one of these methods:")
        print("    1. Linux (apt): sudo apt install terraform -y")
        print("    2. Linux (yum): sudo yum install terraform")
        print("    3. MacOS: brew install terraform")
        print("    4. Download from: https://www.terraform.io/downloads")
        sys.exit(1)


def validate_location(value):
    loc = value.lower()
    if loc not in VALID_LOCATIONS:
        print(f"\n[!] Error: Invalid Azure location provided\n")
        print("[*] Valid locations are:\n")
        print("\n".join(VALID_LOCATIONS))
        sys.exit(1)
    return loc


def validate_size(value):
    size = value.lower()
    if size not in VALID_SIZES:
        print(f"\n[!] Error: Invalid Azure VM size provided\n")
        print("[*] Valid VM sizes are:\n")
        print("\n".join(VALID_SIZES))
        sys.exit(1)
    return size


def run(cmd, cwd=None):
    result = subprocess.run(cmd, cwd=cwd)
    if result.returncode != 0:
        sys.exit(result.returncode)


def terraform_output(key, cwd):
    result = subprocess.run(
        ["terraform", "output", "-raw", key],
        capture_output=True, text=True, cwd=cwd
    )
    return result.stdout.strip()


def main():
    parser = argparse.ArgumentParser(
        usage="%(prog)s -l <location> -u <username> -n <prefix> -s <ssh_key> -d <dns> -v <vm_size>",
        description="Azure infrastructure setup via Terraform"
    )
    parser.add_argument("-l", "-location",  dest="location",  required=True, help="Azure region location")
    parser.add_argument("-u", "-username",  dest="username",  required=True, help="VM username")
    parser.add_argument("-n", "-name",      dest="prefix",    required=True, help="Resource name prefix")
    parser.add_argument("-s", "-ssh",       dest="ssh_key",   required=True, help="SSH key name")
    parser.add_argument("-d", "-dns",       dest="dns_name",  required=True, help="DNS name prefix for public IP")
    parser.add_argument("-v", "-vm",        dest="vm_size",   required=True, help="VM size")

    args = parser.parse_args()

    location = validate_location(args.location)
    vm_size  = validate_size(args.vm_size)

    check_azure_cli()
    check_terraform()

    tf_pack = os.path.join(PROJECT_ROOT, "Terraform-Pack")
    if not os.path.isdir(tf_pack):
        print("Error: Terraform-Pack directory not found")
        sys.exit(1)

    if not os.path.isfile(TFVARS_PATH):
        print("Error: terraform.tfvars file not found in Terraform-Pack")
        sys.exit(1)

    tfvars_content = (
        f'resource_group_location = "{location}"\n'
        f'username               = "{args.username}"\n'
        f'prefix                 = "{args.prefix}"\n'
        f'ssh_privkey           = "{args.ssh_key}"\n'
        f'dns_name              = "{args.dns_name}"\n'
        f'size                  = "{vm_size}"\n'
    )

    with open(TFVARS_PATH, "w") as f:
        f.write(tfvars_content)

    print("[+] terraform.tfvars updated with:\n")
    print(f"VM-Location: {location}")
    print(f"Username:    {args.username}")
    print(f"Prefix:      {args.prefix}")
    print(f"SSH Key:     {args.ssh_key}")
    print(f"DNS Name:    {args.dns_name}")
    print(f"VM Size:     {vm_size}\n")

    print("[*] Initializing Terraform...\n")
    run(["terraform", "init"], cwd=tf_pack)

    print("\n[*] Planning Terraform deployment...\n")
    run(["terraform", "plan"], cwd=tf_pack)

    print("\n[*] Applying Terraform configuration...\n")
    run(["terraform", "apply", "-auto-approve"], cwd=tf_pack)

    print("\n[*] Getting connection information...\n")
    print(f"[*] Connection String: {terraform_output('connection_string', tf_pack)}")
    print(f"[*] FQDN:              {terraform_output('fqdn', tf_pack)}")
    print(f"[*] Public IP:         {terraform_output('public_ip', tf_pack)}")
    print(f"[*] Username:          {terraform_output('username', tf_pack)}")
    print()


if __name__ == "__main__":
    main()
