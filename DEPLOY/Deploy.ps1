#MiShell DEPLOY
#GUI for runnning remote batches/scripts
#Mikel V.
#2017/06/01
function Append-Richtextbox {
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$Message,
		[string]$MessageColor = $css.richtextcolor2,
		[string]$DateTimeColor = $css.richtextcolor1,
		[string]$Source,
		[string]$SourceColor = $css.richtextcolor1,
		[string]$ComputerName,
		[String]$ComputerNameColor = $css.richtextcolorcomputer,
		[String]$logfile)

	$Sortabledate = get-date -Format "yyyy/MM/dd HH:mm:ss"
	$SortableTime = get-date -Format "HH:mm:ss"
	$richtextbox.SelectionColor = $DateTimeColor
	$richtextbox.AppendText("$SortableTime ")

	IF ($PSBoundParameters['ComputerName']) {
		$richtextbox.SelectionColor = $ComputerNameColor
		$richtextbox.AppendText(("$ComputerName ").ToUpper())
	}

	IF ($PSBoundParameters['Source']) {
		$richtextbox.SelectionColor = $SourceColor
		$richtextbox.AppendText("$Source ")
	}

	$richtextbox.SelectionColor = $MessageColor
	$richtextbox.AppendText("$Message`r")
	$richtextbox.Refresh()
	$richtextbox.ScrollToCaret()

	Write-Verbose -Message "$Sortabledate $ComputerName $Message"
	IF ($PSBoundParameters['logfile']) {
		out-file "$psscriptroot\logs\$logfile" -input "$Sortabledate $ComputerName $Message" -append -enc ascii
	}
}
Function Add-Node($Nodes, $Path, $icon, $tag) {
	$Path.Split($treeSeparator)| % {
		Write-Verbose "Searching For: $_"
		$SearchResult = $Nodes.Find($_, $False)
		If ($SearchResult.Count -eq 1) {
			Write-Verbose "Selecting: $($SearchResult.Name)"
			# Must select first element. Return from Find is TreeNode[]
			$Nodes = $SearchResult[0].Nodes
		}
		Else {
			Write-Verbose "Adding: $_"
			$Node = New-Object Windows.Forms.TreeNode($_)
			# Name must be populated for Find work
			$Node.Name = $_
			$Node.imageindex = $icon
			$Node.SelectedImageIndex = $icon
			$node.tag = $tag
			$Nodes.Add($Node)|out-null

		}
	}
}
Function fill-TreeView($scriptsrepository, $treeview) {
	$TreeView.nodes.clear()

	gci $scriptsrepository -include *.ps1, *.bat, *.cmd, *.txt|select basename, extension| % {
		try {
			$tag = $_.extension
			switch ($_.extension) {
				".BAT" {$indexicon = 1}
				".CMD" {$indexicon = 1}
				".PS1" {$indexicon = 2}
				".TXT" {$indexicon = 3}
			}
			$fullnodexceptlast = $_.basename.substring(0, $_.basename.lastindexof($treeSeparator))
			$fullnode = ""
			foreach ($node in $fullnodexceptlast.split($treeSeparator)) {
				$fullnode += "$treeSeparator$node"
				Add-Node $TreeView.Nodes $fullnode.substring(1) 0 #remove first character when adding the node (it is always a separator)
			}
		}
		catch {}
		Add-Node $TreeView.Nodes $_.basename $indexicon $tag
	}
}
Function ping-computers($objcomputers) {
	Append-Richtextbox -Source "Test-connection" -Message "Testing-connection first"
	$objcomputers2 = @()
	$count = 0
	foreach ($computername in $objcomputers) {
		If ($objcomputers.GetType().Name -match "Object") {$total = $objcomputers.length}else {$total = 1}
		$percent = [int](($count / $total) * 100)
		Write-Progress -Activity "PINGING" -CurrentOperation "Pinging $computername" -status "$percent% Completed ($count/$total)" -PercentComplete $percent
		$count++
		$resultado = Test-Connection -ComputerName $computername -Count 1 -BufferSize 16 -quiet
		if ($resultado -eq $true) {
			$color = "green"
			$objcomputers2 += $computername
			Append-Richtextbox -ComputerName $computername -Source "Test-connection" -Message "Online" -MessageColor $css.richtextcolorOK -logfile 'test-connection.log'
		}
		else {
			$color = "red"
			Append-Richtextbox -ComputerName $computername -Source "Test-connection" -Message "Offline" -MessageColor $css.richtextcolorERR -logfile 'test-connection.log'
		}
		write-host "$computername " -fore $color -nonewline
	}
	Write-Progress -Activity "PINGING" -Completed
	return $objcomputers2
}
Function test-ports($objcomputers, $ports) {
	Append-Richtextbox -Source "Test-Ports" -Message "Test-ports $($ports -join(',')) first"
	$objcomputers2 = @()
	$count = 0
	foreach ($computername in $objcomputers) {
		If ($objcomputers.GetType().Name -match "Object") {$total = $objcomputers.length}else {$total = 1}
		$percent = [int](($count / $total) * 100)
		Write-Progress -Activity "TESTING PORTS" -CurrentOperation "Testing $computername ports" -status "$percent% Completed ($count/$total)" -PercentComplete $percent
		$count++
		$color = $css.richtextcolorOK
		$checkedports = ""
		foreach ($port in $ports) {
			$socket = New-Object system.net.Sockets.TcpClient
			$connect = $socket.BeginConnect($computername, $port, $null, $null)
			#Configure a timeout before quitting - time in milliseconds
			$wait = $connect.AsyncWaitHandle.WaitOne(2000, $false)
			If (-Not $Wait) {
				#timeout
				$color = 'gray'
				$checkedports += "$port=timeout "
			}
			Else {
				try {
					$socket.EndConnect($connect)
					#open
					$checkedports += "$port=open "
				}
				Catch [system.exception] {
					#closed
					$color = $css.richtextcolorERR
					$checkedports += "$port=closed "
				}
			}
		}#fin foreach port
		if ($color -eq $css.richtextcolorOK) {$objcomputers2 += $computername}
		Append-Richtextbox -ComputerName $computername -Source "Test-ports" -Message $checkedports -MessageColor $color -logfile 'test-ports.log'
	}
	Write-Progress -Activity "TESTING PORTS" -Completed
	return $objcomputers2
}
### main ###
import-module "$PSScriptRoot\..\_Modules\MiCredentialModule"
$identity = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).identities.name
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::loadwithpartialname("System.Drawing")
[System.Windows.Forms.Application]::EnableVisualStyles()
#set random style
$cssfiles = Get-ChildItem "$PSScriptRoot\css\*.ps1"|select -expand fullname
$cssfile = get-random -input $cssfiles
. $cssfile
$treeSeparator = "_"
'Logs', 'Results'| % {if (!(test-path "$PSScriptRoot\$_")) {md "$PSScriptRoot\$_"|out-null}}

