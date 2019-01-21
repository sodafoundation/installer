## opensds-installer/salt/srv/salt/install/dock.sls
base:
  '*':
    - opensds.dock.clean
    - opensds.dock
