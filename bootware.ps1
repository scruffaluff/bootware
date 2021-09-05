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
                $Skip = $Args[0][$ArgIdx + 1] -Join ","
                $ArgIdx += 2
                Break
            }
            {$_ -In "-t", "--tags"} {
                $Tags = $Args[0][$ArgIdx + 1] -Join ","
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
    } ElseIf (-Not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Throw "Error: The WSL needs to be setup before bootstrapping"
        Exit 1
    }

    FindConfigPath "$ConfigPath"
    $ConfigPath = $(WSLPath "$Global:RetVal")
    $Inventory = "$(FindRelativeIP)"
    $PlaybookPath = $(WSLPath "$Playbook")

    # TODO: Fix errors when Ubuntu uses Windows encoded configuration file.
    wsl bootware bootstrap --windows `
        --inventory "$Inventory," `
        --playbook "$PlaybookPath" `
        --skip "$Skip" `
        --ssh-key "`${HOME}/.ssh/bootware" `
        --tags "$Tags" `
        --user "$User"
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

    $DstDir = "$(Split-Path -Path $DstFile -Parent)"
    If (-Not (Test-Path -Path "$DstDir" -PathType Container)) {
        New-Item -ItemType Directory -Path "$DstDir"
    }

    If ($EmptyCfg) {
        Log "Writing empty configuration file to $DstFile"
        Write-Output "passwordless_sudo: false" > "$DstFile"
    } Else {
        # Log "Downloading configuration file to $DstFile"
        DownloadFile "$SrcURL" "$DstFile"
    }
}

# Download file to destination efficiently.
#
# Required as a seperate function, since the default progress bar updates every
# byte, making downloads slow. For more information, visit
# https://stackoverflow.com/a/43477248.
Function DownloadFile($SrcURL, $DstFile) {
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

# Find IP address of Windows host relative from WSL.
#
# For WSL version, the Linux subsystem and the Windows host share the same
# network. For WSL version 2, the first "nameserver <ip-address>" section of
# /etc/resolv.conf contains the IP address of the windows host. Note that there
# can be several namserver sections. For more information, visit
# https://docs.microsoft.com/en-us/windows/wsl/compare-versions#accessing-windows-networking-apps-from-linux-host-ip.
Function FindRelativeIP {
    wsl -l -v 2>&1 | Out-Null

    If ($LastExitCode) {
        Write-Output "127.0.0.1"
    } Else {
        Write-Output "$(wsl grep -Po "'nameserver\s+\K([0-9]{1,3}\.){3}[0-9]{1,3}'" /etc/resolv.conf `| head -1)"
    }
}

# Print log message to stdout if logging is enabled.
Function Log($Message) {
    If (!"$Env:BOOTWARE_NOLOG") {
        Write-Output "$Message"
    }
}

# Request remote script and execution efficiently.
#
# Required as a seperate function, since the default progress bar updates every
# byte, making downloads slow. For more information, visit
# https://stackoverflow.com/a/43477248.
Function RemoteScript($URL) {
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -UseBasicParsing -Uri "$URL" | Invoke-Expression
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
        RemoteScript "https://chocolatey.org/install.ps1"

        # Several packages require the Visual C++ build tools and Chocolatey
        # requires user interaction yes prompt.
        Log "Installing Visual C++ build tools"
        choco install -y microsoft-visual-cpp-build-tools
    }

    # Install Scoop package manager.
    If (-Not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Log "Downloading Scoop package manager"
        RemoteScript "https://get.scoop.sh"
    }

     # Git is required for addding Scoop buckets.
    If (-Not (Get-Command git -ErrorAction SilentlyContinue)) {
        Log "Downloading Git version control"
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
        git clone `
            --single-branch `
            --branch "$Branch" `
            --depth 1 "$URL" `
            "$RepoPath"
    }

    # WSL version 1 requires the Windows host SSH server to be initialized
    # before the WSL is setup. Since the Windows host and WSL share networking
    # for WSL version 1, the hypothesis is that whichever OS sets up the SSH
    # server handles all connections.
    SetupSSHServer

    If ($WSL) {
        SetupWSL "$Branch"
        SetupSSHKeys
    }
}

