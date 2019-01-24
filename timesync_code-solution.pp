plan tools::timesync_code(
  TargetSpec $nodes,
) {
  apply_prep($nodes)

  apply($nodes) {
    case $facts['kernel'] {
      'Linux': {
        class { 'ntp':
          servers  => [ '0.nl.pool.ntp.org',
                        '1.nl.pool.ntp.org',
                        '2.nl.pool.ntp.org' ],
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
  }
}
