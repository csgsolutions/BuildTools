$Version = "0.9.13-preview"
$env:BUILD_VERSION = $Version
Write-Host "Building Csg.Build.Metadata.Tasks NuGet package..." -ForegroundColor Magenta
pushd ./src/Csg.Build.Metadata.Tasks
& nuget pack -OutputDirectory ../../bin/ -Version "$Version"
popd

Write-Host "Building Csg.Reflection.BuildMetadata..." -ForegroundColor Magenta
pushd ./src/Csg.Reflection.BuildMetadata
& dotnet restore
& dotnet build --configuration Release 
& dotnet pack --configuration Release --output ../../bin
popd

Write-Host "Creating BuildTools ZIP" -ForegroundColor Magenta
Compress-Archive -Force -Path .\src\Tools\* -DestinationPath ".\bin\BuildTools-$Version.zip"

Write-Host "All good!" -ForegroundColor Green