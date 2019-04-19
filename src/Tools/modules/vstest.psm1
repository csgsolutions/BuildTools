Import-Module "$PSScriptRoot/common.psm1"

# Finds the latest version of VSTest installed as part of Visual Studio. This is only intended to work with Visual Studio 2015 and later. 
function Find-VSTest(){	
	$program_files = "${env:ProgramFiles(x86)}"

	$testpaths = @(
		"$program_files\Microsoft Visual Studio\*\*\Common7\IDE\Extensions\TestPlatform\vstest.console.exe"	
	)
	
	$vstestexe = Find-FirstExistingPath -Paths $testpaths
	
	if (!($vstestexe) -OR !(Test-Path -Path $vstestexe)){
		throw "vstest.console.exe could not be located."
	}
	
	return $vstestexe
}

function Start-VSTest(
	[Parameter(Mandatory = $true, Position = 0)]
	[string]
	$Project,
	[parameter(mandatory=$false, ValueFromRemainingArguments=$true)]
	[string[]]
	$Args
	) {
	$vstestexe = Find-VSTest

	& $vstestexe $Project @Args | Write-Host

	if ($LASTEXITCODE -ne 0){
		throw "vstest.console.exe exited with code $LASTEXITCODE."
	}
	
	return $LASTEXITCODE
}