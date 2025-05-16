[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseConsistentWhitespace',
    '',
    Justification = 'Space after comma is incorrect for Bootware parameters.'
)]
param()

BeforeAll {
    $Bootware = "$PSScriptRoot/../../src/bootware.ps1"
    . $Bootware
}

Describe 'Roles' {
    It 'Subcommand applies multiple tags' {
        $Env:BOOTWARE_NOLOG = ''
        $Actual = & $Bootware roles --skip alacritty,language --tags `
            server,terminal
        $Actual | Should -Contain 'build'
        $Actual | Should -Contain 'wezterm'
        $Actual | Should -Not -Contain 'alacritty'
        $Actual | Should -Not -Contain 'deno'
    }

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