# Create SSH keys to connect to Windows host and scan for fingerprints.
# TODO: Add logic to skip if SSH key already exists.
Function SetupSSHKeys {
    $SetupSSHKeysComplete = "$PSScriptRoot/.setup_ssh_keys"
    If (-Not (Test-Path -Path "$SetupSSHKeysComplete" -PathType Leaf)) {
        Log "Generating SSH keys"

        # GetTempFileName creates a 0 byte file, so it has to be deleted to work
        # with ssh-keygen.
        $WindowsKeyPath = [System.IO.Path]::GetTempFileName()
        Remove-Item -Force -Path "$WindowsKeyPath"

        ssh-keygen -N '""' -q -f "$WindowsKeyPath" -t ed25519
        $PublicKey = Get-Content -Path "$WindowsKeyPath.pub"
        Add-Content `
            -Path "C:/ProgramData/ssh/administrators_authorized_keys" `
            -Value $PublicKey
        
        $WSLKeyPath = "$(WSLPath $WindowsKeyPath)"
        wsl mkdir -p -m 700 "${HOME}/.ssh/"
        wsl mv "$WSLKeyPath" "`${HOME}/.ssh/bootware"
        wsl chmod 600 "${HOME}/.ssh/bootware"
        wsl mv "$WSLKeyPath.pub" "${HOME}/.ssh/bootware.pub"
        wsl ssh-keyscan "$(FindRelativeIP)" `1`>`> "${HOME}/.ssh/known_hosts"

        New-Item -ItemType File -Path "$SetupSSHKeysComplete"
    }
}

# Launch OpenSSH server and create inbound network rule.
#
# Based on documentation from
# https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse.
Function SetupSSHServer() {
    $SetupSSHServerComplete = "$PSScriptRoot/.setup_ssh_server"
    If (-Not (Test-Path -Path "$SetupSSHServerComplete" -PathType Leaf)) {
        Log "Setting up OpenSSH server"

        # Turn on Windows Update and TrustedInstaller services
        Start-Service -name wuauserv

        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        New-NetFirewallRule `
            -Action Allow `
            -Direction Inbound `
            -DisplayName "Bootware SSH" `
            -Enabled True `
            -LocalPort 22 `
            -Name sshd `
            -Protocol TCP

        # OpenSSH default shell needs to match the shell used by Ansible. For
        # more information, visit
        # https://groups.google.com/g/ansible-project/c/quRiK_2WKtE/m/NcXnDsp_CQAJ.
        New-ItemProperty `
            -Force `
            -Name DefaultShell `
            -Path "HKLM:\SOFTWARE\OpenSSH" `
            -PropertyType String `
            -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

        # Administrative Windows users must have their accepted public keys
        # stored in C:/ProgramData/ssh/administrators_authorized_keys with
        # specific permissions. For more information, visit
        # https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement#administrative-user.
        $AuthKeys = "C:/ProgramData/ssh/administrators_authorized_keys"
        If (-Not (Test-Path -Path "$AuthKeys" -PathType Leaf)) {
            New-Item -ItemType File -Path "$AuthKeys"
        }
        icacls.exe "$AuthKeys" `
            /grant "Administrators:F" `
            /grant "SYSTEM:F" `
            /inheritance:r

        New-Item -ItemType File -Path "$SetupSSHServerComplete"
    }

    Start-Service sshd
}

# Install WSL2 with Ubuntu.
#
# Implemented based on instructions at
# https://docs.microsoft.com/en-us/windows/wsl/install-win10.
Function SetupWSL($Branch) {
    If (-Not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        dism.exe `
            /all `
            /enable-feature `
            /featurename:Microsoft-Windows-Subsystem-Linux `
            /norestart `
            /online
        dism.exe `
            /all `
            /enable-feature `
            /featurename:VirtualMachinePlatform `
            /norestart `
            /online

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
        DownloadFile `
            "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" `
            $TempFile
        Start-Process -Wait $TempFile /Passive

        # TODO: Add logic for WSL 1 case.
        wsl --set-default-version 2

        $TempFile = [System.IO.Path]::GetTempFileName() -Replace ".tmp", ".zip"
        $TempDir = $TempFile -Replace ".zip", ""
        Log "Downloading Ubuntu image. Follow the prompt for installation"
        DownloadFile "https://aka.ms/wslubuntu2004" "$TempFile"

        Expand-Archive "$TempFile" "$TempDir"
        & "$TempDir/ubuntu2004.exe" exit 0
    }

    If (-Not (wsl command -v bootware)) {
        Log "Installing a WSL copy of Bootware"
        wsl curl -LSfs `
            https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/install.sh `
            `| bash -s -- --version "$Branch"
        wsl bootware setup
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
