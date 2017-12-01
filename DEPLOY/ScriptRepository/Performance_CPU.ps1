Function PercentProcessorTime() {
	if ($scope -eq '') {$result = gwmi -computername $computername Win32_PerfRawData_PerfOS_Processor -Filter "Name='_Total'" -ea stop|select PercentProcessorTime, timestamp_sys100ns}
	else {$result = gwmi -computername $computername Win32_PerfRawData_PerfOS_Processor -Filter "Name='_Total'" -credential $creds -ea stop|select PercentProcessorTime, timestamp_sys100ns}
	return $result
}
$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
#PercentProcessorTime	DPCsQueuedPerSec	Frequency_PerfTime	InterruptsPerSec
if (!(test-path $logfile)) {out-file $logfile -input "Computername	PercentProcessorTime"}
try {
	$result1 = PercentProcessorTime
	start-sleep -s 5
	$result2 = PercentProcessorTime
	$ProcessorTime = 1 - (($result2.percentprocessortime - $result1.percentprocessortime) / ($result2.timestamp_sys100ns - $result1.timestamp_sys100ns))
	Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message 'CPU retrieved successfully' -logfile 'ps1command.log'
	$line = '{0}	{1:P}' -f $computername, $ProcessorTime
	out-file $logfile -input $line -append
}
catch {Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageColor $css.richtextcolorERR -logfile 'ps1command.log'}