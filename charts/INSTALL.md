# OpenSDS Installation using Helm # 

## Prerequisite ##

### ubuntu
* Version information

	```
	root@proxy:~# cat /etc/issue
	Ubuntu 16.04.2 LTS \n \l
	```


#### Required Packages 

* Install following packages:
    ```bash
    apt-get install socat gcc make libc-dev docker.io
    apt-get install -y git curl wget libltdl7 libseccomp2
    apt-get install python-pip
    
    ```
* Install golang (Version 1.11.2)
    ```bash
    wget https://storage.googleapis.com/golang/go1.11.2.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.11.2.linux-amd64.tar.gz   
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile  
    echo 'export GOPATH=$HOME/gopath' >> /etc/profile  
    source /etc/profile
    ```
* Install etcd (Version 3.3.1)
    ```bash
    curl -L https://github.com/coreos/etcd/releases/download/v3.3.1/etcd-v3.3.1-linux-amd64.tar.gz -o etcd-v3.3.1-linux-amd64.tar.gz
    tar xzvf etcd-v3.3.1-linux-amd64.tar.gz
    cd etcd-v3.3.1-linux-amd64
    sudo cp etcd /usr/local/bin/
    sudo cp etcdctl /usr/local/bin/
    etcd –-version

    ```
* Install docker-compose:

    ```
    curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ```
### [kubernetes](https://github.com/kubernetes/kubernetes) local cluster
* You can startup `v1.13.0` k8s local cluster by executing commands below, etcd version 3.2.24 or greater required:

	```
	cd $HOME
	git clone https://github.com/kubernetes/kubernetes.git
	cd $HOME/kubernetes
	git checkout v1.13.0
	make
	echo alias kubectl='$HOME/kubernetes/cluster/kubectl.sh' >> /etc/profile
	ALLOW_PRIVILEGED=true FEATURE_GATES=CSIPersistentVolume=true,MountPropagation=true,VolumeSnapshotDataSource=true,KubeletPluginsWatcher=true RUNTIME_CONFIG="storage.k8s.io/v1alpha1=true" LOG_LEVEL=5 hack/local-up-cluster.sh
	```
	
### Helm Installation ###
* This will fetch the latest version of helm :

	```
	curl https://raw.githubusercontent.com/helm/helm/master/scripts/get >get_helm.sh
	chmod 700 get_helm.sh
	./get_helm.sh
	helm init
    ```
### Keystone installation and configuration ###

* Keystone Installation
	```
	git clone https://github.com/opensds/opensds-installer.git
	cd opensds-installer/ansible
	chmod +x ./install_ansible.sh && ./install_ansible.sh
	cd script
	./keystone.sh install 
	./keystone.sh config hotpot
    ```
