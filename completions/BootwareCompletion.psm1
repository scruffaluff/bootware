# PowerShell module to enable Bootware command line completion.
#
# For more information on PowerShell command line completion, visit
# https://docs.microsoft.com/powershell/module/microsoft.powershell.core/register-argumentcompleter.

using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Register-ArgumentCompleter -CommandName 'bootware' -ScriptBlock {
    Param($WordToComplete)

    $Completions = @(
        [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information'),
        [CompletionResult]::new('--version', '--version', [CompletionResultType]::ParameterName, 'Print version information'),
        [CompletionResult]::new('bootstrap', 'bootstrap', [CompletionResultType]::ParameterValue, 'Boostrap install computer software'),
        [CompletionResult]::new('config', 'config', [CompletionResultType]::ParameterValue, 'Generate Bootware configuration file'),
        [CompletionResult]::new('setup', 'setup', [CompletionResultType]::ParameterValue, 'Install dependencies for Bootware'),
        [CompletionResult]::new('uninstall', 'uninstall', [CompletionResultType]::ParameterValue, 'Remove Bootware files'),
        [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Update Bootware to latest version')
    )
    $Completions | Where-Object { $_.CompletionText -Like "$WordToComplete*" }
}
