Param(
    [string]
    $VersionPrefix = "0.9.20",
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
if ($VersionSuffix -eq "stable"){
    $PackageVersion = "$VersionPrefix"
    $ZipVersion = "$VersionPrefix"
}

Write-Host "Cleanup" -ForegroundColor Magenta
Remove-Item ./bin/* -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

Write-Host "Building Csg.Build.Metadata..." -ForegroundColor Magenta
Push-Location ./src/Csg.Build.Metadata
& dotnet restore
#& dotnet build --configuration Release /p:BuildNumber=$BuildNumber /p:ProjVersionSuffix=$VersionSuffix /p:ProjVersionPrefix=$VersionPrefix /p:IsFinalBuild=$IsFinalBuild
& dotnet pack --configuration Release --output ../../bin /p:BuildNumber=$BuildNumber /p:RepoVersionSuffix=$VersionSuffix /p:RepoVersionPrefix=$VersionPrefix
Pop-Location

Write-Host "Building Csg.Build.Metadata.Tasks NuGet package..." -ForegroundColor Magenta
Push-Location ./src/Csg.Build.Metadata.Tasks
& '../../build/nuget.exe' pack -OutputDirectory ../../bin/ -Properties "PackageVersion=$PackageVersion"
Pop-Location

Write-Host "Creating BuildTools ZIP" -ForegroundColor Magenta
$PackageVersion | Out-File .\src\Tools\VersionInfo.txt

$ZipPath = ".\bin\BuildTools-$ZipVersion.zip"
Compress-Archive -Force -Path .\src\Tools\* -DestinationPath $ZipPath

$VersionParts = $VersionPrefix.Split(".")
$LatestMajorVersion = "$($VersionParts[0])-$VersionSuffix"
$LatestMinorVersion = "$($VersionParts[0]).$($VersionParts[1])-$VersionSuffix"
$LatestBuildVersion = "$VersionPrefix-$VersionSuffix"
Copy-Item -Path $ZipPath -Destination ".\bin\BuildTools-$LatestMajorVersion.zip"
Copy-Item -Path $ZipPath -Destination ".\bin\BuildTools-$LatestMinorVersion.zip"
if ($VersionSuffix -eq "stable"){
    Copy-Item -Path $ZipPath -Destination ".\bin\BuildTools-$LatestBuildVersion.zip"
}

Write-Host "All good!" -ForegroundColor Green
