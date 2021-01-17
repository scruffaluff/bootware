#Requires -Version 5

if (($PSVersionTable.PSVersion.Major) -lt 5) {
    Write-Output "PowerShell 5 or later is required to run Bootware."
    Write-Output "Upgrade PowerShell at https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell."
    break
}

# Check for correct execution policy.
$AllowedExecutionPolicy = @('Unrestricted', 'RemoteSigned', 'ByPass')
if ((Get-ExecutionPolicy).ToString() -NotIn $AllowedExecutionPolicy) {
    Write-Output "PowerShell requires an execution policy in [$($AllowedExecutionPolicy -Join ", ")] to run Bootware."
    Write-Output "For example, to set the execution policy to 'RemoteSigned' please run :"
    Write-Output "'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser'"
    break
}
