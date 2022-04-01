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
# Original development at:
# * https://github.com/noelmcloughlin/salter
# * https://github.com/saltstack-formulas/salter
# SOLUTION section has additional copyright under this "License".
#--------------------------------------------------------------------------
#
# This script allows common bootstrapping for any project using salt
#
#-----------------------------------------------------------------------
trap exit SIGINT SIGTERM
[ `id -u` != 0 ] && echo -e "\nRun script with sudo, exiting\n" && exit 1

SALT_VERSION='stable 2019.2.0'    ##stick with stable previous release
RC=0
ACTION=
BASE=/srv
BASE_ETC=/etc
PY_VER=3
STATEDIR=''
USER=
if [ `uname` == "FreeBSD" ]; then
    BASE=/usr/local/etc
    BASE_ETC=/usr/local/etc
    STATEDIR=/states
    SUBDIR=/salt
elif [ "$( uname )" = "Darwin" ]; then
    # macos needs homebrew (unattended https://github.com/Homebrew/legacy-homebrew/issues/46779#issuecomment-162819088)
    USER=$( stat -f "%Su" /dev/console )
    HOMEBREW=/usr/local/bin/brew
    ${HOMEBREW} >/dev/null 2>&1
    (( $? == 127 )) && su - ${USER} -c 'echo | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
fi
HOMEBREW=/usr/local/bin/brew
PILLARFS=${BASE:-/srv}${SUBDIR}/pillar
SALTFS=${BASE:-/srv}/salt${STATEDIR}
SKIP_UNNECESSARY_CLONE=''
TERM_PS1=${PS1} && unset PS1
PROFILE=
DEBUGG=

# bash version must be modern
declare -A your solution fork 2>/dev/null || RC=$?
if (( RC > 0 )); then
    echo "[warning] your bash version is too old ..."
    if [ "$( uname )" = "Darwin" ]; then
        (( RC > 0 )) && (su - ${USER} -c "${HOMEBREW} install bash" || exit 12) && RC=0
    else
        exit ${RC}
    fi
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
    elif [[ -f "/usr/sbin/pkg" ]]; then
         /usr/sbin/pkg query ${PACKAGE}
    fi
}

