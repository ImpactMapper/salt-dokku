<YOUR_USER>:
  ssh_auth.present:
    - user: ubuntu
    - source: salt://users/keys/<YOUR_USER>.id_rsa.pub
