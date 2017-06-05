#MiShell DEPLOY
#GUI for runnning remote batches/scripts
#Mikel V.
#2017/06/01
function Append-Richtextbox{
		PARAM(
		[Parameter(Mandatory=$true)]
		[string]$Message,
		[string]$MessageColor = "DarkGreen",
		[string]$DateTimeColor="Black",
		[string]$Source,
		[string]$SourceColor="Gray",
		[string]$ComputerName,
		[String]$ComputerNameColor= "Blue",
		[String]$logfile)
		
		$SortableTime = get-date -Format "yyyy/MM/dd HH:mm:ss"
		$richtextbox.SelectionColor = $DateTimeColor
		$richtextbox.AppendText("[$SortableTime] ")
		
		IF ($PSBoundParameters['ComputerName']){
			$richtextbox.SelectionColor = $ComputerNameColor
			$richtextbox.AppendText(("$ComputerName ").ToUpper())
		}
		
		IF ($PSBoundParameters['Source']){
			$richtextbox.SelectionColor = $SourceColor
			$richtextbox.AppendText("$Source ")
		}
		
		$richtextbox.SelectionColor = $MessageColor
		$richtextbox.AppendText("$Message`r")
		$richtextbox.Refresh()
		$richtextbox.ScrollToCaret()
		
		Write-Verbose -Message "$SortableTime $ComputerName $Message"
		IF ($PSBoundParameters['logfile']){
			out-file "$psscriptroot\logs\$logfile" -input "$SortableTime $ComputerName $Message" -append -enc ascii
			}
	}
