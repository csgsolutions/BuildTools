#!/usr/bin/env powershell
#requires -version 4
# CSG Build Script
# Copyright 2017 Cornerstone Solutions Group
Param(
	[alias("c")][string]
	$Configuration = "Release",
	[string]
	$BuildToolsVersion = "0.9.15S-beta",
	[switch]
	$NoTest
)

$Solution=".\<SOLUTION_NAME>.sln"
$TestProjects = @(
	#".\src\<TEST_PROJECT_NAME>\bin\$Configuration\<TEST_PROJECT_NAME>.dll"
)
$OutputPackages = @(
	#".\src\<PROJECT_NAME>\.csproj"
)

Write-Host "=============================================================================="
Write-Host "The Build Script"
Write-Host "=============================================================================="

try {
	. "$PSScriptRoot/bootstrap.ps1"
	Get-BuildTools -Version $BuildToolsVersion | Out-Null

	# RESTORE PACKAGES
	Write-Host "Restoring Packages..." -ForegroundColor Magenta
	Start-NuGetRestore -Configuration $Configuration $Solution
	
	# BUILD SOLUTION
	Write-Host "Performing build..." -ForegroundColor Magenta
	Start-MSBuild -Project $SOLUTION -Configuration $Configuration -Verbosity "M"	

	# RUN TESTS
	if ( !($NoTest.IsPresent) -and $TestProjects.Length -gt 0 ) {
		Write-Host "Performing tests..." -ForegroundColor Magenta
		foreach ($test_proj in $TestProjects) {
			Write-Host "Testing $test_proj"
			$result = Start-MSTest -Project $test_proj	
			if ($result -ne 0) {
				throw "Test failed with code $result"
			}
		}
	}

	# CREATE NUGET PACKAGES
	if ( $OutputPackages.Length -gt 0 ) {
		Write-Host "Packaging..."  -ForegroundColor Magenta
		foreach ($pack_proj in $OutputPackages){
			Write-Host "Packing $pack_proj"
			$result = Start-MSBuild -Target "Pack" -Project $pack_proj -Configuration $Configuration -Verbosity "M"
			if ($result -ne 0) {
				throw "Pack failed with code $result"
			}
		}
	}

	Write-Host "All Done. This build is great! (as far as I can tell)" -ForegroundColor Green
	exit 0
} catch {
	Write-Host "ERROR: An error occurred and the build was aborted." -ForegroundColor White -BackgroundColor Red
	Write-Error $_	
	exit 3
}