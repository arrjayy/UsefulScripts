# Define string constants for usage in scripts
$DEFAULTDATABASE = "pipeline"
$DEFAULTSMPLOCALDATABASE = "tunstall-smp-db-stage"
$DEFAULTSMPLOGDATABASE = "tunstall-smp-db-log"
$LOCALDATABASE = "dmp-db-local"
$LOCALTESTDATABASE = "${LOCALDATABASE}-test"
$LOGDATABASE = "dmp-db-log"
$LOGTESTDATABASE = "${LOGDATABASE}-test"
$DBUSERNAME = "NewUser"
#$SA_PASSWORD = $env:SA_PASSWORD
$SA_PASSWORD = "Password123"
$SERVERINSTANCE = $null

# Define constants for files, e.g. database scripts
$CREATEDATABASE = "$env:System_DefaultWorkingDirectory\Database\CreateDatabase\CreateDatabase.sql"
$CREATELOGDATABASE = "$env:System_DefaultWorkingDirectory\Database\CreateDatabase\CreateLocalLogDatabase.sql"
$CREATEACTIVITYLOG = "$env:System_DefaultWorkingDirectory\Database\CreateDatabase\CreateLogDatabase[NONEXPRESS].sql"
$BUILDDATABASE = "$env:System_DefaultWorkingDirectory\Database\CleanDatabase\02_Build_Database.sql"
$DATABASELIST = "Database_List.txt"

function NavigateToRepository{
    Set-Location $env:System_DefaultWorkingDirectory
}

function QueryDatabaseWithFile($database, $file) {
    #Invoke-SqlCmd -ConnectionString "Server=$SERVERINSTANCE;Database=pipeline;Trusted_Connection=True;MultipleActiveResultSets=true" -Database "$database" -InputFile "$file"
    Invoke-SqlCmd -ServerInstance "$SERVERINSTANCE" -Database "$database" -InputFile "$file"
}

function ReplaceStringInFile($file, $originalString, $replacementString) {
    ((Get-Content -Path "$file" -Raw) -Replace "$originalString", "$replacementString") | Set-Content -Path "$file"
}

function CreateMasterDatabase {
    Invoke-SqlCmd -ServerInstance .\SQLEXPRESS -Query "CREATE DATABASE [$DEFAULTDATABASE]"
}

function GetLocalDBNamedPipe {
    param( [string]$DB)
    
    # This function can accept instance names in the format '(localdb)\Instance'
    $DB = $DB.replace("(localdb)\", '')
 
    # Ensure that it is running (assumes the DB already exists)
    # Note: pipe names change each time the database starts
     sqllocaldb start $DB | Out-Null
     
    return ((sqllocaldb info $DB | Select-String -Pattern "Instance pipe name") -split " ")[3]
}

function CreateAndStartLocalDB {
    #SqlLocalDB.exe create "$DEFAULTDATABASE" -s
    SqlLocalDB.exe create "pipeline"  
    SqlLocalDB.exe share "pipeline" "localhost"  
    SqlLocalDB.exe start "pipeline"  
    SqlLocalDB.exe info "pipeline"  
    #$NamedPipe = GetLocalDBNamedPipe -DB "master"
    $global:SERVERINSTANCE = GetLocalDBNamedPipe -DB "pipeline"
    # The previous statement outputs the Instance pipe name for the next step 
    # Invoke-SqlCmd -ServerInstance $SERVERINSTANCE -Query "CREATE LOGIN [$DBUSERNAME] WITH PASSWORD = '$SA_PASSWORD', DEFAULT_DATABASE=[pipeline]"
    # Invoke-SqlCmd -ServerInstance $SERVERINSTANCE -Query "ALTER SERVER ROLE [sysadmin] ADD MEMBER [$DBUSERNAME]"
    # Invoke-SqlCmd -ServerInstance $SERVERINSTANCE -Query "CREATE USER [$DBUSERNAME] FOR LOGIN [$DBUSERNAME];"  
    # Invoke-SqlCmd -ServerInstance $SERVERINSTANCE -Query "EXEC sp_addrolemember 'db_owner', [$DBUSERNAME];" 

    Invoke-SqlCmd -ServerInstance $SERVERINSTANCE -Query "Create LOGIN [NewUser] WITH PASSWORD = 'Password123'; CREATE USER [NewUser];"
    #Invoke-SqlCmd -ServerInstance $SERVERINSTANCE -Query "ALTER ROLE sysadmin ADD MEMBER [PipelineUser]"

    Invoke-Sqlcmd -ServerInstance $SERVERINSTANCE -Query "CREATE DATABASE [$DEFAULTDATABASE]"
}

function CreateLocalDatabases {
    Write-Output "Creating local database."
    replaceStringInFile "$CREATEDATABASE" "$DEFAULTSMPLOCALDATABASE" "$LOCALDATABASE"
    queryDatabaseWithFile "$DEFAULTDATABASE" "$CREATEDATABASE"

    Write-Output "Creating local test database."
    replaceStringInFile "$CREATEDATABASE" "$LOCALDATABASE" "$LOCALTESTDATABASE"
    queryDatabaseWithFile "$DEFAULTDATABASE" "$CREATEDATABASE"
}

function CreateLogDatabases {
    Write-Output "Creating log database."
    replaceStringInFile "$CREATELOGDATABASE" "$DEFAULTSMPLOGDATABASE" "$LOGDATABASE"
    queryDatabaseWithFile "$DEFAULTDATABASE" "$CREATELOGDATABASE"
    queryDatabaseWithFile "$LOGDATABASE" "$CREATEACTIVITYLOG"

    Write-Output "Creating log test database."
    replaceStringInFile "$CREATELOGDATABASE" "$LOGDATABASE" "$LOGTESTDATABASE"
    queryDatabaseWithFile "$DEFAULTDATABASE" "$CREATELOGDATABASE"
    queryDatabaseWithFile "$LOGTESTDATABASE" "$CREATEACTIVITYLOG"
}

function BuildDatabase {
    Write-Output "Building local database."
    queryDatabaseWithFile "$LOCALDATABASE" "$BUILDDATABASE"
    queryDatabaseWithFile "$LOCALTESTDATABASE" "$BUILDDATABASE"
    Write-Output "Database setup complete."
}

CreateAndStartLocalDB
#CreateMasterDatabase
CreateLocalDatabases
CreateLogDatabases
BuildDatabase