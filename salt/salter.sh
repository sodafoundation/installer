#!/usr/bin/env bash
#-------------------------------------------------------------------------
# Copyright 2019 Saltstack Formulas
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
#
# Original work from: https://github.com/saltstack-formulas/salter
# MODIFIED WORK SECTION has additional copyright under this "License".
#--------------------------------------------------------------------------
#
# This script allows common bootstrapping for any project using salt
#
#-----------------------------------------------------------------------
trap exit SIGINT SIGTERM
[ `id -u` != 0 ] && echo && echo "Run script with sudo, exiting" && echo && exit 1

RC=0
BASE=/srv
BASE_ETC=/etc
STATEDIR=''
if [ `uname` == 'FreeBSD' ]; then
    BASE=/usr/local/etc
    BASE_ETC=/usr/local/etc
    STATEDIR=states
fi
PILLARFS=${BASE:-/srv}/pillar
SALTFS=${BASE:-/srv}/salt/${STATEDIR}
SKIP_UNNECESSARY_CLONE=''
HOMEBREW=/usr/local/bin/brew

# bash version must be modern
declare -A your solution fork 2>/dev/null || RC=$?
if (( RC > 0 )) && [ "$( uname )" = "Darwin" ]; then
    echo "[warning] your bash version is too old ..."
    # macos needs homebrew (unattended https://github.com/Homebrew/legacy-homebrew/issues/46779#issuecomment-162819088)
    export PY_VER=3
    export USER=$( stat -f "%Su" /dev/console )
    export HOMEBREW=/usr/local/bin/brew
    ${HOMEBREW} >/dev/null 2>&1
    (( $? == 127 )) && su - ${USER} -c 'echo | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
    # macos needs modern bash
    (( RC > 0 )) && (su - ${USER} -c "${HOMEBREW} install bash" || exit 12) && RC=0
fi
if (( RC > 0 )); then
    # linux needs modern bash
    echo "[error] your bash version is too old ..."
    exit ${RC}
fi

#-----------------------------------------
#   Adaption layer for OS package handling
#-----------------------------------------
pkg-query() {
    PACKAGE=${@}
    if [ -f "/usr/bin/zypper" ]; then
         /usr/bin/zypper se -si ${PACKAGE}
    elif [ -f "/usr/bin/yum" ]; then
         /usr/bin/rpm -qa | grep ${PACKAGE}
    elif [[ -f "/usr/bin/apt-get" ]]; then
         /usr/bin/dpkg-query --list | grep ${PACKAGE}
    elif [ -f "/usr/bin/pacman" ]; then
         /usr/bin/pacman -Qi ${PACKAGE}
    fi
}

pkg-install() {
    PACKAGES=${@}
    case ${OSTYPE} in
    darwin*) for p in ${PACKAGES}; do
                 su - ${USER} -c "${HOMEBREW} install ${p}"
                 su - ${USER} -c "${HOMEBREW} unlink ${p} 2>/dev/null"
                 su - ${USER} -c "${HOMEBREW} link ${p} 2>/dev/null"
             done
             awk >/dev/null 2>&1
             if (( $? == 134 )); then
                 ## https://github.com/atomantic/dotfiles/issues/23#issuecomment-298784915 ###
                 su - ${USER} -c "${HOMEBREW} uninstall gawk"
                 su - ${USER} -c "${HOMEBREW} uninstall readline"
                 su - ${USER} -c "${HOMEBREW} install readline"
                 su - ${USER} -c "${HOMEBREW} install gawk"
             fi
             ;;

    linux*)  if [ -f "/usr/bin/zypper" ]; then
                 /usr/bin/zypper update -y || exit 1
                 /usr/bin/zypper --non-interactive install ${PACKAGES} || exit 1
             elif [ -f "/usr/bin/emerge" ]; then
                 /usr/bin/emerge --oneshot ${PACKAGES} || exit 1
             elif [ -f "/usr/bin/pacman" ]; then
                 [ -x '/usr/bin/pacman-mirrors' ] && /usr/bin/pacman-mirrors -g
                 /usr/bin/pacman -Syyu --noconfirm
                 /usr/bin/pacman -S --noconfirm ${PACKAGES} || exit 1
             elif [ -f "/usr/bin/dnf" ]; then
                 /usr/bin/dnf install -y --best --allowerasing ${PACKAGES} || exit 1
             elif [ -f "/usr/bin/yum" ]; then
                 /usr/bin/yum update -y || exit 1 
                 /usr/bin/yum install -y ${PACKAGES} || exit 1 
             elif [[ -f "/usr/bin/apt-get" ]]; then
                 /usr/bin/apt-get update --fix-missing -y || exit 1
                 /usr/bin/apt-add-repository universe
                 /usr/bin/apt autoremove -y
                 /usr/bin/apt-get update -y
                 /usr/bin/apt-get install -y ${PACKAGES} || exit 1
             fi
    esac
}

