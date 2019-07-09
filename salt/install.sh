#!/usr/bin/env bash

# Copyright 2018 The OpenSDS Authors.
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
trap exit SIGINT SIGTERM

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
WORKDIR=$(pwd)
LOGDIR=/tmp/opensds-installer-salt
LOG=""
BASE=/srv
BASE_ETC=/etc
DIR=
STATES=salt
if [[ `uname` == 'FreeBSD' ]]
then
    BASE=/usr/local/etc
    BASE_ETC=/usr/local/etc
    DIR=salt
    STATES=states
fi
MODELS=$( pwd )/srv
REPO=https://github.com/saltstack-formulas
FORK_REPO=https://example.com/your_forked_repo
FORK_FORMULAS=""
FORK_BRANCH="fixes"

## salt bootstrap
SALT_OPTS="-x python3"
if [ -f "/usr/bin/zypper" ] || [ -f "/usr/sbin/pkg" ]; then
    # No major version pegged packages support for suse/freebsd
    SALT_VERSION=""
else
    SALT_VERSION='stable 2019.2.0'
fi

usage()
{
    echo "Usage: sudo $0 -i INSTALL_TARGET [ OPTIONS ]" 1>&2
    echo "Usage: sudo $0 -r REMOVE_TARGET [ OPTIONS ]" 1>&2
    echo 1>&2
    echo "  TARGETS" 1>&2
    echo 1>&2
    echo "     salt      Apply salt formula (infra-as-code)" 1>&2
    echo 1>&2
    echo "     opensds   Apply all OpenSDS states" 1>&2
    echo 1>&2
    echo " infra|keystone|config|database|auth|hotpot|dashboard|backend|dock|sushi|gelato|freespace|telemetry" 1>&2
    echo "               Apply specific OpenSDS state" 1>&2
    echo 1>&2
    echo "  See://github.com/saltstack-formulas/opensds-formula.git" 1>&2
    echo 1>&2
    echo "  OPTIONS" 1>&2
    echo 1>&2
    echo "   [ -l debug ]    Debug output in logs." 1>&2
    echo 1>&2
    echo "   [ -t debug ]    Debug output and valgrind in logs." 1>&2
    echo 1>&2
    echo "   [ -v yyyy.m.n ] Install specific salt release; i.e. 2017.7.2" 1>&2
    echo 1>&2
    exit ${1}
}


#**** SALTSTACK INTEGRATION

### Install Salt agent software on host (using wget, instead of 'salt-ssh')
salt-bootstrap()
{
    ${WORKDIR}/${PACKAGE_MGR} update 2>/dev/null
    ${WORKDIR}/${PACKAGE_MGR} -i wget 2>/dev/null
    if (( $? > 0 ))
    then
       echo "Failed to install wget"
       exit 1
    fi
    # hack for https://github.com/saltstack/salt-bootstrap/pull/1356
    sh salt-bootstrap.sh ${1}
    #wget -O install_salt.sh https://bootstrap.saltstack.com || exit 10
    #(sh install_salt.sh ${1} && rm -f install_salt.sh) || exit 10
    return 0
}

### Pull down formula
clone_formula()
{
    f="${1}"
    rm -fr ${BASE}/${DIR}/formulas/${f}-formula 2>/dev/null
    git clone ${REPO}/${f}-formula.git ${BASE}/${DIR}/formulas/${f}-formula >/dev/null 2>&1
    (( $? > 0 )) && exit 11
    ln -s ${BASE}/${DIR}/formulas/${f}-formula/${f} ${BASE}/${DIR}/${STATES}/${f} 2>/dev/null
    [[ ! -z "${2}" ]] && cd $BASE/${DIR}/formulas/${f}-formula && git checkout ${2} && cd $OLDPWD
}

### Get 'salt-master' hostname - either from salt minion or user or 'hostname'
get-salt-master-hostname()
{
    if [[ -f "${BASE_ETC}/salt/minion" ]]
    then
        MASTER=$( grep '^\s*master\s*:\s*' ${BASE_ETC}/salt/minion | awk '{print $2}')
        [[ -z "${MASTER_HOST}" ]] && MASTER_HOST=${MASTER}
        [[ -z "${MASTER_HOST}" ]] && MASTER_HOST=$( hostname )
    else
        MASTER_HOST=$( hostname )
    fi
}

