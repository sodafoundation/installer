## opensds-installer/srv/salt/tzdns.sls
base:
  '*':
    - timezone
    - resolver.ng
