#!/bin/bash

# Copyright 2020 The OpenSDS Authors.
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


add_delay () {
    sleep 1
}

get_default_host_ip() {
    local host_ip=$1
    local af=$2
    # Search for an IP unless an explicit is set by ``HOST_IP`` environment variable
    if [ -z "$host_ip" ]; then
        host_ip=""
        # Find the interface used for the default route
        host_ip_iface=${host_ip_iface:-$(ip -f "$af" route | awk '/default/ {print $5}' | head -1)}
        local host_ips
        host_ips=$(LC_ALL=C ip -f "$af" addr show "${host_ip_iface}" | sed /temporary/d |awk /$af'/ {split($2,parts,"/");  print parts[1]}')
        local ip
        for ip in $host_ips; do
            host_ip=$ip
            break;
        done
    fi
    echo "$host_ip"
}

# create_lvm_volume_group <vg name> <size> <file name>
# Example usage: create_lvm_volume_group opensds-volumes 10G /opt/opensds/opensds-volume.img
create_lvm_volume_group () {
    local vg=$1
    local size=$2
    local backing_file=$3

    modprobe dm_thin_pool

    dir_name=`dirname("$backing_file")`
    mkdir "$dir_name" -p
    if ! sudo vgs $vg &> /dev/null ; then
        [[ -f $backing_file ]] || truncate -s $size $backing_file
        local vg_dev
        vg_dev=`sudo losetup -f --show $backing_file`

        if ! sudo pvs $vg_dev; then
            sudo pvcreate $vg_dev
        fi

        if ! sudo vgs $vg; then
            sudo vgcreate $vg $vg_dev
        fi
    fi
}
