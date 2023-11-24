PARAM (
    [switch]$debug
)

# -==================-
# Desc:     Generates dacpacs from target server 
#           and deploys them on localhost
#           NOTE: This is an old version of dbMirror
# Author:   abebalmao
# Date:     2023-08-14
# Version:  1.0
# -==================-

<### CONFIG ###>

[string]$sqlPackagePath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\150\sqlpackage.exe"
[string]$output = ''
[string]$server = ''
[boolean]$autorun = $false

<### ###>

function ListVariables {
    Write-Host ("#   sqlPackagePath=" + $sqlPackagePath)
    Write-Host ("#   output=" + $output)
    Write-Host ("#   server=" + $server)
    Write-Host ("#   autorun=" + $autorun)

    # Warnings

    if ($autorun) {
        Write-host 'WARNING! - if $autorun is enabled it will automatically deploy the dacpac after generation'
    }
}

function StartMenu {
    Write-host "-= generate and deploy dacpacs ===-"
    Write-host "#   To assign a variable: 'variable1=NewValue'"
    Write-Host "#   'list' lists variables"
    Write-host "#   'start' self explanatory"
    Write-host "-=================================-"

    while ($true) {
        
        #Write-Host ("To change a variable type: $var=newValue")
        $input = Read-Host "|>"
        
        if ($input -eq 'start') {
            if ($autorun) {
                Write-host 'WARNING! - $autorun is enabled and will automatically deploy the dacpacs'
                $input = Read-Host "Continue?"
                if ($input -eq 'yes' -or $input -eq 'y') {
                    Write-host "Starting..."
                    return # Exit the while loop
                }
                Write-host "Autorun has been turned off"
                Set-Variable -Name $variableName -Value $false -Scope 1

            }
            Write-host "Starting..."
            return # Exit the while loop
        }
    
        if ($input -eq 'list') {
            ListVariables
        }
    
        if ($input -match '^(?<variableName>[a-zA-Z0-9_]+)=(?<value>.*)$') {
            $variableName = $Matches['variableName']
            $value = $Matches['value']
    
            # Update the variable if it exists
            if (Get-Variable -Name $variableName -Scope 1 -ErrorAction SilentlyContinue) {
                Set-Variable -Name $variableName -Value $value -Scope 1
                Write-Host "CHANGED:"$variableName"="$value
            } else {
                Write-Host "ERROR: Variable '$variableName' does not exist"
            }
        }
    }
}

function DeployDacpac {
    param (
        [string]$databaseName,
        [string]$dacpacFilepath
    )
    
    Write-Host "Deploying $dacpacFilePath on localhost"
    & $sqlPackagePath /Action:Publish /SourceFile:$dacpacFilePath /TargetServerName:'localhost' /TargetDatabaseName:$databaseName

}

# Start message
Write-host ("-= CONFIG ========================-")
ListVariables # Lists variables
StartMenu # Start menu loop

$today = Get-date -Format "yyMMdd"
$dacpacFolder = Join-Path -Path $output -ChildPath $today #> $null

# Checks if a folder exists for today
if (-not (Test-Path $dacpacFolder -PathType Container)) {
    # If not, create
    New-Item -Path $dacpacFolder -ItemType Directory
}

# Removes old dacpacs
Get-ChildItem -Path $dacpacFolder | Remove-Item -Force > $null

# Define the T-SQL query
$query = @"
    SELECT name
    FROM sys.databases
    WHERE database_id > 4;
"@

# Execute the query using Invoke-Sqlcmd
$databases = Invoke-Sqlcmd -ServerInstance $server -Database "master" -Query $query

$totalDatabases = $databases.Count
$currentDatabaseIndex = 0

Write-host ("Found " + $totalDatabases + " databases")

# Output the database names and generate .dacpac files
$databases | ForEach-Object {
    $currentDatabaseIndex++
    $databaseName = $_.name
    $dacpacFilePath = Join-Path -Path $dacpacFolder -ChildPath "$databaseName.dacpac"

    Write-Host ("Processing database "+ $currentDatabaseIndex + "/" + $totalDatabases + ": " + $databaseName)

    # Build the sqlpackage.exe command
    $sqlPackageArgs = @(
        "/Action:Extract",
        "/SourceDatabaseName:$databaseName",
        "/SourceServerName:$server",
        "/TargetFile:`"$dacpacFilePath`""
    )

    # Execute sqlpackage.exe
    & $sqlPackagePath @sqlPackageArgs 2>&1 > $null

    Write-Host "Dacpac created: $dacpacFilePath"
}

### ghetto fix this later, duplicate code
if ($autorun = 'true') {
    $databases | ForEach-Object {
        $databaseName = $_.name
        $dacpacFilePath = Join-Path -Path $dacpacFolder -ChildPath "$databaseName.dacpac"
        if (Test-Path $dacpacFilePath -PathType Leaf) {
            DeployDacpac -databaseName $databaseName -dacpacFilePath $dacpacFilePath
        } else {
            Write-Host "DACPAC file not found for database $databaseName"
        }
    }
} else {
    Write-Host "Deploy dacpacs to localhost? (Y/N)"
    $input = Read-Host "|>"
    
    if ($input -eq 'y') {
        $databases | ForEach-Object {
            $databaseName = $_.name
            $dacpacFilePath = Join-Path -Path $dacpacFolder -ChildPath "$databaseName.dacpac"
            if (Test-Path $dacpacFilePath -PathType Leaf) {
                DeployDacpac -databaseName $databaseName -dacpacFilePath $dacpacFilePath
            } else {
                Write-Host "DACPAC file not found for database $databaseName"
            }
        }
    }
    
}

