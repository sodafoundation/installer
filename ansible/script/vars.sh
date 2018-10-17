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

