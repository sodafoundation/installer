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


#
# TEST: Hotpot
#
test_opensds_01 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 01"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: hotpot"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"hotpot"'/g' ansible/group_vars/common.yml
    
    install
}

#
# TEST: Gelato
#
test_opensds_02 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 02"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: gelato"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"gelato"'/g' ansible/group_vars/common.yml
    
    install
}

#
# TEST: all
#
test_opensds_03 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 03"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: all"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"all"'/g' ansible/group_vars/common.yml
    
    install
}

#
# TEST: telemetry
#
test_opensds_04 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 04"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: hotpot"
    echo "  File Modified: ansible/group_vars/telemetry.yml"
    echo "    enable_telemetry_tools: true"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"hotpot"'/g' ansible/group_vars/common.yml
    sed -i 's/^enable_telemetry_tools: .*/enable_telemetry_tools: '"true"'/g' ansible/group_vars/telemetry.yml
    sed -i 's/^enable_orchestration: .*/enable_orchestration: '"false"'/g' ansible/group_vars/orchestration.yml
    
    install
}

#
# TEST: orchestration
#
test_opensds_05 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 05"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: hotpot"
    echo "  File Modified: ansible/group_vars/orchestration.yml"
    echo "    enable_orchestration: true"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"hotpot"'/g' ansible/group_vars/common.yml
    sed -i 's/^enable_telemetry_tools: .*/enable_telemetry_tools: '"false"'/g' ansible/group_vars/telemetry.yml
    sed -i 's/^enable_orchestration: .*/enable_orchestration: '"true"'/g' ansible/group_vars/orchestration.yml
    
    install
}

#
# TEST: telemetry+orchestration
#
test_opensds_06 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 06"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: hotpot"
    echo "  File Modified: ansible/group_vars/telemetry.yml"
    echo "    enable_telemetry_tools: true"
    echo "  File Modified: ansible/group_vars/orchestration.yml"
    echo "    enable_orchestration: true"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"hotpot"'/g' ansible/group_vars/common.yml
    sed -i 's/^enable_telemetry_tools: .*/enable_telemetry_tools: '"true"'/g' ansible/group_vars/telemetry.yml
    sed -i 's/^enable_orchestration: .*/enable_orchestration: '"true"'/g' ansible/group_vars/orchestration.yml
    
    install
}






#
# TEST: repository
#
test_opensds_07 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 07"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: repository"
    echo "    deploy_project: hotpot"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"repository"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"hotpot"'/g' ansible/group_vars/common.yml
    
    install
}

test_opensds_08 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 08"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: repository"
    echo "    deploy_project: gelato"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"repository"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"gelato"'/g' ansible/group_vars/common.yml
    
    install
}

test_opensds_09 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 09"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: repository"
    echo "    deploy_project: all"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"repository"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"all"'/g' ansible/group_vars/common.yml
    
    install
}

test_opensds_10 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 10"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: repository"
    echo "    deploy_project: hotpot"
    echo "  File Modified: ansible/group_vars/telemetry.yml"
    echo "    enable_telemetry_tools: true"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"repository"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"hotpot"'/g' ansible/group_vars/common.yml
    sed -i 's/^enable_telemetry_tools: .*/enable_telemetry_tools: '"true"'/g' ansible/group_vars/telemetry.yml
    sed -i 's/^enable_orchestration: .*/enable_orchestration: '"false"'/g' ansible/group_vars/orchestration.yml
    
    install
}

test_opensds_11 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 11"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: repository"
    echo "    deploy_project: hotpot"
    echo "  File Modified: ansible/group_vars/orchestration.yml"
    echo "    enable_orchestration: true"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"repository"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"hotpot"'/g' ansible/group_vars/common.yml
    sed -i 's/^enable_telemetry_tools: .*/enable_telemetry_tools: '"false"'/g' ansible/group_vars/telemetry.yml
    sed -i 's/^enable_orchestration: .*/enable_orchestration: '"true"'/g' ansible/group_vars/orchestration.yml

    install
}

test_opensds_12 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 12"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: repository"
    echo "    deploy_project: hotpot"
    echo "  File Modified: ansible/group_vars/telemetry.yml"
    echo "    enable_telemetry_tools: true"
    echo "  File Modified: ansible/group_vars/orchestration.yml"
    echo "    enable_orchestration: true"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"repository"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"hotpot"'/g' ansible/group_vars/common.yml
    sed -i 's/^enable_telemetry_tools: .*/enable_telemetry_tools: '"true"'/g' ansible/group_vars/telemetry.yml
    sed -i 's/^enable_orchestration: .*/enable_orchestration: '"true"'/g' ansible/group_vars/orchestration.yml
    
    install
}





#
# TEST: container
#
test_opensds_13 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 13"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: container"
    echo "    deploy_project: hotpot"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"container"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"hotpot"'/g' ansible/group_vars/common.yml

    install
}

test_opensds_14 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 14"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: container"
    echo "    deploy_project: gelato"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"container"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"gelato"'/g' ansible/group_vars/common.yml

    install
}

test_opensds_14 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 03"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: container"
    echo "    deploy_project: all"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"container"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"all"'/g' ansible/group_vars/common.yml

    install
}

