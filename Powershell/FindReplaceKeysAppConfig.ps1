# Consider using AGENT_JOBNAME and jobid for parallelism
$jobname = [Environment]::GetEnvironmentVariable("AGENT_JOBNAME")
$jobid = $jobname.Substring($jobname.Length - 1, 1)

# App Config location
$filePath = "$(System.DefaultWorkingDirectory)\Example\Path\To\File\App.config"

# Read the existing file
$appConfig = [xml](cat $filePath)

# ENV Variables defined in Azure Pipeline which we need to provide two values for
$logDatabaseContext = "$(DbLogContext)"
$logDatabaseConnectionString = "$(dbLog)"

# Hash table of environmental variables to iterate through
$envVars = @{}

Get-ChildItem Env: | ForEach-Object {
    $envVars.Add($_.Key, $_.Value) 
}

$envVars.GetEnumerator() | ForEach-Object {
    $message = "ENV Key: {0}, ENV Value: {1}" -f $_.Key, $_.Value
    Write-Host $message
}

# Check if hash key exists in appConfig and replace with value if true
$appConfig.configuration.appSettings.add | ForEach-Object {
    if ($envVars.ContainsKey($_.key)) {
        $_.value = $envVars[$_.key]
    }
}

# Re-factor this foreach to get the list of replacable elements
$appConfig.configuration.connectionStrings.add | foreach {
    Write-Host $_.name  #Write each name you want to replace here
    if ($_.name -eq "DbLogContext") {
        $_.connectionString = $logDatabaseContext
        $_.providerName = "System.Data.EntityClient"
    }
    elseif ($_.name -eq "dbLog") {
        $_.connectionString = $logDatabaseConnectionString
        $_.providerName = "System.Data.SqlClient"
    }
}

# Save changes
$appConfig.Save($filePath)