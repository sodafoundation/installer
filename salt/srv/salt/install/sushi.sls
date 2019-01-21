## opensds-installer/salt/srv/salt/install/sushi.sls
base:
  '*':
    - opensds.sushi.clean
    - opensds.sushi
