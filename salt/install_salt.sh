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
# Adaption layer - bootstrap saltstack locally
##############################################

[[ `id -u` != 0 ]] && echo && echo "Run script with sudo, exiting" && echo && exit 1

PACKAGE_EA_CMD=$( dirname $0 )/ea/package_ea.sh
RELEASE=""

case "${OSTYPE}" in
darwin*) USER=$( stat -f "%Su" /dev/console )
         su ${USER} -c 'brew tap homebrew/services'
         which salt >/dev/null 2>&1
         if (( $? > 0 )); then
             ${PACKAGE_EA_CMD} -i saltstack || exit 10
         else
             ${PACKAGE_EA_CMD} -u saltstack || exit 10
         fi
         ;;

linux*)  ${PACKAGE_EA_CMD} -i python-pip 2>/dev/null
         ${PACKAGE_EA_CMD} -i python2-pip 2>/dev/null
         ${PACKAGE_EA_CMD} -i git wget || exit 10

         wget -O install_salt.sh https://bootstrap.saltstack.com || exit 10
         (sh install_salt.sh -P ${RELEASE} && rm -f install_salt.sh) || exit 10
         ;;
esac
exit 0
