#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

# Exit immediately if a PowerShell cmdlet encounters an error.
$ErrorActionPreference = 'Stop'
# Disable progress bar for PowerShell cmdlets.
$ProgressPreference = 'SilentlyContinue'
# Exit immediately when an native executable encounters an error.
$PSNativeCommandUseErrorActionPreference = $True

# Taken from https://stackoverflow.com/a/422529.
function ReadIni($File) {
    $Data = @{}
    $Section = 'NO_SECTION'
    $Data[$Section] = @{}

    switch -Regex -File $File {
        '^\[(.+)\]$' {
            $Section = $Matches[1].Trim()
            $Data[$Section] = @{}
        }
        '^\s*([^#].+?)\s*=\s*(.*)' {
            $Name, $Value = $Matches[1..2]

            # Skip comments that start with semicolon.
            if (-not ($Name.StartsWith(';'))) {
                $Data[$Section][$Name] = $Value.Trim()
            }
        }
    }

    return $Data
}

# Script entrypoint.
function DefaultProfile($Module) {
    $User = $Module.Params.user
    if ($User) {
        $UserHome = "C:\Users\$User"
    }
    else {
        $UserHome = "$HOME"
    }
    $AppData = "$UserHome\AppData\Roaming"

    if (Test-Path "$UserHome\scoop\persist\firefox\profile") {
        $Paths = @("$UserHome\scoop\persist\firefox\profile")
    }
    else {
        $Paths = @()
    }
    $ProfilesPath = "$AppData\Mozilla\Firefox\profiles.ini"

    $Parser = ReadIni $ProfilesPath
    foreach ($Section in $Parser.Keys) {
        $Keys = $Parser[$Section].Keys
        if (($Section -like 'Profile*') -and ($Keys -contains 'Path')) {
            $Paths += $Parser[$Section]['Path']
        }
        elseif (($Keys -contains 'Locked') -and ($Keys -contains 'Default')) {
            $Paths += $Parser[$Section]['Default']
        }
    }

    $Module.Result.paths = @()
    foreach ($Path in $($Paths | Sort-Object -Unique)) {
        if ([System.IO.Path]::IsPathRooted($Path)) {
            $Module.Result.paths += $Path
        }
        else {
            $Module.Result.paths += "$AppData\Mozilla\Firefox\$Path"
        }
    }
    $Module.ExitJson()
    return $Module
}

# Only run Main if invoked as script. Otherwise import functions as library.
if ($MyInvocation.InvocationName -ne '.') {
    # Variables Module and Spec need to be defined at the root of the script.
    $Spec = @{
        options             = @{
            user = @{ default = ''; required = $False; type = 'str' }
        }
        supports_check_mode = $true
    }

    $Module = [Ansible.Basic.AnsibleModule]::Create($Args, $Spec)
    $Module = DefaultProfile $Module
    Write-Output $Module
}
