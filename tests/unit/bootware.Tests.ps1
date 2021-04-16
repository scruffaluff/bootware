BeforeAll { 
    $Bootware = "$PSScriptRoot/../../bootware.ps1"
}

Describe "Bootstrap" {
    It "Throw error if setup subcommand has not be executed" {
        { & "$Bootware" bootstrap } | Should -Throw "Error: The setup subcommand needs to be run before bootstrap"
    }
}
