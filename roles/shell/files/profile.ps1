# PowerShell settings file.


# Docker settings.
$Env:COMPOSE_DOCKER_CLI_BUILD = 1
$Env:DOCKER_BUILDKIT = 1


# Python settings.

# Make Poetry create virutal environments inside projects.
$Env:POETRY_VIRTUALENVS_IN_PROJECT = 1

# Add scripts directory to system path.
$Env:PATH = "$HOME/scoop/apps/python/current/Scripts" + $Env:PATH


# Starship settings.

# Initialize Starship.
Invoke-Expression (&starship init powershell)


# Tool settings.

# Load Docker autocompletion.
Import-Module posh-docker

# Load Git autocompletion.
Import-Module post-git