#Formulario
$Form1 = New-Object System.Windows.Forms.Form
$Form1.ClientSize = new-object System.Drawing.Size(900, 575)
$Form1.text = "SistemasWin | MiShell Deploy | $identity"
$Form1.Icon = New-Object system.drawing.icon ("$PSScriptRoot\ico\rocket.ico")
$Form1.backcolor = $css.formcolor
$Form1.WindowState = "Normal"    # Maximized, Minimized, Normal
$Form1.SizeGripStyle = "Hide"    # Auto, Hide, Show
$Form1.Add_Resize( {
		#relocate all the objects
		$TreeViewscripts.Size = New-Object System.Drawing.Size(300, ($form1.Clientsize.height - 145))
		$buttonopenrepo.Location = new-object System.Drawing.Point(0, ($form1.clientsize.height - 20))
		$buttonopenlogs.Location = new-object System.Drawing.Point(100, ($form1.clientsize.height - 20))
		$buttonopenresults.Location = new-object System.Drawing.Point(150, ($form1.clientsize.height - 20))
		$buttonrefresh.Location = new-object System.Drawing.Point(210, ($form1.clientsize.height - 20))
		$textboxobjects.Size = new-object System.Drawing.Size(160, ($Form1.ClientSize.height - 270))
		$labelcreds.Location = New-Object System.Drawing.Point($textboxobjects.Location.X, ($textboxobjects.Location.Y + $textboxobjects.Size.height))
		$combocreds.Location = New-Object System.Drawing.Point($labelcreds.Location.X, ($labelcreds.Location.Y + 15))
		$PredeployGroupBox.Location = new-object System.Drawing.Point($combocreds.Location.X, ($combocreds.location.Y + 25))
		$tabControl1.Location = new-object System.Drawing.Point($PredeployGroupBox.Location.X, ($PredeployGroupBox.Location.Y + $PredeployGroupBox.size.height + 5))
		$richtextbox.Size = new-object System.Drawing.Size(($Form1.ClientSize.Width - 475), ($Form1.ClientSize.height - 10))
		$progressBar1.Location = new-object System.Drawing.Point($richtextbox.Location.X, ($Form1.ClientSize.height - 10))
		$progressBar1.Size = new-object System.Drawing.Size($richtextbox.size.Width, 10)
	})
