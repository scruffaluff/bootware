# If unable to execute due to policy rules, run
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser.

# Exit immediately if a PowerShell Cmdlet encounters an error.
$ErrorActionPreference = 'Stop'

# Show CLI help information.
Function Usage() {
    Write-Output @'
Bootware Installer
Installer script for Bootware

USAGE:
    bootware-installer [OPTIONS]

OPTIONS:
    -h, --help                  Print help information
    -u, --user                  Install bootware for current user
    -v, --version <VERSION>     Version of Bootware to install
'@
}

Function CheckEnvironment() {
    If (($PSVersionTable.PSVersion.Major) -LT 5) {
        Write-Output 'PowerShell 5 or later is required to run Bootware.'
        Write-Output 'Upgrade PowerShell: https://docs.microsoft.com/powershell/scripting/windows-powershell/install/installing-windows-powershell'
        Exit 1
    }

    $AllowedExecutionPolicy = @('Unrestricted', 'RemoteSigned', 'ByPass')
    if ((Get-ExecutionPolicy).ToString() -NotIn $AllowedExecutionPolicy) {
        Write-Output "PowerShell requires an execution policy [$($AllowedExecutionPolicy -Join ', ')] to run Bootware."
        Write-Output "To set the execution policy to the recommended 'RemoteSigned' run:"
        Write-Output "'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser'"
        Exit 1
    }
}

# Download file to destination efficiently.
#
# Required as a seperate function, since the default progress bar updates every
# byte, making downloads slow. For more information, visit
# https://stackoverflow.com/a/43477248.
Function DownloadFile($SrcURL, $DstFile) {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -UseBasicParsing -Uri "$SrcURL" -OutFile "$DstFile"
}

# Print error message and exit script with usage error code.
Function ErrorUsage($Message) {
    Throw "Error: $Message"
    Exit 2
}

# Print log message to stdout if logging is enabled.
Function Log($Message) {
    If (!"$Env:BOOTWARE_NOLOG") {
        Write-Output "$Message"
    }
}

# Script entrypoint.
Function Main() {
    $ArgIdx = 0
    $Target = 'Machine'
    $Version = 'master'

    While ($ArgIdx -LT $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            { $_ -In '-h', '--help' } {
                Usage
                Exit 0
            }
            { $_ -In '-v', '--version' } {
                $Version = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            '--user' {
                $Target = 'User'
                $ArgIdx += 1
                Break
            }
            Default {
                ErrorUsage "No such option '$($Args[0][$ArgIdx])'"
            }
        }
    }

    CheckEnvironment
    $Source = "https://raw.githubusercontent.com/scruffaluff/bootware/$Version/bootware.ps1"
    If ($Target -Eq 'User') {
        $Dest = "$Env:AppData/Bootware/bootware.ps1"
    }
    Else {
        $Dest = 'C:/Program Files/Bootware/bootware.ps1'
    }

    $DestDir = Split-Path -Path "$Dest" -Parent
    # Explicit path update needed, since SetEnvironmentVariable does not seem to
    # instantly take effect.
    $Env:Path = "$DestDir" + ";$Env:Path"

    $Path = [Environment]::GetEnvironmentVariable('Path', "$Target")
    If (-Not ($Path -Like "*$DestDir*")) {
        [System.Environment]::SetEnvironmentVariable(
            'Path', "$DestDir" + ";$Path", "$Target"
        )
    }

    Log 'Installing Bootware'

    New-Item -Force -ItemType Directory -Path "$DestDir" | Out-Null
    DownloadFile "$Source" "$Dest"
    Log "Installed $(bootware --version)"
}

# Only run Main if invoked as script. Otherwise import functions as library.
If ($MyInvocation.InvocationName -NE '.') {
    Main $Args
}
