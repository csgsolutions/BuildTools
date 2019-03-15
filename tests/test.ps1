#!/usr/bin/env powershell


function Get-NewExpected(){
    return @{
        "BuildNumber" = Get-Random;
        "SourceVersion" = Get-Random;
    }
}

function Set-VSTSEnvironment {
    $values = Get-NewExpected
    $env:BUILD_BUILDNUMBER = $values.BuildNumber
    $env:BUILD_SOURCEVERSION = $values.SourceVersion
    return $values
}

function Set-AppVeyorEnvironment {
    $values = Get-NewExpected
    $env:APPVEYOR_REPO_COMMIT = $values.BuildNumber
    $env:APPVEYOR_BUILD_NUMBER = $values.SourceVersion
    $values
}

function Set-CsgEnvironment {
    $values = Get-NewExpected
    $env:CSG_BUILDDATE = $values.BuildNumber
    $env:CSG_SVNREV = $values.SourceVersion
    $values
}

function Test-AttributeValues($val, $test, $Expected){
    if (!($val)){
        throw "No output from $test"
    }

    if (!($val[0] -match "CommitRevision: $($Expected.SourceVersion)")) {
        throw "Unexpected commit revision from $test. Got '${$val[0]}' expected '$($Expected.SourceVersion)'"
    }

    if (!($val[1] -match "BuildNumber: $($Expected.BuildNumber)")) {
        throw "Unexpected build number from $test. Got '${$val[1]}' expected '$($Expected.BuildNumber)'"
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
        Test-AttributeValues $output $projectPath
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
        Remove-Item ./obj/* -Recurse -Force -ErrorAction SilentlyContinue| Out-Null
        Remove-Item ./bin/* -Recurse -Force -ErrorAction SilentlyContinue| Out-Null
        Remove-Item msbuild.log -ErrorAction SilentlyContinue -Force
        Start-MSBuild -Project $projectFile -Target Restore -Configuration Debug -NoLogo | Out-File -Append msbuild.log
        #Invoke-Expression "& '$msbuild' '/nologo' '/t:Restore' '/p:Configuration=Debug' '/v:m' '$projectFile'" | Out-File -Append msbuild.log
       
        if ($LASTEXITCODE -ne 0){
            throw "Restore failed code: $LASTEXITCODE"
        }

        Start-MSBuild -Project $projectFile -Configuration Debug -NoLogo | Out-File -Append msbuild.log
        #Invoke-Expression "& '$msbuild' '/nologo' '/p:Configuration=Debug' '/v:m' '$projectFile'" | Out-File -Append msbuild.log
        if ($LASTEXITCODE -ne 0){
            throw "Build failed code: $LASTEXITCODE"
        }
        $val = & .\bin\Debug\console.exe
        $val | Out-File -Append msbuild.log
        Test-AttributeValues $val $projectPath
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
$env:CI="true"
Import-Module "../src/Tools/BuildTools.psd1"

$vstest = Find-VSTest

if (!($vstest)){
    throw "VSTest not found"
}

# VSTS Environment
$expected = Set-VSTSEnvironment $expected
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