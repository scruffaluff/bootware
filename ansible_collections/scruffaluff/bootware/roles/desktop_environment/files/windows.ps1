# Configure Windows desktop.
#
# Most commands are taken from
# https://github.com/Sycnex/Windows10Debloater/blob/master/Windows10Debloater.ps1.

# Exit immediately if a PowerShell cmdlet encounters an error.
$ErrorActionPreference = 'Stop'
# Disable progress bar for PowerShell cmdlets.
$ProgressPreference = 'SilentlyContinue'
# Exit immediately when an native executable encounters an error.
$PSNativeCommandUseErrorActionPreference = $True

function MakePath($Path) {
    if (-not (Test-Path $Path)) {
        New-Item $Path | Out-Null
    }
}

# Remove applications.
$Applications = @(
    'Microsoft.BingFinance',
    'Microsoft.BingFoodAndDrink',
    'Microsoft.BingHealthAndFitness',
    'Microsoft.BingNews',
    'Microsoft.BingSports',
    'Microsoft.BingTranslator',
    'Microsoft.BingTravel',
    'Microsoft.BingWeather'
)
foreach ($Application in $Applications) {
    Get-AppxPackage -AllUsers -Name $Application | Remove-AppxPackage -AllUsers
    Get-AppxProvisionedPackage -Online |
        Where-Object DisplayName -EQ $Application |
        Remove-AppxProvisionedPackage -Online
}

# Disable services.
$Services = @(
    'Beep', # Windows error beep sound.
    'XblAuthManager', # Xbox live authentication manager.
    'XblGameSave', # Xbox live game save service.
    'XboxGipSvc', # Xbox accessory management service.
    'XboxNetApiSvc' # Xbox live networking service.
)
foreach ($Service in $Services) {
    Get-Service -ErrorAction SilentlyContinue -Name $Service |
        Set-Service -StartupType Manual
}

# File Explorer related settings.
$RegPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
MakePath $RegPath
# Show hidden files in File Explorer.
Set-ItemProperty -Name 'HideFileExt' -Path $RegPath -Type DWord -Value 0
# Show more pins than recommendations in start menu.
Set-ItemProperty -Name 'Start_Layout' -Path $RegPath -Type DWord -Value 1
# Disable recommendations in start menu.
Set-ItemProperty -Name 'Start_IrisRecommendations' -Path $RegPath -Type DWord `
    -Value 0
# Restart File Explorer
Stop-Process -Force -ErrorAction SilentlyContinue -ProcessName Explorer

# Change Windows error beep sound to nothing.
$RegPath = 'HKCU:\Control Panel\Sound'
MakePath $RegPath
Set-ItemProperty -Name 'Beep' -Path $RegPath -Type String -Value 'no'

# Disable Bing search in startup menu.
$RegPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
MakePath $RegPath
Set-ItemProperty -Name 'BingSearchEnabled' -Path $RegPath -Type DWord -Value 0

# Remove Cortana from Windows search.
$RegPath = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
MakePath $RegPath
Set-ItemProperty -Name AllowCortana -Path $RegPath -Type DWord -Value 0

# Remove news and interests from task bar.
$RegPath = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'
MakePath $RegPath
Set-ItemProperty -Name 'EnableFeeds' -Path $RegPath -Type DWord -Value 0

# Remove application recommendations.
$RegPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
MakePath $RegPath
$RegKeys = @(
    'ContentDeliveryAllowed',
    'OemPreInstalledAppsEnabled',
    'PreInstalledAppsEnabled',
    'PreInstalledAppsEverEnabled',
    'SilentInstalledAppsEnabled',
    'SystemPaneSuggestionsEnabled'
)
foreach ($RegKey in $RegKeys) {
    Set-ItemProperty -Name $RegKey -Path $RegPath -Type DWord -Value 0
}

# Remove "Open in" application context keys from File Explorer.
$RegPaths = @(
    'HKCU:\Software\Classes\Directory\shell\AnyCode', # Visual Studio
    'HKCU:\Software\Classes\Directory\Background\shell\AnyCode', # Visual Studio
    'HKCU:\Software\Classes\Directory\shell\git_gui', # Git Bash
    'HKCU:\Software\Classes\Directory\Background\shell\git_gui', # Git Bash
    'HKCU:\Software\Classes\Directory\shell\git_shell', # Git Bash
    'HKCU:\Software\Classes\Directory\Background\shell\git_shell', # Git Bash
    'HKCU:\Software\Classes\Directory\shell\PowerShell7x64', # PowerShell 7
    'HKCU:\Software\Classes\Directory\Background\shell\PowerShell7x64' # PowerShell 7
)
foreach ($RegPath in $RegPaths) {
    if (Test-Path $RegPath) {
        Remove-Item -Force -Recurse -Path $RegPath
    }
}
