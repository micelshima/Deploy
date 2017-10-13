$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
if($scope -ne ''){$credsplain=select-MiCredential -scope $scope -plain}
#### Origen y Destino ####
$source="c:\OM TE"
$destination = "c:\ProgramData\AppsAE\OMTermicasBETA"
$files="*.txt"
##########################
if ($scope -ne '') {
	$cmdkeyadd = "cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
	invoke-expression $cmdkeyadd
}
$robocommand='robocopy "{0}" "\\{1}\{2}" "{3}" /w:1 /r:1 /xo /e /tee /np /LOG+:".\logs\Copiar_Robocopy Origen-Destino.log"' -f $source, $computername, ($destination -replace (':', '$')), $files
invoke-expression $robocommand
if ($lastexitcode -gt 8){$color='red';$premsg='Error'}
else{$color='green';$premsg='Exito'}
Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message "$premsg copiando $source a $destination"  -MessageColor $color -logfile 'ps1command.log'
if ($scope -ne '') {
	$cmdkeydelete = "cmdkey.exe /delete:" + $computername
	invoke-expression $cmdkeydelete
}
