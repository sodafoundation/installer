#!/bin/bash

# Copyright 2020 The OpenSDS Authors.
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

HOST_IP=${HOST_IP:-}
HOST_IP=$(get_default_host_ip "$HOST_IP" "inet")
if [ "$HOST_IP" == "" ]; then
    echo "Failed to set HOST_IP."
fi
