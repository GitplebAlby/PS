#Connect-SPOService -Url "https://meidata-admin.sharepoint.com/"
#Connect-AzureAD
$alby = "adm.alby@meidata.com"


$Mail_Array = (Get-AzureADUser).UserPrincipalName
$AllSites = Get-SPOSite | select Title, Url
cls

$Answer1 = Read-Host "Let's Search for the site's URL yea? ('Y' for search / 'N' for Display all sites) "



#1 Fork - whether to search or view All the sites

if ($Answer1 -eq "N") {

    Write-Host ($AllSites | Format-Table Title, Url | Out-String)

}

elseif ($Answer1 -eq "Y") {
    $LikeName = Read-Host "
    What does the name sounds like? "
    $SearchName = '*' + $LikeName + '*'
    $SearchOptions = @()
    foreach($site in $AllSites){
        if ($site.Title -like $SearchName){
            $SearchOptions = $SearchOptions += $site
    }
}
Write-Host ($SearchOptions | Format-Table Title, Url | Out-String)
}

 
$Site = Read-Host "
    What's the Site's URL? " 


Set-SPOUser -site $Site -LoginName $alby -IsSiteCollectionAdmin $True
$Answer2 = Read-Host "Do you want to search the user's mail address? ('Y' for search / 'N' for entering the mail address) "
if ($Answer1 -eq "N") {

    $user_mail = Read-Host "What's the mail address then? "

}

elseif ($Answer1 -eq "Y") {
    $LikeName = Read-Host "
    What does the mail sound like? "
    $SearchName = '*' + $LikeName + '*'
    $SearchOptions = @()
    foreach($user in $Mail_Array){
        if ($user -like $SearchName){
            $SearchOptions += $user
    }
}
Write-Host ($SearchOptions | Out-String)
$user_mail = Read-Host "What's the mail address then? "
}






$site_name = (Get-SPOSite -Identity $site).Title
$Members_Group_Name = $site_name + ' Members'

Write-Host "
 Adding user to memebrs group"

Add-SPOUser -LoginName $user_mail -Site $site -Group $Members_Group_Name

Write-Host "
 Done!" -ForegroundColor Green
