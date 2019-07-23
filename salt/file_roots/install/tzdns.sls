## opensds-installer/salt/srv/salt/installer/tzdns.sls
base:
  '*':
    - timezone
    - resolver.ng
