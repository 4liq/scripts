$baseLocation = 'H:\code\ps1\scripts\'
$git = 'H:\git\'
$mssql = ($git + 'daco-mssql\')

function Get-WelcomeMessage { & ($baseLocation + 'welcomeMsg.ps1') }

function Get-Encoding { & ($baseLocation + 'getEncoding.ps1') }

function Get-Dailies {
    $jsonFile = Get-Content -Path ($baseLocation + 'conf\dailies.json') -Raw
    $json = $jsonfile | ConvertFrom-Json
    write-host $json[1]
}

function Get-Scripts {
    <#
    .SYNOPSIS
        Lists all incorporated scripts

    .NOTES
        v1.0
    #>
    Write-Host 'Listing availible scripts: '
    Get-ChildItem -Path $baseLocation | Where-Object { $_.Name -like '*.ps1' } | ForEach-Object {
        
        write-host '  - '$_.Name
    }
}

function Update-SQL {
    <#
    .DESCRIPTION
        Updates / creates the procedures and tables in the .sql files in the directory listed at $localpath

    .PARAMETER $path
        [string] Path to the directory where .sql files are located

    .PARAMETER $server
        [string] Server name (and instance) for the target in which to Invoke-Sqlcmd

    .PARAMETER $output
        [boolean] Displays the files which have been executed
    
    .NOTES
        v1.0
    #>
    param (
        [string]$path = 'H:\git\daco-mssql\daco-mssql',
        [string]$server = 'SEV74006',
        [boolean]$output = $false
    )
    $scriptPath = Join-Path -Path $baseLocation -ChildPath "updateSql.ps1"

    try {
        Write-Host 'Updating SQL Server procedures'
        Write-host '    @location'  $path
        Write-host '    @server' $server
        & $scriptPath $path $server $output
        Write-Host 'Updated SQL procedures'
    }
    catch {
        Write-Host 'ERROR!!!'
        foreach ($e in $error) {
            write-host $e
        }
    }
}

function prompt {
    $currentFolder = (Get-Location).Path | Split-Path -Leaf
    $prompt = "| $currentFolder |> "
    return $prompt
}

function Help-Please {
    Write-host '|> The current custom functions enabled are:'
    Write-host '|  - hp : Help-Please'
    Write-host '|  - wm : Get-WelcomeMessage'
    Write-host '|  - Get-Dailies'
    Write-host '|  - Get-Scripts'
    Write-host '|  - Update-SQL'
    Write-host '|  - prompt'
    Write-host '|'
    Write-host '|> Variables:'
    Write-host '|  - $baseLocation  = H:\code\ps1\scripts\'
    Write-host '|  - $git           = H:\git\'
    Write-host '|  - $mssql         = ($git + daco-mssql\)'
}

# Aliases
Set-Alias -Name hp -Value Help-Please
Set-Alias -name wm -Value Get-WelcomeMessage
Get-WelcomeMessage
