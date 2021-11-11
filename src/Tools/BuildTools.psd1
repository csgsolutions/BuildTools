@{
    GUID = '14456ABB-144C-49E9-B0A6-E16CFABC8E3B'
    RootModule = 'modules/buildtools.psm1'
    Author = 'CSG'
    CompanyName = 'CSG'
    Copyright = '2021 Cornerstone Solutions Group'
    ModuleVersion = '1.0'
    Description = 'Functions for using BuildTools'
    PowerShellVersion = '4.0'
    FunctionsToExport = @('Find-MSBuild', 'Start-MSBuild', 'Find-VSTest', 'Start-VSTest', 'Find-NuGet', 'Start-NuGetRestore')
    AliasesToExport = @('')
    VariablesToExport = @('')
}