# PowerShell settings file.
#
# To profile PowerShell profile startup time, install PSProfiler,
# https://github.com/IISResetMe/PSProfiler, with command
# 'Install-Module -Name PSProfiler'. Then run command
# 'Measure-Script -Path $Profile'. For more information about the PowerShell
# profile file, visit
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles.

# Public convenience functions.

# Open PowerShell history file with default editor.
Function edit-history() {
    If ($Env:EDITOR) {
        & $Env:EDITOR $(Get-PSReadLineOption).HistorySavePath
    }
    Else {
        vim  $(Get-PSReadLineOption).HistorySavePath
    }
}

Function export($Key, $Value) {
    Set-Content Env:$Key $Value
}

Function get-params($Params, $Index) {
    If ($Params.Length -GT $Index) {
        Return $Params[$Index..($Params.Length - 1)]
    }
    Else {
        Return @()
    }
}

Function pkill() {
    While ($ArgIdx -LT $Args[0].Count) {
        Stop-Process -Force -Name "$(get-params $Args $ArgIdx)"
        $ArgIdx += 1
    }
}

Function pgrep() {
    While ($ArgIdx -LT $Args[0].Count) {
        Get-Process "$(get-params $Args $ArgIdx)"
        $ArgIdx += 1
    }
}

# Prepend existing directories that are not in the system path.
Function prepend-paths() {
    While ($ArgIdx -LT $Args[0].Count) {
        $Folder = get-params $Args $ArgIdx
        If (
            (Test-Path -Path $Folder -PathType Container) -And `
            (-Not ($Env:Path -Like "*$Folder*"))
        ) {
            Set-Content Env:Path "$Folder;$Env:Path"
        }
        $ArgIdx += 1
    }
}

Function rmf() {
    While ($ArgIdx -LT $Args[0].Count) {
        Remove-Item -Force -Recurse "$(get-params $Args $ArgIdx)"
        $ArgIdx += 1
    }
}

# Check if current shell is within a remote SSH session.
Function ssh-session() {
    !!"$Env:SSH_CLIENT$Env:SSH_CONNECTION$Env:SSH_TTY"
}

Function which() {
    While ($ArgIdx -LT $Args[0].Count) {
        Get-Command "$(get-params $Args $ArgIdx)" |
            Select-Object -ExpandProperty Definition
        $ArgIdx += 1
    }
}

# Essential fixes.

# Fix system path for SSH connections.
#
# On some Windows SSH configurations the path environment variable will only
# have a restricted set of entries, but the correct values can be obtained with
# GetEnvironmentVariable.
$Env:Path = [Environment]::GetEnvironmentVariable('Path', 'User').TrimEnd(';') `
    + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')

# Private convenience variables.

$Tty = -Not [System.Console]::IsOutputRedirected

# Shell settings.

# Add Unix compatibility aliases.
Set-Alias -Name open -Value Invoke-Item
Set-Alias -Name poweroff -Value Stop-Computer
Set-Alias -Name reboot -Value Restart-Computer
Set-Alias -Name rsync -Value scp
Set-Alias -Name touch -Value New-Item

# Configure PSReadLine settings if interactive and available.
#
# Do not enable Vi mode command line edits. Will disable functionality.
If ($Tty -And (Get-Module -ListAvailable -Name PSReadLine)) {
    Import-Module PSReadLine

    # Remove shell key bindings.
    Remove-PSReadLineKeyHandler -Chord Ctrl+w

    # Disable sounds for errors.
    Set-PSReadLineOption -BellStyle None

    # Use only spaces as word boundaries.
    Set-PSReadLineOption -WordDelimiters ' /\'

    # Add Unix shell key bindings.
    Set-PSReadLineKeyHandler -Chord Alt+d -Function DeleteWord
    Set-PSReadLineKeyHandler -Chord Alt+Z -Function Redo
    Set-PSReadLineKeyHandler -Chord Alt+z -Function Undo
    Set-PSReadLineKeyHandler -Chord Ctrl+a -Function BeginningOfLine
    Set-PSReadLineKeyHandler -Chord Ctrl+e -Function EndOfLine
    Set-PSReadLineKeyHandler -Chord Ctrl+d -Function BackwardDeleteWord
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
    Set-PSReadLineKeyHandler -Chord Alt+c -ScriptBlock {
        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

        $WorkingDir = "$(Get-Location)\"
        # Need to use ".Replace" instead of "-Replace" to avoid regular
        # expression features as explained at
        # https://stackoverflow.com/a/24287874.
        $StripLine = $Line.Replace("$WorkingDir", '')
        If ($StripLine.Length -LT $Line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($StripLine)
        }
        Else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$Line$WorkingDir")
        }
    }
    Set-PSReadLineKeyHandler -Chord Alt+e ViEditVisually
    Set-PSReadLineKeyHandler -Chord Alt+f -ScriptBlock {
        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

        $StripLine = $Line -Replace " 2>&1 `\| fzf`$", ''
        If ($StripLine.Length -LT $Line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($StripLine)
        }
        Else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$Line 2>&1 | fzf")
        }
    }
    Set-PSReadLineKeyHandler -Chord Alt+p -ScriptBlock {
        If ($Env:PAGER) {
            $Pager = $Env:PAGER
        }
        Else {
            $PAGER = 'less'
        }

        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

        $StripLine = $Line -Replace " 2>&1 `\| $Pager`$", ''
        If ($StripLine.Length -LT $Line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($StripLine)
        }
        Else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$Line 2>&1 | $Pager")
        }
    }
    Set-PSReadLineKeyHandler -Chord Alt+s -ScriptBlock {
        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

        $StripLine = $Line -Replace '^sudo ', ''
        If ($StripLine.Length -LT $Line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($StripLine)
        }
        Else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("sudo $Line")
        }
    }
    Set-PSReadLineKeyHandler -Chord Ctrl+k -ScriptBlock {
        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)

        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($Line.Substring(0, $Cursor))
    }
    Set-PSReadLineKeyHandler -Chord Ctrl+u -ScriptBlock {
        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)

        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($Line.Substring($Cursor, $Line.Length - $Cursor))
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(0)
    }
    Set-PSReadLineKeyHandler -Chord Ctrl+x -ScriptBlock {
        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)
        Set-Clipboard $Line
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
}

