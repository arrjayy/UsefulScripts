# Define string constants for usage in scripts

$DEFAULTDATABASE = "master"
$DEFAULTSMPLOCALDATABASE = "tunstall-smp-db-stage"
$DEFAULTSMPLOGDATABASE = "tunstall-smp-db-log"
$LOCALDATABASE = "dmp-db-local"
$LOCALTESTDATABASE = "${LOCALDATABASE}-test"
$LOGDATABASE = "dmp-db-log"
$LOGTESTDATABASE = "${LOGDATABASE}-test"

# Define constants for files, e.g. database scripts
$CREATEDATABASE = "/Database/CreateDatabase.sql"
$CREATELOGDATABASE = "/Database/CreateLocalLogDatabase.sql"
$CREATEACTIVITYLOG = "/Database/CreateLogDatabase[NONEXPRESS].sql"
$BUILDDATABASE = "/Database/02_Build_Database.sql"
$DATABASELIST = "Database_List.txt"

function QueryDatabaseWithFile {
    Invoke-SqlCmd -HostName "localhost" -Username "sa" -Password "${SA_PASSWORD}" -d "$1" -i "$2"
}

function ReplaceStringInFile {

}

QueryDatabaseWithFile "$DEFAULTDATABASE" "$CREATEDATABASE"

function createLocalDatabases() {
    Write-Output "Creating local database."
    replaceStringInFile "$DEFAULTSMPLOCALDATABASE" "$LOCALDATABASE" "$CREATEDATABASE"
    queryDatabaseWithFile "$DEFAULTDATABASE" "$CREATEDATABASE"

    Write-Output "Creating local test database."
    replaceStringInFile "$LOCALDATABASE" "$LOCALTESTDATABASE" "$CREATEDATABASE"
    queryDatabaseWithFile "$DEFAULTDATABASE" "$CREATEDATABASE"
}

function createLogDatabases() {
    Write-Output "Creating log database."
    replaceStringInFile "$DEFAULTSMPLOGDATABASE" "$LOGDATABASE" "$CREATELOGDATABASE"
    queryDatabaseWithFile "$DEFAULTDATABASE" "$CREATELOGDATABASE"
    queryDatabaseWithFile "$LOGDATABASE" "$CREATEACTIVITYLOG"

    Write-Output "Creating log test database."
    replaceStringInFile "$LOGDATABASE" "$LOGTESTDATABASE" "$CREATELOGDATABASE"
    queryDatabaseWithFile "$DEFAULTDATABASE" "$CREATELOGDATABASE"
    queryDatabaseWithFile "$LOGTESTDATABASE" "$CREATEACTIVITYLOG"
}

function buildDatabase() {
    Write-Output "Building local database."
    queryDatabaseWithFile "$LOCALDATABASE" "$BUILDDATABASE"
    queryDatabaseWithFile "$LOCALTESTDATABASE" "$BUILDDATABASE"
    Write-Output "Database setup complete."
}