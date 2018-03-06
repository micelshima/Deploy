$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)) {out-file $logfile -input "Computername	IPAddress	SubnetMask	DefaultGateway	MACAddress	IsDHCPEnabled	DNSServers"}
if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
try {
	$result = gwmi Win32_NetworkAdapterConfiguration @params -ea stop|? {$_.IPEnabled}
	foreach ($Network in $result) {
		$IPAddress = $Network.IpAddress[0]
		$SubnetMask = $Network.IPSubnet[0]
		$DefaultGateway = $Network.DefaultIPGateway
		$DNSServers = $Network.DNSServerSearchOrder
		$IsDHCPEnabled = $false
		If ($network.DHCPEnabled) {$IsDHCPEnabled = $true}
		$MACAddress = $Network.MACAddress
		out-file $logfile -input "$Computername	$IPAddress	$SubnetMask	$DefaultGateway	$MACAddress	$IsDHCPEnabled	$DNSServers" -append
	}#fin foreach networkadapter
	if ($computername -eq $objcomputers[-1]) {start-process $logfile}
}
catch {Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageColor $css.richtextcolorERR -logfile 'ps1command.log'}
