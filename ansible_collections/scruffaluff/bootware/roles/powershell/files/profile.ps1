# PowerShell settings file.
#
# To profile PowerShell profile startup time, install PSProfiler,
# https://github.com/IISResetMe/PSProfiler, with command
# 'Install-Module -Name PSProfiler'. Then run command
# 'Measure-Script -Path $Profile'. For more information about the PowerShell
# profile file, visit
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles.

# Check if only minimally functional shell settings should be loaded.
#
# If file ~/.shell_minimal_config exists, then most shell completion will not be
# configured. These are useful to disable if on a slow system where shell
# startup takes too long.
If (Test-Path "$HOME/.shell_minimal_config") {
    $Env:SHELL_MINIMAL_CONFIG = 'true'
}

# Convenience functions.
Function Edit-History() {
    If (Get-Command $Env:EDITOR -ErrorAction SilentlyContinue) {
        & $Env:EDITOR $(Get-PSReadLineOption).HistorySavePath
    }
}

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

$Env:COMPOSE_DOCKER_CLI_BUILD = 'true'
$Env:DOCKER_BUILDKIT = 'true'

# Load Docker autocompletion if available.
If (
    (-Not $Env:SHELL_MINIMAL_CONFIG) -And
    (Get-Module -ListAvailable -Name DockerCompletion)
) {
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
If (
    (-Not $Env:SHELL_MINIMAL_CONFIG) -And
    (Get-Command bat -ErrorAction SilentlyContinue)
) {
    $Env:FZF_CTRL_T_OPTS = "--preview 'bat --color always --style numbers {} 2> Nul || tree {} | more +3'"
}

# Git settings.

# Load Git autocompletion if available.
If (
    (-Not $Env:SHELL_MINIMAL_CONFIG) -And
    (Get-Module -ListAvailable -Name posh-git)
) {
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
            Emphasis         = '#859900'
            InlinePrediction = '#268bd2'
            Member           = '#657b83'
            Number           = '#657b83'
            Parameter        = '#657b83'
            String           = '#657b83'
        }

        # PSStyle requires ANSI color codes and double quotes.
        $PSStyle.FileInfo.Directory = "`e[34;1m"
    }

    # Disable sounds for errors.
    Set-PSReadLineOption -BellStyle None

    # Setup Fzf PowerShell integration if available.
    #
    # Fzf PowerShell integration depends on PSReadLine being activated first.
    If (
        (-Not $Env:SHELL_MINIMAL_CONFIG) -And
        (Get-Module -ListAvailable -Name PsFzf)
    ) {
        Import-Module PsFzf

        # Replace builtin 'Ctrl+t' and 'Ctrl+r' bindings with Fzf key bindings.
        Set-PsFzfOption `
            -PSReadlineChordProvider 'Ctrl+t' `
            -PSReadlineChordReverseHistory 'Ctrl+r'
    }
}

# Python settings.

# Make Poetry create virutal environments inside projects.
$Env:POETRY_VIRTUALENVS_IN_PROJECT = 'true'

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
If (
    (-Not $Env:SHELL_MINIMAL_CONFIG) -And
    (Get-Command starship -ErrorAction SilentlyContinue)
) {
    Invoke-Expression (&starship init powershell)
}

# Tool settings.

$Env:BAT_THEME = 'Solarized (light)'
Set-Alias -Name cbcopy -Value Set-Clipboard
Set-Alias -Name cbpaste -Value Get-Clipboard
Set-Alias -Name exa -Value Get-ChildItem
Set-Alias -Name touch -Value New-Item

# Load Bootware autocompletion if available.
If (
    (-Not $Env:SHELL_MINIMAL_CONFIG) -And
    (Get-Module -ListAvailable -Name BootwareCompletion)
) {
    Import-Module BootwareCompletion
}

# Load Chocolatey autocompletion if available.
If (
    (-Not $Env:SHELL_MINIMAL_CONFIG) -And
    (Test-Path "$Env:ChocolateyInstall\helpers\chocolateyProfile.psm1")
) {
    Import-Module "$Env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
}

# Load Scoop autocompletion if available.
If (
    (-Not $Env:SHELL_MINIMAL_CONFIG) -And
    (Get-Module -ListAvailable -Name scoop-completion)
) {
    Import-Module scoop-completion
}

# Load SSH autocompletion if available.
If (
    (-Not $Env:SHELL_MINIMAL_CONFIG) -And
    (Get-Module -ListAvailable -Name SSHCompletion)
) {
    Import-Module SSHCompletion
}

# TypeScript settings.

# Load Deno autocompletion if available.
If (
    (-Not $Env:SHELL_MINIMAL_CONFIG) -And
    (Get-Module -ListAvailable -Name DenoCompletion)
) {
    Import-Module DenoCompletion
}

# User settings.

# Set default editor if Helix is installed.
If (Get-Command hx -ErrorAction SilentlyContinue) {
    $Env:COLORTERM = 'truecolor'
    $Env:EDITOR = 'hx'
}
