#!/usr/bin/env bash

# Copyright 2019 The OpenSDS Authors.
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

PROJECTDIR=opensds
PROJECTNAME="OpenSDS"
source $( dirname $0 )/lib/salt.sh

# Custom git info
# REPO=
# FORK_REPO=
# FORK_FORMULAS=
# FORK_BRANCH=

# Business Logic
workflow()
{
    if [[ -z "${REMOVE_TARGET}" ]]
    then
        case "${INSTALL_TARGET}" in
        salt)          configure_salt
                       ;;

        opensds)       echo "install ${PROJECTDIR}"
                       losetup -D 2>/dev/null
                       get-salt-master-hostname
                       salt-key -A --yes >/dev/null 2>&1
                       apply-salt-state-model install infra
                       apply-salt-state-model install telemetry
                       apply-salt-state-model install keystone
                       show_logger /tmp/devstack/stack.sh.log
                       apply-salt-state-model install config
                       apply-salt-state-model install database
                       apply-salt-state-model install auth
                       apply-salt-state-model install hotpot
                       apply-salt-state-model install sushi
                       apply-salt-state-model install backend
                       apply-salt-state-model install dock
                       apply-salt-state-model install dashboard
                       apply-salt-state-model install gelato
                       apply-salt-state-model install freespace

                       ## opensds post-install steps
                       if [[ -d /etc/${PROJECTDIR} ]]
                       then
                          echo "Copy ${PROJECTDIR}-installer/conf/policy.json to /etc/${PROJECTDIR}/"
                          if [[ -f "/root/${PROJECTDIR}-installer/conf/policy.json" ]]
                          then
                              cp /root/${PROJECTDIR}-installer/conf/policy.json /etc/${PROJECTDIR}/
                          else
                              cp $(dirname $0)/../conf/policy.json /etc/${PROJECTDIR}/
                          fi
                       else
                          echo "Failed to copy policy.json because ${PROJECTDIR} is not installed"
                       fi
                ;;
   gelato|auth|hotpot|dashboard|database|dock|keystone|config|infra|backend|sushi|deepsea|freespace|telemetry)
                get-salt-master-hostname
                salt-key -A --yes >/dev/null 2>&1
                apply-salt-state-model install ${INSTALL_TARGET}
                salt-call --local grains.append ${PROJECTDIR} default ${MASTER_HOST}
                if (( $? == 0 )) && [[ "${INSTALL_TARGET}" == "deepsea" ]]
                then
                    salt-call --local grains.append deepsea default ${MASTER_HOST}
                    cp ${MODELS}/salt/deepsea_post.sls ${BASE}/${DIR}/${STATES}/top.sls
                fi
                apply-salt-state-model install freespace
                ;;
        *)      usage 1
                ;;
        esac
    elif [[ -z "${INSTALL_TARGET}" ]]
    then
        case "${REMOVE_TARGET}" in
        opensds|gelato|auth|hotpot|backend|dashboard|database|dock|keystone|config|infra|sushi|freespace|telemetry)
                get-salt-master-hostname
                salt-key -A --yes >/dev/null 2>&1
                apply-salt-state-model remove ${REMOVE_TARGET}
                ;;
        *)      usage 1
                ;;
        esac
    else
        usage 1
    fi
}

usage()
{   
    echo "Usage: sudo $0 -i INSTALL_TARGET [ OPTIONS ]" 1>&2
    echo "Usage: sudo $0 -r REMOVE_TARGET [ OPTIONS ]" 1>&2
    echo 1>&2
    echo "  TARGETS" 1>&2
    echo 1>&2  
    echo "     salt      Apply salt formula (infra-as-code)" 1>&2
    echo 1>&2  
    echo "     ${PROJECTDIR}   Apply all ${PROJECTNAME} states" 1>&2
    echo 1>&2
    echo " infra|keystone|config|database|auth|hotpot|dashboard|backend|dock|sushi|gelato|freespace|telemetry" 1>&2
    echo "               Apply specific ${PROJECTNAME} state" 1>&2
    echo 1>&2
    echo "  See://github.com/saltstack-formulas/${PROJECTDIR}-formula.git" 1>&2
    echo 1>&2
    echo "  OPTIONS" 1>&2
    echo 1>&2
    echo "   [ -l debug ]    Debug output in logs." 1>&2
    echo 1>&2
    echo "   [ -t debug ]    Debug output and valgrind in logs." 1>&2
    echo 1>&2
    echo "   [ -v yyyy.m.n ] Install specific salt release; i.e. 2019.2.0" 1>&2
    echo 1>&2
    exit ${1}
}

## MAIN
workflow
