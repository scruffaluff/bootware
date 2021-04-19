BeforeAll {
    $Bootware = "$PSScriptRoot/../../bootware.ps1"
    . "$Bootware"
}

Describe "Main" {
    It "Throw error for unkown subcommand" {
        { & "$Bootware" notasubcommand } | Should -Throw "Error: No such subcommand 'notasubcommand'"
    }
}

Describe "FindConfigPath" {
    It "Return given executable files" {
        Mock Test-Path { Write-Output 1 }

        $Expected="C:\Windows\regedit.exe"
        FindConfigPath "$Expected"
        $Global:RetVal | Should -Be $Expected
    }

    It "Return environment variable" {
        Mock Test-Path { Write-Output 1 }

        $expected="C:\Windows\regedit.exe"
        $Env:BOOTWARE_CONFIG = "$Expected"; FindConfigPath
        $Global:RetVal | Should -Be $Expected
    }

    It "Return default when given non-existent file" {
        $Expected="$HOME/.bootware/config.yaml"
        $Env:BOOTWARE_CONFIG = "/a/fake/nonsense/path";  FindConfigPath
        $Global:RetVal | Should -Be $Expected
    }
}
