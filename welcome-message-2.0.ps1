<#
.DESCRIPTION
    Just a simple welcome message to be run via $profile
.NOTES
    Version: 1.0
#>
function Get-DayExtension {
    param (
        [Parameter(Mandatory=$true)]
        [int]$Day
    )

    $extension = ""

    if ($Day -ge 11 -and $Day -le 13) {
        $extension = "th"
    }
    else {
        $lastDigit = $Day % 10

        switch ($lastDigit) {
            1 { $extension = "st" }
            2 { $extension = "nd" }
            3 { $extension = "rd" }
            default { $extension = "th" }
        }
    }

    return $extension
}

# NOTE!!!
# NEEDS colorText.ps1 to display colors correctly


Clear-Host

$date = Get-Date
$dateString = $date.ToString("dddd d'th' MMMM, yyyy 'at' HH:mm")

$weekday = to_cyan $date.DayOfWeek.ToString()
$dayOfMonth = to_red $date.Day.ToString()
$dayOfMonthNoColor = $date.Day.ToString()
$year = to_purple $date.Year
$month = to_yellow $date.ToString("MM")
$day = to_blue $date.Day
$time = to_red $date.ToString("HH:mm")

#$out = $weekday.ToString() + ': ' + $dayOfMonth + (to_yellow (Get-DayExtension $dayOfMonthNoColor)) + (to_yellow ' of ') + $month + (to_yellow ', ') + $year + (to_yellow ' at ') + $time
$out = $weekday + '@' + $time + '@' + $year +'-'+$month+'-'+$day 
while ($datestring.Length -lt 37) {
    $dateString += ' '
}
$dateString += '|'

$welcome = to_yellow 'Welcome'
$name = to_green 'Albin'

$startBottom = (to_cyan 'v>-----')
$endingMiddle = (to_blue '<') + (to_green 'h') + (to_yellow 'p') + ' >' + (to_cyan '*')
$endingBottom = (to_purple '__') + (to_red '.--==') + (to_blue '*^')

write-host '-======================================-'
write-host 'l' $out
write-host '|'$welcome', '$name'.                '$endingMiddle
write-host '^>-----                       ' $endingBottom #__.--==*^'
