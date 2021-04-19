BeforeAll {
    $Bootware = "$PSScriptRoot/../../bootware.ps1"
    . "$Bootware"

    Mock FindRelativeIP { Write-Output "192.48.16.0" }
    Mock Setup { }

    If (Get-Command wsl -ErrorAction SilentlyContinue) {
        Mock wsl { Write-Output "wsl $Args" }
    } Else {
        Function wsl() {
            Write-Output "wsl $Args"
        }
    }
}

Describe "Bootstrap" {
    It "Subcommand passes arguments to WSL copy of Bootware" {
        $Env:BOOTWARE_NOLOG = 1
        $Expected = "wsl bootware bootstrap --winrm --inventory 192.48.16.0 --playbook /mnt/c/Fake/path/repo/main.yaml --tags desktop --skip none ---user $Env:UserName"

        $Actual = "$(& "$Bootware" bootstrap --playbook C:/Fake\path/repo/main.yaml)"
        $Actual | Should -Be $Expected
    }
}
