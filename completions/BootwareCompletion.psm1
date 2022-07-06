# PowerShell module to enable Bootware command line completion.
#
# For more information on PowerShell command line completion, visit
# https://docs.microsoft.com/powershell/module/microsoft.powershell.core/register-argumentcompleter.

Register-ArgumentCompleter -CommandName 'bootware' -ScriptBlock {
    Param($WordToComplete)

    $Completions = 'bootstrap', 'config', 'setup', 'uninstall', 'update'
    $Completions | Where-Object { $_ -Like "$WordToComplete*" }
}
