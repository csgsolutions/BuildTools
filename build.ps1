Param(
    [string]
    $VersionPrefix = "0.9.16",
    [string]
    $VersionSuffix = "beta",
    [string]
    $BuildNumber = "",
	[alias("c")][string]
	$Configuration = "Release",
    [string]
    $IsFinalBuild = "false",
    [switch]
    $NoTest
)

#$env:BuildNumber = 
$BuildNumber = $BuildNumber.PadLeft(5, "0")

# duplicate logic in version.props for zip and nuspec
$PackageVersion = "$VersionPrefix-$VersionSuffix-$BuildNumber"
$ZipVersion = "$VersionPrefix-$VersionSuffix"
if ($IsFinalBuild -eq "true" -and $VersionSuffix -eq "rtm"){
    $PackageVersion = "$VersionPrefix"
    $ZipVersion = "$VersionPrefix"
} elseif ($IsFinalBuild -eq "true") {
    $PackageVersion = "$VersionPrefix-$VersionSuffix-final"
}

Write-Host "Cleanup" -ForegroundColor Magenta
Remove-Item ./bin/* -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

Write-Host "Building Csg.Build.Metadata..." -ForegroundColor Magenta
Push-Location ./src/Csg.Build.Metadata
& dotnet restore
#& dotnet build --configuration Release /p:BuildNumber=$BuildNumber /p:ProjVersionSuffix=$VersionSuffix /p:ProjVersionPrefix=$VersionPrefix /p:IsFinalBuild=$IsFinalBuild
& dotnet pack --configuration Release --output ../../bin /p:BuildNumber=$BuildNumber /p:RepoVersionSuffix=$VersionSuffix /p:RepoVersionPrefix=$VersionPrefix /p:IsFinalBuild=$IsFinalBuild
Pop-Location

Write-Host "Building Csg.Build.Metadata.Tasks NuGet package..." -ForegroundColor Magenta
Push-Location ./src/Csg.Build.Metadata.Tasks
& '../../build/nuget.exe' pack -OutputDirectory ../../bin/ -Properties "PackageVersion=$PackageVersion"
Pop-Location

Write-Host "Creating BuildTools ZIP" -ForegroundColor Magenta
$PackageVersion | Out-File .\src\Tools\VersionInfo.txt
Compress-Archive -Force -Path .\src\Tools\* -DestinationPath ".\bin\BuildTools-$ZipVersion.zip"

Write-Host "All good!" -ForegroundColor Green