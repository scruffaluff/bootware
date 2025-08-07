#!/usr/bin/env -S nu --no-config-file --stdin

# Copy and configure file.
def deploy [
    --mode (-m): string
    --super (-s): string
    source: string
    dest: string
] {
    let quiet = $env.BOOTWARE_NOLOG? | into bool --relaxed
    let folder = $dest | path dirname

    # Download to temporary file to avoid permission restrictions.
    let file = if ($source | path exists) {
        $source
    } else {
        let temp = mktemp --tmpdir
        if $quiet {
            http get $source | save --force $temp
        } else {
            http get $source | save --force --progress $temp
        }
        $temp
    }

    # Copy file instead of move to ensure correct ownership.
    if ($super | is-empty) {
        mkdir $folder
        cp $file $dest
        if ($mode | is-not-empty) and $nu.os-info.name != "windows" {
            chmod $mode $dest
        }
    } else {
        ^$super mkdir -p $folder
        ^$super cp $file $dest
        if ($mode | is-not-empty) and $nu.os-info.name != "windows" {
            sudo chmod $mode $dest
        }
    }
}

# Find command to elevate as super user.
def find-super [] {
    if (is-admin) {
        ""
    } else if $nu.os-info.name == "windows" {
        error make { msg: ("
System level installation requires an administrator console.
Restart this script from an administrator console or install to a user directory.
"
            | str trim)
        }
    } else if (which doas | is-not-empty) {
        "doas"
    } else if (which sudo | is-not-empty) {
        "sudo"
    } else {
        error make { msg: "Unable to find a command for super user elevation." }
    }
}

# Print message if error or logging is enabled.
def --wrapped log [...args: string] {
    if (
        not ($env.BOOTWARE_NOLOG? | into bool --relaxed)
        or ("-e" in $args) or ("--stderr" in $args)
    ) {
        print ...$args
    }
}

# Download and install Bootware.
def install [super: string dest: directory version: string] {
    let quiet = $env.BOOTWARE_NOLOG? | into bool --relaxed
    let ext = if $nu.os-info.name == "windows" { ".ps1" } else { ".sh" }
    let source = if $version == "local" {
        const folder = path self | path dirname
        $"($folder)/bootware($ext)"
    } else {
        $"https://raw.githubusercontent.com/scruffaluff/bootware/($version)/src/bootware($ext)"
    }
    let program = if $nu.os-info.name == "windows" {
        $"($dest)/bootware.ps1"
    } else {
        $"($dest)/bootware"
    }

    deploy --super $super --mode 755 $source $program
    if $nu.os-info.name == "windows" {
        '
@echo off
powershell -NoProfile -ExecutionPolicy RemoteSigned -File "%~dnp0.ps1" %*
'
        | str trim --left | save --force $"($dest)/bootware.cmd"
    }
}

# Install completion scripts for Bootware.
def install-completions [super: string global: bool version: string] {
    let quiet = $env.BOOTWARE_NOLOG? | into bool --relaxed
    let home = path-home
    let source = if $version == "local" {
        const folder = path self | path dirname
        $"($folder)/completion/bootware"
    } else {
        $"https://raw.githubusercontent.com/scruffaluff/bootware/($version)/src/completion/bootware"
    }

    if $nu.os-info.name == "windows" {
        let folders = if $global {
            [
                'C:\Program Files\PowerShell\Modules'
                'C:\Program Files\WindowsPowerShell\Modules'
            ]
        } else {
            [
                $'($home)\Documents\PowerShell\Modules'
                $'($home)\Documents\WindowsPowerShell\Modules'
            ]
        }

        for folder in $folders {
            deploy $"($source).psm1" $"($folder)/BootwareCompletion.psm1"
        }
    } else if $global {
        let dest = match $nu.os-info.name {
            "freebsd" => {
                bash: "/usr/local/share/bash-completion/completions/bootware"
                fish: "/usr/local/etc/fish/completions/bootware.fish"
             }
            "macos" => {
                let prefix = if $nu.os-info.arch == "aarch64" {
                    "/opt/homebrew"
                } else {
                    "/usr/local"
                }
                {
                    bash: $"($prefix)/share/bash-completion/completions/bootware"
                    fish: $"($prefix)/etc/fish/completions/bootware.fish"
                }
            }
            _ => {
                bash: "/usr/share/bash-completion/completions/bootware"
                fish: "/etc/fish/completions/bootware.fish"
            }
        }

        deploy --super $super --mode 644 $"($source).bash" $dest.bash
        deploy --super $super --mode 644 $"($source).fish" $dest.fish
        (
            deploy --super $super --mode 644 $"($source).man"
            "/usr/local/share/man/man1/bootware.1"
        )
    } else {
        (
            deploy --mode 644 $"($source).bash"
            $"($home)/.local/share/bash-completion/completions/bootware"
        )
        (
            deploy --mode 644 $"($source).fish"
            $"($home)/.config/fish/completions/bootware.fish"
        )
    }
}

