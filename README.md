# installer

[![Releases](https://img.shields.io/github/release/sodafoundation/installer/all.svg?style=flat-square)](https://github.com/sodafoundation/installer/releases)
[![LICENSE](https://img.shields.io/github/license/sodafoundation/installer.svg?style=flat-square)](https://github.com/sodafoundation/installer/blob/master/LICENSE)

<img src="https://sodafoundation.io/wp-content/uploads/2020/01/SODA_logo_outline_color_800x800.png" width="200" height="200">

## Introduction

SODA installer project provides easy installation and basic deployment based on specific configurations for SODA Projects. The installer is created so as to support the integrated installation of specific projects for each SODA Release.

It is modular and specific project installation information is built based on the installation hooks and related configurations. Basically SODA installer plays a wrapper role to put all together and provide a simple installation for the users and experience overall solution.

Installer project is maintained by SODA Foundation directly.

SODA Installer supports installation of following SODA projects. If you want to install Orchestration, Sushi or Terra with Ceph backend, please use Installer version 1.7.0 or older.
* Delfin
* Terra/Hotpot (Api, Controller & Dock)
* Strato/Gelato (Multi-cloud)
* Orchestration
* Sushi (NBP)
* Dashboard

## Installation using Ansible

* Supported OS: **Ubuntu 20.04, Ubuntu 18.04**
* Prerequisite: **Python 3.6 or above** should be installed


### Install steps

Ensure no ansible & docker installed, OR **Latest** ansible and docker tools are installed with versions listed below or later. If ansible & docker is not installed in the OS, script `install_dependencies.sh` will install it.

Update configurations for individual projects in **`installer/ansible/group_var/*.yml`** and follow commands listed below.

* auth.yml
* common.yml
* dashboard.yml
* delfin.yml
* gelato-ha.yml
* gelato.yml
* hotpot.yml
* orchestration.yml
* osdsdb.yml
* osdsdock.yml
* srm-toolchain.yml
* sushi.yml
* telemetry.yml


Please refer [SODA documentation](https://docs.sodafoundation.io/soda-gettingstarted/installation-using-ansible/) for the detailed installation steps and configuration options available.

**Installation steps for Strato :** To install Strato(Multi-cloud) and Dashboard using ansible installer, please follow below steps.


```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/sodafoundation/installer.git
git checkout v1.8.0 # you may choose specific release version also
cd installer/ansible
chmod +x install_dependencies.sh && source install_dependencies.sh
export PATH=$PATH:/home/$USER/.local/bin
```

Enable following configurations
 * In file installer/ansible/group_vars/gelato.yml
`enable_gelato.yml: true`
* In file installer/ansible/group_vars/dashboard.yml
`enable_dashboard: true`
* In file installer/ansible/group_vars/common.yml
`host_ip: <User's IP address, eg. 192.168.0.2>`

Note : 
* Change HOST_IP value in below export command also.
* To enable Storage Service Plan in Multi-cloud edit the configuration file installer/ansible/group_vars/common.yml as below 
`enable_storage_service_plans: true`

```bash
export HOST_IP=192.168.0.2 # Change HOST_IP value to real host ip
sudo -E env "PATH=$PATH" ansible-playbook site.yml -i local.hosts -v
```

**Installation steps for Delfin :** To install Delfin, SRM tool chain and Dashboard using ansible installer, please follow below steps.

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/sodafoundation/installer.git
cd installer/ansible
git checkout v1.8.0 # you may choose specific release version also
chmod +x install_dependencies.sh && source install_dependencies.sh
export PATH=$PATH:/home/$USER/.local/bin
```

Enable following configurations
 * In file installer/ansible/group_vars/delfin.yml
`enable_delfin: true`
* In file installer/ansible/group_vars/srm-toolchain.yml
`install_srm_toolchain: true`
* In file installer/ansible/group_vars/dashboard.yml
`enable_dashboard: true`
* In file installer/ansible/group_vars/common.yml
`host_ip: <User's IP address, eg. 192.168.0.2>`

```bash
export HOST_IP=192.168.0.2 # Change HOST_IP value to real host ip
sudo -E env "PATH=$PATH" ansible-playbook site.yml -i local.hosts -v
```
### Uninstall
```bash
sudo -E env "PATH=$PATH" ansible-playbook clean.yml -i local.hosts -v
```

### Tools used
#### Ubuntu 20.04
```bash
root@ubuntu2004:~/installer/ansible# ansible --version
ansible [core 2.13.5]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /root/.local/lib/python3.8/site-packages/ansible
  ansible collection location = /root/.ansible/collections:/usr/share/ansible/collections
  executable location = /root/.local/bin/ansible
  python version = 3.8.10 (default, Jun 22 2022, 20:18:18) [GCC 9.4.0]
  jinja version = 3.1.2
  libyaml = True
root@ubuntu20:~/installer/ansible# python3 -m pip show ansible
Name: ansible
Version: 5.10.0
Summary: Radically simple IT automation
Home-page: https://ansible.com/
Author: Ansible, Inc.
Author-email: info@ansible.com
License: GPLv3+
Location: /usr/lib/python3/dist-packages
Requires: ansible-core
Required-by:

root@ubuntu20:~/installer/ansible# docker version
Client: Docker Engine - Community
 Version:           20.10.21
 API version:       1.41
 Go version:        go1.18.7
 Git commit:        baeda1f
 Built:             Tue Oct 25 18:02:21 2022
 OS/Arch:           linux/amd64
 Context:           default
 Experimental:      true

Server: Docker Engine - Community
 Engine:
  Version:          20.10.21
  API version:      1.41 (minimum version 1.12)
  Go version:       go1.18.7
  Git commit:       3056208
  Built:            Tue Oct 25 18:00:04 2022
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.6.9
  GitCommit:        1c90a442489720eec95342e1789ee8a5e1b9536f
 runc:
  Version:          1.1.4
  GitCommit:        v1.1.4-0-g5fd4c4d
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
root@ubuntu20:~/installer/ansible# docker compose version
Docker Compose version v2.12.2
```

#### Ubuntu 18.04
```bash
test@T:~/installer$ ansible --version
[DEPRECATION WARNING]: Ansible will require Python 3.8 or newer on the controller starting with Ansible 2.12. Current version: 3.6.9 
(default, Jun 29 2022, 11:45:57) [GCC 8.4.0]. This feature will be removed from ansible-core in version 2.12. Deprecation warnings can be 
disabled by setting deprecation_warnings=False in ansible.cfg.
ansible [core 2.11.12]
  config file = None
  configured module search path = ['/home/test/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /home/test/.local/lib/python3.6/site-packages/ansible
  ansible collection location = /home/test/.ansible/collections:/usr/share/ansible/collections
  executable location = /home/test/.local/bin/ansible
  python version = 3.6.9 (default, Jun 29 2022, 11:45:57) [GCC 8.4.0]
  jinja version = 3.0.3
  libyaml = True
test@T:~/installer$ python3 -m pip show ansible
Name: ansible
Version: 4.10.0
Summary: Radically simple IT automation
Home-page: https://ansible.com/
Author: Ansible, Inc.
Author-email: info@ansible.com
License: GPLv3+
Location: /home/test/.local/lib/python3.6/site-packages
Requires: ansible-core
Required-by:

test@T:~/installer/ansible$ docker version
Client: Docker Engine - Community
 Version:           20.10.21
 API version:       1.41
 Go version:        go1.18.7
 Git commit:        baeda1f
 Built:             Tue Oct 25 18:02:00 2022
 OS/Arch:           linux/amd64
 Context:           default
 Experimental:      true
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/version": dial unix /var/run/docker.sock: connect: permission denied
test@T:~/installer/ansible$ docker compose version
Docker Compose version v2.12.2

```
## Documentation

[https://docs.sodafoundation.io](https://docs.sodafoundation.io/)

## Quick Start - To Use/Experience

[https://docs.sodafoundation.io](https://docs.sodafoundation.io/)

## Quick Start - To Develop

[https://docs.sodafoundation.io](https://docs.sodafoundation.io/)

## Latest Releases

[https://github.com/sodafoundation/installer/releases](https://github.com/sodafoundation/installer/releases)

## Support and Issues

[https://github.com/sodafoundation/installer/issues](https://github.com/sodafoundation/installer/issues)

## Project Community

[https://sodafoundation.io/slack/](https://sodafoundation.io/slack/)

## How to contribute to this project?

Join [https://sodafoundation.io/slack/](https://sodafoundation.io/slack/) and share your interest in the ‘general’ channel

Checkout [https://github.com/sodafoundation/installer/issues](https://github.com/sodafoundation/installer/issues) labelled with ‘good first issue’ or ‘help needed’ or ‘help wanted’ or ‘StartMyContribution’ or ‘SMC’

## Project Roadmap

We envision to provide fully automated, single click installation or deployment for SODA Solutions using all the projects integrated.

[https://docs.sodafoundation.io](https://docs.sodafoundation.io/)

## Join SODA Foundation

Website : [https://sodafoundation.io](https://sodafoundation.io/)

Slack  : [https://sodafoundation.io/slack/](https://sodafoundation.io/slack/)

Twitter  : [@sodafoundation](https://twitter.com/sodafoundation)

Mailinglist  : [https://lists.sodafoundation.io](https://lists.sodafoundation.io/)
