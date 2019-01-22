# Deploying OpenSDS with Salt

Provision one or more GNU/Linux hosts so we can deploy OpenSDS.

Solution View
=============

<a href="https://github.com/opensds/opensds">![Solution overview](solutionDesign.png)</a>

Example Vagrant setup
=====================
Allow minimum of 2GB+2CPU for virutalized host (12GB+6CPU is verified).

Download [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
Download [Vagrant](https://www.vagrantup.com/downloads.html)

Choose Linux Image
```
 mkdir ~/vagrant && cd ~/vagrant

 vagrant init generic/ubuntu1804    #UBUNTU

 vagrant init geerlingguy/centos7   #CENTOS
```

Configure a public network and sufficient compute resources.
```
 vi Vagrantfile

   config.vm.provider "virtualbox" do |vb|
     vb.memory = "12127"
     vb.cpus = 6
   end
   config.vm.network "public_network"

 vagrant up            # select 'bridge' or 'internet' interface
 vagrant ssh 
```

OpenSDS deployed with Salt
==========================
Now deploy OpenSDS as follows (expected run duration is 20-35 minutes).

```
 sudo -s
 rm -fr /srv/formulas/* /root/opensds-installer
 cd /root && git clone https://github.com/opensds/opensds-installer.git
 cd opensds-installer/salt
```

Review site deployment data-
```
 vi site.j2
```

Deploy on UBUNTU
```
 ./install.sh -i salt; ./install.sh -i opensds
```

Deploy on CENTOS (repeat command twice due to upstream bug)
```
  yum install git -y; ./install.sh -i salt; ./install.sh -i opensds;./install.sh -i opensds
```


Sample output (of interest)
============================

```
 ./install.sh -i salt
  ... etc ...
Summary for local
-------------
Succeeded: 32 (changed=27)
Failed:     0
-------------
Total states run:     32
Total run time:   65.047 s
Accepted Keys:
ubuntu1804.localdomain
Denied Keys:
Unaccepted Keys:
Rejected Keys:
done
  ... etc ...


Summary for local
-------------
Succeeded: 24 (changed=10)
Failed:     0
-------------
Total states run:     24
Total run time:  145.313 s


 ./install.sh -i opensds
prepare salt ...
run salt ...
local:
    ----------
    base:
        - opensds
 ... please be patient ...

  ...etc... 

Summary for local
--------------
Succeeded: 222 (changed=150)
Failed:      0
--------------
Total states run:     222
Total run time:  1472.874 s
local:
    ----------
    opensds:
        - default
Copy opensds-installer/conf/policy.json to /etc/opensds/
```

How to test opensds cluster
===========================

Ensure openSDS services are running
```
 sudo -s
 docker ps -a
 systemctl list-unit-files | grep opensds
 systemctl status opensds-<name>
```

Firstly configure opensds CLI tool:
```
 export OPENSDS_AUTH_STRATEGY=keystone
 export OPENSDS_ENDPOINT=http://127.0.0.1:50040   (or your <primary_host_ipa)
```
Check if the pool resource is avaibable
```
 osdsctl pool list
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

### Dashboard
The OpenSDS dashboard is available at http://{your_host_ip}:8088, please login the dashboard using the default admin credentials: admin/opensds@123. Create tenant, user, and profiles as admin. Multi-Cloud is also supported by dashboard. Logout of the dashboard as admin and login the dashboard again as a non-admin user to create volume, snapshot, expand volume, create volume from snapshot, create volume group.


How to purge and clean opensds cluster
========================================
```
 sudo /root/opensds-installer/salt/install.sh -r opensds
```
