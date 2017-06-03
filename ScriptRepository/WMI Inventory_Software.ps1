$HKLM = 2147483650
$logfile="LOGS\WMI Inventory Software.csv"
if (!(test-path $logfile)){out-file $logfile -input "SERVER	DISPLAYNAME	UNINSTALLSTRING"}
try{
	if($scope -eq ''){$reg = gwmi -List -Namespace root\default -ComputerName $computername|?{$_.Name -eq "StdRegProv"}}
	else{$reg = gwmi -List -Namespace root\default -ComputerName $computername -credential $creds|?{$_.Name -eq "StdRegProv"}}
	foreach ($key in $reg.Enumkey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall").snames)
	{
	$displayname=$reg.GetStringValue($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$key","Displayname").svalue
	$uninstallstring=$reg.GetStringValue($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$key","uninstallstring").svalue
		if($displayname -notmatch "Update for " -and $displayname -notmatch "Hotfix for " -and $displayname -ne $null)
		{
		out-file $logfile -input "$computername	$displayname	$uninstallstring" -append
		}
	}
}
catch{Append-Richtextbox -ComputerName $computername -Source "WMIInventorySoftware" -Message $_.Exception.Message -MessageColor 'red' -logfile 'ps1command.log'}
