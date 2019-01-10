class student_name::puppet_agent {

  service { 'puppet':
    ensure => running,
    enable => true 
  }

}
