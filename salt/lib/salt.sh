# Copyright 2019 Saltstack Formulas Community.
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

#######################
## DEFAULT VARS
#######################
if [ -f default.vars ]
then
    source default.vars
else
    source $(dirname $0)/lib/default.vars 2>/dev/null
fi

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

PROJECTDIR=${PROJECTDIR:-salt-desktop}
PROJECTNAME=${PROJECTNAME:-SaltDesktop}
USER=username
WORKDIR=$(pwd)
LOGDIR=/tmp/${PROJECTDIR}-installer
LOG=""
REPO=https://github.com/saltstack-formulas
FORK_REPO=https://github.com/myforkplace
FORK_FORMULAS=""
FORK_BRANCH="fixes"

if [ -f package-manager ]
then
    PACKAGE_MGR=package-manager.sh
else
    PACKAGE_MGR=$(dirname $0)/lib/package-manager.sh
fi

SALT_OPTS="-x python3"
if [ -f "/usr/bin/zypper" ] || [ -f "/usr/sbin/pkg" ]; then
    # No major version pegged packages support for suse/freebsd
    SALT_VERSION=""
else
    SALT_VERSION='stable 2019.2.0'
fi

### Install Salt agent software on host (using wget, instead of 'salt-ssh')
salt-bootstrap()
{
    case "$OSTYPE" in
    darwin*) OSHOME=/Users
             USER=$( stat -f "%Su" /dev/console )

             echo "Setup Darwin known good baseline ..."
             ### https://github.com/Homebrew/legacy-homebrew/issues/19670
             sudo chown -R ${USER}:admin /usr/local/*
             sudo chmod -R 0755 /usr/local/* /Library/Python/2.7/site-packages/pip* /Users/${USER}/Library/Caches/pip 2>/dev/null

             ### https://stackoverflow.com/questions/34386527/symbol-not-found-pycodecinfo-getincrementaldecoder
             su - ${USER} -c 'hash -r python'

             ### Secure install pip https://pip.pypa.io/en/stable/installing/
             su - ${USER} -c 'curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py'
             sudo python get-pip.py

             which brew | su - ${USER} -c '/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
             su - ${USER} -c '/usr/local/bin/pip install --upgrade wrapper barcodenumber npyscreen'
             [[ ! -x /usr/local/bin/brew ]] && echo "Install homebrew (https://docs.brew.sh/Installation.html)" && exit 1

             echo "Install salt ..."
             /usr/local/bin/salt --version >/dev/null 2>&1
             if (( $? > 0 )); then
                 su ${USER} -c 'brew install saltstack'
             else
                 su ${USER} -c 'brew upgrade saltstack'
             fi
             su ${USER} -c 'brew unlink saltstack && brew link saltstack'
             su ${USER} -c 'brew tap homebrew/services'
             mkdir /etc/salt 2>/dev/null
             echo $( hostname ) >/etc/salt/minion_id
             cp /usr/local/etc/saltstack/minion /etc/salt/minion
             sed -i'' 's/#file_client: remote/file_client: local/' /etc/salt/minion

             ##Workaround https://github.com/Homebrew/brew/issues/4099
             echo '--no-alpn' >> ~/.curlrc
             export HOMEBREW_CURLRC=1
             ;;

     linux*) OSHOME=/home
             ${WORKDIR}/${PACKAGE_MGR} update 2>/dev/null
             echo "Setup Linux baseline and install saltstack masterless minion ..."
             if [ -f "/usr/bin/dnf" ]; then
                 ADD="--best --allowerasing git wget redhat-rpm-config"
             elif [ -f "/usr/bin/yum" ]; then
                 ADD="epel-release git wget redhat-rpm-config"
             elif [ -f "/usr/bin/zypper" ]; then
                 ADD="git wget"
             elif [ -f "/usr/bin/apt-get" ]; then
                 PACKAGES="git ssh wget curl software-properties-common"
             elif [ -f "/usr/bin/pacman" ]; then
                 PACKAGES="git wget psutils"
             fi
             rm -f install_salt.sh 2>/dev/null
             ${WORKDIR}/${PACKAGE_MGR} -i ${PACKAGES} 2>/dev/null
             if (( $? > 0 ))
             then
                echo "Failed to install packages"
                exit 1
             fi
             wget -O install_salt.sh https://bootstrap.saltstack.com || exit 1

             # hack for https://github.com/saltstack/salt-bootstrap/pull/1356
             if [ -f salt-bootstrap.sh ]
             then
                 sh ./salt-bootstrap.sh ${1}
             else
                 sh ./lib/salt-bootstrap.sh ${1}
             fi
             #wget -O install_salt.sh https://bootstrap.saltstack.com || exit 10
             #(sh install_salt.sh ${1} && rm -f install_salt.sh) || exit 10
             ;;
    esac
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
    if [[ "`uname`" == 'FreeBSD' ]] || [[ "`uname`" == 'Darwin' ]]; then
        sed -i'' "s@^\s*#*\s*master\s*: salt\s*\$@master: ${MASTER_HOST}@" ${BASE_ETC}/salt/minion
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

setup_logger()
{
    #### SETUP LOG
    cd ${CWD}
    LOGDIR=${LOGDIR}/${1}-${2}
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
    cp ${BASE}/profiles/${1}/${2}.sls ${BASE}/${DIR}/${STATES}/top.sls 2>/dev/null
    cp ${BASE}/pillar/site.j2 ${BASE}/${DIR}/pillar/site.bak 2>/dev/null
    cp ${BASE}/pillar/* ${BASE}/${DIR}/pillar/
    ln -s ${BASE}/pillar/${PROJECTDIR}.sls ${BASE}/${DIR}/pillar/${2}.sls 2>/dev/null
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
  cd ${BASE}
}

configure_salt()
{
    losetup -D 2>/dev/null
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
    echo
    echo "////////////////////////////////////////////////////////////////////////"
    echo "///////////                                              ///////////////"
    echo "///////////              Congratulations                 ///////////////"
    echo "///////////     Salt for ''${PROJECTNAME}'' is installed        ///////////////"
    echo "///////////                                              ///////////////"
    echo "////////////////////////////////////////////////////////////////////////"
    echo
    ${WORKDIR}/${PACKAGE_MGR} -q kernel-[123456] 2>/dev/null
    echo
    echo "Reboot this host if linux kernel-${KERNEL_RELEASE} package was upgraded - if unsure reboot!"
    echo
}

#*** GETOPTS
while getopts ":i:l:t:r:v:" option; do
    case "${option}" in
    m)  MASTER_HOST=${OPTARG} ;;
    i)  INSTALL_TARGET=${OPTARG}
        REMOVE_TARGET=""
        ;;
    r)  REMOVE_TARGET=${OPTARG}
        INSTALL_TARGET=""
        ;;
    l)  DEBUGG_ON="-ldebug" && set -xv ;;
    t)  DEBUGG_ON="-tdebug" ;;
    v)  SALT_VERSION="git v${OPTARG}" ;;
    esac
done
shift $((OPTIND-1))
KERNEL_RELEASE=$( uname -r | awk -F. '{print $1"."$2"."$3"."$4"."$5}' )
