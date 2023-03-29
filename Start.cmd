::This script runs the tiny11 Windows Creation Tool as TrustedInstaller in order to have access to protected components that cannot be modified under Administrator privileges
@echo off
Set ExecutionPolicy = RemoteSigned
start /B nsudo.exe -U:T -P:E powershell -noexit %~dp0tiny11creator.ps1

exit