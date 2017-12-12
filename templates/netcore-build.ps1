#!/usr/bin/env powershell
#requires -version 4
# CSG Build Script
# Copyright 2017 Cornerstone Solutions Group
Param(
	[alias("c")][string]
	$Configuration = "Release",
	[string]
	$BuildToolsVersion = "0.9.7-test",
	[switch]
	$NoTest
)

#### CONFIGURATION ####
$Solution=".\<SOLUTION_FILE>.sln"

$TestProjects = @(
	".\src\<TEST_PROJECT_NAME>\<TEST_PROJECT_NAME>.csproj"
)

$PackProjects = @(
	".\src\<PROJECT_NAME>\.csproj"
)

#### ---- MAIN ---- ####
try {
	. "$PSScriptRoot/bootstrap.ps1"
	Write-Host "BuildTools Initialization..." -NoNewline
	Get-BuildTools | Out-Null
	Write-Host "Done"

	# RESTORE
	Write-Output "Restoring packages..."
	dotnet restore $SOLUTION
	if ($LASTEXITCODE -ne 0){
		throw "Package restore failed with exit code $LASTEXITCODE."
	}

	# BUILD SOLUTION
	Write-Output "Performing build..."
	dotnet build $SOLUTION --configuration $Configuration
	if ($LASTEXITCODE -ne 0){
		throw "Build failed with exit code $LASTEXITCODE."
	}

	if ( !($NoTest.IsPresent) -and $TestProjects.Length -gt 0 ) {
		Write-Output "Performing tests..."
		foreach ($test_proj in $TestProjects) {
			Write-Output "Testing $test_proj"
			dotnet test $test_proj --no-build --configuration $Configuration --logger "trx;logfilename=TEST-out.xml"
			if ($LASTEXITCODE -ne 0){
				throw "Test failed with code $LASTEXITCODE"
			}
		}
	}
	# CREATE NUGET PACKAGES
	if ( $OutputPackages.Length -gt 0 ) {
		Write-Output "Packaging..."
		foreach ($pack_proj in $OutputPackages){
			Write-Output "Packing $pack_proj"
			dotnet pack $pack_proj --no-build --configuration $Configuration
			if ($result -ne 0){
				throw "Pack failed with code $result"
			}
		}
	}

	Write-Output "-------------------"
	Write-Output "EVERYTHING WAS GOOD"
	Write-Output "-------------------"
		
	exit 0
} catch {
	Write-Error $_
	Write-Output "-------------"
	Write-Output "*** ERROR ***"
	Write-Output "-------------"
	Write-Host "ERROR: An error occurred and the build was aborted." -ForegroundColor White -BackgroundColor Red
	exit 3
}