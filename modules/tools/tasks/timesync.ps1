[CmdletBinding()]
Param(
  [Parameter(Mandatory = $True)] [Boolean] $Restart
)

echo "Reconfiguring W32Time..."
w32tm /config /syncfromflags:MANUAL /manualpeerlist:"0.nl.pool.ntp.org 1.nl.pool.ntp.org" /update
echo ""
echo "Resyncing clock..."
w32tm /resync
echo ""
echo "Current time source:"
w32tm /query /source
echo ""
echo "All configured time sources:"
w32tm /query /peers

if ($Restart) {
    write-host "Restart parameter enabled, restarting Windows Time service"
    restart-service 'W32Time' -force
    write-host "Windows Time service restarted"
}
