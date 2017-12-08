#!/usr/bin/env powershell
#requires -version 4
# CSG Build Script
# Copyright 2017 Cornerstone Solutions Group

#### CONFIGURATION ####
$SOLUTION=".\apps\<SOLUTION_FILE>.sln"
$BUILD_CONFIG="Release"
$BuildToolsVersion="0.9.5-test"

$TEST_PROJS = @(
	".\src\<TEST_PROJECT_NAME>\bin\Release\<TEST_PROJECT_NAME>.dll"
)

$PACK_PROJS = @(
	".\src\<PROJECT_NAME>\.csproj"
)

# From https://github.com/aspnet/Security/blob/dev/run.ps1
function Get-RemoteFile([string]$RemotePath, [string]$LocalPath) {
    if ($RemotePath -notlike 'http*') {
        Copy-Item $RemotePath $LocalPath
        return
    }

    $retries = 10
    while ($retries -gt 0) {
        $retries -= 1
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $RemotePath -OutFile $LocalPath
            return
        }
        catch {
            Write-Verbose "Request failed. $retries retries remaining"
        }
    }

    Write-Error "Download failed: '$RemotePath'."
}

# Inspired by from https://github.com/aspnet/Security/blob/dev/run.ps1
function Extract-Zip([string]$Src, [string]$Dst) {
	if (Get-Command -Name 'Expand-Archive' -ErrorAction Ignore) {
		Expand-Archive -Path $Src -DestinationPath $Dst -Force
	}
	else {
		Add-Type -AssemblyName System.IO.Compression.FileSystem
		[System.IO.Compression.ZipFile]::ExtractToDirectory($Src, $Dst)
	}
}

function Init-BuildTools(){
	if ($env:CI_BUILDTOOLS_PATH) {
		$BuildToolsRemotePath = "$($env:CI_BUILDTOOLS_PATH)/$BuildToolsVersion.zip"
	} else {
		$BuildToolsRemotePath = "https://github.com/csgsolutions/BuildTools/archive/$BuildToolsVersion.zip"
	}
	
	Write-Host "Downloading build tools from $BuildToolsRemotePath"

	$BuildToolsLocalPath = ".\"
	$BuildToolsZipFile = "BuildTools-$BuildToolsVersion.zip"
	
	Get-RemoteFile $BuildToolsRemotePath $BuildToolsZipFile
	
	Extract-Zip $BuildToolsZipFile $BuildToolsLocalPath
	
	return (Resolve-Path "$BuildToolsLocalPath\BuildTools-$BuildToolsVersion").Path
}

#### MAIN ####

Write-Output "----- GET BUILD TOOLING -----"

$env:CI_BUILDTOOLS = Init-BuildTools

Write-Output "Build Tools Path: $env:CI_BUILDTOOLS"

if (!(Test-Path $env:CI_BUILDTOOLS)){
	Write-Error "Build tools failed to download"
	exit 3
}

# Import msbuild module
Import-Module "$env:CI_BUILDTOOLS\modules\msbuild.psm1"

$msbuild = Find-MsBuild

# Error because we can't find msbuild
if (!(Test-Path $msbuild)) {
	Write-Error "Could not find msbuild.exe"
	exit 3
}

# RESTORE PACKAGES
Write-Output "----- RESTORING -----"
.\apps\.nuget\nuget.exe restore $SOLUTION

if ($LASTEXITCODE -ne 0){
	Write-Error "***Restore Failed: $LASTEXITCODE***"
	exit $LASTEXITCODE
}

# BUILD SOLUTION
Write-Output "----- BUILDING -----"
Invoke-Expression "& '$msbuild' '$SOLUTION' '/p:Configuration=$BUILD_CONFIG' '/v:M'"

if ($LASTEXITCODE -ne 0){
	Write-Error "***Build Failed: $LASTEXITCODE***"
	exit $LASTEXITCODE
}

# RUN TESTS
Write-Output "----- TESTING -----"

$mstest = Find-MsTest

foreach ($test_proj in $TEST_PROJS){
	Write-Output "Testing $test_proj"
	Invoke-Expression "& '$mstest' '/testcontainer:$test_proj'"
	if ($LASTEXITCODE -ne 0){
		Write-Error "***Test Failed: $LASTEXITCODE***"
		exit $LASTEXITCODE
	}
}

# CREATE NUGET PACKAGES
Write-Output "----- PACKAGING -----"
foreach ($pack_proj in $PACK_PROJS){
	Write-Output "Packing $pack_proj"	
	Invoke-Expression "& '$msbuild' '$pack_proj' '/t:Pack' '/p:Configuration=$BUILD_CONFIG' '/v:M'"
	if ($LASTEXITCODE -ne 0){
		Write-Error "***Pack Failed: $LASTEXITCODE***"
		exit $LASTEXITCODE
	}
}

Write-Output "*** RESTORE + BUILD + TEST SUCCESSFUL ***"
