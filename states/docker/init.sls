# Docker
#
# See: https://docs.docker.com/install/linux/docker-ee/ubuntu/#install-using-the-repository

docker-deps:
  pkg.installed:
    - pkgs:
      - apt-transport-https
      - software-properties-common
      - ca-certificates
    - require_in:
      - pkgrepo: docker-repo

docker-repo:
  pkgrepo.managed:
    - name: deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ grains["oscodename"] }} stable
    - humanname: Docker Package Repository
    - key_url: https://download.docker.com/linux/ubuntu/gpg
    - file: /etc/apt/sources.list.d/docker.list
    - refresh_db: True
    - require_in:
      - pkg: docker-ce

docker-ce:
  pkg:
    - latest
    - refresh: True
    - require:
      - mount: /var/lib/docker

docker:
  service:
    - running
    - enable: True
    - watch:
      - pkg: docker-ce
