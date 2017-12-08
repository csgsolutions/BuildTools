#!/usr/bin/env powershell
#requires -version 4
# CSG Build Script
# Copyright 2017 Cornerstone Solutions Group

#### CONFIGURATION ####
$SOLUTION=".\<SOLUTION_FILE>.sln"
$BUILD_CONFIG="Release"
$BuildToolsVersion="0.9.5-test"

$TEST_PROJS = @(
	".\src\<TEST_PROJECT_NAME>\<TEST_PROJECT_NAME>.csproj"
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

Write-Output "----- RESTORING -----"
dotnet restore $SOLUTION
if ($LASTEXITCODE -ne 0){
	exit $LASTEXITCODE
}

Write-Output "----- BUILDING -----"
dotnet build $SOLUTION --configuration $BUILD_CONFIG
if ($LASTEXITCODE -ne 0){
	exit $LASTEXITCODE
}

Write-Output "----- TESTING -----"
foreach ($test_proj in $TEST_PROJS){
	Write-Output "Testing $test_proj"
	dotnet test $test_proj --no-build --configuration $BUILD_CONFIG --logger "trx;logfilename=TEST-out.xml"
	if ($LASTEXITCODE -ne 0){
		exit $LASTEXITCODE
	}
}

Write-Output "----- PACKAGING -----"

foreach ($pack_proj in $PACK_PROJS){
	Write-Output "Packing $pack_proj"
	dotnet pack $pack_proj --no-build --configuration $BUILD_CONFIG
	if ($LASTEXITCODE -ne 0){
		exit $LASTEXITCODE
	}
}

Write-Output "*** RESTORE + BUILD + TEST SUCCESSFUL ***"
