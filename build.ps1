$Version = "0.9.14-beta"
$env:BUILD_VERSION = $Version

Write-Host "Building Csg.Build.Metadata..." -ForegroundColor Magenta
pushd ./src/Csg.Build.Metadata
& dotnet restore
& dotnet build --configuration Release 
& dotnet pack --configuration Release --output ../../bin
popd

Write-Host "Building Csg.Build.Metadata.Tasks NuGet package..." -ForegroundColor Magenta
pushd ./src/Csg.Build.Metadata.Tasks
& nuget pack -OutputDirectory ../../bin/ -Version "$Version"
popd

Write-Host "Creating BuildTools ZIP" -ForegroundColor Magenta
Compress-Archive -Force -Path .\src\Tools\* -DestinationPath ".\bin\BuildTools-$Version.zip"

Write-Host "All good!" -ForegroundColor Green