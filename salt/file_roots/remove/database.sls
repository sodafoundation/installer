## opensds-installer/salt/srv/salt/remove/database.sls
base:
  '*':
    - opensds.database.clean
