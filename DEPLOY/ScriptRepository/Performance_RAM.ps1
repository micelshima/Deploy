$scriptbasename=$MyInvocation.Mycommand.name.substring(0,$MyInvocation.Mycommand.name.lastindexof('.'))
$logfile= "results\$($scriptbasename).csv"
if (!(test-path $logfile)){out-file $logfile -input "COMPUTERNAME	SIZEMB	AVAILABLEMB	USEDMB	PERCENTUSED"}
try{
	if($scope -eq ''){$result=gwmi -computername $computername Win32_PerfRawData_PerfOS_Memory -ea stop}
	else{$result=gwmi -computername $computername Win32_PerfRawData_PerfOS_Memory -credential $creds -ea stop}
	$FreeMB=$result.availableMBytes
	if($scope -eq ''){$result2=gwmi -computername $computername Win32_ComputerSystem -ea stop}
	else{$result2=gwmi -computername $computername Win32_ComputerSystem -credential $creds -ea stop}
	$totalMB=$result2.TotalPhysicalMemory/1MB
	$UsedMB=$totalMB - $FreeMB
	Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message 'RAM retrieved successfully' -logfile 'ps1command.log'
	$line='{0}	{1:N0}	{2:N0}	{3:N0}	{4:P}' -f $computername,$totalMB,$FreeMB,$UsedMB,($UsedMB/$totalMB)
	out-file $logfile -input $line -append
	}
	catch{Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageColor $css.richtextcolorERR -logfile 'ps1command.log'}