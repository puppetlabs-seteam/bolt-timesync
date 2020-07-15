plan tools::timesync_code(
  TargetSpec $targets,
) {
  apply_prep($targets)

  apply($targets) {
    class { 'windowstime':
      servers  => { '0.nl.pool.ntp.org' => '0x08',
                    '1.nl.pool.ntp.org' => '0x08',
                    '2.nl.pool.ntp.org' => '0x08',
                    '3.nl.pool.ntp.org' => '0x08' }
    }
  }
}
