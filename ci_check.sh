#!/bin/bash

# Copyright (c) 2019 The OpenSDS Authors.
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
sed -i 's/^install_telemetry_tools: .*/install_telemetry_tools: '"true"'/g' ansible/group_vars/telemetry.yml
# Validate the installation using repository type
sed -i 's/^install_from: .*/install_from: '"repository"'/g' ansible/group_vars/common.yml
sudo -E env "PATH=$PATH" ansible-playbook ansible/site.yml -i ansible/local.hosts
sudo -E env "PATH=$PATH" ansible-playbook ansible/clean.yml -i ansible/local.hosts
# Validate the installation using release type
sed -i 's/^install_from: .*/install_from: '"release"'/g' ansible/group_vars/common.yml
sudo -E env "PATH=$PATH" ansible-playbook ansible/site.yml -i ansible/local.hosts
sudo -E env "PATH=$PATH" ansible-playbook ansible/clean.yml -i ansible/local.hosts
# Validate the installation using container type
sed -i 's/^install_from: .*/install_from: '"container"'/g' ansible/group_vars/common.yml
sudo -E env "PATH=$PATH" ansible-playbook ansible/site.yml -i ansible/local.hosts
sudo -E env "PATH=$PATH" ansible-playbook ansible/clean.yml -i ansible/local.hosts
