## opensds-installer/srv/salt/salt/let.sls
base:
  '*':
    - opensds.let.clean
    - opensds.let
