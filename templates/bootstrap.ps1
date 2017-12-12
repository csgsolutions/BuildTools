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
function Expand-ZipFile([string]$Src, [string]$Dst) {
	if (Get-Command -Name 'Expand-Archive' -ErrorAction Ignore) {
		Expand-Archive -Path $Src -DestinationPath $Dst -Force
	}
	else {
		Add-Type -AssemblyName System.IO.Compression.FileSystem
		[System.IO.Compression.ZipFile]::ExtractToDirectory($Src, $Dst)
	}
}

function Get-BuildTools(){
	if ($env:CI_BUILDTOOLS_PATH) {
		$BuildToolsRemotePath = "$($env:CI_BUILDTOOLS_PATH)/$BuildToolsVersion.zip"
	} else {
		$BuildToolsRemotePath = "https://github.com/csgsolutions/BuildTools/archive/$BuildToolsVersion.zip"
	}
	
	Write-Host "CSG BuildTools Bootstrapper"
	Write-Host "Downloading CSG BuildTools from $BuildToolsRemotePath"

	$BuildToolsLocalPath = ".\"
	$BuildToolsZipFile = "BuildTools-$BuildToolsVersion.zip"
	
	#Get-RemoteFile $BuildToolsRemotePath $BuildToolsZipFile
	#Expand-ZipFile $BuildToolsZipFile $BuildToolsLocalPath
	
	$build_tools_path = (Resolve-Path "$BuildToolsLocalPath\BuildTools-$BuildToolsVersion").Path
		
	$env:CI_BUILDTOOLS = $build_tools_path
	
	if ( !(Test-Path $env:CI_BUILDTOOLS) ){
		Write-Error "Build tools failed to download"
		exit 3
	}
		
	Import-Module "$env:CI_BUILDTOOLS\modules\msbuild.psm1"
	Import-Module "$env:CI_BUILDTOOLS\modules\nuget.psm1"
	
	Write-Host "CSG BuildTools Configuration Complete"
	Write-Output "Build Tools Path: $env:CI_BUILDTOOLS"
	
	return $build_tools_path
}
