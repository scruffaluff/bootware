BeforeAll {
    $Bootware = "$PSScriptRoot/../../bootware.ps1"
    . "$Bootware"

    Mock FindConfigPath {
        $Global:RetVal = "C:\Users\Administrator\.bootware\config.yaml"
    }
    Mock FindRelativeIP { Write-Output "192.48.16.0" }
    Mock Setup { }

    If (Get-Command wsl -ErrorAction SilentlyContinue) {
        Mock wsl { Write-Output "wsl $Args" }
    } 
    Else {
        Function wsl() {
            Write-Output "wsl $Args"
        }
    }
}

Describe "Bootstrap" {
    It "Subcommand passes default arguments to WSL copy of Bootware" {
        $Env:BOOTWARE_NOLOG = 1
        $Expected = "wsl bootware bootstrap --windows --config " `
            + "/mnt/c/Users/Administrator/.bootware/config.yaml --inventory " `
            + "192.48.16.0, --playbook /mnt/c/Fake/path/repo/main.yaml " `
            + "--skip none --ssh-key `$HOME/.ssh/bootware --tags desktop --user " `
            + "$Env:UserName"

        $Actual = "$(& "$Bootware" bootstrap  --playbook C:/Fake\path/repo/main.yaml)"
        $Actual | Should -Be $Expected
    }

    It "Subcommand passes debug argument to WSL copy of Bootware" {
        $Env:BOOTWARE_NOLOG = 1
        $Expected = "wsl bootware bootstrap --debug --windows --config " `
            + "/mnt/c/Users/Administrator/.bootware/config.yaml --inventory " `
            + "192.48.16.0, --playbook /mnt/c/Fake/path/repo/main.yaml " `
            + "--skip python,rust --ssh-key `$HOME/.ssh/bootware --tags fd,go " `
            + "--user $Env:UserName"

        $Actual = "$(& "$Bootware" bootstrap --debug --playbook `
            C:/Fake\path/repo/main.yaml --skip python,rust --tags fd,go)"
        $Actual | Should -Be $Expected
    }

    It "Subcommand passes list arguments to WSL copy of Bootware" {
        $Env:BOOTWARE_NOLOG = 1
        $Expected = "wsl bootware bootstrap --windows --config " `
            + "/mnt/c/Users/Administrator/.bootware/config.yaml --inventory " `
            + "192.48.16.0, --playbook /mnt/c/Fake/path/repo/main.yaml " `
            + "--skip python,rust --ssh-key `$HOME/.ssh/bootware --tags fd,go " `
            + "--user $Env:UserName"

        $Actual = "$(& "$Bootware" bootstrap  --playbook `
            C:/Fake\path/repo/main.yaml --skip python,rust --tags fd,go)"
        $Actual | Should -Be $Expected
    }
}