#Imagelist
$ImageList = new-Object System.Windows.Forms.ImageList
$ImageList.ImageSize = new-object System.Drawing.Size(16, 16)
get-childitem -path "$PSScriptRoot\ico\*.png"|? {$_.basename -match "^\d{1}$"}| % {
	$imagetxt = [System.Drawing.Image]::FromFile($_.fullname)
	$imageList.Images.Add("img", $imagetxt)
}
#cabecera
$pictureBox = new-object System.Windows.Forms.PictureBox
$pictureBox.Location = new-object System.Drawing.Point(0, 0)
$pictureBox.Size = new-object System.Drawing.Size(300, 124)
$pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
$pictureBox.TabStop = $false
$pictureBox.Load("$psscriptroot\ico\DeployRocket.png")
$Form1.Controls.Add($pictureBox)
$TreeViewscripts = New-Object Windows.Forms.TreeView
$TreeViewscripts.PathSeparator = $treeSeparator
$TreeViewscripts.Location = New-Object System.Drawing.Point(5, 125)
$TreeViewscripts.Size = New-Object System.Drawing.Size(300, ($form1.Clientsize.height - 145))
$TreeViewscripts.borderstyle = 0 #0=sin borde, 2=borde 1=hundido
$TreeViewscripts.BackColor = $css.formcolor
$TreeViewscripts.forecolor = $css.textcolor
$TreeViewscripts.imagelist = $imageList
$TreeViewscripts.Hideselection = $false
$form1.Controls.Add($TreeViewscripts)
fill-treeview "$psscriptroot\ScriptRepository\*" $TreeViewscripts
$TreeViewscripts.Add_AfterSelect( {
		$script:scriptfilebasename = $_.Node.Text
		$script:scriptfilefullname = '{0}\ScriptRepository\{1}{2}' -f $psscriptroot, $_.Node.fullpath, $_.node.tag
		$buttonpsexec.enabled = $buttonps.enabled = $buttonplink.enabled = $false
		switch ($_.node.tag) {
			".BAT" {$tabControl1.selectedtab = $tabPage1; $buttonpsexec.enabled = $true}
			".CMD" {$tabControl1.selectedtab = $tabPage1; $buttonpsexec.enabled = $true}
			".PS1" {
				$tabControl1.selectedtab = $tabPage2
				$buttonps.enabled = $true
				if ($scriptfilebasename -match "RunAs") {$PwshGroupBox.controls[1].Checked = $true}
				else {$PwshGroupBox.controls[0].Checked = $true}
			}
			".TXT" {$tabControl1.selectedtab = $tabPage3; $buttonplink.enabled = $true}
		}

	})
$buttonopenrepo = New-Object System.Windows.Forms.Button
$buttonopenrepo.Location = new-object System.Drawing.Point(0, ($form1.clientsize.height - 20))
$buttonopenrepo.Size = New-Object System.Drawing.Size(100, 20)
$buttonopenrepo.font = $css.smallfont
$buttonopenrepo.flatstyle = "System"
$buttonopenrepo.text = "ScriptRepository"
$buttonopenrepo.Add_Click( {
		Invoke-Item "$PSScriptRoot\ScriptRepository"
	})
$form1.controls.add($buttonopenrepo)
$buttonopenlogs = New-Object System.Windows.Forms.Button
$buttonopenlogs.Location = new-object System.Drawing.Point(100, ($form1.clientsize.height - 20))
$buttonopenlogs.Size = New-Object System.Drawing.Size(50, 20)
$buttonopenlogs.font = $css.smallfont
$buttonopenlogs.flatstyle = "System"
$buttonopenlogs.text = "Logs"
$buttonopenlogs.Add_Click( {
		Invoke-Item "$PSScriptRoot\Logs"
	})
$form1.controls.add($buttonopenlogs)
$buttonopenresults = New-Object System.Windows.Forms.Button
$buttonopenresults.Location = new-object System.Drawing.Point(150, ($form1.clientsize.height - 20))
$buttonopenresults.Size = New-Object System.Drawing.Size(60, 20)
$buttonopenresults.font = $css.smallfont
$buttonopenresults.flatstyle = "System"
$buttonopenresults.text = "Results"
$buttonopenresults.Add_Click( {
		Invoke-Item "$PSScriptRoot\Results"
	})
