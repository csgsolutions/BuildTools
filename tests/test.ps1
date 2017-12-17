#!/usr/bin/env powershell

$env:CI="true"
$env:BUILD_BUILDNUMBER="42"
$env:BUILD_SOURCEVERSION="abc"

function Test-AttributeValues($val, $test){
    if (!($val)){
        throw "No output from $test"
    }

    if (!($val[0] -match "CommitRevision: $($env:BUILD_SOURCEVERSION)")) {
        throw "Unexpected commit revision from $test"
    }

    if (!($val[1] -match "BuildNumber: $($env:BUILD_BUILDNUMBER)")) {
        throw "Unexpected build number from $test"
    }
}

Write-Host "Testing netcoreapp" -ForegroundColor Magenta
pushd .\netcoreapp
dotnet restore
dotnet build
$val = & dotnet run
Test-AttributeValues $val "netcoreapp"
popd

pushd .\netstandard
Write-Host "Testing NETStandard" -ForegroundColor Magenta
dotnet restore
dotnet build
$val = & dotnet run --project .\console\
Test-AttributeValues $val "netstandard"
popd


