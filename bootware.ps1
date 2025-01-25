# If unable to execute due to policy rules, run
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser.

# Exit immediately if a PowerShell cmdlet encounters an error.
$ErrorActionPreference = 'Stop'
# Exit immediately when an native executable encounters an error.
$PSNativeCommandUseErrorActionPreference = $True

# Show CLI help information.
Function Usage() {
    Switch ($Args[0]) {
        'bootstrap' {
            Write-Output @'
Bootstrap install computer software.

Usage: bootware bootstrap [OPTIONS]

Options:
      --check                     Perform dry run and show possible changes
  -c, --config <PATH>             Path to bootware user configuration file
      --debug                     Enable Ansible task debugger
  -d, --dev                       Run bootstrapping in development mode
  -h, --help                      Print help information
      --install-group <GROUP>     Remote group to install software for
      --install-user <USER>       Remote user to install software for
  -i, --inventory <IP-LIST>       Ansible remote hosts IP addresses
      --no-passwd                 Do not ask for user password
      --no-setup                  Skip Bootware dependency installation
      --password <PASSWORD>       Remote user login password
  -p, --playbook <FILE>           Path to playbook to execute
      --private-key <FILE>        Path to SSH private key
      --port <INTEGER>            Port for SSH connection
      --retries <INTEGER>         Playbook retry limit during failure
  -s, --skip <TAG-LIST>           Ansible playbook tags to skip
      --start-at-role <ROLE>      Begin execution with role
  -t, --tags <TAG-LIST>           Ansible playbook tags to select
      --temp-key <FILE>           Path to SSH private key for one time connection
  -u, --url <URL>                 URL of playbook repository
      --user <USER>               Remote user login name

Ansible Options:
'@
            wsl ansible --help
        }
        'config' {
            Write-Output @'
Download default Bootware configuration file.

Usage: bootware config [OPTIONS]

Options:
  -d, --dest <PATH>     Path to alternate download destination
  -e, --empty           Write empty configuration file
  -h, --help            Print help information
  -s, --source <URL>    URL to configuration file
'@
        }
        'main' {
            Write-Output @'
Bootstrapping software installer.

Usage: bootware [OPTIONS] [SUBCOMMAND]

Options:
      --debug     Enable shell debug traces
  -h, --help      Print help information
  -v, --version   Print version information

Subcommands:
  bootstrap   Bootstrap install computer software
  config      Generate Bootware configuration file
  roles       List all Bootware roles
  setup       Install dependencies for Bootware
  uninstall   Remove Bootware files
  update      Update Bootware to latest version

Environment Variables:
  BOOTWARE_CONFIG         Set the configuration file path
  BOOTWARE_GITHUB_TOKEN   GitHub API authentication token
  BOOTWARE_NOPASSWD       Assume password less doas or sudo
  BOOTWARE_NOSETUP        Skip Ansible install and system setup
  BOOTWARE_PLAYBOOK       Set Ansible playbook name
  BOOTWARE_SKIP           Set skip tags for Ansible roles
  BOOTWARE_TAGS           Set tags for Ansible roles
  BOOTWARE_URL            Set location of Ansible repository

See 'bootware <subcommand> --help' for more information on a specific command.
'@
        }
        'roles' {
            Write-Output @'
List all Bootware roles.

Usage: bootware roles [OPTIONS]

Options:
  -h, --help              Print help information
  -t, --tags <TAG-LIST>   Ansible playbook tags to select
'@
        }
        'setup' {
            Write-Output @'
Install dependencies for Bootware.

Usage:
    bootware setup [OPTIONS]

Options:
  -h, --help             Print help information
      --checkout <REF>   Git reference to run against
  --no-wsl               Do not configure WSL
  -u, --url <URL>        URL of playbook repository
'@
        }
        'uninstall' {
            Write-Output @'
Remove Bootware files.

Usage: bootware uninstall

Options:
  -h, --help    Print help information
'@
        }
        'update' {
            Write-Output @'
Update Bootware to latest version.

Usage: bootware update [FLAGS]

Options:
  -h, --help                Print help information
  -v, --version <VERSION>   Version override for update
'@
        }
    }
}

