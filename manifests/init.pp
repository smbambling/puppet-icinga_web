# Install and Setup Icinga Web
#
# === Authors
#
# Steven Bambling <smbambling@gmail.com>
#
# === Parameters
#
# If the Icinga 2 Yum Repository should be configured
# $manage_repos = true/false
#
# Which IDO backend should be used, I prefer PostgreSQL so its default :)
# $ido_backend = pgsql/mysql

class icinga_web (
  $manage_repos = true,
  $db_backend = 'pqsql',
  $db_user = 'icingaweb',
  $db_pass = 'icingaweb',
  $db_name = 'icingaweb',
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
  $icinga_web_pkgs = [ 'icinga-web', "icinga-web-${db_backend}", 'icinga-web-scheduler' ]

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
    require => [ Package['icinga-web'], Package["icinga-web-${db_backend}"] ],
  }

  # Clear Icinga Web cache after updating the xml configuration file
  exec { 'icinga clear cache':
    command     => '/usr/bin/icinga-web-clearcache',
    refreshonly => true,
  }

  exec { 'icinga_web load schema':
    command => "/usr/bin/sudo /sbin/runuser -l postgres -c 'psql -U ${db_user} -d ${db_name} < /usr/share/icinga-web/etc/schema/pgsql.sql'",
    require => Package['icinga-web-pgsql'],
    onlyif  => "/usr/bin/sudo /sbin/runuser -l postgres -c \"/usr/bin/psql -U ${db_user} -d ${db_name} -t -c \"SELECT version FROM nsm_db_version\"\" 2>&1 >/dev/null | grep -q \"does not exist\"",
  }
}
