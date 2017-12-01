$scriptbasename=$MyInvocation.Mycommand.name.substring(0,$MyInvocation.Mycommand.name.lastindexof('.'))
$logfile= "results\$($scriptbasename).csv"
if (!(test-path $logfile)){out-file $logfile -input "COMPUTERNAME	DRIVE	SIZEGB	FREEGB	USEDGB	PERCENTUSED"}
try{
	if($scope -eq ''){$result = gwmi win32_logicaldisk -filter "drivetype=3" -ComputerName $computername -ea stop}
	else{$result = gwmi win32_logicaldisk -filter "drivetype=3" -ComputerName $computername -credential $creds -ea stop}
	foreach ($Disk in $result)
	{
	$Used = [int64]$Disk.size - [int64]$Disk.freespace
	$line='{0}	{1}	{2:N1}	{3:N1}	{4:N1}	{5:P}' -f $computername,$Disk.deviceid, ($Disk.Size/1GB),($Disk.FreeSpace/1GB),($used/1GB),($Used/$Disk.Size)
	out-file $logfile -input $line -append
	}
	Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message 'HDD retrieved successfully' -logfile 'ps1command.log'
}
catch{Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageColor $css.richtextcolorERR -logfile 'ps1command.log'}