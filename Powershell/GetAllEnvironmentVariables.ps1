$envVars = @{}

Get-ChildItem Env: | ForEach-Object {
    $envVars.Add($_.Key, $_.Value) 
}

$envVars.GetEnumerator() | ForEach-Object {
    $message = "ENV Key: {0}, ENV Value: {1}" -f $_.Key, $_.Value
    Write-Host $message
}