# SkyFall-Pack

Your Skyfall Infrastructure Pack

<p align="center">
  <img width="500" height="400" src="/Pictures/logo2.png"><br /><br />
  <img alt="Static Badge" src="https://img.shields.io/badge/License-MIT-green?link=https%3A%2F%2Fgithub.com%2Fnickvourd%2FSkyFall-Pack%2Fblob%2Fmain%2FLICENSE">
  <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/nickvourd/SkyFall-Pack?logoColor=yellow">
  <img alt="GitHub forks" src="https://img.shields.io/github/forks/nickvourd/SkyFall-Pack?logoColor=red">
  <img alt="GitHub watchers" src="https://img.shields.io/github/watchers/nickvourd/SkyFall-Pack?logoColor=blue">
</p>

## Description

SkyFall-Pack is an infrastructure automation pack for C2 operations. It leverages Cloudflare Workers as redirectors and an Azure VM as the teamserver.

The following list explains the meaning of each pack:

- **Workers-Pack**: A Go-based pack that automates the generation of `wrangler.jsonc` and `index.js`.
- **Scripts-Pack**: Bash scripts that initiate and configure the process.
- **Terraform-Pack**: A Terraform pack that contains all the code for deploying the Azure VM.
- **Ansible-Pack**: An Ansible pack that contains all the code for configuring the Azure VM.

This project created with :heart: by [@nickvourd](https://x.com/nickvourd) && [@kavasilo](https://x.com/kavasilo).

Special thanks to [@kyleavery_](https://x.com/kyleavery_) for all the valuable tips.

## Table of Contents
- [SkyFall-Pack](#skyfall-pack)
  - [Description](#description)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Usage](#usage)
  - [References](#references)

## Installation

Install the following dependencies on your local machine.

For Linux:

```
sudo apt install terraform npm ansible golang azure-cli -y
```

For Mac:

```
brew install terraform azure-cli node wrangler ansible go
```

## Usage

### Authentication

- Cloudflare

```
npm exec wangler login
```

- Azure 

```
az login
```

### Build Infra

- Clone The Project

```
git clone https://github.com/nickvourd/SkyFall-Pack.git
```

- Azure VM (Team Server)

```
./Scripts-Pack/setup.sh -l <location> -u <username> -n <resource_group_name> -s <ssh_filename> -d <dns_name>
```

- Configure Azure VM (Team Server)

```
./Scripts-Pack/run_ansible.sh -f <keystore_filename> -p <password> -c <custom_header> -s <secret_value>
```

- Cloudflare Worker

```
npm create cloudflare
```

- Configure Cloudflare Worker

```
./WorkerMan build -t <teamserver_hostname> -w <worker_hostname> -c <custom_header> -s <secret_value>
```

## References

- [(Re)visiting Cloudflare Workers for C2 by Marcello](https://byt3bl33d3r.substack.com/p/revisiting-cloudflare-workers-for)
- [Using Cloudflare Workers as Redirectors](https://ajpc500.github.io/c2/Using-CloudFlare-Workers-as-Redirectors/)
- [Putting the C2 in C2loudflare by JUMPSEC Labs](https://labs.jumpsec.com/putting-the-c2-in-c2loudflare/)
