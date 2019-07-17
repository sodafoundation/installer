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

######################################################
# Adaption layer - GNU Linux basic package management
######################################################

[[ `id -u` != 0 ]] && echo && echo "Run script with sudo, exiting" && echo && exit 1

while getopts ":i:u:r:q:" action; do
    case "${action}" in

    ## QUERY PACKAGE
    q)  shift
        PACKAGE=${@}
        if [ "${OSTYPE}" == linux* ]
        then
            if [ -f "/usr/bin/zypper" ]; then
                 /usr/bin/zypper se -si ${PACKAGE}
            elif [ -f "/usr/bin/yum" ]; then
                 /usr/bin/rpm -qa | grep ${PACKAGE}
            elif [[ -f "/usr/bin/apt-get" ]]; then
                 /usr/bin/dpkg-query --list | grep ${PACKAGE}
            fi
        fi
        ;;

    ## INSTALL PACKAGE(S) ##

    i)  shift
        PACKAGES=${@}
        case ${OSTYPE} in
        darwin*) USER=$( stat -f "%Su" /dev/console )
                 for p in ${PACKAGES}
                 do
                     su ${USER} -c "brew install ${p}"
                     su ${USER} -c "brew unlink ${p} 2>/dev/null && brew link ${p} 2>/dev/null"
                 done
                 awk >/dev/null 2>&1
                 if (( $? == 134 ))
                 then
                     #### From https://github.com/atomantic/dotfiles/issues/23#issuecomment-298784915 ###
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
                     /usr/bin/pacman-mirrors -g
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
                 ;;
        esac
        ;;

    ## UPGRADE PACKAGE(S) ##

    u)  shift
        PACKAGES=${@}
        case ${OSTYPE} in
        darwin*) USER=$( stat -f "%Su" /dev/console )
                 for p in ${PACKAGES}
                 do
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
                 ;;
        esac
        ;;

    ## REMOVE PACKAGE(S) ##

    r)  shift
        PACKAGES=${@}
        case ${OSTYPE} in
        darwin*) USER=$( stat -f "%Su" /dev/console )
                 for p in ${PACKAGES}
                 do
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
                 ;;
        esac
        ;;
    esac
done
shift $((OPTIND-1))
exit 0
