{% from "site.j2" import sitedata as site %}

opensds:
  deploy_project: {{ site.deploy_project }}
  host: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}
  ports:
    opensds: {{ site.port_hotpot }}
    dock: {{ site.port_dock }}

  ######### BACKENDS ##################
  backend:
    block:
      instances: {{ site.enabled_backends }}
      container:
        cinder:
          enabled: True

  ######## BACKEND DRIVERS ###########
    drivers:
      lvm:
        tgtBindIp: {{ site.tgtBindIp }}
        pool:
          {{ site.poolname }}:
            extras:
              advanced:
                custom_feature_a: 'b'
      ceph:
        pool:
          {{ site.poolname }}:
            extras:
              advanced:
                custom_feature_c: 'd'

      fusionstorage:
        authOptions:
          fmIp: {{ site.fusionstorage_fmip }}
          fsaIp: {{ site.fusionstorage_fsaip }}
        pool:
          {{ site.poolname }}:
            extras:
              advanced:
                custom_feature_e: 'f'
      cinder:
        pool:
          {{ site.poolname }}:
            extras:
              advanced:
                custom_feature_g: 'h'

      drbd:
        Hosts:
          - Hostname: {{ site.drbd_host_0_name }}
            IP: {{ site.drbd_host_0_ipv4 }}
            Node-ID: 0
          - Hostname: {{ site.drbd_host_1_name }}
            IP: {{ site.drbd_host_1_ipv4 }}
            Node-ID: 1


  ########### DOCKS ###############
  dock:
    instances:
      - osdsdock
    opensdsconf:
      osdsdock:
        api_endpoint: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_dock }}
        dock_type: {{ site.dock_type }}
        enabled_backends: {{ site.enabled_backends }}
    container:
      osdsdock:
        image: {{ site.container_dock_img }}
        version: {{ site.container_dock_version }}
        ports:
          - {{ site.port_dock }}
          - {{ site.port_dock }}/udp
        port_bindings:
          - '{{ site.port_dock }}:{{ site.port_dock }}'

  ############ GELATO #############
  gelato:
    release: {{ site.gelato_release }}
    service: {{ site.gelato_service }}
    instances:
      - {{ site.gelato_service }}
    opensdsconf:
      {{ site.gelato_service }}:
        endpoint: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"  }}
        port: {{ site.port_gelato }}
    container:
      {{ site.gelato_service }}:
        enabled: False
        build: False
    daemon:
      {{ site.gelato_service }}:
        strategy: keystone-repo-systemd   ##or keystone-release-systemd, or keystone-compose-systemd
        repo:
          branch: stable/bali


  ############ AUTH #############
  auth:
    instances:
      - osdsauth
      - keystone_authtoken
    opensdsconf:
      keystone_authtoken:
        memcached_servers: '{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"  }}:11211'
        auth_uri: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}/identity'
        auth_url: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}/identity'
        password: {{ site.devstack_password }}
    daemon:
      osdsauth:
        strategy: keystone   #Verified on Ubuntu salt installer
        endpoint_ipv4: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}
        endpoint_port: {{ site.port_hotpot }}

  ############ DATABASE #############
  database:
    instances:
      - database
      - etcd
    container:
      etcd:
        enabled: True
        build: True
    opensdsconf:
      database:
        endpoint: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_auth1 }},http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_auth2 }}'
        credential: 'opensds:{{ site.devstack_password }}@{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}:{{ site.port_mysql }}/dbname'


  ############### HOTPOT ################
  hotpot:
    release: {{ site.hotpot_release }}
    service: {{ site.hotpot_service }}
    instances:
      - opensds
      - osdslet
    opensdsconf:
      osdslet:
        api_endpoint: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}:{{ site.port_hotpot }}
        auth_strategy: noauth  ## verified on ubuntu salt installer
    container:
      opensds:
        enabled: False
        build: False
        image: {{ site.container_hotpot_img }}
        version: {{ site.container_hotpot_version }}
        ports:
          - {{ site.port_hotpot }}
          - {{ site.port_hotpot }}/udp
        port_bindings:
          - {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_hotpot }}:{{ site.port_hotpot }}
    daemon:
      opensds:
        strategy: repo-systemd
        endpoint_ipv4: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}
        endpoint_port: {{ site.port_hotpot }}
        repo:
          branch: stable/bali

  ############### DASHBOARDS ################
  dashboard:
    instances:
      - dashboard
    opensdsconf:
      dashboard:
        endpoint: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}
        port: {{ site.port_hotpot }}
    container:
      dashboard:
         enabled: True
         image: {{ site.container_dashboard_img }}
         version: {{ site.container_dashboard_version }}
    daemon:
      dashboard:
        strategy: container-systemd     #or 'repo-systemd' or 'release-systemd'
        build_cmd: make
        start: {{ site.hotpot_path }}/bin/dashboard
        repo:
          branch: stable/bali


  ############### SUSHI NORTH BOUND PLUGINS ################
  sushi:
    release: {{ site.sushi_release }}
    plugin_type: {{ site.dock_type }}
    instances:
      - nbp
    daemon:
      nbp:
        strategy: repo-systemd
        start: '/usr/local/bin/kubectl create -f {{ site.sushi_path }}/deploy/kubernetes'
        stop: '/usr/local/bin/kubectl delete -f {{ site.sushi_path }}/deploy/kubernetes'
        repo:
          branch: {{ site.sushi_release }}



