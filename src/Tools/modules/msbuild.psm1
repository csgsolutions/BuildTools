Import-Module "$PSScriptRoot/common.psm1"

$default_msbuild_version = 15
$default_mstest_version = 15

function Find-MSBuild([int]$Version = $default_msbuild_version){
	$program_files = "${env:ProgramFiles(x86)}"

	if ($Version -eq 12){
		$testpaths = @(
			"$program_files\MSBuild\12.0\Bin\MSBuild.exe"
		)
	} elseif ($Version -eq 14) {
		$testpaths = @(
			"$program_files\MSBuild\14.0\Bin\MSBuild.exe"
		)
	} else {
		$testpaths = @(
			"$program_files\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe",
			"$program_files\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\MSBuild.exe",
			"$program_files\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe",
			"$program_files\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe"
		)
	}
		
	$msbuildexe = Find-FirstExistingPath -Paths $testpaths
	
	if (!($msbuildexe) -OR !(Test-Path -Path $msbuildexe)){
		throw "MSBuild.exe could not be located."
	}
	
	return $msbuildexe
}

function Find-MSTest([int]$Version = $default_mstest_version){	
	$program_files = "${env:ProgramFiles(x86)}"
	
	if ($Version -eq 12) {
		$testpaths = @(
			"$program_files\Microsoft Visual Studio 12.0\Common7\IDE\MSTest.exe"
		)
	} elseif ($Version -eq 14) {
		$testpaths = @(
			"$program_files\Microsoft Visual Studio 14.0\Common7\IDE\MSTest.exe"
		)
	} else {
		$testpaths = @(
			"$program_files\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\mstest.exe",
			"$program_files\Microsoft Visual Studio\2017\Professional\Common7\IDE\mstest.exe",
			"$program_files\Microsoft Visual Studio\2017\BuildTools\Common7\IDE\mstest.exe",
			"$program_files\Microsoft Visual Studio\2017\TestAgent\Common7\IDE\mstest.exe"
		)
	}
	
	$mstestexe = Find-FirstExistingPath -Paths $testpaths
	
	if (!($mstestexe) -OR !(Test-Path -Path $mstestexe)){
		throw "MSTest.exe could not be located."
	}
	
	return $mstestexe
}


function Start-MSBuild([string]$Project, [int]$Version = $default_msbuild_version, [string]$Target = "Build", [string]$Configuration = "Debug", [string]$Verbosity = "M") {
	$msbuildexe = Find-MSBuild -Version $Version

	Invoke-Expression "& '$msbuildexe' '/t:$Target' '/p:Configuration=$Configuration' '/v:$Verbosity' '$Project'" | Write-Host

	return $LASTEXITCODE
}

function Start-MSTest([string]$Project, [int]$Version = $default_mstest_version) {
	$mstestexe = Find-MSTest -Version $Version

	Invoke-Expression "& '$mstestexe' '/testcontainer:$Project'" | Write-Host
	
	return $LASTEXITCODE
}