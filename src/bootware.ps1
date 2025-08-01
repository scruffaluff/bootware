<#
.SYNOPSIS
    Bootstrap software installations with Ansible.
#>

# If unable to execute due to policy rules, run
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser.

# Exit immediately if a PowerShell cmdlet encounters an error.
$ErrorActionPreference = 'Stop'
# Disable progress bar for PowerShell cmdlets.
$ProgressPreference = 'SilentlyContinue'
# Keep native executable arguments consistent between PowerShell versions.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignment',
    '',
    Justification = 'Variable is a standard PowerShell setting.'
)]
$PSNativeCommandArgumentPassing = 'Legacy'
# Exit immediately when an native executable encounters an error.
$PSNativeCommandUseErrorActionPreference = $True

# Show CLI help information.
function Usage() {
    switch ($Args[0]) {
        'bootstrap' {
            Write-Output @'
Bootstrap install computer software.

Usage: bootware bootstrap [OPTIONS]

Options:
      --check                     Perform dry run and show possible changes.
  -c, --config <PATH>             Path to bootware user configuration file.
      --debug                     Enable Ansible task debugger.
  -d, --dev                       Run bootstrapping in development mode.
  -h, --help                      Print help information.
      --install-group <GROUP>     Remote group to install software for.
      --install-user <USER>       Remote user to install software for.
  -i, --inventory <IP-LIST>       Ansible remote hosts IP addresses.
      --no-passwd                 Do not ask for user password.
      --no-setup                  Skip Bootware dependency installation.
      --password <PASSWORD>       Remote user login password.
  -p, --playbook <FILE>           Path to playbook to execute.
      --private-key <FILE>        Path to SSH private key.
      --port <INTEGER>            Port for SSH connection.
      --retries <INTEGER>         Playbook retry limit during failure.
  -s, --skip <TAG-LIST>           Ansible playbook tags to skip.
      --start-at-role <ROLE>      Begin execution with role.
  -t, --tags <TAG-LIST>           Ansible playbook tags to select.
      --temp-key <FILE>           Path to SSH private key for one time connection.
  -u, --url <URL>                 URL of playbook repository.
      --user <USER>               Remote user login name.
'@
            if (wsl command -v ansible) {
                Write-Output "`nAnsible Options:"
                wsl ansible --help
            }
        }
        'config' {
            Write-Output @'
Download default Bootware configuration file.

Usage: bootware config [OPTIONS]

Options:
  -d, --dest <PATH>     Path to alternate download destination.
  -e, --empty           Write empty configuration file.
  -h, --help            Print help information.
  -s, --source <URL>    URL to configuration file.
'@
        }
        'main' {
            Write-Output @'
Bootstrapping software installer.

Usage: bootware [OPTIONS] <SUBCOMMAND>

Options:
      --debug     Enable shell debug traces.
  -h, --help      Print help information.
  -v, --version   Print version information.

Subcommands:
  bootstrap   Bootstrap install computer software.
  config      Generate Bootware configuration file.
  roles       List all Bootware roles.
  setup       Install dependencies for Bootware.
  uninstall   Remove Bootware files.
  update      Update Bootware to latest version.

Environment Variables:
  BOOTWARE_CONFIG         Set the configuration file path.
  BOOTWARE_GITHUB_TOKEN   GitHub API authentication token.
  BOOTWARE_NOLOG          Silence log messages.
  BOOTWARE_NOPASSWD       Assume password less doas or sudo.
  BOOTWARE_NOSETUP        Skip Ansible install and system setup.
  BOOTWARE_PLAYBOOK       Set Ansible playbook name.
  BOOTWARE_SKIP           Set skip tags for Ansible roles.
  BOOTWARE_TAGS           Set tags for Ansible roles.
  BOOTWARE_URL            Set location of Ansible repository.

Run 'bootware <subcommand> --help' for usage on a subcommand.
'@
        }
        'roles' {
            Write-Output @'
List all Bootware roles.

Usage: bootware roles [OPTIONS]

Options:
  -h, --help              Print help information.
  -t, --tags <TAG-LIST>   Ansible playbook tags to select.
'@
        }
        'setup' {
            Write-Output @'
Install dependencies for Bootware.

Usage:
    bootware setup [OPTIONS]

Options:
  -h, --help             Print help information.
      --checkout <REF>   Git reference to run against.
  --no-wsl               Do not configure WSL.
  -u, --url <URL>        URL of playbook repository.
'@
        }
        'uninstall' {
            Write-Output @'
Remove Bootware files.

Usage: bootware uninstall

Options:
  -h, --help    Print help information.
'@
        }
        'update' {
            Write-Output @'
Update Bootware to latest version.

Usage: bootware update [FLAGS]

Options:
  -h, --help                Print help information.
  -v, --version <VERSION>   Version override for update.
'@
        }
        Default {
            throw "No such usage option '$($Args[0])'"
        }

    }
}

