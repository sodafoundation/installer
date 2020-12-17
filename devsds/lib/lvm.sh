#!/bin/bash

# Copyright 2020 The SODA Authors.
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

# Save trace setting
_XTRACE_LVM=$(set +o | grep xtrace)
set +o xtrace

# Defaults
# --------
# Name of the lvm volume groups to use/create for iscsi volumes
VOLUME_GROUP_NAME=${VOLUME_GROUP_NAME:-opensds-volumes}
FILE_GROUP_NAME=${FILE_GROUP_NAME:-opensds-files}
FILE_VOLUME_GROUP_NAME=${VOLUME_GROUP_NAME:-opensds-files}
DEFAULT_VOLUME_GROUP_NAME=$VOLUME_GROUP_NAME-default
FILE_DEFAULT_VOLUME_GROUP_NAME=$FILE_GROUP_NAME-default

# Name of lvm nvme volume group to use/create for nvme volumes
NVME_VOLUME_GROUP_NAME=$VOLUME_GROUP_NAME-nvme
# Backing file name is of the form $VOLUME_GROUP$BACKING_FILE_SUFFIX
BACKING_FILE_SUFFIX=-backing-file
# Default volume size
VOLUME_BACKING_FILE_SIZE=${VOLUME_BACKING_FILE_SIZE:-20G}
LVM_DIR=$OPT_DIR/lvm
DATA_DIR=$LVM_DIR
mkdir -p $LVM_DIR

FILE_LVM_DIR=$OPT_DIR/nfs
FILE_DATA_DIR=$FILE_LVM_DIR
mkdir -p $FILE_LVM_DIR


# nvme dir
NVME_DIR=/opt/opensdsNvme
# nvme device
LVM_DEVICE=/dev/nvme0n1

soda::lvm::pkg_install(){
    sudo apt-get install -y lvm2 tgt open-iscsi ibverbs-utils
}

soda::nfs::pkg_install(){
    sudo apt-get install -y nfs-kernel-server
}

soda::lvm::pkg_uninstall(){
    sudo apt-get purge -y lvm2 tgt open-iscsi ibvverbs-utils
}

soda::lvm::nvmeofpkginstall(){
    # nvme-cli utility for nvmeof initiator
    wget https://github.com/linux-nvme/nvme-cli/archive/v1.8.1.tar.gz -O /opt/nvmecli-1.8.1.tar.gz
    sudo tar -zxvf /opt/nvmecli-1.8.1.tar.gz -C /opt/
    cd /opt/nvme-cli-1.8.1 && sudo make && sudo make install
    # nvme kernel
    sudo modprobe nvmet
    sudo modprobe nvme-tcp
    sudo modprobe nvmet-tcp
    sudo modprobe nvme-rdma
    sudo modprobe nvmet-rdma
    sudo modprobe nvme-fc
    sudo modprobe nvmet-fc
}

soda::lvm::nvmeofpkguninstall(){
    sudo nvme disconnect-all
    sudo modprobe -r nvme-rdma
    sudo modprobe -r nvmet-rdma
    sudo modprobe -r nvme-tcp
    sudo modprobe -r nvmet-tcp
    sudo modprobe -r nvme-fc
    sudo modprobe -r nvmet-fc
    sudo modprobe -r nvmet
}

soda::lvm::create_volume_group(){
    local vg=$1
    local size=$2

    local backing_file=$DATA_DIR/$vg$BACKING_FILE_SUFFIX
    if ! sudo vgs $vg; then
        # Only create if the file doesn't already exists
        [[ -f $backing_file ]] || truncate -s $size $backing_file
        local vg_dev
        vg_dev=`sudo losetup -f --show $backing_file`

        # Only create volume group if it doesn't already exist
        if ! sudo vgs $vg; then
            sudo vgcreate $vg $vg_dev
        fi
    fi
}

