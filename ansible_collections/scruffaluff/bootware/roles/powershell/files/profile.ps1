# PowerShell settings file.
#
# To profile PowerShell profile startup time, install PSProfiler,
# https://github.com/IISResetMe/PSProfiler, with command
# 'Install-Module -Name PSProfiler'. Then run command
# 'Measure-Script -Path $Profile'. For more information about the PowerShell
# profile file, visit
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles.

# Public convenience functions.

function acls($Path) {
    Get-ChildItem $Path | Get-Acl
}

function chown() {
    $ArgIdx = 0
    $File = ''
    $Owner = ''
    $Recursive = $False

    while ($ArgIdx -lt $Args.Count) {
        switch ($Args[$ArgIdx]) {
            { $_ -in '-h', '--help' } {
                Write-Output @'
Change file owner.

Usage: wchown [OPTIONS] <OWNER> <FILE>

Options:
  -h, --help        Print help information
  -R, --recursive   Operate on files and directories recursively
'@
                exit 0
            }
            { $_ -in '-R', '--recursive' } {
                $Recursive = $True
                $ArgIdx += 1
                break
            }
            default {
                if (-not $Owner) {
                    $Owner = $Args[$ArgIdx]
                }
                elseif (-not $File) {
                    $File = $Args[$ArgIdx]
                }
                $ArgIdx += 1
                break
            }
        }
    }

    $Account = New-Object -TypeName System.Security.Principal.NTAccount `
        -ArgumentList $Owner
    $Paths = @(Get-Item -Path $File)
    if ($Recursive) {
        $Paths += Get-ChildItem -Recurse -Path $File
    }

    foreach ($Path in $Paths) {
        $ACL = Get-Acl -Path $Path.FullName
        $ACL.SetOwner($Account)
        Set-Acl -AclObject $ACL -Path $Path.FullName
    }
}

# Open PowerShell history file with default editor.
function edit-history() {
    if ($Env:EDITOR) {
        & $Env:EDITOR $(Get-PSReadLineOption).HistorySavePath
    }
    else {
        vim  $(Get-PSReadLineOption).HistorySavePath
    }
}

function export($Key, $Value) {
    Set-Content Env:$Key $Value
}

function pkill() {
    $ArgIdx = 0
    while ($ArgIdx -lt $Args.Count) {
        Stop-Process -Force -Name $Args[$ArgIdx]
        $ArgIdx += 1
    }
}

function pgrep() {
    $ArgIdx = 0
    while ($ArgIdx -lt $Args.Count) {
        Get-Process $Args[$ArgIdx]
        $ArgIdx += 1
    }
}

# Prepend existing directories that are not in the system path.
function prepend-paths() {
    $ArgIdx = 0
    while ($ArgIdx -lt $Args.Count) {
        $Folder = [System.IO.Path]::GetFullPath($Args[$ArgIdx])
        if (
            (Test-Path -Path $Folder -PathType Container) -and `
            (-not ($Env:Path -like "*$Folder*"))
        ) {
            Set-Content Env:Path "$Folder;$Env:Path"
        }
        $ArgIdx += 1
    }
}

function rmf() {
    $ArgIdx = 0
    while ($ArgIdx -lt $Args.Count) {
        Remove-Item -Force -Recurse $Args[$ArgIdx]
        $ArgIdx += 1
    }
}

# Check if current shell is within a remote SSH session.
function ssh-session() {
    !!"$Env:SSH_CLIENT$Env:SSH_CONNECTION$Env:SSH_TTY"
}

function touch() {
    $ArgIdx = 0
    while ($ArgIdx -lt $Args.Count) {
        switch ($Args[$ArgIdx]) {
            { $_ -in '-h', '--help' } {
                Write-Output @'
Create file if does not exist.

Usage: touch [OPTIONS] <FILES>...

Options:
  -h, --help        Print help information
'@
                exit 0
            }
            default {
                if (-not (Test-Path -Path $Args[$ArgIdx])) {
                    New-Item $Args[$ArgIdx] | Out-Null
                }
                $ArgIdx += 1
                break
            }
        }
    }
}

function which() {
    $ArgIdx = 0
    while ($ArgIdx -lt $Args.Count) {
        Get-Command $Args[$ArgIdx] |
            Select-Object -ExpandProperty Definition
        $ArgIdx += 1
    }
}

