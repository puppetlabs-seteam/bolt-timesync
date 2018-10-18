[CmdletBinding()]
Param(
  [Parameter(Mandatory = $True)] [Boolean] $Restart
)

w32tm /config /manualpeerlist:"0.nl.pool.ntp.org 1.nl.pool.ntp.org"
w32tm /config /update
w32tm /query /peers
w32tm /resync
if ($Restart) {
    write-host "Restart parameter enabled, restarting Windows Time service"
    restart-service 'W32Time' -force
    write-host "Windows Time service restarted"