# Subcommand to bootstrap software installations.
function Bootstrap() {
    $ArgIdx = 0
    $ConfigPath = ''
    $Debug = $Global:Debug
    $ExtraArgs = @()
    $Inventory = ''
    $Playbook = "$PSScriptRoot\repo\playbook.yaml"
    $Remote = $False
    $Skip = 'none'
    $Tags = 'desktop'
    $URL = 'https://github.com/scruffaluff/bootware.git'
    $UseSetup = $True
    $User = $Env:UserName

    while ($ArgIdx -lt $Args[0].Count) {
        switch ($Args[0][$ArgIdx]) {
            { $_ -in '-c', '--config' } {
                $ConfigPath = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            { $_ -in '-d', '--dev' } {
                $Playbook = "$(Get-Location)\playbook.yaml"
                $UseSetup = $False
                $ArgIdx += 1
                break
            }
            { $_ -in '-h', '--help' } {
                Usage 'bootstrap'
                exit 0
            }
            { $_ -in '-i', '--inventory' } {
                $Inventory = $Args[0][$ArgIdx + 1] -join ','
                $Remote = $True
                $ArgIdx += 2
                break
            }
            '--no-setup' {
                $UseSetup = $False
                $ArgIdx += 1
                break
            }
            { $_ -in '-p', '--playbook' } {
                $Playbook = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            '--private-key' {
                $ExtraArgs += "--private-key"
                $ExtraArgs += MakeWSLKey $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            { $_ -in '-s', '--skip' } {
                $Skip = $Args[0][$ArgIdx + 1] -join ','
                $ArgIdx += 2
                break
            }
            '--start-at-role' {
                $StartRole = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            { $_ -in '-t', '--tags' } {
                $Tags = $Args[0][$ArgIdx + 1] -join ','
                $ArgIdx += 2
                break
            }
            '--temp-key' {
                $ExtraArgs += "--temp-key"
                $ExtraArgs += MakeWSLKey $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            { $_ -in '-u', '--url' } {
                $URL = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            '--user' {
                $User = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            Default {
                $ExtraArgs += $Args[0][$ArgIdx]
                $ArgIdx += 1
                break
            }
        }
    }

    if ($UseSetup) {
        $Params = @()
        $Params += '--url', $URL
        Setup $Params
    }
    elseif (-not (Get-Command -ErrorAction SilentlyContinue wsl)) {
        throw 'Error: The WSL needs to be setup before bootstrapping'
    }

    # Configure run to find task associated with start role.
    #
    # Special quoting is required for the filter due to PowerShell shenanigans.
    # For more information, visit https://github.com/mikefarah/yq/issues/747.
    if ($StartRole) {
        $Filter = ".[0].tasks[] | select(.`"ansible.builtin.include_role`".name == `"scruffaluff.bootware.$StartRole`") | .name"
        $StartTask = yq --exit-status $($Filter -replace '"', '\"') $Playbook
        $ExtraArgs += @(
            '--extra-vars', 'connect_role_executed=false', '--start-at-task',
            $StartTask
        )
    }

    try {
        $ConfigPath = FindConfigPath $ConfigPath
    }
    catch [System.IO.FileNotFoundException] {
        $Params = @()
        $Params += @('--empty')
        Config $Params
        $ConfigPath = "$HOME\.bootware\config.yaml"
    }

    Log "Using $ConfigPath as configuration file."
    $WSLConfigPath = WSLPath $ConfigPath
    if (-not $Remote) {
        $Inventory = FindRelativeIP
    }
    $PlaybookPath = WSLPath $Playbook

    # Home variable cannot be wrapped in brackets in case the default WSL shell
    # is Fish. Have not found a way to optionally include arguments in
    # PowerShell. If a simpler solution exists, please edit.
    #
    # $ExtraArgs needs to be passed as an array to WSL. Do not change it into a
    # string.
    if ($Debug -and $Remote -and $ExtraArgs.Count -gt 0) {
        wsl bootware --debug bootstrap `
            --config $WSLConfigPath `
            --inventory $Inventory `
            --playbook $PlaybookPath `
            --skip $Skip `
            --tags $Tags `
            --user $User `
            $ExtraArgs
    }
    elseif ($Debug -and $Remote) {
        wsl bootware --debug bootstrap `
            --config $WSLConfigPath `
            --inventory $Inventory `
            --playbook $PlaybookPath `
            --tags $Tags `
            --skip $Skip `
            --user $User
    }
    elseif ($Remote -and $ExtraArgs.Count -gt 0) {
        wsl bootware bootstrap `
            --config $WSLConfigPath `
            --inventory $Inventory `
            --playbook $PlaybookPath `
            --skip $Skip `
            --tags $Tags `
            --user $User `
            $ExtraArgs
    }
    elseif ($Remote) {
        wsl bootware bootstrap `
            --config $WSLConfigPath `
            --inventory $Inventory `
            --playbook $PlaybookPath `
            --skip $Skip `
            --tags $Tags `
            --user $User
    }
    elseif ($Debug -and $ExtraArgs.Count -gt 0) {
        wsl bootware --debug bootstrap --no-passwd `
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
    elseif ($Debug) {
        wsl bootware --debug bootstrap --no-passwd `
            --config $WSLConfigPath `
            --inventory $Inventory `
            --playbook $PlaybookPath `
            --private-key "`$HOME/.ssh/bootware" `
            --skip $Skip `
            --ssh-extra-args "'-o StrictHostKeyChecking=no'" `
            --tags $Tags `
            --user $User
    }
    elseif ($ExtraArgs.Count -gt 0) {
        wsl bootware bootstrap --no-passwd `
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
    else {
        wsl bootware bootstrap --no-passwd `
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
function Config() {
    $ArgIdx = 0
    $SrcURL = ''
    $DstFile = "$HOME\.bootware\config.yaml"
    $EmptyCfg = $False

    while ($ArgIdx -lt $Args[0].Count) {
        switch ($Args[0][$ArgIdx]) {
            { $_ -in '-d', '--dest' } {
                $DstFile = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            { $_ -in '-e', '--empty' } {
                $EmptyCfg = $True
                $ArgIdx += 1
                break
            }
            { $_ -in '-h', '--help' } {
                Usage 'config'
                exit 0
            }
            { $_ -in '-s', '--source' } {
                $SrcURL = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            Default {
                Log "error: No such option '$($Args[0][$ArgIdx])'."
                Log "Run 'bootware config --help' for usage."
                exit 2
            }
        }
    }

    $DstDir = Split-Path -Parent -Path $DstFile
    if (-not (Test-Path -Path $DstDir -PathType Container)) {
        New-Item -ItemType Directory -Path $DstDir | Out-Null
    }

    if ($EmptyCfg -or (-not $SrcURL)) {
        Log "Writing empty configuration file to '$DstFile'."
        # Do not use Write-Output. On PowerShell 5, it will add a byte order
        # marker to the file, which makes WSL Ansible throw UTF-8 errors.
        # Solution was taken from https://stackoverflow.com/a/32951824.
        [System.IO.File]::WriteAllLines($DstFile, 'font_size: 14')
    }
    else {
        Log "Downloading configuration file to '$DstFile'."
        Invoke-WebRequest -UseBasicParsing -OutFile $DstFile -Uri $SrcURL
    }
}

# Find path of Bootware configuration file.
function FindConfigPath($FilePath) {
    $ConfigPath = ''

    if (($FilePath) -and (Test-Path -Path $FilePath -PathType Leaf)) {
        $ConfigPath = $FilePath
    }
    elseif (($Env:BOOTWARE_CONFIG) -and (Test-Path -Path "$Env:BOOTWARE_CONFIG")) {
        $ConfigPath = "$Env:BOOTWARE_CONFIG"
    }
    elseif (Test-Path -Path "$HOME\.bootware\config.yaml" -PathType Leaf) {
        $ConfigPath = "$HOME\.bootware\config.yaml"
    }
    else {
        throw [System.IO.FileNotFoundException] `
            'Unable to find Bootware configuration file'
    }

    $ConfigPath
}

# Find IP address of Windows host relative from WSL.
#
# For WSL version 1, the Linux subsystem and the Windows host share the same
# network. For WSL version 2, the first "nameserver <ip-address>" section of
# /etc/resolv.conf contains the IP address of the windows host. Note that there
# can be several nameserver sections. For more information, visit
# https://docs.microsoft.com/en-us/windows/wsl/compare-versions#accessing-windows-networking-apps-from-linux-host-ip.
function FindRelativeIP {
    $WSLVersion = Get-ItemPropertyValue `
        -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss' `
        -Name DefaultVersion

    if ($WSLVersion -eq 1) {
        '127.0.0.1'
    }
    else {
        wsl sh -c 'ip route show | grep -i default | awk ''{print \$3}'''
    }
}

# Get parameters for subcommands.
function GetParameters($Params, $Index) {
    if ($Params.Length -gt $Index) {
        $Params[$Index..($Params.Length - 1)]
    }
    else {
        @()
    }
}

# Check if script is run from an admin console.
function IsAdministrator {
    ([Security.Principal.WindowsPrincipal]`
        [Security.Principal.WindowsIdentity]::GetCurrent()`
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Print log message to stdout if logging is enabled.
function Log($Message) {
    if (!"$Env:BOOTWARE_NOLOG") {
        Write-Output $Message
    }
}

# Copy SSH private key to WSL temporary path with correct permissions.
#
# Required when SSH private key lives in Windows file system, since its open
# permissions cannot be changed.
function MakeWSLKey($FilePath) {
    $WSLFile = wsl mktemp --dry-run
    wsl cp "$(WSLPath $FilePath)" $WSLFile
    wsl chmod 600 $WSLFile
    $WSLFile
}

# Request remote script and execution efficiently.
#
# Required as a separate function, since the default progress bar updates every
# byte, making downloads slow. For more information, visit
# https://stackoverflow.com/a/43477248.
function RemoteScript($URL) {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -UseBasicParsing -Uri $URL | Invoke-Expression
}

# Subcommand to list all Bootware roles.
function Roles() {
    $ArgIdx = 0
    $Playbook = ''
    $Skip = ''
    $Tags = ''

    while ($ArgIdx -lt $Args[0].Count) {
        switch ($Args[0][$ArgIdx]) {
            { $_ -in '-h', '--help' } {
                Usage 'roles'
                exit 0
            }
            { $_ -in '-s', '--skip' } {
                $Skip = $Args[0][$ArgIdx + 1] -join ','
                $ArgIdx += 2
                break
            }
            { $_ -in '-t', '--tags' } {
                $Tags = $Args[0][$ArgIdx + 1] -join ','
                $ArgIdx += 2
                break
            }
            Default {
                Log "error: No such option '$($Args[0][$ArgIdx])'."
                Log "Run 'bootware roles --help' for usage."
                exit 2
            }
        }
    }

    $ContainsInner = $Tags.Replace(',', '") | any) or (map(. == "')
    if ($Tags -match 'All(,|$)') {
        $Contains = "((map(. != `"never`") | all) or (map(. == `"$ContainsInner`") | any))"
    }
    else {
        $Contains = "(map(. == `"$ContainsInner`") | any)"
    }
    $RejectsInner = $Skip.Replace(',', '") | all) and (map(. != "')
    $Rejects = "(map(. != `"$RejectsInner`") | all)"

    if ($Skip -and $Tags) {
        $Filter = ".[0].tasks[] | select(.tags | (($Contains) and ($Rejects)))"
    }
    elseif ($Skip) {
        $Filter = ".[0].tasks[] | select(.tags | $Rejects)"
    }
    elseif ($Tags) {
        $Filter = ".[0].tasks[] | select(.tags | $Contains)"
    }
    else {
        $Filter = '.[0].tasks[] | select(.tags | (map(. != "never") | all))'
    }
    $Format = '."ansible.builtin.include_role".name  | sub("scruffaluff.bootware.", "")'
    $Command = "$Filter | $Format"

    if (Test-Path -Path "$PSScriptRoot\repo\playbook.yaml" -PathType Leaf) {
        $Playbook = "$PSScriptRoot\repo\playbook.yaml"
    }
    elseif (Test-Path -Path 'playbook.yaml' -PathType Leaf) {
        $Playbook = 'playbook.yaml'
    }
    else {
        throw 'Unable to find Bootware playbook.'
    }

    # Special quoting is required for the command due to PowerShell shenanigans.
    # For more information, visit https://github.com/mikefarah/yq/issues/747.
    Get-Content "$Playbook" | yq --exit-status $($Command -replace '"', '\"')
}

# Subcommand to configure bootstrapping services and utilities.
function Setup() {
    $ArgIdx = 0
    $Branch = 'main'
    $URL = 'https://github.com/scruffaluff/bootware.git'
    $WSL = $True

    while ($ArgIdx -lt $Args[0].Count) {
        switch ($Args[0][$ArgIdx]) {
            { $_ -in '-h', '--help' } {
                Usage 'setup'
                exit 0
            }
            '--checkout' {
                $Branch = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            '--no-wsl' {
                $WSL = $False
                $ArgIdx += 1
                break
            }
            { $_ -in '-u', '--url' } {
                $URL = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            Default {
                Log "error: No such option '$($Args[0][$ArgIdx])'."
                Log "Run 'bootware setup --help' for usage."
                exit 2
            }
        }
    }

    if (-not (IsAdministrator)) {
        Log @'
Setup requires an administrator console.
Restart this script from an administrator console to continue.
'@
        exit 1
    }

    # Install Chocolatey package manager.
    if (-not (Get-Command -ErrorAction SilentlyContinue choco)) {
        Log 'Downloading Chocolatey package manager.'
        RemoteScript 'https://chocolatey.org/install.ps1'
    }

    # Install Scoop package manager.
    if (-not (Get-Command -ErrorAction SilentlyContinue scoop)) {
        Log 'Downloading Scoop package manager.'
        # Scoop disallows installation from an admin console by default. For
        # more information, visit
        # https://github.com/ScoopInstaller/Install#for-admin.
        if (IsAdministrator) {
            $ScoopInstaller = [System.IO.Path]::GetTempFileName() `
                -replace '.tmp', '.ps1'
            Invoke-WebRequest -UseBasicParsing -OutFile $ScoopInstaller `
                -Uri 'get.scoop.sh'
            & $ScoopInstaller -RunAsAdmin
            Remove-Item -Force -Path $ScoopInstaller
        }
        else {
            RemoteScript 'https://get.scoop.sh'
        }

        # Add Scoop shims to system path.
        $Path = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $GlobalShims = 'C:\ProgramData\scoop\shims'
        if (-not ($Path -like "*$GlobalShims*")) {
            [System.Environment]::SetEnvironmentVariable(
                'Path', "$GlobalShims;$Path", 'Machine'
            )
        }
        $Path = [Environment]::GetEnvironmentVariable('Path', 'User')
        $UserShims = "$HOME\scoop\shims"
        if (-not ($Path -like "*$UserShims*")) {
            [System.Environment]::SetEnvironmentVariable(
                'Path', "$UserShims;$Path", 'User'
            )
        }
    }

    # Git is required for adding Scoop buckets.
    if (-not (Get-Command -ErrorAction SilentlyContinue git)) {
        Log 'Installing Git.'
        scoop install mingit
        Log "Installed $(git --version)."
    }

    if (-not (Get-Command -ErrorAction SilentlyContinue yq)) {
        Log 'Installing Yq.'
        scoop install yq
        Log "Installed $(yq --version)."
    }

    $ScoopBuckets = scoop bucket list
    foreach ($Bucket in @('extras', 'main', 'versions')) {
        if ($Bucket -notin $ScoopBuckets.Name) {
            scoop bucket add $Bucket
        }
    }

    $RepoPath = "$PSScriptRoot\repo"
    if (-not (Test-Path -Path $RepoPath -PathType Any)) {
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

    if ($WSL) {
        SetupWSL $Branch
        SetupSSHKeys
    }
}

# Create SSH keys to connect to Windows host and scan for fingerprints.
function SetupSSHKeys {
    $SetupSSHKeysComplete = "$PSScriptRoot\.setup_ssh_keys"
    if (-not (Test-Path -Path $SetupSSHKeysComplete -PathType Leaf)) {
        Log 'Generating SSH keys.'

        # GetTempFileName creates a 0 byte file, so it has to be deleted to work
        # with ssh-keygen.
        $WindowsKeyPath = [System.IO.Path]::GetTempFileName()
        Remove-Item -Force -Path $WindowsKeyPath

        # SSH key generation behavior for empty passphrases is different between
        # PowerShell versions.
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            ssh-keygen -q -N '' -f $WindowsKeyPath -t ed25519 -C 'bootware'
        }
        else {
            ssh-keygen -q -N '""' -f $WindowsKeyPath -t ed25519 -C 'bootware'
        }
        $PublicKey = Get-Content -Path "$WindowsKeyPath.pub"
        Add-Content `
            -Path 'C:\ProgramData\ssh\administrators_authorized_keys' `
            -Value $PublicKey

        Log 'Moving SSH keys to WSL.'

        # Home variable cannot be wrapped in brackets in case the default WSL
        # shell is Fish.
        $WSLKeyPath = WSLPath $WindowsKeyPath
        wsl mkdir --parents --mode 700 "`$HOME/.ssh"
        wsl mv $WSLKeyPath "`$HOME/.ssh/bootware"
        wsl chmod 600 "`$HOME/.ssh/bootware"
        wsl mv "$WSLKeyPath.pub" "`$HOME/.ssh/bootware.pub"

        wsl sudo DEBIAN_FRONTEND=noninteractive apt-get --quiet update
        wsl sudo DEBIAN_FRONTEND=noninteractive apt-get --quiet install --yes `
            openssh-client
        wsl ssh-keyscan "$(FindRelativeIP)" `1`>`> "`$HOME/.ssh/known_hosts"

        Log 'Disabling SSH password authentication.'

        # Disable password based logins for SSH.
        Add-Content `
            -Path "$Env:ProgramData\ssh\sshd_config" `
            -Value 'PasswordAuthentication no'

        New-Item -ItemType File -Path $SetupSSHKeysComplete | Out-Null
        Log 'Completed SSH key configuration.'
    }
}

# Launch OpenSSH server and create inbound network rule.
#
# Based on documentation from
# https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse.
function SetupSSHServer() {
    $SetupSSHServerComplete = "$PSScriptRoot\.setup_ssh_server"
    if (-not (Test-Path -Path $SetupSSHServerComplete -PathType Leaf)) {
        Log 'Setting up OpenSSH server.'

        # Turn on Windows Update and TrustedInstaller services.
        Start-Service -ErrorAction SilentlyContinue -Name wuauserv
        if ($? -eq $False) {
            Set-Service -Name wuauserv -StartupType Manual
            Start-Service -Name wuauserv
        }

        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        if (
            (-not (Get-NetFirewallRule -DisplayName 'Bootware SSH' -ErrorAction SilentlyContinue)) -and
            (-not (Get-NetFirewallRule -Name 'sshd' -ErrorAction SilentlyContinue))
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
        if (Test-Path -Path 'C:\Program Files\PowerShell\7\pwsh.exe' -PathType Leaf) {
            $RemoteShell = 'C:\Program Files\PowerShell\7\pwsh.exe';
        }
        else {
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
        $AuthKeys = 'C:\ProgramData\ssh\administrators_authorized_keys'
        if (-not (Test-Path -Path $AuthKeys -PathType Leaf)) {
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
function SetupWSL($Branch) {
    $Debug = $Global:Debug
    $WSLExe = Get-Command -ErrorAction SilentlyContinue wsl
    $MWSL = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    $VMP = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

    if ((-not $WSLExe) -or ($MWSL.State -ne 'Enabled') -or ($VMP.State -ne 'Enabled')) {
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

        Log 'Restart your system to finish WSL installation.'
        Log "Then run 'bootware setup' again to install Debian."
        exit 0
    }

    # Unable to figure a better way to check if a Linux distro is installed.
    # Checking output of wsl list seems to never work.
    $MatchString = 'A WSL distro is installed'
    $DistroCheck = wsl echo $MatchString
    if (-not ($DistroCheck -like $MatchString)) {
        $TempFile = [System.IO.Path]::GetTempFileName() -replace '.tmp', '.msi'
        Log 'Downloading WSL update.'
        Invoke-WebRequest -UseBasicParsing -OutFile $TempFile -Uri `
            'https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi'
        Start-Process -Wait $TempFile /Passive

        Log 'Installing Debian distribution.'
        Log "Complete pop up window and then run 'bootware setup' again."
        wsl --set-default-version 2
        wsl --install --distribution Debian
        Log 'Finished Debian installation.'
        exit 0
    }

    if (-not (wsl command -v bootware)) {
        Log 'Installing a WSL copy of Bootware.'

        wsl sudo DEBIAN_FRONTEND=noninteractive apt-get --quiet update
        wsl sudo DEBIAN_FRONTEND=noninteractive apt-get --quiet install --yes `
            curl
        wsl curl -LSfs `
            https://scruffaluff.github.io/bootware/install.sh `
            `| sh -s -- --global --version $Branch

        if ($Debug) {
            wsl bootware --debug setup
        }
        else {
            wsl bootware setup
        }
        Log 'Finished WSL Bootware installation.'
    }
}

# Subcommand to remove Bootware files.
function Uninstall() {
    $ArgIdx = 0
    $Debug = $Global:Debug

    while ($ArgIdx -lt $Args[0].Count) {
        switch ($Args[0][$ArgIdx]) {
            { $_ -in '-h', '--help' } {
                Usage 'uninstall'
                exit 0
            }
            Default {
                Log "error: No such option '$($Args[0][$ArgIdx])'."
                Log "Run 'bootware uninstall --help' for usage."
                exit 2
            }
        }
    }

    # Uninstall WSL copy of Bootware.
    if (Get-Command -ErrorAction SilentlyContinue wsl) {
        # Check if Bootware is installed on WSL.
        if (wsl command -v bootware) {
            if ($Debug) {
                wsl bootware --debug uninstall
            }
            else {
                wsl bootware uninstall `> /dev/null
            }
        }
    }

    Remove-Item -Force -Recurse -Path $PSScriptRoot
    Log 'Uninstalled Bootware.'
}

# Subcommand to update Bootware script.
function Update() {
    $ArgIdx = 0
    $Debug = $Global:Debug
    $Version = 'main'

    while ($ArgIdx -lt $Args[0].Count) {
        switch ($Args[0][$ArgIdx]) {
            { $_ -in '-h', '--help' } {
                Usage 'update'
                exit 0
            }
            { $_ -in '-v', '--version' } {
                $Version = $Args[0][$ArgIdx + 1]
                $ArgIdx += 2
                break
            }
            Default {
                Log "error: No such option '$($Args[0][$ArgIdx])'."
                Log "Run 'bootware update --help' for usage."
                exit 2
            }
        }
    }

    $SrcURL = "https://raw.githubusercontent.com/scruffaluff/bootware/$Version/src/bootware.ps1"
    Invoke-WebRequest -UseBasicParsing -OutFile "$PSScriptRoot\bootware.ps1" `
        -Uri $SrcURL
    UpdateCompletion $Version

    # Update WSL copy of Bootware.
    if (Get-Command -ErrorAction SilentlyContinue wsl) {
        # Check if Bootware is installed on WSL.
        if (wsl command -v bootware) {
            if ($Debug) {
                wsl bootware --debug update --version $Version
            }
            else {
                wsl bootware update --version $Version `> /dev/null
            }
        }
    }

    # Update playbook repository.
    $RepoPath = "$PSScriptRoot\repo"
    if (Test-Path -Path $RepoPath -PathType Container) {
        git -C $RepoPath pull
    }

    Log "Updated to $(bootware --version)."
}

# Update completion script for Bootware.
function UpdateCompletion($Version) {
    $PowerShellURL = "https://raw.githubusercontent.com/scruffaluff/bootware/$Version/src/completion/bootware.psm1"

    $Paths = @(
        "$HOME\Documents\PowerShell\Modules\BootwareCompletion"
        "$HOME\Documents\WindowsPowerShell\Modules\BootwareCompletion"
    )
    foreach ($Path in $Paths) {
        New-Item -Force -ItemType Directory -Path $Path | Out-Null
        Invoke-WebRequest -UseBasicParsing -OutFile `
            "$Path\BootwareCompletion.psm1" -Uri $PowerShellURL
    }
}

# Print Bootware version string.
function Version() {
    Write-Output 'Bootware 0.9.1'
}

# Convert path to WSL relative path.
function WSLPath($FilePath) {
    $FilePath = $FilePath -replace '~', $HOME
    $Drive = $(Split-Path -Path $FilePath -Qualifier) -replace ':', ''
    $ChildPath = $(Split-Path -Path $FilePath -NoQualifier) -replace '\\', '/'
    "/mnt/$($Drive.ToLower())$ChildPath"
}

# Script entrypoint.
function Main() {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseDeclaredVarsMoreThanAssignment',
        '',
        Justification = 'Global variable is necessary for debugging.',
        Scope = 'Function'
    )]

    $ArgIdx = 0
    $Global:Debug = $False

    while ($ArgIdx -lt $Args[0].Count) {
        switch ($Args[0][$ArgIdx]) {
            '--debug' {
                $Global:Debug = $True
                $ArgIdx += 1
                break
            }
            { $_ -in '-h', '--help' } {
                Usage 'main'
                exit 0
            }
            { $_ -in '-v', '--version' } {
                Version
                exit 0
            }
            'bootstrap' {
                $ArgIdx += 1
                Bootstrap @(GetParameters $Args[0] $ArgIdx)
                exit $LastExitCode
            }
            'config' {
                $ArgIdx += 1
                Config @(GetParameters $Args[0] $ArgIdx)
                exit 0
            }
            'roles' {
                $ArgIdx += 1
                Roles @(GetParameters $Args[0] $ArgIdx)
                exit 0
            }
            'setup' {
                $ArgIdx += 1
                Setup @(GetParameters $Args[0] $ArgIdx)
                exit 0
            }
            'uninstall' {
                $ArgIdx += 1
                Uninstall @(GetParameters $Args[0] $ArgIdx)
                exit 0
            }
            'update' {
                $ArgIdx += 1
                Update @(GetParameters $Args[0] $ArgIdx)
                exit 0
            }
            Default {
                Log "error: No such subcommand or option '$($Args[0][$ArgIdx])'."
                Log "Run 'bootware --help' for usage."
                exit 2
            }
        }
    }

    Usage 'main'
}

# Only run Main if invoked as script. Otherwise import functions as library.
if ($MyInvocation.InvocationName -ne '.') {
    Main $Args
}