$form1.controls.add($buttonopenresults)
$buttonrefresh = New-Object System.Windows.Forms.Button
$buttonrefresh.Location = new-object System.Drawing.Point(210, ($form1.clientsize.height - 20))
$buttonrefresh.Size = New-Object System.Drawing.Size(97, 20)
$buttonrefresh.font = $css.smallfont
$buttonrefresh.flatstyle = "System"
$buttonrefresh.text = "Refresh Treeview"
$buttonrefresh.Add_Click( {
		fill-treeview "$psscriptroot\ScriptRepository\*" $TreeViewscripts
	})
$form1.controls.add($buttonrefresh)
$labelobjects = New-Object System.Windows.Forms.Label
$labelobjects.Location = New-Object System.Drawing.Point(310, 5)
$labelobjects.Size = New-Object System.Drawing.Size(100, 15)
$labelobjects.text = "Computers"
$labelobjects.foreColor = $css.textcolor
$form1.Controls.Add($labelobjects)
$buttonexplorer = New-Object System.Windows.Forms.Button
$buttonexplorer.Location = new-object System.Drawing.Point(450, 0)
$buttonexplorer.Size = New-Object System.Drawing.Size(20, 20)
$buttonexplorer.flatstyle = 'flat'
$buttonexplorer.backcolor = $css.tabcolor
$buttonexplorer.image = $ImageList.images[3] #file icon
$buttonexplorer.Add_Click( {
		$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
		$OpenFileDialog.initialDirectory = $PSScriptroot
		$OpenFileDialog.filter = "txt (*.txt)| *.txt"
		$OpenFileDialog.ShowDialog() | Out-Null
		if ($OpenFileDialog.FileName) {$textboxobjects.text = $textboxobjects.text + ((get-content $OpenFileDialog.filename) -join ("`n`r"))}
	})
