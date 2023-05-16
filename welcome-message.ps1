<#
.DESCRIPTION
    Just a simple welcome message to be run via $profile
.NOTES
    Version: 1.0
#>

$date = Get-Date
$dateString = $date.ToString("dddd d'th' MMMM, yyyy 'at' HH:mm")
while ($datestring.Length -lt 37) {
    $dateString += ' '
}
$dateString += '|'

Clear-Host
write-host '-======================================-'
write-host 'l' $dateString
Write-Host '| Welcome, Albin.                      l'
write-host '^>----                        __.--==*^'
