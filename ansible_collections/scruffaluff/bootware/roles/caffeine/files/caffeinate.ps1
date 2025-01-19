<#
.SYNOPSIS
    Prevent system from sleeping during a program.
#>

# Exit immediately if a PowerShell cmdlet encounters an error.
$ErrorActionPreference = 'Stop'
# Exit immediately when an native executable encounters an error.
$PSNativeCommandUseErrorActionPreference = $True

# Show CLI help information.
Function Usage() {
    Write-Output @'
Prevent system from sleeping during a program.

Usage: caffeinate [OPTIONS] [PROGRAM]

Options:
  -h, --help      Print help information
  -v, --version   Print version information
'@
}

# Print Caffeinate version string.
Function Version() {
    Write-Output 'Caffeinate 0.0.1'
}

# Script entrypoint.
Function Main() {
    $ArgIdx = 0
    $CmdArgs = @()

    While ($ArgIdx -LT $Args[0].Count) {
        Switch ($Args[0][$ArgIdx]) {
            { $_ -In '-h', '--help' } {
                Usage
                Exit 0
            }
            { $_ -In '-v', '--version' } {
                Version
                Exit 0
            }
            Default {
                $CmdArgs += $Args[0][$ArgIdx]
                $ArgIdx += 1
            }
        }
    }

    caffeine
    Try {
        If ($CmdArgs.Count -Eq 0) {
            While ($True) {
                Start-Sleep -Seconds 86400
            }
        }
        Else {
            & $CmdArgs
        }
    }
    Finally {
        caffeine --appexit
    }
}

# Only run Main if invoked as script. Otherwise import functions as library.
If ($MyInvocation.InvocationName -NE '.') {
    Main $Args
}