soda::lvm::create_volume_group_for_file(){
    local fvg="opensds-files-default"
    local size=$2

    local backing_file=$FILE_DATA_DIR/$fvg$BACKING_FILE_SUFFIX
    if ! sudo vgs $fvg; then
        # Only create if the file doesn't already exists
        [[ -f $backing_file ]] || truncate -s $size $backing_file
        local vg_dev
        vg_dev=`sudo losetup -f --show $backing_file`

        # Only create volume group if it doesn't already exist
        if ! sudo vgs $fvg; then
            sudo vgcreate $fvg $vg_dev
        fi
    fi
}

soda::lvm::create_nvme_vg(){
    local vg=$1
    local size=$2
    cap=$(parted $LVM_DEVICE unit GB print free | grep 'Free Space' | tail -n1 | awk '{print $3}')
    if [ cap > '$size' ];then
        # Only create if the file doesn't already exists
        # create volume group and prepare kernel module
        sudo mkdir -p $NVME_DIR/$vg
        sudo mount $LVM_DEVICE $NVME_DIR/$vg
        local backing_file=$NVME_DIR/$vg/$vg$BACKING_FILE_SUFFIX
        if ! sudo vgs $vg; then
            # Only create if the file doesn't already exists
            [[ -f $backing_file ]] || truncate -s $size $backing_file
            local vg_dev
            vg_dev=`sudo losetup -f --show $backing_file`

            # Only create physical volume if it doesn't already exist
            if ! sudo pvs $vg_dev; then
                sudo pvcreate $vg_dev
            fi

            # Only create volume group if it doesn't already exist
            if ! sudo vgs $vg; then
                sudo vgcreate $vg $vg_dev
            fi
        fi
    else
        echo "disk $LVM_DEVICE does not have enough space"
    fi
}

soda::lvm::set_configuration(){
cat > $SODA_DRIVER_CONFIG_DIR/lvm.yaml << OPENSDS_LVM_CONFIG_DOC
tgtBindIp: $HOST_IP
tgtConfDir: /etc/tgt/conf.d
pool:
  $DEFAULT_VOLUME_GROUP_NAME:
    diskType: NL-SAS
    availabilityZone: default
    multiAttach: true
    storageType: block
    extras:
      dataStorage:
        provisioningPolicy: Thin
        compression: false
        deduplication: false
      ioConnectivity:
        accessProtocol: iscsi
        maxIOPS: 7000000
        maxBWS: 600
        minIOPS: 1000000
        minBWS: 100
        latency: 100
      advanced:
        diskType: SSD
        latency: 5ms
OPENSDS_LVM_CONFIG_DOC

cat >> $SODA_CONFIG_DIR/opensds.conf << OPENSDS_LVM_GLOBAL_CONFIG_DOC
[lvm]
name = lvm
description = LVM Test
driver_name = lvm
config_path = /etc/opensds/driver/lvm.yaml

OPENSDS_LVM_GLOBAL_CONFIG_DOC
}

soda::lvm::set_configuration_for_file(){
cat > $SODA_DRIVER_CONFIG_DIR/nfs.yaml << OPENSDS_FILE_CONFIG_DOC
tgtBindIp: $HOST_IP
tgtConfDir: /etc/tgt/conf.d
pool:
  $FILE_DEFAULT_VOLUME_GROUP_NAME:
    diskType: NL-SAS
    availabilityZone: default
    multiAttach: true
    storageType: file
    extras:
      dataStorage:
        provisioningPolicy: Thin
        compression: false
        deduplication: false
        storageAccessCapability:
         - Read
         - Write
         - Execute
      ioConnectivity:
        accessProtocol: nfs
        maxIOPS: 7000000
        maxBWS: 600
        minIOPS: 1000000
        minBWS: 100
        latency: 100
      advanced:
        diskType: SSD
        latency: 5ms
OPENSDS_FILE_CONFIG_DOC

cat >> $SODA_CONFIG_DIR/opensds.conf << OPENSDS_FILE_GLOBAL_CONFIG_DOC
[nfs]
name = nfs
description = NFS LVM TEST
driver_name = nfs
config_path = /etc/opensds/driver/nfs.yaml

OPENSDS_FILE_GLOBAL_CONFIG_DOC
}