Function Add-Node($Nodes,$Path,$icon)
{
  $Path.Split($treeSeparator)|%{
    Write-Verbose "Searching For: $_"
    $SearchResult = $Nodes.Find($_, $False)
    If ($SearchResult.Count -eq 1)
    {
      Write-Verbose "Selecting: $($SearchResult.Name)"
      # Must select first element. Return from Find is TreeNode[]
      $Nodes = $SearchResult[0].Nodes
    }
    Else
    {
      Write-Verbose "Adding: $_"
      $Node = New-Object Windows.Forms.TreeNode($_)
      # Name must be populated for Find work
      $Node.Name = $_
	  $Node.imageindex=$icon
	  $Node.SelectedImageIndex=$icon
      $Nodes.Add($Node)|out-null

    }
  }
}
Function fill-TreeView($scriptsrepository,$treeview)
{
	switch ($treeview.name)
	{
	"BAT"{$indexicon=1}
	"PS"{$indexicon=2}
	"TXT"{$indexicon=3}
	}
gci $scriptsrepository|select -expand basename|%{
    try{
		$fullnodexceptlast=$_.substring(0,$_.lastindexof($treeSeparator))
		$fullnode=""
			foreach ($node in $fullnodexceptlast.split($treeSeparator))
			{
			$fullnode+="$treeSeparator$node"
			Add-Node $TreeView.Nodes $fullnode.substring(1) 0
			}
		}
    catch{}
	Add-Node $TreeView.Nodes $_ $indexicon
	}
}
Function ping-computers($objcomputers)
{
Append-Richtextbox -Source "Ping" -Message "Testing-connection first" -MessageColor 'Blue'
$objcomputers2=@()
$count=0
	foreach($computername in $objcomputers)
	{
	If ($objcomputers.GetType().Name -match "Object"){$total=$objcomputers.length}else{$total=1}
	$percent=[int](($count/$total)*100)	
	Write-Progress -CurrentOperation "$percent% Completed ($count/$total)" -status "Pinging $computername" -Activity "PINGING" -PercentComplete $percent
	$count++
	$resultado = Test-Connection -ComputerName $computername -Count 1 -BufferSize 16 -quiet
		if ($resultado -eq $true)
		{
		$color="green"
		$objcomputers2+=$computername
		Append-Richtextbox -ComputerName $computername -Source "Test-connection" -Message "Online" -MessageColor 'green' -logfile 'test-connection.log'
		}
		else
		{
		$color="red"
		Append-Richtextbox -ComputerName $computername -Source "Test-connection" -Message "Offline" -MessageColor 'red' -logfile 'test-connection.log'
		}
		write-host "$computername " -fore $color -nonewline
	}
Write-Progress -Activity "PINGING" -Completed
return $objcomputers2
}
Function test-ports($objcomputers,$ports)
{
Append-Richtextbox -Source "Test-Ports" -Message "Testing-ports $($ports -join(',')) first" -MessageColor 'Blue'
$objcomputers2=@()
$count=0
	foreach($computername in $objcomputers)
	{
	If ($objcomputers.GetType().Name -match "Object"){$total=$objcomputers.length}else{$total=1}
	$percent=[int](($count/$total)*100)	
	Write-Progress -CurrentOperation "$percent% Completed ($count/$total)" -status "Testing $computername ports" -Activity "TESTING PORTS" -PercentComplete $percent
	$count++
	$color='green'
	$checkedports=""
		foreach ($port in $ports)
		{	
		$socket=New-Object system.net.Sockets.TcpClient
		$connect = $socket.BeginConnect($computername,$port,$null,$null)
		#Configure a timeout before quitting - time in milliseconds 
		$wait = $connect.AsyncWaitHandle.WaitOne(2000,$false) 
			If (-Not $Wait)
			{
			#timeout
			$color='red'
			$checkedports+="$port=timeout "
			} 
			Else
			{
				try
				{
				$socket.EndConnect($connect)
				#open
				$checkedports+="$port=open "
				}
				Catch [system.exception]{
				#closed
				$color='red'
				$checkedports+="$port=closed "
				}
			}
		}#fin foreach port
	if($color -eq 'green'){$objcomputers2+=$computername}
	Append-Richtextbox -ComputerName $computername -Source "Test-ports" -Message $checkedports -MessageColor $color -logfile 'test-ports.log'
	}
Write-Progress -Activity "TESTING PORTS" -Completed
return $objcomputers2
}
Function base64imagestring2image($base64ImageString)
{
$imageBytes = [Convert]::FromBase64String($base64ImageString)
$ms = New-Object IO.MemoryStream($imageBytes, 0, $imageBytes.Length)
$ms.Write($imageBytes, 0, $imageBytes.Length);
return [System.Drawing.Image]::FromStream($ms, $true)
}
### main ###
import-module "$PSScriptRoot\..\_Modules\MiCredentialModule"
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::loadwithpartialname("System.Drawing")
[System.Windows.Forms.Application]::EnableVisualStyles()
$treeSeparator="_"
'logs','results'|%{if(!(test-path "$PSScriptRoot\$_")){md "$PSScriptRoot\$_"}}
$css=[pscustomobject]@{
	labelcolor=[System.Drawing.Color]::WhiteSmoke
	formcolor=[System.Drawing.Color]::Gray
	tabcolor=[System.Drawing.Color]::White
	textfont= new-object System.Drawing.Font("Lucida Console",10)
	checkboxfont=new-object System.Drawing.Font("Calibri",8)
	richtextfont=new-object System.Drawing.Font("Lucida Console",10)
	}
