## soda-installer/salt/srv/salt/remove/database.sls
base:
  '*':
    - soda.database.clean
