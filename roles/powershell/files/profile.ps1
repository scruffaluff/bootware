# PowerShell settings file.
#
# For more information, visit
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles.

# Docker settings.
$Env:COMPOSE_DOCKER_CLI_BUILD = 1
$Env:DOCKER_BUILDKIT = 1

# Load Docker autocompletion if available.
If (Get-Module -ListAvailable -Name posh-docker) {
    Import-Module posh-docker
}

# Load Kubectl autocompletion if available.
If (Get-Module -ListAvailable -Name PSKubectlCompletion) {
    Import-Module PSKubectlCompletion
}

# GCloud settings.

# Load GCloud autocompletion if available.
If (Get-Module -ListAvailable -Name GcloudTabComplete) {
    Import-Module GcloudTabComplete
}

# Git settings.

# Load Git autocompletion if available.
If (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git
}

# PowerShell settings.

# Configure console theme if available.
If (Get-Module -ListAvailable -Name PSConsoleTheme) {
    Import-Module PSConsoleTheme
    Set-ConsoleTheme "Solarized Light"
}

# Configure PSReadLine settings if available.
If (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine

    # Use Bash style tab completion.
    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

    # Use VI mode for command line editing.
    Set-PSReadlineOption -EditMode vi

    # Add history based autocompletion to arrow keys.
    Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

    # Show history based autocompletion for every typed character.
    Set-PSReadLineOption -PredictionSource History
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

# Tool settings.

# Load SSH autocompletion if available.
If (Get-Module -ListAvailable -Name Posh-SSH) {
    Import-Module Posh-SSH
}

# TypeScript settings.

# Load NPM autocompletion if available.
If (Get-Module -ListAvailable -Name npm-completion) {
    Import-Module npm-completion
}

# User settings.

# Add scripts directory to PATH environment variable.
$Env:PATH = "$HOME/.local/bin;" + $Env:PATH
