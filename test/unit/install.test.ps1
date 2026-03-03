BeforeAll {
    # Path normalization required for Assert-MockCalled parameter filters.
    $Install = [System.IO.Path]::GetFullPath("$PSScriptRoot/../../src/install.ps1")
    . $Install

    Mock Invoke-WebRequest { }
    Mock Test-Path { 1 }
}

Describe 'Install' {
    It 'Write error for nonexistant option at end of call' {
        $Env:BOOTWARE_NOLOG = ''
        $Actual = & $Install --preserve-env -v develop notanoption
        $Actual | Should -Be @(
            "error: No such option 'notanoption'.",
            "Run 'install-bootware --help' for usage."
        )
    }

    It 'Pass local path to Invoke-WebRequest' {
        if (Get-Command -ErrorAction SilentlyContinue bootware) {
            Mock bootware { '' }
        }
        else {
            function bootware() { '' }
        }

        $Env:BOOTWARE_NOLOG = 'true'

        & $Install --preserve-env --version develop
        Assert-MockCalled Invoke-WebRequest -Scope It -Times 1 -ParameterFilter {
            $OutFile -eq "$Env:LocalAppData\Programs\Bootware\bootware.ps1" -and
            $Uri -eq 'https://raw.githubusercontent.com/scruffaluff/bootware/develop/src/bootware.ps1'
        }
    }
}
