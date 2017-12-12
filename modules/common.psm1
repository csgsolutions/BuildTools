function Find-FirstExistingPath( [string[]]$Paths ){
    foreach ($path in $paths){
        if (Test-Path $path){
            return $path
        }
    }

    return ""
}