# Private convenience variables.

$Tty = -not [System.Console]::IsOutputRedirected

# System settings.

# Fix system path for SSH connections.
#
# On some Windows SSH configurations the path environment variable will only
# have a restricted set of entries, but the correct values can be obtained with
# GetEnvironmentVariable.
$Env:Path = [Environment]::GetEnvironmentVariable('Path', 'User').TrimEnd(';') `
    + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')

# Add standard Unix environment variables for Windows.
$Env:HOME = "$($Env:HOMEDRIVE)$($Env:HOMEPATH)"
$Env:USER = $Env:USERNAME

# Alacritty settings.

if ($Tty -and ($Env:TERM -eq 'alacritty') -and (-not ($TERM_PROGRAM))) {
    # Autostart Zellij or connect to existing session if within Alacritty
    # terminal.
    #
    # For more information, visit
    # https://zellij.dev/documentation/integration.html.
    if (
        (Get-Command -ErrorAction SilentlyContinue zellij) -and
        (-not $(ssh-session))
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

# Bat settings.

# Set default pager to Bat.
if (Get-Command -ErrorAction SilentlyContinue bat) {
    $Env:PAGER = 'bat'
}

# Bootware settings.

# Load Bootware completions if available.
if ($Tty) {
    Import-Module -ErrorAction SilentlyContinue BootwareCompletion
}

# Carapace settings.

# Load Carapace completions if available.
if (
    ($Tty) -and
    ($PSVersionTable.PSVersion.Major -ge 7) -and
    (Get-Command -ErrorAction SilentlyContinue carapace)
) {
    $Env:CARAPACE_BRIDGES = 'fish,zsh,bash,inshellisense'
    carapace _carapace | Out-String | Invoke-Expression
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

# Add LazyDocker convenience alias.
Set-Alias -Name lzd -Value lazydocker

# Load Docker completions if interactice and available.
if ($Tty) {
    Import-Module -ErrorAction SilentlyContinue DockerCompletion
}

# FFmpeg settings.

# Disable verbose FFmpeg banners.
function ffmpeg() {
    ffmpeg.exe -hide_banner -stats -loglevel quiet $Args
}
function ffplay() {
    ffplay.exe -hide_banner -loglevel quiet $Args
}
function ffprobe() {
    ffprobe.exe -hide_banner $Args
}

# Fzf settings.

# Setup Fzf PowerShell integration if interactive and available.
if (($Tty) -and (Get-Module -ListAvailable -Name PsFzf)) {
    # Disable Fzf Alt-C command.
    $Env:FZF_ALT_C_COMMAND = ''
    # Set Fzf solarized light theme.
    $FzfColors = '--color fg:-1,bg:-1,hl:33,fg+:235,bg+:254,hl+:33'
    $FzfHighlights = '--color info:136,prompt:136,pointer:230,marker:230,spinner:136'
    $Env:FZF_DEFAULT_OPTS = "--reverse $FzfColors $FzfHighlights"
    Remove-Variable -Name FzfColors
    Remove-Variable -Name FzfHighlights

    Import-Module PsFzf
    if (
        (Get-Command -ErrorAction SilentlyContinue bat) -and `
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

# Load Git completions if interactive and available.
if ($Tty) {
    Import-Module -ErrorAction SilentlyContinue posh-git
}

# Helix settings.

# Set default editor to Helix if available.
if (Get-Command -ErrorAction SilentlyContinue hx) {
    $Env:EDITOR = 'hx'
}

# Just settings.

# Add alias for account wide Just recipes.
function jt() {
    just --justfile "$HOME\.justfile" --working-directory . $Args
}

# Lsd settings.

# Set solarized light color theme for several Unix tools.
#
# Uses output of command "vivid generate solarized-light" from
# https://github.com/sharkdp/vivid.
if (Test-Path -Path "$HOME\.ls_colors" -PathType Leaf) {
    $Env:LS_COLORS = Get-Content "$HOME\.ls_colors"
}

# Replace Ls with Lsd if available.
if (Get-Command -ErrorAction SilentlyContinue lsd) {
    Set-Alias -Name ls -Option AllScope -Value lsd
}

# Podman settings.

# Load Podman completions if interactice and available.
if ($Tty) {
    Import-Module -ErrorAction SilentlyContinue PodmanCompletion
}

