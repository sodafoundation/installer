## opensds-installer/salt/srv/salt/install/prereq.sls
base:
  '*':
    - docker.remove
    - docker
    # apache.uninstall
    - nginx.ng
