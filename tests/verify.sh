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


export_env_var () {
    export OPENSDS_ENDPOINT=http://$HOST_IP:50040
    export OPENSDS_AUTH_STRATEGY=`grep "opensds_auth_strategy" "$TOP_DIR/ansible/group_vars/auth.yml" | cut -f2 -d " "`
    export OS_AUTH_URL=http://$HOST_IP/identity
    export OS_USERNAME=admin
    export OS_PASSWORD=opensds@123
    export OS_TENANT_NAME=admin
    export OS_PROJECT_NAME=admin
    export OS_USER_DOMAIN_ID=default
}

cleanup_verify () {
    set -o errexit

    block_profile_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl profile list | grep default_block | cut -f2 -d " "`
    if [ -n "$block_profile_id" ]; then
        echo "Error: block_profile_id is not empty deleting";
        /opt/opensds-hotpot-linux-amd64/bin/osdsctl profile  delete $block_profile_id
    fi

    file_profile_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl profile list | grep default_file | cut -f2 -d " "`
    if [ -n "$file_profile_id" ]; then
        echo "Error: file_profile_id is not empty deleting";
        /opt/opensds-hotpot-linux-amd64/bin/osdsctl profile  delete $file_profile_id
    fi

}

purge_verify () {
    host_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl host list | grep test-host | cut -f2 -d " "`
    vol_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl volume list | grep test-001 | grep -v error | cut -f2 -d " "`

    if [ -n "$host_id" ] && [ -n "$vol_id" ]; then
        vol_attach_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl volume attachment list | grep $vol_id | grep $host_id | cut -f2 -d " "`
        if [ -n "$vol_attach_id" ]; then
            /opt/opensds-hotpot-linux-amd64/bin/osdsctl volume attachment delete $vol_attach_id
        fi
    fi

    if [ -n "$host_id" ] ; then
        /opt/opensds-hotpot-linux-amd64/bin/osdsctl host  delete $host_id
    fi

    if [ -n "$vol_id" ]; then
        /opt/opensds-hotpot-linux-amd64/bin/osdsctl volume  delete $vol_id
    fi

    fs_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl fileshare list | grep test_fileshare | cut -f2 -d " "`
    if [ -n "$fs_id" ]; then
        /opt/opensds-hotpot-linux-amd64/bin/osdsctl fileshare  delete $fs_id
    fi

    cleanup_verify

    # Stop and remove all docker containers/volumes
    # docker stop $(docker ps -aq)
    # docker system prune -f --volumes
    # docker rm $(docker ps -aq)
}

check_empty_error () {
    if [ -z "$2" ]; then
        echo "Error: $1 is not available";
        exit 1
    fi
}

verify_pool () {
    ./osdsctl pool list
    pool_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl pool list | grep -i available | cut -f2 -d " "`
    check_empty_error pool $pool_id
}

verify_profile () {

    ./osdsctl profile create '{"name": "default_block", "description": "default policy", "storageType": "block"}'
    ./osdsctl profile create '{"name":"default_file", "description":"default policy for fileshare", "storageType":"file"}'
    
    block_profile_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl profile list | grep default_block | cut -f2 -d " "`
    file_profile_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl profile list | grep default_file | cut -f2 -d " "`

    ./osdsctl profile  delete $block_profile_id
    ./osdsctl profile  delete $file_profile_id
}

verify_volume () {
    ./osdsctl profile create '{"name": "default_block", "description": "default policy", "storageType": "block"}'
    block_profile_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl profile list | grep default_block | cut -f2 -d " "`

    # Create, List and Delete Volume
    ./osdsctl volume create 1 --name=test-001
    
    add_delay
    
    ./osdsctl volume list
    vol_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl volume list | grep test-001 | grep -v error | cut -f2 -d " "`
    check_empty_error volume $vol_id
    ./osdsctl volume update $vol_id --description='test_vol description'
    
    vol_id_update=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl volume list | grep 'test_vol description'`
    check_empty_error "volume update"  $vol_id_update
    
    ./osdsctl volume show $vol_id

    ./osdsctl volume  delete $vol_id
    add_delay
    ./osdsctl profile  delete $block_profile_id
}

