## opensds-installer/srv/salt/salt/database.sls
base:
  '*':
    - opensds.database.clean
    - opensds.database
