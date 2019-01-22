#!/usr/bin/env bash

# Copyright (c) 2018 Noel McLoughlin. All Rights Reserved.
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

##############################################
# Adapt salt-bootstrap saltstack
##############################################

[[ `id -u` != 0 ]] && echo && echo "Run script with sudo, exiting" && echo && exit 1

hostname -f >/dev/null 2>&1
if (( $? > 0 ))
then
   cat <<HEREDOC

   Note: 'hostname -f' is not working ...

   Unless you are using bind or NIS for host lookups you could change the
   FQDN (Fully Qualified Domain Name) and the DNS domain name (which is
   part of the FQDN) in the /etc/hosts. Meanwhile, I'll use short hostname.

HEREDOC
   FQDN=$(hostname)
else
   FQDN=$(hostname -f)
fi

PACKAGE_MGR=$( dirname $0 )/ea/package_ea.sh
BASE=/srv
MODELS=$( pwd )/${BASE}
REPO=https://github.com/saltstack-formulas
FORK_REPO=https://github.com/noelmcloughlin
FORK_FORMULAS="opensds docker"
FORK_FORMULAS2="golang"
FORK_BRANCH="fixes"
FORK_BRANCH2="fixes2"

usage()
{
    echo "Usage: sudo $0 -i INSTALL_TARGET [ OPTIONS ]" 1>&2
    echo "Usage: sudo $0 -r REMOVE_TARGET [ OPTIONS ]" 1>&2
    echo 1>&2
    echo "  TARGETS" 1>&2
    echo 1>&2
    echo "  salt|opensds|deepsea" 1>&2
    echo 1>&2
    echo "     salt      Apply salt formula (infra-as-code)" 1>&2
    echo 1>&2
    echo "     opensds   Apply OpenSDS salt formula states" 1>&2
    echo 1>&2
    echo " auth|hotpot|dashboard|database|dock|infra|let|sushi|gelato" 1>&2
    echo "               Apply specific OpenSDS state" 1>&2
    echo 1>&2
    echo "     prereq    Install docker-ce and nginx;remove apache" 1>&2
    echo 1>&2
    echo "  See://github.com/saltstack-formulas/opensds-formula.git" 1>&2
    echo 1>&2
    echo "  OPTIONS" 1>&2
    echo 1>&2
    echo "   [ -l debug ]    Debug output (install/remove)." 1>&2
    echo 1>&2
    echo "   [ -m <name>]    Install; needed if /etc/salt/minion unparseable" 1>&2
    echo 1>&2
    echo "   [ -x python3 ]  Install the Python3 salt packages" 1>&2
    echo 1>&2
    echo "   [ -v yyyy.m.n ] Install specific salt release; i.e. 2017.7.2" 1>&2
    echo 1>&2
    exit ${1}
}


#**** SALTSTACK INTEGRATION

### Install Salt agent software on host (using wget, instead of 'salt-ssh')
salt-bootstrap()
{
    ${PACKAGE_MGR} -i git wget patch 2>/dev/null
    wget -O install_salt.sh https://bootstrap.saltstack.com || exit 10
    (sh install_salt.sh ${1} && rm -f install_salt.sh) || exit 10
    return 0
} 

### Pull down formula
clone_formula()
{
    f="${1}"
    rm -fr ${BASE}/formulas/${f}-formula 2>/dev/null
    git clone ${REPO}/${f}-formula.git ${BASE}/formulas/${f}-formula >/dev/null 2>&1
    (( $? > 0 )) && exit 11
    ln -s ${BASE}/formulas/${f}-formula/${f} ${BASE}/salt/${f} 2>/dev/null
    [[ ! -z "${2}" ]] && cd $BASE/formulas/${f}-formula && git checkout ${2} && cd $OLDPWD
}

### Get 'salt-master' hostname - either from /etc/salt/minion or user - else error!
get-salt-master-hostname()
{
    if [[ -f "/etc/salt/minion" ]]
    then
        MASTER=$( grep '^\s*master\s*:\s*' /etc/salt/minion | awk '{print $2}')
        [[ -z "${MASTER_HOST}" ]] && MASTER_HOST=${MASTER}
        [[ -z "${MASTER_HOST}" ]] && usage 2
    else
        MASTER_HOST=$( hostname )
    fi
}

### Enable Salt Minion agent on this host
salt-minion-service()
{
    get-salt-master-hostname
    sed -i "s@^\s*#*\s*master\s*:\s*salt\s*\$@master: ${MASTER_HOST}@g" /etc/salt/minion
    systemctl restart salt-minion
    systemctl enable salt-minion
    return $?
}

### Enable Salt Master role; accept pending registrations
salt-master-service()
{
    mkdir -p ${BASE}/salt ${BASE}/formulas ${BASE}/pillar 2>/dev/null
    systemctl enable salt-master
    systemctl restart salt-master
    salt-key -A --yes >/dev/null 2>&1
    return $?
}

#**** OPENSDS-INSTALLER

