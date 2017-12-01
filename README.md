# Deploy
Powershell GUI to deploy your own scripts to remote computers.

![alt tag](https://4.bp.blogspot.com/-uknJpXqoqrI/WiGVDLsI9GI/AAAAAAAACAg/Kn6daIOjvagNaU0lXBcCgf59RCxFB5hmQCEwYBhgL/s640/deployGUIv2.jpg)

STEPS:
1. Choose the script you want to run from ScriptRepository
2. Write the computernames in Computers textbox or select txt file that contains them
3. Select proper credentials from the credentials combobox or write a description for new ones.
4. Choose whether you want to ping computers first, test the ports needed to work or do nothing
5. Run!

This GUI allows you to execute any script to a list of computers. The only thing you need to do is store your own batches and powershell scripts under 'ScriptRepository' folder.

When creating your own powershell scripts just bear in mind that the list of computers will fill the variable $computername and the credentials will be saved in $creds
Here is an example for restarting a list of computers:

restart-computer -computername $computername -credential $creds -force -confirm:$false

I have uploaded some of my scripts and batches as examples.
Notice that underscore '_' character in scriptnames is used to create tree levels inside the GUI treeview in order to keep them organized.

More info about this project in:
https://systemswin.blogspot.com.es/2017/06/powershell-forms-deploy-batches-to.html

Enjoy!