#Formulario
$Form1 = New-Object System.Windows.Forms.Form
$Form1.ClientSize = new-object System.Drawing.Size(900, 525)
$Form1.text="SistemasWin | MiShell Deploy"
$Icon = [system.drawing.icon]::ExtractAssociatedIcon("$PSHOME\powershell.exe")
$Form1.Icon = $Icon
$Form1.backcolor=$css.formcolor
$Form1.WindowState = "Normal"    # Maximized, Minimized, Normal
$Form1.SizeGripStyle = "Hide"    # Auto, Hide, Show
$Form1.Add_Resize({
	#relocate all the objects
	$pictureBox.Location = new-object System.Drawing.Point(($Form1.ClientSize.width -155),10)
	$textboxobjects.Size = new-object System.Drawing.Size(160,($Form1.ClientSize.height -80))
	$tabControl1.Size = new-object System.Drawing.Size(300,($Form1.ClientSize.height -60))
	$TreeViewbat.Size = New-Object System.Drawing.Size(($tabControl1.size.width -20),($tabControl1.size.height -130))
	$buttonpsexec.Location = new-object System.Drawing.Point(5,($tabControl1.size.height -60))
	$buttonpsexec.Size = New-Object System.Drawing.Size(($tabControl1.size.width -20),22)
	$TreeViewps.Size = New-Object System.Drawing.Size(($tabControl1.size.width -20),($tabControl1.size.height -130))
	$buttonps.Location = new-object System.Drawing.Point(5,($tabControl1.size.height -60))
	$buttonps.Size = New-Object System.Drawing.Size(($tabControl1.size.width -20),22)
	$TreeViewtxt.Size = New-Object System.Drawing.Size(($tabControl1.size.width -20),($tabControl1.size.height -130))
	$buttonplink.Location = new-object System.Drawing.Point(5,($tabControl1.size.height -60))
	$buttonplink.Size = New-Object System.Drawing.Size(($tabControl1.size.width -20),22)
	$richtextbox.Size = new-object System.Drawing.Size(($Form1.ClientSize.Width -480),($Form1.ClientSize.height -91))
	$progressBar1.Location = new-object System.Drawing.Point(475,($Form1.ClientSize.height -15))
	$progressBar1.Size = new-object System.Drawing.Size(($Form1.ClientSize.Width -480),10)
})	
#Imagelist
$ImageList = new-Object System.Windows.Forms.ImageList
$ImageList.ImageSize=new-object System.Drawing.Size(16,16)
gci "$PSScriptRoot\ico\*.png"|%{
	$imagetxt = [System.Drawing.Image]::FromFile($_.fullname)
	$imageList.Images.Add("img",$imagetxt)
	}
#cabecera
$combocreds=New-Object System.Windows.Forms.ComboBox
$combocreds.Location = New-Object System.Drawing.Point(5,30)
$combocreds.Size = New-Object System.Drawing.Size(160,20) 
$combocreds.Name = "creds"
if(test-path "$PSScriptroot\creds"){$array=gci ("$PSScriptroot\creds\$($env:username)" + "_*.cred")|select @{l='basename';e={$_.basename -replace("$($env:username)_")}}|select -expand basename}
if ($array -eq $null){$array=""}
$combocreds.items.addrange($array)
	if($array.gettype().name -eq "Object[]"){$combocreds.text=$array[0]}
	else{$combocreds.text=$array}
$form1.Controls.Add($combocreds)
$labelcreds = New-Object System.Windows.Forms.Label
$labelcreds.Location = New-Object System.Drawing.Point(5,15)
$labelcreds.Size = New-Object System.Drawing.Size(135,20) 
$labelcreds.text = "Credentials"
$labelcreds.foreColor = $css.labelcolor
$form1.Controls.Add($labelcreds)

$pictureBox = new-object System.Windows.Forms.PictureBox
$pictureBox.Location = new-object System.Drawing.Point(($Form1.ClientSize.width -155),10)
$pictureBox.Size = new-object System.Drawing.Size(150,50)
$pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
$pictureBox.TabStop = $false
$base64logo="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"
$pictureBox.image=base64imagestring2image($base64logo)
$Form1.Controls.Add($pictureBox)
$buttonexplorer = New-Object System.Windows.Forms.Button
$buttonexplorer.Location = new-object System.Drawing.Point(146,55)
$buttonexplorer.Size = New-Object System.Drawing.Size(20,20)
$buttonexplorer.Font = $css_buttonery.font
$buttonexplorer.image=$ImageList.images[3] #file icon
$buttonexplorer.Add_Click({
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "txt (*.txt)| *.txt"
    $OpenFileDialog.ShowDialog() | Out-Null
    $textboxobjects.text=$textboxobjects.text + ((get-content $OpenFileDialog.filename) -join ("`n`r"))
	})
