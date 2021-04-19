BeforeAll {
    # Path normalization required for Assert-MockCalled parameter filters.
    $Install = [System.IO.Path]::GetFullPath("$PSScriptRoot/../../install.ps1")
    . "$Install"

    Mock DownloadFile { }
    Mock New-Item { }
    Mock Test-Path { Write-Output 1 }
}

Describe "Install" {
    It "Throw error for nonexistant option at end of call" {
        { & "$Install" -v develop notanoption } | Should -Throw "Error: No such option 'notanoption'"
    }

    It "Pass local path to DownloadFile" {
        $Env:BOOTWARE_NOLOG=1

        & "$Install" --user --version develop
        Assert-MockCalled DownloadFile -Times 1 -ParameterFilter {
            $DstFile -eq "$Env:AppData/Bootware/bootware.ps1" -And
            $SrcURL -eq "https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/develop/bootware.ps1"
        }
    }
}
