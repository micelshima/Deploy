$scriptbasename=$MyInvocation.Mycommand.name.substring(0,$MyInvocation.Mycommand.name.lastindexof('.'))
$logfile= "results\$($scriptbasename).csv"
if (!(test-path $logfile)){out-file $logfile -input "Computername	displayname	uninstallstring"}
try{
	if($scope -eq ''){$result = gwmi Win32_NetworkAdapterConfiguration -ComputerName $computername -ea stop|?{$_.IPEnabled}
	else{$result = gwmi Win32_NetworkAdapterConfiguration -ComputerName $computername -credential $creds -ea stop|?{$_.IPEnabled}
	foreach ($Network in $result)
		{            
		$IPAddress  = $Network.IpAddress[0]            
		$SubnetMask  = $Network.IPSubnet[0]            
		$DefaultGateway = $Network.DefaultIPGateway            
		$DNSServers  = $Network.DNSServerSearchOrder            
		$IsDHCPEnabled = $false            
		If($network.DHCPEnabled){$IsDHCPEnabled = $true}            
		$MACAddress  = $Network.MACAddress
		out-file $logfile -input "$Computername	$IPAddress	$SubnetMask	$DefaultGateway	$MACAddress	$IsDHCPEnabled	$DNSServers" -append          
		}#fin foreach networkadapter
}
catch{Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageColor 'red' -logfile 'ps1command.log'}
