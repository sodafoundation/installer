## opensds-installer/srv/salt/salt/infra.sls
base:
  '*':
    - opensds.infra.clean
    - opensds.infra
