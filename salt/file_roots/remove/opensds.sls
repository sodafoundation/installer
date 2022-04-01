## soda-installer/salt/srv/salt/remove/top.sls
base:
  '*':
    - salt.formulas
    - soda.cleaner