$form1.controls.add($buttonexplorer)
$textboxobjects = New-Object System.Windows.Forms.textbox
$textboxobjects.Location = new-object System.Drawing.Point($labelobjects.Location.X, ($labelobjects.Location.Y + 15))
$textboxobjects.Size = new-object System.Drawing.Size(160, ($Form1.ClientSize.height - 270))
$textboxobjects.Multiline = $true
$textboxobjects.scrollbars = 'Vertical'
$textboxobjects.Font = $css.textfont
$textboxobjects.borderstyle = 2 #0=sin borde, 1=borde 2=hundido
$form1.controls.add($textboxobjects)
$labelcreds = New-Object System.Windows.Forms.Label
$labelcreds.Location = New-Object System.Drawing.Point($textboxobjects.Location.X, ($textboxobjects.Location.Y + $textboxobjects.Size.height))
$labelcreds.Size = New-Object System.Drawing.Size(135, 15)
$labelcreds.text = "Credentials"
$labelcreds.foreColor = $css.textcolor
$form1.Controls.Add($labelcreds)
$combocreds = New-Object System.Windows.Forms.ComboBox
$combocreds.Location = New-Object System.Drawing.Point($labelcreds.Location.X, ($labelcreds.Location.Y + 15))
$combocreds.Size = New-Object System.Drawing.Size(160, 20)
$combocreds.Name = "creds"
if (test-path "$PSScriptroot\creds") {$array = gci ("$PSScriptroot\creds\$($env:username)" + "_*.cred")|select @{l = 'basename'; e = {$_.basename -replace ("$($env:username)_")}}|select -expand basename
}
if ($array -eq $null) {$array = ""}
$combocreds.items.addrange($array)
if ($array.gettype().name -eq "Object[]") {$combocreds.text = $array[0]}
else {$combocreds.text = $array}
$form1.Controls.Add($combocreds)
#Create a group that will contain your radio buttons
$PredeployGroupBox = New-Object System.Windows.Forms.GroupBox
$PredeployGroupBox.size = new-object System.Drawing.Size(160, 80)
$PredeployGroupBox.Location = new-object System.Drawing.Point($combocreds.Location.X, ($combocreds.location.Y + 25))
$PredeployGroupBox.foreColor = $css.textcolor
$PredeployGroupBox.text = "Pre-Deploy Options"
$form1.controls.add($PredeployGroupBox)
# Create the collection of radio buttons
$RadioButtonping = New-Object System.Windows.Forms.RadioButton
$RadioButtonping.Location = new-object System.Drawing.Point(5, 15)
$RadioButtonping.size = New-Object System.Drawing.Size(110, 17)
$RadioButtonping.Checked = $true
$RadioButtonping.foreColor = $css.textcolor
$RadioButtonping.Text = "test-connection"
$RadioButtonports = New-Object System.Windows.Forms.RadioButton
$RadioButtonports.Location = new-object System.Drawing.Point(5, 35)
$RadioButtonports.size = New-Object System.Drawing.Size(80, 17)
$RadioButtonports.Checked = $false
$RadioButtonports.foreColor = $css.textcolor
$RadioButtonports.Text = "test-ports"
$RadioButtonnothing = New-Object System.Windows.Forms.RadioButton
$RadioButtonnothing.Location = new-object System.Drawing.Point(5, 55)
$RadioButtonnothing.size = New-Object System.Drawing.Size(85, 17)
$RadioButtonnothing.Checked = $false
$RadioButtonnothing.foreColor = $css.textcolor
$RadioButtonnothing.Text = "test-nothing"
#Add radiobuttons to groupbox
$PredeployGroupBox.Controls.AddRange(@($RadioButtonping, $RadioButtonports, $RadioButtonnothing))
#Tabs
$tabControl1 = New-Object System.Windows.Forms.TabControl
$tabControl1.DataBindings.DefaultDataSourceUpdateMode = 0
$tabControl1.Size = new-object System.Drawing.Size(160, 123)
$tabControl1.Location = new-object System.Drawing.Point($PredeployGroupBox.Location.X, ($PredeployGroupBox.Location.Y + $PredeployGroupBox.size.height + 5))
$tabControl1.SelectedIndex = 0
$tabControl1.TabIndex = 1
$form1.controls.add($tabControl1)
$tabPage1 = New-Object System.Windows.Forms.TabPage
$tabPage1.Text = "psexec"
$tabPage1.BackColor = $css.tabcolor
$tabPage2 = New-Object System.Windows.Forms.TabPage
$tabPage2.Text = "pwsh"
$tabPage2.BackColor = $css.tabcolor
$tabPage3 = New-Object System.Windows.Forms.TabPage
$tabPage3.Text = "plink"
$tabPage3.BackColor = $css.tabcolor
#Add Tabs to tabcontrol
$tabControl1.Controls.AddRange(@($tabPage1, $tabPage2, $tabpage3))
####TAB 1 CONTENT (PSEXEC)
$checkBoxElevated = New-Object System.Windows.Forms.CheckBox
$checkBoxElevated.checked = $true
$checkBoxElevated.Location = New-Object System.Drawing.Point(5, 15)
$checkBoxElevated.Size = New-Object System.Drawing.Size(65, 15)
$checkBoxElevated.text = "Elevated"
$checkBoxElevated.Font = $css.smallfont
$checkBoxSystem = New-Object System.Windows.Forms.CheckBox
$checkBoxSystem.Location = New-Object System.Drawing.Point(80, 15)
$checkBoxSystem.Size = New-Object System.Drawing.Size(65, 15)
$checkBoxSystem.text = "System"
$checkBoxSystem.Font = $css.smallfont
$checkBoxDontwait = New-Object System.Windows.Forms.CheckBox
$checkBoxDontwait.checked = $true
$checkBoxDontwait.Location = New-Object System.Drawing.Point(5, 30)
$checkBoxDontwait.Size = New-Object System.Drawing.Size(75, 15)
$checkBoxDontwait.text = "Don't wait"
$checkBoxDontwait.Font = $css.smallfont
$checkBoxinteractive = New-Object System.Windows.Forms.CheckBox
$checkBoxinteractive.Location = New-Object System.Drawing.Point(80, 30)
$checkBoxinteractive.Size = New-Object System.Drawing.Size(75, 15)
$checkBoxinteractive.text = "Interactive"
$checkBoxinteractive.Font = $css.smallfont
$tabPage1.Controls.Addrange(@($checkBoxElevated, $checkBoxSystem, $checkBoxDontwait, $checkBoxinteractive))

