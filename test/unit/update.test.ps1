BeforeAll {
    # Path normalization required for Assert-MockCalled parameter filters.
    $Bootware = [System.IO.Path]::GetFullPath("$PSScriptRoot/../../src/bootware.ps1")
    . $Bootware

    Mock Invoke-WebRequest { }
    # Mocking Git appears to not work on Windows.
    function git { "git $Args" }
    Mock Test-Path { 1 }

    # Avoid overwriting WSL copy of Bootware during tests if installed.
    if (Get-Command -ErrorAction SilentlyContinue wsl) {
        Mock wsl { }
    }
}

Describe 'Update' {
    It 'Subcommand help prints message' {
        $Actual = & $Bootware update --help
        $Actual | Should -Match 'Update Bootware to latest version'
    }

    It 'Write error for nonexistant option at end of call' {
        $Env:BOOTWARE_NOLOG = ''
        $Actual = & $Bootware update -v develop notanoption
        $Actual | Should -Be @(
            "error: No such option 'notanoption'.",
            "Run 'bootware update --help' for usage."
        )
    }

    It 'Subcommand passes args to Invoke-WebRequest and Git' {
        if (Get-Command -ErrorAction SilentlyContinue bootware) {
            Mock bootware { '' }
        }
        else {
            function bootware() { '' }
        }

        $Env:BOOTWARE_NOLOG = 'true'
        $BootwareDir = Split-Path -Parent $Bootware
        $Expected = "git -C $BootwareDir\repo pull"

        $Actual = & $Bootware update --version main
        Assert-MockCalled Invoke-WebRequest -Scope It -Times 1 -ParameterFilter {
            $OutFile -eq "$BootwareDir\bootware.ps1" -and
            $Uri -eq 'https://raw.githubusercontent.com/scruffaluff/bootware/main/src/bootware.ps1'
        }

        $Actual | Should -Be $Expected
    }
}
