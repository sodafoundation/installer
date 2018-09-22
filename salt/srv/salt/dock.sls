## opensds-installer/srv/salt/salt/dock.sls
base:
  '*':
    - opensds.dock.clean
    - opensds.dock
