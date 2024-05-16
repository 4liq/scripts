param (
    [Parameter(Mandatory = $true)]
    [string]$user1 = "",
    
    [Parameter(Mandatory = $true)]
    [string]$user2 = ""
)

function clean_list($list) {
 
    $newList = @()
    foreach ($_ in $list) {

        $components = $_ -split ","
        $newList += $components[0].Substring(3)
    }

    return $newList

} 

$list1 = clean_list((Get-ADUser -Identity $user1 -Properties MemberOf | Select-Object MemberOf).MemberOf)
$list2 = clean_list((Get-ADUser -Identity $user2 -Properties MemberOf | Select-Object MemberOf).MemberOf)

$itemsOnlyList1 = $list1 | Where-Object { $_ -notin $list2 }
$itemsOnlyList2 = $list2 | Where-Object { $_ -notin $list1 }

$itemsBothHave = $list1 | Where-Object { $_ -in $list2 }
 
$maxLines = (@($itemsOnlyList1.Count, $itemsBothHave.Count, $itemsOnlyList2.Count) | Measure-Object -Maximum).Maximum

while ($itemsOnlyList1.Count -lt $maxLines) { $itemsOnlyList1 += ' ' }
while ($itemsBothHave.Count -lt $maxLines) { $itemsBothHave += ' ' }
while ($itemsOnlyList2.Count -lt $maxLines) { $itemsOnlyList2 += ' ' }

$table = for ($i = 0; $i -lt $itemsOnlyList1.Count; $i++) {

    [PSCustomObject]@{
        
        $user1 = $itemsOnlyList1[$i]
        both   = $itemsBothHave[$i]
        $user2 = $itemsOnlyList2[$i]
    }
}

$table | Format-Table -AutoSize
