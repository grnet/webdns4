# WebDNS

`webdns` is a web PowerDNS frontend using the powerful pdns MySQL backend.

## Features

 * Automatically handle zone serial updates using multiple serial strategies.
 * DNSSEC support.
 * Slave & Master support.
 * Smart editing helpers.
 * A flexible per group permission model.

## Installation

`webdns` was developed to be deployed using standard debian jessie (stable) packages and practices. It does not require bundler for production, but is should be pretty straightforward to set it up using bundler on other platforms.

### Setup powerdns
```
$ sudo apt-get install pdns-server pdns-backend-mysql
$ cat /etc/powerdns/pdns.d/pdns.local.gmysql.conf
# MySQL Configuration
launch+=gmysql

# gmysql parameters
gmysql-host=127.0.0.1
gmysql-port=3306
gmysql-dbname=webdns
gmysql-user=webdns
gmysql-password=password
gmysql-dnssec=no
```

You might also want to enable slave and master support on powerdns in order to manage slave & master zones in WebDNS.

### Prepare for deploy

Install dependencies

```
$ cat Gemfile | grep -oE 'pkg:[a-z0-9-]+' | cut -d: -f2 | xargs echo apt-get install
```

Edit & install

```
contrib/systemd/sudo_unicorn -> /etc/sudoers.d/unicorn
contrib/systemd/default_unicorn -> /etc/default/unicorn
contrib/systemd/unicornctl -> /usr/local/bin/unicornctl
contrib/systemd/unicorn.service -> /etc/systemd/system/unicorn.service
```

```
systemctl daemon-reload # Notify systemd about the newly installed unicorn service
```

You should also create an empty database and an account.

### Setup Capistrano

On the server create the following files under `/srv/webdns/shared/config/`. Those files will be symlinked to `config/` on deploy by capistrano.

```
database.yml
secrets.yml
local_settings.rb # Override config/initializers/00_settings.rb

```
Locally create `config/deploy/production.rb` based on the sample file.

```
$ apt get install capistrano
$ cap production deploy

```
