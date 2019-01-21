## opensds-installer/salt/srv/salt/install/auth.sls
base:
  '*':
    - opensds.auth.clean
    - opensds.auth
