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

soda:usage()
{
    echo "Usage: $(basename $0) [--help|--cleanup|--purge]"
cat  << OSDS_HELP_UNINSTALL_INFO_DOC
Usage:
    $(basename $0) [-h|--help]
    $(basename $0) [-c|--cleanup]
    $(basename $0) [-p|--purge]
Flags:
    -h, --help     Print this information.
    -c, --cleanup  Stop service and clean up some application data.
    -p, --purge    Remove package, config file, log file.
OSDS_HELP_UNINSTALL_INFO_DOC
}

# Parse parameter first
case "$# $*" in
    "0 "|"1 --purge"|"1 -p"|"1 --cleanup"|"1 -c")
    ;;
    "1 -h"|"1 --help")
    soda:usage
    exit 0
    ;;
     *)
    soda:usage
    exit 1
    ;;
esac

set -o xtrace

# Keep track of the script directory
TOP_DIR=$(cd $(dirname "$0") && pwd)
# Temporary dir for testing
OPT_DIR=/opt/sodafoundation
OPT_BIN=$OPT_DIR/bin

source $TOP_DIR/lib/util.sh
source $TOP_DIR/sdsrc

soda::cleanup() {
    soda::util::service_operation cleanup
}

soda::uninstall(){
    soda::cleanup
    soda::util::service_operation uninstall
}

soda::uninstall_purge(){
    soda::uninstall
    soda::util::service_operation uninstall_purge

    rm /opt/sodafoundation -rf
    rm /etc/soda -rf
    rm /var/log/sodafoundation -rf
    rm /etc/bash_completion.d/osdsctl.bash_completion -rf
    rm /opt/soda-security -rf
}

case "$# $*" in
    "1 -c"|"1 --cleanup")
    soda::cleanup
    ;;
    "0 ")
    soda::uninstall
    ;;
    "1 -p"|"1 --purge")
    soda::uninstall_purge
    ;;
     *)
    soda:usage
    exit 1
    ;;
esac
