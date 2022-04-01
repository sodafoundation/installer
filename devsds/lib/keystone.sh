#!/usr/bin/env bash

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


_XTRACE_KEYSTONE=$(set +o | grep xtrace)
set +o xtrace

# 'stack' user is just for install keystone through devstack
soda::keystone::create_user(){
    if id ${STACK_USER_NAME} &> /dev/null; then
        return
    fi
    sudo useradd -s /bin/bash -d ${STACK_HOME} -m ${STACK_USER_NAME}
    echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
}


soda::keystone::remove_user(){
    userdel ${STACK_USER_NAME} -f -r
    rm /etc/sudoers.d/stack
}

soda::keystone::devstack_local_conf(){
DEV_STACK_LOCAL_CONF=${DEV_STACK_DIR}/local.conf
cat > $DEV_STACK_LOCAL_CONF << DEV_STACK_LOCAL_CONF_DOCK
[[local|localrc]]
# use TryStack git mirror
GIT_BASE=$STACK_GIT_BASE

# If the ``*_PASSWORD`` variables are not set here you will be prompted to enter
# values for them by ``stack.sh``and they will be added to ``local.conf``.
ADMIN_PASSWORD=$STACK_PASSWORD
DATABASE_PASSWORD=$STACK_PASSWORD
RABBIT_PASSWORD=$STACK_PASSWORD
SERVICE_PASSWORD=$STACK_PASSWORD

# Neither is set by default.
HOST_IP=$HOST_IP

# path of the destination log file.  A timestamp will be appended to the given name.
LOGFILE=\$DEST/logs/stack.sh.log

# Old log files are automatically removed after 7 days to keep things neat.  Change
# the number of days by setting ``LOGDAYS``.
LOGDAYS=2

ENABLED_SERVICES=mysql,key
# Using stable/queens branches
# ---------------------------------
KEYSTONE_BRANCH=$STACK_BRANCH
KEYSTONECLIENT_BRANCH=$STACK_BRANCH
DEV_STACK_LOCAL_CONF_DOCK
chown stack:stack $DEV_STACK_LOCAL_CONF
}

soda::keystone::soda_conf() {
cat >> $SODA_CONFIG_DIR/soda.conf << SODA_GLOBAL_CONFIG_DOC
[keystone_authtoken]
memcached_servers = $KEYSTONE_IP:11211
signing_dir = /var/cache/soda
cafile = /opt/stack/data/ca-bundle.pem
auth_uri = http://$KEYSTONE_IP/identity
project_domain_name = Default
project_name = service
user_domain_name = Default
password = $STACK_PASSWORD
# Whether to encrypt the password. If enabled, the value of the password must be ciphertext.
enable_encrypted = False
# Encryption and decryption tool. Default value is aes. The decryption tool can only decrypt the corresponding ciphertext.
pwd_encrypter = aes
username = $SODA_SERVER_NAME
auth_url = http://$KEYSTONE_IP/identity
auth_type = password

SODA_GLOBAL_CONFIG_DOC

cp $SODA_DIR/examples/policy.json $SODA_CONFIG_DIR
}

soda::keystone::create_user_and_endpoint(){
    . $DEV_STACK_DIR/openrc admin admin
    openstack user create --domain default --password $STACK_PASSWORD $SODA_SERVER_NAME
    openstack role add --project service --user soda admin
    openstack group create service
    openstack group add user service soda
    openstack role add service --project service --group service
    openstack group add user admins admin
    openstack service create --name soda$SODA_VERSION --description "soda Block Storage" soda$SODA_VERSION
    openstack endpoint create --region RegionOne soda$SODA_VERSION public http://$HOST_IP:50040/$SODA_VERSION/%\(tenant_id\)s
    openstack endpoint create --region RegionOne soda$SODA_VERSION internal http://$HOST_IP:50040/$SODA_VERSION/%\(tenant_id\)s
    openstack endpoint create --region RegionOne soda$SODA_VERSION admin http://$HOST_IP:50040/$SODA_VERSION/%\(tenant_id\)s
}

soda::keystone::delete_user(){
    . $DEV_STACK_DIR/openrc admin admin
    openstack service delete soda$SODA_VERSION
    openstack role remove service --project service --group service
    openstack group remove user service soda
    openstack group delete service    
    openstack user delete $SODA_SERVER_NAME --domain default
}

soda::keystone::delete_redundancy_data() {
    . $DEV_STACK_DIR/openrc admin admin
    openstack project delete demo
    openstack project delete alt_demo
    openstack project delete invisible_to_admin
    openstack user delete demo
    openstack user delete alt_demo
}

soda::keystone::download_code(){
    if [ ! -d ${DEV_STACK_DIR} ];then
        git clone ${STACK_GIT_BASE}/openstack-dev/devstack.git -b ${STACK_BRANCH} ${DEV_STACK_DIR}
        chown stack:stack -R ${DEV_STACK_DIR}
    fi

}

soda::keystone::install(){
    if [ "true" == $USE_CONTAINER_KEYSTONE ] 
    then
        KEYSTONE_IP=$HOST_IP
        docker pull sodaio/soda-authchecker:latest
        docker run -d --privileged=true --net=host --name=soda-authchecker sodaio/soda-authchecker:latest
        soda::keystone::soda_conf
        docker cp $TOP_DIR/lib/keystone.policy.json soda-authchecker:/etc/keystone/policy.json
    else
        if [ "true" != $USE_EXISTING_KEYSTONE ] 
        then
            KEYSTONE_IP=$HOST_IP
            soda::keystone::create_user
            soda::keystone::download_code
            soda::keystone::soda_conf

            # If keystone is ready to start, there is no need continue next step.
            if soda::util::wait_for_url http://$HOST_IP/identity "keystone" 0.25 4; then
                return
            fi
            soda::keystone::devstack_local_conf
            cd ${DEV_STACK_DIR}
            su $STACK_USER_NAME -c ${DEV_STACK_DIR}/stack.sh
            soda::keystone::create_user_and_endpoint
            soda::keystone::delete_redundancy_data
            # add soda customize policy.json for keystone
            cp $TOP_DIR/lib/keystone.policy.json /etc/keystone/policy.json
        else
            soda::keystone::soda_conf
            cd ${DEV_STACK_DIR}
            soda::keystone::create_user_and_endpoint
        fi    
    fi
}

soda::keystone::cleanup() {
    : #do nothing
}

soda::keystone::uninstall(){
    if [ "true" == $USE_CONTAINER_KEYSTONE ] 
    then
        docker stop soda-authchecker
        docker rm soda-authchecker
    else
        if [ "true" != $USE_EXISTING_KEYSTONE ] 
        then
            su $STACK_USER_NAME -c ${DEV_STACK_DIR}/unstack.sh
        else
            soda::keystone::delete_user
        fi
    fi
}

soda::keystone::uninstall_purge(){
    rm $STACK_HOME/* -rf
    soda::keystone::remove_user
}

## Restore xtrace
$_XTRACE_KEYSTONE
