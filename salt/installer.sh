#!/usr/bin/env bash
#----------------------------------------------------------------------
# Copyright 2019 Saltstack Formulas, The OpenSDS Authors
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
#-----------------------------------------------------------------------
#
# This script allows common bootstrapping for any salt-project.
#
COMMUNITYNAME=OpenSDS
PROJECT=${PROJECT:-opensds}
SUBPROJECT=opensds-installer
SUBDIR=salt
NAME="$( echo ${SUBPROJECT} | awk -F- '{print $NF}' )"
URI=https://github.com
USERNAME=''

STATES="opensds|gelato|auth|hotpot|backend|dashboard|database|dock|keystone|config|infra|sushi|freespace|telemetry|deepsea"
#
#----------------------
#  Developer settings
#---------------------
# FORK_URI=https://github.com
# FORK_PROJECT=noelmcloughlin
# FORK_BRANCH="develop"
# FORK_SUBPROJECTS="opensds-installer"

#********************************
#  Boilerplate implementation
#********************************
trap exit SIGINT SIGTERM
[[ `id -u` != 0 ]] && echo && echo "Run script with sudo, exiting" && echo && exit 1

MASTER_HOST=''
if [[ `uname` == 'FreeBSD' ]]; then
    BASE=/usr/local/etc
    BASE_ETC=/usr/local/etc
    DIR=salt
    STATES_DIR=states  #file_roots is /usr/local/etc/salt/states
else
    BASE=${BASE:-/srv}
    BASE_ETC=/etc
    DIR=
    STATES_DIR=''      #file_roots is /srv/salt
fi
SALTFS=${BASE:-/srv}/${DIR:-salt}
WORKDIR=$(pwd)

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
    darwin*) USER=$( stat -f "%Su" /dev/console )
             for p in ${PACKAGES}; do
                 su ${USER} -c "brew install ${p}"
                 su ${USER} -c "brew unlink ${p} 2>/dev/null && brew link ${p} 2>/dev/null"
             done
             awk >/dev/null 2>&1
             if (( $? == 134 )); then
                 ## https://github.com/atomantic/dotfiles/issues/23#issuecomment-298784915 ###
                 brew uninstall gawk
                 brew uninstall readline
                 brew install readline
                 brew install gawk
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
    darwin*) USER=$( stat -f "%Su" /dev/console )
             for p in ${PACKAGES}; do
                 su ${USER} -c "brew upgrade ${p}"
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
    darwin*) USER=$( stat -f "%Su" /dev/console )
             for p in ${PACKAGES}; do
                 su ${USER} -c "brew uninstall ${p} --force"
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

#-------------------------------
#---- salt-project -------------
#-------------------------------

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
        [[ -z "${MASTER_HOST}" ]] && MASTER_HOST=${MASTER}
    fi
    [[ -z "${MASTER_HOST}" ]] && MASTER_HOST=$( hostname )
    salt-key -A --yes >/dev/null 2>&1
}

