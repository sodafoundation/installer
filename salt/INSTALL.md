# Deploying OpenSDS with Salt

Provision one or more GNU/Linux hosts so we can deploy OpenSDS.

Solution View
=============

<a href="https://github.com/opensds/opensds">![Solution overview](solutionDesign.png)</a>

Example Vagrant setup
=====================
Allow minimum of 2GB+2CPU for virutalized host (12GB+6CPU is verified).

Download [VirtualBox](https://www.virtualbox.org/wiki/Downloads) and download [Vagrant](https://www.vagrantup.com/downloads.html)

Choose a vagrant Linux image.
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
```

Start the virtual environment.
```
 vagrant up            # select 'bridge' or 'internet' interface
 vagrant ssh 
```

OpenSDS deployed via Salt
=========================
Now deploy OpenSDS as follows - expected run duration is 20-55 minutes depending on your network bandwith and compute resources (i.e. 4CPU x 8GiB).

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
Succeeded: 231 (changed=152)
Failed:      0
--------------
Total states run:     231
Total run time:  4555.575 s
local:
    The val default was already in the list opensds
Copy opensds-installer/conf/policy.json to /etc/opensds/




./install.sh -r opensds  #removal
...

Summary for local
--------------
Succeeded: 144 (changed=70)
Failed:      2
--------------
Total states run:     146
Total run time:   437.846 s

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
 export OPENSDS_AUTH_STRATEGY=noauth
 export OPENSDS_ENDPOINT=http://127.0.0.1:50040   (or your <primary_host_ip)
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
The OpenSDS dashboard is available at http://127.0.0.1:8088 or http://<primary_host_ip>:8080. 

Please login to the dashboard using the default admin credentials: admin/opensds@123. Create tenant, user, and profiles as admin. Multi-Cloud is also supported by dashboard.

Now logout from the dashboard (as admin) and login the dashboard again as a non-admin user to create volume, snapshot, expand volume, create volume from snapshot, create volume group.


How to purge and clean opensds cluster
========================================
```
 sudo /root/opensds-installer/salt/install.sh -r opensds
 sudo /root/opensds-installer/salt/install.sh -r devstack # optional
```
