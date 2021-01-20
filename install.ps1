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
    $User = false
    $Version = "master"

    ForEach ($Arg in $Args) {
        Switch ($Arg) {
            "-h" { Usage; Exit 0 }
            "--help" { Usage; Exit 0 }
            "-v" { $Version = Args[1] }
            "--version" { $Version = Args[1] }
            "--user" { $User = true }
        }
    }

    $Source = "https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/$Version/bootware.ps1"
    If ($User) {
        $Dest = "$Env:AppData/Roaming/Bootware/bootware.ps1"
        [System.Environment]::SetEnvironmentVariable("PATH", "$Dest.Parent" + ";$Env:PATH", "User")
    } Else {
        $Dest = "C:/Program Files/Bootware/bootware.ps1"
        [System.Environment]::SetEnvironmentVariable("PATH", "$Dest.Parent" + ";$Env:PATH", "Machine")
    }

    echo "Installing Bootware..."

    New-Item -Force -ItemType Directory -Path $Dest.Parent
    Invoke-WebRequest -UseBasicParsing -Uri "$Source" -OutFile "$Dest"

    echo "Installed $(bootware --version)."
}

Main $Args
