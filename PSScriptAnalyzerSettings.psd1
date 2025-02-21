# PowerShell ScriptAnalyzer configuration file.
#
# For more information, visit
# https://docs.microsoft.com/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer#settings-support-in-scriptanalyzer.

@{
    ExcludeRules = @(
        'PSAvoidGlobalVars',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPositionalParameters'
        'PSUseApprovedVerbs'
        'PSUseBOMForUnicodeEncodedFile'
    )
}
