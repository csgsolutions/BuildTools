#!/usr/bin/env powershell


function Get-NewExpected() {
    return @{
        "BuildNumber" = Get-Random;
        "SourceVersion" = Get-Random;
    }
}

function Clear-Environment {
    $env:BUILD_BUILDNUMBER = $Null
    $env:BUILD_SOURCEVERSION = $Null
    $env:APPVEYOR_REPO_COMMIT = $Null
    $env:APPVEYOR_BUILD_NUMBER = $Null
    $env:CSG_BUILDDATE = $Null
    $env:CSG_SVNREV = $Null
    $env:GIT_COMMITHASH = $Null
    $env:CI=$Null
    $env:AGENT_ID=$Null
    $env:SYSTEM_COLLECTIONID=$Null
    $env:GenerateAssemblyMetadataFromBuild=$Null
}

function Set-VSTSEnvironment {
    Clear-Environment
    $values = Get-NewExpected
    $env:BUILD_BUILDNUMBER = $values.BuildNumber
    $env:BUILD_SOURCEVERSION = $values.SourceVersion
    $env:AGENT_ID="123"
    $env:SYSTEM_COLLECTIONID="456"
    return $values
}

function Set-AppVeyorEnvironment {
    Clear-Environment
    $values = Get-NewExpected
    $env:APPVEYOR_REPO_COMMIT = $values.SourceVersion
    $env:APPVEYOR_BUILD_NUMBER = $values.BuildNumber
    $env:CI="true"
    return $values
}

function Set-CsgEnvironment {
    Clear-Environment
    $values = Get-NewExpected
    $env:CI="true"
    $env:CSG_BUILDDATE = $values.BuildNumber
    $env:CSG_SVNREV = $values.SourceVersion
    return $values
}

function Test-AttributeValues($val, $test, $Expected){
    if (!($val)){
        throw "No output from $test"
    }

    if (!($val -match "CommitRevision: $($Expected.SourceVersion)")) {
        throw "Unexpected commit revision from $test. Got '$val' expected '$($Expected.SourceVersion)'"
    }

    if (!($val -match "BuildNumber: $($Expected.BuildNumber)")) {
        throw "Unexpected build number from $test. Got '$val' expected '$($Expected.BuildNumber)'"
    }
}

function Test-DotNetProject($projectPath, $projectFile = "console.csproj", $Expected, $TestName, $Pack = $false){
    Write-Host "Testing $TestName..." -ForegroundColor Blue
    try {
        pushd $projectPath | Out-Null
        Remove-Item ./obj/* -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-Item ./bin/* -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-Item dotnet.log -Force -ErrorAction SilentlyContinue
        dotnet restore --no-cache $projectFile | Out-File -Append dotnet.log
        dotnet build --no-restore $projectFile | Out-File -Append dotnet.log

        if ($Pack -eq $true){
            dotnet pack --no-restore $projectFile | Out-File -Append dotnet.log
        }

        $output = & dotnet run --no-build --no-restore
        $output | Out-File -Append dotnet.log
        
        Test-AttributeValues $output $projectPath $Expected

        return @{ "Test" = "$TestName"; "Status" = "PASS" }
    } catch {
        Write-Error $_
        return @{ "Test" = "$TestName"; "Status" = "FAIL" }
    }
    finally {
        popd
    }
}

function Test-MSBuildProject($projectPath, $projectFile = "console.csproj", $Expected, $TestName){
    Write-Host "Testing $TestName..." -ForegroundColor Blue
    try {
        pushd $projectPath
        Remove-Item ./obj/* -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-Item ./bin/* -Recurse -Force -ErrorAction SilentlyContinue | Out-Null        
        Remove-Item msbuild.log -ErrorAction SilentlyContinue -Force
        $msbuild = Find-MSBuild

        Invoke-Expression "& '$msbuild' /nologo /t:Restore /p:Configuration=Debug /v:M /p:RestoreNoCache=true  $projectFile" | Out-File -Append msbuild.log
               
        if ($LASTEXITCODE -ne 0){
            throw "Restore failed code: $LASTEXITCODE"
        }

        Start-MSBuild -Project $projectFile -Configuration Debug -NoLogo | Out-File -Append msbuild.log
        
        if ($LASTEXITCODE -ne 0){
            throw "Build failed code: $LASTEXITCODE"
        }

        $val = & .\bin\Debug\console.exe
        Write-Host "Output $val"
        $val | Out-File -Append msbuild.log

        Test-AttributeValues $val $projectPath $Expected

        return @{ "Test" = "$TestName"; "Status" = "PASS" }
    } catch {
        Write-Error $_
        return @{ "Test" = "$TestName"; "Status" = "FAIL" }
    }
    finally {
        popd
    }
}

$testResults = @()
#$env:CI="true"
#$env:GenerateAssemblyMetadataFromBuild="true"
Import-Module "../src/Tools/BuildTools.psd1"

$vstest = Find-VSTest

if (!($vstest)){
    throw "VSTest not found"
}

& dotnet nuget locals all --clear

# VSTS Environment
$expected = Set-VSTSEnvironment
$testResults += (Test-MSBuildProject .\net45 -Expected $expected -TestName "VSTS net45")
$testResults += (Test-DotNetProject .\netcoreapp -Expected $expected -TestName "VSTS netcoreapp")
$testResults += (Test-DotNetProject .\netstandard16.console -ProjectFile netstandard.sln -Expected $expected -TestName "VSTS netstandard")

# Appveyor Environment
$expected = Set-AppVeyorEnvironment
$testResults += (Test-MSBuildProject .\net45 -Expected $expected -TestName "AV net45")
$testResults += (Test-DotNetProject .\netcoreapp -Expected $expected -TestName "AV netcoreapp")
$testResults += (Test-DotNetProject .\netstandard16.console -ProjectFile netstandard.sln -Expected $expected -TestName "AV netstandard")

# CSG Environment
$expected = Set-CsgEnvironment
$testResults += (Test-MSBuildProject .\net45 -Expected $expected -TestName "CSG net45")
$testResults += (Test-DotNetProject .\netcoreapp -Expected $expected -TestName "CSG netcoreapp")
$testResults += (Test-DotNetProject .\netstandard16.console -ProjectFile netstandard.sln -Expected $expected -TestName "CSG netstandard")

# Test Summary Table
Write-Host "----- TEST SUMMARY -----"
$failCount = 0
foreach ($test in $testResults) {
    Write-Host $test.Test.PadRight(32,'.') -NoNewline
    if ($test.Status -eq "PASS") {
        Write-Host $test.Status -ForegroundColor Green
    } else {
        Write-Host $test.Status -ForegroundColor Red
        $failCount++
    }
}

Write-Host "All done!" -ForegroundColor Blue
Remove-Module 'BuildTools' -ErrorAction Ignore

if ($failCount -gt 0){
    exit 3
}