salt-bootstrap() {
    get-salt-master-hostname
    if [ -f "/usr/bin/zypper" ] || [ -f "/usr/sbin/pkg" ]; then
        # No major version pegged packages support for suse/freebsd
        SALT_VERSION=''
    fi
    rm -fr ${BASE}/pillar/* 2>/dev/null

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
             sudo python get-pip.py 2>/dev/null

             which brew|su - ${USER} -c '/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
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
             sed -i"bak" "s/#file_client: remote/file_client: local/" /etc/salt/minion

             ##Workaround https://github.com/Homebrew/brew/issues/4099
             echo '--no-alpn' >> ~/.curlrc
             export HOMEBREW_CURLRC=1
             ;;

     linux*) OSHOME=/home
             pkg-update 2>/dev/null
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
    ### install salt-api (except arch)
    [ -f "/etc/arch-release" ] || pkg-install salt-api

    ### salt services
    if [[ "`uname`" == "FreeBSD" ]] || [[ "`uname`" == "Darwin" ]]; then
        sed -i"bak" "s@^\s*#*\s*master\s*: salt\s*\$@master: ${MASTER_HOST}@" ${BASE_ETC}/salt/minion
    else
        sed -i "s@^\s*#*\s*master\s*: salt\s*\$@master: ${MASTER_HOST}@" ${BASE_ETC}/salt/minion
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
    LOGDIR=${1} && LOG=${2}
    mkdir -p ${LOGDIR} 2>/dev/null
    salt-call --versions >>${LOG} 2>&1
    [ -f "${BASE}/pillar.site.j2" ] && cat ${BASE}/pillar/site.j2 >>${LOG} 2>&1
    cat ${BASE}/pillar/*.sls >>${LOG} 2>&1
    echo >> ${LOG}
    salt-call pillar.items --local >> ${LOG} 2>&1
    echo >>${LOG} 2>&1
    salt-call state.show_top --local | tee -a ${LOG} 2>&1
    echo >>${LOG} 2>&1
    echo "run salt: this takes a while, please be patient ..."
}

### Pull down project
clone-project() {
    PROJ=${1} && SUBPROJ=${2} && ALIAS=${3} && CHILD=${4} && GIT=${5}
    echo "cloning ${SUBPROJ} for ${COMMUNITYNAME} ..."
    mkdir -p ${SALTFS}/${STATES_DIR}/community/${PROJ} 2>/dev/null
    rm -fr ${SALTFS}/${STATES_DIR}/community/${PROJ}/${SUBPROJ} 2>/dev/null

    echo "${FORK_SUBPROJECTS}" | grep "${SUBPROJ}" >/dev/null 2>&1
    if (( $? == 0 )) && [[ -n "${FORK_URI}" ]] && [[ -n "${FORK_PROJECT}" ]] && [[ -n "${FORK_BRANCH}" ]]; then
        echo "... using fork: ${FORK_PROJECT}, branch: ${FORK_BRANCH}"
        git clone ${FORK_URI}/${FORK_PROJECT}/${SUBPROJ} ${SALTFS}/${STATES_DIR}/community/${PROJ}/${SUBPROJ} >/dev/null 2>&1 || exit 11
        cd  ${SALTFS}/${STATES_DIR}/community/${PROJ}/${SUBPROJ} && git checkout ${FORK_BRANCH}
    else
        git clone ${GIT}/${PROJ}/${SUBPROJ} ${SALTFS}/${STATES_DIR}/community/${PROJ}/${SUBPROJ} >/dev/null 2>&1 || exit 11
    fi
    echo && ln -s ${SALTFS}/${STATES_DIR}/community/${PROJ}/${SUBPROJ}/${CHILD} ${SALTFS}/${STATES_DIR}/${ALIAS} 2>/dev/null
}

pillar_roots() {
    PILLAR_ROOTS_SOURCE=${1} && mkdir -p ${BASE}/pillar/ 2>/dev/null
    cp -Rp ${PILLAR_ROOTS_SOURCE}/* ${BASE}/pillar/ 2>/dev/null
}


highstate() {
    was-salt-done || usage
    ACTION=${1} && NAME=${2} && FILE_ROOTS_SOURCE=${3}
    salt-key -A --yes >/dev/null 2>&1
    [ -n "${DEBUGG_ON}" ] && salt-key -L

    if [ -n "${USERNAME}" ]; then    #find/replace username placeholders in pillar data
        case "$OSTYPE" in
        darwin*) grep -rl 'domainadm' ${BASE}/pillar | xargs sed -i '' "s/domainadm/undefined_user/g" 2>/dev/null
                 grep -rl 'undefined_user' ${BASE}/pillar | xargs sed -i '' "s/undefined_user/${USERNAME}/g" 2>/dev/null
                 ;;
        linux*)  grep -rl 'domainadm' ${BASE}/pillar | xargs sed -i "s/domainadm/undefined_user/g" 2>/dev/null
                 grep -rl 'undefined_user' ${BASE}/pillar | xargs sed -i "s/undefined_user/${USERNAME}/g" 2>/dev/null
        esac
    fi

    cp ${FILE_ROOTS_SOURCE}/${NAME}.sls ${SALTFS}/${STATES_DIR}/top.sls 2>/dev/null
    LOGDIR=/tmp/${ACTION}-${PROJECT}-${SUBPROJECT}-${NAME}
    LOG=${LOGDIR}/log.$( date '+%Y%m%d%H%M' )
    setup-log ${LOGDIR} ${LOG}
    salt-call state.highstate --local ${DEBUGG_ON} --retcode-passthrough saltenv=base  >>${LOG} 2>&1
    [ -f "${LOG}" ] && (tail -6 ${LOG} | head -4) 2>/dev/null && echo "See full log in [ ${LOG} ]"
    echo
    echo "///////////////////////////////////////////////////////////////////////////"
    echo "      congrats:  ${NAME} for ${COMMUNITYNAME} is now installed"
    echo "///////////////////////////////////////////////////////////////////////////"
    echo
}

### salt-formula should do some of this instead
clone-saltstack-formulas() { 
    was-salt-done || usage
    FILE_ROOTS_SOURCE=${1} && NAME=${2}
    cp ${FILE_ROOTS_SOURCE}/${NAME}.sls ${SALTFS}/${STATES_DIR}/top.sls 2>/dev/null
    for formula in $( grep '^.* - ' ${SALTFS}/${STATES_DIR}/top.sls |awk '{print $2}' |cut -d'.' -f1 |uniq )
    do
        ## adjust for state and formula name mismatches
        case ${formula} in
        linuxvda)   source='citrix-linuxvda' ;;
        resharper)  source='jetbrains-resharper';;
        pycharm)    source='jetbrains-pycharm';;
        goland)     source='jetbrains-goland';;
        rider)      source='jetbrains-rider';;
        datagrip)   source='jetbrains-datagrip';;
        clion)      source='jetbrains-clion';;
        rubymine)   source='jetbrains-rubymine';;
        appcode)    source='jetbrains-appcode';;
        webstorm)   source='jetbrains-webstorm';;
        phpstorm)   source='jetbrains-phpstorm';;
        *)          source=${formula} ;;
        esac
        clone-project saltstack-formulas ${source}-formula ${formula} ${formula} https://github.com
    done
}

usage() {
    echo "Usage: sudo $0 -i INSTALL_TARGET [ OPTIONS ]" 1>&2
    echo "Usage: sudo $0 -r REMOVE_TARGET [ OPTIONS ]" 1>&2
    echo 1>&2
    echo "  TARGETS" 1>&2
    echo 1>&2
    echo "\tsalt\t\tBootstrap Salt and Salt formula" 1>&2
    echo 1>&2
    echo "\t${PROJECT}\tApply all ${COMMUNITYNAME} states" 1>&2
    echo 1>&2
    echo " ${STATES}" 1>&2
    echo "\t\t\tApply specific ${COMMUNITYNAME} state" 1>&2
    echo 1>&2
    echo "  OPTIONS" 1>&2
    echo 1>&2
    echo "  [-l <all|debug|warning|error|quiet]" 1>&2
    echo "      Optional log-level (default warning)" 1>&2
    echo 1>&2
    echo "   [ -l debug ]    Debug output in logs." 1>&2
    echo 1>&2
    echo "  [-u <loginname>]" 1>&2
    echo "        Valid loginname (local or corporate user)." 1>&2
    echo 1>&2
    exit 1
}

INSTALL_TARGET=salt && REMOVE_TARGET=''
while getopts ":i:l:r:u:" option; do
    case "${option}" in
    i)  INSTALL_TARGET=${OPTARG:-menu} ;;
    r)  REMOVE_TARGET=${OPTARG}
        INSTALL_TARGET='' ;;
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

was-salt-done() {
    get-salt-master-hostname && [ -d ${SALTFS}/${STATES_DIR}/community/${PROJECT}/${SUBPROJECT} ]
    (( $? > 0 )) && (echo "Run salt first" && return 1)
    return 0
}

business-logic()
{
    STATES_DIR_SYMLINK=${SALTFS}/${STATES_DIR}/${NAME}/file_roots/install           ## path includes symlink
    get-salt-master-hostname

    # install option
    case "${INSTALL_TARGET}" in
    salt)     salt-bootstrap                                                    ## bootstrap salt software
              clone-project saltstack-formulas salt-formula salt salt ${URI}    ## clone salt formula
              clone-project ${PROJECT} ${SUBPROJECT} ${NAME} ${SUBDIR} ${URI}   ## clone our Project
              pillar_roots ${SALTFS}/${STATES_DIR}/${NAME}/pillar_roots         ## path includes symlnk
              highstate install salt ${STATES_DIR_SYMLINK}                      ## apply salt metastate
              rm /usr/local/bin/salter.sh 2>/dev/null
              ln -s ${SALTFS}/${STATES_DIR}/${NAME}/installer.sh /usr/local/bin/salter.sh 2>/dev/null
              ;;

    opensds)  ## YOUR PROJECT
              clone-project ${PROJECT} ${SUBPROJECT} ${NAME} ${SUBDIR} ${URI}   ## clone our Project (in case)
              clone-saltstack-formulas ${STATES_DIR_SYMLINK} ${NAME}
              losetup -D 2>/dev/null
              highstate install infra ${STATES_DIR_SYMLINK}
              highstate install telemetry ${STATES_DIR_SYMLINK}
              highstate install keystone ${STATES_DIR_SYMLINK}
              #show-logger /tmp/devstack/stack.sh.log
              highstate install config ${STATES_DIR_SYMLINK}
              highstate install database ${STATES_DIR_SYMLINK}
              highstate install auth ${STATES_DIR_SYMLINK}
              highstate install hotpot ${STATES_DIR_SYMLINK}
              highstate install sushi ${STATES_DIR_SYMLINK}
              highstate install backend ${STATES_DIR_SYMLINK}
              highstate install dock ${STATES_DIR_SYMLINK}
              highstate install dashboard ${STATES_DIR_SYMLINK}
              highstate install gelato ${STATES_DIR_SYMLINK}
              highstate install freespace ${STATES_DIR_SYMLINK}
              [[ -d /etc/${PROJECT} ]] && cp ${STATES_DIR_SYMLINK}/../../../conf/policy.json /etc/opensds/
              ;;

    *)        ## INDIVIDUAL STATES
              echo "${STATES}" | grep "${INSTALL_TARGET}" >/dev/null 2>&1
              if (( $? == 0 )) || [ -f ${STATES_DIR_SYMLINK}/install/${INSTALL_TARGET}.sls ]; then
                  clone-saltstack-formulas ${STATES_DIR_SYMLINK} ${NAME}
                  highstate install ${INSTALL_TARGET} ${STATES_DIR_SYMLINK}
                  [ -d /etc/${PROJECT} ] && cp ${STATES_DIR_SYMLINK}/../../../conf/policy.json /etc/opensds/

                  ## deepsea post-install step
                  if (( $? == 0 )) && [[ "${INSTALL_TARGET}" == "deepsea" ]]; then
                     salt-call --local grains.append deepsea default ${MASTER_HOST}
                     cp ${STATES_DIR_SYMLINK}/deepsea_post.sls ${SALTFS}/${STATES}/top.sls
                  fi
                  return 0
              fi
              echo "Not implemented" && usage 1
    esac

    # remove option
    if [ -n "${REMOVE_TARGET}" ]; then
        echo "${STATES}" | grep "${REMOVE_TARGET}" >/dev/null 2>&1
        if (( $? == 0 )) && [ -f ${STATES_DIR_SYMLINK}/remove/${INSTALL_TARGET}.sls ]; then
           highstate remove ${INSTALL_TARGET} ${STATES_DIR_SYMLINK}
           return $?
        fi
        echo "Not implemented" && usage 1
    fi
}

## MAIN
business-logic
