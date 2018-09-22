## opensds-installer/srv/salt/salt/auth.sls
base:
  '*':
    - opensds.auth.clean
    - opensds.auth
