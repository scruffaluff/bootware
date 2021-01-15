#!/usr/bin/pwsh
#
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
Bootware 0.0.4
Boostrapping software installer

USAGE:
    bootware [FLAGS] [SUBCOMMAND]

FLAGS:
    -h, --help       Print help information
    -v, --version    Print version information

SUBCOMMANDS:
    config           Generate default Bootware configuration file
    install          Boostrap install computer software
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
    Write-Output "Launching Bootware Docker container..."
    Write-Output "Enter your user account password when prompted."

    docker run `
        -it `
        -v "$Args[0]:/root/.ssh/bootware" `
        -v "$Args[1]:/bootware/host_vars/host.docker.internal.yaml" `
        --rm `
        "--add-host" "host.docker.internal:$FindDockerIp" `
        wolfgangwazzlestrauss/bootware:latest `
        --ask-become-pass `
        --tag "$3" `
        --user "$Env:UserName" `
        main.yaml
}

# Config subcommand.
Function Config() {
    ForEach ($Arg in $Args) {
        Switch ($Arg) {
            "-h" { Usage "config"; Exit 0 }
            "--help" { Usage "config"; Exit 0 }
        }
    }

    Write-Output "Downloading default configuration file to $HOME/bootware.yaml..."
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/host_vars/bootware.yaml" -OutFile "$HOME/bootware.yaml"
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
    } elif (Test-Path -Path "$HOME/bootware.yaml" -PathType Leaf) {
        $ConfigPath = "$HOME/bootware.yaml"
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
    #     error "Unable to find Docker host IP address. Restart Docker and try again."
    # fi

    # RET_VAL="$_docker_ip"
}

Function Install() {
    ForEach ($Arg in $Args) {
        Switch ($Arg) {
            "-h" { Usage "install"; Exit 0 }
            "--help" { Usage "install"; Exit 0 }
        }
    }

    Write-Output "Install subcommand."
    Error "Not implemented."
}

# Configure boostrapping services and utilities.
Function Setup() {
    # Install Scoop package manager.
    If (-Not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Invoke-WebRequest -Uri "https://get.scoop.sh" | Invoke-Expression
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

    # Something?
    # winrm set winrm/config/client/auth '@{Basic="true"}'
    # winrm set winrm/config/service/auth '@{Basic="true"}'
    # winrm set winrm/config/service '@{AllowUnencrypted="true"}'
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
    Write-Output "Bootware 0.0.4"
}

Function Main() {
    ForEach ($Arg in $Args) {
        Switch ($Arg) {
            "-h" { Usage "main"; Exit 0 }
            "--help" { Usage "main"; Exit 0 }
            "-v" { Version; Exit 0 }
            "--version" { Version; Exit 0 }
            "config" { Config Args[1:]; Exit 0 }
            "install" { Install Args[1:]; Exit 0 }
            "update" { Update Args[1:]; Exit 0 }
        }
    }

    Usage "main"
}

Main $Args
