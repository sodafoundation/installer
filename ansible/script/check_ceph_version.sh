#!/usr/bin/env bash

# Copyright 2019 The soda Authors.
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

cephver=$(ceph --version |grep -Eow '^ceph version [^ ]+' |gawk '{ print $3 }')
echo "The actual version of Ceph is $cephver"

if [[ "$cephver" <  1.0.0 ]]; then
  echo "Ceph installation is required"
  exit 1
fi

exit 0

