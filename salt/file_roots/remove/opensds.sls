## opensds-installer/salt/srv/salt/remove/top.sls
base:
  '*':
    - salt.formulas
    - opensds.cleaner
