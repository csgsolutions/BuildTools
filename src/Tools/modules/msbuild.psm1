Import-Module "$PSScriptRoot/common.psm1"

# Finds the latest version of MSbuild installed as part of Visual Studio. This is only intended to work with Visual Studio 2015 and later. 
function Find-MSBuild($VisualStudioVersion = "*"){
	$program_files = "${env:ProgramFiles(x86)}"
	$program_files64 = "${env:ProgramFiles}"
	
	$testpaths = @(
		"$program_files64\Microsoft Visual Studio\$VisualStudioVersion\*\MSBuild\*\Bin\MSBuild.exe",
		"$program_files\Microsoft Visual Studio\$VisualStudioVersion\*\MSBuild\*\Bin\MSBuild.exe"
	)
	
	$msbuildexe = Find-FirstExistingPath -Paths $testpaths
	
	if (!($msbuildexe) -OR !(Test-Path -Path $msbuildexe)){
		throw "MSBuild.exe could not be located."
	}
	
	return $msbuildexe
}

# Finds the latest version of MSTest installed as part of Visual Studio. This is only intended to work with Visual Studio 2015 and later. 
function Find-MSTest($VisualStudioVersion = "*"){	
	$program_files = "${env:ProgramFiles(x86)}"
	$program_files64 = "${env:ProgramFiles}"
	
	$testpaths = @(
		"$program_files64\Microsoft Visual Studio\$VisualStudioVersion\*\Common7\IDE\mstest.exe",
		"$program_files\Microsoft Visual Studio\$VisualStudioVersion\*\Common7\IDE\mstest.exe"
	)
	
	$mstestexe = Find-FirstExistingPath -Paths $testpaths
	
	if (!($mstestexe) -OR !(Test-Path -Path $mstestexe)){
		throw "MSTest.exe could not be located."
	}
	
	return $mstestexe
}

function Start-MSBuild(
	[string]$Project, 
	[string]$VisualStudioVersion = "*",
	[string]$Target = "Build", 
	[string]$Configuration = "Debug", 
	[string]$Verbosity = "M",
	[switch]$NoLogo,
	[string[]]$Properties
) {
	$msbuildexe = Find-MSBuild -Version $Version -VisualStudioVersion $VisualStudioVersion
	
	$cmd = "& '$msbuildexe' '/t:$Target' '/p:Configuration=$Configuration' '/v:$Verbosity' "
	if ($NoLogo.IsPresent) {
		$cmd += "'/nologo' "
	}
	foreach ($property in $Properties) {
		$cmd += "'/p:$property' "
	}
	$cmd += "'$Project' "

	Invoke-Expression $cmd | Write-Host

	if ($LASTEXITCODE -ne 0){
		throw "msbuild.exe exited with code $LASTEXITCODE."
	}

	return $LASTEXITCODE
}

function Start-MSTest(
	[string]$Project, 
	[string]$VisualStudioVersion = "*"
) {
	$mstestexe = Find-MSTest -Version $Version -VisualStudioVersion $VisualStudioVersion

	Invoke-Expression "& '$mstestexe' '/testcontainer:$Project'" | Write-Host

	if ($LASTEXITCODE -ne 0){
		throw "mstest.exe exited with code $LASTEXITCODE."
	}

	return $LASTEXITCODE
}