pkg-update() {
    PACKAGES=${@}
    case ${OSTYPE} in
    darwin*) for p in ${PACKAGES}; do
                 su - ${USER} -c "${HOMEBREW} upgrade ${p}"
             done
             ;;
    linux*)  if [ -f "/usr/bin/zypper" ]; then
                 /usr/bin/zypper --non-interactive up ${PACKAGES} || exit 1
             elif [ -f "/usr/bin/emerge" ]; then
                 /usr/bin/emerge -avDuN ${PACKAGES} || exit 1
             elif [ -f "/usr/bin/pacman" ]; then
                 /usr/bin/pacman -Syu --noconfirm ${PACKAGES} || exit 1
             elif [ -f "/usr/bin/dnf" ]; then
                 /usr/bin/dnf upgrade -y --allowerasing ${PACKAGES} || exit 1
             elif [ -f "/usr/bin/yum" ]; then
                 /usr/bin/yum update -y ${PACKAGES} || exit 1 
             elif [[ -f "/usr/bin/apt-get" ]]; then
                 /usr/bin/apt-get upgrade -y ${PACKAGES} || exit 1
             fi
    esac
}

pkg-remove() {
    PACKAGES=${@}
    case ${OSTYPE} in
    darwin*) for p in ${PACKAGES}; do
                 su - ${USER} -c "${HOMEBREW} uninstall ${p} --force"
             done
             ;;
    linux*)  if [ -f "/usr/bin/zypper" ]; then
                 /usr/bin/zypper --non-interactive rm ${PACKAGES} || exit 1
             elif [ -f "/usr/bin/emerge" ]; then
                 /usr/bin/emerge -C ${PACKAGES} || exit 1
             elif [ -f "/usr/bin/pacman" ]; then
                 /usr/bin/pacman -Rs --noconfirm ${PACKAGES} || exit 1
             elif [ -f "/usr/bin/dnf" ]; then
                 /usr/bin/dnf remove -y ${PACKAGES} || exit 1
             elif [ -f "/usr/bin/yum" ]; then
                 /usr/bin/yum remove -y ${PACKAGES} || exit 1 
             elif [[ -f "/usr/bin/apt-get" ]]; then
                 /usr/bin/apt-get remove -y ${PACKAGES} || exit 1
             fi
    esac
}

#-----------------------
#---- salt -------------
#-----------------------

get-salt-master-hostname() {
   hostname -f >/dev/null 2>&1
   if (( $? == 0 )); then
       FQDN=$(hostname -f)
   else
       FQDN=$(hostname)
       cat <<HEREDOC

   Note: 'hostname -f' is not working ...
   Unless you are using bind or NIS for host lookups you could change the
   FQDN (Fully Qualified Domain Name) and the DNS domain name (which is
   part of the FQDN) in the /etc/hosts. Meanwhile, I'll use short hostname.

HEREDOC
    fi
    if [[ -f "${BASE_ETC}/salt/minion" ]]; then
        MASTER=$( grep '^\s*master\s*:\s*' ${BASE_ETC}/salt/minion | awk '{print $2}')
        [[ -z "${solution[saltmaster]}" ]] && solution[saltmaster]=${MASTER}
    fi
    [[ -z "${solution[saltmaster]}" ]] && solution[saltmaster]=$( hostname )
    salt-key -A --yes >/dev/null 2>&1
}

