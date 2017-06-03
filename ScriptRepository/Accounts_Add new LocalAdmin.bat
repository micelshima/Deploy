@echo off
set theuser=SysAdmin
set thepass=V3ry5tr0ngP455w0rd
REM ---------------------------------------------
echo create local user %theuser%
net user %theuser% %thepass% /add 

net localgroup administrators %theuser% /add

WMIC USERACCOUNT WHERE "Name='%theuser%'" SET PasswordExpires=FALSE

