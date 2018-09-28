#!/bin/bash

source ./script/vars.sh
var_path=./group_vars

#etcd
sed -i 's/^etcd_port: .*/etcd_port: '"$port"'/g' $var_path/osdsdb.yml
sed -i 's/^etcd_peer_port: .*/etcd_peer_port: '"$etcd_peer_port"'/g' $var_path/osdsdb.yml

#commom
sed -i 's/^opensds_endpoint: .*/opensds_endpoint: http:\/\/'"$opensds_ip"':'"$opensds_endpoint"'/g' $var_path/common.yml
sed -i 's/^nbp_plugin_type: .*/nbp_plugin_type: '"$nbp_plugin_type"'/g' $var_path/common.yml

#dashboard.yml
sed -i 's/^dashboard_installation_type: .*/dashboard_installation_type: '"$dashboard_installation_type"'/g' $var_path/dashboard.yml

#osdsdock.yml
sed -i 's/^enabled_backend: .*/enabled_backend: '"$enabled_backend"'/g' $var_path/osdsdock.yml

#lvm.yml
sed -i 's/^tgtBindIp: .*/tgtBindIp: '"$tgtBindIp"'/g' $var_path/lvm/lvm.yaml

#ceph/all.yml
sed -i 's/^public_network: .*\/*/public_network: '"$public_ip"'\/'"$public_br"'/g' $var_path/ceph/all.yml
sed -i 's/^monitor_interface: .*/monitor_interface: '"$monitor_interface"'/g' $var_path/ceph/all.yml
sed -i 's?^devices:.*?devices: '"$devices"'?g' $var_path/ceph/all.yml