###################################
## All non OpenSDS values go here 
###################################
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
  enabled: True
  services:
    saltstack:
      short: salt
      description: SaltStack rules
      ports:
        tcp:
          - 4505
          - 4506
    ceph:
      short: ceph
      description: Ceph firewall rules
      ports:
        tcp:
          - 6789
          - 6800:6810
    opensds:
      short: opensds
      description: Open Software Defined Storage
      ports:
        tcp:
          - {{ site.port_hotpot }}
          - {{ site.port_gelato }}
          - {{ site.port_dock }}
          - {{ site.port_mysql }}
          - {{ site.port_auth1 }}
          - {{ site.port_auth2 }}
          - '11211'
  zones:
    public:
      short: Public
      services:
        - http
        - https
        - ssh
        - ntp
        - saltstack
        - ceph
        - opensds

      {%- if grains.os == 'Fedora' %}
    FedoraWorkstation:
      short: FedoraWorkstation
      services:
        - http
        - https
        - ssh
        - ntp
        - saltstack
        - ceph
        - opensds
      {%- endif %}


devstack:
  local:
    username: stack
    password: {{ site.devstack_password }}
    #git_branch: 'stable/rocky'
    enabled_services: {{ site.devstack_enabled_services }}
    os_password: {{ site.devstack_password }}
    host_ipv4: {{ site.host_ipv4 or "127.0.0.1" }}
    host_ipv6: {{ site.host_ipv6 or '::1/128' }}
    service_host: {{ site.host_ipv4 or "127.0.0.1" }}
    db_host: {{ site.db_host or "127.0.0.1" }}
  dir:
    dest: {{ site.devstack_path }}
  cli:
    service:
      create:
        opensds{{ site.hotpot_release }}:
          options:
            name: opensds{{ site.hotpot_release }}
            description: "opensds Service"
            enable: True
        {{ site.gelato_service }}{{ site.gelato_release }}:
          options:
            name: "{{ site.gelato_service }}{{ site.gelato_release }}"
            description: "Multi-cloud Block Storage"
            enable: True
    user:
      create:
        opensds{{ site.hotpot_release }}:
          options:
            domain: default
            password: {{ site.devstack_password }}
            project: service
            enable: True
        {{ site.gelato_service }}{{ site.gelato_release }}:
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
            - {{ site.gelato_service }}{{ site.gelato_release }}
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
          user:
            - opensds{{ site.hotpot_release }}
            - {{ site.gelato_service }}{{ site.gelato_release }}
        service:
          options:
            project: service
          group:
            - service
    endpoint:
      create:
        'opensds{{site.hotpot_release}} public https://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}/{{ site.port_hotpot }}/{{ site.hotpot_release }}/%\(tenant_id\)s':
          options:
            region: RegionOne
            enable: True
        'opensds{{site.hotpot_release}} internal https://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}/{{ site.port_hotpot }}/{{ site.hotpot_release }}/%\(tenant_id\)s':
          options:
            region: RegionOne
            enable: True
        'opensds{{site.hotpot_release}} admin https://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}/{{ site.port_hotpot }}/{{ site.hotpot_release }}/%\(tenant_id\)s':
          options:
            region: RegionOne
            enable: True
        '{{ site.gelato_service }}{{ site.gelato_release }} public https://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}:{{ site.port_gelato }}/{{ site.gelato_release }}/%\(tenant_id\)s':
          options:
            region: RegionOne
            enable: True
        '{{ site.gelato_service }}{{ site.gelato_release }} internal https://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}:{{ site.port_gelato }}/{{ site.gelato_release }}/%\(tenant_id\)s':
          options:
            region: RegionOne
            enable: True
        '{{ site.gelato_service }}{{ site.gelato_release }} admin https://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}:{{ site.port_gelato }}/{{ site.gelato_release }}/%\(tenant_id\)s':
          options:
            region: RegionOne
            enable: True


