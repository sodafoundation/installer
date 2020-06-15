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

# This script helps new contributors or users set up their local workstation
# for sodafoundation installation and development.

# Project to install
TOP_DIR=$(cd $(dirname "$0") && pwd)
source $TOP_DIR/sdsrc

SODA_PROJECT=${SODA_PROJECT:-all}
if [ "${SODA_PROJECT}" = "all" ]; then
    SODA_PROJECT="api,controller, dock"
fi

echo "SODA projects to be installed is ${SODA_PROJECT}"



# Temporary directory
OPT_DIR=/opt/sodafoundation
mkdir -p $OPT_DIR

# Golang version
MINIMUM_GO_VERSION=${MINIMUM_GO_VERSION:-go1.12.1}
GOENV_PROFILE=${GOENV_PROFILE:-/etc/profile.d/goenv.sh}

# Log file
LOG_DIR=/var/log/sodafoundation
LOGFILE=${LOGFILE:-/var/log/sodafoundation/bootstrap.log}
mkdir -p $LOG_DIR

# Log function
log() {
    DATE=`date "+%Y-%m-%d %H:%M:%S"`
    USER=$(whoami)
    echo "${DATE} [INFO] $@"
    echo "${DATE} ${USER} execute $0 [INFO] $@" >> $LOGFILE
}

log_error ()
{
    DATE=`date "+%Y-%m-%d %H:%M:%S"`
    USER=$(whoami)
    echo "${DATE} [ERROR] $@" 2>&1
    echo "${DATE} ${USER} execute $0 [ERROR] $@" >> $LOGFILE
}
log Sodafoundation \(api, controller and dock\) bootstrap starting ...

# load profile
source /etc/profile

# if not found go, install it.
check_and_install_go(){
    if [[ -z "$(which go)" ]]; then
        log "Golang is not installed, downloading..."
        wget https://storage.googleapis.com/golang/${MINIMUM_GO_VERSION}.linux-amd64.tar.gz -O $OPT_DIR/${MINIMUM_GO_VERSION}.linux-amd64.tar.gz > /dev/null
        log "tar xzf $OPT_DIR/${MINIMUM_GO_VERSION}.linux-amd64.tar.gz -C /usr/local/"
        tar xzf $OPT_DIR/${MINIMUM_GO_VERSION}.linux-amd64.tar.gz -C /usr/local/
        echo 'export GOROOT=/usr/local/go' > $GOENV_PROFILE
        echo 'export GOPATH=$HOME/go' >> $GOENV_PROFILE
        echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >> $GOENV_PROFILE
        source $GOENV_PROFILE
    fi
}

# verify go version
validate_go_version(){
    IFS=" " read -ra go_version <<< "$(go version)"
    if [[ "${MINIMUM_GO_VERSION}" != $(echo -e "${MINIMUM_GO_VERSION}\n${go_version[2]}" | sort -s -t. -k 1,1 -k 2,2n -k 3,3n | head -n1) && "${go_version[2]}" != "devel" ]]; then
        log_error "Detected go version: ${go_version[*]}, Sodafoundation requires ${MINIMUM_GO_VERSION} or greater."
        log_error "Please remove golang old version ${go_version[2]}, bootstrap will install ${MINIMUM_GO_VERSION} automatically"
        exit 2
    fi
}


GOPATH=${GOPATH:-$HOME/go}
SODA_ROOT=${GOPATH}/src/github.com/sodafoundation
SODA_API_DIR=${GOPATH}/src/github.com/sodafoundation/api
SODA_CONTROLLER_DIR=${GOPATH}/src/github.com/sodafoundation/controller
SODA_DOCK_DIR=${GOPATH}/src/github.com/sodafoundation/dock

mkdir -p ${SODA_ROOT}

cd ${SODA_ROOT}

clone_api_proj(){
    # Download API source
    if [ ! -d ${SODA_API_DIR} ]; then
        log Downloading the sodafoundation API source code...
        git clone https://github.com/sodafoundation/api.git -b master
    fi
}

# Download controller source
clone_controller_proj(){
    if [ ! -d ${SODA_CONTROLLER_DIR} ]; then
        log Downloading the sodafoundation controller source code...
        git clone https://github.com/sodafoundation/controller.git -b master
    fi
}

# Download dock source
clone_dock_proj(){
    if [ ! -d ${SODA_DOCK_DIR} ]; then
        log Downloading the sodafoundation dock source code...
        git clone https://github.com/sodafoundation/dock.git -b master
    fi
}

# make sure 'make' has been installed.
check_and_install_make(){
    if [[ -z "$(which make)" ]]; then
        log Installing make ...
        sudo apt-get install make -y
    fi
}

# build API project
build_api(){
    cd ${SODA_API_DIR}
    if [ ! -d ${SODA_API_DIR}/build ]; then
        log Building sodafoundation API ...
        make ubuntu-dev-setup
        make
    fi
}

# build CONTROLLER project
build_controller(){
    cd ${SODA_CONTROLLER_DIR}
    if [ ! -d ${SODA_CONTROLLER_DIR}/build ]; then
        log Building sodafoundation Controller ...
        make
    fi
}

# build DOCK project
build_dock(){
    cd ${SODA_DOCK_DIR}
    if [ ! -d ${SODA_DOCK_DIR}/build ]; then
        log Building sodafoundation  Dock ...
        make
    fi
}

build_project_list(){
    IFS=',' read -ra PROJS <<< "$SODA_PROJECT"
    for proj in "${PROJS[@]}"; do
        proj=`echo $proj | sed 's/^\s+|\s+$//'` 
        log Bootstrapping ${proj} ....
        "clone_${proj}_proj"
        "build_${proj}"
    done
}

check_and_install_go
validate_go_version
check_and_install_make
build_project_list

log sodafoundation projects bootstrapped successfully. you can execute 'source /etc/profile' to load golang ENV.
