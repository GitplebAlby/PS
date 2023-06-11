



#import-Module microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell


#Connect-SPOService -Url "https://meidata-admin.sharepoint.com/" 


#Find Source Sites 
cls
$Answer1 = Read-Host "Do You Know the Urls of Your Source And Target Sites? If yes, Type 'K', if no and you wanna search, type 'S' and if you want to look at all of them, type 'A' "

$AllSites = Get-SPOSite | select Title, Url

#1 Fork - whether to search or view All the sites

if ($Answer1 -eq "A") {
Write-Host ($AllSites | Format-Table Title, Url | Out-String)
}

elseif ($Answer1 -eq "S") {
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

#By This Point you should have on the screen All the Root sites matching your search
 
$SourceRootSite = Read-Host "
What's the Source Root Site's URL? " 

#Now we find the SubSite from which we want to copy

$subAnswer = Read-Host "
Does this Site has sub sites? (Y/N)"

#2 Fork - subsites
if ($subAnswer -eq "Y"){
Connect-PnPOnline -Url $SourceRootSite -Interactive
$subsites = Get-PnPSubWeb -Recurse -IncludeRootWeb
Write-Host ($subsites | Format-Table Title, Url | Out-String)
}

#By This Point you should have on the screen All the Sub Sites of the root site you chose

$SourceSite = Read-Host "
What's the Source Site then? "

#Now we find the source List
$Answerlist = Read-Host "
Do u know the Source list's Name? (Y/N) "
if ($Answerlist = "N"){
Connect-PnPOnline -Url $SourceSite -Interactive
Write-Host (Get-PnPList | Out-String)
}
$Sourcelistname = Read-Host "
what's the  source's list's name then?"
$Sourcelist = Get-PnPList -Identity $Sourcelistname
$SourceFolderURL = $sourcelist.DefaultViewUrl.Replace("/Forms/AllItems.aspx","")

#Now we are done with the source's URLs, Lets find the target urls

$AnswerDestination = Read-Host "
Do U Wanna Search the Destination site URL? (Y/N) "

if ($AnswerDestination -eq "Y"){
$LikeName = Read-Host "What does the name sounds like? "
$SearchName = '*' + $LikeName + '*'
$SearchOptions = @()
foreach($site in $AllSites){
if ($site.Title -like $SearchName){
$SearchOptions = $SearchOptions += $site
}
}
Write-Host ($SearchOptions | Format-Table Title, Url | Out-String)
}

$TargetSite = Read-Host "
What's the Target's site URL then? "
Connect-PnPOnline -Url $TargetSite -Interactive

$AnswerTargetFolder = Read-Host "
Do you like to View the folders and pick a Root Target Folder? (Y/N)"

if ($AnswerTargetFolder -eq "Y"){
 $mylist = "Documents"
 $AllFolders = Get-PnPListItem -List $mylist -PageSize 500 | where {$_.FieldValues.File__x0020_Type -eq $null}
 $allFoldersURL = $AllFolders.FieldValues.FileRef
 $AllFoldersArray = @($allFoldersURL)
 $NewFoldersArray = @()
 Foreach ($item in $AllFoldersArray) {
    $charCount = ($item.ToCharArray() | Where-Object {$_ -eq '/'} | Measure-Object).Count
    If ($charCount -le 5) {
        $NewFoldersArray = $NewFoldersArray += $item
    }
}

Write-Host ($NewFoldersArray |  Out-String)
}

$RootTargetFolder = Read-Host "
What's the Root Target Folder then? "


#NOW WE WILL CHECK IF THE ACTIVE USERS IN THIS SITE IS OK FOR US:
Connect-PnPOnline -Url $SourceSite -Interactive
$AllFiles = Get-PnPListItem -List $Sourcelistname -PageSize 500
$FileAuthors = $AllFiles.fieldvalues.Author
$inactiveUsers = @()
$ActiveUsers = @()
$Ers = @()

foreach($FileAuthor in $FileAuthors){

$Author = $FileAuthor.LookupValue
if ($Author -notin $inactiveUsers -and $Author -notin $ActiveUsers){

$user = Get-PnPUser -Identity $Author

if ($user -eq $null){
$inactiveUsers += $Author
}

else{
$ActiveUsers += $Author
}
}
}

Write-Host "
These are The Inactive Authors in this site: " $inactiveUsers 

$AnswerProceed = Read-Host "
Is This OK? (Y/N) "
if ($AnswerProceed -eq "N"){
return
}
#*************************ADD SOURCE USERS TO TARGET MEMBERS*****************






#IF WE REACHED HERE WE ARE READY TO PROCEED, NOW THE BIG LOOP:

$Errors = @()
$counter = 0

Connect-PnPOnline -Url $SourceSite -Interactive
$TotalFilesCount = (Get-PnPListItem -List $Sourcelistname -PageSize 500).Count
$SourceRootFolders = (Get-PnPListItem -List $Sourcelistname -PageSize 500 | where {(($_.FieldValues.FileRef.ToCharArray()| Where-Object {$_ -eq '/'} | Measure-Object).Count) -eq ((($SourceFolderURL.ToCharArray()| Where-Object {$_ -eq '/'} | Measure-Object).Count) + 1)})

#Start Copy Confirmation:

$FoldersCopied = @()

#BIG LOOP

foreach($SourceFolder in $SourceRootFolders){

#Confirm Big Folder Copy
$AnswerFolderContinue = Read-Host ("
Copying Root Folder: " + $SourceFolder.FieldValues.FileLeafRef + " - Okay? (Y/N)")


if ($AnswerFolderContinue -eq "N") {
continue
}

$counter++
Write-Progress -Activity 'Copying Big Folder' -CurrentOperation $SourceFolder.FieldValues.FileLeafRef -PercentComplete (($counter / $TotalFilesCount ) * 100)
#Copy Big Folder and continue Script



$TargetBigFolderURL = $RootTargetFolder.ToString() + $SourceFolder.FieldValues.FileRef.Substring($SourceFolderURL.Length)

#**************COPY********************


try{
Copy-PnPFile -SourceUrl $SourceFolder.FieldValues.FileRef -TargetUrl $RootTargetFolder -IgnoreVersionHistory -Force -ErrorAction Stop

}
catch{
$Errors += [pscustomobject]@{File=$SourceFolder.FieldValues.FileLeafRef ; RelativePath =$SourceFolder.FieldValues.FileRef ; Error = $_.ToString()}

}

#Get The Target Big Folder as PnPListItem

Connect-PnPOnline -Url $TargetSite -Interactive

$TargetBigFolder = (Get-PnPListItem -List "Documents" -PageSize 500 | Where-Object {$_.FieldValues.FileRef -eq $TargetBigFolderURL})

if($TargetBigFolder -eq $null){
$TargetBigFolder = Get-PnPListItem -List "Documents" -PageSize 500 | Where-Object {$_.FieldValues.FileRef -eq $TargetBigFolderURL}
}

#****************SET THE METADATA********************(Set the target big folder's metadata)


try{
Set-PnPListItem -List "Documents" -Identity $TargetBigFolder.Id -Values @{Modified = $SourceFolder.FieldValues.Modified} -ErrorAction Stop
}
catch{
$Errors += [pscustomobject]@{File=$SourceFolder.FieldValues.FileLeafRef ; RelativePath =$SourceFolder.FieldValues.FileRef ; Error = $_.ToString()}
}
try{
Set-PnPListItem -List "Documents" -Identity $TargetBigFolder.Id -Values @{Modified_x0020_By = $SourceFolder.FieldValues.Modified_x0020_By ; Created_x0020_By = $SourceFolder.FieldValues.Created_x0020_By  ; Author = $SourceFolder.FieldValues.Author.Email ; Editor = $SourceFolder.FieldValues.Editor.Email} -ErrorAction Stop
Write-Host $TargetBigFolder.FieldValues.FileLeafRef "Was Copied Succesfully" -ForegroundColor Green
}
catch{
$Errors += [pscustomobject]@{File=$SourceFolder.FieldValues.FileLeafRef ; RelativePath =$SourceFolder.FieldValues.FileRef ; Error = $_.ToString()}
}

 

$AnswerLittleLoop = Read-Host ("I Copied Big folder: " + $SourceFolder.FieldValues.FileLeafRef + " Do You Want me To copy the metadata of the nested files and folders? (Y/N) ")
if ($AnswerLittleLoop -eq "N"){
$FoldersCopied += $TargetBigFolder.FieldValues.FileLeafRef
continue
}
else{
$FoldersCopied += $TargetBigFolder.FieldValues.FileLeafRef
}


#LITTLE LOOP - Files and Nested Folders - first get all the files in the big folder, then loop.

Connect-PnPOnline -Url $SourceSite -Interactive
$SourceFolderFiles = (Get-PnPListItem -List $Sourcelistname -PageSize 500 | where {$_.FieldValues.FileDirRef -like ($SourceFolder.FieldValues.FileRef+'*')})
if ($SourceFolderFiles.count -eq 1 -and $SourceFolderFiles.FieldValues.fileRef -eq $TargetBigFolderURL){
continue
}
else{

#***************************ADD AUTHORS OF FILES TO TARGET SITE MEMBERS************************

#$SourceFiles_Authors = $SourceFolderFiles.FieldValues.Author.Email

#Connect-PnPOnline -Url $TargetSite -Interactive

#$TargetUsers = (Get-SPOUser -Site $TargetSite).LoginName
#create the group string for XXXX members
#$cutter = "sites/"
#$GroupName = $TargetSite.Substring($TargetSite.IndexOf($cutter) + $cutter.Length) + " Members"

#foreach($LittleAuthor in $SourceFiles_Authors){
#if($TargetUsers -cnotcontains $LittleAuthor){
#Add-SPOUser -Site $TargetSite -Group $GroupName -LoginName $LittleAuthor
#}
#}

foreach ($file in $SourceFolderFiles){
$counter++
Write-Progress -Activity 'Copying Metadata' -CurrentOperation $file.FieldValues.FileLeafRef -PercentComplete (($counter / $TotalFilesCount ) * 100)
Connect-PnPOnline -Url $SourceSite -Interactive
$SourceFileURL = $file.FieldValues.FileRef
$targetFileURL = $RootTargetFolder.ToString() + $file.FieldValues.FileRef.Substring($SourceFolderURL.Length)
$TargetFolderURL = $targetFileURL.Replace('/' + $file.FieldValues.FileLeafRef, "")


#connect to target pnp
Connect-PnPOnline -Url $TargetSite -Interactive

$TargetFile = Get-PnPListItem   -List "Documents" -PageSize 500 | Where-Object {$_.FieldValues.FileRef -eq $TargetFileURL} 


#Change Metadata

try{
Set-PnPListItem -List "Documents" -Identity $TargetFile.Id -Values @{Modified = $file.FieldValues.Modified} -ErrorAction Stop
}
catch{
$Errors += [pscustomobject]@{File=$file.FieldValues.FileLeafRef ; RelativePath =$file.FieldValues.FileRef ; Error = $_.ToString()}
}
try{
Set-PnPListItem -List "Documents" -Identity $TargetFile.Id -Values @{Modified_x0020_By = $file.FieldValues.Modified_x0020_By ; Created_x0020_By = $file.FieldValues.Created_x0020_By  ; Author = $file.FieldValues.Author.Email ; Editor = $file.FieldValues.Editor.Email} -ErrorAction Stop
}
catch{
$Errors += [pscustomobject]@{File=$file.FieldValues.FileLeafRef ; RelativePath =$file.FieldValues.FileRef ; Error = $_.ToString()}
}
Write-Host $TargetFile.FieldValues.FileLeafRef "  metadata Was Copied Succesfully" -ForegroundColor Green
}
} 
}

#End Of Little Loop - Time For Validation:
Connect-PnPOnline -Url $TargetSite -Interactive
$today = Get-Date
$TargetFolderFiles = Get-PnPListItem -List "Documents" -PageSize 500 | where {$_.FieldValues.FileRef -like ('*'+$TargetFolderURL + '*')}
$ShitFiles = $Target  | where {$_.FieldValues.Author.Email -eq "adm.alby@meidata.com" -or $_.FieldValues.Editor.Email -eq "adm.alby@meidata.com" -or $_.FieldValues.Modified -eq $today}
if ($ShitFiles -eq $null) {
write-host "
Metadata Check Went Well!"
}
else {
write-host ("
Some Files seems to have been written today or by alby, These are the files:" +
$ShitFiles.FieldValues.FileLeafRef)
}
$AnswerAnotherBigFolder = Read-Host "
Do u Wish to do another big folder? (Y/N)"
if ($AnswerAnotherBigFolder -eq "N"){ 
return
}
#End Of Big Loop
$FoldersCopied | Out-File -FilePath "C:\PSScripts\Meidata\FolderCopied.csv" -Append -Force
$Errors | Export-Csv -Path "C:\PSScripts\Meidata\Errors.csv" -Force -NoTypeInformation

