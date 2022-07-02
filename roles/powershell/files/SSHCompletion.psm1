# PowerShell module to enable SSH autocompletion from SSH config file.
#
# Forked from
# https://gist.github.com/backerman/2c91d31d7a805460f93fe10bdfa0ffb0?permalink_comment_id=4131763#gistcomment-4131763.

# Find all hosts from SSH config file.
Function Get-SSHHost($ConfigPath) {
    Get-Content -Path $ConfigPath `
        | Select-String -Pattern '^Host ' `
        | ForEach-Object { $_ -Replace 'Host ', '' } `
        | ForEach-Object { $_ -Split ' ' } `
        | Sort-Object -Unique `
        | Select-String -Pattern '^.*[*!?].*$' -NotMatch
}

Register-ArgumentCompleter -CommandName 'ssh', 'scp', 'sftp' -Native -ScriptBlock {
    Param($WordToComplete, $CommandAST, $CursorPosition)

    $SSHFolder = "$HOME/.ssh"
    $SSHConfig = "$SSHFolder/config"

    $Hosts = Get-Content -Path "$SSHConfig" `
        | Select-String -Pattern '^Include ' `
        | ForEach-Object { $_ -Replace 'Include ', '' }  `
        | ForEach-Object { Get-SSHHost "$SSHFolder/$_" }

    $Hosts += Get-SSHHost "$SSHConfig"
    $Hosts = $Hosts | Sort-Object -Unique

    $Hosts | Where-Object { $_ -Like "$WordToComplete*" } `
        | ForEach-Object { $_ }
}
