#!/bin/bash

###########
#  Global #
###########
# Change it according to your backend, currently support 'lvm', 'ceph', 'cinder'
enabled_backend=ceph

# The IP (127.0.0.1) should be replaced with the opensds actual endpoint IP
#opensds_endpoint=http://10.10.3.100:50040
opensds_ip=10.10.3.100
opensds_endpoint=50040

# 'hotpot_only' is the default integration way, but you can change it to 'csi'
# or 'flexvolume'
nbp_plugin_type=hotpot_only

#etcd
port=2350
etcd_peer_port=1739

#dashboard
# Dashboard installation types are: 'container', 'source_code'
dashboard_installation_type=container

###########
#   LVM   #
###########
# change tgtBindIp to your real host ip, run 'ifconfig' to check
tgtBindIp=$opensds_ip

###########
#  Ceph   #
###########
# you can get info by command "ip -4 address"
#public_network:10.10.3.100/16
public_ip=10.10.3.100
public_br=16
# for example:eth0 or enp0s8
monitor_interface=enp0s8
# you should create device first
devices=[/dev/loop0]