### Prepare salt deployment model for salt middleware and formulas
apply-salt-state-model()
{
    if [[ ! -d "${BASE}/salt" ]]
    then
       echo "error"
       exit 32
    fi
    echo "prepare salt ..."
    cp ${MODELS}/salt/${1}/${2}.sls ${BASE}/salt/top.sls 2>/dev/null
    cp ${BASE}/pillar/site.j2 ${BASE}/pillar/site.bak 2>/dev/null
    cp ${MODELS}/pillar/* ${BASE}/pillar/
    ln -s ${BASE}/pillar/opensds.sls ${BASE}/pillar/${2}.sls 2>/dev/null
    [[ "${2}" == 'salt' ]] && clone_formula salt

    echo "run salt ..."
    salt-call state.show_top --local
    echo " ... please be patient ..."
    salt-call state.highstate --local ${DEBUGG_ON}
}

### Prepare things for DeepSea README workflow
deepsea()
{
    salt-call --local grains.append deepsea default ${MASTER_HOST}
    cp ${MODELS}/salt/deepsea_post.sls ${BASE}/salt/top.sls
    return 0
}

### Prepare things for OpenSDS README workflow
opensds()
{
    salt-call --local grains.append opensds default ${MASTER_HOST}
    if [[ -d /etc/opensds ]]
    then
       echo "Copy opensds-installer/conf/policy.json to /etc/opensds/"
       cp $(dirname $0)/../conf/policy.json /etc/opensds/
    else
       echo "Failed to copy policy.json because opensds is not installed"
    fi
    return 0
}

### use #FORKFIXES branch on args
use_branch_instead()
{
  for f in $(echo -n ${1})
  do
    echo "using [${f}] ${2} branch"
    [[ -d "${BASE}/formulas/${f}-formula" ]] && rm -fr ${BASE}/formulas/${f}* 2>/dev/null
    git clone ${FORK_REPO}/${f}-formula.git ${BASE}/formulas/${f}-formula >/dev/null 2>&1
    if (( $? == 0 ))
    then
        cd ${BASE}/formulas/${f}-formula/
        git checkout ${2} >/dev/null 2>&1
        (( $? > 0 )) && echo "Failed to checkout ${f} ${2} branch" && return 1
    fi
  done
  cd ${MODELS}
  echo "done"
}


#*** MAIN

while getopts ":i:m:l:x:r:v:" option; do
    case "${option}" in
    m)  MASTER_HOST=${OPTARG} ;;
    i)  INSTALL_TARGET=${OPTARG}
        REMOVE_TARGET=""
        ;;
    r)  REMOVE_TARGET=${OPTARG}
        INSTALL_TARGET=""
        ;;
    l)  DEBUGG_ON="-ldebug" ;;
    x)  SALT_OPTS="-x python3" ;;
    v)  SALT_VERSION="git v${OPTARG}" ;;
    esac
done
shift $((OPTIND-1))

#trying workaround for https://github.com/saltstack/salt/issues/44062 noise
${PACKAGE_MGR} -r python2-botocore >/dev/null 2>&1

if [[ -z "${REMOVE_TARGET}" ]]
then
    case "${INSTALL_TARGET}" in
    salt)   losetup -D 2>/dev/null
            get-salt-master-hostname
            if [[ -z "${SALT_VERSION}" ]]
            then
                salt-bootstrap "${SALT_OPTS}"
                ${PACKAGE_MGR} -i salt-api
            else
                salt-bootstrap "${SALT_OPTS} -M ${SALT_VERSION}"
            fi
            salt-master-service
            salt-minion-service
            apply-salt-state-model install salt
            salt-key -A --yes >/dev/null 2>&1
            salt-key -L
            [[ ! -z "${FORK_FORMULAS}" ]] && use_branch_instead "${FORK_FORMULAS}" ${FORK_BRANCH}
            [[ ! -z "${FORK_FORMULAS2}" ]] && use_branch_instead "${FORK_FORMULAS2}" ${FORK_BRANCH2}
            apply-salt-state-model install "prereq"
            ;;

    opensds)
            losetup -D 2>/dev/null
            get-salt-master-hostname
            salt-key -A --yes >/dev/null 2>&1
            apply-salt-state-model install opensds
            (( $? == 0 )) && opensds
            ;;

    gelato|auth|hotpot|dashboard|database|dock|infra|let|sushi|deepsea|prereq)
            get-salt-master-hostname
            salt-key -A --yes >/dev/null 2>&1
            apply-salt-state-model install ${INSTALL_TARGET}
            (( $? == 0 )) && [[ "${INSTALL_TARGET}" == "deepsea" ]] && deepsea
            ;;

    *)      usage 1;;
    esac
elif [[ -z "${INSTALL_TARGET}" ]]
then
    case "${REMOVE_TARGET}" in
    opensds|gelato|auth|hotpot|backend|dashboard|database|dock|infra|sushi)
            get-salt-master-hostname
            salt-key -A --yes >/dev/null 2>&1
            apply-salt-state-model remove ${REMOVE_TARGET}
            ;;
    *)      usage 1 ;;
    esac

else
    usage 1
fi
exit ${?}
