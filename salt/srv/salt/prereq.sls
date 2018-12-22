## opensds-installer/srv/salt/prereq.sls
base:
  '*':
    - docker.remove
    - docker
    - apache.uninstall
    - nginx.ng
