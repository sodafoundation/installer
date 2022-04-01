{% from "site.j2" import sitedata as site %}

salt:
  # Set this to 'py3' to install the Python 3 packages.
  # If this is not set, the Python 2 packages will be installed by default.
  py_ver: 'py3'

  install_packages: False
  master:
    file_roots:
      base:
            {%- if grains['kernel'] in ['FreeBSD', 'OpenBSD', 'NetBSD'] %}
        - /usr/local/etc/salt/states
            {%- else %}
        - /srv/salt
            {%- endif %}
    pillar_roots:
      base:
        - /srv/pillar
  minion:
    file_roots:
      base:
            {%- if grains['kernel'] in ['FreeBSD', 'OpenBSD', 'NetBSD'] %}
        - /usr/local/etc/salt/states
            {%- else %}
        - /srv/salt
            {%- endif %}
    pillar_roots:
      base:
        - /srv/pillar
  ssh_roster:
    controller1:
      host: {{ site.host_ipv4 or site.host_ipv6 }}
      user: stack
      sudo: True
      priv: /etc/salt/ssh_keys/sshkey.pem
salt_formulas:
  git_opts:
    default:
      baseurl: https://github.com/saltstack-formulas
         {%- if grains['kernel'] in ['FreeBSD', 'OpenBSD', 'NetBSD'] %}
      basedir: /usr/local/etc/salt/states/namespaces/saltstack-formulas
         {%- else %}
      basedir: /srv/salt/namespaces/saltstack-formulas
         {%- endif %}
  basedir_opts:
    makedirs: True
    user: root
      {%- if grains['kernel'] in ['FreeBSD', 'OpenBSD', 'NetBSD'] %}
    group: wheel
      {%- else %}
    group: root
      {%- endif %}
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
     - soda-formula
     - mysql-formula
     - timezone-formula
     - resolver-formula
     - nginx-formula
     - mongodb-formula
     - apache-formula
     - prometheus-formula
     - grafana-formula
     - sysstat-formula
