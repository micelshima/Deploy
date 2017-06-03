@echo off

cd c:\windows\system32
cscript slmgr.vbs /ckms
cscript slmgr.vbs /ckhc
cscript slmgr.vbs /skhc
cscript slmgr.vbs /skms kms.sistemaswin.int

cscript slmgr.vbs /ato
