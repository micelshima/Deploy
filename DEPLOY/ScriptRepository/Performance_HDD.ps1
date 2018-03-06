$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)) {out-file $logfile -input "COMPUTERNAME	DRIVE	SIZEGB	FREEGB	USEDGB	PERCENTUSED	INCREMENTGB80PERCENTUSED"}
if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
try {
	$result = gwmi win32_logicaldisk -filter "drivetype=3" @params -ea stop
	foreach ($Disk in $result) {
		$Used = [int64]$Disk.size - [int64]$Disk.freespace
		$increment80percentused = ([int64]$Disk.size - 5 * [int64]$Disk.freespace) / 4
		$line = '{0}	{1}	{2:N1}	{3:N1}	{4:N1}	{5:P}	{6}' -f $computername, $Disk.deviceid, ($Disk.Size / 1GB), ($Disk.FreeSpace / 1GB), ($used / 1GB), ($Used / $Disk.Size), [math]::Round($increment80percentused / 1GB, 0)
		out-file $logfile -input $line -append
	}
	Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message 'HDD retrieved successfully' -logfile 'ps1command.log'
	if ($computername -eq $objcomputers[-1]) {start-process $logfile}
}
catch {Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageColor $css.richtextcolorERR -logfile 'ps1command.log'}