# Procs settings.

# Set light theme since Procs automatic theming fails on some systems.
function procs() {
    procs.exe --theme light $Args
}

# Python settings.

# Add Jupyter Lab alias.
function jupylab() {
    uv tool run --from jupyterlab --with bokeh,numpy,polars,scipy jupyter-lab `
        $Args
}
# Add Python debugger alias.
function pdb() {
    python3 -m pdb $Args
}

# Make Poetry create virtual environments inside projects.
$Env:POETRY_VIRTUALENVS_IN_PROJECT = 'true'
# Fix Poetry package install issue on headless systems.
$Env:PYTHON_KEYRING_BACKEND = 'keyring.backends.fail.Keyring'

# Ripgrep settings.

# Set Ripgrep settings file location.
$Env:RIPGREP_CONFIG_PATH = "$HOME\.ripgreprc"

# Rust settings.

# Add Rust debugger aliases.
function rgd() {
    rust-gdb --quiet $Args
}
function rld() {
    rust-lldb --source-quietly $Args
}

# Secure Shell settings.

# Load SSH completions if interactive and available.
if ($Tty) {
    Import-Module -ErrorAction SilentlyContinue SSHCompletion
}

# Shell settings.

# Add Unix compatibility aliases.
Set-Alias -Name open -Value Invoke-Item
function poweroff() {
    Stop-Computer -Force
}
function reboot() {
    Restart-Computer -Force
}

# Configure PSReadLine settings if interactive and available.
#
# Do not enable Vi mode command line edits. Will disable functionality.
if ($Tty -and (Get-Module -ListAvailable -Name PSReadLine)) {
    Import-Module PSReadLine

    # Remove shell key bindings.
    Remove-PSReadLineKeyHandler -Chord Ctrl+w
    # Disable prompt to show all completion possibilities.
    Set-PSReadLineOption -CompletionQueryItems 1000000
    # Disable sounds for errors.
    Set-PSReadLineOption -BellStyle None
    # Use only spaces as word boundaries.
    Set-PSReadLineOption -WordDelimiters ' /\'

    # Add Unix shell key bindings.
    Set-PSReadLineKeyHandler -Chord Alt+b -Function ShellBackwardWord
    Set-PSReadLineKeyHandler -Chord Alt+d -Function DeleteWord
    Set-PSReadLineKeyHandler -Chord Alt+Z -Function Redo
    Set-PSReadLineKeyHandler -Chord Alt+z -Function Undo
    Set-PSReadLineKeyHandler -Chord Ctrl+a -Function BeginningOfLine
    Set-PSReadLineKeyHandler -Chord Ctrl+d -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Chord Shift+LeftArrow -Function ShellBackwardWord

    # Set alt+f or shift+rightarrow to jump to end of next suggestion if at the
    # end of the line else to the end of the next word.
    Set-PSReadLineKeyHandler -Chord Alt+f -ScriptBlock {
        param($Key, $Arg)

        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)

        if ($Cursor -lt $Line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::ShellNextWord($Key, $Arg)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($Key, $Arg)
        }
    }
    Set-PSReadLineKeyHandler -Chord Shift+RightArrow -ScriptBlock {
        param($Key, $Arg)

        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)

        if ($Cursor -lt $Line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::ShellNextWord($Key, $Arg)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($Key, $Arg)
        }
    }
    # Set Ctrl+eto jump to end of line suggestion if at the end of the line else
    # to the end of the line.
    Set-PSReadLineKeyHandler -Chord Ctrl+e -ScriptBlock {
        param($Key, $Arg)

        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)

        if ($Cursor -lt $Line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine($Key, $Arg)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion($Key, $Arg)
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
        if ($StripLine.Length -lt $Line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($StripLine)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$Line$WorkingDir")
        }
    }
    Set-PSReadLineKeyHandler -Chord Alt+e ViEditVisually
    Set-PSReadLineKeyHandler -Chord Alt+p -ScriptBlock {
        if ($Env:PAGER) {
            $Pager = $Env:PAGER
        }
        else {
            $PAGER = 'less'
        }

        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

        $StripLine = $Line -replace " 2>&1 `\| $Pager`$", ''
        if ($StripLine.Length -lt $Line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($StripLine)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$Line 2>&1 | $Pager")
        }
    }
    Set-PSReadLineKeyHandler -Chord Alt+s -ScriptBlock {
        $Line = $Null
        $Cursor = $Null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([Ref]$Line, [Ref]$Cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

        $StripLine = $Line -replace '^sudo ', ''
        if ($StripLine.Length -lt $Line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($StripLine)
        }
        else {
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

    # Add history based completions to arrow keys.
    Set-PSReadLineKeyHandler -Chord DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Chord Ctrl+n -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord Ctrl+p -Function HistorySearchBackward
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd

    # Features are only available for PowerShell 7.0 and later.
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        # Disable command not found suggestions.
        Set-PSReadLineOption -CommandValidationHandler $Null
        # Show history based completions for every typed character.
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin

        # Add Unix shell key bindings.
        Set-PSReadLineKeyHandler -Chord "`u{e000}" -Function ForwardChar
        Set-PSReadLineKeyHandler -Chord "`u{e004}" -Function MenuComplete
        Set-PSReadLineKeyHandler -Chord "`u{e005}" -Function BackwardChar

        # Set solarized light theme variables based on
        # https://ethanschoonover.com/solarized/#the-values.
        # $Private:Base03 = '#002b36'
        # $Private:Base02 = '#073642'
        $Private:Base01 = '#586e75'
        $Private:Base00 = '#657b83'
        $Private:Base0 = '#839496'
        $Private:Base1 = '#93a1a1'
        # $Private:Base2 = '#eee8d5'
        # $Private:Base3 = '#fdf6e3'
        # $Private:Yellow = '#b58900'
        # $Private:Orange = '#cb4b16'
        $Private:Red = '#dc322f'
        # $Private:Magenta = '#d33682'
        # $Private:Violet = '#6c71c4'
        $Private:Blue = '#268bd2'
        $Private:Cyan = '#2aa198'
        $Private:Green = '#859900'
        $Private:Inverse = "`e[7m"

        # Set PowerShell color theme as documented at
        # https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlineoption?view=powershell-7.5#-colors.
        Set-PSReadLineOption -Colors @{
            Command                = $Private:Cyan
            Comment                = $Private:Base1
            ContinuationPrompt     = $Private:Base00
            Default                = $Private:Base00
            Emphasis               = $Private:Cyan
            Error                  = $Private:Red
            InlinePrediction       = $Private:Base1
            Keyword                = $Private:Green
            ListPrediction         = $Private:Green
            ListPredictionSelected = $Private:Green
            Member                 = $Private:Base01
            Number                 = $Private:Base01
            Operator               = $Private:Base1
            Parameter              = $Private:Base1
            Selection              = $Private:Inverse
            String                 = $Private:Blue
            Type                   = $Private:Base0
            Variable               = $Private:Green
        }
    }
}