test_opensds_15 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 15"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: container"
    echo "    deploy_project: hotpot"
    echo "  File Modified: ansible/group_vars/telemetry.yml"
    echo "    enable_telemetry_tools: true"
    echo "  File Modified: ansible/group_vars/orchestration.yml"
    echo "    enable_orchestration: true"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"container"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"hotpot"'/g' ansible/group_vars/common.yml
    sed -i 's/^enable_telemetry_tools: .*/enable_telemetry_tools: '"true"'/g' ansible/group_vars/telemetry.yml
    sed -i 's/^enable_orchestration: .*/enable_orchestration: '"true"'/g' ansible/group_vars/orchestration.yml

    install
}

#
# opensds_auth_strategy=noauth
#
test_opensds_16 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 16"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: hotpot"
    echo "  File Modified: ansible/group_vars/auth.yml"
    echo "    opensds_auth_strategy: noauth"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"hotpot"'/g' ansible/group_vars/common.yml
    sed -i 's/^opensds_auth_strategy: .*/opensds_auth_strategy: '"noauth"'/g' ansible/group_vars/auth.yml

    install
}

test_opensds_17 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 17"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: gelato"
    echo "  File Modified: ansible/group_vars/auth.yml"
    echo "    opensds_auth_strategy: noauth"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"gelato"'/g' ansible/group_vars/common.yml
    sed -i 's/^opensds_auth_strategy: .*/opensds_auth_strategy: '"noauth"'/g' ansible/group_vars/auth.yml

    install
}

test_opensds_18 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 18"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: all"
    echo "  File Modified: ansible/group_vars/auth.yml"
    echo "    opensds_auth_strategy: noauth"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"all"'/g' ansible/group_vars/common.yml
    sed -i 's/^opensds_auth_strategy: .*/opensds_auth_strategy: '"noauth"'/g' ansible/group_vars/auth.yml

    install
}


#
# install_keystone_with_docker=false
#
test_opensds_19 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 19"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: hotpot"
    echo "  File Modified: ansible/group_vars/auth.yml"
    echo "    install_keystone_with_docker: true"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"hotpot"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_keystone_with_docker: .*/install_keystone_with_docker: '"true"'/g' ansible/group_vars/auth.yml

    install
}

test_opensds_20 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 20"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: gelato"
    echo "  File Modified: ansible/group_vars/auth.yml"
    echo "    install_keystone_with_docker: true"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"gelato"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_keystone_with_docker: .*/install_keystone_with_docker: '"true"'/g' ansible/group_vars/auth.yml

    install
}

test_opensds_21 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 21"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: all"
    echo "  File Modified: ansible/group_vars/auth.yml"
    echo "    install_keystone_with_docker: true"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"all"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_keystone_with_docker: .*/install_keystone_with_docker: '"true"'/g' ansible/group_vars/auth.yml

    install
}

#
# sushi_plugin_type=csi
#
test_opensds_22 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 22"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: hotpot"
    echo "  File Modified: ansible/group_vars/sushi.yml"
    echo "    sushi_plugin_type: csi"
    echo "====================================================================================="
    
    cd $TOP_DIR
    backup_config

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"hotpot"'/g' ansible/group_vars/common.yml
    sed -i 's/^sushi_plugin_type: .*/sushi_plugin_type: '"csi"'/g' ansible/group_vars/sushi.yml

    install
}


#------------------
# Utility Functions
#------------------

backup_config () {
    cd $TOP_DIR
    cp ansible/group_vars/common.yml ansible/group_vars/common.yml.bk
    cp ansible/group_vars/telemetry.yml ansible/group_vars/telemetry.yml.bk
    cp ansible/group_vars/orchestration.yml ansible/group_vars/orchestration.yml.bk
    cp ansible/group_vars/auth.yml ansible/group_vars/auth.yml.bk
    cp ansible/group_vars/sushi.yml ansible/group_vars/sushi.yml.bk

}

revert_config () {
    cd $TOP_DIR
    mv ansible/group_vars/common.yml.bk ansible/group_vars/common.yml || true
    mv ansible/group_vars/telemetry.yml.bk ansible/group_vars/telemetry.yml || true
    mv ansible/group_vars/orchestration.yml.bk ansible/group_vars/orchestration.yml || true
    mv ansible/group_vars/auth.yml.bk ansible/group_vars/auth.yml || true
    mv ansible/group_vars/sushi.yml.bk ansible/group_vars/sushi.yml || true
}

install () {
    if [ "$debug" = "1" ]; then
        ver="-vv"
    fi
    sudo -E env "PATH=$PATH" ansible-playbook ansible/site.yml -i ansible/local.hosts $ver
}

purge_installation () {
    cd $TOP_DIR/ansible && ansible-playbook clean.yml -i local.hosts
    revert_config

    if [ -e /opt/ceph-ansible/infrastructure-playbooks/purge-cluster.yml ]; then
        cd /opt/ceph-ansible && ansible-playbook infrastructure-playbooks/purge-cluster.yml -i ceph.hosts -e ireallymeanit=yes
        rm -rf /opt/ceph-ansible
    fi
}


