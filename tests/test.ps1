#!/usr/bin/env powershell

Import-Module "../modules/msbuild.psm1"
Import-Module "../modules/nuget.psm1"

$msbuild15 = Find-MSBuild -Version 15
Write-Output "Find MSBuild15: $msbuild15"
if (!(Test-Path $msbuild15 )){
    Write-Error("We should have found msbuild 15")
}

$msbuild14 = Find-MSBuild -Version 14
Write-Output "Find MSBuild14: $msbuild14"
if (!(Test-Path $msbuild14)){
    Write-Error("We should have found msbuild 14")
}

$msbuild12 = Find-MSBuild -Version 12
Write-Output "Find MSBuild12: $msbuild12"
if (!(Test-Path $msbuild12)){
    Write-Error("We should have found msbuild 15")
}
