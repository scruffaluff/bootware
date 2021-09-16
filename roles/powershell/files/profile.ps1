# PowerShell settings file.


# Docker settings.
$Env:COMPOSE_DOCKER_CLI_BUILD = 1
$Env:DOCKER_BUILDKIT = 1

# Load Docker autocompletion if available.
If (Get-Module -ListAvailable -Name posh-docker) {
    Import-Module posh-docker
}


# Git settings.

# Load Git autocompletion if available.
If (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git
}


# PowerShell settings.

# Load PowerShell modules if available.
ForEach ($Module in @("Posh-SSH", "PoshColor", "PSReadLine")) {
    If (Get-Module -ListAvailable -Name $Module) {
        Import-Module $Module
    }
}


# Python settings.

# Make Poetry create virutal environments inside projects.
$Env:POETRY_VIRTUALENVS_IN_PROJECT = 1

# Add scripts directory to system path.
$Env:PATH = "$HOME/scoop/apps/python/current/Scripts;" + $Env:PATH


# Starship settings.

# Initialize Starship if available.
If (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}


# User settings.

# Add scripts directory to PATH environment variable.
$Env:PATH = "$HOME/.local/bin;" + $Env:PATH
