Import-Module "$PSScriptRoot/common.psm1"

function Find-VSTest(){	
	$program_files = "${env:ProgramFiles(x86)}"

	$testpaths = @(
		"$program_files\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\Extensions\TestPlatform\vstest.console.exe",
		"$program_files\Microsoft Visual Studio\2017\Professional\Common7\IDE\Extensions\TestPlatform\vstest.console.exe",
		"$program_files\Microsoft Visual Studio\2017\Community\Common7\IDE\Extensions\TestPlatform\vstest.console.exe",
		"$program_files\Microsoft Visual Studio\2017\TestAgent\Common7\IDE\Extensions\TestPlatform\vstest.console.exe"
	)
	
	$vstestexe = Find-FirstExistingPath -Paths $testpaths
	
	if (!($vstestexe) -OR !(Test-Path -Path $vstestexe)){
		throw "vstest.console.exe could not be located."
	}
	
	return $vstestexe
}

function Start-VSTest([string]$Project) {
	$vstestexe = Find-VSTest

	Invoke-Expression "& '$vstestexe' '$Project'" | Write-Host
	
	return $LASTEXITCODE
}