soda::lvm::set_nvme_configuration(){
cat >> $SODA_DRIVER_CONFIG_DIR/lvm.yaml << OPENSDS_LVM_CONFIG_DOC

  $NVME_VOLUME_GROUP_NAME:
    diskType: NL-SAS
    availabilityZone: default
    multiAttach: true
    storageType: block
    extras:
      dataStorage:
        provisioningPolicy: Thin
        compression: false
        deduplication: false
      ioConnectivity:
        accessProtocol: nvmeof
        maxIOPS: 7000000
        maxBWS: 600
        minIOPS: 1000000
        minBWS: 100
        latency: 100
      advanced:
        diskType: SSD
        latency: 20us
OPENSDS_LVM_CONFIG_DOC
}

soda::lvm::remove_volumes() {
    local vg=$1

    # Clean out existing volumes
    sudo lvremove -f $vg
}

soda::lvm::remove_volume_group() {
    local vg=$1

    # Remove the volume group
    sudo vgremove -f $vg
}
soda::lvm::remove_volume_group_for_file() {
    local fvg="opensds-files-default"
    # Remove the volume group
    sudo vgremove -f $fvg
}

soda::lvm::clean_backing_file() {
    local backing_file=$1
    # If the backing physical device is a loop device, it was probably setup by DevStack
    if [[ -n "$backing_file" ]] && [[ -e "$backing_file" ]]; then
        local vg_dev
        vg_dev=$(sudo losetup -j $backing_file | awk -F':' '/'$BACKING_FILE_SUFFIX'/ { print $1}')
        if [[ -n "$vg_dev" ]]; then
            sudo losetup -d $vg_dev
        fi
        rm -f $backing_file
    fi
}

soda::lvm::clean_volume_group_for_file() {
    local fvg="opensds-files-default"
    soda::lvm::remove_volume_group_for_file $fvg
    # if there is no logical volume left, it's safe to attempt a cleanup
    # of the backing file
    if [[ -z "$(sudo lvs --noheadings -o lv_name $fvg 2>/dev/null)" ]]; then
        soda::lvm::clean_backing_file $FILE_DATA_DIR/$fvg$BACKING_FILE_SUFFIX
    fi
}

soda::lvm::clean_volume_group() {
    local vg=$1
    soda::lvm::remove_volumes $vg
    soda::lvm::remove_volume_group $vg
    soda::lvm::remove_volume_group_for_file $fvg
    # if there is no logical volume left, it's safe to attempt a cleanup
    # of the backing file
    if [[ -z "$(sudo lvs --noheadings -o lv_name $vg 2>/dev/null)" ]]; then
        soda::lvm::clean_backing_file $DATA_DIR/$vg$BACKING_FILE_SUFFIX
    fi
}

soda::lvm::clean_nvme_volume_group(){
    local nvmevg=$1
    echo "nvme pool ${nvmevg}"
    soda::lvm::remove_volumes $nvmevg
    soda::lvm::remove_volume_group $nvmevg
    # if there is no logical volume left, it's safe to attempt a cleanup
    # of the backing file
    if [[ -z "$(sudo lvs --noheadings -o lv_name $nvmevg 2>/dev/null)" ]]; then
        soda::lvm::clean_backing_file $NVME_DIR/$nvmevg/$nvmevg$BACKING_FILE_SUFFIX
    fi
    ## umount nvme disk and remove corresponding dir
    for i in {1..10}
    do
	# 'umount -l' can umount even if target is busy
	sudo umount -l $NVME_DIR/$nvmevg
	if [ $? -eq 0 ]; then
		sudo rmdir $NVME_DIR/$nvmevg
		sudo rmdir $NVME_DIR
		echo "umount & removement succeed"
		return 0
	fi
	sleep 1
    done
    echo "umount failed after retry 10 times"
    echo "please check if there are any remaining attachments and umount dir ${NVME_DIRi}/${nvmevg} manually"
}


