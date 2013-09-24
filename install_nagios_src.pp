class nagios_user{
						
					Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }


						group { "nagcmd":
										ensure => present,
										gid => 1000
						}

						group { "nagios":
										ensure => present,
										gid => 1002
						}


						file { "/home/nagios":
							ensure => "directory",
							owner  => "nagios",
							group  => "nagios",
							mode   => 750,
						}

						user { "nagios":
										ensure => present,
										gid => "nagios",
										groups => ["nagcmd"],
										membership => minimum,
										shell => "/bin/bash",
										home => "/home/nagios",
										password=>"nagios",
										require => Group["nagcmd"]
						}

						file { "/etc/sudoers":
									owner   => "root",
									group   => "root",
									mode    => "440",
								 }


								augeas { "sudonagios":
									context => "/files/etc/sudoers",
									changes => [
										"set spec[last() + 1]/user nagios",
										"set spec[last()]/host_group/host ALL",
										"set spec[last()]/host_group/command ALL",
										"set spec[last()]/host_group/command/runas_user ALL",
										"set spec[last()]/host_group/command/tag NOPASSWD",
									],
									onlyif => "match *[user = '${name}'] size == 0",
						}
}


class install_nagios{
								Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
								file { '/usr/bin/php':
												ensure  => file,
												recurse => true,
												alias => "php"
								}
								$dir = "/tmp/nagios/nagios/"
								$pdir = "/tmp/nagios/nagios-plugins-1.4.16"


								exec { "unpacktars":
									command => "tar -xf /tmp/nagios/nagios-4.0.0.tar.gz && tar -xf /tmp/nagios/nagios-plugins-1.4.16.tar.gz",
									logoutput => true,
									require => Exec["get_tars"],
									cwd => "/tmp/nagios/",
								}

								file { "/tmp/nagios": ensure => directory, alias => "tmp"}

								exec { "get_tars":
										command => "wget http:// /sources/nagios-4.0.0.tar.gz -P /tmp/nagios/ | wget http:///sources/nagios-plugins-1.4.16.tar.gz -P /tmp/nagios/",
										cwd => "/tmp/nagios/",  
										require => File["tmp"], 
								}


								exec { "$dir/configure --with-nagios-user=nagios --with-command-group=nagcmd ":
										cwd     => "/tmp/nagios/nagios/",
										require => [Exec["unpacktars"],File["php"]],
										before  => Exec["make install nagios"],
										alias   => "./configure",
								}
														
								exec { "make all && make install && make install-init && make install-config && make install-commandmode && make install-webconf":
										cwd     => "/tmp/nagios/nagios/",
										alias   => "make install nagios",
										creates => [ "/usr/local/nagios/bin/nagios","/usr/local/nagios/etc/nagios.cfg" ],
										require => Exec["./configure"],
										before  => Exec["./configure plugins"],
								}

								exec { "$pdir/configure --with-nagios-user=nagios --with-nagios-group=nagcmd":
										cwd     => "/tmp/nagios/nagios-plugins-1.4.16",
										require => Exec["make install nagios","chmod_install"],
										before  => Exec["make install plugins"],
										alias   => "./configure plugins",
								}

								exec { "make && make install":
										cwd     => "$pdir",
										alias   => "make install plugins",
										creates => [ "/usr/local/nagios/bin/nagios","/usr/local/nagios/etc/nagios.cfg" ],
										require => Exec["./configure plugins"],
										before  => Service["nagios"],
								}
								exec { "chmod_install":
								command => "/usr/bin/install -c -m 775 -o nagios -g nagios -d /usr/local/nagios/bin",
								cwd     => "$pdir",
								}
								exec { "cp -R /tmp/nagios/nagios/contrib/eventhandlers /usr/local/nagios/libexec/":
									alias   => "cp_handler" ,
									require => Exec["make install nagios"]}
								exec { "chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers":
									require => Exec["cp_handler"], }
								}

class start_nagios { 
								service { "nagios":
												ensure    => running,
												enable => true,
								}
								service { "httpd":
												ensure    => running,
												enable => true,
								}
}

class { 'nagios_user': }
class { 'install_nagios': require => Class["nagios_user"], }
class { 'start_nagios': require => Class["install_nagios"], }
