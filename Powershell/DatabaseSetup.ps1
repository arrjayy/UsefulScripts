# Define string constants for usage in scripts

$DEFAULTDATABASE = "master"
$DEFAULTSMPLOCALDATABASE = "tunstall-smp-db-stage"
$DEFAULTSMPLOGDATABASE = "tunstall-smp-db-log"
$LOCALDATABASE = "dmp-db-local"
$LOCALTESTDATABASE = "${LOCALDATABASE}-test"
$LOGDATABASE = "dmp-db-log"
$LOGTESTDATABASE = "${LOGDATABASE}-test"
$DB_USERNAME = "NewUser"
$SA_PASSWORD = $env:SA_PASSWORD
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
    Invoke-SqlCmd -ServerInstance "$SERVERINSTANCE" -Username "$DB_USERNAME" -Password "$SA_PASSWORD" -Database "$database" -InputFile "$file"
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
    SqlLocalDB.exe create "master"  
    SqlLocalDB.exe share "master" "localhost"  
    SqlLocalDB.exe start "master"  
    SqlLocalDB.exe info "master"  
    #$NamedPipe = GetLocalDBNamedPipe -DB "master"
    $global:SERVERINSTANCE = GetLocalDBNamedPipe -DB "master"
    # The previous statement outputs the Instance pipe name for the next step 
    Invoke-SqlCmd -ServerInstance $SERVERINSTANCE -Query "CREATE LOGIN NewUser WITH PASSWORD = '$SA_PASSWORD';"
    Invoke-SqlCmd -ServerInstance $SERVERINSTANCE -Query "CREATE USER NewUser;"  
    Invoke-SqlCmd -ServerInstance $SERVERINSTANCE -Query "ALTER ROLE db_owner ADD MEMBER [NewUser] ;" 
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