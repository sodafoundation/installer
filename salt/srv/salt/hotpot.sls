## opensds-installer/srv/salt/salt/hotpot.sls
base:
  '*':
    - opensds.hotpot.clean
    - opensds.hotpot
