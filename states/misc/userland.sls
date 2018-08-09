# Common user stuff: tools, apt sources, goodies

userland:
  pkg.installed:
    - pkgs:
      - bash-completion
      - vim-tiny
      - python-software-properties
      - htop

ntp:
  pkg:
    - installed
  service.running:
    - require:
      - pkg: ntp

locales:
  locale.present:
    - name: en_US.UTF-8
