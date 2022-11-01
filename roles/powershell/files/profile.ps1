# PowerShell settings file.
#
# For more information, visit
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles.


# Convenience functions.
Function Export($Name, $Value) {
    Set-Content Env:$Name $Value
}

Function PKill($Name) {
    Stop-Process -Force -Name "$Name"
}

Function PGrep($Name) {
    Get-Process $Name
}

Function Which($Name) {
    Get-Command $Name | Select-Object -ExpandProperty Definition
}

# Docker settings.
$Env:COMPOSE_DOCKER_CLI_BUILD = 1
$Env:DOCKER_BUILDKIT = 1

# Load Docker autocompletion if available.
If (Get-Module -ListAvailable -Name DockerCompletion) {
    Import-Module DockerCompletion
}

# Fzf settings.

# Set Fzf solarized light theme.
$FzfColors = '--color fg:-1,bg:-1,hl:33,fg+:235,bg+:254,hl+:33'
$FzfHighlights = '--color info:136,prompt:136,pointer:230,marker:230,spinner:136'
$Env:FZF_DEFAULT_OPTS = "--reverse $FzfColors $FzfHighlights"

# Add inode preview to Fzf file finder.
#
# Flags:
#   -q: Only check for exit status by supressing output.
If (Get-Command bat -ErrorAction SilentlyContinue) {
    $Env:FZF_CTRL_T_OPTS = "--preview 'bat --color always --style numbers {} 2> Nul || tree {} | more +3'"
}

# Load Kubectl autocompletion if available.
If (Get-Module -ListAvailable -Name PSKubectlCompletion) {
    Import-Module PSKubectlCompletion
}

# Git settings.

# Load Git autocompletion if available.
If (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git
}

# Configure PSReadLine settings if available.
#
# Do not enable Vi mode command line edits. Will disable functionality.
If (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine

    # Use only spaces as word boundaries.
    Set-PSReadLineOption -WordDelimiters ' /\'

    # Add Unix shell key bindings.
    Set-PSReadLineKeyHandler -Chord Ctrl+a -Function BeginningOfLine
    Set-PSReadLineKeyHandler -Chord Ctrl+w -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Chord Shift+LeftArrow -Function ShellBackwardWord

    # Set shift+rightarrow to jump to end of next suggestion if at the end
    # of the line else to the end of the next word.
    Set-PSReadLineKeyHandler -Chord Shift+RightArrow -ScriptBlock {
        Param($Key, $Arg)

        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)

        If ($Cursor -LT $Line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::ShellNextWord($Key, $Arg)
        }
        Else {
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($Key, $Arg)
        }
    }

    # Use Bash style tab completion.
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    # Add history based autocompletion to arrow keys.
    Set-PSReadLineKeyHandler -Chord DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord UpArrow -Function HistorySearchBackward
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd

    # Features are only available for PowerShell 7.0 and later.
    If ($PSVersionTable.PSVersion.Major -GE 7) {
        # Show history based autocompletion for every typed character.
        Set-PSReadLineOption -PredictionSource History

        # Use solarized light compatible colors for predictions.
        Set-PSReadLineOption -Colors @{
            Default          = '#657b83'
            InlinePrediction = '#268bd2'
            Number           = '#657b83'
            Parameter        = '#657b83'
            String           = '#657b83'
        }
    }

    # Disable sounds for errors.
    Set-PSReadLineOption -BellStyle None

    # Setup Fzf PowerShell integration if available.
    #
    # Fzf PowerShell integration depends on PSReadLine being activated first.
    If (Get-Module -ListAvailable -Name PsFzf) {
        Import-Module PsFzf

        # Replace builtin 'Ctrl+t' and 'Ctrl+r' bindings with Fzf key bindings.
        Set-PsFzfOption `
            -PSReadlineChordProvider 'Ctrl+t' `
            -PSReadlineChordReverseHistory 'Ctrl+r'
    }
}

# Python settings.

# Make Poetry create virutal environments inside projects.
$Env:POETRY_VIRTUALENVS_IN_PROJECT = 1

# Shell settings.

# Load aliases if file exists.
If (Test-Path "$HOME/.aliases.ps1") {
    . "$HOME/.aliases.ps1"
}

# Load environment variables if file exists.
If (Test-Path "$HOME/.env.ps1") {
    . "$HOME/.env.ps1"
}

# Load secrets if file exists.
If (Test-Path "$HOME/.secrets.ps1") {
    . "$HOME/.secrets.ps1"
}

# Starship settings.

# Initialize Starship if available.
If (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# Tool settings.

$Env:BAT_THEME = 'Solarized (light)'
Set-Alias -Name exa -Value Get-ChildItem
Set-Alias -Name touch -Value New-Item

# Load Bootware autocompletion if available.
If (Get-Module -ListAvailable -Name BootwareCompletion) {
    Import-Module BootwareCompletion
}

# Load Chocolatey autocompletion if available.
If (Test-Path "$Env:ChocolateyInstall\helpers\chocolateyProfile.psm1") {
    Import-Module "$Env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
}

# Load Scoop autocompletion if available.
If (Get-Module -ListAvailable -Name scoop-completion) {
    Import-Module scoop-completion
}

# Load SSH autocompletion if available.
If (Get-Module -ListAvailable -Name SSHCompletion) {
    Import-Module SSHCompletion
}

# Initialize Zoxide if available.
If (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (
        & {
            If ($PSVersionTable.PSVersion.Major -lt 6) {
                $Hook = 'prompt'
            }
            Else {
                $Hook = 'pwd'
            }
            zoxide init --hook $Hook powershell --cmd cd | Out-String
        }
    )
}

# # TypeScript settings.

# Load Deno autocompletion if available.
If (Get-Module -ListAvailable -Name DenoCompletion) {
    Import-Module DenoCompletion
}

# Load NPM autocompletion if available.
If (Get-Module -ListAvailable -Name npm-completion) {
    Import-Module npm-completion
}
