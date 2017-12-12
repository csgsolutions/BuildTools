#!/usr/bin/env powershell

Import-Module "../modules/msbuild.psm1"
Import-Module "../modules/nuget.psm1"
Import-Module "../templates/bootstrap.ps1"

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

Write-Output "bootstrap: Get-RemoteFile"
Get-RemoteFile "https://github.com/csgsolutions/BuildTools/archive/0.9.6-test.zip" "./test.zip"
if ( !(Test-Path "./test.zip") ){
    Write-Error "Get-RemoteFile test"
} else {
    Remove-Item -Force "./test.zip"
}

Write-Output "bootstrap: Get-BuildTools"
$env:CI_BUILDTOOLS = "FOO"
$path = Get-BuildTools -Version "0.9.6-test" -NoSetEnvironment

if ($env:CI_BUILDTOOLS -ne "FOO") {
    Write-Error "Get-BuildTools failed"
}

if ( !(Test-Path $path ) ){
    Write-Error "Get-BuildTools failed"
}

$path = Get-BuildTools -Version "0.9.6-test"

if ($path -ne $env:CI_BUILDTOOLS) {
    Write-Error "Get-BuildTools failed"
}