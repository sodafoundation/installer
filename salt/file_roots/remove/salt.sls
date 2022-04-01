## soda-installer/salt/srv/salt/salt.sls
base:
  '*':
    {{ '- salt.pkgrepo' if grains.os_family|lower not in ('suse', 'freebsd') else '' }}   #Is suse fixed yet?
    - salt.minion
    - salt.master
    # salt.standalone
    - salt.formulas
    - salt.ssh
