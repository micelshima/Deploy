# Deploy
Powershell GUI to deploy batches to remote computers with psexec or execute powershell scripts to them

![alt tag](https://2.bp.blogspot.com/-KBzdm2fjqDU/WTWOK9xP6EI/AAAAAAAAB-g/xtPfciJeV8siMD1Bfjou93KpgzR0xljdACLcB/s640/deployGUI.jpg)

STEPS:
1. Select proper credentials from the credentials combobox or write a description for new ones.
2. Write the computernames in Computers textbox or select txt file that contains them
3. Choose whether you want to ping computers first, test the ports needed to work or do nothing
4. Choose the script you want to run from ScriptRepository
5. Run!

This GUI allows you to execute any script to a list of computers. The only thing you need to do is store your own batches and powershell scripts under 'ScriptRepository' folder.
I have uploaded some of my scripts and batches as examples.
Notice that underscore '_' character in scriptnames is used to create grouping levels inside the GUI treeview in order to keep them organized.

More info about this project in:
https://systemswin.blogspot.com.es/2017/06/powershell-forms-deploy-batches-to.html

Enjoy!
