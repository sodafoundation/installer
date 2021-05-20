#!/bin/bash

# Copyright 2021 The SODA Authors.
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

echo "Install required packages for python3 upgrade"
sudo apt-get install software-properties-common python-software-properties -y

echo "Add the python3 repository"
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update

echo "Installing python3.6..."
sudo apt-get install python3.6 -y

echo "Install and keep both python3.5.2 and python3.6"
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.5 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 2

echo "Install python3.6 virtual env and python3.6-dev"
sudo apt-get install python3.6-venv -y
sudo apt-get install python3.6-dev -y
sudo wget https://bootstrap.pypa.io/get-pip.py
sudo python3.6 get-pip.py
sudo ln -s /usr/bin/python3.6 /usr/local/bin/python3

echo "Install python3.6 distutils"
sudo apt-get install python-distutils-extra -y
pip install --upgrade pip

echo "Python2 Version:"
python -V

echo "Python3 version:"
python3 -V
