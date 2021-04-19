BeforeAll {
    $Bootware = "$PSScriptRoot/../../bootware.ps1"
    . "$Bootware"
}

Describe "Main" {
    It "Throw error for unkown subcommand" {
        { & "$Bootware" notasubcommand } | Should -Throw "Error: No such subcommand 'notasubcommand'."
    }
}

Describe "FindConfigPath" {
    It "Return given executable files" {
        $Expected="/bin/bash"
        FindConfigPath "$Expected"
        $Global:RetVal | Should -Be $Expected
    }

    It "Return environment variable" {
        $expected="/usr/bin/cat"
        $Env:BOOTWARE_CONFIG = "$Expected"; FindConfigPath
        $Global:RetVal | Should -Be $Expected
    }

    It "Return default when given non-existent file" {
        $Expected="$HOME/.bootware/config.yaml"
        $Env:BOOTWARE_CONFIG = "/a/fake/nonsense/path";  FindConfigPath
        $Global:RetVal | Should -Be $Expected
    }
}
