#start

group { "nagcmd":
        ensure => present,
        gid => 1000
}

group { "nagios":
        ensure => present,
        gid => 1002
}

user { "nagios":
        ensure => present,
        gid => "nagios",
        groups => ["nagcmd"],
        membership => minimum,
        shell => "/bin/bash",
        home => "/home/$nagios",
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


