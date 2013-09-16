	
$nagios_base = [ "gd", "gd-devel", "httpd", "php", "gcc", "glibc", "glibc-common", "nagios-plugins-all", "nagios", "nagios-common" ]

package { 	$nagios_base: ensure => "installed", } 


   package {
      "nagios":
         ensure  => installed,
         alias   => 'nagd',
         ;
   }

  exec {'make-nag-cfg-readable':
    command => "/bin/find /etc/nagios -type f -name \"*.cfg\" | xargs chmod +r",
  }


   service {
      "nagios":
         ensure  => running,
         alias   => 'nagios',
         hasstatus       => true,
         hasrestart      => true,
    	 require => Exec['make-nag-cfg-readable'],
  }
 
 file { 'resource-d':
    path   => '/etc/nagios/resource.d',
    ensure => directory,
    owner  => 'nagios',
  }

  # Collect the nagios_host resources
  Nagios_host <<||>> {
    require => File[resource-d],
    notify  => [Exec[make-nag-cfg-readable],Service[nagios]],
  }

