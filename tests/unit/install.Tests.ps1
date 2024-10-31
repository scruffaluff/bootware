BeforeAll {
    # Path normalization required for Assert-MockCalled parameter filters.
    $Install = [System.IO.Path]::GetFullPath("$PSScriptRoot/../../install.ps1")
    . $Install

    Mock CheckEnvironment { }
    Mock DownloadFile { }
    Mock New-Item { }
    Mock Test-Path { Write-Output 1 }
}

Describe 'Install' {
    It 'Throw error for nonexistant option at end of call' {
        { & $Install -v develop notanoption } |
            Should -Throw "Error: No such option 'notanoption'"
    }

    It 'Pass local path to DownloadFile' {
        If (Get-Command -ErrorAction SilentlyContinue bootware) {
            Mock bootware { Write-Output '' }
        }
        Else {
            Function bootware() { Write-Output '' }
        }

        $Env:BOOTWARE_NOLOG = 1

        & $Install --user --version develop
        Assert-MockCalled DownloadFile -Times 1 -ParameterFilter {
            $DstFile -Eq "$Env:AppData/Bootware/bootware.ps1" -And
            $SrcURL -Eq 'https://raw.githubusercontent.com/scruffaluff/bootware/develop/bootware.ps1'
        }
    }
}
