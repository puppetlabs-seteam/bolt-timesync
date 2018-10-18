plan tools::timesync_code(
  TargetSpec $nodes,
) {
  apply_prep($nodes)

  apply($nodes) {
    class { 'windowstime':
      servers  => { '0.nl.pool.ntp.org' => '0x09',
                    '1.nl.pool.ntp.org' => '0x09',
                    '2.nl.pool.ntp.org' => '0x09',
                    '3.nl.pool.ntp.org' => '0x09' }
    }
  }
}
