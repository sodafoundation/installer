#!/bin/bash

# Copyright (c) 2018 Huawei Technologies Co., Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## This file is used to set global variables. 
## Before executing this file, please set the variables you need in the script/vars.sh file.

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
