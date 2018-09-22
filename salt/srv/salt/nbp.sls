## opensds-installer/srv/salt/salt/nbp.sls
base:
  '*':
    - opensds.nbp.clean
    - opensds.nbp