docker:
  # Global functions for all docker_container states
  install_docker_py: True
  containers:
    skip_translate: ports
    force_present: False
    force_running: False       #maybe unsupported by python-py
    error_on_absent: False
    restart_policy: always
    network_mode: host

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
          {%- if grains.os_family in ('RedHat',) %}
          available_dir: /etc/nginx/sites-available
          {%- endif %}
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
                - proxy_pass: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}:{{ site.port_hotpot }}/{{ site.hotpot_release }}'
              - location /v3/:
                - proxy_pass: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}/identity/v3/'
              - location /v1beta/:
                - proxy_pass: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}:{{ site.port_hotpot }}/{{ site.hotpot_release }}/'

memcached:
  daemonize: True
  listen_address: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}

golang:
  lookup:
    prefix: {{ site.go_prefix }}
    go_root: {{ site.go_root }}           #symlink to 'go_root'/<ver>/go/
    go_path: {{ site.go_path }}
  linux:
    altpriority: {{ range(10000, 50000)| random }}


### Note: we use devstack to deploy mysql not mysql-formula ###
mysql:
  # mysql password needs to match devstack 'DATABASE_PASSWORD' !!!!!!!!! Important !!!!
  server:
    root_password: {{ site.devstack_password }}
    mysqld:
      bind_address: {{ site.db_host or site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}

etcd:
  dir:
    tmp: /tmp/etcd_tmp
  service:
    name: osdsdb
    data_dir: /var/lib/etcd/osdsdb
    initial_cluster: 'osdsdb=http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_auth2 }}'
    initial_cluster_state: new
    initial_cluster_token: osdsdb-1
    initial_advertise_peer_urls: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_auth2 }}'
    listen_peer_urls: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_auth2 }}'
    listen_client_urls: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_auth1 }}'
    advertise_client_urls: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_auth1 }}'
    #cmd_args: '--auto-tls --peer-auto-tls'
    cmd_args: ''
  docker:
    enabled: True
    image: {{ site.container_etcd_img }}
    version: {{ site.container_etcd_version }}
    container_name: osdsdb
    skip_translate: None
    port_bindings:
      - '{{ site.port_auth1 }}:{{ site.port_auth1 }}'
      - '{{ site.port_auth2 }}:{{ site.port_auth2 }}'
    binds:
      - /usr/share/ca-certificates/:/etc/ssl/certs
    stop_local_etcd_service_first: True

ceph:
  use_upstream_repo: true

packages:
  pips:
    wanted:
      - tox
      - click
  pkgs:
    wanted: []  ## map.jinja will populate this from opensds-formula
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
      gelato_compose_file:
        dest: {{ site.gelato_path }}
        dl:
          format: yml
          source: {{ site.gelato_compose_url }}
          hashsum: {{ site.gelato_compose_hashsum }}
      gelato_multi_cloud:
        dest: {{ site.go_path }}/src/github.com/opensds/multi-cloud
        options: '--strip-components=1'
        dl:
          format: tar
          source: {{ site.gelato_uri }}/{{ site.gelato_release }}/opensds-multicloud-{{ site.gelato_release }}-linux-amd64.tar.gz
          hashsum: {{ site.gelato_hashsum }}
      hotpot:
        dest: {{ site.go_path }}/src/github.com/opensds/opensds
        options: '--strip-components=1'
        dl:
          format: tar
          source: {{ site.hotpot_uri }}/{{ site.hotpot_release }}/opensds-hotpot-{{ site.hotpot_release }}-linux-amd64.tar.gz
          hashsum: {{ site.hotpot_hashsum }}
      sushi:
        dest: {{ site.go_path }}/src/github.com/opensds/nbp
        options: '--strip-components=1'
        dl:
          format: tar
          source: {{ site.sushi_uri }}/{{ site.sushi_release }}/opensds-sushi-{{ site.sushi_release }}-linux-amd64.tar.gz
          hashsum: {{ site.sushi_hashsum }}
      cinder_compose:
        dest: {{ site.sushi_path }}/cinder
        dl:
          format: yml
          source: {{ site.cinder_compose_url }}
          hashsum: {{ site.cinder_compose_hashsum }}
    unwanted:
      - {{ site.go_path }}/src/github.com/opensds/nbp
      - {{ site.go_path }}/src/github.com/opensds/opensds
      - {{ site.sushi_path }}
      - {{ site.hotpot_path }}
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
    hotpot1:
      host: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}
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
     - mongodb-formula
     - node-formula
     - apache-formula
