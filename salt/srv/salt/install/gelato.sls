## opensds-installer/salt/srv/salt/install/let.sls
base:
  '*':
    - opensds.gelato.clean
    - opensds.gelato
