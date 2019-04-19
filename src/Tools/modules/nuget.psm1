Import-Module "$PSScriptRoot/common.psm1"
Import-Module "$PSScriptRoot/msbuild.psm1"

function Find-NuGet {
    $testpaths= @(
        ".\.nuget\nuget.exe",
		".\nuget\nuget.exe",
        ".\apps\.nuget\nuget.exe",
        ".\build\nuget.exe",
        "$env:LOCALAPPDATA\NuGet\NuGet.exe"
    )
    
    return Find-FirstExistingPath -Paths $testpaths
}

function Start-NuGetRestore(
    [string]$Project, 
    [string]$Configuration, 
    [string]$NugetExe = ""
) {
    if (!$NugetExe){
        $NugetExe = Find-NuGet
    }

    if ($NugetExe){
        Invoke-Expression "& '$nugetexe' restore '$Project'" | Write-Host
        
		if ($LASTEXITCODE -ne 0){
			throw "The NuGet restore task failed with code: $LASTEXITCODE"
		}		
    } else {
        Write-Host "NuGet.exe not found. Attempting to use msbuild /t:restore"
		
        Start-MSBuild -Project $Project -Configuration $Configuration -Target "Restore"
		
		if ($LASTEXITCODE -ne 0){
			throw "The NuGet restore task via MSBuild failed with code: $LASTEXITCODE"
		}
    }
}