# Overview

# Server requirements

Supported Operating Systesm: CentOS
Supported Database Type: PostgreSQL

Currently this module only support CentOS and with a PostgreSQL database, but skeleton code has been setup to allow for updates to also use Additional Operating Systems and A MySQL Database.

This module does not set up any databases. You'll have to create one before installing Icinga Web via the module.

If you would like to set up your own database, either of the Puppet Labs [Postgres](https://github.com/puppetlabs/puppetlabs-postgresql) modules can be used.

The example below shows the Puppet Labs Postgres module being used to install Postgres and create a database and database user for Icinga Web:

````
class { 'postgresql::server': }

postgresql::server::db { 'icinga_web':
  user     => 'icinga_web',
  password => postgresql_password('icinga_web', 'icinga_web'),
}
````





