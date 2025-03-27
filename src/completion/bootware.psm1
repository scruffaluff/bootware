# PowerShell module to enable Bootware command line completion.
#
# For more information on PowerShell command line completion, visit
# https://docs.microsoft.com/powershell/module/microsoft.powershell.core/register-argumentcompleter.

using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Register-ArgumentCompleter -CommandName 'bootware' -ScriptBlock {
    param($WordToComplete, $CommandAst)

    $CommandElements = $CommandAst.CommandElements
    $Command = @(
        'bootware'
        for ($Index = 1; $Index -lt $CommandElements.Count; $Index++) {
            $Element = $CommandElements[$Index]
            if ($Element -isnot [StringConstantExpressionAst] -or
                $Element.StringConstantType -ne [StringConstantType]::BareWord -or
                $Element.Value.StartsWith('-') -or
                $Element.Value -eq $WordToComplete) {
                break
            }
            $Element.Value
        }
    ) -join ';'

    $Completions = @(
        switch ($Command) {
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
                break
            }
            'bootware;bootstrap' {
                [CompletionResult]::new('--check', '--check', [CompletionResultType]::ParameterName, 'Perform dry run and show possible changes')
                [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to bootware user configuration file')
                [CompletionResult]::new('--debug', '--debug', [CompletionResultType]::ParameterName, 'Enable Ansible task debugger')
                [CompletionResult]::new('--dev', '--dev', [CompletionResultType]::ParameterName, 'Run bootstrapping in development mode')
                [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information')
                [CompletionResult]::new('--install-group', '--install-group', [CompletionResultType]::ParameterName, 'Remote group to install software for')
                [CompletionResult]::new('--install-user', '--install-user', [CompletionResultType]::ParameterName, 'Remote user to install software for')
                [CompletionResult]::new('--inventory', '--inventory', [CompletionResultType]::ParameterName, 'Ansible remote hosts IP addesses')
                [CompletionResult]::new('--no-passwd', '--no-passwd', [CompletionResultType]::ParameterName, 'Do not ask for user password')
                [CompletionResult]::new('--no-setup', '--no-setup', [CompletionResultType]::ParameterName, 'Skip Bootware dependency installation')
                [CompletionResult]::new('--password', '--password', [CompletionResultType]::ParameterName, 'Remote user login password')
                [CompletionResult]::new('--playbook', '--playbook', [CompletionResultType]::ParameterName, 'Path to playbook to execute')
                [CompletionResult]::new('--private-key', '--private-key', [CompletionResultType]::ParameterName, 'Path to SSH private key')
                [CompletionResult]::new('--retries', '--retries', [CompletionResultType]::ParameterName, 'Playbook retry limit during failure')
                [CompletionResult]::new('--skip', '--skip', [CompletionResultType]::ParameterName, 'Ansible playbook tags to skip in quotes')
                [CompletionResult]::new('--start-at-role', '--start-at-role', [CompletionResultType]::ParameterName, 'Begin execution with role')
                [CompletionResult]::new('--tags', '--tags', [CompletionResultType]::ParameterName, 'Ansible playbook tags to select in quotes')
                [CompletionResult]::new('--temp-key', '--temp-key', [CompletionResultType]::ParameterName, 'Path to SSH private key for one time connection')
                [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'URL of playbook repository')
                [CompletionResult]::new('--user', '--user', [CompletionResultType]::ParameterName, 'Remote user login name')
                break
            }
            'bootware;config' {
                [CompletionResult]::new('--dest', '--dest', [CompletionResultType]::ParameterName, 'Path to alternate download destination')
                [CompletionResult]::new('--empty', '--empty', [CompletionResultType]::ParameterName, 'Write empty configuration file')
                [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information')
                [CompletionResult]::new('--source', '--source', [CompletionResultType]::ParameterName, 'URL to configuration file')
                break
            }
            'bootware;roles' {
                [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information')
                [CompletionResult]::new('--tags', '--tags', [CompletionResultType]::ParameterName, 'Ansible playbook tags to select in quotes')
                break
            }
            'bootware;setup' {
                [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information')
                [CompletionResult]::new('--checkout', '--checkout', [CompletionResultType]::ParameterName, 'Git reference to run against')
                [CompletionResult]::new('--no-wsl', '--no-wsl', [CompletionResultType]::ParameterName, 'Do not configure WSL')
                [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'URL of playbook repository')
                break
            }
            'bootware;uninstall' {
                [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information')
                break
            }
            'bootware;update' {
                [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help information')
                [CompletionResult]::new('--version', '--version', [CompletionResultType]::ParameterName, 'Version override for update')
                break
            }
        }
    )

    $Completions | Where-Object { $_.CompletionText -like "$WordToComplete*" }
}
