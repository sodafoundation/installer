#!/bin/bash

echo Enabling docker repository
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update local repositories
echo Updating local repositories
sudo apt-get update

# Install dependencies
echo Installing dependencies
sudo apt-get install -y make curl wget libltdl7 libseccomp2 libffi-dev gawk apt-transport-https ca-certificates curl gnupg gnupg-agent lsb-release software-properties-common sshpass pv

# Install python dependencies
echo Installing Python dependencies
sudo apt-get install -y python3-distutils
sudo apt-get install -y python3-pip
python3 -m pip install -U pip setuptools

# Install ansible if not present
if [ "`which ansible`" != ""  ]; then
    echo ansible already installed, skipping.
else
    echo Installing ansible
    python3 -m pip install --user ansible
fi

# Install docker if not present
if [ "`which docker`" != ""  ]; then
    echo Docker already installed, skipping.
else
    echo Installing docker
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo adduser $USER vboxsf
fi

# Install Go if not present
if [ "`which go`" != "" ]; then
    IFS=' '
    v=`go version | { read _ _ v _; echo ${v#go}; }`
    IFS='.'
    read -ra v <<< "$v"
    if (( ${v[0]} == 1 && ${v[1]} >= 17 )); then
        echo Go 1.17+ already installed, skipping.
    else
        echo Found unsupported Go version! Installation may FAIL!
        echo If installer configuration needs Go support, please uninstall current Go version and re run the script
    fi
    unset IFS v
else
    echo Installing Go 1.17.9
    wget https://storage.googleapis.com/golang/go1.17.9.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.17.9.linux-amd64.tar.gz
fi

# Ensure /usr/local/bin is in path
export PATH=$PATH:/usr/local/bin:/usr/local/go/bin
export GOPATH=$HOME/gopath
