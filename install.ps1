# If unable to execute due to policy rules, run
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser.


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

# Downloads file to destination efficiently.
Function DownloadFile($SrcURL, $DstFile) {
    # The progress bar updates every byte, which makes downloads slow. See
    # https://stackoverflow.com/a/43477248 for an explanation.
    $ProgressPreference = "SilentlyContinue"
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
    $Target = "Machine"
    $Version = "master"

    While ($ArgIdx -lt $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            {$_ -In "-h", "--help"} {
                Usage
                Exit 0
            }
            {$_ -In "-v", "--version"} {
                $Version = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            "--user" {
                $Target = "User"
                $ArgIdx += 1
                Break
            }
            Default {
                ErrorUsage "No such option '$($Args[0][$ArgIdx])'"
            }
        }
    }

    $Source = "https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/$Version/bootware.ps1"
    If ($Target -Eq "User") {
        $Dest = "$Env:AppData/Bootware/bootware.ps1"
    } Else {
        $Dest = "C:/Program Files/Bootware/bootware.ps1"
    }

    $DestDir = Split-Path -Path $Dest -Parent
    $Env:Path = "$DestDir" + ";$Env:Path"
    [System.Environment]::SetEnvironmentVariable("Path", "$Env:Path", "$Target")

    Log "Installing Bootware"

    New-Item -Force -ItemType Directory -Path $DestDir | Out-Null
    DownloadFile "$Source" "$Dest"
    Log "Installed $(bootware --version)"
}

Main $Args
