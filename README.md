# backup-server

backup scripts working on collector server with rsync.

to setup remote backup target, use [backup-remote][br].

## depends on

- rsync

## setup

### create ssh key pair.

create ssh key pair for access to remote servers over the ssh.

```
# ssh-keygen 
```

enter the key name. it is recommended that change from the default name. path for save can be anyware.

set default path `/root/.ssh` and custom name `id_rsa_rsync` in this document.

```
Enter file in which to save the key (/root/.ssh/id_rsa): /root/.ssh/id_rsa_rsync
```

passphrase MUST NOT set. leave blank.

```
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
```

### setup scripts

setup into `/root/` as root.

```
$ su -
```

clone scripts from github.

```
# git clone https://github.com/kedamaDQ/backup-server.git
```

change directory into script root.

```
# cd ~/backup-server
```

copy sample file to `.env` and edit it.

```
# cp .env.sample .env
# vi .env
```

change backup destination path according to your environment. 

```
DST_DIR='/path/to/backup/dest'
```

set user name for remote servers.

```
SSH_USER='username'
```

set path to ssh privkey which created at [previous step](#create-ssh-key-pair "create ssh key pair").

```
SSH_PRIVKEY='/root/.ssh/id_rsa_rsync'
```

## create backup target list

change directory into target list directory.

```
# cd ~/backup-server/backup.d
```

copy sample file to "__HOSTNAME__.list". __HOSTNAME__ is a name of the backup target host, and __HOSTNAME__ is an ip address or a hostname which can be resolves. eg:

- 192.168.1.1.list
- web1.list
- example.com.list

```
# cp hostname.list.sample 192.168.1.1.list
```

edit list.

```
# vi 192.168.1.1.list
```

write absolute path to backup target directory on the remote host in list file. the path SHOULD ends with '/'.

```
/etc/
/var/backups/
```

if necessary, you can set the rsync options separated one or more blanks following the path. eg:

```
/home/user  --bwlimit=4096
```

## setup remote server

setup the remote backup environment. see [backup-remote][br]


## run backup

run `backup.sh` with __HOSTNAME__. eg:

```
# bash /root/backup-server/backup.sh 192.168.1.1
```

you can set the port to second argument if necessary.(default: 22)

```
# bash /root/backup-server/backup.sh 192.168.1.1 22222
```

## schedule the backup

write in your crontab. eg:

```
03 03 * * * root /bin/bash /root/backup-server.sh 192.168.1.1 > /tmp/192.168.1.1.log 2>&1
13 03 * * * root /bin/bash /root/backup-server.sh example.com 22222 > /tmp/example.com.log 2>&1
```

[br]:https://github.com/kedamaDQ/backup-remote
