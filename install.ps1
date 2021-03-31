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
    -d, --dest <PATH>           Path to install bootware
    -h, --help                  Print help information
    -u, --user                  Install bootware for current user
    -v, --version <VERSION>     Version of Bootware to install
'@
}

# Print error message and exit with error code.
Function Error($Message) {
    Write-Error "Error: $Message"
    Exit 1
}

# Script entrypoint.
Function Main() {
    $Target = "Machine"
    $Version = "master"

    ForEach ($Arg in $Args) {
        Switch ($Arg) {
            "-h" { Usage; Exit 0 }
            "--help" { Usage; Exit 0 }
            "-v" { $Version = Args[1] }
            "--version" { $Version = Args[1] }
            "--user" { $Target = "User" }
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

    Write-Output "Installing Bootware..."

    New-Item -Force -ItemType Directory -Path $DestDir

    # The progress bar updates every byte, which makes downloads slow. See
    # https://stackoverflow.com/a/43477248 for an explanation.
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -UseBasicParsing -Uri "$Source" -OutFile "$Dest"

    Write-Output "Installed $(bootware --version)."
}

Main $Args
