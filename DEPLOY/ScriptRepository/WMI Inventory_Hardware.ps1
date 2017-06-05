$scriptbasename=$MyInvocation.Mycommand.name.substring(0,$MyInvocation.Mycommand.name.lastindexof('.'))
$HKLM = 2147483650
$logfile= "results\$($scriptbasename).csv"
if (!(test-path $logfile)){out-file $logfile -input "Servidor	tipo	dominio	marca	modelo	serialnumber	partnumber	Nprocessors	Ncores	ram	almacenamiento	OSfamily	SP	WUdate	bootup"}
#WMI computer info
try{
	#COMPUTERSYSTEM
	if($scope -eq ''){$result=gwmi -computername $computername Win32_ComputerSystem}
	else{$result=gwmi -computername $computername Win32_ComputerSystem -credential $creds}
	$marca=$result.manufacturer 
	$modelo=$result.model
	$nproc=$result.NumberOfProcessors			
	$dominio=$result.domain
	$ram=[math]::round($result.TotalPhysicalMemory/1GB,1)
		if ($marca -eq "VMware, Inc." -or $marca -eq "Microsoft Corporation")
		{
		$tipo="Virtual ($marca)"
		$modelo=$numerodeserie=$partnumber=$null
		}
		else
		{
		$tipo="Físico"
		#BIOS
		if($scope -eq ''){$result=gwmi -computername $computername Win32_Bios}
		else{$result=gwmi -computername $computername Win32_Bios -credential $creds}
		$numerodeserie=$result.serialnumber
		#PARTNUMBER
		if($scope -eq ''){$reg = gwmi -List -Namespace root\default -ComputerName $computername|?{$_.Name -eq "StdRegProv"}}
		else{$reg = gwmi -List -Namespace root\default -ComputerName $computername -credential $creds|?{$_.Name -eq "StdRegProv"}}
		$partnumber = $reg.GetStringValue($HKLM,"HARDWARE\DESCRIPTION\System\BIOS","SystemSKU").sValue
		}
	
	#PROCESSOR
	if($scope -eq ''){$result=gwmi -computername $computername Win32_processor}
	else{$result=gwmi -computername $computername Win32_processor -credential $creds}
	$ncores=0
	Foreach ($processorinfo in $result){$ncores+=$processorinfo.numberofcores}
	#LOGICALDISK
	if($scope -eq ''){$result=gwmi -computername $computername win32_logicaldisk}
	else{$result=gwmi -computername $computername win32_logicaldisk -credential $creds}
	$almacenamiento=0
	Foreach ($disk in $result){$almacenamiento+=($Disk.Size/1GB)}
	$almacenamiento=[math]::round($almacenamiento,1)
	#OPERATINGSYSTEM
	if($scope -eq ''){$result=gwmi -computername $computername Win32_OperatingSystem}
	else{$result=gwmi -computername $computername Win32_OperatingSystem -credential $creds}
	$LastBootUpTime=$result.converttodatetime($result.lastbootuptime)
	$LastBootUpTime="{0:yyyy/MM/dd HH:mm:ss}" -f [datetime]$LastBootUpTime
	$sp=$result.csdversion -replace("service pack ","SP")
	$osfamily=$result.caption -replace("®") -replace ("\(R\)") -replace (',')
	#WINDOWSUPDATE
	if($scope -eq ''){$reg = gwmi -List -Namespace root\default -ComputerName $computername|?{$_.Name -eq "StdRegProv"}}
	else{$reg = gwmi -List -Namespace root\default -ComputerName $computername -credential $creds|?{$_.Name -eq "StdRegProv"}}
	$WUdate = $reg.GetStringValue($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install","LastSuccessTime").sValue
	$WUdate="{0:yyyy/MM/dd HH:mm:ss}" -f [datetime]$WUdate
out-file $logfile -input "$computername	$tipo	$dominio	$marca	$modelo	$numerodeserie	$partnumber	$nproc	$ncores	$ram	$almacenamiento	$osfamily	$sp	$WUdate	$LastBootUpTime" -append
}
catch{Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageColor 'red' -logfile 'ps1command.log'}


			

