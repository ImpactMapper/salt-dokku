# EBS storage for Dokku and Docker.

/dev/nvme1n1:
  blockdev.formatted:
    - fs_type: ext4

/mnt/ebs:
  mount.mounted:
    - device: /dev/nvme1n1
    - fstype: ext4
    - opts: discard,defaults,nofail
    - persist: True
    - mkmnt: True
    - require:
      - blockdev: /dev/nvme1n1

make_swapfile:
  cmd.run:
    - name: |
        dd if=/dev/zero of=/mnt/ebs/.swapfile bs=1M count=4096
        chmod 0600 /mnt/ebs/.swapfile
        mkswap /mnt/ebs/.swapfile
    - unless: file /mnt/ebs/.swapfile 2>&1 | grep -q 'Linux/i386 swap'
    - require:
      - mount: /mnt/ebs

/mnt/ebs/.swapfile:
  mount.swap:
    - require:
      - cmd: make_swapfile

# Owner will be changed by dokku state.
/mnt/ebs/dokku:
  file.directory:
    - user: root
    - group: root
    - mode: 0777
    - makedirs: True
    - require:
      - mount: /mnt/ebs
    - onchanges:
      - blockdev: /dev/nvme1n1

/mnt/ebs/dokku-data:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - makedirs: True
    - require:
      - mount: /mnt/ebs

/mnt/ebs/docker:
  file.directory:
    - user: root
    - group: root
    - mode: 0711
    - makedirs: True
    - require:
      - mount: /mnt/ebs

/mnt/ebs/nginx:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - makedirs: True
    - require:
      - mount: /mnt/ebs

/var/lib/docker:
  mount.mounted:
    - device: /mnt/ebs/docker
    - fstype: none
    - opts: bind
    - dump: 0
    - pass_num: 0
    - persist: True
    - mkmnt: True
    - onchanges:
      - file: /mnt/ebs/docker

/etc/nginx:
  mount.mounted:
    - device: /mnt/ebs/nginx
    - fstype: none
    - opts: bind
    - dump: 0
    - pass_num: 0
    - persist: True
    - mkmnt: True
    - onchanges:
      - file: /mnt/ebs/nginx

/var/lib/dokku:
  mount.mounted:
    - device: /mnt/ebs/dokku-data
    - fstype: none
    - opts: bind
    - dump: 0
    - pass_num: 0
    - persist: True
    - mkmnt: True
    - onchanges:
      - file: /mnt/ebs/dokku-data

/home/dokku:
  mount.mounted:
    - device: /mnt/ebs/dokku
    - fstype: none
    - opts: bind
    - dump: 0
    - pass_num: 0
    - persist: True
    - mkmnt: True
    - onchanges:
      - file: /mnt/ebs/dokku
