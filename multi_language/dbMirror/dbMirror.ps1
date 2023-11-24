PARAM (
    [switch]$debug,
    [boolean]$log = $true
)

# -==================-
# Desc:     Generates dacpacs from target server 
#           and deploys them on localhost
# Author:   abebalmao
# Date:     2023-10-09
  $Version  =2.0
# -==================-
# CHANGELOG:
<### CONFIG ###>

[string]$sqlPackagePath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\150\sqlpackage.exe"
[string]$output = "$PSScriptRoot\util\dacpac"
[string]$server = ''
[boolean]$autorun = $false
[string]$logPath = ("$PSScriptRoot\util\logs\" + 'deployment_' + (Get-Date -Format "yyyyMMdd_HHmmss") + '.log')
[string]$postDeploymentPath = ''
[string]$alterSourceConfigPath = ''
[string]$utilDB = "dev"
<### ###>

function ListVariables {
    Write-Host "#   sqlPackagePath=$sqlpackagepath"
    Write-Host "#   output=$output"
    Write-Host "#   server=$server"
    Write-Host "#   autorun=$autorun"
    Write-Host "#   log=$log"
    Write-Host "#   logPath=$logPath"
    Write-Host "#   postDeploymentPath=$postDeploymentPath"
    Write-Host "#   alterSourceConfigPath=$alterSourceConfigPath"
    Write-Host ""
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
    $query = @"
    INSERT INTO $utilDB.dbo.dp_deployLog (dbName, loadid, deployDate, version)
    VALUES ('$databaseName', $loadid, GETDATE(), $version)
"@
    $loadId = Invoke-Sqlcmd -ServerInstance 'localhost' -Database $utilDB -Query $query

}

# Start message
Write-host ("-= CONFIG ========================-")
ListVariables # Lists variables
StartMenu # Start menu loop

if ($log) {Start-Transcript -Path $logPath}

$today = (Get-Date -Format "yyyyMMdd_HHmmss")
$dacpacFolder = Join-Path -Path $output -ChildPath $today #> $null

Invoke-Sqlcmd -ServerInstance 'localhost' -Database $utilDB -InputFile "$PSScriptRoot\create_deployLog.sql"
$loadId = Invoke-Sqlcmd -ServerInstance 'localhost' -Database $utilDB -Query "SELECT CASE WHEN max(uniqueId) is NULL THEN 1 ELSE max(uniqueId) END FROM $utilDB.dbo.dp_deployLog" | Select-Object -ExpandProperty Column1

# Checks if a folder exists for today
if (-not (Test-Path $dacpacFolder -PathType Container)) {
    # If not, create
    New-Item -Path $dacpacFolder -ItemType Directory
}

# Removes old dacpacs
#Get-ChildItem -Path $dacpacFolder | Remove-Item -Force > $null

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
if ($autorun -eq $true) {
    $databases | ForEach-Object {
        $databaseName = $_.name
        $dacpacFilePath = Join-Path -Path $dacpacFolder -ChildPath "$databaseName.dacpac"
        if (Test-Path $dacpacFilePath -PathType Leaf) {
            DeployDacpac -databaseName $databaseName -dacpacFilePath $dacpacFilePath
        } else {
            Write-Host "DACPAC file not found for database $databaseName"
        }
    }
    ## Run post deployment scripts
    Invoke-Sqlcmd -ServerInstance 'localhost' -Database 'DACO_CODE' -InputFile $postDeploymentPath
    Write-Host 'INFO: Ran postdeployment script'
    Invoke-Sqlcmd -ServerInstance 'localhost' -Database 'DACO_CODE' -InputFile $alterSourceConfigPath
    Write-Host 'INFO: Ran alter source config script'
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
        ## Run post deployment scripts
        Invoke-Sqlcmd -ServerInstance 'localhost' -Database 'DACO_CODE' -InputFile $postDeploymentPath
        Write-Host 'INFO: Ran postdeployment script'
        Invoke-Sqlcmd -ServerInstance 'localhost' -Database 'DACO_CODE' -InputFile $alterSourceConfigPath
        Write-Host 'INFO: Ran alter source config script'
    }
}



if ($log) {Stop-Transcript}