# Bat settings.

# Set default pager to Bat.
If (Get-Command -ErrorAction SilentlyContinue bat) {
    $Env:PAGER = 'bat'
}

# Bootware settings.

# Load Bootware autocompletion if available.
If ($Tty) {
    Import-Module -ErrorAction SilentlyContinue BootwareCompletion
}

# Clipboard settings.

# Add unified clipboard aliases.
Set-Alias -Name cbcopy -Value Set-Clipboard
Set-Alias -Name cbpaste -Value Get-Clipboard

# Docker settings.

# Ensure newer Docker features are enabled.
$Env:COMPOSE_DOCKER_CLI_BUILD = 'true'
$Env:DOCKER_BUILDKIT = 'true'
$Env:DOCKER_CLI_HINTS = 'false'

# Load Docker autocompletion if interactice and available.
If ($Tty) {
    Import-Module -ErrorAction SilentlyContinue DockerCompletion
}

# Fzf settings.

# Setup Fzf PowerShell integration if interactive and available.
If (($Tty) -And (Get-Module -ListAvailable -Name PsFzf)) {
    # Disable Fzf Alt-C command.
    $Env:FZF_ALT_C_COMMAND = ''
    # Set Fzf solarized light theme.
    $FzfColors = '--color fg:-1,bg:-1,hl:33,fg+:235,bg+:254,hl+:33'
    $FzfHighlights = '--color info:136,prompt:136,pointer:230,marker:230,spinner:136'
    $Env:FZF_DEFAULT_OPTS = "--reverse $FzfColors $FzfHighlights"
    Remove-Variable -Force FzfColors
    Remove-Variable -Force FzfHighlights

    Import-Module PsFzf
    If (
        (Get-Command -ErrorAction SilentlyContinue bat) -And `
        (Get-Command -ErrorAction SilentlyContinue lsd)
    ) {
        # PSFzf requires inline code since it cannot lookup profile defined
        # functions at runtime.
        $FzfFilePreview = 'bat --color always --line-range :100 --style numbers'
        $FzfDirPreview = 'lsd --tree --depth 1'
        $Env:FZF_CTRL_T_OPTS = "--preview 'If (Test-Path -Path {} -PathType Container) { $FzfDirPreview {} } Else { $FzfFilePreview {} }'"
    }

    # Replace builtin 'Ctrl+t' and 'Ctrl+r' bindings with Fzf key bindings.
    Set-PsFzfOption `
        -PSReadlineChordProvider 'Ctrl+f' `
        -PSReadlineChordReverseHistory 'Ctrl+r'
}

# Git settings.

# Load Git autocompletion if interactive and available.
If ($Tty) {
    Import-Module -ErrorAction SilentlyContinue posh-git
}

# Helix settings.

# Set default editor to Helix if available.
If (Get-Command -ErrorAction SilentlyContinue hx) {
    $Env:EDITOR = 'hx'
}

# Just settings.

# Add alias for account wide Just recipes.
Function jt() {
    just --justfile "$HOME/.justfile" --working-directory . $Args
}

# Lsd settings.

# Replace Ls with Lsd if avialable.
If (Get-Command -ErrorAction SilentlyContinue lsd) {
    Set-Alias -Name ls -Option AllScope -Value lsd
}

# Python settings.

# Add Python debugger alias.
Function pdb() {
    python3 -m pdb $Args
}

# Make Poetry create virutal environments inside projects.
$Env:POETRY_VIRTUALENVS_IN_PROJECT = 'true'
# Fix Poetry package install issue on headless systems.
$Env:PYTHON_KEYRING_BACKEND = 'keyring.backends.fail.Keyring'

# Ripgrep settings.

# Set Ripgrep settings file location.
$Env:RIPGREP_CONFIG_PATH = "$HOME/.ripgreprc"

# Rust settings.

# Add Rust debugger aliases.
Set-Alias -Name rgd -Value rust-gdb
Set-Alias -Name rld -Value rust-lldb

# Secure Shell settings.

# Load SSH autocompletion if interactive and available.
If ($Tty) {
    Import-Module -ErrorAction SilentlyContinue SSHCompletion
}

# Starship settings.

# Disable Starship warnings about command timeouts.
$Env:STARSHIP_LOG = 'error'

# Initialize Starship if interactive and available.
If ($Tty) {
    If (Get-Command -ErrorAction SilentlyContinue starship) {
        Invoke-Expression (&starship init powershell)
    }
    Else {
        # Warning: PowerShell 5 does not support writing unicode characters.
        Function Prompt {
            "`r`n$Env:USER at $Env:COMPUTERNAME in $(Get-Location)`r`n> "
        }
    }
}

# Yazi settings.

# Yazi wrapper to change directory on program exit.
Function yz() {
    $Tmp = [System.IO.Path]::GetTempFileName()
    yazi --cwd-file $Tmp $Args
    $Cwd = Get-Content -Path $Tmp
    If (($Cwd) -And ($Cwd -NE $PWD.Path)) {
        Set-Location $Cwd
    }
    Remove-Item $Tmp
}

# Zoxide settings.

# Initialize Zoxide if interactive and available.
If ($Tty -And (Get-Command -ErrorAction SilentlyContinue zoxide)) {
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
}

# Alacritty settings.

# Placed near end of config to ensure Zellij reads the correct window size.
If ($Tty -And ($Env:TERM -Eq 'alacritty') -And (-Not ($TERM_PROGRAM))) {
    # Autostart Zellij or connect to existing session if within Alacritty
    # terminal.
    #
    # For more information, visit
    # https://zellij.dev/documentation/integration.html.
    If (
        (Get-Command -ErrorAction SilentlyContinue zellij) -And
        (-Not $(ssh-session))
    ) {
        # Attach to a default session if it exists.
        $Env:ZELLIJ_AUTO_ATTACH = 'true'
        # Exit the shell when Zellij exits.
        $Env:ZELLIJ_AUTO_EXIT = 'true'
        # TODO: Uncomment when Zellij gains Windows support.
        # Invoke-Expression (& { (zellij setup --generate-auto-start powershell | Out-String) })
    }

    # Switch TERM variable to avoid "alacritty: unknown terminal type" errors
    # during remote connections.
    #
    # For more information, visit
    # https://github.com/alacritty/alacritty/issues/3962.
    $Env:TERM = 'xterm-256color'
}

# Remove private convenience variables.

Remove-Variable -Force Tty

# User settings.

# Load user aliases, secrets, and variables.
If (Test-Path "$HOME/.env.ps1") {
    . "$HOME/.env.ps1"
}
If (Test-Path "$HOME/.secrets.ps1") {
    . "$HOME/.secrets.ps1"
}
