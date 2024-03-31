# PowerShell module to enable SSH autocompletion from SSH config file.
#
# Forked from
# https://gist.github.com/backerman/2c91d31d7a805460f93fe10bdfa0ffb0?permalink_comment_id=4131763#gistcomment-4131763.

# Find all hosts beginning with input.
Function CompleteHosts($Partial) {
    $SSHFolder = "$HOME/.ssh"
    $SSHConfig = "$SSHFolder/config"

    $Hosts = Get-Content -Path "$SSHConfig" |
        Select-String -Pattern '^Include ' |
        ForEach-Object { $_ -Replace 'Include ', '' }  |
        ForEach-Object { GetHosts "$SSHFolder/$_" }

    $Hosts += GetHosts "$SSHConfig"
    $HostMatches = $(
        $Hosts | Where-Object { $_ -Like "$Partial*" } | ForEach-Object { $_ }
    )

    Return $HostMatches
}

# Find all hosts from SSH config file.
Function GetHosts($ConfigPath) {
    $Text = $(Get-Content -Path $ConfigPath)
    $Lines = $($Text | Select-String -Pattern '^Host ')
    $Hosts = $($Lines | ForEach-Object { $_ -Replace 'Host ', '' } |
            ForEach-Object { $_ -Split ' ' } | Sort-Object -Unique
    )

    Return $Hosts | Select-String -Pattern '^.*[*!?].*$' -NotMatch
}

Register-ArgumentCompleter -Native -CommandName 'scp', 'sftp', 'ssh' -ScriptBlock {
    Param($WordToComplete)
    CompleteHosts $WordToComplete
}
