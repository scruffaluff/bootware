BeforeAll { 
    $Bootware = "$PSScriptRoot/../../bootware.ps1"
}

Describe "Main" {
    It "Throw error for unkown subcommand" {
        { & "$Bootware" notasubcommand } | Should -Throw "Error: No such subcommand 'notasubcommand'."
    }
}