# Subcommand to bootstrap software installations.
Function Bootstrap() {
    $ArgIdx = 0
    $ConfigPath = ''
    $Debug = $Global:Debug
    $ExtraArgs = @()
    $Inventory = ''
    $Playbook = "$PSScriptRoot/repo/playbook.yaml"
    $Remote = $False
    $Skip = 'none'
    $Tags = 'desktop'
    $URL = 'https://github.com/scruffaluff/bootware.git'
    $UseSetup = $True
    $User = $Env:UserName

    While ($ArgIdx -LT $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            { $_ -In '-c', '--config' } {
                $ConfigPath = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            { $_ -In '-d', '--dev' } {
                $Playbook = "$(Get-Location)/playbook.yaml"
                $UseSetup = $False
                $ArgIdx += 1
                Break
            }
            { $_ -In '-h', '--help' } {
                Usage 'bootstrap'
                Exit 0
            }
            { $_ -In '-i', '--inventory' } {
                $Inventory = $Args[0][$ArgIdx + 1] -Join ','
                $Remote = $True
                $ArgIdx += 2
                Break
            }
            '--no-setup' {
                $UseSetup = $False
                $ArgIdx += 1
                Break
            }
            { $_ -In '-p', '--playbook' } {
                $Playbook = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            '--private-key' {
                $ExtraArgs += "--private-key"
                $ExtraArgs += MakeWSLKey $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            { $_ -In '-s', '--skip' } {
                $Skip = $Args[0][$ArgIdx + 1] -Join ','
                $ArgIdx += 2
                Break
            }
            '--start-at-role' {
                $StartRole = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            { $_ -In '-t', '--tags' } {
                $Tags = $Args[0][$ArgIdx + 1] -Join ','
                $ArgIdx += 2
                Break
            }
            '--temp-key' {
                $ExtraArgs += "--temp-key"
                $ExtraArgs += MakeWSLKey $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            { $_ -In '-u', '--url' } {
                $URL = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            '--user' {
                $User = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            Default {
                $ExtraArgs += $Args[0][$ArgIdx]
                $ArgIdx += 1
                Break
            }
        }
    }

    If ($UseSetup) {
        $Params = @()
        $Params += '--url', $URL
        Setup $Params
    }
    ElseIf (-Not (Get-Command -ErrorAction SilentlyContinue wsl)) {
        Throw 'Error: The WSL needs to be setup before bootstrapping'
    }

    # Configure run to find task associated with start role.
    If ($StartRole) {
        $RepoPath = Split-Path -Parent -Path $Playbook
        $StartTask = yq '.[0].name' "$RepoPath/ansible_collections/scruffaluff/bootware/roles/$StartRole/tasks/main.yaml"
        $ExtraArgs += @("--start-at-task", $StartTask)
    }

    Try {
        $ConfigPath = FindConfigPath $ConfigPath
    }
    Catch [System.IO.FileNotFoundException] {
        $Params = @()
        $Params += @('--empty')
        Config $Params
        $ConfigPath = "$HOME/.bootware/config.yaml"
    }

    Log "Using $ConfigPath as configuration file"
    $WSLConfigPath = WSLPath $ConfigPath
    If (-Not $Remote) {
        $Inventory = FindRelativeIP
    }
    $PlaybookPath = WSLPath $Playbook

    # Home variable cannot be wrapped in brackets in case the default WSL shell
    # is Fish. Have not found a way to optionally include arguments in
    # PowerShell. If a simpler solution exists, please edit.
    #
    # $ExtraArgs needs to be passed as an array to WSL. Do not change it into a
    # string.
    If ($Debug -And $Remote -And $ExtraArgs.Count -GT 0) {
        wsl bootware --debug bootstrap `
            --config $WSLConfigPath `
            --inventory $Inventory `
            --playbook $PlaybookPath `
            --skip $Skip `
            --tags $Tags `
            --user $User `
            $ExtraArgs
    }
    ElseIf ($Debug -And $Remote) {
        wsl bootware --debug bootstrap `
            --config $WSLConfigPath `
            --inventory $Inventory `
            --playbook $PlaybookPath `
            --tags $Tags `
            --skip $Skip `
            --user $User
    }
    ElseIf ($Remote -And $ExtraArgs.Count -GT 0) {
        wsl bootware bootstrap `
            --config $WSLConfigPath `
            --inventory $Inventory `
            --playbook $PlaybookPath `
            --skip $Skip `
            --tags $Tags `
            --user $User `
            $ExtraArgs
    }
    ElseIf ($Remote) {
        wsl bootware bootstrap `
            --config $WSLConfigPath `
            --inventory $Inventory `
            --playbook $PlaybookPath `
            --skip $Skip `
            --tags $Tags `
            --user $User
    }
    ElseIf ($Debug -And $ExtraArgs.Count -GT 0) {
        wsl bootware --debug bootstrap --windows `
            --config $WSLConfigPath `
            --inventory $Inventory `
            --playbook $PlaybookPath `
            --private-key "`$HOME/.ssh/bootware" `
            --skip $Skip `
            --ssh-extra-args "'-o StrictHostKeyChecking=no'" `
            --tags $Tags `
            --user $User `
            $ExtraArgs
    }
    ElseIf ($Debug) {
        wsl bootware --debug bootstrap --windows `
            --config $WSLConfigPath `
            --inventory $Inventory `
            --playbook $PlaybookPath `
            --private-key "`$HOME/.ssh/bootware" `
            --skip $Skip `
            --ssh-extra-args "'-o StrictHostKeyChecking=no'" `
            --tags $Tags `
            --user $User
    }
    ElseIf ($ExtraArgs.Count -GT 0) {
        wsl bootware bootstrap --windows `
            --config $WSLConfigPath `
            --inventory $Inventory `
            --playbook $PlaybookPath `
            --private-key "`$HOME/.ssh/bootware" `
            --skip $Skip `
            --ssh-extra-args "'-o StrictHostKeyChecking=no'" `
            --tags $Tags `
            --user $User `
            $ExtraArgs
    }
    Else {
        wsl bootware bootstrap --windows `
            --config $WSLConfigPath `
            --inventory $Inventory `
            --playbook $PlaybookPath `
            --private-key "`$HOME/.ssh/bootware" `
            --skip $Skip `
            --ssh-extra-args "'-o StrictHostKeyChecking=no'" `
            --tags $Tags `
            --user $User
    }
}

# Subcommand to generate or download Bootware configuration file.
Function Config() {
    $ArgIdx = 0
    $SrcURL = ''
    $DstFile = "$HOME/.bootware/config.yaml"
    $EmptyCfg = $False

    While ($ArgIdx -LT $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            { $_ -In '-d', '--dest' } {
                $DstFile = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            { $_ -In '-e', '--empty' } {
                $EmptyCfg = $True
                $ArgIdx += 1
                Break
            }
            { $_ -In '-h', '--help' } {
                Usage 'config'
                Exit 0
            }
            { $_ -In '-s', '--source' } {
                $SrcURL = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            Default {
                ErrorUsage "No such option '$($Args[0][$ArgIdx])'"
            }
        }
    }

    $DstDir = Split-Path -Parent -Path $DstFile
    If (-Not (Test-Path -Path $DstDir -PathType Container)) {
        New-Item -ItemType Directory -Path $DstDir | Out-Null
    }

    If ($EmptyCfg -Or (-Not $SrcURL)) {
        Log "Writing empty configuration file to $DstFile"
        # Do not use Write-Output. On PowerShell 5, it will add a byte order
        # marker to the file, which makes WSL Ansible throw UTF-8 errors.
        # Solution was taken from https://stackoverflow.com/a/32951824.
        [System.IO.File]::WriteAllLines($DstFile, 'font_size: 14')
    }
    Else {
        # Log "Downloading configuration file to $DstFile"
        DownloadFile $SrcURL $DstFile
    }
}

# Download file to destination efficiently.
#
# Required as a separate function, since the default progress bar updates every
# byte, making downloads slow. For more information, visit
# https://stackoverflow.com/a/43477248.
Function DownloadFile($SrcURL, $DstFile) {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -UseBasicParsing -OutFile $DstFile -Uri $SrcURL
}

# Print error message and exit script with usage error code.
Function ErrorUsage($Message) {
    Write-Error "Error: $Message"
    Exit 2
}

# Find path of Bootware configuration file.
Function FindConfigPath($FilePath) {
    $ConfigPath = ''

    If (($FilePath) -And (Test-Path -Path $FilePath -PathType Leaf)) {
        $ConfigPath = $FilePath
    }
    ElseIf (($Env:BOOTWARE_CONFIG) -And (Test-Path -Path "$Env:BOOTWARE_CONFIG")) {
        $ConfigPath = "$Env:BOOTWARE_CONFIG"
    }
    ElseIf (Test-Path -Path "$HOME/.bootware/config.yaml" -PathType Leaf) {
        $ConfigPath = "$HOME/.bootware/config.yaml"
    }
    Else {
        Throw [System.IO.FileNotFoundException] `
            'Unable to find Bootware configuration file'
    }

    Return $ConfigPath
}

# Find IP address of Windows host relative from WSL.
#
# For WSL version 1, the Linux subsystem and the Windows host share the same
# network. For WSL version 2, the first "nameserver <ip-address>" section of
# /etc/resolv.conf contains the IP address of the windows host. Note that there
# can be several nameserver sections. For more information, visit
# https://docs.microsoft.com/en-us/windows/wsl/compare-versions#accessing-windows-networking-apps-from-linux-host-ip.
Function FindRelativeIP {
    $WSLVersion = Get-ItemPropertyValue `
        -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss' `
        -Name DefaultVersion

    If ($WSLVersion -Eq 1) {
        Return '127.0.0.1'
    }
    Else {
        Return wsl grep -Po "'nameserver\s+\K([0-9]{1,3}\.){3}[0-9]{1,3}'" /etc/resolv.conf `| head -1
    }
}

# Get parameters for subcommands.
Function GetParameters($Params, $Index) {
    If ($Params.Length -GT $Index) {
        Return $Params[$Index..($Params.Length - 1)]
    }
    Else {
        Return @()
    }
}

# Check if script is run from an admin console.
Function IsAdministrator {
    Return (New-Object Security.Principal.WindowsPrincipal( `
                [Security.Principal.WindowsIdentity]::GetCurrent() `
        )).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Print log message to stdout if logging is enabled.
Function Log($Message) {
    If (!"$Env:BOOTWARE_NOLOG") {
        Write-Output $Message
    }
}

# Copy SSH private key to WSL temporary path with correct permissions.
#
# Required when SSH private key lives in Windows file system, since its open
# permissions cannot be changed.
Function MakeWSLKey($FilePath) {
    $WSLFile = wsl mktemp --dry-run
    wsl cp "$(WSLPath $FilePath)" $WSLFile
    wsl chmod 600 $WSLFile
    Return $WSLFile
}

# Request remote script and execution efficiently.
#
# Required as a separate function, since the default progress bar updates every
# byte, making downloads slow. For more information, visit
# https://stackoverflow.com/a/43477248.
Function RemoteScript($URL) {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -UseBasicParsing -Uri $URL | Invoke-Expression
}

# Subcommand to list all Bootware roles.
Function Roles() {
    $ArgIdx = 0
    $Tags = ''

    While ($ArgIdx -LT $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            { $_ -In '-h', '--help' } {
                Usage 'roles'
                Exit 0
            }
            { $_ -In '-t', '--tags' } {
                $Tags = $Args[0][$ArgIdx + 1] -Join ','
                $ArgIdx += 2
                Break
            }
            Default {
                ErrorUsage "No such option '$($Args[0][$ArgIdx])'"
            }
        }
    }

    $TagList = "[`"$($Tags.Replace(',', '`", `"'))`"]"
    $Filter = ".[0].tasks[] | select(.tags | contains($TagList))"
    $Format = '."ansible.builtin.import_role".name  | sub("scruffaluff.bootware.", "")'
    yq "$Filter | $Format" "$PSScriptRoot/repo/playbook.yaml"
}

# Subcommand to configure bootstrapping services and utilities.
Function Setup() {
    $ArgIdx = 0
    $Branch = 'main'
    $URL = 'https://github.com/scruffaluff/bootware.git'
    $WSL = $True

    While ($ArgIdx -LT $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            { $_ -In '-h', '--help' } {
                Usage 'setup'
                Exit 0
            }
            '--checkout' {
                $Branch = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            '--no-wsl' {
                $WSL = $False
                $ArgIdx += 1
                Break
            }
            { $_ -In '-u', '--url' } {
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
    If (-Not (Get-Command -ErrorAction SilentlyContinue choco)) {
        Log 'Downloading Chocolatey package manager'
        RemoteScript 'https://chocolatey.org/install.ps1'
    }

    # Install Scoop package manager.
    If (-Not (Get-Command -ErrorAction SilentlyContinue scoop)) {
        Log 'Downloading Scoop package manager'
        # Scoop disallows installation from an admin console by default. For
        # more information, visit
        # https://github.com/ScoopInstaller/Install#for-admin.
        If (IsAdministrator) {
            $ScoopInstaller = [System.IO.Path]::GetTempFileName() -Replace '.tmp', '.ps1'
            DownloadFile 'get.scoop.sh' $ScoopInstaller
            & $ScoopInstaller -RunAsAdmin
            Remove-Item -Force -Path $ScoopInstaller
        }
        Else {
            RemoteScript 'https://get.scoop.sh'
        }

        # Add Scoop shims to system path.
        $Path = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $GlobalShims = 'C:\ProgramData\scoop\shims'
        If (-Not ($Path -Like "*$GlobalShims*")) {
            [System.Environment]::SetEnvironmentVariable(
                'Path', $GlobalShims + ";$Path", 'Machine'
            )
        }
        $Path = [Environment]::GetEnvironmentVariable('Path', 'User')
        $UserShims = "$HOME\scoop\shims"
        If (-Not ($Path -Like "*$UserShims*")) {
            [System.Environment]::SetEnvironmentVariable(
                'Path', $UserShims + ";$Path", 'User'
            )
        }
    }

    # Git is required for adding Scoop buckets.
    If (-Not (Get-Command -ErrorAction SilentlyContinue git)) {
        Log 'Installing Git'
        scoop install mingit
    }

    If (-Not (Get-Command -ErrorAction SilentlyContinue yq)) {
        Log 'Installing YQ'
        scoop install yq
    }

    $ScoopBuckets = scoop bucket list
    ForEach ($Bucket In @('extras', 'main', 'versions')) {
        If ($Bucket -NotIn $ScoopBuckets.Name) {
            scoop bucket add $Bucket
        }
    }

    $RepoPath = "$PSScriptRoot/repo"
    If (-Not (Test-Path -Path $RepoPath -PathType Any)) {
        git clone `
            --single-branch `
            --branch $Branch `
            --depth 1 $URL `
            $RepoPath
    }

    # WSL version 1 requires the Windows host SSH server to be initialized
    # before the WSL is setup. Since the Windows host and WSL share networking
    # for WSL version 1, the hypothesis is that whichever OS sets up the SSH
    # server handles all connections.
    SetupSSHServer

    If ($WSL) {
        SetupWSL $Branch
        SetupSSHKeys
    }
}

# Create SSH keys to connect to Windows host and scan for fingerprints.
Function SetupSSHKeys {
    $SetupSSHKeysComplete = "$PSScriptRoot/.setup_ssh_keys"
    If (-Not (Test-Path -Path $SetupSSHKeysComplete -PathType Leaf)) {
        Log 'Generating SSH keys'

        # GetTempFileName creates a 0 byte file, so it has to be deleted to work
        # with ssh-keygen.
        $WindowsKeyPath = [System.IO.Path]::GetTempFileName()
        Remove-Item -Force -Path $WindowsKeyPath

        # SSH key generation behavior for empty passphrases is different between
        # PowerShell versions.
        If ($PSVersionTable.PSVersion.Major -GE 7) {
            ssh-keygen -q -N '' -f $WindowsKeyPath -t ed25519 -C 'bootware'
        }
        Else {
            ssh-keygen -q -N '""' -f $WindowsKeyPath -t ed25519 -C 'bootware'
        }
        $PublicKey = Get-Content -Path "$WindowsKeyPath.pub"
        Add-Content `
            -Path 'C:/ProgramData/ssh/administrators_authorized_keys' `
            -Value $PublicKey

        Log 'Moving SSH keys to WSL'

        # Home variable cannot be wrapped in brackets in case the default WSL
        # shell is Fish.
        $WSLKeyPath = WSLPath $WindowsKeyPath
        wsl mkdir --parents --mode 700 "`$HOME/.ssh"
        wsl mv $WSLKeyPath "`$HOME/.ssh/bootware"
        wsl chmod 600 "`$HOME/.ssh/bootware"
        wsl mv "$WSLKeyPath.pub" "`$HOME/.ssh/bootware.pub"

        wsl sudo apt-get --quiet update
        wsl sudo apt-get --quiet install --yes openssh-client
        wsl ssh-keyscan "$(FindRelativeIP)" `1`>`> "`$HOME/.ssh/known_hosts"

        Log 'Disabling SSH password authentication'

        # Disable password based logins for SSH.
        Add-Content `
            -Path "$Env:ProgramData/ssh/sshd_config" `
            -Value 'PasswordAuthentication no'

        New-Item -ItemType File -Path $SetupSSHKeysComplete | Out-Null
        Log 'Completed SSH key configuration'
    }
}

# Launch OpenSSH server and create inbound network rule.
#
# Based on documentation from
# https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse.
Function SetupSSHServer() {
    $SetupSSHServerComplete = "$PSScriptRoot/.setup_ssh_server"
    If (-Not (Test-Path -Path $SetupSSHServerComplete -PathType Leaf)) {
        Log 'Setting up OpenSSH server'

        # Turn on Windows Update and TrustedInstaller services.
        Start-Service -ErrorAction SilentlyContinue -Name wuauserv
        If ($? -Eq $False) {
            Set-Service -Name wuauserv -StartupType Manual
            Start-Service -Name wuauserv
        }

        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        If (
            (-Not (Get-NetFirewallRule -DisplayName 'Bootware SSH' -ErrorAction SilentlyContinue)) -And
            (-Not (Get-NetFirewallRule -Name 'sshd' -ErrorAction SilentlyContinue))
        ) {
            New-NetFirewallRule `
                -Action Allow `
                -Direction Inbound `
                -DisplayName 'Bootware SSH' `
                -Enabled True `
                -LocalPort 22 `
                -Name sshd `
                -Protocol TCP
        }

        # OpenSSH default shell needs to match the shell used by Ansible. For
        # more information, visit
        # https://groups.google.com/g/ansible-project/c/quRiK_2WKtE/m/NcXnDsp_CQAJ.
        If (Test-Path -Path 'C:\Program Files\PowerShell\7\pwsh.exe' -PathType Leaf) {
            $RemoteShell = 'C:\Program Files\PowerShell\7\pwsh.exe';
        }
        Else {
            $RemoteShell = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';
        }
        New-ItemProperty `
            -Force `
            -Name DefaultShell `
            -Path 'HKLM:\SOFTWARE\OpenSSH' `
            -PropertyType String `
            -Value $RemoteShell

        # Administrative Windows users must have their accepted public keys
        # stored in C:/ProgramData/ssh/administrators_authorized_keys with
        # specific permissions. For more information, visit
        # https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement#administrative-user.
        $AuthKeys = 'C:/ProgramData/ssh/administrators_authorized_keys'
        If (-Not (Test-Path -Path $AuthKeys -PathType Leaf)) {
            New-Item -ItemType File -Path $AuthKeys | Out-Null
        }
        icacls $AuthKeys `
            /Grant 'Administrators:F' `
            /Grant 'SYSTEM:F' `
            /Inheritance:r

        New-Item -ItemType File -Path $SetupSSHServerComplete | Out-Null
    }

    Start-Service sshd
}

# Install WSL2 with Debian.
#
# Implemented based on instructions at
# https://docs.microsoft.com/en-us/windows/wsl/install-win10.
Function SetupWSL($Branch) {
    $Debug = $Global:Debug
    $WSLExe = Get-Command -ErrorAction SilentlyContinue wsl
    $MWSL = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    $VMP = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

    If ((-Not $WSLExe) -Or ($MWSL.State -NE 'Enabled') -Or ($VMP.State -NE 'Enabled')) {
        # Dism appears to require arguments in a specific order.
        dism `
            /Online `
            /Enable-Feature `
            /FeatureName:Microsoft-Windows-Subsystem-Linux `
            /All `
            /NoRestart
        dism `
            /Online `
            /Enable-Feature `
            /FeatureName:VirtualMachinePlatform `
            /All `
            /NoRestart

        Log 'Restart your system to finish WSL installation'
        Log "Then run 'bootware setup' again to install Debian"
        Exit 0
    }

    # Unable to figure a better way to check if a Linux distro is installed.
    # Checking output of wsl list seems to never work.
    $MatchString = 'A WSL distro is installed'
    $DistroCheck = wsl echo $MatchString
    If (-Not ($DistroCheck -Like $MatchString)) {
        $TempFile = [System.IO.Path]::GetTempFileName() -Replace '.tmp', '.msi'
        Log 'Downloading WSL update'
        DownloadFile `
            'https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi' `
            $TempFile
        Start-Process -Wait $TempFile /Passive

        Log 'Installing Debian distribution'
        Log "Complete pop up window and then run 'bootware setup' again"
        wsl --set-default-version 2
        wsl --install --distribution Debian
        exit 0
    }

    If (-Not (wsl command -v bootware)) {
        Log 'Installing a WSL copy of Bootware'

        wsl sudo apt-get --quiet update
        wsl sudo apt-get --quiet install --yes curl
        wsl curl -LSfs `
            https://raw.githubusercontent.com/scruffaluff/bootware/main/install.sh `
            `| bash -s -- --version $Branch

        If ($Debug) {
            wsl bootware --debug setup
        }
        Else {
            wsl bootware setup
        }
    }
}

# Subcommand to remove Bootware files.
Function Uninstall() {
    $ArgIdx = 0
    $Debug = $Global:Debug

    While ($ArgIdx -LT $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            { $_ -In '-h', '--help' } {
                Usage 'uninstall'
                Exit 0
            }
            Default {
                ErrorUsage "No such option '$($Args[0][$ArgIdx])'"
            }
        }
    }

    # Uninstall WSL copy of Bootware.
    If (Get-Command -ErrorAction SilentlyContinue wsl) {
        # Check if Bootware is installed on WSL.
        If (wsl command -v bootware) {
            If ($Debug) {
                wsl bootware --debug uninstall
            }
            Else {
                wsl bootware uninstall `> /dev/null
            }
        }
    }

    Remove-Item -Force -Recurse -Path $PSScriptRoot
    Log 'Uninstalled Bootware'
}

# Subcommand to update Bootware script.
Function Update() {
    $ArgIdx = 0
    $Debug = $Global:Debug
    $Version = 'main'

    While ($ArgIdx -LT $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            { $_ -In '-h', '--help' } {
                Usage 'update'
                Exit 0
            }
            { $_ -In '-v', '--version' } {
                $Version = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                Break
            }
            Default {
                ErrorUsage "No such option '$($Args[0][$ArgIdx])'"
            }
        }
    }

    $SrcURL = "https://raw.githubusercontent.com/scruffaluff/bootware/$Version/bootware.ps1"
    DownloadFile $SrcURL "$PSScriptRoot/bootware.ps1"
    UpdateCompletion $Version

    # Update WSL copy of Bootware.
    If (Get-Command -ErrorAction SilentlyContinue wsl) {
        # Check if Bootware is installed on WSL.
        If (wsl command -v bootware) {
            If ($Debug) {
                wsl bootware --debug update --version $Version
            }
            Else {
                wsl bootware update --version $Version `> /dev/null
            }
        }
    }

    # Update playbook repository.
    $RepoPath = "$PSScriptRoot/repo"
    If (Test-Path -Path $RepoPath -PathType Container) {
        git -C $RepoPath pull
    }

    Log "Updated to version $(bootware --version)"
}

# Update completion script for Bootware.
Function UpdateCompletion($Version) {
    $PowerShellURL = "https://raw.githubusercontent.com/scruffaluff/bootware/$Version/completions/bootware.psm1"

    $Paths = @(
        "$HOME/Documents/PowerShell/Modules/BootwareCompletion"
        "$HOME/Documents/WindowsPowerShell/Modules/BootwareCompletion"
    )
    ForEach ($Path In $Paths) {
        New-Item -Force -ItemType Directory -Path $Path | Out-Null
        DownloadFile $PowerShellURL "$Path/BootwareCompletion.psm1"
    }
}

# Print Bootware version string.
Function Version() {
    Write-Output 'Bootware 0.8.3'
}

# Convert path to WSL relative path.
Function WSLPath($FilePath) {
    $FilePath = $FilePath -Replace '~', $HOME
    $Drive = $(Split-Path -Path $FilePath -Qualifier) -Replace ':', ''
    $ChildPath = $(Split-Path -Path $FilePath -NoQualifier) -Replace '\\', '/'
    Return "/mnt/$($Drive.ToLower())$ChildPath"
}

# Script entrypoint.
Function Main() {
    $ArgIdx = 0
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignment", "")]
    $Global:Debug = $False

    While ($ArgIdx -LT $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            '--debug' {
                $Global:Debug = $True
                $ArgIdx += 1
                Break
            }
            { $_ -In '-h', '--help' } {
                Usage 'main'
                Exit 0
            }
            { $_ -In '-v', '--version' } {
                Version
                Exit 0
            }
            'bootstrap' {
                $ArgIdx += 1
                Bootstrap @(GetParameters $Args[0] $ArgIdx)
                Exit $LastExitCode
            }
            'config' {
                $ArgIdx += 1
                Config @(GetParameters $Args[0] $ArgIdx)
                Exit 0
            }
            'roles' {
                $ArgIdx += 1
                Roles @(GetParameters $Args[0] $ArgIdx)
                Exit 0
            }
            'setup' {
                $ArgIdx += 1
                Setup @(GetParameters $Args[0] $ArgIdx)
                Exit 0
            }
            'uninstall' {
                $ArgIdx += 1
                Uninstall @(GetParameters $Args[0] $ArgIdx)
                Exit 0
            }
            'update' {
                $ArgIdx += 1
                Update @(GetParameters $Args[0] $ArgIdx)
                Exit 0
            }
            Default {
                ErrorUsage "No such subcommand or option '$($Args[0][0])'"
            }
        }
    }

    Usage 'main'
}

# Only run Main if invoked as script. Otherwise import functions as library.
If ($MyInvocation.InvocationName -NE '.') {
    Main $Args
}
