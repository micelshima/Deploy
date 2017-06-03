@echo off
cd deploy
powershell -executionpolicy unrestricted -noprofile -windowstyle minimized .\deploy.ps1
