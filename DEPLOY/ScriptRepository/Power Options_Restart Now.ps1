if($scope -eq ''){restart-computer -computername $computername -force -confirm:$false}
else{restart-computer -computername $computername -credential $creds -force -confirm:$false}