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

# # GCloud settings.

# # Load GCloud autocompletion if available.
# If (Get-Module -ListAvailable -Name GcloudTabComplete) {
#     Import-Module GcloudTabComplete
# }

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

        $Line = $null
        $Cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line, [ref]$Cursor)

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

    # Features are only available for PowerShell 7.0 and later.
    If ($PSVersionTable.PSVersion.Major -GE 7) {
        # Show history based autocompletion for every typed character.
        Set-PSReadLineOption -PredictionSource History

        # Use solarized light blue for predictions.
        Set-PSReadLineOption -Colors @{ InlinePrediction = '#268bd2' }
    }

    # Disable sounds for errors.
    Set-PSReadLineOption -BellStyle None
}

# Python settings.

# Make Poetry create virutal environments inside projects.
$Env:POETRY_VIRTUALENVS_IN_PROJECT = 1

# Starship settings.

# Initialize Starship if available.
If (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# Tool settings.
Set-Alias -Name exa -Value Get-ChildItem
Set-Alias -Name touch -Value New-Item

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