# soda::lvm::clean_lvm_filter() Remove the filter rule set in set_lvm_filter()

soda::lvm::clean_lvm_filter() {
    sudo sed -i "s/^.*# from devsds$//" /etc/lvm/lvm.conf
}

# soda::lvm::set_lvm_filter() Gather all devices configured for LVM and
# use them to build a global device filter
# soda::lvm::set_lvm_filter() Create a device filter
# and add to /etc/lvm.conf.  Note this uses
# all current PV's in use by LVM on the
# system to build it's filter.
soda::lvm::set_lvm_filter() {
    local filter_suffix='"r|.*|" ]  # from devsds'
    local filter_string="global_filter = [ "
    local pv
    local vg
    local line

    for pv_info in $(sudo pvs --noheadings -o name); do
        pv=$(echo -e "${pv_info}" | sed 's/ //g' | sed 's/\/dev\///g')
        new="\"a|$pv|\", "
        filter_string=$filter_string$new
    done
    filter_string=$filter_string$filter_suffix

    soda::lvm::clean_lvm_filter
    sudo sed -i "/# global_filter = \[.*\]/a\    $global_filter$filter_string" /etc/lvm/lvm.conf
    soda::echo_summary "set lvm.conf device global_filter to: $filter_string"
}


soda::lvm::install() {
    local vg=$DEFAULT_VOLUME_GROUP_NAME
    local fvg=$FILE_DEFAULT_VOLUME_GROUP_NAME
    local size=$VOLUME_BACKING_FILE_SIZE

    # Install lvm relative packages.
    soda::lvm::pkg_install
    soda::nfs::pkg_install
    soda::lvm::create_volume_group_for_file $fvg $size
    soda::lvm::create_volume_group $vg $size

    # Remove iscsi targets
    sudo tgtadm --op show --mode target | awk '/Target/ {print $3}' | sudo xargs -r -n1 tgt-admin --delete
    # Remove volumes that already exist.
    soda::lvm::remove_volumes $vg
    soda::lvm::set_configuration
    soda::lvm::set_configuration_for_file

    # Check nvmeof prerequisites
    local nvmevg=$NVME_VOLUME_GROUP_NAME
    if [[ -e "$LVM_DEVICE" ]]; then
        #phys_port_cnt=$(ibv_devinfo |grep -Eow hca_id |wc -l)
        #echo "The actual quantity of RDMA ports is $phys_port_cnt"
	#nvmetcpsupport=$(sudo modprobe nvmet-tcp)
        #if [[ "$phys_port_cnt" < '1' ]] && [ $nvmetcpsupport -ne 0 ] ; then
        #    echo "RDMA card not found , and kernel version can not support nvme-tcp "
        #else
        soda::lvm::create_nvme_vg $nvmevg $size
        soda::lvm::nvmeofpkginstall
        # Remove volumes that already exist
        soda::lvm::remove_volumes $nvmevg
        soda::lvm::set_nvme_configuration
        #fi
    fi
    soda::lvm::set_lvm_filter
}

soda::lvm::cleanup(){
    soda::lvm::clean_volume_group $DEFAULT_VOLUME_GROUP_NAME
    soda::lvm::clean_volume_group_for_file $FILE_DEFAULT_VOLUME_GROUP_NAME
    soda::lvm::clean_lvm_filter
    local nvmevg=$NVME_VOLUME_GROUP_NAME
    if vgs $nvmevg ; then
    	soda::lvm::clean_nvme_volume_group $nvmevg
    fi
}

soda::lvm::uninstall(){
    : # do nothing
}

soda::lvm::uninstall_purge(){
    echo soda::lvm::pkg_uninstall
    echo soda::lvm::nvmeofpkguninstall
}

# Restore xtrace
$_XTRACE_LVM
