# PowerShell settings file.
#
# To progile PowerShell profile startup time, install PSProfiler,
# https://github.com/IISResetMe/PSProfiler, with command
# 'Install-Module -Name PSProfiler'. Then run command
# 'Measure-Script -Path $Profile'. For more information about the PowerShell
# profile file, visit
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles.

Function Delete-History($Command) {
    $Reply = Read-Host -Prompt "Delete command '$Command' from PowerShell history? [Y/n]"

    If ($Reply -In 'Y', 'y', 'Yes', 'yes') {
        $HistoryPath = $(Get-PSReadLineOption).HistorySavePath
        $Content = $(Get-Content -Path "$HistoryPath" | Where-Object { $_ -NE "$Command" })
        # Do not quote $Content variable. It will remove newlines.
        Set-Content -Path "$HistoryPath" -Value $Content

        # Clear the current PSReadLine history session and repopulate it with
        # filtered commands.
        #
        # Solution taken from
        # https://github.com/PowerShell/PSReadLine/issues/494#issuecomment-273358367.
        [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
        $Content | Where-Object { [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($_) }

        Write-Output "Removed command '$Command' from PowerShell history"
    }
}

# Convenience functions.
Function Edit-History() {
    $Env:EDITOR $(Get-PSReadLineOption).HistorySavePath
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
    If (Get-Module -ListAvailable -Name PsFzf) {
        Import-Module PsFzf

        # Replace builtin 'Ctrl+t' and 'Ctrl+r' bindings with Fzf key bindings.
        Set-PsFzfOption `
            -PSReadlineChordProvider 'Ctrl+t' `
            -PSReadlineChordReverseHistory 'Ctrl+r'
    }

    # Add ctrl+d key binding to delete current command from PowerShell history.
    Set-PSReadLineKeyHandler -Chord Ctrl+d -ScriptBlock {
        $Command = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Command, [ref]$Cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::InsertLineBelow()

        If ($Command) {
            Delete-History "$Command"
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        }
    }

    # Add ctrl+y key binding to edit PowerShell history file.
    Set-PSReadLineKeyHandler -Chord Ctrl+y -ScriptBlock {
        Edit-History
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
Set-Alias -Name cbcopy -Value Set-Clipboard
Set-Alias -Name cbpaste -Value Get-Clipboard
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

# TypeScript settings.

# Load Deno autocompletion if available.
If (Get-Module -ListAvailable -Name DenoCompletion) {
    Import-Module DenoCompletion
}

# Load NPM autocompletion if available.
If (Get-Module -ListAvailable -Name npm-completion) {
    Import-Module npm-completion
}

# User settings.

# Set default editor if Helix is installed.
If (Get-Command hx -ErrorAction SilentlyContinue) {
    $Env:COLORTERM = 'truecolor'
    $Env:EDITOR = 'hx'
}