### Enable and/or start a service
enable-start-service()
{
    if [[ -x "/usr/sbin/systemctl" || -x "/usr/bin/systemctl" ]]
    then
        systemctl restart ${1}
        systemctl enable ${1}
    elif [[ -x "/usr/sbin/service" ]]; then
        service ${1} restart
    fi
    return $?
}

### Enable Salt Minion agent on this host
salt-minion-service()
{
    get-salt-master-hostname
    if [[ "`uname`" == 'FreeBSD' ]]; then
        sed -i '' "s@^\s*#*\s*master\s*: salt\s*\$@master: ${MASTER_HOST}@" ${BASE_ETC}/salt/minion
    else
        sed -i "s@^\s*#*\s*master\s*: salt\s*\$@master: ${MASTER_HOST}@" ${BASE_ETC}/salt/minion
    fi
    enable-start-service salt-minion
}

### Enable Salt Master role; accept pending registrations
salt-master-service()
{
    mkdir -p ${BASE}/${DIR}/${STATES} ${BASE}/${DIR}/formulas ${BASE}/${DIR}/pillar 2>/dev/null
    enable-start-service salt-master
    salt-key -A --yes >/dev/null 2>&1
    return $?
}

### Enable Salt Api
salt-api-service()
{
    enable-start-service salt-api
    return $?
}

#**** OPENSDS-INSTALLER
setup_logger()
{
    #### SETUP LOG
    cd ${CWD}
    LOGDIR=/tmp/opensds-installer-salt/${1}-${2}
    mkdir -p ${LOGDIR} 2>/dev/null
    LOG=${LOGDIR}/log.$( date '+%Y%m%d%H%M' )
    salt-call --versions >>${LOG} 2>&1
    cat ${BASE}/${DIR}/pillar/site.j2 >>${LOG} 2>&1
    cat ${BASE}/${DIR}/pillar/${2}.sls >>${LOG} 2>&1
}

show_logger()
{
    #### DISPLAY LOG
    if [ -f "${LOG}" ]
    then
        tail -6 ${1} | head -4 2>/dev/null
        echo "See full log in [ ${1} ]"
        echo
    fi
}

