#!/bin/bash

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

set -e
export PATH=$PATH:/home/$USER/.local/bin

install_delfin(){
    # Enable Delfin, SRM Toolchain and Dashboard installation
    sed -i 's/^enable_delfin: .*/enable_delfin: '"true"'/g' ansible/group_vars/delfin.yml
    sed -i 's/^install_srm_toolchain: .*/install_srm_toolchain: '"true"'/g' ansible/group_vars/srm-toolchain.yml
    sed -i 's/^enable_dashboard: .*/enable_dashboard: '"true"'/g' ansible/group_vars/dashboard.yml
    sudo -E env "PATH=$PATH" ansible-playbook ansible/site.yml -i ansible/local.hosts -v
    sudo -E env "PATH=$PATH" ansible-playbook ansible/clean.yml -i ansible/local.hosts -v
    sed -i 's/^enable_delfin: .*/enable_delfin: '"false"'/g' ansible/group_vars/delfin.yml
    sed -i 's/^install_srm_toolchain: .*/install_srm_toolchain: '"false"'/g' ansible/group_vars/srm-toolchain.yml
    sed -i 's/^enable_dashboard: .*/enable_dashboard: '"false"'/g' ansible/group_vars/dashboard.yml
}

install_hotpot(){
    # Hotpot installation with Dashboard using release
    sed -i 's/^enable_hotpot: .*/enable_hotpot: '"true"'/g' ansible/group_vars/hotpot.yml
    sed -i 's/^enable_dashboard: .*/enable_dashboard: '"true"'/g' ansible/group_vars/dashboard.yml
    sudo -E env "PATH=$PATH" ansible-playbook ansible/site.yml -i ansible/local.hosts -v
    sudo -E env "PATH=$PATH" ansible-playbook ansible/clean.yml -i ansible/local.hosts

    # Hotpot installation using repository
    sed -i 's/^enable_dashboard: .*/enable_dashboard: '"false"'/g' ansible/group_vars/dashboard.yml
    sed -i 's/^install_from: .*/install_from: '"repository"'/g' ansible/group_vars/common.yml
    sudo -E env "PATH=$PATH" ansible-playbook ansible/site.yml -i ansible/local.hosts -v
    sudo -E env "PATH=$PATH" ansible-playbook ansible/clean.yml -i ansible/local.hosts

    # Hotpot installation using container
    sed -i 's/^install_from: .*/install_from: '"container"'/g' ansible/group_vars/common.yml
    sudo -E env "PATH=$PATH" ansible-playbook ansible/site.yml -i ansible/local.hosts
    sudo -E env "PATH=$PATH" ansible-playbook ansible/clean.yml -i ansible/local.hosts

    # Reset
    sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
    sed -i 's/^enable_hotpot: .*/enable_hotpot: '"false"'/g' ansible/group_vars/hotpot.yml
    sed -i 's/^enable_dashboard: .*/enable_dashboard: '"false"'/g' ansible/group_vars/dashboard.yml
}


case "$# $1" in
    "1 delfin")
    echo "Validate the installation using repository type"
    install_delfin
    ;;
    "1 hotpot")
    echo "Validate the installation using container type"
    install_hotpot
    ;;
     *)
    echo "Usage: $(basename $0) <delfin|hotpot>"
    exit 1
    ;;
esac
