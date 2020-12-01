#Requires -RunAsAdministrator


# Make current network private.
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

# Start WinRM service.
Enable-PSRemoting -Force -SkipNetworkProfileCheck

# Something?
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
