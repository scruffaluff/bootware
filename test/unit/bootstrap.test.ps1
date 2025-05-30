BeforeAll {
    $Bootware = "$PSScriptRoot/../../src/bootware.ps1"
    . $Bootware

    Mock FindConfigPath { 'C:\Users\Administrator\.bootware\config.yaml' }
    Mock FindRelativeIP { '192.48.16.0' }
    Mock Setup { }

    # Flatten array logic taken from https://stackoverflow.com/a/712205.
    if (Get-Command -ErrorAction SilentlyContinue wsl) {
        Mock wsl { "wsl $($Args | ForEach-Object {$_})" }
    }
    else {
        function wsl() {
            "wsl $($Args | ForEach-Object {$_})"
        }
    }
}

Describe 'Bootstrap' {
    It 'Subcommand finds first task associated with role' {
        $Env:BOOTWARE_NOLOG = 'true'
        $Playbook = "$(Get-Location)\playbook.yaml"
        $Expected = 'wsl bootware bootstrap --no-passwd --config ' `
            + '/mnt/c/Users/Administrator/.bootware/config.yaml --inventory ' `
            + "192.48.16.0 --playbook $(WSLPath $Playbook) " `
            + "--private-key `$HOME/.ssh/bootware --skip none " `
            + "--ssh-extra-args '-o StrictHostKeyChecking=no' " `
            + "--tags desktop --user $Env:UserName " `
            + '--extra-vars connect_role_executed=false ' `
            + '--start-at-task Install Deno JavaScript and TypeScript runtime'

        $Actual = & $Bootware bootstrap --start-at-role deno --playbook $Playbook
        $Actual | Should -Be $Expected
    }

    It 'Subcommand passes default arguments to WSL copy of Bootware' {
        $Env:BOOTWARE_NOLOG = 'true'
        $Expected = 'wsl bootware bootstrap --no-passwd --config ' `
            + '/mnt/c/Users/Administrator/.bootware/config.yaml --inventory ' `
            + '192.48.16.0 --playbook /mnt/c/Fake/path/repo/playbook.yaml ' `
            + "--private-key `$HOME/.ssh/bootware --skip none " `
            + "--ssh-extra-args '-o StrictHostKeyChecking=no' --tags desktop " `
            + "--user $Env:UserName"

        $Actual = & $Bootware bootstrap --playbook C:/Fake\path/repo/playbook.yaml
        $Actual | Should -Be $Expected
    }

    It 'Subcommand passes debug argument to WSL copy of Bootware' {
        $Env:BOOTWARE_NOLOG = 'true'
        $Expected = 'wsl bootware bootstrap --no-passwd --config ' `
            + '/mnt/c/Users/Administrator/.bootware/config.yaml --inventory ' `
            + '192.48.16.0 --playbook /mnt/c/Fake/path/repo/playbook.yaml ' `
            + "--private-key `$HOME/.ssh/bootware --skip python " `
            + "--ssh-extra-args '-o StrictHostKeyChecking=no' " `
            + "--tags fd --user $Env:UserName --debug"

        $Actual = & $Bootware bootstrap --debug --playbook `
            C:/Fake\path/repo/playbook.yaml --skip python --tags fd
        $Actual | Should -Be $Expected
    }

    It 'Subcommand passes list arguments to WSL copy of Bootware' {
        $Env:BOOTWARE_NOLOG = 'true'
        $Expected = 'wsl bootware bootstrap --no-passwd --config ' `
            + '/mnt/c/Users/Administrator/.bootware/config.yaml --inventory ' `
            + '192.48.16.0 --playbook /mnt/c/Fake/path/repo/playbook.yaml ' `
            + "--private-key `$HOME/.ssh/bootware --skip rust " `
            + "--ssh-extra-args '-o StrictHostKeyChecking=no' " `
            + "--tags fd --user $Env:UserName"

        $Actual = & $Bootware bootstrap --playbook `
            C:/Fake\path/repo/playbook.yaml --skip rust --tags fd
        $Actual | Should -Be $Expected
    }

    It 'Subcommand passes extra arguments to WSL copy of Bootware' {
        $Env:BOOTWARE_NOLOG = 'true'
        $Expected = 'wsl bootware bootstrap --no-passwd --config ' `
            + '/mnt/c/Users/Administrator/.bootware/config.yaml --inventory ' `
            + '192.48.16.0 --playbook /mnt/c/Fake/path/repo/playbook.yaml ' `
            + "--private-key `$HOME/.ssh/bootware --skip python " `
            + "--ssh-extra-args '-o StrictHostKeyChecking=no' " `
            + "--tags lsd --user $Env:UserName --timeout 60"

        $Actual = & $Bootware bootstrap --playbook `
            C:/Fake\path/repo/playbook.yaml --skip python --timeout 60 `
            --tags lsd
        $Actual | Should -Be $Expected
    }
}
