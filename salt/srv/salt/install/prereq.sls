## opensds-installer/salt/srv/salt/install/prereq.sls
base:
  '*':
    - docker
    - apache.uninstall
    - nginx.ng
