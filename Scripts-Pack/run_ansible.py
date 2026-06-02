#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys

SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))


def convert_header(header: str) -> str:
    return header.lower().replace("-", "_")


def check_ansible():
    if subprocess.run(["which", "ansible"], capture_output=True).returncode != 0:
        print("\n[!] Error: Ansible is not installed\n")
        print("[*] Please install Ansible using one of these methods:")
        print("    1. Linux (apt): sudo apt install ansible")
        print("    2. Linux (yum): sudo yum install ansible")
        print("    3. MacOS:       brew install ansible")
        sys.exit(1)


def terraform_output(key: str, cwd: str) -> str:
    result = subprocess.run(
        ["terraform", "output", "-raw", key],
        capture_output=True, text=True, cwd=cwd
    )
    return result.stdout.strip().strip("\r\n\t\x00")


def run_ansible(cmd: list, cwd: str, env: dict):
    result = subprocess.run(cmd, cwd=cwd, env=env)
    if result.returncode != 0:
        sys.exit(result.returncode)


def main():
    parser = argparse.ArgumentParser(
        usage="%(prog)s [-f FILE] [-p PASS] [--port PORT] [-c HEADER] [-s SECRET] [--local-cs PATH] [--remote-cs DIR] [--http]"
    )
    parser.add_argument("-f", "--file",          dest="keystore_file",   default="",              help="Keystore filename")
    parser.add_argument("-p", "--password",      dest="keystore_pass",   default="",              help="Keystore password")
    parser.add_argument("--port",                dest="teamserver_port", default="8443",           help="Teamserver port (default: 8443)")
    parser.add_argument("-c", "--custom-header", dest="custom_header",   default="X-CSRF-TOKEN",  help="Custom header name")
    parser.add_argument("-s", "--custom-secret", dest="custom_secret",   default="MySecretValue", help="Custom secret value")
    parser.add_argument("--local-cs",            dest="local_cs_path",   default="",              help="Absolute local path to Cobalt Strike Linux archive (.tgz)")
    parser.add_argument("--remote-cs",           dest="remote_cs_dir",   default="/opt",          help="Remote install directory for Cobalt Strike (default: /opt)")
    parser.add_argument("--http",                action="store_true",    default=False,           help="Use HTTP mode")

    args = parser.parse_args()

    # -------------------------------
    # VALIDATION
    # -------------------------------

    if args.http:
        conflicts = []
        if args.keystore_file:              conflicts.append("-f / --file")
        if args.keystore_pass:              conflicts.append("-p / --password")
        if args.local_cs_path:              conflicts.append("--local-cs")
        if args.remote_cs_dir != "/opt":    conflicts.append("--remote-cs")
        if conflicts:
            print("\n[!] Error: --http mode cannot be used with:")
            for c in conflicts:
                print(f"    {c}")
            sys.exit(1)

    if not args.http:
        if not args.keystore_file or not args.keystore_pass:
            parser.error("Arguments -f/--file and -p/--password are required in HTTPS mode")

    if args.local_cs_path and not os.path.isfile(args.local_cs_path):
        print(f"\n[!] Error: --local-cs path does not exist: {args.local_cs_path}")
        sys.exit(1)

    protocol            = "http" if args.http else "https"
    custom_header_lower = convert_header(args.custom_header)

    # -------------------------------
    # CHECK ANSIBLE
    # -------------------------------

    check_ansible()

    # -------------------------------
    # TERRAFORM OUTPUT
    # -------------------------------

    tf_pack      = os.path.join(PROJECT_ROOT, "Terraform-Pack")
    vm_ip        = terraform_output("public_ip",   tf_pack)
    vm_user      = terraform_output("username",    tf_pack)
    ssh_privkey  = terraform_output("ssh_privkey", tf_pack)
    vm_fqdn      = terraform_output("fqdn",        tf_pack)
    ssh_key_path = os.path.join(tf_pack, f"{ssh_privkey}.pem")

    # -------------------------------
    # ANSIBLE
    # -------------------------------

    ansible_pack = os.path.join(PROJECT_ROOT, "Ansible-Pack")
    if not os.path.isdir(ansible_pack):
        print(f"\n[!] Error: Ansible-Pack directory not found at {ansible_pack}")
        sys.exit(1)

    if not os.path.isfile(ssh_key_path):
        print(f"\n[!] Error: SSH key not found at {ssh_key_path}")
        sys.exit(1)

    os.chmod(ssh_key_path, 0o600)

    print("\n[+] Running Ansible playbook with:")
    print(f"Protocol:             {protocol}")
    print(f"VM IP:                {vm_ip}")
    print(f"Username:             {vm_user}")
    print(f"SSH Key:              {ssh_key_path}")
    print(f"VM FQDN:              {vm_fqdn}")
    print(f"Teamserver Port:      {args.teamserver_port}")

    if not args.http:
        print(f"Keystore Filename:    {args.keystore_file}")
        print(f"Keystore Password:    {args.keystore_pass}")
        print(f"Custom Header:        {args.custom_header}")
        print(f"Custom Header Lower:  {custom_header_lower}")
        print(f"Custom Secret:        {args.custom_secret}")
        if args.local_cs_path:
            print(f"Local CS Path:        {args.local_cs_path}")
            print(f"Remote CS Dir:        {args.remote_cs_dir}")
    print()

    cmd = [
        "ansible-playbook",
        "-i", "inventory/hosts.yml",
        "setup.yml", "-vv",
        "-e", f"protocol={protocol}",
        "-e", f"remote_cs_dir={args.remote_cs_dir}",
        "-e", f"cs_install_dir={args.remote_cs_dir}",
    ]

    if args.local_cs_path:
        cmd += ["-e", f"local_cs_path={args.local_cs_path}"]

    if not args.http:
        cmd += [
            "-e", f"keystore_filename={args.keystore_file}",
            "-e", f"keystore_password={args.keystore_pass}",
            "-e", f"custom_header={args.custom_header}",
            "-e", f"custom_secret={args.custom_secret}",
            "-e", f"teamserver_port={args.teamserver_port}",
        ]

    env = os.environ.copy()
    env["VM_IP"]        = vm_ip
    env["VM_USER"]      = vm_user
    env["SSH_KEY_PATH"] = ssh_key_path
    env["VM_FQDN"]      = vm_fqdn
    env["PROTOCOL"]     = protocol

    if not args.http:
        env["KEYSTORE_FILENAME"] = args.keystore_file
        env["KEYSTORE_PASSWORD"] = args.keystore_pass
        env["TEAMSERVER_PORT"]   = args.teamserver_port
        env["CUSTOM_HEADER"]     = args.custom_header
        env["CUSTOM_SECRET"]     = args.custom_secret

    run_ansible(cmd, cwd=ansible_pack, env=env)


if __name__ == "__main__":
    main()
