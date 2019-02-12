# Deploying OpenSDS with Salt

Provision one or more GNU/Linux hosts so we can deploy OpenSDS.

Solution View
=============

<a href="https://github.com/opensds/opensds">![Solution overview](solutionDesign.png)</a>

Reference Vagrant setup
=======================
Refer to HACKING.md. Allow minimum of 2GB+2CPU for virutalized host.


OpenSDS deployed via Salt
=========================
Now deploy OpenSDS as follows - expected run duration is 20-55 minutes depending on your network bandwith and compute resources (i.e. 4CPU x 8GiB).

```
 sudo -s
 yum check-update -y || apt-get update -y
 yum install git libffi-devel -y || apt-get install git libffi-dev openssh-server -y
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
  ./install.sh -i salt; ./install.sh -i opensds;./install.sh -i opensds
```


How to test opensds cluster
===========================
Check openSDS services are running (check logs/status if necessary)
```
 sudo -s
 docker ps -a
 ps -ef | grep osds
 systemctl list-unit-files | grep opensds
```

Firstly configure opensds CLI tool:
```
 export OPENSDS_AUTH_STRATEGY=noauth
 export OPENSDS_ENDPOINT=http://127.0.0.1:50040   (or your <primary_host_ip)
```
Check if the pool resource is available
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
The OpenSDS dashboard is available at http://127.0.0.1:8088 or http://<primary_host_ip>:8088. 

Please login to the dashboard using the default admin credentials: admin/opensds@123. Create tenant, user, and profiles as admin. Multi-Cloud is also supported by dashboard.

Now logout from dashboard (as admin) and login the dashboard again as a non-admin user to create volume, snapshot, expand volume, create volume from snapshot, create volume group.


How to purge and clean opensds cluster
========================================
```
 sudo /root/opensds-installer/salt/install.sh -r opensds
 sudo /root/opensds-installer/salt/install.sh -r devstack # optional
```