pkg-add() {
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

    linux*|freebsd*)
             if [ -f "/usr/bin/zypper" ]; then
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
                 /usr/bin/yum install -y ${PACKAGES} --skip-broken || exit 1
             elif [[ -f "/usr/bin/apt-get" ]]; then
                 /usr/bin/apt-get update --fix-missing -y || exit 1
                 /usr/bin/apt-add-repository universe
                 /usr/bin/apt autoremove -y
                 /usr/bin/apt-get update -y
                 /usr/bin/apt-get install -y ${PACKAGES} || exit 1
             elif [[ -f "/usr/sbin/pkg" ]]; then
                 /usr/sbin/pkg update -f --quiet || exit 1
                 /usr/sbin/pkg install --automatic --yes ${PACKAGES} || exit 1
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
             elif [[ -f "/usr/sbin/pkg" ]]; then
                 /usr/sbin/pkg upgrade --yes ${PACKAGES} || exit 1
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
    linux*|freebsd*)
             if [ -f "/usr/bin/zypper" ]; then
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
             elif [[ -f "/usr/sbin/pkg" ]]; then
                 /usr/sbin/pkg delete --yes ${PACKAGES} || exit 1
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

             ### pip https://pip.pypa.io/en/stable
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

     linux*|freebsd*)
             pkg-update 2>/dev/null
             echo "Setup Linux/FreeBSD baseline and Salt masterless minion ..."
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
             elif [ -f "/usr/sbin/pkg" ]; then
                 PACKAGES="git wget psutils"
             fi
             pkg-add ${PACKAGES} 2>/dev/null
             if (( $? > 0 )); then
                echo "Failed to add packages"
                exit 1
             fi
             wget -O bootstrap_salt.sh https://bootstrap.saltstack.com || exit 10
             (sh bootstrap_salt.sh -x python3 ${SALT_VERSION} && rm -f bootstrap_salt.sh) || exit 10
             ;;
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
    ### salt-api (except arch/macos/freebsd)
    [ ! -f "/etc/arch-release" ] && [ "$(uname)" != "Darwin" ] && [ "$(uname)" != "FreeBSD" ] && pkg-add salt-api

    ### salt minion
    [ ! -f "${BASE_ETC}/salt/minion" ] && echo "File ${BASE_ETC}/salt/minion not found" && exit 1
    if [[ "`uname`" == "FreeBSD" ]] || [[ "`uname`" == "Darwin" ]]; then
        sed -i"bak" "s@^\s*#*\s*master\s*: salt\s*\$@master: ${solution[saltmaster]}@" ${BASE_ETC}/salt/minion
    else
        sed -i "s@^\s*#*\s*master\s*: salt\s*\$@master: ${solution[saltmaster]}@" ${BASE_ETC}/salt/minion
    fi
    ### salt services
    (systemctl enable salt-api && systemctl start salt-api) 2>/dev/null || service start salt-api 2>/dev/null
    (systemctl enable salt-master && systemctl start salt-master) 2>/dev/null || service start salt-master 2>/dev/null
    (systemctl enable salt-minion && systemctl start salt-minion) 2>/dev/null || service start salt-minion 2>/dev/null
    salt-key -A --yes >/dev/null 2>&1     ##accept pending registrations

    ### reboot to activate a new kernel?
    echo && KERNEL_VERSION=$( uname -r | awk -F. '{print $1"."$2"."$3"."$4"."$5}' )
    echo "kernel before: ${KERNEL_VERSION}"
    if [ "$(uname)" == "FreeBSD" ]; then
        echo "kernel after: $( /bin/freebsd-version -k 2>/dev/null )"
    else
        echo "kernel after: $( pkg-query linux 2>/dev/null )"
    fi
    echo "Reboot if kernel was major-upgraded; if unsure reboot!"
    echo
}

setup-log() {
    LOG=${1}
    mkdir -p ${solution[logdir]} 2>/dev/null
    salt-call --versions >>${LOG} 2>&1
    [ -f "${PILLARFS}/site.j2" ] && cat ${PILLARFS}/site.j2 >>${LOG} 2>&1
    [ -n "${DEBUGG_ON}" ] && salt-call pillar.items --local >> ${LOG} 2>&1 && echo >>${LOG} 2>&1
    salt-call state.show_top --local | tee -a ${LOG} 2>&1   ## slow with many pillar files = needs refactoring
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
    ## Its important to ensure symlink points to *this* correct namespace
    rm -f ${SALTFS}/${ALIAS} 2>/dev/null ## this is important make sure symlink is current
    echo && ln -s ${SALTFS}/namespaces/${ENTITY}/${REPO}/${SUBDIR} ${SALTFS}/${ALIAS} 2>/dev/null
}

