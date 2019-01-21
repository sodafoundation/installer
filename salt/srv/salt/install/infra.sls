## opensds-installer/salt/srv/salt/install/infra.sls
base:
  '*':
    - opensds.infra.clean
    - opensds.infra
