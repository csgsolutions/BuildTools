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

$Solution=".\<SOLUTION_NAME>.sln"
$TestProjects = @(
	#".\src\<TEST_PROJECT_NAME>\bin\Release\<TEST_PROJECT_NAME>.dll"
)
$OutputPackages = @(
	#".\src\<PROJECT_NAME>\.csproj"
)

try {
	. "$PSScriptRoot/bootstrap.ps1"
	Write-Host "BuildTools Initialization..." -NoNewline
	Get-BuildTools | Out-Null
	Write-Host "Done"

	# RESTORE PACKAGES
	Write-Output "Restoring packages..."
	Start-NuGetRestore -Configuration $Configuration $Solution
	
	# BUILD SOLUTION
	Write-Output "Performing build..."
	Start-MSBuild -Project $SOLUTION -Configuration $Configuration -Verbosity "M"	

	# RUN TESTS
	if ( !($NoTest.IsPresent) -and $TestProjects.Length -gt 0 ) {
		Write-Output "Performing tests..."
		foreach ($test_proj in $TestProjects) {
			Write-Output "Testing $test_proj"
			$result = Start-MSTest -Project $test_proj	
			if ($result -ne 0){
				throw "Test failed with code $result"
			}
		}
	}

	# CREATE NUGET PACKAGES
	if ( $OutputPackages.Length -gt 0 ) {
		Write-Output "Packaging..."
		foreach ($pack_proj in $OutputPackages){
			Write-Output "Packing $pack_proj"
			$result = Start-MSBuild -Target "Pack" -Project $pack_proj -Configuration $Configuration -Verbosity "M"
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
