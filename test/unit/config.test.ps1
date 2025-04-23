BeforeAll {
    $Bootware = "$PSScriptRoot/../../src/bootware.ps1"
    . $Bootware

    Mock Invoke-WebRequest { }
}

Describe 'Config' {
    It 'Subcommand makes empty configuration log' {
        $Env:BOOTWARE_NOLOG = ''
        $Expected = "Writing empty configuration file to '/dev/null'."

        $Actual = & $Bootware config -e --dest /dev/null
        $Actual | Should -Be $Expected
    }

    It 'Subcommand parses no parameters correctly' {
        $Env:BOOTWARE_NOLOG = 'true'

        & $Bootware config --source 'https://example.com/config.yaml'
        Assert-MockCalled Invoke-WebRequest -Times 1 -ParameterFilter {
            $OutFile -eq "$HOME/.bootware/config.yaml" -and
            $Uri -eq 'https://example.com/config.yaml'
        }
    }

    It 'Subcommand passes source to Invoke-WebRequest' {
        $Env:BOOTWARE_NOLOG = 'true'

        & $Bootware config --source https://fakedomain.com
        Assert-MockCalled Invoke-WebRequest -Times 1 -ParameterFilter {
            $OutFile -eq "$HOME/.bootware/config.yaml" -and
            $Uri -eq 'https://fakedomain.com'
        }
    }
}
