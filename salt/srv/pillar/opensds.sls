{% from "site.j2" import sitedata as site %}

timezone:
  name: {{ site.timezone or 'America/Denver' }}
  utc: True

resolver:
  ng:
    resolvconf:
      enabled: False
  domain: {{ site.ipdomain or 'example.com' }}
  nameservers:
    - {{ site.dns_host1 or '8.8.8.8' }}
    - {{ site.dns_host2 or '64.6.64.6' }}
  #searchpaths:
  #- {{ site.ipdomain or 'example.com' }}
  options:
    - rotate
    - timeout:1
    - attempts:5

nginx:
  ng:
    servers:
      managed:
        default:
          enabled: True
          overwrite: True
          config:
            - server:
              - root:
                - /var/www/html
              - server_name: '_'
              - listen:
                - 8088
                - default_server
              - listen:
                - '[::]:8088'
                - default_server
              - index:
                - index.html
                - index.htm
          {%- if grains.os_family == 'Debian' %}
                - index.nginx-debian.html
          {%- endif %}
              - location /{{ site.hotpot_release }}/:
                - proxy_pass: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_controller }}/{{ site.hotpot_release }}'
              - location /v3/:
                - proxy_pass: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}/identity/v3/'
              - location /v1beta/:
                - proxy_pass: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_controller }}/{{ site.hotpot_release }}/'

