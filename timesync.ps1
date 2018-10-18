w32tm /config /manualpeerlist:"0.nl.pool.ntp.org 1.nl.pool.ntp.org"
w32tm /config /update
w32tm /query /peers
w32tm /resync