$buttonpsexec = New-Object System.Windows.Forms.Button
$buttonpsexec.Location = new-object System.Drawing.Point(5, ($tabControl1.size.height - 60))
$buttonpsexec.Size = New-Object System.Drawing.Size(($tabControl1.size.width - 20), 22)
$buttonpsexec.backcolor = $css.DeployButton
$buttonpsexec.flatstyle = 'flat'
$buttonpsexec.text = "Deploy with Psexec"
$buttonpsexec.enabled = $false
$tabPage1.controls.add($buttonpsexec)
$buttonpsexec.Add_Click( {
		$scope = $combocreds.text
		if ($scope -ne '') {
			$credsplain = select-MiCredential -scope $scope -plain
			Append-Richtextbox -Source "Credentials" -Message "Using $($combocreds.text) ($($credsplain.username))" -logfile 'psexec.log'
		}
		else {Append-Richtextbox -Source "Credentials" -Message "Using Current Credentials ($identity)" -logfile 'psexec.log'}

		$objcomputers = $textboxobjects.text.Split("`n`r") -replace "`#.*", "$([char]0)" -replace "#.*" -replace "$([char]0)", "#" -replace "^\s*" -replace "\s*$"|? {$_; }
		if ($RadioButtonping.Checked) {$objcomputers = ping-computers $objcomputers}
		elseif ($RadioButtonports.Checked) {$objcomputers = test-ports $objcomputers (139, 445)}

		if ($objcomputers.length -ne 0 -and (test-path $scriptfilefullname)) {
			$count = $progressBar1.Value = 0
			If ($objcomputers.GetType().Name -match "Object") {$progressBar1.Maximum = $total = $objcomputers.length}else {$progressBar1.Maximum = $total = 1}

			foreach ($computername in $objcomputers) {
				$percent = [int](($count / $total) * 100)
				Write-Progress -activity "DEPLOYING BAT's" -CurrentOperation "Deploying $scriptfilebasename to $computername with psexec" -status "$percent% Completed ($count/$total)" -PercentComplete $percent
				$count++
				$progressBar1.PerformStep()
				write-host "`n$computername : Deploying $scriptfilebasename..." -fore cyan
				$params = ""
				if ($checkBoxElevated.checked) {$params += " -h"}
				if ($checkBoxSystem.checked) {$params += " -s"}
				if ($checkBoxDontwait.checked) {$params += " -d"}
				if ($checkBoxinteractive.checked) {$params += " -i"}
				$cmdkeyadd = "cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
				if ($scope -ne '') {$psexeccommand = "$psscriptroot\..\_bin\psexec.exe \\{0} -accepteula -v -n 10 -u {1} -p '{2}' {3} -c '{4}'" -f $computername, $credsplain.username, $credsplain.password, $params, $scriptfilefullname}
				else {$psexeccommand = "$psscriptroot\..\_bin\psexec.exe \\{0} -accepteula -v -n 10 {1} -c '{2}'" -f $computername, $params, $scriptfilefullname}
				$cmdkeydelete = "cmdkey.exe /delete:" + $computername
				if ($scope -ne '') {invoke-expression $cmdkeyadd}
				invoke-expression $psexeccommand
				$msg = "{0}: Executing: {1} with params:{2} exitcode:{3}" -f $computername, $scriptfilebasename, $params, $lastexitcode
				if ($lastexitcode -in (5, 6, 50, 53, 122, 1311, 1326, 2250)) {$color = $css.richtextcolorERR}else {$color = $css.richtextcolorOK}
				Append-Richtextbox -ComputerName $computername -Source "Psexec" -Message $msg -MessageColor $color -logfile 'psexec.log'
				if ($scope -ne '') {invoke-expression $cmdkeydelete}
				write-host $raya -fore cyan
			}
			Write-Progress -Activity "DEPLOYING BAT'S" -Completed
			Append-Richtextbox -Source "Psexec" -Message "END OF DEPLOYMENT"
			write-host "END OF DEPLOYMENT" -fore cyan
		}
	})
