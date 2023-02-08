# PowerShell module to enable Bootware command line completion.
#
# For more information on PowerShell command line completion, visit
# https://docs.microsoft.com/powershell/module/microsoft.powershell.core/register-argumentcompleter.

using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Register-ArgumentCompleter -CommandName 'bootware' -ScriptBlock {
    Param($WordToComplete, $CommandAst)

    $CommandElements = $CommandAst.CommandElements
    $Command = @(
        'bootware'
        For ($Index = 1; $Index -LT $CommandElements.Count; $Index++) {
            $Element = $CommandElements[$Index]
            If ($Element -IsNot [StringConstantExpressionAst] -Or
                $Element.StringConstantType -NE [StringConstantType]::BareWord -Or
                $Element.Value.StartsWith('-') -Or
                $Element.Value -EQ $WordToComplete) {
                Break
            }
            $Element.Value
        }
    ) -Join ';'

    $Completions = @(
        Switch ($Command) {
            'bootware' {
                [CompletionResult]::new('--debug', '--debug', [CompletionResultType]::ParameterName, 'Enable shell debug traces')
                [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information')
                [CompletionResult]::new('--version', '--version', [CompletionResultType]::ParameterName, 'Print version information')
                [CompletionResult]::new('bootstrap', 'bootstrap', [CompletionResultType]::ParameterValue, 'Boostrap install computer software')
                [CompletionResult]::new('config', 'config', [CompletionResultType]::ParameterValue, 'Generate Bootware configuration file')
                [CompletionResult]::new('roles', 'roles', [CompletionResultType]::ParameterValue, 'List all Bootware roles')
                [CompletionResult]::new('setup', 'setup', [CompletionResultType]::ParameterValue, 'Install dependencies for Bootware')
                [CompletionResult]::new('uninstall', 'uninstall', [CompletionResultType]::ParameterValue, 'Remove Bootware files')
                [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Update Bootware to latest version')
                Break
            }
            'bootware;bootstrap' {
                [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to bootware user configuation file')
                [CompletionResult]::new('--debug', '--debug', [CompletionResultType]::ParameterName, 'Enable Ansible task debugger')
                [CompletionResult]::new('--dev', '--dev', [CompletionResultType]::ParameterName, 'Run bootstrapping in development mode')
                [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information')
                [CompletionResult]::new('--no-passwd', '--no-passwd', [CompletionResultType]::ParameterName, 'Do not ask for user password')
                [CompletionResult]::new('--no-setup', '--no-setup', [CompletionResultType]::ParameterName, 'Skip Bootware dependency installation')
                [CompletionResult]::new('--playbook', '--playbook', [CompletionResultType]::ParameterName, 'Name of play to execute')
                [CompletionResult]::new('--password', '--password', [CompletionResultType]::ParameterName, 'Remote host user password')
                [CompletionResult]::new('--retries', '--retries', [CompletionResultType]::ParameterName, 'Playbook retry limit during failure')
                [CompletionResult]::new('--skip', '--skip', [CompletionResultType]::ParameterName, 'Ansible playbook tags to skip in quotes')
                [CompletionResult]::new('--start-at-role', '--start-at-role', [CompletionResultType]::ParameterName, 'Begin execution with role')
                [CompletionResult]::new('--tags', '--tags', [CompletionResultType]::ParameterName, 'Ansible playbook tags to select in quotes')
                [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'URL of playbook repository')
                [CompletionResult]::new('--user', '--user', [CompletionResultType]::ParameterName, 'Remote host user login name')
                Break
            }
            'bootware;config' {
                [CompletionResult]::new('--dest', '--dest', [CompletionResultType]::ParameterName, 'Path to alternate download destination')
                [CompletionResult]::new('--empty', '--empty', [CompletionResultType]::ParameterName, 'Write empty configuration file')
                [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information')
                [CompletionResult]::new('--source', '--source', [CompletionResultType]::ParameterName, 'URL to configuration file')
                Break
            }
            'bootware;roles' {
                [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information')
                Break
            }
            'bootware;setup' {
                [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information')
                [CompletionResult]::new('--checkout', '--checkout', [CompletionResultType]::ParameterName, 'Git reference to run against')
                [CompletionResult]::new('--no-wsl', '--no-wsl', [CompletionResultType]::ParameterName, 'Do not configure WSL')
                [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'URL of playbook repository')
                Break
            }
            'bootware;uninstall' {
                [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information')
                Break
            }
            'bootware;update' {
                [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information')
                [CompletionResult]::new('--version', '--version', [CompletionResultType]::ParameterName, 'Version override for update')
                Break
            }
        }
    )

    $Completions | Where-Object { $_.CompletionText -Like "$WordToComplete*" }
}