highstate() {
    (get-salt-master-hostname && [ -d ${solution[homedir]} ]) || usage

    ## prepare states
    ACTION=${1} && STATEDIR=${2} && PROFILE=${3}
    for profile in ${solution[saltdir]}/${ACTION}/${PROFILE} ${your[saltdir]}/${ACTION}/${PROFILE}
    do  
        [ -f ${profile}.sls ] && cp ${profile}.sls ${SALTFS}/top.sls && break
        [ -f ${profile}/init.sls ] && cp ${profile}/init.sls ${SALTFS}/top.sls && break
    done
    [ ! -f ${SALTFS}/top.sls ] && echo "Failed to find ${PROFILE}.sls or ${PROFILE}/init.sls" && usage

    ## prepare pillars
    cp -Rp ${solution[pillars]}/* ${PILLARFS}/ 2>/dev/null
    cp -Rp ${your[pillars]}/* ${PILLARFS}/ 2>/dev/null
    if [ -n "${USER}" ]; then
        ### find/replace dummy usernames in pillar data ###
        case "$OSTYPE" in
        darwin*) grep -rl 'undefined_user' ${PILLARFS} | xargs sed -i '' "s/undefined_user/${USER}/g" 2>/dev/null
                 ;;
        linux*)  grep -rl 'undefined_user' ${PILLARFS} | xargs sed -i "s/undefined_user/${USER}/g" 2>/dev/null
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
    echo "        $(basename ${PROFILE}) for ${solution[repo]} has completed"
    echo "////////////////////////////////////////////////////////////////"
    echo
}

usage() {
    echo "Example usage:"
    echo "  salter add PROFILE..."
    echo "  salter edit PROFILE..."
    echo "  salter show PROFILE..."
    echo "  salter remove PROFILE..."
    echo 1>&2
    echo "Synopsis:"
    echo "  sudo $0 add PROFILE [ OPTIONS ] [ -u username ]" 1>&2
    echo "  sudo $0 add PROFILE [ OPTIONS ]" 1>&2
    echo "  sudo $0 remove PROFILE [ OPTIONS ]" 1>&2
    echo "  sudo $0 edit PROFILE [ OPTIONS ]" 1>&2
    echo "  sudo $0 show PROFILE [ OPTIONS ]" 1>&2
    echo 1>&2
    echo "Profiles:" 1>&2
    echo -e "  PROFILE\tAdd profile named PROFILE" 1>&2
    echo 1>&2
    if [ "${solution[alias]}" != "salter" ]; then
        echo 1>&2
        echo -e "\t${solution[entity]}\t${solution[repo]} profile" 1>&2
        echo 1>&2
    fi
    if [ -n "${solution[targets]}" ]; then
        echo 1>&2
        echo "${solution[targets]}, etc" 1>&2
        echo 1>&2
    fi
    echo "Options:"
    echo "  [-u <username>]" 1>&2
    echo "        A Loginname (current or corporate or root user)." 1>&2
    echo "        Optional for MacOS and many Linux profiles" 1>&2
    echo "        but not required on MacOS" 1>&2 
    echo 1>&2
    echo "  [-l <all|debug|warning|error|quiet]" 1>&2
    echo "      Optional log-level (default warning)" 1>&2
    echo 1>&2
    echo "Salter Installer" 1>&2
    echo -e "  sudo salter bootstrap\t\tre-bootstrap Salt" 1>&2
    echo -e "  sudo salter add salter\tre-bootstrap Salter" 1>&2
    echo 1>&2
    exit 1
}

explain_add_salter() {
    echo
    echo "==> This script will add:"
    echo "${SALTFS}/salter/salter.sh   (salter orchestrator)"
    echo "/usr/local/bin/salter        (salter symlink)"
    echo "Salt                         (orchestrator-of-infra-and-apps-at-scale)"
    echo "${SALTFS}/namespaces/*       (namespaces and profiles)"
    echo "${PILLARFS}/*                (namespaces and configs)"
    echo
    echo "==> Your namespace is:"
    echo "${SALTFS}/your/*             (profiles/configs designed by you)"
}

interact() {
    echo -e "$*\npress return to continue or control-c to abort"
    [ -n "$PS1" ] && read
}

salter-engine() {
    case ${ACTION} in
    remove) if [ -n "${PROFILE}" ] && [ -f ${solution[saltdir]}/${ACTION}/${PROFILE}.sls ]; then
                highstate remove ${solution[saltdir]} ${PROFILE}
                return 0
            else
                echo "No profile named [${PROFILE}] found" && usage
            fi ;;

    edit|show)
            ACTION_DIR=add
            [ -f ${solution[saltdir]}/remove/${PROFILE}.sls ] && ACTION_DIR=remove
            [ -f ${solution[saltdir]}/add/${PROFILE}.sls ] && ACTION_DIR=add
            if [ "${ACTION}" == 'show' ]; then
                [ ! -f "${solution[saltdir]}/${ACTION_DIR}/${PROFILE}.sls" ] && echo "profile ${PROFILE} not found" && exit 1
                cat ${solution[saltdir]}/${ACTION_DIR}/${PROFILE}.sls
                return
            elif [ ! -f ${solution[saltdir]}/${ACTION_DIR}/${PROFILE}.sls ]; then
                cp ${solution[saltdir]}/edit/template.sls ${solution[saltdir]}/${ACTION_DIR}/${PROFILE}.sls
            fi
            vi ${solution[saltdir]}/${ACTION_DIR}/${PROFILE}.sls
            [ ! -f "${solution[saltdir]}/${ACTION_DIR}/${PROFILE}.sls" ] && echo "you aborted" && exit 1
            echo -e "\nNow run: sudo salter ${ACTION_DIR} ${PROFILE}"
            ;;

    add)    case ${PROFILE} in
            bootstrap)  interact "==> This script will bootstrap: Salt"
                        salt-bootstrap ;;

            salter)     explain_add_salter && interact
                        gitclone 'https://github.com' "${solution[provider]}" salt-formula salt salt
                        gitclone ${solution[uri]} ${solution[entity]} ${solution[repo]} ${solution[alias]} ${solution[subdir]}
                        highstate add "${solution[saltdir]}" salt
                        rm /usr/local/bin/salter 2>/dev/null
                        ln -s ${solution[homedir]}/salter.sh /usr/local/bin/salter
                        ;;

            ${solution[alias]})
                        interact "==> This script will add: ${solution[entity]}"
                        custom-add ${solution[alias]} ;;

            menu)       pip${PY_VER} install --pre wrapper barcodenumber npyscreen || exit 1
                        ([ -x ${SALTFS}/contrib/menu.py ] && ${SALTFS}/contrib/menu.py ${solution[saltdir]}/install) || exit 2
                        highstate add "${solution[saltdir]}" ${PROFILE} ;;

            *)          interact "==> This script will add: ${PROFILE}"
                        if [ -f ${solution[saltdir]}/${ACTION}/${PROFILE}.sls ]; then
                            highstate add ${solution[saltdir]} ${PROFILE}
                            custom-postadd ${PROFILE}
                        fi
            esac
            ;;
    esac
}

cli-options() {
    (( $# == 0 )) && usage
    case ${1} in
    add|remove|edit|show)   ACTION=${1} && shift ;;
    bootstrap)              ACTION=add ;;
    install)                echo "install is deprecated - use 'add' instead" && ACTION=add && shift ;;
    menu)                   ACTION=add && shift ;;   ## not maintained
    *)                      usage ;;
    esac
    PROFILE="$( echo ${1%%.*} )"
    shift   #check for options

    while getopts ":i:l:u:" option; do
        case "${option}" in
        i)  PS1=TERM_PS1 ;;
        l)  case ${OPTARG} in
            'all'|'garbage'|'trace'|'debug'|'warning'|'error') DEBUGG="-l${OPTARG}" && set -xv
               ;;
            'quiet'|'info') DEBUGG="-l${OPTARG}"
               ;;
            *) DEBUGG="-lwarning"
            esac ;;
        u)  USER=${OPTARG}
            ([ "${USER}" == "username" ] || [ -z "${USER}" ]) && usage
        esac
    done
    shift $((OPTIND-1))
}

#########################################################################
# SOLUTION: Copyright 2019 The soda Authors
#########################################################################

developer-definitions() {
    fork['uri']="https://github.com"
    fork['entity']="noelmcloughlin"
    fork['branch']="fixes"
    fork['solutions']="salter packages-formula golang-formula postgres-formula"
}

solution-definitions() {
    solution['saltmaster']=""
    solution['uri']="https://github.com"
    solution['entity']="soda"
    solution['repo']="soda-installer"
    solution['alias']="soda"
    solution['subdir']="salt"
    solution['provider']="saltstack-formulas"
    solution['profiles']="soda|gelato|auth|hotpot|backend|dashboard|database|dock|keystone|config|infra|sushi|freespace|telemetry|deepsea"

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
    echo
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
    cp ${SALTFS}/namespaces/${solution['entity']}/${solution[repo]}/conf/*.json /etc/soda/ 2>/dev/null
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
cli-options $*
salter-engine
exit $?
