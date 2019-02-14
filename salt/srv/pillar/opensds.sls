{% from "site.j2" import sitedata as site %}

opensds:
  deploy_project: {{ site.deploy_project }}
  host: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}
  ports:
    opensds: {{ site.port_hotpot }}
    dock: {{ site.port_dock }}
  dir:
    go: {{ site.go_path }}/src/github.com/opensds
  environ:
    opensds_endpoint: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_hotpot }}
    opensds_auth_strategy: {{ site.auth_strategy }}
    csi_endpoint: {{ site.host_ipv4 or site.host_ipv6 or '127.0.0.1' }}:{{ site.port_csi }}

  ######### BACKENDS ##################
  backend:
    block:
      ids: {{ site.enabled_backends }}
      container:
        cinder:
          image: {{ site.container_cinder_img }}
          version: {{ site.cinder_version }}
          custom:
            dbports: '3307:3306'
      daemon:
        cinder:
          strategy: repo-compose-config-build-systemd
          repo:
            branch: {{ site.cinder_version }}
        lvm:
          strategy: saltstack-formulas/lvm-formula

  ######## BACKEND DRIVERS ###########
    drivers:
      cinder:
        pool:
          {{ site.cinder_poolname }}:
            extras:
              advanced:
                custom_feature_g: 'h'
        authOptions:
          endpoint: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}/identity'
          cinderEndpoint: 'http:{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:8776/v2'
          domainId: {{ site.project_domain_name }}
          projectName: {{ site.project_name }}
          domainName: {{ site.user_domain_name }}
          username: {{ site.hotpot_service }}
          password: {{ site.devstack_password }}
          tenantName: {{ site.hotpot_service }}

      lvm:
        tgtBindIp: {{ site.tgtBindIp }}
        pool:
          {{ site.lvm_poolname }}:
            extras:
              advanced:
                custom_feature_a: 'b'
      ceph:
        pool:
          {{ site.ceph_poolname }}:
            extras:
              advanced:
                custom_feature_c: 'd'

      fusionstorage:
        authOptions:
          fmIp: {{ site.fusionstorage_fmip }}
          fsaIp: {{ site.fusionstorage_fsaip }}
        pool:
          {{ site.fusionstorage_poolname }}:
            extras:
              advanced:
                custom_feature_e: 'f'

      dorado:
        pool:
          {{ site.dorado_poolname }}:
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
    opensdsconf:
      osdsdock:
        api_endpoint: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_dock }}
        dock_type: {{ site.dock_type }}
        enabled_backends: {{ site.enabled_backends }}
    container:
      osdsdock:
        image: {{ site.container_dock_img }}
        version: {{ site.dock_version }}
        ports:
          - {{ site.port_dock }}
          - {{ site.port_dock }}/udp
        port_bindings:
          - '{{ site.port_dock }}:{{ site.port_dock }}'
    daemon:
      opensds:
        strategy: binaries
      osdsdock:
        strategy: config-systemd

  ############ OPENSDS GELATO #############
  gelato:
    release: {{ site.gelato_release }}
    service: {{ site.gelato_service }}
    ids:
      - {{ site.gelato_service }}
    opensdsconf:
      {{ site.gelato_service }}:
        endpoint: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"  }}
        port: {{ site.port_gelato }}
    container:
      {{ site.gelato_service }}:
    daemon:
      {{ site.gelato_service }}:
        strategy: keystone-repo-config-compose-build-systemd
        repo:
          branch: {{ site.gelato_release }}


  ############ OPENSDS AUTH #############
  auth:
    ids:
      - osdsauth
      - keystone_authtoken
    opensdsconf:
      keystone_authtoken:
        memcached_servers: '{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"  }}:11211'
        auth_uri: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}/identity'
        auth_url: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}/identity'
        username: {{ site.hotpot_service }}
        password: {{ site.devstack_password }}
        auth_type: password
        project_domain_name: {{ site.project_domain_name }}
        project_name: {{ site.project_name }}
        user_domain_name: {{ site.user_domain_name }}
    daemon:
      osdsauth:
        strategy: config-keystone   ##verified on Ubuntu opensds-installer/salt
        endpoint_ipv4: http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}
        endpoint_port: {{ site.port_hotpot }}

  ############ OPENSDS DATABASE #############
  database:
    ids:
      - database
      - etcd
    opensdsconf:
      database:
        endpoint: '{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_auth1 }},http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_auth2 }}'
        credential: '{{ site.hotpot_service }}:{{ site.devstack_password }}@{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}:{{ site.port_mysql }}/dbname'
    daemon:
      database:
        strategy: config-etcd-formula/container


  ############### OPENSDS HOTPOT ################
  hotpot:
    release: {{ site.hotpot_release }}
    service: {{ site.hotpot_service }}
    opensdsconf:
      osdslet:
        api_endpoint: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}:{{ site.port_hotpot }}
        auth_strategy: {{ site.auth_strategy }}   ### note: noauth verified on ubuntu salt installer
    container:
      opensds:
        image: {{ site.container_hotpot_img }}
        version: {{ site.hotpot_version }}
        ports:
          - {{ site.port_hotpot }}
          - {{ site.port_hotpot }}/udp
        port_bindings:
          - {{site.host_ipv4 or site.host_ipv6 or '127.0.0.1'}}:{{site.port_hotpot}}:{{site.port_hotpot}}
    daemon:
      opensds:
        strategy: repo-config-build-binaries-systemd
        endpoint_ipv4: http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}
        endpoint_port: {{ site.port_hotpot }}

  ############### OPENSDS DASHBOARD(S) ################
  dashboard:
    opensdsconf:
      dashboard:
        endpoint: http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}
        port: {{ site.port_hotpot }}
    container:
      dashboard:
         image: {{ site.container_dashboard_img }}
         version: {{ site.dashboard_version }}
         env:
           OPENSDS_HOST_IP: {{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}
    daemon:
      dashboard:
        strategy: config-container
        repo:
          branch: {{ site.dashboard_version }}

  ############### OPENSDS SUSHI NORTH-BOUND-PLUGINS ################
  sushi:
    release: {{ site.sushi_release }}
    plugin_type: {{ site.dock_type }}
    daemon:
      nbp:
        strategy: repo-config-systemd
        repo:
          branch: {{ site.sushi_release }}


################################
## upstream formula pillar data
################################

lvm:
  files:
    loopbackdir: {{ site.hotpot_path }}/volumegroups    #Where to create backing files
    remove:
      - {{ site.hotpot_path }}/volumegroups/{{ site.cinder_poolname }}.img
      - {{ site.hotpot_path }}/volumegroups/{{ site.ceph_poolname }}.img
      - {{ site.hotpot_path }}/volumegroups/{{ site.lvm_poolname }}.img
      - {{ site.hotpot_path }}/volumegroups/{{ site.fusionstorage_poolname }}.img
      - {{ site.hotpot_path }}/volumegroups/{{ site.dorado_poolname }}.img
    create:
      ### dd: copy a file, converting and formatting according to the operands
      dd:
        {{ site.hotpot_path }}/volumegroups/{{ site.lvm_poolname }}.img:
          options:
            if: /dev/urandom
            bs: 1024
            count: 204800

      ### or truncate: Shrink or extend the size of each FILE to the specified size
      truncate:
        {{ site.hotpot_path }}/volumegroups/{{ site.cinder_poolname }}.img:
          options:
            size: 100M
      'truncate ':
        {{ site.hotpot_path }}/volumegroups/{{ site.ceph_poolname }}.img:
          options:
            size: 10M
      'truncate  ':
        {{ site.hotpot_path }}/volumegroups/{{ site.dorado_poolname }}.img:
          options:
            size: 10M
      'truncate   ':
        {{ site.hotpot_path }}/volumegroups/{{ site.fusionstorage_poolname }}.img:
          options:
            size: 10M

      ### setup backing devices
      losetup:
        {{ site.hotpot_path }}/volumegroups/{{ site.lvm_poolname }}.img:
          options:
            show: True
            find: True
        {{ site.hotpot_path }}/volumegroups/{{ site.cinder_poolname }}.img:
          options:
            show: True
            find: True
  pv:
    create:
      /dev/loop0:
      /dev/loop1:
    remove:
      /dev/loop0:
      /dev/loop1:
  vg:
    remove:
      cinder-volumes:
      opensds-volumes:
    create:
      cinder-volumes:
        devices:
          - /dev/loop0
      opensds-volumes:
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
    os_project_name: {{ site.project_name }}
    os_username: {{ site.hotpot_service }}
    os_password: {{ site.devstack_password }}
    admin_password: {{ site.devstack_password }}
    #git_branch: 'stable/rocky'
    enabled_services: {{ site.devstack_enabled_services }}
    host_ipv4: {{ site.host_ipv4 or "127.0.0.1" }}
    host_ipv6: {{ site.host_ipv6 or '::1/128' }}
    service_host: {{ site.host_ipv4 or "127.0.0.1" }}
    db_host: {{ site.db_host or "127.0.0.1" }}
  dir:
    dest: {{ site.devstack_path }}
  cli:
    service:
      create:
        {{ site.hotpot_service }}{{ site.hotpot_release }}:
          options:
            name: {{ site.hotpot_service }}{{ site.hotpot_release }}
            description: "{{ site.hotpot_service }} Service"
            enable: True
        {{ site.gelato_service }}{{ site.gelato_release }}:
          options:
            name: "{{ site.gelato_service }}{{ site.gelato_release }}"
            description: "{{ site.gelato_service }} service"
            enable: True
    user:
      create:
        {{ site.hotpot_service }}{{ site.hotpot_release }}:
          options:
            domain: {{ site.user_domain_name }}
            password: {{ site.devstack_password }}
            project: {{ site.project_name }}
            enable: True
        {{ site.gelato_service }}{{ site.gelato_release }}:
          options:
            domain: {{ site.user_domain_name }}
            password: {{ site.devstack_password }}
            project: {{ site.project_name }}
            enable: True
    group:
      create:
        {{ site.project_name }}:
          options:
            domain: {{ site.user_domain_name }}
      add user:
        {{ site.project_name }}:
          target:
            - {{ site.hotpot_service }}{{ site.hotpot_release }}
            - {{ site.gelato_service }}{{ site.gelato_release }}
        admins:
          options:
            domain: {{ site.user_domain_name }}
          target:
            - admin
    role:
      add:
        admin:
          options:
            project: {{ site.project_name }}
          user:
            - opensds{{ site.hotpot_release }}
            - {{ site.gelato_service }}{{ site.gelato_release }}
        {{ site.project_name }}:
          options:
            project: {{ site.project_name }}
          group:
            - {{ site.project_name }}
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
    initial_advertise_peer_urls: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1"}}:{{site.port_auth2}}'
    listen_peer_urls: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_auth2 }}'
    listen_client_urls: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_auth1 }}'
    advertise_client_urls: 'http://{{ site.host_ipv4 or site.host_ipv6 or "127.0.0.1" }}:{{ site.port_auth1 }}'
    #cmd_args: '--auto-tls --peer-auto-tls'
    cmd_args: ''
  docker:
    enabled: True
    image: {{ site.container_etcd_img }}
    version: {{ site.etcd_version }}
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
    wanted: []  ## populated by opensds-formula in map.jinja
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

      {{ site.gelato_service }}:
        dest: {{ site.gelato_path }}/{{ site.gelato_service }}
        options: '--strip-components=1'
        dl:
          format: tar
          source: {{ site.gelato_uri }}/{{ site.gelato_release }}/opensds-multicloud-{{ site.gelato_release }}-linux-amd64.tar.gz
          hashsum: {{ site.gelato_hashsum }}

      hotpot:
        dest: {{ site.hotpot_path }}/opensds
        options: '--strip-components=1'
        dl:
          format: tar
          source: {{ site.hotpot_uri }}/{{ site.hotpot_release }}/opensds-hotpot-{{ site.hotpot_release }}-linux-amd64.tar.gz
          hashsum: {{ site.hotpot_hashsum }}

      nbp:
        dest: {{ site.sushi_path }}/nbp
        options: '--strip-components=1'
        dl:
          format: tar
          source: {{ site.sushi_uri }}/{{ site.sushi_release }}/opensds-sushi-{{ site.sushi_release }}-linux-amd64.tar.gz
          hashsum: {{ site.sushi_hashsum }}

      cinder:
        dest: {{ site.sushi_path }}/cinder
        options: '--strip-components=1'
        dl:
          format: tar
          source: {{ site.cinder_url }}
          hashsum: {{ site.cinder_hashsum }}
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