### Prepare salt deployment model for salt middleware and formulas
apply-salt-state-model()
{
    if [[ ! -d "${BASE}/${DIR}/${STATES}" ]]
    then
       echo "error"
       exit 32
    fi
    cp ${MODELS}/salt/${1}/${2}.sls ${BASE}/${DIR}/${STATES}/top.sls 2>/dev/null
    cp ${BASE}/pillar/site.j2 ${BASE}/${DIR}/pillar/site.bak 2>/dev/null
    cp ${MODELS}/pillar/* ${BASE}/${DIR}/pillar/
    ln -s ${BASE}/pillar/opensds.sls ${BASE}/${DIR}/pillar/${2}.sls 2>/dev/null
    [[ "${2}" == 'salt' ]] && clone_formula salt

    echo "run salt: this takes a while, please be patient ..."
    setup_logger $1 $2
    echo >>${LOG} 2>&1
    salt-call pillar.items --local >> ${LOG} 2>&1
    echo >>${LOG} 2>&1
    salt-call state.show_top --local | tee -a ${LOG} 2>&1
    echo >>${LOG} 2>&1
    if [[ "${DEBUGG_ON}" == '-tdebug' ]] && [[ -x "${WORKDIR}/${PACKAGE_MGR}" ]]
    then
        ${WORKDIR}/${PACKAGE_MGR} -i valgrind kexec-tools crash >/dev/null 2>&1
        valgrind --tool=memcheck --trace-children=yes --track-fds=yes --time-stamp=yes salt-call state.highstate --local -ldebug --retcode-passthrough saltenv=base  >>${LOG} 2>&1

    else
        salt-call state.highstate --local ${DEBUGG_ON} --retcode-passthrough saltenv=base  >>${LOG} 2>&1
    fi
    show_logger ${LOG}
}

### Prepare things for DeepSea README workflow
deepsea()
{
    salt-call --local grains.append deepsea default ${MASTER_HOST}
    cp ${MODELS}/salt/deepsea_post.sls ${BASE}/${DIR}/${STATES}/top.sls
    return 0
}

### Prepare things for OpenSDS README workflow
opensds()
{
    salt-call --local grains.append opensds default ${MASTER_HOST}
    if [[ -d /etc/opensds ]]
    then
       echo "Copy opensds-installer/conf/policy.json to /etc/opensds/"
       if [[ -f "/root/opensds-installer/conf/policy.json" ]]
       then
           cp /root/opensds-installer/conf/policy.json /etc/opensds/
       else
           cp $(dirname $0)/../conf/policy.json /etc/opensds/
       fi
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
    [[ -d "${BASE}/formulas/${f}-formula" ]] && rm -fr ${BASE}/${DIR}/formulas/${f}* 2>/dev/null
    git clone ${FORK_REPO}/${f}-formula.git ${BASE}/${DIR}/formulas/${f}-formula >/dev/null 2>&1
    if (( $? == 0 ))
    then
        cd ${BASE}/${DIR}/formulas/${f}-formula/
        git checkout ${2} >/dev/null 2>&1
        (( $? > 0 )) && echo "Failed to checkout ${f} ${2} branch" && return 1
    fi
  done
  cd ${MODELS}
}


#*** MAIN

while getopts ":i:l:t:r:v:" option; do
    case "${option}" in
    m)  MASTER_HOST=${OPTARG} ;;
    i)  INSTALL_TARGET=${OPTARG}
        REMOVE_TARGET=""
        ;;
    r)  REMOVE_TARGET=${OPTARG}
        INSTALL_TARGET=""
        ;;
    l)  DEBUGG_ON="-ldebug" ;;
    t)  DEBUGG_ON="-tdebug" ;;
    v)  SALT_VERSION="git v${OPTARG}" ;;
    esac
done
shift $((OPTIND-1))
KERNEL_RELEASE=$( uname -r | awk -F. '{print $1"."$2"."$3"."$4"."$5}' )

if [[ -z "${REMOVE_TARGET}" ]]
then
    case "${INSTALL_TARGET}" in
    salt)   losetup -D 2>/dev/null
            get-salt-master-hostname
            if [[ -z "${SALT_VERSION}" ]]
            then
                salt-bootstrap "${SALT_OPTS}"
            else
                salt-bootstrap "${SALT_OPTS} -M ${SALT_VERSION}"
            fi

            ### workaround https://github.com/saltstack/salt-bootstrap/issues/1355
            if [ -f "/usr/bin/apt-get" ]; then
                ### prevent dpkg from starting daemons: https://wiki.debian.org/chroot
                cat > /usr/sbin/policy-rc.d <<EOF
#!/bin/sh
exit 101
EOF
                chmod a+x /usr/sbin/policy-rc.d
                ### Enforce python3
                rm /usr/bin/python 2>/dev/null; ln -s /usr/bin/python3 /usr/bin/python
            fi

            ### salt services
            ${WORKDIR}/${PACKAGE_MGR} -i salt-api
            salt-api-service
            salt-master-service
            salt-minion-service
            apply-salt-state-model install salt
            salt-key -A --yes >/dev/null 2>&1
            salt-key -L
            [[ ! -z "${FORK_FORMULAS}" ]] && use_branch_instead "${FORK_FORMULAS}" ${FORK_BRANCH}
            [[ ! -z "${FORK_FORMULAS2}" ]] && use_branch_instead "${FORK_FORMULAS2}" ${FORK_BRANCH2}
            echo
            ${WORKDIR}/${PACKAGE_MGR} -q kernel-[123456] 2>/dev/null
            echo
            echo "Reboot this host if linux kernel-${KERNEL_RELEASE} package was upgraded - if unsure reboot!"
            echo
            ;;

    opensds)
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
            (( $? == 0 )) && opensds
            ;;

    gelato|auth|hotpot|dashboard|database|dock|keystone|config|infra|backend|sushi|deepsea|freespace|telemetry)
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
    opensds|gelato|auth|hotpot|backend|dashboard|database|dock|keystone|config|infra|sushi|freespace|telemetry)
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
