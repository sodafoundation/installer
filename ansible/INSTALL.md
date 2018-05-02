# Install OpenSDS with Kubernetes CSI through Ansible

## Installation
### Pre-config (Ubuntu 16.04)
* Kubernetes

This installation requires k8s v1.10, so please make sure your existing k8s cluster version is v1.10.

If you don't have k8s cluster, just follow these commands to create a new one:
```shell
cd $HOME && git clone https://github.com/kubernetes/kubernetes.git -b v1.10.0
cd kubernetes && make

echo alias kubectl='$HOME/kubernetes/cluster/kubectl.sh' >> /etc/profile
ALLOW_PRIVILEGED=true AUTHORIZATION_MODE=Node,RBAC hack/local-up-cluster.sh -O
```

### Download opensds-installer code
```bash
git clone https://github.com/opensds/opensds-installer.git
cd opensds-installer/ansible
```

### Install ansible tool
To install ansible, you can run `install_ansible.sh` directly or input these commands below:
```bash
sudo add-apt-repository ppa:ansible/ansible # This step is needed to upgrade ansible to version 2.4.2 which is required for the ceph backend.
sudo apt-get update
sudo apt-get install ansible
ansible --version # Ansible version 2.4.2 or higher is required for ceph; 2.0.2 or higher is needed for other backends.
```

### Configure opensds cluster variables:
##### System environment:
If you want to integrate OpenSDS with k8s csi, please modify `nbp_plugin_type` variable to `csi` in `group_vars/common.yml`:
```yaml
nbp_plugin_type: csi # standalone is the default integration way, but you can change it to 'csi', 'flexvolume'
```

##### LVM
If `lvm` is chosen as storage backend, modify `group_vars/osdsdock.yml`:
```yaml
enabled_backend: lvm # Change it according to the chosen backend. Supported backends include 'lvm', 'ceph', and 'cinder'
pv_devices: # Specify block devices and ensure them existed if you choose lvm
  #- /dev/sdc
  #- /dev/sdd
vg_name: "specified_vg_name" # Specify a name for VG if choosing lvm
```

Modify ```group_vars/lvm/lvm.yaml```, change pool name to be the same as `vg_name` above:
```yaml
tgtBindIp: 127.0.0.1 # change tgtBindIp to your real host ip, run 'ifconfig' to check
tgtConfDir: /etc/tgt/conf.d
pool:
  "vg001" # change pool name to be the same as vg_name
```

In addition, change `tgtBindIp` variable in `group_vars/lvm/lvm.yaml` to your real host ip.

##### Ceph
If `ceph` is chosen as storage backend, modify `group_vars/osdsdock.yml`:
```yaml
enabled_backend: ceph # Change it according to the chosen backend. Supported backends include 'lvm', 'ceph', and 'cinder'.
ceph_pools: # Specify pool name randomly if choosing ceph
  - rbd
  #- ssd
  #- sas
```

Modify ```group_vars/ceph/ceph.yaml```, change pool name to be the same as `ceph_pool_name`. But if you enable multiple pools, please append the current pool format:
```yaml
"rbd" # change pool name to be the same as ceph pool
```

Configure two files under ```group_vars/ceph```: `all.yml` and `osds.yml`. Here is an example:

```group_vars/ceph/all.yml```:
```yml
ceph_origin: repository
ceph_repository: community
ceph_stable_release: luminous # Choose luminous as default version
public_network: "192.168.3.0/24" # Run 'ip -4 address' to check the ip address
cluster_network: "{{ public_network }}"
monitor_interface: eth1 # Change to the network interface on the target machine
```
```group_vars/ceph/osds.yml```:
```yml
devices: # For ceph devices, append ONE or MULTIPLE devices like the example below:
    - '/dev/sda' # Ensure this device exists and available if ceph is chosen
    - '/dev/sdb' # Ensure this device exists and available if ceph is chosen
osd_scenario: collocated
```

### Check if the hosts can be reached
```bash
sudo ansible all -m ping -i local.hosts
```

### Run opensds-ansible playbook to start deploy
```bash
sudo ansible-playbook site.yml -i local.hosts
```

## Test it
### Configure opensds CLI tool
```bash
sudo cp /opt/opensds-linux-amd64/bin/osdsctl /usr/local/bin
export OPENSDS_ENDPOINT=http://127.0.0.1:50040
export OPENSDS_AUTH_STRATEGY=noauth
osdsctl pool list # Check if the pool resource is available
```

### Check if the csi plugin pod running
Since you have configured `nbp_plugin_type` above to `csi`, the system would run automatically starting all services, all you need is to check if the csi plugin pods are running:
```bash
kubectl get pod
```
If there is no error, the output should be like:
```bash
root@vultr-test:~/workplace/opensds-installer/ansible# kubectl get pod
NAME                                 READY     STATUS    RESTARTS   AGE
csi-attacher-opensdsplugin-0         2/2       Running   0          23s
csi-nodeplugin-opensdsplugin-nkn6j   2/2       Running   0          22s
csi-provisioner-opensdsplugin-0      2/2       Running   0          22s
```

### Create a default profile first.
```
osdsctl profile create '{"name": "default", "description": "default policy"}'
```

### Create pod with persistent volume.
```
cd /opt/opensds-k8s-linux-amd64/csi
kubectl create -f examples/kubernetes/nginx.yaml
```

After running this command, the output would be like:
```shell
root@vultr-test:/opt/opensds-k8s-linux-amd64/csi# kubectl get pod
NAME                                 READY     STATUS    RESTARTS   AGE
csi-attacher-opensdsplugin-0         2/2       Running   0          2m
csi-nodeplugin-opensdsplugin-nkn6j   2/2       Running   0          2m
csi-provisioner-opensdsplugin-0      2/2       Running   0          2m
nginx                                1/1       Running   0          23s
```

## Delete and purge opensds cluster
### Run opensds-ansible playbook to clean the environment
```bash
sudo ansible-playbook clean.yml -i local.hosts
```

### Run ceph-ansible playbook to clean ceph cluster if ceph is deployed
```bash
cd /opt/ceph-ansible
sudo ansible-playbook infrastructure-playbooks/purge-cluster.yml -i ceph.hosts
```

In addition, clean up the logical partition on the physical block device used by ceph, using the ```fdisk``` tool.

### Remove ceph-ansible source code (optional)
```bash
cd ..
sudo rm -rf /opt/ceph-ansible
```
