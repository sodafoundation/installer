# Deploying OpenSDS with Salt

Provision one or more GNU/Linux hosts so we can deploy OpenSDS.

## Vagrant environment

Allow minimum of 2GB+2CPU for virutalized host (12GB+6CPU is verified).
```
Download https://www.virtualbox.org/wiki/Downloads
Download https://www.vagrantup.com/downloads.html
$ mkdir ~/vagrant && cd ~/vagrant
```
Choose Linux Image
```
$ vagrant init generic/ubuntu1804    #UBUNTU

$ vagrant init geerlingguy/centos7   #CENTOS
```
Configure Vagrantfile with public network, and sufficient cpu/ram resources.
```
$ vi Vagrantfile

   config.vm.provider "virtualbox" do |vb|
     vb.memory = "12127"
     vb.cpus = 6
   end
   config.vm.network "public_network"

$ vagrant up            # select 'bridge' or 'internet' interface
$ vagrant ssh 
```
Note: On CentOS install git
```
$ yum install git -y
```


## Install OpenSDS with Salt
```
$ sudo -s
$ rm -fr /srv/formulas/* /root/opensds-installer
$ cd /root && git clone https://github.com/opensds/opensds-installer.git
$ cd opensds-installer/salt
```
Cleandown loopback devices
```
$ losetup -D
```

You must set your primary host ip address now
```
$ vi site.j2
```

Deploy OpenSDS
```
$ ./install.sh -i salt
```
UBUNTU
```
$ ./install.sh -i opensds
```
CENTOS
```
$ ./install.sh -i opensds;./install.sh -i opensds
```
Note: We run twice to workaround upstream devstack/CentOS bug.

## Example Output
```
$ ./install.sh -i salt
  ... etc ...
Summary for local
-------------
Succeeded: 31 (changed=22)
Failed:     0
-------------
Total states run:     31
Total run time:   60.999 s
Accepted Keys:
10.0.2.15
Denied Keys:
Unaccepted Keys:
Rejected Keys:
using [docker] fixes branch
done
  ... etc ...
Summary for local
-------------
Succeeded: 11 (changed=6)
Failed:     0
-------------
Total states run:     11
Total run time:   76.144 s


$ ./install.sh -i opensds
  ... etc ...
Summary for local
--------------
Succeeded: 197 (changed=107)
Failed:      0
--------------
Total states run:     197
Total run time:  2333.544 s
local:
    ----------
    opensds:
        - default
```

## How to test opensds cluster

Ensure openSDS services are running
```
$ ps -ef | grep 'osds'
$ sudo docker ps -a
```

Firstly configure opensds CLI tool:
```
$ sudo cp /opt/opensds-linux-amd64/bin/osds* /usr/bin
$ export OPENSDS_ENDPOINT=http://<primary_host_ip>:50040
$ source /opt/opensds-linux-amd64-devstack/openrc admin admin
```
Check if the pool resource is avaibable
```
$ osdsctl pool list
```

Then create a default profile:
```
$ osdsctl profile create '{"name": "default", "description": "default policy"}'
```

Create a volume:
```
$ osdsctl volume create 1 --name=test-001
```

List all volumes:
```
$ osdsctl volume list
```

Delete the volume:
```
$ osdsctl volume delete <your_volume_id>
```

### OpenSDS UI
OpenSDS UI dashboard is available at http://{your_host_ip}:8088, please login the dashboard using the default admin credentials: admin/opensds@123. Create tenant, user, and profiles as admin. Multi-Cloud is also supported by dashboard.  

Logout of the dashboard as admin and login the dashboard again as a non-admin user to create volume, snapshot, expand volume, create volume from snapshot, create volume group.

### How to purge and clean opensds cluster
Run automation to clean the environment
```
$ sudo /root/opensds-installer/salt/install.sh -i opensds/clean
```