memcached:
  daemonize: True
  listen_address: {{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}

golang:
  prefix: /usr/local
  go_root: /usr/local/golang
  go_path: /usr/local/go

### Note: we use devstack to deploy mysql not mysql-formula ###
mysql:
  # mysql password needs to match devstack 'DATABASE_PASSWORD' !!!!!!!!! Important !!!!
  server:
    root_password: {{ site.devstack_password }}
    mysqld:
      bind_address: {{ site.db_host or site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}

etcd:
  service:
    etcd_endpoints: '{{ site.db_host or site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }},{{ site.db_host or site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}:2380'
  dir:
    tmp: /tmp/etcd_tmp
  docker:
    image: {{ site.img_etcd }}
    version: {{ site.ver_etcd }}
    container_name: osdsdb
    enabled: True
    skip_translate: None
    ports:
      - 2379
      - 2380
      - 2379/udp
      - 2380/udp
    port_bindings:
      - '0.0.0.0:2379:2379'
      - '0.0.0.0:2380:2380'
    binds:
      - /usr/share/ca-certificates/:/etc/ssl/certs
    stop_local_etcd_service_first: True

opensds:
  host: {{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}
  ports:
    opensds: {{ site.port_controller }}
    dock: {{ site.port_dock }}
  release:
    hotpot: {{ site.hotpot_release }}
    sushi: {{ site.sushi_release }}
  hashsum:
    hotpot: '{{ site.hotpot_hashsum }}'
    sushi: '{{ site.sushi_hashsum }}'
  dir:
    devstack: {{ site.devstack_dir }}
  driver:
    pool:
      {{ site.poolname }}:
        extras:
          advanced:
            a: 'b'

  auth:
    opensdsconf:
      keystone_authtoken:
        memcached_servers: {{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1'  }}:11211
        auth_uri: http://{{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}/identity
        auth_url: http://{{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}/identity
        username: opensds
        password: {{ site.devstack_password }}

  database:
    container:
      enabled: True
      build: True
      ports:
        - 2379
        - 2379/udp
        - 2380
        - 2380/udp
      port_bindings:
        - '0.0.0.0:2379:2379'
        - '0.0.0.0:2380:2380'
    opensdsconf:
      database:
        endpoint: https://{{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}:2379,https://{{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}:2380
        credential: 'opensds:{{ site.devstack_password }}@{{ site.host_ipv4 or site.host_ipv6 or 127.0.0.1 }}:3306/dbname'

  let:
    container:
      enabled: True
      image: {{ site.img_controller }}
      version: {{ site.ver_controller }}
      ports:
        - {{ site.port_controller }}
        - {{ site.port_controller }}/udp
      port_bindings:
        - '0.0.0.0:{{ site.port_controller }}:{{ site.port_controller }}'

    opensdsconf:
      osdslet:
        api_endpoint: {{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}:{{ site.port_controller }}
        auth_strategy: noauth
        graceful: True

  controller:
    endpoint: {{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}:{{ site.port_controller }}
    container:
      enabled: False
      image: {{ site.img_controller }}
      version: {{ site.ver_controller }}
      ports:
        - {{ site.port_controller }}
        - {{ site.port_controller }}/udp
      port_bindings:
        - {{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}:{{ site.port_controller }}:{{ site.port_controller }}

  dashboard:
    provider: repo       #or release
    container:
      image: {{ site.img_dashboard }}
      version: {{ site.ver_dashboard }}

  nbp:
    provider: release  #or repo
    plugin_type: {{ site.dock_type }}
    plugins:
      csi:
        dir: /opt/opensds-sushi-linux-amd64/csi/deploy/kubernetes
        conf: csi-k8s_configmap-opensdsplugin.yaml
      provisioner:
        dir: /opt/opensds-sushi-linux-amd64/provisioner/deploy/kubernetes
        conf: configmap.yaml
      flexvolume:
        dir: /usr/libexec/kubernetes/kubelet-plugins/volume/exec/opensds.io~opensds
        binary: /opt/opensds-sushi-linux-amd64/bin/flexvolume.server.opensds

  dock:
    container:
      image: {{ site.img_dock }}
      version: {{ site.ver_dock }}
      volumes:
        - /etc/opensds/:/etc/opensds
      ports:
        - {{ site.port_dock }}
        - {{ site.port_dock }}/udp
      port_bindings:
        - '0.0.0.0:{{ site.port_dock }}:{{ site.port_dock }}'
    opensdsconf:
      osdsdock:
        api_endpoint: localhost:{{ site.port_dock }}
        dock_type: {{ site.dock_type }}
        enabled_backend: {{ site.enabled_backend }}

    block:
      provider: {{ site.enabled_backend }}
      opensdsconf:
        {{ site.enabled_backend }}:
          {{ site.enabled_backend }}_name: {{ site.enabled_backend }} backend!
          {{ site.enabled_backend }}_description: {{ site.enabled_backend }} backend service!
          {{ site.enabled_backend }}_driver_name: {{ site.enabled_backend }}!
          {{ site.enabled_backend }}_config_path: /etc/opensds/driver/{{site.enabled_backend}}.yaml
      cinder:
        container:
          enabled: True

lvm:
  files:
    loopbackdir: /tmp/opensds_loopdevs    #Where to create backing files
    remove:
      - /tmp/opensds_loopdevs/cinder-volumes.img
      - /tmp/opensds_loopdevs/opensds-volumes.img
    create:
      truncate:    #Shrink or extend the size of each FILE to the specified size
        /tmp/opensds_loopdevs/cinder-volumes.img:
          options:
            size: 100M
      dd:     #copy a file, converting and formatting according to the operands
        /tmp/opensds_loopdevs/opensds-volumes.img:
          options:
            if: /dev/urandom
            bs: 1024
            count: 20480
      losetup:          #set up and control loop devices
        /tmp/opensds_loopdevs/cinder-volumes.img:
          options:
            show: True
            find: True
        /tmp/opensds_loopdevs/opensds-volumes.img:
  pv:
    create:
      /dev/loop0:
      /dev/loop1:
    remove:
      /dev/loop0:
      /dev/loop1:
  vg:
    remove:
      cinder_volumes:
      opensds_volumes:
    create:
      cinder_volumes:
        devices:
          - /dev/loop0
      opensds_volumes:
        devices:
          - /dev/loop1

firewalld:
  services:
    opensds:
      ports:
        tcp:
          - {{ site.port_controller }}
          - {{ site.port_dock }}

devstack:
  local:
    password: {{ site.devstack_password }}
    enabled_services: {{ site.devstack_enabled_services }}
    os_password: {{ site.devstack_password }}
    host_ip: {{ site.host_ipv4 }}
    host_ipv6: {{ site.host_ipv6 or '127.0.0.1' }}
    service_host: {{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}
    db_host: {{ site.db_host }}
  dir:
    dest: {{ site.devstack_dir }}
    tmp: /tmp/devstack
  cli:
    service:
      create:
        opensds{{ site.hotpot_release }}:
          options:
            name: opensds{{ site.hotpot_release }}
            description: "opensds Service"
            enable: True
    user:
      create:
        opensds{{ site.hotpot_release }}:
          options:
            domain: default
            password: {{ site.devstack_password }}
            project: service
            enable: True
    group:
      create:
        service:
          options:
            domain: default
      add user:
        service:
          target:
            - opensds{{ site.hotpot_release }}
        admins:
          options:
            domain: default
          target:
            - admin
    role:
      add:
        admin:
          options:
            project: service
            user: opensds{{ site.hotpot_release }}
        service:
          options:
            project: service
            group: service
    endpoint:
      create:
        'opensds{{site.hotpot_release}} public https://{{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}/{{ site.port_controller }}/{{ site.hotpot_release }}/%\(tenant_id\)s':
          options:
            region: RegionOne
            enable: True
        'opensds{{site.hotpot_release}} internal https://{{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}/{{ site.port_controller }}/{{ site.hotpot_release }}/%\(tenant_id\)s':
          options:
            region: RegionOne
            enable: True
        'opensds{{site.hotpot_release}} admin https://{{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}/{{ site.port_controller }}/{{ site.hotpot_release }}/%\(tenant_id\)s':
          options:
            region: RegionOne
            enable: True

docker:
  # Global functions for all docker_container states
  install_docker_py: True
  containers:
    skip_translate: ports
    force_present: False
    force_running: False   #maybe unsupported by python-py

packages:
  pips:
    wanted:
      - tox
      - click
  pkgs:
    unwanted:
      - unattended-upgrades
     {%- if grains.os_family in ('RedHat',) %}
       #because of https://github.com/saltstack-formulas/mysql-formula/issues/195
      - mariadb
      - mariadb-tokudb-engine
      - mariadb-config
      - mariadb-libs
      - mariadb-rocksdb-engine
      - mariadb-common
      - mariadb-cracklib-password-check
      - mariadb-gssapi-server
      - mariadb-devel
      - mariadb-server-utils
      - mariadb-server
      - mariadb-backup
      - mariadb-errmsg
     {%- elif grains.os == "Ubuntu" %}
      - libmysqlclient-dev
      - libmysqlclient20
      - mysql-client-5.7
      - mysql-client-core-5.7
      - mysql-common
      - mysql-server
      - mysql-server-5.7
      - mysql-server-core-5.7
     {%- endif %}
  archives:
    wanted:
      kubectl:
        dest: /usr/local/bin
        dl:
          format: bin
          source: {{ site.kubectl_url }}
          hashsum: {{ site.kubectl_hashsum }}
      opensds-hotpot:
        dest: /opt/opensds-linux-amd64
        options: '--strip-components=1'
        dl:
          format: tar
          source: {{ site.hotpot_uri }}/{{ site.hotpot_release }}/opensds-hotpot-{{ site.hotpot_release }}-linux-amd64.tar.gz
          hashsum: {{ site.hotpot_hashsum }}
      opensds-sushi:
        dest: /usr/local/go/bin/src/github.com/opensds/nbp
        options: '--strip-components=1'
        dl:
          format: tar
          source: {{ site.sushi_uri }}/{{ site.sushi_release }}/opensds-sushi-{{ site.sushi_release }}-linux-amd64.tar.gz
          hashsum: {{ site.sushi_hashsum }}
      cinder:
        dest: /opt/opensds-k8s-linux-amd64/cinder
        dl:
          format: yml
          source: {{ site.cinder_url }}
          hashsum: {{ site.cinder_hashsum }}
    unwanted:
      - /usr/local/go/bin/src/github.com/opensds/nbp
      - /opt/opensds-k8s-linux-amd64
      - /opt/opensds-linux-amd64
      # /var/lib/mysql/

salt:
  install_packages: False
  master:
    file_roots:
      base:
        - /srv/salt
    pillar_roots:
      base:
        - /srv/pillar
  minion:
    file_roots:
      base:
        - /srv/salt
    pillar_roots:
      base:
        - /srv/pillar
  ssh_roster:
    controller1:
      host: {{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}
      user: stack
      sudo: True
      priv: /etc/salt/ssh_keys/sshkey.pem
salt_formulas:
  git_opts:
    default:
      baseurl: https://github.com/saltstack-formulas
      basedir: /srv/formulas
  basedir_opts:
    makedirs: True
    user: root
    group: root
    mode: 755
  minion_conf:
    create_from_list: True
  list:
    base:
     {{ '- epel-formula' if grains.os_family in ('RedHat',) else '' }}
     - salt-formula
     - openssh-formula
     - packages-formula
     - firewalld-formula
     - etcd-formula
     - ceph-formula
     - deepsea-formula
     - docker-formula
     - etcd-formula
     - firewalld-formula
     - helm-formula
     - iscsi-formula
     - lvm-formula
     - packages-formula
     - devstack-formula
     - golang-formula
     - memcached-formula
     - opensds-formula
     - mysql-formula
     - timezone-formula
     - resolver-formula
     - nginx-formula
     - apache-formula
     - mongodb-formula
