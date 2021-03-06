
Param(
	[string] [Parameter(Mandatory=$true)] $AdminUser,
    [string] [Parameter(Mandatory=$true)] $AdminPassword,
    [string] [Parameter(Mandatory=$true)] $MqttBroker,
    [string] [Parameter(Mandatory=$true)] $MqttUser,
    [string] [Parameter(Mandatory=$true)] $MqttPassword
)

# Turn off firewall. Azure security group settings control external access. Intra Test Cell connections should be available
& netsh advfirewall set allprofiles state off

mkdir  c:\WinConfig

#install Git
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.8.1.windows.1/Git-2.8.1-64-bit.exe" -OutFile "c:\WinConfig\Git-2.8.1-64-bit.exe" -TimeoutSec 180 -ErrorAction:Stop -Verbose
& c:\WinConfig\Git-2.8.1-64-bit.exe /Silent | Out-Null  -Verbose
$env:Path += ";C:\Program Files\Git"

#install nodejs
Invoke-WebRequest -Uri "https://nodejs.org/dist/v4.4.3/node-v4.4.3-x64.msi" -OutFile "c:\WinConfig\node-v4.4.3-x64.msi" -TimeoutSec 180 -ErrorAction:Stop -Verbose
& msiexec /i c:\WinConfig\node-v4.4.3-x64.msi /quiet | Out-Null  -Verbose
$env:Path += ";C:\Program Files\nodejs;c:\Users\" + $AdminUser + "\AppData\Roaming\npm"

#configure autologon
..\scripts\autoLogon.ps1 -AdminUser $AdminUser -AdminPassword $AdminPassword

mkdir  c:\StartupConfig -Force

#configure logon startup script
$startUpBatchFileContent = @"
powershell.exe -command "& {[System.IO.Directory]::Delete('c:\Wave',1) }" 2>&1 > C:\StartupConfig\WaveDelete.log
powershell.exe -NoProfile -ExecutionPolicy unrestricted -Command "&{`$target='c:\Wave\';`$broker='$MqttBroker';`$username='$MqttUser';`$password='$MqttPassword';iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/aspnet/Wave/master/scripts/Install.ps1'))}"  2>&1 > c:\StartupConfig\WaveInstall.log
"@

$startUpBatchFileContent | Set-Content c:\StartupConfig\Startup.bat

$startupRegContent = @"
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run]
"startup"="C:\\StartupConfig\\Startup.bat"
"@
$startupRegContent | Set-Content c:\StartupConfig\EnableStartup.reg
$result = cmd /c  regedit.exe /S c:\StartupConfig\EnableStartup.reg  2`>`&1 
$result = "Startup config complete  " + $result 
Write-Output $result

