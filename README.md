# Salted Dokku

Deploy Dokku using SaltStack. :whale: :shipit:

TODO:
 * [ ] use salt-cloud to provision instances
 * [ ] add a bastion host

## SaltStack

Salt handles the configuration management and remote execution for the
instances.

A quick guide on SaltStack is available at:
[OpsSchool.org](http://www.opsschool.org/en/latest/config_management.html#saltstack)

### Installation

```bash
(local)$ virtualenv -p python3 .venv
(local)$ source .venv/bin/activate
(local)$ pip install salt-ssh
```

### Remote execution

To ping all available instances in the roster, use:

```bash
(local)$ salt-ssh '*' test.ping
```

To execute a command on the available instances in the roster, use:

```bash
(local)$ salt-ssh '*' cmd.run 'date'
```

The output will include the instance name and the command execution result.

### Configuration management

To see the instances and what configuration applies to those, run:

```bash
(local)$ salt-ssh '*' state.show_top
```

To apply the latest changes to the instances, use:

```bash
(local)$ salt-ssh '*' state.apply
```

To target just a specific instance for updates, use:

```bash
(local)$ salt-ssh 'dokku-01' state.apply
```

## Dokku

Dokku as our _PaaS_ for deploying prodution or staging apps.

Suggested list:
 * Pick a larger instance (on AWS: an m5.x) running Ubuntu with a bit of root
   storage (>50G) and provision it (allow SSH connections to it)
 * Attach some persistent block storage or network drive to it
 * Optionally, attach the new instance to a load balancer and assign a
   sub-domain to it (ex. `dokku.domain.com`)
 * Update the `etc/salt/roster` file to include the new instance IP address
 * Run `salt-ssh 'dokku-XX' state.apply`
 * Install some plugins (ex. postgres, letsencrypt, or slack)
 * Reboot the instance
 * Open the browser to check if everything works as intended.

The last step will configure the instance to be ready for immediate use.
It will deploy ssh keys (see `states/users`), install relevant packages and
update the mount points.

To upgrade, deploy a new Dokku instance and re-associate the load-balancer,
block storage/network drive and the elastic IP address to the new instance.
Make backups before!

### Local client

To download a local bash client, download and allow execution of the official
script:

[https://github.com/dokku/dokku/blob/master/contrib/dokku_client.sh](https://raw.githubusercontent.com/dokku/dokku/master/contrib/dokku_client.sh)

Example:
```
(local)$ curl https://raw.githubusercontent.com/dokku/dokku/master/contrib/dokku_client.sh > ~/.bin/dokku
(local)$ chmod +x ~/.bin/dokku
```

### Adding a new Dokku user

To add a new user, update the file in `states/dokku/authorized_keys` based
on this template:
```
command="FINGERPRINT=<FINGERPRINT> NAME=\"<USER_ALIAS>\" `cat /home/dokku/.sshcommand` $SSH_ORIGINAL_COMMAND",no-agent-forwarding,no-user-rc,no-X11-forwarding,no-port-forwarding <PUBLIC_KEY_CONTENTS>
```

To get the public key fingerprint, use:
```
(local)$ ssh-keygen -lf states/users/keys/<USER>.id_rsa.pub
```

Next apply the changes:

```
(local)$ salt-ssh 'dokku-*' state.apply
```

### Creating applications

To create an application, follow the
[official guide](http://dokku.viewdocs.io/dokku~v0.12.10/deployment/application-deployment/#create-the-app).

```bash
(local)$ ssh -t dokku@dokku.domain.com apps:create <NEW_APP_NAME>
```

Consider the following naming scheme for the applications:
`<REPOSITORY_NAME>-<FEATURE/BRANCH>`.

Next point your application to the new Dokku origin:

```bash
(local/app)$ git remote add dokku dokku@dokku.domain.com:<NEW_APP_NAME>
(local/app)$ git push dokku <YOUR_BRANCH>:master
```

To see all available apps, use:

```bash
(local)$ ssh -t dokku@dokku.domain.com apps:list
```

### CI

You can automate your continuous integration server to create the applications.

Here's a template you can use to automatically let your build server provision
new applications is your commit includes the keyword `[staging]`:

```bash
export STAGING=`git show -s --format=%B --grep '\[staging\]'`
export DOKKU_REPO=`echo $REPONAME | tr '[:upper:]' '[:lower:]' | tr '_' '-'`
export DOKKU_BRANCH=`echo $BRANCH | tr '[:upper:]' '[:lower:]' | tr '_' '-'`
export DOKKU_TO_CLONE_ID=template-app
export DOKKU_ID="$DOKKU_REPO-$DOKKU_BRANCH"
if [ $CIRCLE_BRANCH == 'develop' ] || [ -n "$STAGING" ]
then
  echo `ssh -t dokku@dokku.domain.com apps:create "$DOKKU_ID"`
  echo `git remote add dokku "dokku@dokku.domain.com:$DOKKU_ID"`
  git push dokku "$BRANCH:master" -f
  export DOKKU_STAGED=`dokku config:get STAGED`
  if [[ $DOKKU_STAGED != *'yes'* ]]
  then
    export DOKKU_DEF_CONF=`ssh -t dokku@dokku.domain.com config:export --format=shell $DOKKU_TO_CLONE_ID`
    echo `dokku config:set --no-restart $DOKKU_DEF_CONF STAGED=yes`
    echo `dokku config:unset --no-restart DATABASE_URL`
    echo `dokku domains:add $DOKKU_ID.dokku.domain.com`
    # Plugins
    # echo `dokku proxy:ports-remove https:443:3000`
    # echo `dokku proxy:ports-add http:80:3000`
    # echo `dokku letsencrypt`
    # echo `dokku postgres:clone "pg-$DOKKU_TO_CLONE_ID" "pg-$DOKKU_ID"`
    # echo `dokku postgres:link "pg-$DOKKU_ID" "$DOKKU_ID"`
    # echo `dokku postgres:promote "pg-$DOKKU_ID" "$DOKKU_ID"`
  fi
  dokku ps:report
  dokku urls
fi
echo "STAGING $STAGING"
```
