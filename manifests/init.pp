# Install and Setup Icinga Web
#
# === Authors
#
# Steven Bambling <smbambling@gmail.com>
#
# === Parameters
#
# If the Icinga Yum Repository should be configured
# $manage_repos = true/false
#
# Which IDO backend should be used, I prefer PostgreSQL so its default :)
# This should be updated to support mysql if desired
# $server_db_type = pgsql

class icinga_web (
  $manage_repos = true,
  $server_db_type = 'pqsql',
  $db_user = 'icingaweb',
  $db_password = 'icingaweb',
  $db_name = 'icingaweb',
  $db_host = 'localhost',
  $db_port = '5432',
  $icinga_server_db_type = 'pgsql',
  $icinga_db_user = 'icinga',
  $icinga_db_password = 'icinga',
  $icinga_db_name = 'icinga',
  $icinga_db_host = 'localhost',
  $icinga_db_port = '5432',
  ) {

  if $manage_repos == true {
    case $::operatingsystem {
      #CentOS systems:
      'CentOS': {

        #Add the official Icinga Yum repository: http://packages.icinga.org/epel/
        #Check to see if the Yumrepo class is already defined from the icinga module
        if !defined ( Yumrepo['icinga2_yum_repo'] ) {

          yumrepo { 'icinga2_yum_repo':
            baseurl  => "http://packages.icinga.org/epel/${::operatingsystemmajrelease}/release/",
            descr    => 'Icinga 2 Yum repository',
            enabled  => 1,
            gpgcheck => 1,
            gpgkey   => 'http://packages.icinga.org/icinga.key'
          }

        } else {

          notify { 'icinga2_yum_repo':
            message => 'Icinga 2 Yum Repository already defined in catalog',
          }

        }
      }

      #Fail if we're on any other OS:
      default: { fail("${::operatingsystem} is not supported!") }
    }
  }

  # PHP Dependencies Packages
  $dependencies_pkgs = [ 'php', 'php-cli', 'php-pear', 'php-xmlrpc', 'php-pdo', 'php-soap', 'php-gd', 'php-ldap', 'php-pgsql' ]

  # Icinga Web Packages
  $icinga_web_pkgs = [ 'icinga-web', "icinga-web-${server_db_type}", 'icinga-web-scheduler' ]

  # Install Packages
  package { $dependencies_pkgs:
    ensure => installed,
  } ->

  package { $icinga_web_pkgs:
    ensure => installed,
  }

  # Manage the Icinga Web database.xml configuration file
  file { 'icinga web databases.xml':
    ensure  => present,
    path    => '/etc/icinga-web/conf.d/databases.xml',
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('icinga_web/databases.xml.erb'),
    notify  => Exec['icinga clear cache'],
    require => [ Package['icinga-web'], Package["icinga-web-${server_db_type}"] ],
  }

  # Clear Icinga Web cache after updating the xml configuration file
  exec { 'icinga clear cache':
    command     => '/usr/bin/icinga-web-clearcache',
    refreshonly => true,
  }

  #Pick set the right path where we can find the DB schema based on the OS...
  case $::operatingsystem {
    'CentOS': {
      #...and database that the user picks
      case $server_db_type {
        'mysql': { $server_db_schema_path = '/usr/share/icinga-web/etc/schema/mysql.sql' }
        'pgsql': { $server_db_schema_path = '/usr/share/icinga-web/etc/schema/pgsql.sql' }
        default: { fail("${server_db_type} is not supported") }
      }
    }

  #Fail if we're on any other OS:
    default: { fail("${::operatingsystem} is not supported!") }
  }

  # Load the Icinga Web schema if not already loaded
  exec { 'icinga_web load schema':
    command => "/usr/bin/sudo /sbin/runuser -l postgres -c 'psql -U ${db_user} -d ${db_name} < ${server_db_schema_path}'",
    require => Package['icinga-web-pgsql'],
    onlyif  => "/usr/bin/sudo /sbin/runuser -l postgres -c \"/usr/bin/psql -U ${db_user} -d ${db_name} -t -c \"SELECT version FROM nsm_db_version\"\" 2>&1 >/dev/null | grep -q \"does not exist\"",
  }
}