$form1.controls.add($buttonexplorer)
$textboxobjects = New-Object System.Windows.Forms.textbox
$textboxobjects.Location = new-object System.Drawing.Point(5,75)
$textboxobjects.Size = new-object System.Drawing.Size(160,($Form1.ClientSize.height -80))
$textboxobjects.Multiline =$true
$textboxobjects.scrollbars ='Vertical'
$textboxobjects.Font = $css.textfont
$textboxobjects.borderstyle = 2 #0=sin borde, 1=borde 2=hundido
$form1.controls.add($textboxobjects)
$labelobjects = New-Object System.Windows.Forms.Label
$labelobjects.Location = New-Object System.Drawing.Point(5,60)
$labelobjects.Size = New-Object System.Drawing.Size(135,20) 
$labelobjects.text = "Computers"
$labelobjects.foreColor = $css.labelcolor
$form1.Controls.Add($labelobjects)
# Create a group that will contain your radio buttons
$PredeployGroupBox = New-Object System.Windows.Forms.GroupBox
$PredeployGroupBox.Location = new-object System.Drawing.Point(170,15)
$PredeployGroupBox.size = new-object System.Drawing.Size(300,35)
$PredeployGroupBox.foreColor = $css.labelcolor
$PredeployGroupBox.text = "Pre-Deploy Options"
$form1.controls.add($PredeployGroupBox)
# Create the collection of radio buttons
$RadioButtonping = New-Object System.Windows.Forms.RadioButton
$RadioButtonping.Location = new-object System.Drawing.Point(5,15)
$RadioButtonping.size = New-Object System.Drawing.Size(110,17) 
$RadioButtonping.Checked = $true
$RadioButtonping.foreColor = $css.labelcolor
$RadioButtonping.Text = "test-connection"
$RadioButtonports = New-Object System.Windows.Forms.RadioButton
$RadioButtonports.Location = new-object System.Drawing.Point(120,15)
$RadioButtonports.size = New-Object System.Drawing.Size(80,17) 
$RadioButtonports.Checked = $false
$RadioButtonports.foreColor = $css.labelcolor
$RadioButtonports.Text = "test-ports"
$RadioButtonnothing = New-Object System.Windows.Forms.RadioButton
$RadioButtonnothing.Location = new-object System.Drawing.Point(210,15)
$RadioButtonnothing.size = New-Object System.Drawing.Size(85,17) 
$RadioButtonnothing.Checked = $false
$RadioButtonnothing.foreColor = $css.labelcolor
$RadioButtonnothing.Text = "test-nothing"
#Add radiobuttons to groupbox
$PredeployGroupBox.Controls.AddRange(@($RadioButtonping,$RadioButtonports,$RadioButtonnothing))
#Tabs
$tabControl1 = New-Object System.Windows.Forms.TabControl
$tabControl1.DataBindings.DefaultDataSourceUpdateMode = 0
$tabControl1.Location = new-object System.Drawing.Point(170,55)
$tabControl1.SelectedIndex = 0
$tabControl1.Size = new-object System.Drawing.Size(300,($Form1.ClientSize.height -60))
$tabControl1.TabIndex = 2
$tabControl1.Add_DoubleClick({
	$TreeViewbat.nodes.clear()
	fill-treeview "$psscriptroot\ScriptRepository\*.bat" $TreeViewbat
	$TreeViewps.nodes.clear()
	fill-treeview "$psscriptroot\ScriptRepository\*.ps1" $TreeViewps
	$TreeViewtxt.nodes.clear()
	fill-treeview "$psscriptroot\ScriptRepository\*.txt" $TreeViewtxt
	})
$form1.controls.add($tabControl1)
$tabPage1 = New-Object System.Windows.Forms.TabPage
$tabPage1.Text = "BAT with Psexec"
$tabPage1.BackColor = $css.tabcolor
$tabPage2 = New-Object System.Windows.Forms.TabPage
$tabPage2.Text = "PS1 Scripts"
$tabPage2.BackColor = $css.tabcolor
$tabPage3 = New-Object System.Windows.Forms.TabPage
$tabPage3.Text = "TXT with Plink"
$tabPage3.BackColor = $css.tabcolor
#Add Tabs to tabcontrol
$tabControl1.Controls.AddRange(@($tabPage1,$tabPage2,$tabpage3))

