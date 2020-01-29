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
# TEST Role: common
#
test_opensds_101 () {
    test_opensds_hotpot 101 "common"
}

#
# TEST Role: keystone
#
test_opensds_102 () {
    test_opensds_hotpot 102 "keystone"
}

#
# TEST Role: hotpot
#
test_opensds_103 () {
    test_opensds_hotpot 103 "hotpot"
}


#
# TEST Role: dock
#
test_opensds_104 () {
    test_opensds_hotpot 104 "dock"
}


#
# TEST Role: sushi
#
test_opensds_105 () {
    test_opensds_hotpot 105 "sushi"
}


#
# TEST Role: dashboard
#
test_opensds_106 () {
    test_opensds_hotpot 106 "dashboard"
}


#
# TEST Role: telemetry
#
test_opensds_107 () {
    test_opensds_hotpot 107 "telemetry"
}

#
# TEST Role: orchestration
#
test_opensds_108 () {
    test_opensds_hotpot 108 "orchestration"
}


#
# TEST Role: gelato
#
test_opensds_109 () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: 109"
    echo "  File Modified: ansible/group_vars/common.yml"
    echo "    install_from: release"
    echo "    deploy_project: gelato"
    echo "====================================================================================="
    
    cd $TOP_DIR
    cp ansible/group_vars/common.yml ansible/group_vars/common.yml.bk

    sed -i 's/^host_ip: .*/host_ip: '"$HOST_IP"'/g' ansible/group_vars/common.yml
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^deploy_project: .*/deploy_project: '"gelato"'/g' ansible/group_vars/common.yml

    test_tags "gelato"

    mv ansible/group_vars/common.yml.bk ansible/group_vars/common.yml
}







#
# test_config <file> <field> <value>
#
test_config () {
    echo "  Changed [File] [Field] [Value]: $1  { $2: $3 }"
    sed -i "s/^$2: .*/$2: $3/g" $1
}

#
# test_tags_wrapper_start <test_id>
#
test_tags_wrapper_start () {
    echo ""
    echo ""
    echo "====================================================================================="
    echo "Test: Ansible, ID: " "$1"
}

test_tags_wrapper_end () {
    echo "====================================================================================="
}

#
# test_file_bkx <file>
#
test_file_bk1 () {
    cd $TOP_DIR
    cp "$1" "$1.bk"
}
test_file_bk2 () {
    cd $TOP_DIR
    mv "$1.bk" "$1"
}

#
# test_opensds_hotpot <TestID> <tags>
#
test_opensds_hotpot () {

    test_tags_wrapper_start $1
    test_file_bk1 ansible/group_vars/common.yml

    test_config ansible/group_vars/common.yml host_ip  $HOST_IP
    test_config ansible/group_vars/common.yml install_from  release
    test_config ansible/group_vars/common.yml deploy_project  hotpot

    test_tags $2

    test_tags_wrapper_end
}


test_tags () {
    if [ "$debug" = "1" ]; then
        ver="-vv"
    fi
    sudo -E env "PATH=$PATH" ansible-playbook ansible/site.yml -i ansible/local.hosts --tags=$1 $ver
    verify_and_clean_tags $1
}

verify_and_clean_tags () {
    if [ "$debug" = "1" ]; then
        ver="-vv"
    fi

    sudo -E env "PATH=$PATH" ansible-playbook ansible/clean.yml -i ansible/local.hosts --tags=$1 $ver

    purge_installation
    test_file_bk2 ansible/group_vars/common.yml
}