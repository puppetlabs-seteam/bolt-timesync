plan tools::timesync_code(
  TargetSpec $nodes,
) {
  apply_prep($nodes)

  apply($nodes) {
    class { 'windowstime':
      servers  => { '0.nl.pool.ntp.org' => '0x08',
                    '1.nl.pool.ntp.org' => '0x08',
                    '2.nl.pool.ntp.org' => '0x08',
                    '3.nl.pool.ntp.org' => '0x08' }
    }
  }
}