####TAB 1 CONTENT (PSEXEC)
$checkBoxElevated = New-Object System.Windows.Forms.CheckBox
$checkBoxElevated.checked=$true
$checkBoxElevated.Location = New-Object System.Drawing.Point(5,15) 
$checkBoxElevated.Size = New-Object System.Drawing.Size(65,20)
$checkBoxElevated.text="Elevated"
$checkBoxElevated.Font = $css.checkboxfont
$checkBoxSystem = New-Object System.Windows.Forms.CheckBox
$checkBoxSystem.Location = New-Object System.Drawing.Point(70,15) 
$checkBoxSystem.Size = New-Object System.Drawing.Size(65,20)
$checkBoxSystem.text="System"
$checkBoxSystem.Font = $css.checkboxfont
$checkBoxDontwait = New-Object System.Windows.Forms.CheckBox
$checkBoxDontwait.checked=$true
$checkBoxDontwait.Location = New-Object System.Drawing.Point(135,15) 
$checkBoxDontwait.Size = New-Object System.Drawing.Size(75,20)
$checkBoxDontwait.text="Don't wait"
$checkBoxDontwait.Font = $css.checkboxfont
$checkBoxinteractive = New-Object System.Windows.Forms.CheckBox
$checkBoxinteractive.Location = New-Object System.Drawing.Point(210,15) 
$checkBoxinteractive.Size = New-Object System.Drawing.Size(75,20)
$checkBoxinteractive.text="Interactive"
$checkBoxinteractive.Font = $css.checkboxfont
$tabPage1.Controls.Addrange(@($checkBoxElevated,$checkBoxSystem,$checkBoxDontwait,$checkBoxinteractive))
$TreeViewbat = New-Object Windows.Forms.TreeView
$TreeViewbat.name="BAT"
$TreeViewbat.PathSeparator = $treeSeparator
$TreeViewbat.Location = New-Object System.Drawing.Point(5,45) 
$TreeViewbat.Size = New-Object System.Drawing.Size(($tabControl1.size.width -20),($tabControl1.size.height -130))
$TreeViewbat.borderstyle = 0 #0=sin borde, 2=borde 1=hundido
$TreeViewbat.BackColor = $css.tabcolor
$TreeViewbat.imagelist = $imageList
$treeviewbat.Hideselection=$false
$tabPage1.Controls.Add($TreeViewbat)
fill-treeview "$psscriptroot\ScriptRepository\*.bat" $TreeViewbat
$TreeViewbat.Add_AfterSelect({
	$script:batfilebasename=$_.Node.Text
	$script:batfilefullname="$psscriptroot\ScriptRepository\$($_.Node.FULLPATH).bat"
	})
