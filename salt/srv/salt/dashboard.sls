## opensds-installer/srv/salt/salt/dashboard.sls
base:
  '*':
    - opensds.dashboard.clean
    - opensds.dashboard