# Check if super user elevation is required.
def need-super [dest: directory global: bool] {
    if $global {
        return true
    }
    try { mkdir $dest } catch { return true }
    try { touch $"($dest)/.super_check" } catch { return true }
    rm $"($dest)/.super_check" 
    false
}

# Install Bootware for FreeBSD, MacOS, Linux, and Windows systems.
def main [
    --dest (-d): directory # Directory to install Bootware
    --global (-g) # Install Bootware for all users
    --preserve-env (-p) # Do not update system environment
    --quiet (-q) # Print only error messages
    --version (-v): string = "main" # Version of Bootware to install
] {
    if $quiet { $env.BOOTWARE_NOLOG = "true" }
    # Force global if root on Unix.
    let global = $global or ((is-admin) and $nu.os-info.name != "windows")

    let dest_default = if $nu.os-info.name == "windows" {
        if $global {
            "C:\\Program Files\\Bootware"
        } else {
            $"($env.LOCALAPPDATA)\\Programs\\Bootware"
        }
    } else {
        if $global { "/usr/local/bin" } else { $"($env.HOME)/.local/bin" }
    }
    let dest = $dest | default $dest_default | path expand

    let system = need-super $dest $global
    let super = if ($system) { find-super } else { "" }

    log $"Installing Bootware to '($dest)'."
    install $super $dest $version
    if not $preserve_env and not ($dest in $env.PATH) {
        if $nu.os-info.name == "windows" {
            update-path $dest $system
        } else {
            update-shell $dest
        }
    }
    install-completions $super $global $version

    $env.PATH = $env.PATH | prepend $dest
    log $"Installed (bootware --version)."
}

# Get user home folder.
def path-home [] {
    if $nu.os-info.name == "windows" {
        $env.HOME? | default $"($env.HOMEDRIVE?)($env.HOMEPATH?)"
    } else {
        $env.HOME? 
    }
}

# Add destination path to Windows environment path.
def update-path [dest: directory global: bool] {
    let target = if $global { "Machine" } else { "User" }
    powershell -command $"
$Dest = '($dest | path expand)'
$Path = [Environment]::GetEnvironmentVariable\('Path', '($target)'\)
if \(-not \($Path -like \"*$Dest*\"\)\) {
    $PrependedPath = \"$Dest;$Path\"
    [System.Environment]::SetEnvironmentVariable\(
        'Path', \"$PrependedPath\", '($target)'
    \)
    Write-Output \"Added '$Dest' to the system path.\"
    Write-Output 'Source shell profile or restart shell after installation.'
}
"
}

# Add Bootware to system path in shell profile.
def update-shell [dest: directory] {
    let shell = $env.SHELL? | default "" | path basename

    let command = match $shell {
        "fish" => $"set --export PATH \"($dest)\" $PATH"
        "nu" => $"$env.PATH = [\"($dest)\" ...$env.PATH]"
        _ => $"export PATH=\"($dest):${PATH}\""
    }
    let profile = match $shell {
        "bash" => $"($env.HOME)/.bashrc"
        "fish" => "($env.HOME)/.config/fish/config.fish"
        "nu" => {
            if $nu.os-info.name == "macos" {
                $"($env.HOME)/Library/Application Support/nushell/config.nu"
            } else {
                $"$(env.HOME)/.config/nushell/config.nu"
            }
        }
        "zsh" => $"($env.HOME)/.zshrc"
        _ => $"($env.HOME)/.profile"
    }

    # Create profile parent directory and add export command to profile.
    mkdir ($profile | path dirname)
    $"\n# Added by Bootware installer.\n($command)\n" | save --append $profile
    log $"Added '($command)' to the '($profile)' shell profile."
    log "Source shell profile or restart shell after installation."
}
