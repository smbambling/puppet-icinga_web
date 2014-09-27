# Overview

This module installs and configure Icinga Web frontend for Icinga/Icinga 2 monitoring sytems.  

The module has only been tested on CentOS 6.5 and PostgreSQL 9.3.5.

Other Red Hat and other EL derivatives, like Fedora, should work, but have not been tested.

Other PostgreSQL versions in the 9.x series should also work, but have not been tested.


# Server requirements

**Supported Operating Systesm**: CentOS
**Supported Database Type**: PostgreSQL

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

or Manually

````
sudo runuser -l postgres -c "psql -c \"create role icinga_web WITH LOGIN PASSWORD 'icinga_web';\""
sudo runuser -l postgres -c "psql -c \"create database icinga_web with owner icinga_web encoding 'utf8';\""
sudo runuser -l postgres -c "psql -c \"grant ALL privileges on database icinga_web to icinga_web;\""
````

# Usage

To install Icinga Web, first set up a Postgres database.

Once the database is set up, use the ````icinga_web```` class with the database connection parameters for both the Icinga Web and Icinga/Icinga 2 IDO databases.

The default Icinga Web database parameters user icinga_web for the username,password and database name.  These can be set as desired.

````
class { 'icinga_web': 
  server_db_type        => 'pgsql',
  db_host               => 'localhost',
  db_port               => '5432',
  db_name               => 'icinga_web',
  db_user               => 'icinga_web',
  db_password           => 'icinga_web,'
  icinga_server_db_type => 'pgsql',
  icinga_db_host        => 'localhost',
  icinga_db_port        => '5432',
  icinga_db_name        => 'icinga2_data',
  icinga_db_user        => 'icinga2',
  icinga_db_password    => 'password, 
}
 
