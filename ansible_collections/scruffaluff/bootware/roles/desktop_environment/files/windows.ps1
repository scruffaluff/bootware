# Configure Windows desktop.
#
# Most commands are taken from
# https://github.com/ChrisTitusTech/winutil/blob/main/winutil.ps1 and
# https://github.com/Sycnex/Windows10Debloater/blob/master/Windows10Debloater.ps1.

# Exit immediately if a PowerShell cmdlet encounters an error.
$ErrorActionPreference = 'Stop'
# Exit immediately when an native executable encounters an error.
$PSNativeCommandUseErrorActionPreference = $True

# Remove applications.
$Applications = @(
    'Microsoft.BingFinance'
    'Microsoft.BingFoodAndDrink'
    'Microsoft.BingHealthAndFitness'
    'Microsoft.BingNews'
    'Microsoft.BingSports'
    'Microsoft.BingTranslator'
    'Microsoft.BingTravel'
    'Microsoft.BingWeather'
)

ForEach ($Application In $Applications) {
    Get-AppxPackage -AllUsers -Name $Application | Remove-AppxPackage -AllUsers

    Get-AppxProvisionedPackage -Online |
        Where-Object DisplayName -EQ $Application |
        Remove-AppxProvisionedPackage -Online
}

# Disable services.
$Services = @(
    'Beep' # Windows error beep sound.
    'XblAuthManager' # Xbox live authentication manager.
    'XblGameSave' # Xbox live game save service.
    'XboxGipSvc' # Xbox accessory management service.
    'XboxNetApiSvc' # Xbox live networking service.
)

ForEach ($Service In $Services) {
    Get-Service -ErrorAction SilentlyContinue -Name $Service |
        Set-Service -StartupType Manual
}

# Show hidden files in File Explorer.
If (Test-Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced') {
    Set-ItemProperty `
        -Name 'HideFileExt' `
        -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
        -Type DWord `
        -Value 0
    Stop-Process -Force -ErrorAction SilentlyContinue -ProcessName Explorer
}

# Change Windows error beep sound to nothing.
If (Test-Path 'HKCU:\Control Panel\Sound') {
    Set-ItemProperty `
        -Name 'Beep' `
        -Path 'HKCU:\Control Panel\Sound' `
        -Type String `
        -Value 'no'
}

# Disable Bing search in startup menu.
If (Test-Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search') {
    Set-ItemProperty `
        -Name 'BingSearchEnabled' `
        -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' `
        -Type DWord `
        -Value 0
}

# Remove Cortana from Windows search.
$SearchPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
If (Test-Path $SearchPath) {
    Set-ItemProperty -Name AllowCortana -Path $SearchPath -Type DWord -Value 0
}

# Remove news and interests from task bar.
$WindowsFeedsPath = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'
If (Test-Path $WindowsFeedsPath) {
    Set-ItemProperty `
        -Name 'EnableFeeds' `
        -Path $WindowsFeedsPath `
        -Type DWord `
        -Value 0
}

# Remove application recommendations.
$ContentPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
If (Test-Path $ContentPath) {
    Set-ItemProperty -Name 'ContentDeliveryAllowed' -Path $ContentPath -Type DWord -Value 0
    Set-ItemProperty -Name 'OemPreInstalledAppsEnabled' -Path $ContentPath -Type DWord -Value 0
    Set-ItemProperty -Name 'PreInstalledAppsEnabled' -Path $ContentPath -Type DWord -Value 0
    Set-ItemProperty -Name 'PreInstalledAppsEverEnabled' -Path $ContentPath -Type DWord -Value 0
    Set-ItemProperty -Name 'SilentInstalledAppsEnabled' -Path $ContentPath -Type DWord -Value 0
    Set-ItemProperty -Name 'SystemPaneSuggestionsEnabled' -Path $ContentPath -Type DWord -Value 0
}

If (-Not (Test-Path 'HKCR:')) {
    New-PSDrive -Name 'HKCR' -PSProvider Registry -Root HKEY_CLASSES_ROOT
}

# Remove "Open in" application context keys from File Explorer.
$ContextKeys = @(
    'HKCR:\Directory\shell\AnyCode' # Visual Studio
    'HKCR:\Directory\Background\shell\AnyCode' # Visual Studio
    'HKCR:\Directory\shell\git_gui' # Git Bash
    'HKCR:\Directory\Background\shell\git_gui' # Git Bash
    'HKCR:\Directory\shell\git_shell' # Git Bash
    'HKCR:\Directory\Background\shell\git_shell' # Git Bash
    'HKCR:\Directory\shell\PowerShell7x64' # PowerShell 7
    'HKCR:\Directory\Background\shell\PowerShell7x64' # PowerShell 7
)

ForEach ($ContextKey In $ContextKeys) {
    If (Test-Path $ContextKey) {
        Remove-Item -Force -Recurse -Path $ContextKey
    }
}
