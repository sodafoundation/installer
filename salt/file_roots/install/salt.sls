base:
  '*':
   {%- if grains.os_family not in ('MacOS', 'Arch') %}
    - salt.pkgrepo
   {%- endif %}
    - salt.minion
    - salt.formulas
