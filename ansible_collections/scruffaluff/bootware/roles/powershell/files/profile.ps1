# PowerShell settings file.
#
# To profile PowerShell profile startup time, install PSProfiler,
# https://github.com/IISResetMe/PSProfiler, with command
# 'Install-Module -Name PSProfiler'. Then run command
# 'Measure-Script -Path $Profile'. For more information about the PowerShell
# profile file, visit
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles.

# Private convenience functions.

Function _GetParameters($Params, $Index) {
    If ($Params.Length -GT $Index) {
        Return $Params[$Index..($Params.Length - 1)]
    }
    Else {
        Return @()
    }
}

# Public convenience interactive functions.

Function edit-history() {
    If (Get-Command $Env:EDITOR -ErrorAction SilentlyContinue) {
        & $Env:EDITOR $(Get-PSReadLineOption).HistorySavePath
    }
}

Function export($Key, $Value) {
    Set-Content Env:$Key $Value
}

Function pkill() {
    While ($ArgIdx -LT $Args[0].Count) {
        Stop-Process -Force -Name $(_GetParameters $Args $ArgIdx)
        $ArgIdx += 1
    }
}

Function pgrep() {
    While ($ArgIdx -LT $Args[0].Count) {
        Get-Process $(_GetParameters $Args $ArgIdx)
        $ArgIdx += 1
    }
}

Function rmf() {
    While ($ArgIdx -LT $Args[0].Count) {
        Remove-Item -Force -Recurse $(_GetParameters $Args $ArgIdx)
        $ArgIdx += 1
    }
}

Function which() {
    While ($ArgIdx -LT $Args[0].Count) {
        Get-Command $(_GetParameters $Args $ArgIdx) `
            | Select-Object -ExpandProperty Definition
        $ArgIdx += 1
    }
}

# Private convenience variables.

$_Tty = -Not [System.Console]::IsOutputRedirected

# Shell settings.

# Add Unix compatibility aliases.
Set-Alias -Name open -Value Invoke-Item
Set-Alias -Name touch -Value New-Item

# Configure PSReadLine settings if available.
#
# Do not enable Vi mode command line edits. Will disable functionality.
If ($_Tty -And (Get-Module -ListAvailable -Name PSReadLine)) {
    Import-Module PSReadLine

    # Use only spaces as word boundaries.
    Set-PSReadLineOption -WordDelimiters ' /\'

    # Add Unix shell key bindings.
    Set-PSReadLineKeyHandler -Chord Ctrl+a -Function BeginningOfLine
    Set-PSReadLineKeyHandler -Chord Ctrl+e -Function EndOfLine
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

    # Add Fish style keybindings.
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord Alt+s -ScriptBlock {
        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("sudo $Line")
    }
    Set-PSReadLineKeyHandler -Chord Ctrl+u -Function RevertLine
    Set-PSReadLineKeyHandler -Chord Ctrl+x -ScriptBlock {
        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)
        Set-Clipboard "$Line"
    }

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
            -PSReadlineChordProvider 'Ctrl+f' `
            -PSReadlineChordReverseHistory 'Ctrl+r'
    }
}

# Add unified clipboard aliases.
Set-Alias -Name cbcopy -Value Set-Clipboard
Set-Alias -Name cbpaste -Value Get-Clipboard

# Bat settings.

# Set default pager to Bat.
If (Get-Command bat -ErrorAction SilentlyContinue) {
    $Env:PAGER = 'bat'
}

# Bootware settings.

# Load Bootware autocompletion if available.
If ($_Tty) {
    Import-Module BootwareCompletion -ErrorAction SilentlyContinue
}

# Docker settings.

# Ensure newer Docker features are enabled.
$Env:COMPOSE_DOCKER_CLI_BUILD = 'true'
$Env:DOCKER_BUILDKIT = 'true'
$Env:DOCKER_CLI_HINTS = 'false'

# Load Docker autocompletion if available.
If ($_Tty) {
    Import-Module DockerCompletion -ErrorAction SilentlyContinue
}

# Fzf settings.

# Set Fzf solarized light theme.
$FzfColors = '--color fg:-1,bg:-1,hl:33,fg+:235,bg+:254,hl+:33'
$FzfHighlights = '--color info:136,prompt:136,pointer:230,marker:230,spinner:136'
$Env:FZF_DEFAULT_OPTS = "--reverse $FzfColors $FzfHighlights"

# Add inode preview to Fzf file finder.
If ((Get-Command bat -ErrorAction SilentlyContinue) -And (Get-Command lsd -ErrorAction SilentlyContinue)) {
    $Env:FZF_CTRL_T_OPTS = "--preview 'bat --color always --style numbers {} 2> Nul || lsd --tree --depth 1 {} | bat'"
}

# Git settings.

# Load Git autocompletion if available.
If ($_Tty) {
    Import-Module posh-git -ErrorAction SilentlyContinue
}

# Helix settings.

# Set full color support for terminal and default editor to Helix.
If (Get-Command hx -ErrorAction SilentlyContinue) {
    $Env:EDITOR = 'hx'
}

# Just settings.

# Add alias for account wide Just recipes.
Function jt() {
    just --justfile "$HOME/.justfile" --working-directory . $Args
}

# Python settings.

# Add Python debugger alias.
Function pdb() {
    python3 -m pdb $Args
}
# Fix Poetry package install issue on headless systems.
$Env:PYTHON_KEYRING_BACKEND = 'keyring.backends.fail.Keyring'
# Make Poetry create virutal environments inside projects.
$Env:POETRY_VIRTUALENVS_IN_PROJECT = 'true'

# Starship settings.

# Disable Starship warnings about command timeouts.
$Env:STARSHIP_LOG = 'error'

# Initialize Starship if available.
If ($_Tty -And (Get-Command starship -ErrorAction SilentlyContinue)) {
    Invoke-Expression (&starship init powershell)
}

# Secure Shell settings.

# Load SSH autocompletion if available.
If ($_Tty) {
    Import-Module SSHCompletion -ErrorAction SilentlyContinue
}

# Rust settings.

# Add Rust debugger alias.
Set-Alias -Name rdb -Value rust-lldb

# Zoxide settings.

# Initialize Zoxide if available.
If ($_Tty -And (Get-Command zoxide -ErrorAction SilentlyContinue)) {
    Invoke-Expression (&{ (zoxide init --cmd cd powershell | Out-String) })
}

# User settings.

# Load user aliases, secrets, and variables.
If (Test-Path "$HOME/.env.ps1") {
    . "$HOME/.env.ps1"
}
If (Test-Path "$HOME/.secrets.ps1") {
    . "$HOME/.secrets.ps1"
}
