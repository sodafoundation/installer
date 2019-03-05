# OpenSDS Multi-nodes installation using Ansible # 

## Pre-requisite ##

### ubuntu
* Version information of all nodes

	```
	root@proxy:~# cat /etc/issue
	Ubuntu 16.04.2 LTS \n \l
	```


#### Required packages and commands for ssh connection between nodes

* Set Password for root (RUN ON ALL NODES):
    ```bash
    passwd root 
    
    #For sudo privileges without having to enter a password
    echo "root ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/root
    
    chmod 0440 /etc/sudoers.d/root
    
    sed -i s'/Defaults requiretty/#Defaults requiretty'/g /etc/sudoers
    ```
    
* Install and Configure NTP (RUN ON ALL NODES):
    ```bash
    sudo apt-get install -y ntp ntpdate ntp-doc
    ntpdate 0.us.pool.ntp.org
    hwclock --systohc
    systemctl enable ntp
    systemctl start ntp
        
    ```
    
* Install Open-vm-tools (RUN ON ALL NODES)
  (If you are running all nodes inside VMware, you need to install this virtualization utility.
)
    ```bash
    sudo apt-get install -y open-vm-tools
    ```
    
* Install Python and parted (RUN ON ALL NODES)
 
    ```bash
    sudo apt-get install -y python python-pip parted
    ```
    
* Configure the Hosts File (RUN ON ALL NODES)
 
    ```bash
    vi /etc/hosts
    
    192.168.3.78    opensds
    192.168.1.234   dock-1
    192.168.1.236   dock-2    

    ```
    
* Now you can try to ping between the server hostnames to test the network connectivity
    ```bash
    ping -c 5 dock-2
    ```

* Configure the SSH Server (RUN ON ALL NODES)
 
    ```bash
    ssh-keygen
    #Leave passphrase is blank/empty.
    
    #Next, create a configuration file for the ssh config.
    vi  ~/.ssh/config
    
    # Paste following configuration
    
    Host opensds
            Hostname opensds
            User root
             
    Host dock-1
            Hostname dock-1
            User root
     
    Host dock-2
            Hostname dock-2
            User root

    #Save and Exit the editor
    
    #Change the permission of the config file to 644
    chmod 644 ~/.ssh/config
    
    #Now add the key to all nodes with the ssh-copy-id command.
    ssh-keyscan dock-1 dock-2 opensds >> ~/.ssh/known_hosts
    
    sudo sed -i 's/prohibit-password/yes/' /etc/ssh/sshd_config
    
    vi /etc/ssh/ssh_config
    # Set "PasswordAuthentication yes"
    
    #Save and exit the editor
    
    #Restart sshd
    sudo systemctl restart sshd
    
    ssh-copy-id dock-1
    ssh-copy-id dock-2
    ssh-copy-id testing-opensds
    ```
    
Install following packages (on all nodes):
```bash
apt-get install -y git curl wget libltdl7 libseccomp2
```
* docker

Install docker (on all nodes):
```bash
wget https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce_18.06.1~ce~3-0~ubuntu_amd64.deb
dpkg -i docker-ce_18.06.1~ce~3-0~ubuntu_amd64.deb 
```
Install docker-compose (on all nodes):
```bash
curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```
* golang (on all nodes)

Check golang version information (v1.11.x):
```bash
root@proxy:~# go version
go version go1.11.2 linux/amd64
```
You can install golang by executing commands below:
```bash
wget https://storage.googleapis.com/golang/go1.11.2.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.11.2.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
echo 'export GOPATH=$HOME/gopath' >> /etc/profile
source /etc/profile
```

### Download opensds-installer code (on all nodes)
```bash
git clone https://github.com/opensds/opensds-installer.git
cd opensds-installer/ansible
```

### Install ansible tool (on all nodes)
To install ansible, run the commands below:
```bash
# This step is needed to upgrade ansible to version 2.4.2 which is required for the "include_tasks" ansible command.
chmod +x ./install_ansible.sh && ./install_ansible.sh
ansible --version # Ansible version 2.4.x is required.
```

### Configure opensds cluster variables (On Controllers node ONLY):
##### System environment:
Firstly you need to modify `host_ip` in `group_vars/common.yml`, and you can specify which project (hotpot or gelato) to be deployed:
```yaml
# This field indicates local machine host ip
host_ip: 127.0.0.1

# This field indicates which project should be deploy
# 'hotpot', 'gelato' or 'all'
deploy_project: all
```

If you want to integrate OpenSDS with k8s csi, please modify `nbp_plugin_type` to `csi` in `group_vars/sushi.yml`:
```yaml
# 'hotpot_only' is the default integration way, but you can change it to 'csi'
# or 'flexvolume'
nbp_plugin_type: hotpot_only
```

##### For MULTI-NODE Installation, make following section COMMENTED/DISABLE as we will configure this in `local.hosts` file
* `group_vars/osdsdock.yml`
    ````
     
    #enabled_backends: lvm # Change it according to the chosen backend. Supported backends include 'lvm', 'ceph', and 'cinder'


    #dock_endpoint: localhost # **For multinodes dock_endpoint should be mentioned in local.hosts file and THIS SHOULD BE COMMENTED

    ````


