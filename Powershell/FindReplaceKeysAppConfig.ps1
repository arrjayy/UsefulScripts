# Consider using AGENT_JOBNAME and jobid for parallelism
$jobname = [Environment]::GetEnvironmentVariable("AGENT_JOBNAME")
$jobid = $jobname.Substring($jobname.Length - 1, 1)

# App Config location
$filePath = "$(System.DefaultWorkingDirectory)\Example\Path\To\File\App.config"

# Read the existing file
$appConfig = [xml](cat $filePath)

# ENV Variables defined in Azure Pipeline
$logDatabaseContext = "$(DbLogContext)"
$logDatabaseConnectionString = "$(dbLog)"
$databaseConnectionString = "$(db)"
$storageAccountConnectionString = "$(storageAccount)"
$cosmosDbEndpoint = "$(documentDbEndPoint)"
$cosmosDbAuthKey = "$(documentDbAuthKey)"
$isBuildPipeline = "$(isBuildPipeline)"

# Re-factor this foreach to get the list of replacable elements
$appConfig.configuration.appSettings.add | foreach {
    Write-Host $_.key  #Write each key you want to replace here
    if ($_.key -eq "db") {
        $_.value = $databaseConnectionString
    }
    elseif ($_.key -eq "storageAccount") {
        $_.value = $storageAccountConnectionString
    }
    elseif ($_.key -eq "documentDbEndPoint") {
        $_.value = $cosmosDbEndpoint
    }
    elseif ($_.key -eq "documentDbAuthKey") {
        $_.value = $cosmosDbAuthKey
    }
    elseif ($_.key -eq "isBuildPipeline") {
        $_.value = $isBuildPipeline
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