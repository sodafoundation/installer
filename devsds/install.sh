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

# default backend list
SODA_BACKEND_LIST=${SODA_BACKEND_LIST:-lvm}

soda::usage(){
    cat  << OSDS_HELP_INFO_DOC
Usage:
    $(basename $0) [-h|--help]
Flags:
    -h, --help     Print this information.
To self-define install configuration, you can edit local.conf, here is config item blow:
    SODA_AUTH_STRATEGY: Authentication strategy, value can be keystone, noauth.
    SODA_BACKEND_LIST: Storage backend list, separated by a comma, support lvm right now.
    HOST_IP: It is used to service ip binding, including osdslet, osdsdock, etcd, keystone etc.
    SODA_PROJECT: Specify the project you need to build and install. It can be either either 'all'
                  or a combination of one or more from api, controller and dock.
                  example: SODA_PROJECT=all OR SODA_PROJECT=api OR SODA_PROJECT=api, controller, dock
OSDS_HELP_INFO_DOC
}

# Parse parameter first
case "$# $1" in
    "0 ")
    echo "Starting install..."
    ;;
    "1 -h"|"2 --help")
    soda::usage
    exit 0
    ;;
     *)
    soda::usage
    exit 1
    ;;
esac


soda::backendlist_check(){
    local backendlist=$1
    for backend in $(echo $backendlist | tr "," " ");do
        case $backend in
        lvm|ceph|nfs)
        ;;
        *)
        echo "Error: backends must be one of lvm,ceph" >&2
        exit -1
        ;;
        esac
    done
    echo "Backedn ${backendlist}"
}

# Print the commands being run so that we can see the command that triggers
# an error.  It is also useful for following along as the install occurs.
set -o xtrace
set -o errexit

# Keep track of the script directory
TOP_DIR=$(cd $(dirname "$0") && pwd)
echo "TOP DIR ${TOP_DIR}"

# SODAfoundation source code root directory
SODA_DIR=$(cd $TOP_DIR/ && pwd)

# SODA configuration directory
SODA_CONFIG_DIR=${SODA_CONFIG_DIR:-/etc/soda}
SODA_DRIVER_CONFIG_DIR=${SODA_CONFIG_DIR}/driver

# Export openssl config file as environment variable
export OPENSSL_CONF="${TOP_DIR}"/lib/openssl.cnf

mkdir -p $SODA_DRIVER_CONFIG_DIR

# Temporary directory for testing
OPT_DIR=/opt/sodafoundation
OPT_BIN=$OPT_DIR/bin
mkdir -p $OPT_BIN
export PATH=$OPT_BIN:$PATH

# Echo text to the log file, summary log file and stdout
# soda::echo_summary "something to say"
function soda::echo_summary {
    echo -e $@ >&6
}

# Echo text only to stdout, no log files
# soda::echo_nolog "something not for the logs"
function soda::echo_nolog {
    echo $@ >&3
}

# Log file
LOGFILE=/var/log/sodafoundation/devsds.log
TIMESTAMP_FORMAT=${TIMESTAMP_FORMAT:-"%F-%H%M%S"}
LOGDAYS=${LOGDAYS:-7}
CURRENT_LOG_TIME=$(date "+$TIMESTAMP_FORMAT")

# Clean up old log files.  Append '.*' to the user-specified
# ``LOGFILE`` to match the date in the search template.
LOGFILE_DIR="${LOGFILE%/*}"           # dirname
LOGFILE_NAME="${LOGFILE##*/}"         # basename
mkdir -p $LOGFILE_DIR
find $LOGFILE_DIR -maxdepth 1 -name $LOGFILE_NAME.\* -mtime +$LOGDAYS -exec rm {} \;
LOGFILE=$LOGFILE.${CURRENT_LOG_TIME}
SUMFILE=$LOGFILE.summary.${CURRENT_LOG_TIME}

# Before set log output, make sure python has already been installed.
if [[ -z "$(which python)" ]]; then
    python_path=${python_path:-}
    test -n "$(which python2)" && python_path=$(which python2)
    test -n "$(which python3)" && python_path=$(which python3)
    if [[ -z $python_path ]]; then
        log_error "Can not find python, please install it."
        exit 2
    fi
    ln -s $python_path /usr/bin/python
fi

# Set fd 3 to a copy of stdout. So we can set fd 1 without losing
# stdout later.
exec 3>&1
# Set fd 1 and 2 to write the log file
exec 1> >( $TOP_DIR/tools/outfilter.py -v -o "${LOGFILE}" ) 2>&1
# Set fd 6 to summary log file
exec 6> >( $TOP_DIR/tools/outfilter.py -o "${SUMFILE}" )

soda::echo_summary "install.sh log $LOGFILE"

# Specified logfile name always links to the most recent log
ln -sf $LOGFILE $LOGFILE_DIR/$LOGFILE_NAME
ln -sf $SUMFILE $LOGFILE_DIR/$LOGFILE_NAME.summary

source $TOP_DIR/lib/util.sh
source $TOP_DIR/sdsrc

soda::backendlist_check $SODA_BACKEND_LIST

# clean up soda.conf
:> $SODA_CONFIG_DIR/soda.conf

# Install service which is enabled.
soda::util::service_operation install
:
# Fin
# ===

set +o xtrace

if [[ -n "$LOGFILE" ]]; then
    exec 1>&3
    # Force all output to stdout and logs now
    exec 1> >( tee -a "${LOGFILE}" ) 2>&1
else
    # Force all output to stdout now
    exec 1>&3
fi

echo
echo "Execute commands below to set up ENVs which are needed by SODA CLI:"
echo "------------------------------------------------------------------"
echo "export soda_AUTH_STRATEGY=$SODA_AUTH_STRATEGY"
echo "export soda_ENDPOINT=http://localhost:50040"
if soda::util::is_service_enabled keystone; then
    if [ "true" == $USE_CONTAINER_KEYSTONE ]
        then
            echo "export OS_AUTH_URL=http://$KEYSTONE_IP/identity"
            echo "export OS_USERNAME=admin"
            echo "export OS_PASSWORD=soda@123"
            echo "export OS_TENANT_NAME=admin"
            echo "export OS_PROJECT_NAME=admin"
            echo "export OS_USER_DOMAIN_ID=default"
    else
        echo "source $DEV_STACK_DIR/openrc admin admin"
    fi
fi
echo "------------------------------------------------------------------"
echo "Enjoy it !!"
echo

# Restore/close logging file descriptors
exec 1>&3
exec 2>&3
exec 3>&-
exec 6>&-

echo
