## opensds-installer/salt/srv/salt/remove/auth.sls
base:
  '*':
    - opensds.auth.clean