verify_host () {
    ./osdsctl profile create '{"name": "default_block", "description": "default policy", "storageType": "block"}'
    block_profile_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl profile list | grep default_block | cut -f2 -d " "`

    # Create, List and Delete Host
    ./osdsctl host create test-host --ip=$HOST_IP
    ./osdsctl host list
    host_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl host list | grep test-host | cut -f2 -d " "`
    check_empty_error host $host_id
    ./osdsctl host update $host_id --hostName='test-host-updated'
    ./osdsctl host show $host_id
    ./osdsctl host  delete $host_id    

    add_delay
    ./osdsctl profile  delete $block_profile_id
}

verify_attachment () {
    ./osdsctl profile create '{"name": "default_block", "description": "default policy", "storageType": "block"}'
    block_profile_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl profile list | grep default_block | cut -f2 -d " "`

    ./osdsctl host create test-host-attach --ip=$HOST_IP
    host_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl host list | grep test-host-attach | cut -f2 -d " "`
    check_empty_error host $host_id
    initiator=`cat /etc/iscsi/initiatorname.iscsi  | grep "InitiatorName=" | cut -f2 -d "="`
    
    ./osdsctl host initiator add $host_id $initiator "iscsi"
    ./osdsctl volume create 1 --name=test_vol_attach
    vol_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl volume list | grep test_vol_attach | cut -f2 -d " "`
    check_empty_error volume $vol_id
    ./osdsctl volume attachment create $vol_id $host_id
    ./osdsctl volume attachment list
    vol_attach_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl volume attachment list | grep $vol_id | grep $host_id | cut -f2 -d " "`
    check_empty_error volume-attachment $vol_attach_id
    ./osdsctl volume attachment show $vol_attach_id
    ./osdsctl volume attachment delete $vol_attach_id

    ./osdsctl volume  delete $vol_id
    ./osdsctl host  delete $host_id    

    add_delay
    ./osdsctl profile  delete $block_profile_id
}

verify_fileshare () {
    ./osdsctl profile create '{"name":"default_file", "description":"default policy for fileshare", "storageType":"file"}'
    file_profile_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl profile list | grep default_file | cut -f2 -d " "`

    # Create, List and Delete FileShare
    ./osdsctl fileshare create 1 -n "test_fileshare" -p $file_profile_id
    ./osdsctl fileshare list
    fs_id=`/opt/opensds-hotpot-linux-amd64/bin/osdsctl fileshare list | grep test_fileshare | cut -f2 -d " "`
    check_empty_error fileshare $fs_id
    ./osdsctl fileshare update $fs_id --description='test_fileshare description'
    ./osdsctl fileshare show $fs_id
    ./osdsctl fileshare  delete $fs_id    

    add_delay
    ./osdsctl profile  delete $file_profile_id
}

verify_hotpot () {
    cd /opt/opensds-hotpot-linux-amd64/bin/

    verify_pool
    verify_profile
    verify_volume
    verify_host
    verify_attachment
    verify_fileshare

}

verify_gelato () {

    # Verify docker execution status

    exited=`docker ps -a | grep Exited | grep -v mysql`
    if [ -n "$exited" ]; then
        echo "Error: Check for docker execution status of gelato failed";
    fi
}

verify () {
    set -o errexit
    set -x

    cd $TOP_DIR
    export_env_var
    purge_verify

    enabled=`grep "deploy_project" "$TOP_DIR/ansible/group_vars/common.yml" | cut -f2 -d " "`

    if [ "$enabled" != "gelato" ]; then
        verify_hotpot
    fi
    
    if [ "$enabled" != "hotpot" ]; then
        verify_gelato
    fi

    echo "-- Verify finished --"
}
