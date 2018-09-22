## opensds-installer/srv/salt/salt/controller.sls
base:
  '*':
    - opensds.controller.clean
    - opensds.controller
