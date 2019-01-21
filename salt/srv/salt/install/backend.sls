## opensds-installer/salt/srv/salt/install/backend.sls
base:
  '*':
    - opensds.backend.clean
    - opensds.backend