# Starship settings.

# Disable Starship warnings about command timeouts.
$Env:STARSHIP_LOG = 'error'

# Initialize Starship if interactive and available.
if ($Tty) {
    if (Get-Command -ErrorAction SilentlyContinue starship) {
        Invoke-Expression (&starship init powershell)
    }
    else {
        # Warning: PowerShell 5 does not support writing unicode characters.
        function Prompt {
            "`r`n$Env:USER at $Env:COMPUTERNAME in $(Get-Location)`r`n> "
        }
    }
}

# Typescript settings.

# Disable Deno update messages.
$Env:DENO_NO_UPDATE_CHECK = 'true'

# Yazi settings.

# Yazi wrapper to change directory on program exit.
function yz() {
    $Tmp = [System.IO.Path]::GetTempFileName()
    yazi --cwd-file $Tmp $Args
    $Cwd = Get-Content -Path $Tmp
    if (($Cwd) -and ($Cwd -ne $PWD.Path)) {
        Set-Location $Cwd
    }
    Remove-Item $Tmp
}

# Zoxide settings.

# Initialize Zoxide if interactive and available.
if ($Tty -and (Get-Command -ErrorAction SilentlyContinue zoxide)) {
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
}

# Remove private convenience variables.

Remove-Variable -Name Tty

# User settings.

# Load user aliases, secrets, and variables.
if (Test-Path "$HOME\.env.ps1") {
    . "$HOME\.env.ps1"
}
if (Test-Path "$HOME\.secrets.ps1") {
    . "$HOME\.secrets.ps1"
}
