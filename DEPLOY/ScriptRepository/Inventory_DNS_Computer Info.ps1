$scriptbasename=$MyInvocation.Mycommand.name.substring(0,$MyInvocation.Mycommand.name.lastindexof('.'))
$logfile= "results\$($scriptbasename).csv"
if (!(test-path $logfile)){out-file $logfile -input "COMPUTERNAME	IP	FQDN	DOMAIN"}
$fqdn=$domain=$ip=$null
$isValidIP = [System.Net.IPAddress]::tryparse([string]$computername, [ref]$null)
if ($isValidIP)
{
	$ip=$computername
	try {$resultdns = [System.Net.Dns]::gethostentry($ip)} catch { }
	if ($resultdns){$computername=[string]$resultdns.HostName.split('.',2)[0]}
	else{$fqdn="IP not found in DNS"}
}
else
{	
	try {$resultdns =[System.Net.DNS]::GetHostByName($computername)} catch { }
	if ($resultdns){$ip=[string]$resultdns.addresslist[0].IPaddresstostring}
	else{$fqdn="Name not found in DNS"}	
}
if($resultdns)
{
$fqdn =$resultdns.hostname
$domain=[string]$resultdns.HostName.split('.',2)[1]
}
out-file $logfile -input "$computername	$ip	$fqdn	$domain" -append