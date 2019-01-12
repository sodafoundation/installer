## opensds-installer/srv/salt/salt/sushi.sls
base:
  '*':
    - opensds.sushi.clean
    - opensds.sushi