####TAB 2 CONTENT (PS1)
#Create a group that will contain your radio buttons
$PwshGroupBox = New-Object System.Windows.Forms.GroupBox
$PwshGroupBox.size = new-object System.Drawing.Size(140, 60)
$PwshGroupBox.Location = new-object System.Drawing.Point(5, 2)
$PwshGroupBox.enabled = $false
$tabPage2.controls.add($PwshGroupBox)
# Create the collection of radio buttons
$RadioButtoRundefault = New-Object System.Windows.Forms.RadioButton
$RadioButtoRundefault.Location = new-object System.Drawing.Point(5, 15)
$RadioButtoRundefault.size = New-Object System.Drawing.Size(133, 17)
$RadioButtoRundefault.Checked = $true
$RadioButtoRundefault.Text = "Run (default)"
$RadioButtonRunas = New-Object System.Windows.Forms.RadioButton
$RadioButtonRunas.Location = new-object System.Drawing.Point(5, 35)
$RadioButtonRunas.size = New-Object System.Drawing.Size(133, 17)
$RadioButtonRunas.Checked = $false
$RadioButtonRunas.Text = "RunAs (start-process)"
#Add radiobuttons to groupbox
$PwshGroupBox.Controls.AddRange(@($RadioButtoRundefault, $RadioButtonRunas))
$buttonps = New-Object System.Windows.Forms.Button
$buttonps.Location = new-object System.Drawing.Point(5, ($tabControl1.size.height - 60))
$buttonps.Size = New-Object System.Drawing.Size(($tabControl1.size.width - 20), 22)
$buttonps.backcolor = $css.DeployButton
$buttonps.flatstyle = 'flat'
$buttonps.text = "Run PS1"
$buttonps.enabled = $false
$tabPage2.controls.add($buttonps)
$buttonps.Add_Click( {
		$scope = $combocreds.text
		if ($scope -ne '') {
			$creds = select-MiCredential -scope $scope
			Append-Richtextbox -Source "Credentials" -Message "Using $($combocreds.text) ($($creds.username))" -logfile 'ps1command.log'
		}
		else {Append-Richtextbox -Source "Credentials" -Message "Using Current Credentials ($identity)" -logfile 'ps1command.log'}

		$objcomputers = $textboxobjects.text.Split("`n`r") -replace "`#.*", "$([char]0)" -replace "#.*" -replace "$([char]0)", "#" -replace "^\s*" -replace "\s*$"|? {$_; }
		if ($RadioButtonping.Checked) {$objcomputers = ping-computers $objcomputers}
		elseif ($RadioButtonports.Checked) {$objcomputers = test-ports $objcomputers (139, 445, 5985)}

		if ($objcomputers.length -ne 0 -and (test-path $scriptfilefullname)) {
			$count = $progressBar1.Value = 0
			If ($objcomputers.GetType().Name -match "Object") {$progressBar1.Maximum = $total = $objcomputers.length}else {$progressBar1.Maximum = $total = 1}
			foreach ($computername in $objcomputers) {
				$percent = [int](($count / $total) * 100)
				Write-Progress -activity "RUNNING PS1'S" -CurrentOperation "Running $scriptfilebasename to $computername" -status "$percent% Completed ($count/$total)" -PercentComplete $percent
				$count++
				$progressBar1.PerformStep()
				write-host "`n$computername : Running $scriptfilebasename..." -fore cyan
				Append-Richtextbox -ComputerName $computername -Source "ps1command" -Message "Running $scriptfilebasename" -logfile 'ps1command.log'
				if ($RadioButtonRunas.Checked) {
					start-process -credential $creds -filepath powershell.exe -argumentlist "-noprofile -file ""$scriptfilefullname"" $computername"
					<#
					$newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell"
					$newProcess.Arguments = "-noprofile -file ""$scriptfilefullname"" $computername"
					$newProcess.Verb = "runas"
					$newProcess.UseShellExecute = $false
					#$newProcess.username = $creds.username
					#$newProcess.Password = $creds.password
					[System.Diagnostics.Process]::Start($newProcess);
					#>
				}
				else {. $scriptfilefullname}
			}
			Write-Progress -Activity "RUNNING PS1'S" -Completed
			Append-Richtextbox -Source "ps1command" -Message "END OF DEPLOYMENT"
			write-host "END OF DEPLOYMENT" -fore cyan
		}
	})
