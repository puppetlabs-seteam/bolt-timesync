case $facts['osfamily'] {
  'RedHat': {
    class { 'ntp':
      servers  => [ '0.nl.pool.ntp.org',
                    '1.nl.pool.ntp.org',
                    '2.nl.pool.ntp.org' ]
      restrict => [ '127.0.0.1' ],
    }
  }
  'windows': {
    class { 'windowstime':
      servers  => { '0.nl.pool.ntp.org' => '0x08',
                    '1.nl.pool.ntp.org' => '0x08',
                    '2.nl.pool.ntp.org' => '0x08',
      }
    }
  }
}
