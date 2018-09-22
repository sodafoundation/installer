## opensds-installer/srv/salt/salt/envs.sls
base:
  '*':
    - opensds.envs.clean
    - opensds.envs
