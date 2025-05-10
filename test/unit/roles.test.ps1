BeforeAll {
    $Bootware = "$PSScriptRoot/../../src/bootware.ps1"
    . $Bootware
}

Describe 'Roles' {
    It 'Subommand default hides never roles' {
        $Env:BOOTWARE_NOLOG = ''
        $Actual = & $Bootware roles
        $Actual | Should -Contain 'alacritty'
        $Actual | Should -Not -Contain 'podman'
    }

    It 'Subommand never shows hidden roles' {
        $Env:BOOTWARE_NOLOG = ''
        $Actual = & $Bootware roles --tags never
        $Actual | Should -Contain 'podman'
        $Actual | Should -Not -Contain 'bash'
    }

    It 'Subommand_skip_hides_desktop_roles' {
        $Env:BOOTWARE_NOLOG = ''
        $Actual = & $Bootware roles --skip bash --tags sysadmin
        $Actual | Should -Contain 'deno'
        $Actual | Should -Not -Contain 'bash'
    }

    It 'Subommand_tag_hides_desktop_roles' {
        $Env:BOOTWARE_NOLOG = ''
        $Actual = & $Bootware roles --tags container
        $Actual | Should -Contain 'podman'
        $Actual | Should -Not -Contain 'alacritty'
    }
}