###TAB 3 CONTENT (TXT WITH Plink)
$buttonplink = New-Object System.Windows.Forms.Button
$buttonplink.Location = new-object System.Drawing.Point(5, ($tabControl1.size.height - 60))
$buttonplink.Size = New-Object System.Drawing.Size(($tabControl1.size.width - 20), 22)
$buttonplink.backcolor = $css.DeployButton
$buttonplink.flatstyle = 'flat'
$buttonplink.text = "Deploy with Plink"
$buttonplink.enabled = $false
$tabPage3.controls.add($buttonplink)
$buttonplink.Add_Click( {
		$scope = $combocreds.text
		if ($scope -ne '') {
			$credsplain = select-MiCredential -scope $scope -plain
			Append-Richtextbox -Source "Credentials" -Message "Using $($combocreds.text) ($($credsplain.username))" -logfile 'plink.log'
		}
		else {Append-Richtextbox -Source "Credentials" -Message "Using Current Credentials ($identity)" -logfile 'plink.log'}

		$objcomputers = $textboxobjects.text.Split("`n`r") -replace "`#.*", "$([char]0)" -replace "#.*" -replace "$([char]0)", "#" -replace "^\s*" -replace "\s*$"|? {$_; }
		if ($RadioButtonping.Checked) {$objcomputers = ping-computers $objcomputers}
		elseif ($RadioButtonports.Checked) {$objcomputers = test-ports $objcomputers 22}

		if ($objcomputers.length -ne 0 -and (test-path $scriptfilefullname)) {
			$count = $progressBar1.Value = 0
			If ($objcomputers.GetType().Name -match "Object") {$progressBar1.Maximum = $total = $objcomputers.length}else {$progressBar1.Maximum = $total = 1}

			foreach ($computername in $objcomputers) {
				$percent = [int](($count / $total) * 100)
				Write-Progress -activity "DEPLOYING TXT's" -CurrentOperation "Deploying $scriptfilebasename to $computername with plink" -status "$percent% Completed ($count/$total)" -PercentComplete $percent
				$count++
				$progressBar1.PerformStep()
				write-host "`n$computername : Deploying $scriptfilebasename..." -fore cyan
				if ($scope -ne '') {
					$plinkcommand = "$psscriptroot\..\_bin\plink.exe -v {1}@{0} -pw '{2}' -m '{3}' >> 'Results\{4}.txt'" -f $computername, $credsplain.username, $credsplain.password, $scriptfilefullname, $scriptfilebasename
					invoke-expression $plinkcommand
					$msg = "{0}: exitcode:{1} executing:{2}" -f $computername, $lastexitcode, $scriptfilebasename
					if ($lastexitcode -eq 1) {$color = $css.richtextcolorERR}else {$color = $css.richtextcolorOK}
					Append-Richtextbox -ComputerName $computername -Source "Plink" -Message $msg -MessageColor $color -logfile 'plink.log'
				}
				else {Append-Richtextbox -ComputerName $computername -Source "Plink" -Message "Please supply proper credentials" -MessageColor $css.richtextcolorwarning -logfile 'plink.log'}
				write-host $raya -fore cyan
			}
			Write-Progress -Activity "DEPLOYING TXT'S" -Completed
			Append-Richtextbox -Source "Plink" -Message "END OF DEPLOYMENT"
			write-host "END OF DEPLOYMENT" -fore cyan
		}
	})

$richtextbox = New-Object System.Windows.Forms.RichTextBox
$richtextbox.Location = new-object System.Drawing.Point(475, 0)
$richtextbox.Size = new-object System.Drawing.Size(($Form1.ClientSize.Width - 475), ($Form1.ClientSize.height - 10))
$richtextbox.Multiline = $true
$richtextbox.scrollbars = 'Vertical'
$richtextbox.Font = $css.richtextfont
$richtextbox.backcolor = $css.richcolor
$richtextbox.borderstyle = 0 #0=sin borde, 1=borde 2=hundido
$form1.controls.add($richtextbox)
#ProgressBar
$progressBar1 = New-Object System.Windows.Forms.ProgressBar
$progressBar1.DataBindings.DefaultDataSourceUpdateMode = 0
$progressBar1.Location = new-object System.Drawing.Point($richtextbox.Location.X, ($Form1.ClientSize.height - 10))
$progressBar1.Size = new-object System.Drawing.Size($richtextbox.size.Width, 10)
$progressBar1.Step = 1
$progressBar1.TabIndex = 0
$progressBar1.Style = 1
$Form1.Controls.Add($progressBar1)
#Personalizo la consola
$host.ui.RawUI.WindowTitle = "SistemasWin | MiShell Deploy | $identity"
write-host ''
write-host '  8888888P.                    888'
write-host '  888  "788b                   888'
write-host '  888    888                   888'
write-host '  888    888 ,A8888A, 88888Y,  888 ,A8888A, 888  888'
write-host '  888    888 888  888 888 "88Y 888 888  888 888  888'
write-host '  888    888 888888Y" 888  888 888 888  888 888  888'
write-host '  888  ,d88P 888      888  888 888 888  888 Y88b 888'
write-host '  8888888K"  "Y8888Y" 888888Y" 888 "Y8888Y"  "Y88888'
write-host '                      888                       "888'
write-host '                      888                       .888'
write-host '                      888                    8888P" '
write-host ''
#muestro el formulario
[System.Windows.Forms.Application]::Run($Form1)
