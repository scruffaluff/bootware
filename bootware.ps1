# If unable to execute due to policy rules, run 
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser.


# Show CLI help information.
Function Usage() {
    Switch ($Args[0]) {
        "config" { 
            Write-Output @'
Bootware config
Generate default Bootware configuration file

USAGE:
    bootware config [FLAGS]

FLAGS:
    -h, --help       Print help information
'@      
        }
        "install" {
            Write-Output @'
Bootware install
Boostrap install computer software

USAGE:
    bootware install [FLAGS] [OPTIONS]

FLAGS:
    -h, --help       Print help information

OPTIONS:
    -c, --config     Path to bootware user configuation file
        --tag        Ansible playbook tag
'@
        }
        "main" {
            Write-Output @'
Bootware 0.1.1
Boostrapping software installer

USAGE:
    bootware [FLAGS] [SUBCOMMAND]

FLAGS:
    -h, --help       Print help information
    -v, --version    Print version information

SUBCOMMANDS:
    bootstrap        Boostrap install computer software
    config           Generate default Bootware configuration file
    update           Update Bootware to latest version
'@
        }
        "update" {
            Write-Output @'
Bootware update
Update Bootware to latest version

USAGE:
    bootware update [FLAGS]

FLAGS:
    -h, --help       Print help information
'@
        }
    }
}

# Launch Docker container to boostrap software installation.
Function Bootstrap() {
    ForEach ($Arg in $Args) {
        Switch ($Arg) {
            "-h" { Usage "install"; Exit 0 }
            "--help" { Usage "install"; Exit 0 }
        }
    }

    Write-Output "Launching Bootware Docker container..."
    Write-Output "Enter your user account password if prompted."

    docker run `
        -it `
        -v "$Args[0]:/root/.ssh/bootware" `
        -v "$Args[1]:/bootware/host_vars/host.docker.internal.yaml" `
        --rm `
        --add-host "host.docker.internal:$FindDockerIp" `
        wolfgangwazzlestrauss/bootware:latest `
        --ask-become-pass `
        --extra-vars "ansible_connection=winrm" `
        --extra-vars "ansible_user=$Env:UserName" `
        --extra-vars "ansible_winrm_server_cert_validation=ignore" `
        --extra-vars "ansible_winrm_transport=basic" `
        --tags "$3" `
        main.yaml
}

# Config subcommand.
Function Config() {
    $Dest = "$HOME/.bootware/config.yaml"

    ForEach ($Arg in $Args) {
        Switch ($Arg) {
            "-h" { Usage "config"; Exit 0 }
            "--help" { Usage "config"; Exit 0 }
        }
    }

    New-Item -Force -ItemType Directory -Path $(Split-Path -Path $Dest -Parent)

    Write-Output "Downloading default configuration file to $HOME/.bootware/config.yaml..."
    Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/host_vars/bootware.yaml" -OutFile "$Dest"
}

# Print error message and exit with error code.
Function Error($Message) {
    Write-Error "Error: $Message"
    Exit 1
}

# Find path of Bootware configuation file.
Function FindConfigPath($FilePath) {
    If (Test-Path -Path "$1" -PathType Leaf) {
        $ConfigPath = $FilePath
    } ElseIf (Test-Path -Path "$(Get-Location)/bootware.yaml" -PathType Leaf) {
        $ConfigPath = "$(Get-Location)/bootware.yaml"
    } ElseIf (Test-Path Env:BOOTWARE_CONFIG) {
        $ConfigPath = "$Env:BOOTWARE_CONFIG"
    } ElseIf (Test-Path -Path "$HOME/.bootware/config.yaml" -PathType Leaf) {
        $ConfigPath = "$HOME/.bootware/config.yaml"
    } else {
        Error "Unable to find Bootware configuation file."
    }

    Write-Output "Using $ConfigPath as configuration file."
}

# Find IP address of host machine that is accessible from Docker.
Function FindDockerIp() {
    # _docker_ip=$(docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}')

    # # Check if Docker IP is not null.
    # #
    # # Flags:
    # #     -z: True if string has zero length.
    # if [ -z "$_docker_ip" ]; then
    #     Error "Unable to find Docker host IP address. Restart Docker and try again."
    # fi

    # RET_VAL="$_docker_ip"
}

# Configure boostrapping services and utilities.
Function Setup() {
    # Install Scoop package manager.
    If (-Not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Invoke-WebRequest -UseBasicParsing -Uri "https://get.scoop.sh" | Invoke-Expression
        scoop bucket add extras
        scoop bucket add main
        scoop bucket add nerd-fonts
        scoop bucket add versions
    }

    # Install Scoop package manager.
    If (-Not (Get-Command git -ErrorAction SilentlyContinue)) {
        scoop install git
    }

    # Install Docker Desktop.
    If (-Not (Get-Command docker -ErrorAction SilentlyContinue)) {
        $TempFile = [System.IO.Path]::GetTempFileName() -Replace ".tmp", ".exe"
        Invoke-WebRequest -Uri "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe" -OutFile $TempFile
        Start-Process -Wait $TempFile
    }

    # Make current network private.
    # Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

    # Start WinRM service.
    # Enable-PSRemoting -Force -SkipNetworkProfileCheck
    # winrm quickconfig

    # Allow HTTP WinRM connection with password credentials.
    winrm set winrm/config/client/auth '@{Basic="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
}


Function Update() {
    ForEach ($Arg in $Args) {
        Switch ($Arg) {
            "-h" { Usage "update"; Exit 0 }
            "--help" { Usage "update"; Exit 0 }
        }
    }

    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/bootware.ps1" -OutFile "/usr/local/bin/bootware"
    bootware version
}

Function Version() {
    Write-Output "Bootware 0.1.1"
}

Function Main() {
    ForEach ($Arg in $Args) {
        Switch ($Arg) {
            "-h" { Usage "main"; Exit 0 }
            "--help" { Usage "main"; Exit 0 }
            "-v" { Version; Exit 0 }
            "--version" { Version; Exit 0 }
            "bootstrap" { Bootstrap Args[1:]; Exit 0 }
            "config" { Config Args[1:]; Exit 0 }
            "update" { Update Args[1:]; Exit 0 }
        }
    }

    Usage "main"
}

Main $Args
