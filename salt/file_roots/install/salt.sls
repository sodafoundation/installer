base:
  '*':
    - salt.pkgrepo
    - salt.minion
       {%- if grains.os_family|lower not in ('suse', 'freebsd', 'macos') %}   # is suse fixed yet?
    - salt.master
    - salt.ssh
    - salt.formulas
       {%- endif %}
