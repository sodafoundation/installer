## opensds-installer/salt/srv/salt/install/dashboard.sls
base:
  '*':
    - opensds.dashboard.clean
    - opensds.dashboard
