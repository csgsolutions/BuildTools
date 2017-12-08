function Get-ProgramFilesX86(){
	return "${env:ProgramFiles(x86)}"
}

function Find-MsBuild(){
	$program_files = Get-ProgramFilesX86
	# Try Enterprise msbuild
	$msbuild="$program_files\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe"
	# Fallback on Visual Studio Pro
	if (!(Test-Path $msbuild)) {
		$msbuild="$program_files\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\MSBuild.exe"
	}
	# Fallback on Build Tools
	if (!(Test-Path $msbuild)) {
		$msbuild="$program_files\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe"	
	}
	
	# Fallback on Build Tools
	if (!(Test-Path $msbuild)) {
		return ""
	}
	
	return $msbuild
}

function Find-MsTest(){	
	$program_files = Get-ProgramFilesX86
	# Try Enterprise mstest
	$mstest="$program_files\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\mstest.exe"
	# Fallback on Visual Studio Pro
	if (!(Test-Path $mstest)) {
		$mstest="$program_files\Microsoft Visual Studio\2017\Professional\Common7\IDE\mstest.exe"
	}
	# Fallback on Build Tools
	if (!(Test-Path $mstest)) {
		$mstest="$program_files\Microsoft Visual Studio\2017\BuildTools\Common7\IDE\mstest.exe"	
	}
	
	# Fallback on Build Tools
	if (!(Test-Path $mstest)) {
		return ""
	}
	
	return $mstest
}

