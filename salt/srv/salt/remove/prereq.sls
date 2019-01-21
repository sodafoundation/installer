## opensds-installer/salt/srv/salt/remove/prereq.sls
base:
  '*':
    - docker.remove
    - apache.uninstall
    # nginx.ng.uninstall
