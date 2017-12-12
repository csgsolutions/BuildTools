Import-Module "$PSScriptRoot/common.psm1"

function Find-NuGet {
    $testpaths= @(
        ".\.nuget\nuget.exe",
        "$env:LOCALAPPDATA\NuGet\NuGet.exe"
    )
    
    return Find-FirstExistingPath -Paths $testpaths
}

function Start-NuGetRestore([string]$Project, [string]$Configuration) {
    $nugetexe = Find-NuGet

    if ($nugetexe){
        Write-Host "Using NuGet exe at $nugetexe"
        Invoke-Expression "& '$nugetexe' restore '$Project'" | Write-Debug
        if ($LASTEXITCODE -ne 0){
			throw "The NuGet task failed with code: $LASTEXITCODE"
		}		
    } else {
        Write-Host "NuGet.exe not found. Attempting to use msbuild /t:restore"
        return (Start-MsBuild -Project $Project -Configuration $Configuration -$Target "Restore")
    }
}