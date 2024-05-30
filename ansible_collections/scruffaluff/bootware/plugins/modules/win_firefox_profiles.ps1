#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

# Exit immediately if a PowerShell Cmdlet encounters an error.
$ErrorActionPreference = 'Stop'

# Taken from https://stackoverflow.com/a/422529.
Function ReadIni($File) {
    $Data = @{}
    $Section = 'NO_SECTION'
    $Data[$Section] = @{}

    Switch -Regex -File $File {
        '^\[(.+)\]$' {
            $Section = $Matches[1].Trim()
            $Data[$Section] = @{}
        }
        '^\s*([^#].+?)\s*=\s*(.*)' {
            $Name, $Value = $Matches[1..2]

            # Skip comments that start with semicolon.
            If (-Not ($Name.StartsWith(';'))) {
                $Data[$Section][$Name] = $Value.Trim()
            }
        }
    }

    Return $Data
}

# Script entrypoint.
Function DefaultProfile($Module) {
    If (Test-Path "$HOME\scoop\persist\firefox\profile") {
        $Paths = @("$HOME\scoop\persist\firefox\profile")
    }
    Else {
        $Paths = @()
    }
    $ProfilesPath = "$Env:APPDATA\Mozilla\Firefox\profiles.ini"

    $Parser = ReadIni $ProfilesPath
    ForEach ($Section In $Parser.Keys) {
        $Keys = $Parser[$Section].Keys
        If (($Section -Like 'Profile*') -And ($Keys -Contains 'Path')) {
            $Paths += $Parser[$Section]['Path']
        }
        Elseif (($Keys -Contains 'Locked') -And ($Keys -Contains 'Default')) {
            $Paths += $Parser[$Section]['Default']
        }
    }

    $Module.Result.paths = @()
    ForEach ($Path in $($Paths | Sort-Object -Unique)) {
        If ([System.IO.Path]::IsPathRooted($Path)) {
            $Module.Result.paths += $Path
        }
        Else {
            $Module.Result.paths += "$Env:APPDATA\Mozilla\Firefox\$Path"
        }
    }
    $Module.ExitJson()
    Return $Module
}

# Only run Main if invoked as script. Otherwise import functions as library.
If ($MyInvocation.InvocationName -NE '.') {
    # Variables Module and Spec need to be defined at the root of the script.
    $Spec = @{
        options             = @{}
        supports_check_mode = $true
    }

    $Module = [Ansible.Basic.AnsibleModule]::Create($Args, $Spec)
    $Module = DefaultProfile $Module
    Write-Output $Module
}
