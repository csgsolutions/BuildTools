$Version = "0.9.13-preview"

Write-Host "Building Csg.Buildmetadata NuGet package..." -ForegroundColor Magenta
pushd ./src/Csg.BuildMetadata
& nuget pack -OutputDirectory ../../bin/ -Version "$Version"
popd

Write-Host "Creating BuildTools ZIP" -ForegroundColor Magenta
Compress-Archive -Force -Path .\src\Tools\* -DestinationPath ".\bin\BuildTools-$Version.zip"

Write-Host "All good!" -ForegroundColor Green