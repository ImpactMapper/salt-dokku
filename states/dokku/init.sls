# Dokku
#
# See: https://github.com/dokku/dokku/blob/master/docs/getting-started/install/debian.md

apt-transport-https:
  pkg:
    - latest
    - refresh: True
    - require_in:
      - pkgrepo: dokku-ppa

dokku-ppa:
  pkgrepo:
    - managed
    - name: deb https://packagecloud.io/dokku/dokku/ubuntu/ {{ grains["oscodename"] }} main
    - key_url: https://packagecloud.io/gpg.key
    - gpgcheck: 1
    - require_in:
      - pkg: dokku

dokku:
  pkg:
    - latest
    - refresh: True
    - require:
      - pkg: docker-ce
      - mount: /etc/nginx
      - mount: /var/lib/dokku
      - mount: /home/dokku

home_folder_permissions:
  file.directory:
    - name: /home/dokku
    - user: dokku
    - group: dokku
    - mode: 0755
    - require:
      - mount: /home/dokku
      - pkg: dokku
    - watch:
      - mount: /home/dokku

/home/dokku/.ssh/authorized_keys:
  file.managed:
    - source: salt://dokku/authorized_keys
    - user: dokku
    - group: dokku
    - mode: 0600
    - require:
      - mount: /home/dokku
      - pkg: dokku

dokku_core_dependencies:
  cmd.wait:
    - name: dokku plugin:install-dependencies --core
    - watch:
      - pkg: dokku
