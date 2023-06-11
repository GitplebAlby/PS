#Connect-SPOService -Url "https://meidata-admin.sharepoint.com/" 


#Find Source Sites 
cls
$Answer1 = Read-Host "Let's Search for the site's URL yea? ('Y' for search / 'N' for Display all sites) "

$AllSites = Get-SPOSite | select Title, Url

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

 
$SourceRootSite = Read-Host "
    What's the Root Site's URL? " 

 
$source_Root_Connection = Connect-PnPOnline -Url $SourceRootSite -Interactive -ReturnConnection
#2 Fork - subsites
Write-Host "Checking For Subsites..." -ForegroundColor Green
$subsites = Get-PnPSubWeb -Recurse -IncludeRootWeb -Connection $source_Root_Connection

if($subsites -eq $null){
    $SourceSite = $SourceRootSite
    $Source_Connection = $source_Root_Connection
}

else{
    cls
    Write-Host "
    IT SEEMS THIS SITE CONTAINS SUBSITES, WHICH ONE DO YOU WANNA FUCK WITH? 
    " -ForegroundColor Green

    Write-Host ($subsites | Format-Table Title, Url | Out-String)
}



$SourceSite = Read-Host "
What's Your Site's URL then? "
$Source_Connection = Connect-PnPOnline -Url $SourceSite -Interactive -ReturnConnection
#Now we find the source List
$Answerlist = Read-Host "
Do u know the Source list's Name? (Y/N) "
if ($Answerlist = "N"){
    Write-Host (Get-PnPList -Connection $source_Connection | Out-String)
}
$Sourcelistname = Read-Host "
what's the  source's list's name then? [EXAMPLE: Documents]"
$Sourcelist = Get-PnPList -Identity $Sourcelistname -Connection $Source_Connection
$SourceFolderURL = $sourcelist.DefaultViewUrl.Replace("/Forms/AllItems.aspx","")

Write-Host "Checking for files Modified after 10/04/2023"
#Now check if there are files with modified date later than 10/04/2023
$Date = Get-Date 10/04/2023
$All_files = Get-PnPListItem -List $Sourcelist -Connection $Source_Connection | Where-Object {$_.FieldValues.Modified -gt $Date}
$Data = @()

if ($All_files -eq $null){
    Write-Host -ForegroundColor Green "
    No Recent Changes Found
    "
}
else{
    Write-Host -ForegroundColor Green "
    Found Some Recent Files, It Will Take a Few Seconds..."

    foreach($file in $All_files){
        $name = $file.FieldValues.FileLeafRef
        $path = $file.FieldValues.FileRef
        $Modified = $file.FieldValues.Modified
        $Editor = $file.FieldValues.Editor.LookupValue
        $Data += [pscustomobject]@{'Name' = $name ; 'Path' = $path ; 'Last Modified' = $Modified ; 'Modified By' = $Editor}
    }
}
$FolderExportPath = Read-Host "What's the path to the folder of the exported CSV? [Example: C:\PSScripts] "
$ExportPath = $FolderExportPath + '\' + 'Changed_Files.csv'
$Data | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