##### For Multi-node Installation, set following sections of following files

* `group_vars/osdsdb`
    ````
    #FOR MULTI-NODE USE HOST_IP INSTEAD OF 127.0.0.1
    etcd_host: 127.0.0.1 # For multi-node set USE host ip as etcd_host
    ````

* `group_vars/ceph/all.yml` ( while using ceph as a backend)
    ```yml
    public_network: "{{ dock_endpoint }}/24" # Run 'ip -4 address' to check the ip address
   ```

* `local.hosts` (docks section)
    ````
    [docks]
    localhost ansible_connection=local enabled_backends=lvm dock_endpoint=192.168.3.78
    192.168.1.234 ansible_connection=ssh enabled_backends=lvm dock_endpoint=192.168.1.234
    192.168.1.236 ansible_connection=ssh enabled_backends=lvm,ceph dock_endpoint=192.168.1.236
    ````
##### LVM
If `lvm` is chosen as storage backend, modify `group_vars/osdsdock.yml`:
```yaml
enabled_backend: lvm 
```

Modify ```group_vars/lvm/lvm.yaml```, change `tgtBindIp` to your real host ip if needed:
```yaml
tgtBindIp: 127.0.0.1 
```

##### Ceph
If `ceph` is chosen as storage backend, modify `group_vars/osdsdock.yml`:
```yaml
enabled_backend: ceph # Change it according to the chosen backend. Supported backends include 'lvm', 'ceph', and 'cinder'.
```

Configure ```group_vars/ceph/all.yml``` with an example below:
```yml
ceph_origin: repository
ceph_repository: community
ceph_stable_release: luminous # Choose luminous as default version
#SET "public_network" as "{{ dock_endpoint }}/24" as described before FOR MULTI-NODE INSTALLATION
public_network: "192.168.3.0/24" # Run 'ip -4 address' to check the ip address
cluster_network: "{{ public_network }}"
monitor_interface: eth1 # Change to the network interface on the target machine
devices: # For ceph devices, append ONE or MULTIPLE devices like the example below:
  - '/dev/sda' # Ensure this device exists and available if ceph is chosen
  #- '/dev/sdb'  # Ensure this device exists and available if ceph is chosen
osd_scenario: collocated
```

##### Cinder
If `cinder` is chosen as storage backend, modify `group_vars/osdsdock.yml`:
```yaml
#COMMENT BELOW PART FOR MULTI-NODE INSTALLATION
enabled_backends: cinder # Change it according to the chosen backend. Supported backends include 'lvm', 'ceph', and 'cinder'

# Use block-box install cinder_standalone if true, see details in:
use_cinder_standalone: true
```

Configure the auth and pool options to access cinder in `group_vars/cinder/cinder.yaml`. Do not need to make additional configure changes if using cinder standalone.

### Check if the hosts can be reached
```bash
ansible all -m ping -i local.hosts
```

### Run opensds-ansible playbook to start deploy
```bash
ansible-playbook site.yml -i local.hosts
```

## 2. How to test opensds cluster
### OpenSDS CLI
Firstly configure opensds CLI tool:
```bash
sudo cp /opt/opensds-hotpot-linux-amd64/bin/osdsctl /usr/local/bin/
export OPENSDS_ENDPOINT=http://{your_real_host_ip}:50040
export OPENSDS_AUTH_STRATEGY=keystone
source /opt/stack/devstack/openrc admin admin

osdsctl pool list # Check if the pool resource is available
```

Then create a default profile:
```
osdsctl profile create '{"name": "default", "description": "default policy"}'
```

Create a volume:
```
osdsctl volume create 1 --name=test-001
```

List all volumes:
```
osdsctl volume list
```

Delete the volume:
```
osdsctl volume delete <your_volume_id>
```

### OpenSDS UI
OpenSDS UI dashboard is available at `http://{your_host_ip}:8088`, please login the dashboard using the default admin credentials: `admin/opensds@123`. Create `tenant`, `user`, and `profiles` as admin. Multi-Cloud service is also supported by dashboard.

Logout of the dashboard as admin and login the dashboard again as a non-admin user to manage storage resource:

#### Volume Service
* Create volume
* Create snapshot
* Expand volume size
* Create volume from snapshot
* Create volume group

#### Multi Cloud Service
* Register object storage backend
* Create bucket
* Upload object
* Download object
* Migrate objects based on bucket across cloud

We would be grateful if you could [report issues](https://github.com/opensds/opensds/issues) when you find some bug or issues.

## 3. How to purge and clean opensds cluster

### Run opensds-ansible playbook to clean the environment
```bash
ansible-playbook clean.yml -i local.hosts
```

### Run ceph-ansible playbook to clean ceph cluster if ceph is deployed
```bash
cd /opt/ceph-ansible
sudo ansible-playbook infrastructure-playbooks/purge-cluster.yml -i ceph.hosts
```

In addition, clean up the logical partition on the physical block device used by ceph, using the ```fdisk``` tool.

### Remove ceph-ansible source code (optional)
```bash
sudo rm -rf /opt/ceph-ansible