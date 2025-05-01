BeforeAll {
    $Bootware = "$PSScriptRoot/../../src/bootware.ps1"
    . $Bootware
}

Describe 'Main' {
    It 'Write error for unknown subcommand' {
        $Env:BOOTWARE_NOLOG = ''
        $Actual = & $Bootware notasubcommand
        $Actual | Should -Be @(
            "error: No such subcommand or option 'notasubcommand'.",
            "Run 'bootware --help' for usage."
        )
    }
}

Describe 'FindConfigPath' {
    It 'Return given executable files' {
        Mock Test-Path { 1 }

        $Expected = 'C:\Windows\regedit.exe'
        $Actual = FindConfigPath $Expected
        $Actual | Should -Be $Expected
    }

    It 'Return environment variable' {
        Mock Test-Path { 1 }

        $Expected = 'C:\Windows\regedit.exe'
        $Env:BOOTWARE_CONFIG = $Expected
        $Actual = FindConfigPath
        $Actual | Should -Be $Expected
    }

    It 'Throw error when given non-existent file' {
        Mock Test-Path { 0 }
        $Env:BOOTWARE_CONFIG = '/a/fake/nonsense/path'
        { FindConfigPath } |
            Should -Throw 'Unable to find Bootware configuration file'
    }
}

Describe 'WSLPath' {
    It 'Map C Drive correctly' {
        $Expected = '/mnt/c/Program Files/regedit.exe'
        $Actual = WSLPath 'C:\Program Files\regedit.exe'
        $Actual | Should -Be $Expected
    }

    It 'Map HK Drive correctly' {
        $Expected = '/mnt/hk/ProgramData/Bootware/config.yaml'
        $Actual = WSLPath 'HK:\ProgramData/Bootware\config.yaml'
        $Actual | Should -Be $Expected
    }
}
