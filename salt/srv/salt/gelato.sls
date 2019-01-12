## opensds-installer/srv/salt/salt/let.sls
base:
  '*':
    - opensds.gelato.clean
    - opensds.gelato
