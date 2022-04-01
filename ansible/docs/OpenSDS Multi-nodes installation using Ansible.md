# soda Multi-nodes installation using Ansible # 
This document explain steps for a sample soda multi-node installation with three nodes (Eg. node-1, node-2 and node-3). First node is configured as Controller and other two nodes are configured as dock backends.
## 1. Installation ##
Installation steps for soda Multi-nodes is similar to wiki page 'soda Cluster Installation through Ansible' https://github.com/soda/soda/wiki/soda-Cluster-Installation-through-Ansible

Difference in steps for soda multi-nodes will be documented here.
### Pre-config (Ubuntu 16.04)
#### Setup SSH Connection (Needed on ALL Nodes)
* Set password for root:
    ```bash
    passwd root 
    
    #For sudo privileges without having to enter a password
    echo "root ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/root
    chmod 0440 /etc/sudoers.d/root
    sed -i s'/Defaults requiretty/#Defaults requiretty'/g /etc/sudoers
    ```
* Install and Configure NTP:
    ```bash
    sudo apt-get install -y ntp ntpdate ntp-doc
    ntpdate 0.us.pool.ntp.org
    hwclock --systohc
    systemctl enable ntp
    systemctl start ntp
    ```
* Install Open-vm-tools:
If you are running all nodes inside VMware, you need to install this virtualization utility.
    ```bash
    sudo apt-get install -y open-vm-tools
    ```
* Install Python and parted:
     ```bash
    sudo apt-get install -y python python-pip parted
    ```
* Add following lines to '/etc/hosts' file:
     ```bash
    192.168.1.234   node-1
    192.168.3.78    node-2
    192.168.1.236   node-3    
    ```
* Now you can try to ping between the server hostnames to test the network connectivity
    ```bash
    ping -c 5 node-2 #from node-1
    ```
* Configure the SSH Server:
    ```bash
    ssh-keygen
    #Leave passphrase as blank/empty.
   ```
* Next, create a configuration file, ~/.ssh/config with contents below.
    ```bash
    Host node-1
            Hostname node-1
            User root
             
    Host node-2
            Hostname node-2
            User root
     
    Host node-3
            Hostname node-3
            User root
    ```
* Configure and restart sshd
    ```bash
    # Change the permission of the config file to 644
    chmod 644 ~/.ssh/config
    
    #Now add the key to all nodes with the ssh-copy-id command.
    ssh-keyscan node-1 node-2 node-3 >> ~/.ssh/known_hosts
    
    sudo sed -i 's/prohibit-password/yes/' /etc/ssh/sshd_config
    
    vi /etc/ssh/ssh_config
    # Set "PasswordAuthentication yes"
    
    #Save and exit the editor
    
    #Restart sshd
    sudo systemctl restart sshd
    
    ssh-copy-id node-1
    ssh-copy-id node-2
    ssh-copy-id node-3
    ```
#### Install following packages  (Needed on ALL Nodes):
Please refer soda Cluster installation steps in [wiki.](https://github.com/soda/soda/wiki/soda-Cluster-Installation-through-Ansible) 
* docker & docker-compose
* golang
* soda-installer code
* ansible tool
### Configure soda install variables (On Controllers node ONLY):
##### System environment:
Firstly you need to modify `host_ip` in `group_vars/common.yml`, and you can specify which project (hotpot or gelato) to be deployed:
```yaml
# This field indicates local machine host ip
host_ip: 127.0.0.1

# This field indicates which project should be deploy
# 'hotpot', 'gelato' or 'all'
deploy_project: all
```
If you want to integrate soda with k8s csi, please modify `nbp_plugin_type` to `csi` in `group_vars/sushi.yml`:
```yaml
# 'hotpot_only' is the default integration way, but you can change it to 'csi'
# or 'flexvolume'
nbp_plugin_type: hotpot_only
```
##### For MULTI-NODE Installation, make following section COMMENTED/DISABLE as we will configure this in `local.hosts` file
* `group_vars/osdsdock.yml`
    ```yml
    #enabled_backends: lvm # Change it according to the chosen backend. Supported backends include 'lvm', 'ceph', and 'cinder'

    #dock_endpoint: localhost # **For multinodes dock_endpoint should be mentioned in local.hosts file and THIS SHOULD BE COMMENTED
    ```
##### For Multi-node Installation, set following sections of following files
* `group_vars/osdsdb`
    ```yml
    #FOR MULTI-NODE USE HOST_IP INSTEAD OF 127.0.0.1
    etcd_host: 127.0.0.1 # For multi-node set USE host ip as etcd_host
    ```
* `group_vars/ceph/all.yml` ( while using ceph as a backend)
    ```yml
    public_network: "{{ ansible_default_ipv4.address }}/24" # Run 'ip -4 address' to check the ip address
   ```
* `local.hosts` (docks section)
    ```yml
    [docks]
    localhost ansible_connection=local enabled_backends=lvm,ceph dock_endpoint=192.168.1.234
    192.168.3.78 ansible_connection=ssh enabled_backends=lvm dock_endpoint=192.168.3.78
    192.168.1.236 ansible_connection=ssh enabled_backends=lvm dock_endpoint=192.168.1.236
    ```
##### LVM
If `lvm` is chosen as storage backend, modify `group_vars/osdsdock.yml`:
   ```yml
   enabled_backend: lvm 
   ```
Modify ```group_vars/lvm/lvm.yaml```, change `tgtBindIp` to your real host ip if needed:
   ```yml
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
#SET "public_network" as "{{ ansible_default_ipv4.address }}/24" as described before FOR MULTI-NODE INSTALLATION
public_network: "{{ ansible_default_ipv4.address }}/24" # Run 'ip -4 address' to check the ip address
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
export HOST_IP={your_real_host_ip}
ansible all -m ping -i local.hosts
```
### Run soda-ansible playbook to start deploy
```bash
ansible-playbook site.yml -i local.hosts
```
## 2. How to test soda cluster
Please refer soda Cluster installation steps in [wiki.](https://github.com/soda/soda/wiki/soda-Cluster-Installation-through-Ansible)
## 3. How to purge and clean soda cluster
Please refer soda Cluster installation steps in [wiki.](https://github.com/soda/soda/wiki/soda-Cluster-Installation-through-Ansible)