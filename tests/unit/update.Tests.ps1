BeforeAll {
    # Path normalization required for Assert-MockCalled parameter filters.
    $Bootware = [System.IO.Path]::GetFullPath("$PSScriptRoot/../../bootware.ps1")
    . "$Bootware"

    Mock DownloadFile { }
    Mock git { Write-Output "git $Args" }
    Mock Test-Path { Write-Output 1 }

    # Avoid overwriting WSL copy of Bootware during tests if installed.
    If (Get-Command wsl -ErrorAction SilentlyContinue) {
        Mock wsl { }
    }
}

Describe "Update" {
    It "Throw error for nonexistant option at end of call" {
        { & "$Bootware" update -v develop notanoption } | Should -Throw "Error: No such option 'notanoption'"
    }

    It "Subcommand passes args to DownloadFile and Git" {
        $Env:BOOTWARE_NOLOG=1
        $Expected = "git -C $(Split-Path -Parent $Bootware)/repo pull"

        $Actual = "$(& "$Bootware" update --version develop)"
        Assert-MockCalled DownloadFile -Times 1 -ParameterFilter {
            $DstFile -eq "$Bootware" -And
            $SrcURL -eq "https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/develop/bootware.ps1"
        }

        $Actual | Should -Be $Expected
    }
}
