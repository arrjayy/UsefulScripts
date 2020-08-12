#!/bin/bash
set -e

function setVariables() {
    # Define string constants for usage in scripts
    DEFAULTDATABASE="master"
    DEFAULTSMPLOCALDATABASE="tunstall-smp-db-stage"
    DEFAULTSMPLOGDATABASE="tunstall-smp-db-log"
    LOCALDATABASE="dmp-db-local"
    LOCALTESTDATABASE="${LOCALDATABASE}-test"
    LOGDATABASE="dmp-db-log"
    LOGTESTDATABASE="${LOGDATABASE}-test"

    # Define constants for files, e.g. database scripts
    CREATEDATABASE="/Database/CreateDatabase.sql"
    CREATELOGDATABASE="/Database/CreateLocalLogDatabase.sql"
    CREATEACTIVITYLOG="/Database/CreateLogDatabase[NONEXPRESS].sql"
    BUILDDATABASE="/Database/02_Build_Database.sql"
    DATABASELIST="Database_List.txt"
}

# Run query, using a .sql file, against specific database
function queryDatabaseWithFile() {
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -d "$1" -i "$2"
}

# Run query against specific database and output results to file
function queryDatabaseSaveOutput() {
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -d "$1" -Q "$2" -o "$3"
}

# Replace string in file with another string
function replaceStringInFile() {
    sed -i "s:$1:$2:g" "$3"
}

# Check if exists within file
function checkDatabaseList() {
    grep -q "$1" "$2"
}

function createLocalDatabases() {
    echo "Creating local database."
    replaceStringInFile "$DEFAULTSMPLOCALDATABASE" "$LOCALDATABASE" "$CREATEDATABASE"
    queryDatabaseWithFile "$DEFAULTDATABASE" "$CREATEDATABASE"

    echo "Creating local test database."
    replaceStringInFile "$LOCALDATABASE" "$LOCALTESTDATABASE" "$CREATEDATABASE"
    queryDatabaseWithFile "$DEFAULTDATABASE" "$CREATEDATABASE"
}

function createLogDatabases() {
    echo "Creating log database."
    replaceStringInFile "$DEFAULTSMPLOGDATABASE" "$LOGDATABASE" "$CREATELOGDATABASE"
    queryDatabaseWithFile "$DEFAULTDATABASE" "$CREATELOGDATABASE"
    queryDatabaseWithFile "$LOGDATABASE" "$CREATEACTIVITYLOG"

    echo "Creating log test database."
    replaceStringInFile "$LOGDATABASE" "$LOGTESTDATABASE" "$CREATELOGDATABASE"
    queryDatabaseWithFile "$DEFAULTDATABASE" "$CREATELOGDATABASE"
    queryDatabaseWithFile "$LOGTESTDATABASE" "$CREATEACTIVITYLOG"
}

function buildDatabase() {
    echo "Building local database."
    queryDatabaseWithFile "$LOCALDATABASE" "$BUILDDATABASE"
    queryDatabaseWithFile "$LOCALTESTDATABASE" "$BUILDDATABASE"
    echo "Database setup complete."
}

function enableMSDTC() {
    ufw allow from any to any port 51000 proto tcp
    ufw allow from any to any port 1433 proto tcp
    ufw allow from any to any port 13500 proto tcp
}

# Assign values to database names and file path locations of scripts
setVariables

# Wait a bit for SQL Server to start. SQL Server doesn't have an effective way of checking if it is active.
echo "Waiting for SQL Server to start."
sleep 15s

# Query that generates list of database(s) to check if Database has been setup already (container entrypoint has been run before)
echo "Checking if databases have already been setup."
queryDatabaseSaveOutput "$DEFAULTDATABASE" "SELECT name FROM $DEFAULTDATABASE.dbo.sysdatabases" "$DATABASELIST"

# If database already exists in txt file then don't re-run setup
if checkDatabaseList "$LOGDATABASE" "$DATABASELIST"; then
    echo "Databases are already setup, skipping setup."
else
    createLocalDatabases
    createLogDatabases
    buildDatabase
fi

echo "Container start-up successful."

exec "$@"
