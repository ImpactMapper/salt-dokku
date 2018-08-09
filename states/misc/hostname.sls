# This updates the hosts file with a static entry to the current
# machine hostname.
# Stolen from: https://github.com/saltstack-formulas/hostsfile-formula

{%- set fqdn = grains['id'] %}

/etc/hostname:
  file.managed:
    - contents: {{ fqdn }}
    - backup: false

set-fqdn:
  cmd.run:
    - name: hostname {{ fqdn }}
    - unless: test "{{ fqdn }}" == "$(hostname)"


hostname-hosts-entry:
  host.present:
    - ip: 127.0.0.1
    - names:
      - {{ fqdn }}
