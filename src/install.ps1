<#
.SYNOPSIS
    Installs Bootware for Windows systems.
#>

# If unable to execute due to policy rules, run
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser.

# Exit immediately if a PowerShell cmdlet encounters an error.
$ErrorActionPreference = 'Stop'
# Disable progress bar for PowerShell cmdlets.
$ProgressPreference = 'SilentlyContinue'
# Exit immediately when an native executable encounters an error.
$PSNativeCommandUseErrorActionPreference = $True

# Show CLI help information.
function Usage() {
    Write-Output @'
Installer script for Bootware.

Usage: install [OPTIONS]

Options:
  -h, --help                Print help information
  -u, --user                Install bootware for current user
  -v, --version <VERSION>   Version of Bootware to install
'@
}

function CheckEnvironment($Target) {
    if (($PSVersionTable.PSVersion.Major) -lt 5) {
        Write-Output @'
PowerShell 5 or later is required to run Bootware.
Upgrade PowerShell: https://docs.microsoft.com/powershell/scripting/windows-powershell/install/installing-windows-powershell
'@
        exit 1
    }

    $AllowedExecutionPolicy = @('Unrestricted', 'RemoteSigned', 'ByPass')
    if ((Get-ExecutionPolicy).ToString() -notin $AllowedExecutionPolicy) {
        Write-Output @"
PowerShell requires an execution policy [$($AllowedExecutionPolicy -Join ', ')] to run Bootware.
To set the execution policy to the recommended 'RemoteSigned' run:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
"@
        exit 1
    }

    if (($Target -eq 'Machine') -and (-not (IsAdministrator))) {
        Write-Output @"
System level installation requires an administrator console.
Run this script from an administrator console or execute with the '--user' flag.
"@
        exit 1
    }
}

# Print error message and exit script with usage error code.
function ErrorUsage($Message) {
    Write-Output "error: $Message"
    Write-Output "Run 'install --help' for usage"
    exit 2
}

# Install completion script for Bootware.
function InstallCompletion($Version) {
    $PowerShellURL = "https://raw.githubusercontent.com/scruffaluff/bootware/$Version/src/completion/bootware.psm1"

    $Paths = @(
        "$HOME/Documents/PowerShell/Modules/BootwareCompletion"
        "$HOME/Documents/WindowsPowerShell/Modules/BootwareCompletion"
    )
    foreach ($Path in $Paths) {
        New-Item -Force -ItemType Directory -Path $Path | Out-Null
        Invoke-WebRequest -UseBasicParsing -OutFile `
            "$Path/BootwareCompletion.psm1" -Uri $PowerShellURL
    }
}


# Check if script is run from an admin console.
function IsAdministrator {
    return ([Security.Principal.WindowsPrincipal]`
            [Security.Principal.WindowsIdentity]::GetCurrent()`
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Print log message to stdout if logging is enabled.
function Log($Message) {
    if (-not "$Env:INSTALL_NOLOG") {
        Write-Output $Message
    }
}

# Script entrypoint.
function Main() {
    $ArgIdx = 0
    $Target = 'Machine'
    $Version = 'main'

    while ($ArgIdx -lt $Args[0].Count) {
        switch ($Args[0][$ArgIdx]) {
            { $_ -in '-h', '--help' } {
                Usage
                exit 0
            }
            { $_ -in '-v', '--version' } {
                $Version = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            '--user' {
                $Target = 'User'
                $ArgIdx += 1
                break
            }
            Default {
                ErrorUsage "No such option '$($Args[0][$ArgIdx])'"
            }
        }
    }

    CheckEnvironment $Target
    $Source = "https://raw.githubusercontent.com/scruffaluff/bootware/$Version/src/bootware.ps1"
    if ($Target -eq 'User') {
        $Dest = "$Env:AppData/Bootware/bootware.ps1"
    }
    else {
        $Dest = 'C:/Program Files/Bootware/bootware.ps1'
    }

    $DestDir = Split-Path -Parent -Path $Dest
    # Explicit path update needed, since SetEnvironmentVariable does not seem to
    # instantly take effect.
    $Env:Path = $DestDir + ";$Env:Path"

    $Path = [Environment]::GetEnvironmentVariable('Path', $Target)
    if (-not ($Path -like "*$DestDir*")) {
        [System.Environment]::SetEnvironmentVariable(
            'Path', "$DestDir;$Path", $Target
        )
    }

    Log 'Installing Bootware...'

    New-Item -Force -ItemType Directory -Path $DestDir | Out-Null
    Invoke-WebRequest -UseBasicParsing -OutFile $Dest -Uri $Source
    InstallCompletion $Version
    Log "Installed $(bootware --version)."
}

# Only run Main if invoked as script. Otherwise import functions as library.
if ($MyInvocation.InvocationName -ne '.') {
    Main $Args
}
