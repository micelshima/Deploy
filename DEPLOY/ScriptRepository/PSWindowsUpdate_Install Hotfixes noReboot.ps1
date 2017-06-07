import-module "..\_Modules\PSWindowsUpdate"
$Script = {ipmo PSWindowsUpdate; Get-WUInstall -AcceptAll -IgnoreReboot | Out-File C:\PSWindowsUpdate.log}
Invoke-WUInstall -ComputerName $computername -script $script -confirm:$false