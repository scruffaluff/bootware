# Configure Windows desktop.
#
# Most commands are taken from
# https://github.com/ChrisTitusTech/winutil/blob/main/winutil.ps1 and
# https://github.com/Sycnex/Windows10Debloater/blob/master/Windows10Debloater.ps1.

# Exit immediately if a PowerShell cmdlet encounters an error.
$ErrorActionPreference = 'Stop'
# Disable progress bar for PowerShell cmdlets.
$ProgressPreference = 'SilentlyContinue'
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

foreach ($Application in $Applications) {
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

foreach ($Service in $Services) {
    Get-Service -ErrorAction SilentlyContinue -Name $Service |
        Set-Service -StartupType Manual
}

# Show hidden files in File Explorer.
if (Test-Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced') {
    Set-ItemProperty `
        -Name 'HideFileExt' `
        -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
        -Type DWord `
        -Value 0
    Stop-Process -Force -ErrorAction SilentlyContinue -ProcessName Explorer
}

# Change Windows error beep sound to nothing.
if (Test-Path 'HKCU:\Control Panel\Sound') {
    Set-ItemProperty `
        -Name 'Beep' `
        -Path 'HKCU:\Control Panel\Sound' `
        -Type String `
        -Value 'no'
}

# Disable Bing search in startup menu.
if (Test-Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search') {
    Set-ItemProperty `
        -Name 'BingSearchEnabled' `
        -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' `
        -Type DWord `
        -Value 0
}

# Remove Cortana from Windows search.
$SearchPath = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
if (Test-Path $SearchPath) {
    Set-ItemProperty -Name AllowCortana -Path $SearchPath -Type DWord -Value 0
}

# Remove news and interests from task bar.
$WindowsFeedsPath = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'
if (Test-Path $WindowsFeedsPath) {
    Set-ItemProperty `
        -Name 'EnableFeeds' `
        -Path $WindowsFeedsPath `
        -Type DWord `
        -Value 0
}

# Remove application recommendations.
$ContentPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
if (Test-Path $ContentPath) {
    Set-ItemProperty -Name 'ContentDeliveryAllowed' -Path $ContentPath -Type DWord -Value 0
    Set-ItemProperty -Name 'OemPreInstalledAppsEnabled' -Path $ContentPath -Type DWord -Value 0
    Set-ItemProperty -Name 'PreInstalledAppsEnabled' -Path $ContentPath -Type DWord -Value 0
    Set-ItemProperty -Name 'PreInstalledAppsEverEnabled' -Path $ContentPath -Type DWord -Value 0
    Set-ItemProperty -Name 'SilentInstalledAppsEnabled' -Path $ContentPath -Type DWord -Value 0
    Set-ItemProperty -Name 'SystemPaneSuggestionsEnabled' -Path $ContentPath -Type DWord -Value 0
}

# Remove "Open in" application context keys from File Explorer.
$ContextKeys = @(
    'HKCU:\Software\Classes\Directory\shell\AnyCode' # Visual Studio
    'HKCU:\Software\Classes\Directory\Background\shell\AnyCode' # Visual Studio
    'HKCU:\Software\Classes\Directory\shell\git_gui' # Git Bash
    'HKCU:\Software\Classes\Directory\Background\shell\git_gui' # Git Bash
    'HKCU:\Software\Classes\Directory\shell\git_shell' # Git Bash
    'HKCU:\Software\Classes\Directory\Background\shell\git_shell' # Git Bash
    'HKCU:\Software\Classes\Directory\shell\PowerShell7x64' # PowerShell 7
    'HKCU:\Software\Classes\Directory\Background\shell\PowerShell7x64' # PowerShell 7
)

foreach ($ContextKey in $ContextKeys) {
    if (Test-Path $ContextKey) {
        Remove-Item -Force -Recurse -Path $ContextKey
    }
}
