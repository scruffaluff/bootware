# If unable to execute due to policy rules, run
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser.


# Show CLI help information.
Function Usage() {
    Switch ($Args[0]) {
        "bootstrap" {
            Write-Output @'
Bootware bootstrap
Boostrap install computer software

USAGE:
    bootware bootstrap [OPTIONS]

OPTIONS:
    -c, --config <PATH>             Path to bootware user configuation file
    -h, --help                      Print help information
    -i, --inventory <IP-List>       Ansible host IP addesses in quotes
        --no-passwd                 Do not ask for user password
        --no-setup                  Skip Bootware dependency installation
    -p, --playbook <FILE-NAME>      Name of play to execute
        --password <PASSWORD>       Remote host user password
    -s, --skip <TAG-LIST>           Ansible playbook tags to skip in quotes
    -t, --tags <TAG-LIST>           Ansible playbook tags to select in quotes
    -u, --url <URL>                 URL of playbook repository
        --user <USER-NAME>          Remote host user login name
'@
        }
        "config" {
            Write-Output @'
Bootware config
Download default Bootware configuration file

USAGE:
    bootware config [OPTIONS]

OPTIONS:
    -d, --dest <PATH>       Path to alternate download destination
    -e, --empty             Write empty configuration file
    -h, --help              Print help information
    -s, --source <URL>      URL to configuration file
'@
        }
        "main" {
            Write-Output @'
Bootware 0.3.3
Boostrapping software installer

USAGE:
    bootware [OPTIONS] [SUBCOMMAND]

OPTIONS:
    -h, --help       Print help information
    -v, --version    Print version information

SUBCOMMANDS:
    bootstrap        Boostrap install computer software
    config           Generate Bootware configuration file
    setup            Install dependencies for Bootware
    update           Update Bootware to latest version

See 'bootware <subcommand> --help' for more information on a specific command.
'@
        }
        "setup" {
            Write-Output @'
Bootware setup
Install dependencies for Bootware

USAGE:
    bootware setup [OPTIONS]

OPTIONS:
    -h, --help              Print help information
        --checkout <REF>    Git reference to run against
    --no-wsl                Do not configure WSL
    -u, --url <URL>         URL of playbook repository
'@
        }
        "update" {
            Write-Output @'
Bootware update
Update Bootware to latest version

USAGE:
    bootware update [FLAGS]

FLAGS:
    -h, --help                  Print help information
    -v, --version <VERSION>     Version override for update
'@
        }
    }
}

