$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
if ($scope -ne '') {$credsplain = select-MiCredential -scope $scope -plain}
#### Origen y Destino ####
if (![bool]$source) {
	Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message 'Rellena los campos solicitados de la consola de comandos' -MessageColor $css.richtextcolorwarning -logfile 'ps1command.log'
	$source = read-host "Carpeta Origen?"
}
if (![bool]$destination) {$destination = read-host "Carpeta Destino?"}
if (![bool]$files) {$files = read-host "Ficheros?"}

##########################
if ($scope -ne '') {
	$cmdkeyadd = "cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
	invoke-expression $cmdkeyadd
}
$robocommand = 'robocopy "{0}" "\\{1}\{2}" "{3}" /w:1 /r:1 /xo /e /tee /np /LOG+:".\logs\Copiar_Robocopy Origen-Destino.log"' -f $source, $computername, ($destination -replace (':', '$')), $files
invoke-expression $robocommand
if ($lastexitcode -gt 8) {$color = $css.richtextcolorERR; $premsg = 'Error'}
else {$color = $css.richtextcolorOK; $premsg = 'Exito'}
Append-Richtextbox -ComputerName $computername -Source $scriptbasename -Message "$premsg copiando $source a $destination"  -MessageColor $color -logfile 'ps1command.log'
if ($scope -ne '') {
	$cmdkeydelete = "cmdkey.exe /delete:" + $computername
	invoke-expression $cmdkeydelete
}
