BeforeAll {
    # Path normalization required for Assert-MockCalled parameter filters.
    $Install = [System.IO.Path]::GetFullPath("$PSScriptRoot/../../src/install.ps1")
    . $Install

    Mock CheckEnvironment { }
    Mock Invoke-WebRequest { }
    Mock New-Item { }
    Mock Test-Path { Write-Output 1 }
}

Describe 'Install' {
    It 'Write error for nonexistant option at end of call' {
        $Actual = & $Install -v develop notanoption
        $Actual | Should -Be @(
            "error: No such option 'notanoption'",
            "Run 'install --help' for usage"
        )
    }

    It 'Pass local path to Invoke-WebRequest' {
        If (Get-Command -ErrorAction SilentlyContinue bootware) {
            Mock bootware { Write-Output '' }
        }
        Else {
            Function bootware() { Write-Output '' }
        }

        $Env:BOOTWARE_NOLOG = 1

        & $Install --user --version develop
        Assert-MockCalled Invoke-WebRequest -Times 1 -ParameterFilter {
            $OutFile -Eq "$Env:AppData/Bootware/bootware.ps1" -And
            $Uri -Eq 'https://raw.githubusercontent.com/scruffaluff/bootware/develop/src/bootware.ps1'
        }
    }
}