salt-bootstrap() {
    get-salt-master-hostname
    if [ -f "/usr/bin/zypper" ] || [ -f "/usr/sbin/pkg" ]; then
        # No major version pegged packages support for suse/freebsd
        SALT_VERSION=''
    fi
    rm -fr ${PILLARFS}/* 2>/dev/null
    export PWD=$( pwd )

    case "$OSTYPE" in
    darwin*) echo "Setup Darwin known good baseline ..."
             ### https://github.com/Homebrew/legacy-homebrew/issues/19670
             sudo chown -R ${USER}:admin /usr/local/*
             sudo chmod -R 0755 /usr/local/* /Library/Python/2.7/site-packages/pip* /Users/${USER}/Library/Caches/pip 2>/dev/null

             ### https://stackoverflow.com/questions/34386527/symbol-not-found-pycodecinfo-getincrementaldecoder
             su - ${USER} -c 'hash -r python'

             ### Secure install https://pip.pypa.io/en/stable/installing/
             su - ${USER} -c 'curl https://bootstrap.pypa.io/get-pip.py -o ${PWD}/get-pip.py'
             sudo python ${PWD}/get-pip.py 2>/dev/null

             /usr/local/bin/salt --version >/dev/null 2>&1
             if (( $? > 0 )); then
                 su - ${USER} -c "${HOMEBREW} install saltstack"
             else
                 su - ${USER} -c "${HOMEBREW} upgrade saltstack"
             fi
             su - ${USER} -c "${HOMEBREW} unlink saltstack"
             su - ${USER} -c "${HOMEBREW} link saltstack"
             su - ${USER} -c "${HOMEBREW} tap homebrew/services"
             echo $( hostname ) >/etc/salt/minion_id
             cp /usr/local/etc/saltstack/minion /etc/salt/minion 2>/dev/null
             sed -i"bak" "s/#file_client: remote/file_client: local/" /etc/salt/minion 2>/dev/null

             ##Workaround https://github.com/Homebrew/brew/issues/4099
             echo '--no-alpn' >> ~/.curlrc
             export HOMEBREW_CURLRC=1
             ;;

     linux*) pkg-update 2>/dev/null
             echo "Setup Linux baseline and install saltstack masterless minion ..."
             if [ -f "/usr/bin/dnf" ]; then
                 PACKAGES="--best --allowerasing git wget redhat-rpm-config"
             elif [ -f "/usr/bin/yum" ]; then
                 PACKAGES="epel-release git wget redhat-rpm-config"
             elif [ -f "/usr/bin/zypper" ]; then
                 PACKAGES="git wget"
             elif [ -f "/usr/bin/apt-get" ]; then
                 PACKAGES="git ssh wget curl software-properties-common"
             elif [ -f "/usr/bin/pacman" ]; then
                 PACKAGES="git wget psutils"
             fi
             pkg-install ${PACKAGES} 2>/dev/null
             if (( $? > 0 )); then
                echo "Failed to install packages"
                exit 1
             fi
             wget -O install_salt.sh https://bootstrap.saltstack.com || exit 10
             (sh install_salt.sh -x python3 ${SALT_VERSION} && rm -f install_salt.sh) || exit 10
             rm -f install_salt.sh 2>/dev/null
    esac
    ### stop debian interference with services (https://wiki.debian.org/chroot)
    if [ -f "/usr/bin/apt-get" ]; then
        cat > /usr/sbin/policy-rc.d <<EOF
#!/bin/sh
exit 101
EOF
        chmod a+x /usr/sbin/policy-rc.d
        ### Enforce python3
        rm /usr/bin/python 2>/dev/null; ln -s /usr/bin/python3 /usr/bin/python
    fi
    ### install salt-api (except arch/macos)
    [ ! -f "/etc/arch-release" ] && [ "$(uname)" != "Darwin" ] && pkg-install salt-api

    ### salt services
    if [[ "`uname`" == "FreeBSD" ]] || [[ "`uname`" == "Darwin" ]]; then
        sed -i"bak" "s@^\s*#*\s*master\s*: salt\s*\$@master: ${solution[saltmaster]}@" ${BASE_ETC}/salt/minion
    else
        sed -i "s@^\s*#*\s*master\s*: salt\s*\$@master: ${solution[saltmaster]}@" ${BASE_ETC}/salt/minion
    fi
    (systemctl enable salt-api && systemctl start salt-api) 2>/dev/null || service start salt-api 2>/dev/null
    (systemctl enable salt-master && systemctl start salt-master) 2>/dev/null || service start salt-master 2>/dev/null
    (systemctl enable salt-minion && systemctl start salt-minion) 2>/dev/null || service start salt-minion 2>/dev/null
    salt-key -A --yes >/dev/null 2>&1     ##accept pending registrations
    echo && KERNEL_VERSION=$( uname -r | awk -F. '{print $1"."$2"."$3"."$4"."$5}' )
    echo "kernel before: ${KERNEL_VERSION}"
    echo "kernel after: $( pkg-query linux 2>/dev/null )"
    echo "Reboot if kernel was major-upgraded; if unsure reboot!"
    echo
}

setup-log() {
    LOG=${1}
    mkdir -p ${solution[logdir]} 2>/dev/null
    salt-call --versions >>${LOG} 2>&1
    [ -f "${PILLARFS}/site.j2" ] && cat ${PILLARFS}/site.j2 >>${LOG} 2>&1
    [ -n "${DEBUGG_ON}" ] && salt-call pillar.items --local >> ${LOG} 2>&1 && echo >>${LOG} 2>&1
    salt-call state.show_top --local | tee -a ${LOG} 2>&1
    echo >>${LOG} 2>&1
    echo "run salt: this takes a while, please be patient ..."
}

gitclone() {
    [ -n "${SKIP_UNNECESSARY_CLONE}" ] && return 0

    URI=${1} && ENTITY=${2} && REPO=${3} && ALIAS=${4} && SUBDIR=${5}
    echo "cloning ${REPO} from ${ENTITY} ..."
    rm -fr ${SALTFS}/namespaces/${ENTITY}/${REPO} 2>/dev/null

    echo "${fork[solutions]}" | grep "${REPO}" >/dev/null 2>&1
    if (( $? == 0 )) && [[ -n "${fork[uri]}" ]] && [[ -n "${fork[entity]}" ]] && [[ -n "${fork[branch]}" ]]; then
        echo "... using fork: ${fork[entity]}, branch: ${fork[branch]}"
        git clone ${fork[uri]}/${fork[entity]}/${REPO} ${SALTFS}/namespaces/${ENTITY}/${REPO} >/dev/null 2>&1 || exit 11
        cd  ${SALTFS}/namespaces/${ENTITY}/${REPO} && git checkout ${fork[branch]}
    else
        git clone ${URI}/${ENTITY}/${REPO} ${SALTFS}/namespaces/${ENTITY}/${REPO} >/dev/null 2>&1 || exit 11
    fi
    echo && ln -s ${SALTFS}/namespaces/${ENTITY}/${REPO}/${SUBDIR} ${SALTFS}/${ALIAS} 2>/dev/null
}

highstate() {
    (get-salt-master-hostname && [ -d ${solution[homedir]} ]) || usage

    ## prepare states
    ACTION=${1} && STATEDIR=${2} && TARGET=${3}
    for PROFILE in ${solution[saltdir]}/${ACTION}/${TARGET} ${your[saltdir]}/${ACTION}/${TARGET}
    do  
        [ -f ${PROFILE}.sls ] && cp ${PROFILE}.sls ${SALTFS}/top.sls && break
        [ -f ${PROFILE}/init.sls ] && cp ${PROFILE}/init.sls ${SALTFS}/top.sls && break
    done
    [ ! -f ${SALTFS}/top.sls ] && echo "Failed to find ${TARGET}.sls or ${TARGET}/init.sls" && usage

    ## prepare pillars
    cp -Rp ${solution[pillars]}/* ${PILLARFS}/ 2>/dev/null
    cp -Rp ${your[pillars]}/* ${PILLARFS}/ 2>/dev/null
    if [ -n "${USERNAME}" ]; then
        ### find/replace dummy usernames in pillar data ###
        case "$OSTYPE" in
        darwin*) grep -rl 'undefined_user' ${PILLARFS} | xargs sed -i '' "s/undefined_user/${USERNAME}/g" 2>/dev/null
                 ;;
        linux*)  grep -rl 'undefined_user' ${PILLARFS} | xargs sed -i "s/undefined_user/${USERNAME}/g" 2>/dev/null
        esac
    fi

    ## prepare formulas
    for formula in $( grep '^.* - ' ${SALTFS}/top.sls |awk '{print $2}' |cut -d'.' -f1 |uniq )
     do
         ## adjust mismatched state/formula names
         case ${formula} in
         resharper|pycharm|goland|rider|datagrip|clion|rubymine|appcode|webstorm|phpstorm)
                     source="jetbrains-${formula}" ;;
         linuxvda)   source='citrix-linuxvda' ;;
         salt)       continue;;                    ##already cloned?
         *)          source=${formula} ;;
         esac
         gitclone 'https://github.com' "${solution[provider]}" ${source}-formula ${formula} ${formula}
    done

    ## run states
    LOG=${solution[logdir]}/log.$( date '+%Y%m%d%H%M' )
    setup-log ${LOG}
    salt-call state.highstate --local ${DEBUGG_ON} --retcode-passthrough saltenv=base  >>${LOG} 2>&1
    [ -f "${LOG}" ] && (tail -6 ${LOG} | head -4) 2>/dev/null && echo "See full log in [ ${LOG} ]"
    echo
    echo "/////////////////////////////////////////////////////////////////"
    echo "        $(basename ${TARGET}) for ${solution[repo]} has completed"
    echo "////////////////////////////////////////////////////////////////"
    echo
}

usage() {
    echo "Usage: sudo $0 -i TARGET [ OPTIONS ] [ -u username ]" 1>&2
    echo "Usage: sudo $0 -r TARGET [ OPTIONS ]" 1>&2
    echo 1>&2
    echo "  [-u <username>]" 1>&2
    echo "        A Loginname (current or corporate or root user)." 1>&2
    echo "        its mandatory for some Linux profiles" 1>&2
    echo "        but not required on MacOS" 1>&2 
    echo 1>&2
    echo "  TARGETS" 1>&2
    echo 1>&2
    echo "\tbootstrap\t\tRun salt-bootstrap with additions" 1>&2
    echo 1>&2
    echo "\tsalter\t\tInstall salter and salt-formula" 1>&2
    echo 1>&2
    if [ "${solution[entity]}" != "salter" ]; then
       echo "\t${solution[entity]}\tDeploy ${solution[repo]}" 1>&2
       echo 1>&2
    fi
    echo " ${solution[targets]}" 1>&2
    echo "\t\t\tApply specific ${solution[repo]} state" 1>&2
    echo 1>&2
    echo "  OPTIONS" 1>&2
    echo 1>&2
    echo "  [-l <all|debug|warning|error|quiet]" 1>&2
    echo "      Optional log-level (default warning)" 1>&2
    echo 1>&2
    echo "   [ -l debug ]    Debug output in logs." 1>&2
    echo 1>&2
    exit 1
}

(( $# == 0 )) && usage
USERNAME=''
while getopts ":i:l:r:u:" option; do
    case "${option}" in
    i)  ACTION=install && TARGET=${OPTARG:-menu} ;;
    r)  ACTION=remove && TARGET=${OPTARG} ;;
    l)  case ${OPTARG} in
        'all'|'garbage'|'trace'|'debug'|'warning'|'error') DEBUGG="-l${OPTARG}" && set -xv
           ;;
        'quiet'|'info') DEBUGG="-l${OPTARG}"
           ;;
        *) DEBUGG="-lwarning"
        esac ;;
    u)  USERNAME=${OPTARG}
        ([ "${USERNAME}" == "username" ] || [ -z "${USERNAME}" ]) && usage
    esac
done
shift $((OPTIND-1))

salter-engine() {
    ## remove option
    if [ "${ACTION}" == 'remove' ] && [ -n "${TARGET}" ]; then
        echo "${solution[targets]}" | grep "${TARGET}" >/dev/null 2>&1
        if (( $? == 0 )) || [ -f ${solution[saltdir]}/${ACTION}/${TARGET}.sls ]; then
           highstate remove ${solution[saltdir]} ${TARGET}
           return 0
        fi
    fi

    ## install option
    case "${TARGET}" in
    bootstrap)  salt-bootstrap ;;

    menu)       pip${PY_VER} install --pre wrapper barcodenumber npyscreen || exit 1
                ([ -x ${SALTFS}/contrib/menu.py ] && ${SALTFS}/contrib/menu.py ${solution[saltdir]}/install) || exit 2
                highstate install "${solution[saltdir]}" ${TARGET} ;;

    salter)     gitclone 'https://github.com' "${solution[provider]}" salt-formula salt salt
                gitclone ${solution[uri]} ${solution[entity]} ${solution[repo]} ${solution[alias]} ${solution[subdir]}
                highstate install "${solution[saltdir]}" salt
                rm /usr/local/bin/salter.sh 2>/dev/null
                ln -s ${solution[homedir]}/salter.sh /usr/local/bin/salter.sh ;;

    ${solution[alias]})
                custom-install ${solution[alias]} ;;

    *)          ## PROFILES (STATES/FORMULAS)
                echo "${solution[targets]}" | grep "${TARGET}" >/dev/null 2>&1
                if (( $? == 0 )) || [ -f ${solution[saltdir]}/install/${TARGET}.sls ]; then
                    highstate install ${solution[saltdir]} ${TARGET}
                    custom-postinstall ${TARGET}
                fi
    esac
}

#########################################################################
# SOLUTION: Copyright 2019 The OpenSDS Authors
#########################################################################

developer-definitions() {
    fork['uri']="https://github.com"
    fork['entity']="noelmcloughlin"
    fork['branch']="fixes"
    fork['solutions']="salter packages-formula golang-formula postgres-formula"
}

solution-definitions() {
    ### solution polyrepo or monorepo ###
    solution['saltmaster']=""
    solution['uri']="https://github.com"
    solution['entity']="opensds"
    solution['repo']="opensds-installer"
    solution['alias']="opensds"
    solution['subdir']="salt"
    solution['provider']="saltstack-formulas"
    solution['profiles']="opensds|gelato|auth|hotpot|backend|dashboard|database|dock|keystone|config|infra|sushi|freespace|telemetry|deepsea"

    ### derivatives
    solution['homedir']="${SALTFS}/namespaces/${solution[entity]}/${solution[repo]}/${solution[subdir]}"
    solution['saltdir']="${solution[homedir]}/file_roots"
    solution['pillars']="${solution[homedir]}/pillar_roots"
    solution['logdir']="/tmp/${solution[entity]}-${solution[repo]}"

    your['saltdir']="${SALTFS}/namespaces/your/file_roots"
    your['pillars']="${SALTFS}/namespaces/your/pillar_roots"
    mkdir -p ${solution[saltdir]} ${solution[pillars]} ${your[saltdir]} ${your[pillars]} ${solution[logdir]} ${PILLARFS} ${BASE_ETC}/salt 2>/dev/null
}

custom-install() {
    ### required - salter-engine is insufficient ###
    gitclone ${solution[uri]} ${solution[entity]} ${solution[repo]} ${solution[alias]} ${solution[subdir]}
    SKIP_UNNECESSARY_CLONE='true'
    losetup -D 2>/dev/null
    highstate install ${solution[saltdir]} infra
    highstate install ${solution[saltdir]} telemetry
    highstate install ${solution[saltdir]} keystone
    #show-logger /tmp/devstack/stack.sh.log
    highstate install ${solution[saltdir]} config
    highstate install ${solution[saltdir]} database
    highstate install ${solution[saltdir]} auth
    highstate install ${solution[saltdir]} hotpot
    highstate install ${solution[saltdir]} sushi
    highstate install ${solution[saltdir]} backend
    highstate install ${solution[saltdir]} dock
    highstate install ${solution[saltdir]} dashboard
    highstate install ${solution[saltdir]} gelato
    highstate install ${solution[saltdir]} freespace
    cp ${SALTFS}/namespaces/${solution['entity']}/${solution[repo]}/conf/*.json /etc/opensds/ 2>/dev/null
}

custom-postinstall() {
    LXD=${SALTFS}/namespaces/saltstack-formulas/lxd-formula
    # see https://github.com/saltstack-formulas/lxd-formula#clone-and-symlink
    [ -d "${LXD}/_modules" ] && ln -s ${LXD}/_modules ${SALTFS}/_modules 2>/dev/null
    [ -d "${LXD}/_states" ] && ln -s ${LXD}/_states ${SALTFS}/_states 2>/dev/null

    # SUSE/Deepsea/Ceph
    if (( $? == 0 )) && [[ "${1}" == "deepsea" ]]; then
       salt-call --local grains.append deepsea default ${solution['saltmaster']}
       cp ${solution['homedir']}/file_roots/install/deepsea_post.sls ${SALTFS}/${STATES_DIR}/top.sls
    fi
}

### MAIN

developer-definitions
solution-definitions
salter-engine
exit $?

