# Deploying OpenSDS with Salt

Deploy OpenSDS (www.opensds.io) using Salt. This is an experimental solution using repeatable patterns of jinja/yaml to deploy cloud-native stack using infrastructure as code. Please use Salt 2018.3.4 or earlier while potential impacts from the <a href="https://docs.saltstack.com/en/develop/topics/releases/2019.2.0.html#non-backward-compatible-change-to-yaml-renderer">NON-BACKWARD-COMPATIBLE-CHANGE-TO-YAML-RENDERER</a> are reviewed by the <a href="https://github.com/saltstack-formulas">saltstack-formulas community</a>.

Software versions
=================
Verified on CENTOS-7, UBUNTU-18, and OPENSUSE-15 with Salt version 2018.3.

Solution View
=============

<a href="https://github.com/opensds/opensds">![Solution overview](solutionDesign.png)</a>

Reference Vagrant setup
=======================
Refer to HACKING.md. Prefer a minimum of 6GB+4CPU per virutalized hosts.


Procedure
===========
Deploy OpenSDS using the steps below. The expected installer duration is 20-55 minutes depending on your network bandwith and compute resources (we recommend at least 4CPU x 8G ram x 60G rootdisk).

```
 sudo -s
 cd /root && git clone https://github.com/opensds/opensds-installer.git
 cd opensds-installer/salt
```

Install Salt on UBUNTU/CENTOS/OpenSUSE_15
```
 ./install.sh -i salt
```
Reboot if kernel got upgraded. If in doubt, reboot anyway.
```
init 6
```

Review site deployment data and set your public ipv4 address-
```
 vi site.j2
```

Deploy OpenSDS on UBUNTU/CENTOS/OpenSUSE_15
```
sudo -s
cd /root/opensds-installer/salt/; install.sh -i opensds
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

If firewalld or iptables is running open the port.
```
iptables -I INPUT 1 -i eth1 -p tcp --dport 8088 -j ACCEPT
```

Please login to the dashboard using the default admin credentials: admin/opensds@123. Create tenant, user, and profiles as admin. Multi-Cloud is also supported by dashboard.

Now logout from dashboard (as admin) and login the dashboard again as a non-admin user to create volume, snapshot, expand volume, create volume from snapshot, create volume group.


How to purge and clean opensds cluster
========================================
```
 sudo /root/opensds-installer/salt/install.sh -r opensds
 sudo /root/opensds-installer/salt/install.sh -r devstack # optional
```
