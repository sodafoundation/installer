base:
  '*':
              {%- if grains.os_family| lower not in ('macos',) %}
    {{'- salt.pkgrepo' if grains.os_family|lower not in ('suse', 'freebsd', 'macos') else '' }}    #Is suse fixed yet?
    - salt.minion
    - salt.master
    - salt.ssh
    - salt.formulas
              {%- endif %}