### Ceph Installation
* Here we are creating only 1 ceph-osd node and Ceph luminous version ( For more details please refer [link](http://docs.ceph.com/ceph-ansible/master/)  )
* Clone Ceph repository
	```
	cd $HOME/kubernetes
	git clone -b stable-3.0 https://github.com/ceph/ceph-ansible.git
	
* Configure ```ceph-ansible/group_vars/all.yml``` by appending below portion:

    ```
    ceph_origin: repository
    ceph_repository: community
    ceph_stable_release: luminous # Choose luminous as default version
    public_network: "192.168.3.0/24" # Run 'ip -4 address' to check the ip address
    cluster_network: "{{ public_network }}"
    monitor_interface: eth1 # Change to the network interface on the target machine
    devices: # For ceph devices, append ONE or MULTIPLE devices like the example below:
      - '/dev/sda' # Ensure this device exists and available if ceph is chosen
      #- '/dev/sdb'  # Ensure this device exists and available if ceph is chosen
    osd_scenario: collocated
    ```

* You can manually create ceph.hosts file OR simply copy it from opensds-installer repo as follow: 
	```
	cd $HOME/kubernetes
	cp opensds-installer/ansible/group_vars/ceph/ceph.hosts ceph-ansible/
	# Install ceph cluster
	cd $HOME/kubernetes/ceph-ansible
	ansible all -m ping -i ceph.hosts
	ansible-playbook site.yml -i ceph.hosts | tee /var/log/ceph_ansible.log
	# Create pools if not available
	ceph osd crush tunables hammer
	grep -q "^rbd default features" /etc/ceph/ceph.conf || sed -i '/\[global\]/arbd default features = 1' /etc/ceph/ceph.conf
	ceph osd pool create rbd 100 && ceph osd pool set rbd size 1   

### OpenSDS helm chart installation

## Pre-configuration
* Before you start, some configurations are required:

    ```
    export BackendType="ceph" 

    sudo cat > /etc/opensds/opensds.conf <<OPENSDS_GLOABL_CONFIG_DOC
    [osdslet]
    api_endpoint = 0.0.0.0:50040
    graceful = True
    log_file = /var/log/opensds/osdslet.log
    socket_order = inc
    auth_strategy = keystone
    
    [osdsdock]
    api_endpoint = 0.0.0.0:50050
    log_file = /var/log/opensds/osdsdock.log
    # Choose the type of dock resource, only support 'provisioner' and 'attacher'.
    dock_type = provisioner
    # Enabled backend types, such as 'sample', 'lvm', 'ceph', 'cinder', etc.
    enabled_backends = ${BackendType}
    
    [ceph]
    name = ceph
    description = Ceph Test
    driver_name = ceph
    config_path = /etc/opensds/driver/ceph.yaml
    
    [cinder]
    name = cinder
    description = Cinder Test
    driver_name = cinder
    config_path = /etc/opensds/driver/cinder.yaml
    
    [lvm]
    name = lvm
    description = LVM Test
    driver_name = lvm
    config_path = /etc/opensds/driver/lvm.yaml
    
    [database]
    # Enabled database types, such as etcd, mysql, fake, etc.
    driver = etcd
    endpoint = 127.0.0.1:2379,127.0.0.1:2380
    OPENSDS_GLOABL_CONFIG_DOC
   	
    
    mkdir /etc/opensds/driver
    cd $HOME/kubernetes
    cp opensds-installer/ansible/group_vars/ceph/ceph.yaml /etc/opensds/driver/
    
* OpenSDS and csiplugin helm charts deployment:

  Tiller  Permission:

    Tiller is the in-cluster server component of Helm. By default, helm init installs the Tiller pod into the kube-system namespace, and configures Tiller to use the default service account.
    ```
    kubectl create clusterrolebinding tiller-cluster-admin \
        --clusterrole=cluster-admin \
        --serviceaccount=kube-system:default
    ```
    Install opensds and csiplugin chart:
    ```
    cd $HOME/kubernetes/opensds-installer/charts
    # OpenSDS chart installation
    helm install opensds/ --name={ service_name } --namespace={ kubernetes_namespace }
    
    # Before installing csiplugin chart modify opensdsendpoint to your host_ip in values.yaml file.
    helm install csiplugin/ --name={ service_name } --namespace={ kubernetes_namespace }
    
    ```
        
	    

## Testing steps ##

* Create a persistentVolume i.e sample.yaml

	```
	kubectl create -f sample.yaml	
	```
	sample.yaml
	```
	kind: PersistentVolume
    apiVersion: v1
    metadata:
      name: csi-pvc-opensdsplugin
      labels:
        type: local
    spec:
      storageClassName: csi-sc-opensdsplugin
      capacity:
        storage: 5Gi
      accessModes:
        - ReadWriteOnce
      hostPath:
        path: "/mnt/data"

* Create example nginx application

	```
	kubectl create -f nginx.yaml
	```
	nginx.yaml
	```apiVersion: storage.k8s.io/v1
       kind: StorageClass
       metadata:
         name: csi-sc-opensdsplugin
       provisioner: csi-opensdsplugin
       parameters:
       
       ---
       apiVersion: v1
       kind: PersistentVolumeClaim
       metadata:
         name: csi-pvc-opensdsplugin
       spec:
         accessModes:
         - ReadWriteOnce
         resources:
           requests:
             storage: 1Gi
         storageClassName: csi-sc-opensdsplugin
       ---
       apiVersion: v1
       kind: Pod
       metadata:
         name: nginx
       spec:
         containers:
         - image: nginx
           imagePullPolicy: IfNotPresent
           name: nginx
           ports:
           - containerPort: 80
             protocol: TCP
           volumeMounts:
             - mountPath: /var/lib/www/html
               name: csi-data-opensdsplugin
         volumes:
         - name: csi-data-opensdsplugin
           persistentVolumeClaim:
             claimName: csi-pvc-opensdsplugin
             readOnly: false
	```
	To verify check whether the nginx pod is running or not.
	```
	kubectl get pods --all-namespaces