# Subcommand to bootstrap software installations.
Function Bootstrap() {
    $ArgIdx = 0
    $ConfigPath = ""
    $Playbook = "$PSScriptRoot/repo/main.yaml"
    $Skip = "none"
    $Tags = "desktop"
    $URL = "https://github.com/wolfgangwazzlestrauss/bootware.git"
    $UsePasswd = 1
    $UseSetup = 1
    $User = "$Env:UserName"

    # Find IP address of Windows host relative from WSL. Taken from
    # https://github.com/Microsoft/WSL/issues/1032#issuecomment-677727024.
    If (Get-Command wsl -ErrorAction SilentlyContinue) {
        $Inventory = "$(FindRelativeIP)"
    } Else {
        Throw "Error: The setup subcommand needs to be run before bootstrap"
        Exit 1
    }

    While ($ArgIdx -lt $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            {$_ -In "-c", "--config"} {
                $ConfigPath = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            {$_ -In "-h", "--help"} {
                Usage "bootstrap"
                Exit 0
            }
            {$_ -In "-i", "--inventory"} {
                $Inventory = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            "--no-passwd" {
                $UsePasswd = 0
                $ArgIdx += 1
                Break
            }
            "--no-setup" {
                $UseSetup = 0
                $ArgIdx += 1
                Break
            }
            {$_ -In "-p", "--playbook"} {
                $Playbook = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            {$_ -In "-s", "--skip"} {
                $Skip = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            {$_ -In "-t", "--tags"} {
                $Tags = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            {$_ -In "-u", "--url"} {
                $URL = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            "--user" {
                $User = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            Default {
                ErrorUsage "No such option '$($Args[0][$ArgIdx])'"
            }
        }
    }

    If ($UseSetup) {
        $Params = @()
        $Params += "--url", "$URL"
        Setup $Params
    }

    FindConfigPath "$ConfigPath"
    $ConfigPath = $(WSLPath "$Global:RetVal")
    $KeyPath = $(WSLPath "$(FindKeyPath)")
    $PlaybookPath = $(WSLPath "$Playbook")

    # TODO: Fix encoding errors from Ubuntu using Windows configuration file.
    wsl bootware bootstrap --windows --inventory "$Inventory" --playbook "$PlaybookPath" --tags "$Tags" --skip "$Skip" --ssh-key "$KeyPath" --user "$User"
}

# Subcommand to generate or download Bootware configuration file.
Function Config() {
    $ArgIdx = 0
    $SrcURL = "https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/host_vars/bootware.yaml"
    $DstFile = "$HOME/.bootware/config.yaml"
    $EmptyCfg = 0

    While ($ArgIdx -lt $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            {$_ -In "-d", "--dest"} {
                $DstFile = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            {$_ -In "-e", "--empty"} {
                $EmptyCfg = 1
                $ArgIdx += 1
                Break
            }
            {$_ -In "-h", "--help"} {
                Usage "config"
                Exit 0
            }
            {$_ -In "-s", "--source"} {
                $SrcURL = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            Default {
                ErrorUsage "No such option '$($Args[0][$ArgIdx])'"
            }
        }
    }

    New-Item -Force -ItemType Directory -Path $(Split-Path -Path $DstFile -Parent) | Out-Null

    If ($EmptyCfg) {
        Log "Writing empty configuration file to $DstFile"
        Write-Output "passwordless_sudo: false" > "$DstFile"
    } Else {
        # Log "Downloading configuration file to $DstFile"
        DownloadFile "$SrcURL" "$DstFile"
    }
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

# Find path of Bootware configuation file.
Function FindConfigPath($FilePath) {
    If (($FilePath) -And (Test-Path -Path "$FilePath" -PathType Leaf)) {
        $ConfigPath = $FilePath
    } ElseIf (($Env:BOOTWARE_CONFIG) -And (Test-Path -Path "$Env:BOOTWARE_CONFIG")) {
        $ConfigPath = "$Env:BOOTWARE_CONFIG"
    } ElseIf (Test-Path -Path "$HOME/.bootware/config.yaml" -PathType Leaf) {
        $ConfigPath = "$HOME/.bootware/config.yaml"
    } Else {
        Log "Unable to find Bootware configuation file"
        $Params = @()
        $Params += @("--empty")
        Config $Params
        $ConfigPath = "$HOME/.bootware/config.yaml"
    }

    Log "Using $ConfigPath as configuration file"
    $Global:RetVal = "$ConfigPath"
}

# Find path of Bootware private SSH key.
Function FindKeyPath() {
    Write-Output "$PSScriptRoot/ssh/bootware"
}

# Find IP address of Windows host relative from WSL.
#
# The first "nameserver <ip-address>" section of /etc/resolv.conf contains the
# IP address of the windows host. Note that there can be several namserver
# sections. For more information, visit
# https://docs.microsoft.com/en-us/windows/wsl/compare-versions#accessing-windows-networking-apps-from-linux-host-ip.
Function FindRelativeIP {
    Write-Output "$(wsl grep -Po "'nameserver\s+\K([0-9]{1,3}\.){3}[0-9]{1,3}'" /etc/resolv.conf `| head -1),"
}

# Print log message to stdout if logging is enabled.
Function Log($Message) {
    If (!"$Env:BOOTWARE_NOLOG") {
        Write-Output "$Message"
    }
}

# Subcommand to configure boostrapping services and utilities.
Function Setup() {
    $ArgIdx = 0
    $Branch = "master"
    $URL = "https://github.com/wolfgangwazzlestrauss/bootware.git"
    $WSL = 1

    While ($ArgIdx -lt $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            {$_ -In "-h", "--help"} {
                Usage "setup"
                Exit 0
            }
            "--checkout" {
                $Branch = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            "--no-wsl" {
                $WSL = 0
                $ArgIdx += 1
                Break
            }
            {$_ -In "-u", "--url"} {
                $URL = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            Default {
                ErrorUsage "No such option '$($Args[0][$ArgIdx])'"
            }
        }
    }

    # Install Chocolatey package manager.
    If (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Log "Downloading Chocolatey package manager"

        # The progress bar updates every byte, which makes downloads slow. See
        # https://stackoverflow.com/a/43477248 for an explanation.
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -UseBasicParsing -Uri "https://chocolatey.org/install.ps1" | Invoke-Expression

        # Several packages require the Visual C++ build tools and Chocolatey
        # requires user interaction yes prompt.
        Log "Installing Visual C++ build tools"
        choco install -y microsoft-visual-cpp-build-tools
    }

    # Install Scoop package manager.
    If (-Not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Log "Downloading Scoop package manager"

        # The progress bar updates every byte, which makes downloads slow. See
        # https://stackoverflow.com/a/43477248 for an explanation.
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -UseBasicParsing -Uri "https://get.scoop.sh" | Invoke-Expression
    }

     # Git is required for addding Scoop buckets.
    If (-Not (Get-Command git -ErrorAction SilentlyContinue)) {
        scoop install git
    }

    $ScoopBuckets = $(scoop bucket list)
    ForEach ($Bucket in @("extras", "main", "nerd-fonts", "versions")) {
        If ($Bucket -NotIn $ScoopBuckets) {
            scoop bucket add "$Bucket"
        }
    }

    $RepoPath = "$PSScriptRoot/repo"
    If (-Not (Test-Path -Path "$RepoPath" -PathType Any)) {
        git clone --single-branch --branch "$Branch" --depth 1 "$URL" "$RepoPath"
    }

    SetupSSH

    If ($WSL) {
        SetupWSL "$Branch"
    }
}

# Launch OpenSSH server and create inbound network rule.
Function SetupSSH() {
    $KeyPath = $(FindKeyPath)
    $SSHPath = $(Split-Path $KeyPath -Parent)

    If (-Not (Test-Path -Path "$SSHPath" -PathType Container)) {
        Log "Setting up OpenSSH server"
        New-Item -Force -ItemType Directory -Path "$SSHPath"

        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        New-NetFirewallRule -Name sshd -DisplayName "OpenSSH Server" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

        ssh-keygen -N "" -q -f "$KeyPath" -t ed25519
        $PublicKey = Get-Content -Path "$KeyPath.pub"
        Add-Content -Path "C:/ProgramData/ssh/administrators_authorized_keys" -Value $PublicKey
        icacls.exe "C:/ProgramData/ssh/administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
    }

    Start-Service sshd
}

# Install WSL2 with Ubuntu.
#
# Implemented based on instructions at
# https://docs.microsoft.com/en-us/windows/wsl/install-win10.
Function SetupWSL($Branch) {
    If (-Not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

        Log "Restart your system to finish WSL installation"
        Log "Then run bootware setup again to install Ubuntu"
        Exit 0
    }

    # Unable to figure a better way to check if a Linux distro is installed.
    # Checking output of wsl list seems to never work.
    $MatchString = "A WSL distro is installed"
    $DistroCheck = "$(wsl echo $MatchString)"
    If (-Not ("$DistroCheck" -Like "$MatchString")) {
        $TempFile = [System.IO.Path]::GetTempFileName() -Replace ".tmp", ".msi"
        Log "Downloading WSL update"
        DownloadFile "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" $TempFile
        Start-Process -Wait $TempFile /Passive

        wsl --set-default-version 2

        $TempFile = [System.IO.Path]::GetTempFileName() -Replace ".tmp", ".zip"
        $TempDir = $TempFile -Replace ".zip", ""
        Log "Downloading Ubuntu image. Follow the prompt for installation"
        DownloadFile "https://aka.ms/wslubuntu2004" $TempFile

        Expand-Archive "$TempFile" "$TempDir"
        & "$TempDir/ubuntu2004.exe"
        Exit 0
    }

    If (-Not (wsl command -v bootware)) {
        Log "Installing a WSL copy of Bootware"
        wsl curl -LSfs https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/install.sh `| bash -s -- --version "$Branch"

    }
}

# Subcommand to update Bootware script
Function Update() {
    $ArgIdx = 0
    $Version = "master"

    While ($ArgIdx -lt $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            {$_ -In "-h", "--help"} {
                Usage "update"
                Exit 0
            }
            {$_ -In "-v", "--version"} {
                $Version = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            Default {
                ErrorUsage "No such option '$($Args[0][$ArgIdx])'"
            }
        }
    }

    $SrcURL = "https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/$Version/bootware.ps1"
    DownloadFile "$SrcURL" "$PSScriptRoot/bootware.ps1"

    # Update WSL copy of Bootware.
    If (Get-Command wsl -ErrorAction SilentlyContinue) {
        wsl bootware update --version `> /dev/null
    }

    # Update playbook repository.
    $RepoPath = "$PSScriptRoot/repo"
    If (Test-Path -Path "$RepoPath" -PathType Container) {
        git -C "$RepoPath" pull
    }

    Log "Updated to version $(bootware --version)"
}

# Print Bootware version string.
Function Version() {
    Write-Output "Bootware 0.3.3"
}

# Convert path to WSL relative path.
Function WSLPath($FilePath) {
    $Drive = $(Split-Path -Path "$FilePath" -Qualifier) -Replace ':',''
    $ChildPath = $(Split-Path -Path "$FilePath" -NoQualifier) -Replace "\\","/"
    Write-Output "/mnt/$($Drive.ToLower())$ChildPath"
}

# Script entrypoint.
Function Main() {
    # Get subcommand parameters.
    If ($Args[0].Length -gt 1) {
        $Slice = $Args[0][1..($Args[0].Length-1)]
    } Else {
        $Slice = @()
    }

    Switch ($Args[0][0]) {
        {$_ -In "-h", "--help"} {
            Usage "main"
            Break
        }
        {$_ -In "-v", "--version"} {
            Version
            Break
        }
        "bootstrap" {
            Bootstrap $Slice
            Break
        }
        "config" {
            Config $Slice
            Break
        }
        "setup" {
            Setup $Slice
            Break
        }
        "update" {
            Update $Slice
            Break
        }
        Default {
            ErrorUsage "No such subcommand '$($Args[0][0])'"
        }
    }
}

# Only run Main if invoked as script. Otherwise import functions as library.
If ($MyInvocation.InvocationName -ne '.') {
    Main $Args
}
