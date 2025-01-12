BeforeAll {
    $Bootware = "$PSScriptRoot/../../bootware.ps1"
    . $Bootware

    Mock DownloadFile { }
}

Describe 'Config' {
    It 'Subcommand makes empty configuration log' {
        $Env:BOOTWARE_NOLOG = ''
        $Expected = 'Writing empty configuration file to /dev/null'

        $Actual = & $Bootware config -e --dest /dev/null
        $Actual | Should -Be $Expected
    }

    It 'Subcommand parses no parameters correctly' {
        $Env:BOOTWARE_NOLOG = 1

        & $Bootware config --source 'https://example.com/config.yaml'
        Assert-MockCalled DownloadFile -Times 1 -ParameterFilter {
            $DstFile -Eq "$HOME/.bootware/config.yaml" -And
            $SrcURL -Eq 'https://example.com/config.yaml'
        }
    }

    It 'Subcommand passes source to DownloadFile' {
        $Env:BOOTWARE_NOLOG = 1

        & $Bootware config --source https://fakedomain.com
        Assert-MockCalled DownloadFile -Times 1 -ParameterFilter {
            $DstFile -Eq "$HOME/.bootware/config.yaml" -And
            $SrcURL -Eq 'https://fakedomain.com'
        }
    }
}