$buttonpsexec = New-Object System.Windows.Forms.Button
$buttonpsexec.Location = new-object System.Drawing.Point(5,($tabControl1.size.height -60))
$buttonpsexec.Size = New-Object System.Drawing.Size(($tabControl1.size.width -20),22)
$buttonpsexec.Font = $css_buttonery.font
$buttonpsexec.text="Deploy with Psexec"
$tabPage1.controls.add($buttonpsexec)
$buttonpsexec.Add_Click({
	$scope=$combocreds.text
	if($scope -ne '')
	{
	$credsplain=select-MiCredential -scope $scope -plain
	Append-Richtextbox -Source "Credentials" -Message "Using $($combocreds.text) ($($credsplain.username))" -MessageColor 'Blue' -logfile 'psexec.log'
	}
	else
	{
	$identity=([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).identities.name
	Append-Richtextbox -Source "Credentials" -Message "Using Current Credentials ($identity)" -MessageColor 'Blue' -logfile 'psexec.log'
	}
	
	$objcomputers=$textboxobjects.text.Split("`n`r") -replace "`#.*", "$([char]0)" -replace "#.*" -replace "$([char]0)", "#" -replace "^\s*" -replace "\s*$"|?{$_;}
	if($RadioButtonping.Checked){$objcomputers=ping-computers $objcomputers}
	elseif($RadioButtonports.Checked){$objcomputers=test-ports $objcomputers (139,445)}

	if ($objcomputers.length -ne 0 -and (test-path $batfilefullname))
	{
		$count=$progressBar1.Value=0
		If($objcomputers.GetType().Name -match "Object"){$progressBar1.Maximum=$total=$objcomputers.length}else{$progressBar1.Maximum=$total=1}

				foreach ($computername in $objcomputers)
				{
				$percent=[int](($count/$total)*100)
				Write-Progress -CurrentOperation "$percent% Completed ($count/$total)" -status "Deploying $batfilebasename to $computername with psexec" -activity "DEPLOYING BAT's" -PercentComplete $percent
				$count++
				write-host "`n$computername : Deploying $batfilebasename..." -fore magenta
				$params=""
				if ($checkBoxElevated.checked){$params+=" -h"}
				if ($checkBoxSystem.checked){$params+=" -s"}
				if ($checkBoxDontwait.checked){$params+=" -d"}
				if ($checkBoxinteractive.checked){$params+=" -i"}					
				$cmdkeyadd="cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
				if ($scope -ne ''){$psexeccommand="$psscriptroot\..\_bin\psexec.exe \\{0} -accepteula -v -n 10 -u {1} -p '{2}' {3} -c '{4}'" -f $computername,$credsplain.username,$credsplain.password,$params,$batfilefullname}
				else{$psexeccommand="$psscriptroot\..\_bin\psexec.exe \\{0} -accepteula -v -n 10 {1} -c '{2}'" -f $computername,$params,$batfilefullname}
				$cmdkeydelete="cmdkey.exe /delete:" + $computername
				if ($scope -ne ''){invoke-expression $cmdkeyadd}
				invoke-expression $psexeccommand				
				$msg="{0}: exitcode:{1} executing:{2} with params:{3}" -f $computername,$lastexitcode,$batfilebasename,$params
				if($lastexitcode -in (5,6,50,53,122,1311,1326,2250)){$color='red'}else{$color='green'}
				Append-Richtextbox -ComputerName $computername -Source "Psexec" -Message $msg -MessageColor $color -logfile 'psexec.log'
				if ($scope -ne ''){invoke-expression $cmdkeydelete}
				write-host $raya -fore magenta
				$progressBar1.PerformStep()
				}
		Write-Progress -Activity "DEPLOYING BAT'S" -Completed
		write-host "END OF DEPLOYMENT" -fore magenta
	}
})
####TAB 2 CONTENT (PS1)
$TreeViewps = New-Object Windows.Forms.TreeView
$TreeViewps.name="PS"
$TreeViewps.PathSeparator = $treeSeparator
$TreeViewps.Location = New-Object System.Drawing.Point(5,15) 
$TreeViewps.Size = New-Object System.Drawing.Size(($tabControl1.size.width -20),($tabControl1.size.height -100))
$TreeViewps.borderstyle = 0 #0=sin borde, 2=borde 1=hundido
$TreeViewps.BackColor = $css.tabcolor
$TreeViewps.imagelist = $imageList
$TreeViewps.Hideselection=$false
$tabPage2.Controls.Add($TreeViewps)
fill-treeview "$psscriptroot\ScriptRepository\*.ps1" $TreeViewps
$TreeViewps.Add_AfterSelect({
	$script:ps1filebasename=$_.Node.Text
	$script:ps1filefullname="$psscriptroot\ScriptRepository\$($_.Node.FULLPATH).ps1"
	})
$buttonps = New-Object System.Windows.Forms.Button
$buttonps.Location = new-object System.Drawing.Point(5,($tabControl1.size.height -60))
$buttonps.Size = New-Object System.Drawing.Size(($tabControl1.size.width -20),22)
$buttonps.Font = $css_buttonery.font
$buttonps.text="Run PS1"
$tabPage2.controls.add($buttonps)
$buttonps.Add_Click({
	$scope=$combocreds.text
	if($scope -ne '')
	{
	$creds=select-MiCredential -scope $scope
	Append-Richtextbox -Source "Credentials" -Message "Using $($combocreds.text) ($($creds.username))" -MessageColor 'Blue' -logfile 'ps1command.log'
	}
	else
	{
	$identity=([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).identities.name
	Append-Richtextbox -Source "Credentials" -Message "Using Current Credentials ($identity)" -MessageColor 'Blue' -logfile 'ps1command.log'
	}
	
	$objcomputers=$textboxobjects.text.Split("`n`r") -replace "`#.*", "$([char]0)" -replace "#.*" -replace "$([char]0)", "#" -replace "^\s*" -replace "\s*$"|?{$_;}
	if($RadioButtonping.Checked){$objcomputers=ping-computers $objcomputers}
	elseif($RadioButtonports.Checked){$objcomputers=test-ports $objcomputers (139,445,5985,5986)}

	if ($objcomputers.length -ne 0 -and (test-path $ps1filefullname))
	{
		$count=$progressBar1.Value=0
		If($objcomputers.GetType().Name -match "Object"){$progressBar1.Maximum=$total=$objcomputers.length}else{$progressBar1.Maximum=$total=1}
				foreach ($computername in $objcomputers)
				{
				$percent=[int](($count/$total)*100)
				Write-Progress -CurrentOperation "$percent% Completed ($count/$total)" -status "Running $ps1filebasename to $computername" -activity "RUNNING PS1'S" -PercentComplete $percent
				$count++
				write-host "`n$computername : Running $ps1filebasename..." -fore cyan
				Append-Richtextbox -ComputerName $computername -Source "ps1command" -Message "Running $ps1filebasename" -MessageColor 'blue' -logfile 'ps1command.log'
				#$result=invoke-command -computername $computername -credential $creds -filepath  $ps1filefullname
				. $ps1filefullname
				$progressBar1.PerformStep()
				}
		Write-Progress -Activity "RUNNING PS1'S" -Completed
		write-host "END OF DEPLOYMENT" -fore cyan
	}
})
###TAB 3 CONTENT (TXT WITH Plink)
$TreeViewtxt = New-Object Windows.Forms.TreeView
$TreeViewtxt.name="TXT"
$TreeViewtxt.PathSeparator = $treeSeparator
$TreeViewtxt.Location = New-Object System.Drawing.Point(5,45) 
$TreeViewtxt.Size = New-Object System.Drawing.Size(($tabControl1.size.width -20),($tabControl1.size.height -130))
$TreeViewtxt.borderstyle = 0 #0=sin borde, 2=borde 1=hundido
$TreeViewtxt.BackColor = $css.tabcolor
$TreeViewtxt.imagelist = $imageList
$TreeViewtxt.Hideselection=$false
$tabPage3.Controls.Add($TreeViewtxt)
fill-treeview "$psscriptroot\ScriptRepository\*.txt" $TreeViewtxt
$TreeViewtxt.Add_AfterSelect({
	$script:txtfilebasename=$_.Node.Text
	$script:txtfilefullname="$psscriptroot\ScriptRepository\$($_.Node.FULLPATH).txt"
	})
$buttonplink = New-Object System.Windows.Forms.Button
$buttonplink.Location = new-object System.Drawing.Point(5,($tabControl1.size.height -60))
$buttonplink.Size = New-Object System.Drawing.Size(($tabControl1.size.width -20),22)
$buttonplink.Font = $css_buttonery.font
$buttonplink.text="Deploy with Plink"
$tabPage3.controls.add($buttonplink)
$buttonplink.Add_Click({
	$scope=$combocreds.text
	if($scope -ne '')
	{
	$credsplain=select-MiCredential -scope $scope -plain
	Append-Richtextbox -Source "Credentials" -Message "Using $($combocreds.text) ($($credsplain.username))" -MessageColor 'Blue' -logfile 'plink.log'
	}
	else
	{
	$identity=([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).identities.name
	Append-Richtextbox -Source "Credentials" -Message "Using Current Credentials ($identity)" -MessageColor 'Blue' -logfile 'plink.log'
	}
	
	$objcomputers=$textboxobjects.text.Split("`n`r") -replace "`#.*", "$([char]0)" -replace "#.*" -replace "$([char]0)", "#" -replace "^\s*" -replace "\s*$"|?{$_;}
	if($RadioButtonping.Checked){$objcomputers=ping-computers $objcomputers}
	elseif($RadioButtonports.Checked){$objcomputers=test-ports $objcomputers 22}

	if ($objcomputers.length -ne 0 -and (test-path $txtfilefullname))
	{
		$count=$progressBar1.Value=0
		If($objcomputers.GetType().Name -match "Object"){$progressBar1.Maximum=$total=$objcomputers.length}else{$progressBar1.Maximum=$total=1}

				foreach ($computername in $objcomputers)
				{
				$percent=[int](($count/$total)*100)
				Write-Progress -CurrentOperation "$percent% Completed ($count/$total)" -status "Deploying $txtfilebasename to $computername with plink" -activity "DEPLOYING TXT's" -PercentComplete $percent
				$count++
				write-host "`n$computername : Deploying $txtfilebasename..." -fore yellow				
				if ($scope -ne '')
				{
				$plinkcommand="$psscriptroot\..\_bin\plink.exe -v {1}@{0} -pw '{2}' -m '{3}' >> 'Results\{4}.txt'" -f $computername,$credsplain.username,$credsplain.password,$txtfilefullname,$txtfilebasename
				invoke-expression $plinkcommand				
				$msg="{0}: exitcode:{1} executing:{2}" -f $computername,$lastexitcode,$txtfilebasename
				if($lastexitcode -eq 1){$color='red'}else{$color='green'}
				Append-Richtextbox -ComputerName $computername -Source "Plink" -Message $msg -MessageColor $color -logfile 'plink.log'
				}
				else{Append-Richtextbox -ComputerName $computername -Source "Plink" -Message "Please supply proper credentials" -MessageColor 'red' -logfile 'plink.log'}
				write-host $raya -fore yellow
				$progressBar1.PerformStep()
				}
		Write-Progress -Activity "DEPLOYING TXT'S" -Completed
		write-host "END OF DEPLOYMENT" -fore yellow
	}
})

$richtextbox = New-Object System.Windows.Forms.RichTextBox
$richtextbox.Location = new-object System.Drawing.Point(475,75)
$richtextbox.Size = new-object System.Drawing.Size(($Form1.ClientSize.Width -480),($Form1.ClientSize.height -91))
$richtextbox.Multiline =$true
$richtextbox.scrollbars ='Vertical'
$richtextbox.Font = $css.richtextfont
$richtextbox.borderstyle = 0 #0=sin borde, 1=borde 2=hundido
$form1.controls.add($richtextbox)
#ProgressBar
$progressBar1 = New-Object System.Windows.Forms.ProgressBar
$progressBar1.DataBindings.DefaultDataSourceUpdateMode = 0
$progressBar1.Location = new-object System.Drawing.Point(475,($Form1.ClientSize.height -15))
$progressBar1.Size = new-object System.Drawing.Size(($Form1.ClientSize.Width -480),10)
$progressBar1.Step = 1
$progressBar1.TabIndex = 0
$progressBar1.Style = 1
$Form1.Controls.Add($progressBar1)
#muestro el formulario
write-host ''
write-host '  8888888P.                    888'
write-host '  888   d88P                   888'
write-host '  888    888                   888'
write-host '  888    888 ,A8888A, 88888Y,  888 ,A8888A, 888  888'
write-host '  888    888 888  888 888 788Y 888 888  888 888  888'
write-host '  888    888 888888Y" 888  888 888 888  888 888  888'
write-host '  888  ,Y88b 888      888  888 888 888  888 Y88b 888'
write-host '  8888888K"  "Y8888Y" 888888Y" 888 "Y8888Y"  "Y88888'
write-host '                      888                       "888'
write-host '                      888                       .888'
write-host '                      888                    8888P" '
[System.Windows.Forms.Application]::Run($Form1)
