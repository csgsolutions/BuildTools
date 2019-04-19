function Find-FirstExistingPath( [string[]]$Paths ){

    foreach ($path in $paths){
        if (Test-Path $path){
            return Get-Item $path | Sort-Object -Property FullName | Select-Object -Last 1
        }
    }

    return ""
}