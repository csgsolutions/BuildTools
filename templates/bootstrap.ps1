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
			
			return $LocalPath
        }
        catch {
            Write-Verbose "Request failed. $retries retries remaining"
        }
    }

	Write-Error "Download failed: '$RemotePath'."
}

# Inspired by from https://github.com/aspnet/Security/blob/dev/run.ps1
function Expand-ZipFile(
	[Parameter(ValueFromPipeline)]
	[string]$SourceFile,
	[string]$DestinationPath
) {
	if (Get-Command -Name 'Expand-Archive' -ErrorAction Ignore) {
		Expand-Archive -Path $SourceFile -DestinationPath $DestinationPath -Force
	}
	else {
		Add-Type -AssemblyName System.IO.Compression.FileSystem
		[System.IO.Compression.ZipFile]::ExtractToDirectory($SourceFile, $DestinationPath)
	}
}

function Get-BuildTools(
	[string]$Version,
	[switch]$NoSetEnvironment
){
	Write-Host "Initializing build tools..." -NoNewline

	if ($env:CI_BUILDTOOLS_PATH) {
		$remotePath = "$($env:CI_BUILDTOOLS_PATH)/$version.zip"
	} else {
		$remotePath = "https://github.com/csgsolutions/BuildTools/archive/$version.zip"
	}
	
	$localPath = ".\BuildTools-$version"
		
	if ( !(Test-Path $localPath) ){
		Get-RemoteFile $remotePath "BuildTools-$version.zip" | Expand-ZipFile -DestinationPath "./"		
	}
	
	if ( !(Test-Path $localPath) ){
		throw "Build tools failed to download"
	}
	
	$absolutePath = (Resolve-Path $localPath).Path
	
	if (!($NoSetEnvironment.IsPresent)) {
		$env:CI_BUILDTOOLS = $absolutePath
	}
		
	Import-Module "$absolutePath\modules\msbuild.psm1"
	Import-Module "$absolutePath\modules\nuget.psm1"
	
	Write-Host "Done`r`n"

	return $absolutePath 
}
