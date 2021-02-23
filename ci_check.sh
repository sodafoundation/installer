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

# Enable both the SRM Toolchain and Orchestration Manager installation
# sed -i 's/^enable_telemetry_tools: .*/enable_telemetry_tools: '"true"'/g' ansible/group_vars/telemetry.yml
sed -i 's/^install_srm_toolchain: .*/install_srm_toolchain: '"true"'/g' ansible/group_vars/srm-toolchain.yml
sed -i 's/^enable_orchestration: .*/enable_orchestration: '"true"'/g' ansible/group_vars/orchestration.yml
# Validate the installation using release type
sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
sudo -E env "PATH=$PATH" ansible-playbook ansible/site.yml -vv -i ansible/local.hosts
sudo -E env "PATH=$PATH" ansible-playbook ansible/clean.yml -vv -i ansible/local.hosts

# Only disable the Orchestration Manager installation
# sed -i 's/^enable_telemetry_tools: .*/enable_telemetry_tools: '"true"'/g' ansible/group_vars/telemetry.yml
sed -i 's/^install_srm_toolchain: .*/install_srm_toolchain: '"true"'/g' ansible/group_vars/srm-toolchain.yml
sed -i 's/^enable_orchestration: .*/enable_orchestration: '"false"'/g' ansible/group_vars/orchestration.yml
# Validate the installation using repository type
sed -i 's/^install_from: .*/install_from: '"repository"'/g' ansible/group_vars/common.yml
sudo -E env "PATH=$PATH" ansible-playbook ansible/site.yml -vv -i ansible/local.hosts
sudo -E env "PATH=$PATH" ansible-playbook ansible/clean.yml -vv -i ansible/local.hosts

# Disable both the SRM Toolchain and Orchestration Manager installation
# sed -i 's/^enable_telemetry_tools: .*/enable_telemetry_tools: '"false"'/g' ansible/group_vars/telemetry.yml
sed -i 's/^install_srm_toolchain: .*/install_srm_toolchain: '"false"'/g' ansible/group_vars/srm-toolchain.yml
sed -i 's/^enable_orchestration: .*/enable_orchestration: '"false"'/g' ansible/group_vars/orchestration.yml
# Validate the installation using container type
sed -i 's/^install_from: .*/install_from: '"container"'/g' ansible/group_vars/common.yml
sudo -E env "PATH=$PATH" ansible-playbook ansible/site.yml -vv -i ansible/local.hosts
sudo -E env "PATH=$PATH" ansible-playbook ansible/clean.yml -vv -i ansible/local.hosts
