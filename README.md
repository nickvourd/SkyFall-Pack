# SkyFall-Pack

Your Skyfall Infrastructure Pack

<p align="center">
  <img width="500" height="400" src="/Pictures/logo2.png"><br /><br />
  <img alt="GitHub License" src="https://img.shields.io/github/license/nickvourd/SkyFall-Pack?style=social&logo=GitHub&logoColor=purple">
  <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/nickvourd/SkyFall-Pack?logoColor=yellow"><br />
  <img alt="GitHub forks" src="https://img.shields.io/github/forks/nickvourd/SkyFall-Pack?logoColor=red">
  <img alt="GitHub watchers" src="https://img.shields.io/github/watchers/nickvourd/SkyFall-Pack?logoColor=blue">
  <img alt="GitHub contributors" src="https://img.shields.io/github/contributors/nickvourd/SkyFall-Pack?style=social&logo=GitHub&logoColor=green">
</p>

## Description

SkyFall-Pack is an infrastructure automation pack for C2 operations. It leverages Cloudflare Workers as redirectors and an Azure VM as the teamserver.

![Static Badge](https://img.shields.io/badge/Ansible-green?style=flat&logoSize=auto)
![Static Badge](https://img.shields.io/badge/Terraform-blue?style=flat&logoSize=auto)
![Static Badge](https://img.shields.io/badge/Golang-cyan?style=flat&logoSize=auto)
![Static Badge](https://img.shields.io/badge/Bash-purple?style=flat&logoSize=auto)
![Static Badge](https://img.shields.io/badge/Version-1.0%20-red?link=https%3A%2F%2Fgithub.com%2Fnickvourd%2FSkyFall-Pack%2Freleases)

The following list explains the meaning of each pack:

- **Workers-Pack**: A Go-based pack that automates the generation of `wrangler.jsonc` and `index.js`.
- **Scripts-Pack**: Bash scripts that initiate and configure the process.
- **Terraform-Pack**: A Terraform pack that contains all the code for deploying the Azure VM.
- **Ansible-Pack**: An Ansible pack that contains all the code for configuring the Azure VM.

> If you find any bugs, don’t hesitate to [report them](https://github.com/nickvourd/SkyFall-Pack/issues). Your feedback is valuable in improving the quality of this project!

## Disclaimer

The authors and contributors of this project are not liable for any illegal use of the tool. It is intended for educational purposes only. Users are responsible for ensuring lawful usage.

## Table of Contents
- [SkyFall-Pack](#skyfall-pack)
  - [Description](#description)
  - [Disclaimer](#disclaimer)
  - [Table of Contents](#table-of-contents)
  - [Acknowledgement](#acknowledgement)
  - [Installation](#installation)
  - [Usage](#usage)
  - [References](#references)

## Acknowledgement

This project created with :heart: by [@nickvourd](https://x.com/nickvourd) && [@kavasilo](https://x.com/kavasilo).

Special thanks to [@kyleavery_](https://x.com/kyleavery_) for all the valuable tips.

Special thanks to my friend [Juan Martinez Moreno](https://www.linkedin.com/in/jmartinezmoreno/) for all the contributions.

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
./Scripts-Pack/setup.sh -l <location> -u <username> -n <resource_group_name> -s <ssh_filename> -d <dns_name> -v <vm_size>
```

- Configure Azure VM (Team Server)

```
./Scripts-Pack/run_ansible.sh -f <keystore_filename> -p <password> -c <custom_header> -s <secret_value> [--http]
```

- Cloudflare Worker

```
npm create cloudflare -y
```

- Configure Cloudflare Worker (Execute this on your local machine)

```
./WorkerMan build -t <teamserver_url> -w <worker_url> -c <custom_header> -s <secret_value>
```

⚠️ Copy `wrangler.jsonc` and `index.js` to the appropriate directories.

- Deploy Wrangler (execute from the Worker project's root directory)

```
npm exec wrangler deploy
```

## References

- [(Re)visiting Cloudflare Workers for C2 by Marcello](https://byt3bl33d3r.substack.com/p/revisiting-cloudflare-workers-for)
- [Using Cloudflare Workers as Redirectors](https://ajpc500.github.io/c2/Using-CloudFlare-Workers-as-Redirectors/)
- [Putting the C2 in C2loudflare by JUMPSEC Labs](https://labs.jumpsec.com/putting-the-c2-in-c2loudflare/)
