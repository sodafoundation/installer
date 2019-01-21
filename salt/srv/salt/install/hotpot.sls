## opensds-installer/salt/srv/salt/install/hotpot.sls
base:
  '*':
    - opensds.hotpot.clean
    - opensds.hotpot
