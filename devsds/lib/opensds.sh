#!/bin/bash

# Copyright 2020 The SODA Authors.
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

# SODA relative operation.

_XTRACE_SODA=$(set +o | grep xtrace)
set +o xtrace


soda:soda:configuration(){

# Copy api spec file to configuration path
SODA_API_DIR=${SODA_DIR}/../../api
cp $SODA_API_DIR/openapi-spec/swagger.yaml $SODA_CONFIG_DIR

# Set global configuration.
cat >> $SODA_CONFIG_DIR/soda.conf << soda_GLOBAL_CONFIG_DOC
[osdsapiserver]
api_endpoint = 0.0.0.0:50040
auth_strategy = $SODA_AUTH_STRATEGY
# If https is enabled, the default value of cert file
# is /opt/soda-security/sodafoundation/api-cert.pem,
# and key file is /opt/soda-security/sodafoundation/api-key.pem
https_enabled = False
beego_https_cert_file =
beego_https_key_file =

[osdslet]
api_endpoint = $HOST_IP:50049

[osdsdock]
api_endpoint = $HOST_IP:50050
# Specify which backends should be enabled, sample,ceph,cinder,lvm,nfs and so on.
enabled_backends = $SODA_BACKEND_LIST

[database]
endpoint = $HOST_IP:$ETCD_PORT,$HOST_IP:$ETCD_PEER_PORT
driver = etcd

soda_GLOBAL_CONFIG_DOC
}

soda::soda::install(){
    soda:soda:configuration
# Run osdsdock and osdslet daemon in background.
(
    cd ${SODA_API_DIR}
    sudo build/out/bin/osdsapiserver --daemon
    cd ..
    sudo controller/build/out/bin/osdslet --daemon
    sudo dock/build/out/bin/osdsdock --daemon

    soda::echo_summary "Waiting for osdsapiserver to come up."
    soda::util::wait_for_url localhost:50040 "osdsapiserver" 0.5 80
    if [ $SODA_AUTH_STRATEGY == "keystone" ]; then
        if [ "true" == $USE_CONTAINER_KEYSTONE ]
        then
            KEYSTONE_IP=$HOST_IP
            export OS_AUTH_URL=http://$KEYSTONE_IP/identity
            export OS_USERNAME=admin
            export OS_PASSWORD=soda@123
            export OS_TENANT_NAME=admin
            export OS_PROJECT_NAME=admin
            export OS_USER_DOMAIN_ID=default
        else
            local xtrace
            xtrace=$(set +o | grep xtrace)
            set +o xtrace
            source $DEV_STACK_DIR/openrc admin admin
            $xtrace
        fi
    fi

    # Copy bash completion script to system.
    cp ${SODA_API_DIR}/osdsctl/completion/osdsctl.bash_completion /etc/bash_completion.d/

    export soda_AUTH_STRATEGY=$SODA_AUTH_STRATEGY
    export soda_ENDPOINT=http://localhost:50040
    ${SODA_API_DIR}/build/out/bin/osdsctl profile create '{"name": "default_block", "description": "default policy", "storageType": "block"}'
    ${SODA_API_DIR}/build/out/bin/osdsctl profile create '{"name": "default_file", "description": "default policy", "storageType": "file", "provisioningProperties":{"ioConnectivity": {"accessProtocol": "NFS"},"DataStorage":{"StorageAccessCapability":["Read","Write","Execute"]}}}'

    if [ $? == 0 ]; then
        soda::echo_summary devsds installed successfully !! 
    fi
)
}

soda::soda::cleanup() {
    sudo killall -9 osdsapiserver osdslet osdsdock &>/dev/null
}

soda::soda::uninstall(){
     : # Do nothing
}

soda::soda::uninstall_purge(){
     : # Do nothing
}

# Restore xtrace
$_XTRACE_SODA
