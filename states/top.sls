base:
  '*':
    - misc.userland
    - misc.hostname

  'dokku-[0-9]*':
    - users.ubuntu
    - misc.fail2ban
    - dokku.ebs
    - docker
    - dokku
