<#
.SYNOPSIS
    Install Bootware for Windows systems.
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

Usage: install-bootware [OPTIONS]

Options:
  -d, --dest <PATH>         Directory to install Bootware.
  -g, --global              Install Bootware for all users.
  -h, --help                Print help information.
  -p, --preserve-env        Do not update system environment.
  -q, --quiet               Print only error messages.
  -v, --version <VERSION>   Version of Bootware to install.
'@
}

# Download and install Bootware.
function InstallBootware($TargetEnv, $Version, $DestDir, $Script, $PreserveEnv) {
    $URL = "https://raw.githubusercontent.com/scruffaluff/bootware/$Version"

    Log "Installing Bootware to '$DestDir\bootware.ps1'."
    Invoke-WebRequest -UseBasicParsing -OutFile "$DestDir\bootware.ps1" `
        -Uri "$URL/src/bootware.ps1"
    Set-Content -Path "$DestDir\bootware.cmd" -Value @"
@echo off
powershell -NoProfile -ExecutionPolicy RemoteSigned -File "%~dnp0.ps1" %*
"@
    InstallCompletion $TargetEnv $Version

    if (-not $PreserveEnv) {
        $Path = [Environment]::GetEnvironmentVariable('Path', "$TargetEnv")
        if (-not ($Path -like "*$DestDir*")) {
            $PrependedPath = "$DestDir;$Path"
            [System.Environment]::SetEnvironmentVariable(
                'Path', "$PrependedPath", "$TargetEnv"
            )
            Log "Added '$DestDir' to the system path."
            Log 'Source shell profile or restart shell after installation.'
        }
    }

    $Env:Path = "$DestDir;$Env:Path"
    Log "Installed $(bootware --version)."
}

# Install completion script for Bootware.
function InstallCompletion($TargetEnv, $Version) {
    $URL = "https://raw.githubusercontent.com/scruffaluff/bootware/$Version/src/completion/bootware.psm1"

    if ($TargetEnv -eq 'Machine') {
        $Paths = @(
            'C:\Program Files\PowerShell\Modules'
            'C:\Program Files\WindowsPowerShell\Modules'
        )
    }
    else {
        $Paths = @(
            "$HOME\Documents\PowerShell\Modules"
            "$HOME\Documents\WindowsPowerShell\Modules"
        )
    }
    foreach ($Path in $Paths) {
        New-Item -Force -ItemType Directory -Path $Path | Out-Null
        Invoke-WebRequest -UseBasicParsing -OutFile `
            "$Path\BootwareCompletion.psm1" -Uri $URL
    }
}

# Check if script is run from an admin console.
function IsAdministrator {
    ([Security.Principal.WindowsPrincipal]`
        [Security.Principal.WindowsIdentity]::GetCurrent()`
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Print message if logging is enabled.
function Log($Text) {
    if (!"$Env:BOOTWARE_NOLOG") {
        Write-Output $Text
    }
}

# Script entrypoint.
function Main() {
    $ArgIdx = 0
    $DestDir = ''
    $PreserveEnv = $False
    $Version = 'main'

    while ($ArgIdx -lt $Args[0].Count) {
        switch ($Args[0][$ArgIdx]) {
            { $_ -in '-d', '--dest' } {
                $DestDir = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            { $_ -in '-g', '--global' } {
                if (-not $DestDir) {
                    $DestDir = 'C:\Program Files\Bootware'
                }
                $ArgIdx += 1
                break
            }
            { $_ -in '-h', '--help' } {
                Usage
                exit 0
            }
            { $_ -in '-p', '--preserve-env' } {
                $PreserveEnv = $True
                $ArgIdx += 1
                break
            }
            { $_ -in '-q', '--quiet' } {
                $Env:BOOTWARE_NOLOG = 'true'
                $ArgIdx += 1
                break
            }
            { $_ -in '-v', '--version' } {
                $Version = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            default {
                Log "error: No such option '$($Args[0][$ArgIdx])'."
                Log "Run 'install-bootware --help' for usage."
                exit 2
            }

        }
    }

    # Create destination folder if it does not exist for Resolve-Path.
    if (-not $DestDir) {
        $DestDir = "$Env:LocalAppData\Programs\Bootware"
    }
    New-Item -Force -ItemType Directory -Path $DestDir | Out-Null

    # Set environment target on whether destination is inside user home folder.
    $DestDir = [System.IO.Path]::GetFullPath($DestDir)
    $HomeDir = [System.IO.Path]::GetFullPath($HOME)
    if ($DestDir.StartsWith($HomeDir)) {
        $TargetEnv = 'User'
    }
    else {
        $TargetEnv = 'Machine'
    }
    if (($TargetEnv -eq 'Machine') -and (-not (IsAdministrator))) {
        Log @'
System level installation requires an administrator console.
Restart this script from an administrator console or install to a user directory.
'@
        exit 1
    }

    InstallBootware $TargetEnv $Version $DestDir $Script $PreserveEnv
}

# Only run Main if invoked as script. Otherwise import functions as library.
if ($MyInvocation.InvocationName -ne '.') {
    Main $Args
}
