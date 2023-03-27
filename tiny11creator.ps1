#tested with original Win11_22H2_Finnish_x64v1.iso ESD/WIM support
#version 0.9
#Defining preferences variables
Set-MpPreference -DisableRealtimeMonitoring $true
cls
Write-Output "Script Starting..."
Write-Output "Loading configs..."
$rootWorkdir = Get-Location
$logfile = "$rootWorkdir\log.txt"
$downloadupd = 1 #download msu updates, disable 0, enable 1, updates found line 116-
$instdownloadupd = 1 # install msu updates, disable 0, enable 1, install found line 280-
#skip indipendet update, change $skipdwn value in line 125-
$isoFolder = join-path -path $rootWorkdir -childpath "\iso\"
$installImageFolder = join-path -path $rootWorkdir -childpath "\installimage\"
$bootImageFolder = join-path -path $rootWorkdir -childpath "\bootimage\"
$updateFolder = join-path -path $rootWorkdir -childpath "\update\"
$scratchdir = join-path -path $rootWorkdir -childpath "\scratchdir\"
$yes = (cmd /c "choice <nul 2>nul")[1] #The $yes variable gets the "y" 
$wimfolder = ($isoFolder + "sources\install.wim")
$esdfolder = ($isoFolder + "sources\install.esd")
$isoPath = Get-ChildItem -Path $rootWorkdir -ErrorAction SilentlyContinue -Include "*.iso" -exclude "*_tiny.iso" -Depth 1 | %{$_.FullName}
if ([String]::IsNullOrEmpty($isoPath)){
   Write-Output "ISO-file not found, please copy Windows install ISO-file in script folder"
   ("ERROR: ISO file not found") | Out-File -Append -FilePath $logfile
   pause
   exit
}
$tinyfound = Get-ChildItem -Path $rootWorkdir -filter "*_tiny.iso" -Depth 1 | %{$_.FullName}
$updfound = Get-ChildItem -Path $updateFolder -filter "*.msu" -Depth 1 | %{$_.FullName}
$isotiny = $isoPath -replace ".{4}$"
function green {
process { Write-Host $_ -ForegroundColor green }}
function red {
process { Write-Host $_ -ForegroundColor red }}

If (Test-Path $logfile) {
   Remove-Item $logfile -Force -ErrorAction SilentlyContinue >$null
}

#remove old mounts
Write-Output "Removing old mounts..."
"Obsolete mount point remove..." | Out-File -Append -FilePath $logfile

Get-windowsImage -Mounted | ForEach {
$ProgressPreference = 'SilentlyContinue'
Dismount-WindowsImage -Discard -Path $_.Path -ErrorVariable ProcessError >$null
If ($ProcessError){
Write-Output ("Unmount not possible, exit now") | green
break
}
Write-Output ("Unmount " + ($_.Path)) | green
} 
if ((Get-DiskImage $isoPath | Get-Volume).DriveLetter) {
while ((Get-DiskImage $isoPath | Get-Volume).DriveLetter) {
Write-Output ("Unmount " + ((Get-DiskImage $isoPath | Get-Volume).DriveLetter)) | green
Dismount-DiskImage -ImagePath $isoPath >$null 
}
}

#Creating temporary folders
if (Test-Path -Path $isoFolder) {
   Remove-Item -Force $isoFolder -Recurse -ErrorVariable ProcessError >$null
   If ($ProcessError){
   takeown /f $isoFolder /r /d $yes >$null
   icacls $isoFolder /grant ("$env:username"+":F") /T /C >$null
   Remove-Item -Force $isoFolder -Recurse -ErrorAction SilentlyContinue >$null
   }
   Write-Output "Deleting old IsoFolder..."
   ($isoFolder + "- folder removed") | Out-File -Append -FilePath $logfile
   md $isoFolder >$null
   Write-Output "Make new IsoFolder..."
   ($isoFolder + " folder added") | Out-File -Append -FilePath $logfile
   } else {
   md $isoFolder >$null
   Write-Output "Make new IsoFolder..."
   ($isoFolder + "- folder added") | Out-File -Append -FilePath $logfile
   }

if (Test-Path -Path $installImageFolder) {
   Remove-Item -Force $installImageFolder -Recurse -ErrorVariable ProcessError >$null
   If ($ProcessError){
   takeown /f $installImageFolder /r /d $yes >$null
   icacls $installImageFolder /grant ("$env:username"+":F") /T /C >$null
   Remove-Item -Force $installImageFolder -Recurse -ErrorAction SilentlyContinue >$null
   }
   Write-Output "Deleting old InstallImageFolder..."
   ($installImageFolder + "- folder removed") | Out-File -Append -FilePath $logfile
   md $installImageFolder >$null
   Write-Output "Make new installFolder..."
   ($installImageFolder + "- folder added") | Out-File -Append -FilePath $logfile
   } else {
   md $installImageFolder >$null
   Write-Output "Make new installFolder..."
   ($installImageFolder + "- folder added") | Out-File -Append -FilePath $logfile
   }

if (Test-Path -Path $bootImageFolder) {
   Remove-Item -Force $bootImageFolder -Recurse  -ErrorVariable ProcessError  >$null
   If ($ProcessError){
   takeown /f $bootImageFolder /r /d $yes >$null
   icacls $bootImageFolder /grant ("$env:username"+":F") /T /C >$null
   Remove-Item -Force $bootImageFolder -Recurse -ErrorAction SilentlyContinue >$null
   }
   Write-Output "Deleting old BootImageFolder..."
   ($bootImageFolder + "- folder removed") | Out-File -Append -FilePath $logfile
   md $bootImageFolder >$null
   Write-Output "Make new bootFolder..."
   ($bootImageFolder + "- folder added") | Out-File -Append -FilePath $logfile
   } else {
   md $bootImageFolder >$null
   Write-Output "Make new bootFolder..."
   ($bootImageFolder + "- folder added") | Out-File -Append -FilePath $logfile
   }
   
#Defining more variables
$config = (Get-Content "config.json" -Raw) | ConvertFrom-Json
$wantedImageName = $config.WantedWindowsEdition
$unwantedProvisionnedPackages = $config.ProvisionnedPackagesToRemove
$unwantedWindowsPackages = $config.WindowsPackagesToRemove
$y = $config.PathsToDelete
Write-Output ("orig. " + $isoPath) | green
("found iso " + ($isoPath)) | Out-File -Append -FilePath $logfile

if ($downloadupd -eq 1){
$jan23 = "https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/secu/2023/01/windows11.0-kb5022303-x64_87d49704f3f7312cddfe27e45ba493048fdd1517.msu"
$feb23 = "https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/secu/2023/02/windows11.0-kb5022845-x64_279b2b5fcc98e99c79f85a395cd7e8eef8d06503.msu"
$mar23 = "https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/secu/2023/03/windows11.0-kb5023706-x64_79f9cb602196d8152019690a7a67d6d3e9833165.msu"

$jan23folder = Get-ChildItem -Path $updateFolder -filter "windows11.0-kb5022303*.msu" -Depth 1 | %{$_.FullName}
$feb23folder = Get-ChildItem -Path $updateFolder -filter "windows11.0-kb5022845*.msu" -Depth 1 | %{$_.FullName}
$mar23folder = Get-ChildItem -Path $updateFolder -filter "windows11.0-kb5023706*.msu" -Depth 1 | %{$_.FullName}

$skipdwn = 0 # 0=skip download update, 1=download
if ($skipdwn -eq 1){
if ([String]::IsNullOrEmpty($jan23folder)){
   Write-Output "Download Windows 11 update January2023..."
   ("Download update:" + $January2023update) | Out-File -Append -FilePath $logfile
   Invoke-WebRequest -uri $jan23 -OutFile "$updateFolder jan23.msu"
}}
$skipdwn = 0 # 0=skip download update, 1=download
if ($skipdwn -eq 1){
if ([String]::IsNullOrEmpty($feb23folder)){
   Write-Output "Download Windows 11 update February2023..."
   ("Download update:" + $February2023update) | Out-File -Append -FilePath $logfile
   Invoke-WebRequest -uri $feb23 -OutFile "$updateFolder feb23.msu"
}}
$skipdwn = 1 # 0=skip download update, 1=download
if ($skipdwn -eq 1){
if ([String]::IsNullOrEmpty($mar23folder)){
   Write-Output "Download Windows 11 update March2023..."
   ("Download update:" + $March2023update) | Out-File -Append -FilePath $logfile
   Invoke-WebRequest -uri $mar23 -OutFile "$updateFolder mar23.msu"
}}
} else {
#Remove-Item ($updateFolder + "/*.*") -Force -Recurse -ErrorAction SilentlyContinue >$null
}

#Creating temporary folders   
if (!(Test-Path -Path $updateFolder)) {
   md $updateFolder >$null
   Write-Output "Make new UpdateFolder..."
   ($updateFolder + "- folder added") | Out-File -Append -FilePath $logfile
   ("put update .msu files here") | Out-File -Append -FilePath $logfile
   } else {
   if ($instdownloadupd -eq 1){
   if (Get-ChildItem -Path $updateFolder -Include "*.msu" -Depth 1 | %{$_.FullName}) {
   Write-Output "Update found:" | green
   Write-Output (Get-ChildItem -Path $updateFolder -Include "*.msu" -Depth 1 | %{$_.FullName}) | green
   }
   if (!(Get-ChildItem -Path $updateFolder -Include "*.msu" -Depth 1 | %{$_.FullName})) {
   Write-Output "No updates found..." | red
   ($updateFolder + "- no any update file") | Out-File -Append -FilePath $logfile
   }}}

if (Test-Path -Path $scratchdir) {
   takeown /f $isoFolder /r /d $yes >$null
   icacls $scratchdir /grant ("$env:username"+":F") /T /C >$null
   Remove-Item -Force $scratchdir -Recurse -ErrorAction SilentlyContinue >$null
   Write-Output "Deleting old Scratchdir..."
   ($scratchdir + "- folder removed") | Out-File -Append -FilePath $logfile
   md $scratchdir >$null
   Write-Output "Make new Scratchdir..."
   ($scratchdir + " folder added") | Out-File -Append -FilePath $logfile
   } else {
   md $scratchdir >$null
   Write-Output "Make new Scratchdir..."
   ($scratchdir + "- folder added") | Out-File -Append -FilePath $logfile
   }



########## Test if ready made iso found ###########
if (-not ([String]::IsNullOrEmpty($tinyfound))){
if (Test-Path $tinyfound -PathType leaf){
$choice = $null
while ($choice -notmatch "[y|n]"){
    Write-Output ("----> " + $tinyfound) | red
    $choice = read-host "Ready made ISO exist, Do you need keep it? (Y/N)"
    }

if ($choice -eq "y"){
    Write-Output "Please, copy now your ISO in save"
    pause
    exit
    } else {
takeown /f $tinyfound >$null
icacls $tinyfound /grant ("$env:username"+":F") /C >$null
Remove-Item -Path $tinyfound
("Old ISO " + ($tinyfound) + " removed") | Out-File -Append -FilePath $logfile
Write-Output ("Old ISO " + ($tinyfound) + " removed") | red
}}}

#Mount the Windows 11 ISO
Write-Output "Mounting original iso..." | green
$mountResult = Mount-DiskImage -ImagePath $isoPath
$isoDriveLetter = ($mountResult | Get-Volume).DriveLetter
("Mount ISO: " + $isoPath + " to " + $isoDriveLetter + ":\") | Out-File -Append -FilePath $logfile

#Copying the ISO files to the ISO folder
Write-Output "Copying mounted ISO to iso-folder..."
cp -Recurse ($isoDriveLetter + ":\*") $isoFolder >$null
("Copying files from: " + $isoDriveLetter + ":\ to " + $isoFolder) | Out-File -Append -FilePath $logfile

#Unmounting the original ISO since we don't need it anymore (we have a copy of the content)
Write-Output "Unmounting original iso..." | green
Dismount-DiskImage -ImagePath $isoPath >$null
("Unmount ISO " + $isoDriveLetter + ":\") | Out-File -Append -FilePath $logfile

#test ISO type install.wim or install.esd and convert to install.wim
if (Test-Path $wimfolder -PathType leaf){
Write-Output "INSTALL.WIM found"
("Testing ISO type found install.wim") | Out-File -Append -FilePath $logfile
#Getting the wanted image index
$wantedImageIndex = Get-WindowsImage -ImagePath ($isoFolder + "sources\install.wim") | where-object { $_.ImageName -eq $wantedImageName } | Select-Object -ExpandProperty ImageIndex

} else {
########## ESD convert ##########
Write-Output "ISO type is install.esd, now need do converting to install.wim" | red
("Testing ISO type found install.esd, now need do converting to install.wim") | Out-File -Append -FilePath $logfile
$choice = $null
Write-Output "Select Windows ISO INDEX !" | red
while ($choice -gt 0 -lt 10){
$choice = read-host "Please select INDEX for ISO handling (h=info)"
     if ($choice -eq "h"){
        cls
        Write-Output (dism /Get-WimInfo /WimFile:$esdfolder /LogPath=$logfile)
        $choice = $null
}}
$wantedImageIndex = $choice
("ISO index valittu: " + $wantedImageIndex) | Out-File -Append -FilePath $logfile
dism /export-image /SourceImageFile:$esdfolder /SourceIndex:$wantedImageIndex /DestinationImageFile:$wimfolder /Compress:max /CheckIntegrity /LogPath=$logfile
("Converting ready") | Out-File -Append -FilePath $logfile
Write-Output ("Orig. ESD REMOVE...") | red
("Original ESD removed") | Out-File -Append -FilePath $logfile
Remove-Item $esdfolder -Force -ErrorAction SilentlyContinue > $null
Write-Output ("Now try handling normally...") | green
("Continue with WIM type handling") | Out-File -Append -FilePath $logfile
}

################# Beginning of install.wim patches ##################
#WIM not found index number
if ([String]::IsNullOrEmpty($wantedImageIndex)){
$choice = $null
Write-Output "Windows install INDEX not found from config or ISO-file" | red
while ($choice -gt 0 -lt 10){
$choice = read-host "Please give INDEX for proper windows version (h=info)"
     if ($choice -eq "h"){
        cls
        Write-Output (dism /get-wiminfo /wimfile:$wimfolder /LogPath=$logfile)
        $choice = $null
     } 
}
("No ISO config file index found, given index:" + $choice) | Out-File -Append -FilePath $logfile
$wantedImageIndex = $choice
}

#Mounting the WIM image
Write-Output "Mounting install.wim image..." | green
("WIM mount folder:" + $wimfolder + " / Index:" + $wantedImageIndex) | Out-File -Append -FilePath $logfile
Set-ItemProperty -Path $wimfolder -Name IsReadOnly -Value $false >$null
Mount-WindowsImage -ImagePath $wimfolder -Index $wantedImageIndex -Path $installImageFolder -ErrorAction SilentlyContinue -ErrorVariable ProcessError >$null

#install windows update 
if ($instdownloadupd -eq 1) {
$upall = Get-ChildItem -Path $updateFolder -Include "*.msu" -Depth 1 | Sort-Object Name | %{$_.FullName}
ForEach ($update in $upall) {
    $UpdateFilePath = $update.FullName
    Write-Output ($update + " update install") |green
    Dism /image:$installImageFolder /add-package /PackagePath:$update /scratchdir:$scratchdir
    ($update + " update installed") | Out-File -Append -FilePath $logfile
}
} else {
Write-Output "Update file not found" | red
("No any update to ISO") | Out-File -Append -FilePath $logfile
}

#Detecting provisionned app packages
Write-Output "APPX PACKAGE REMOVE..."
$detectedProvisionnedPackages = Get-AppxProvisionedPackage -Path $installImageFolder

#Removing unwanted provisionned app packages
("Remove APPX packages:") | Out-File -Append -FilePath $logfile
$ProcessError = $null

ForEach ($detectedProvisionnedPackage in $detectedProvisionnedPackages)
{ 
	ForEach ($unwantedProvisionnedPackage in $unwantedProvisionnedPackages)
	{     
        If ($detectedProvisionnedPackage.PackageName.Contains($unwantedProvisionnedPackage)){
		    Remove-AppxProvisionedPackage -Path $installImageFolder -PackageName $detectedProvisionnedPackage.PackageName -ErrorAction SilentlyContinue -ErrorVariable ProcessError >$null
		    If (!($ProcessError)){
                ("Package: " + ($unwantedProvisionnedPackage) + " REMOVED") | Out-File -Append -FilePath $logfile
                Write-Output (($detectedProvisionnedPackage.PackageName) + " REMOVED") | green >$null
            }
            If ($ProcessError){
                ("Package: " + ($unwantedProvisionnedPackage) + " NOT REMOVED") | Out-File -Append -FilePath $logfile
                Write-Output (($detectedProvisionnedPackage.PackageName) + " ERROR") | red >$null
                ($ProcessError) | Out-File -Append -FilePath $logfile
                $ProcessError = $null
            }
        }
	}
}


#Detecting windows packages
Write-Output "WINDOWS PACKAGE REMOVING..."
$detectedWindowsPackages = Get-WindowsPackage -Path $installImageFolder

#Removing unwanted windows packages
("Removing WINDOWS packages:") | Out-File -Append -FilePath $logfile
$ProcessError = $null

ForEach ($detectedWindowsPackage in $detectedWindowsPackages)
{
    ForEach ($unwantedWindowsPackage in $unwantedWindowsPackages)
	{    
	    If ($detectedWindowsPackage.PackageName.Contains($unwantedWindowsPackage)){        
		    Remove-WindowsPackage -Path $installImageFolder -PackageName $detectedWindowsPackage.PackageName -ErrorAction SilentlyContinue -ErrorVariable ProcessError >$null
            If (!($ProcessError)){
                 ("WindowsPackage: " + ($unwantedWindowsPackage) + " REMOVED") | Out-File -Append -FilePath $logfile
                 Write-Output (($detectedWindowsPackage.PackageName) + " REMOVED") | green >$null                 
            }  
            If ($ProcessError){
                 ("WindowsPackage: " + ($unwantedWindowsPackage) + " NOT REMOVED") | Out-File -Append -FilePath $logfile
                 Write-Output (($detectedWindowsPackage.PackageName) + " ERROR") | red >$null               
                 ($ProcessError) | Out-File -Append -FilePath $logfile
                 $ProcessError = $null
            }              
        }     
    }
}


Write-Output "PATH REMOVING..."
"paths remove:" | Out-File -Append -FilePath $logfile
$ProcessError = $null
Foreach ($pathToDelete in $pathsToDelete)
{
$fullpath = ($installImageFolder + $pathToDelete.Path)
Write-Output ($fullpath)

    If ($pathToDelete.IsFolder -eq $true){
        takeown /f $fullpath /r /d $yes
		icacls $fullpath /grant ("$env:username"+":F") /T /C
		Remove-Item -Force $fullpath -Recurse -ErrorAction SilentlyContinue -ErrorVariable ProcessError
            If (!($ProcessError)){
	            ("Path:" + ($fullpath) + " REMOVED") | Out-File -Append -FilePath $logfile
                Write-Output (($pathToDelete) + " REMOVED") | green >$null
            }
            If ($ProcessError){
                ("Path:" + ($fullpath) + " NOT REMOVED") | Out-File -Append -FilePath $logfile
                Write-Output (($pathToDelete) + " ERROR") | red >$null
                ($ProcessError) | Out-File -Append -FilePath $logfile
                $ProcessError = $null
            }

    } Else {
	    takeown /f $fullpath  >$null
        icacls $fullpath /grant ("$env:username"+":F") /T /C
	    Remove-Item -Force $fullpath -ErrorAction SilentlyContinue -ErrorVariable ProcessError
            If (!($ProcessError)){
                ("File:" + ($fullpath) + " REMOVED") | Out-File -Append -FilePath $logfile
                Write-Output (($pathToDelete) + " REMOVED") | green >$null
            }
            If ($ProcessError){
                 ("File:" + ($fullpath) + " NOT REMOVED") | Out-File -Append -FilePath $logfile
                 Write-Output (($pathToDelete) + " REMOVED") | red >$null
                $ProcessError = $null
            }
 	}
}

# Loading the registry from the mounted WIM image
Write-Output "PATCH REGISTERY IN INSTALL.WIM..."
("Registery pached in install.wim file") | Out-File -Append -FilePath $logfile
reg load HKLM\installwim_DEFAULT ($installImageFolder + "Windows\System32\config\default") >$null
reg load HKLM\installwim_NTUSER ($installImageFolder + "Users\Default\ntuser.dat") >$null
reg load HKLM\installwim_SOFTWARE ($installImageFolder + "Windows\System32\config\SOFTWARE") >$null
reg load HKLM\installwim_SYSTEM ($installImageFolder + "Windows\System32\config\SYSTEM") >$null
# Applying following registry patches on the system image:
#	Bypassing system requirements
#	Disabling Teams
#	Disabling Sponsored Apps
#	Enabling Local Accounts on OOBE
#	Disabling Reserved Storage
#	Disabling Chat icon
regedit /s ./installwim_patches.reg >$null
reg unload HKLM\installwim_DEFAULT >$null
reg unload HKLM\installwim_NTUSER >$null
reg unload HKLM\installwim_SOFTWARE >$null
reg unload HKLM\installwim_SYSTEM >$null

#Copying the setup config file
Write-Output "Placing the autounattend.xml file in the install.wim image..."
("Adding autounattend.xml WIM file") | Out-File -Append -FilePath $logfile
[System.IO.File]::Copy((Get-ChildItem .\autounattend.xml).FullName, ($installImageFolder + "Windows\System32\Sysprep\autounattend.xml"), $true) >$null

#Unmount the install.wim image
Write-Output "Unmounting install.wim image..." | green
("Unmount WIM file folder") | Out-File -Append -FilePath $logfile
Dismount-WindowsImage -Path $installImageFolder -save >$null

#Moving the wanted image index to a new image
Write-Output "Creating a clean install.wim image without all unecessary indexes..."
("Moved proper index WIM file to ISO") | Out-File -Append -FilePath $logfile
Export-WindowsImage -SourceImagePath ($isoFolder + "sources\install.wim") -SourceIndex $wantedImageIndex -DestinationImagePath ($isoFolder + "sources\install_patched.wim") -CompressionType max >$null

#Delete the old install.wim and rename the new one
if (Test-Path -Path $isoFolder) {
   Write-Output "Deleting old Install.wim..."
   ("Delete original install.wim file and replace with new") | Out-File -Append -FilePath $logfile
   Remove-Item -Force ($isoFolder + "sources\install.wim") -Recurse -ErrorAction SilentlyContinue >$null
}  
Rename-Item -Path ($isoFolder + "sources\install_patched.wim") -NewName "install.wim" >$null
################# Ending of install.wim patches ##################

################# Beginning of boot.wim patches ##################
Set-ItemProperty -Path ($isoFolder + "sources\boot.wim") -Name IsReadOnly -Value $false >$null
Write-Output "Mounting boot.wim image..." | green
("Mount Boot.wim file") | Out-File -Append -FilePath $logfile
Mount-WindowsImage -ImagePath ($isoFolder + "sources\boot.wim") -Path $bootImageFolder -Index 2 >$null

Write-Output "PATCH REGISTERY IN BOOT.WIM..."
("Registery pached in boot.wim file") | Out-File -Append -FilePath $logfile
reg load HKLM\bootwim_DEFAULT ($bootImageFolder + "Windows\System32\config\default") >$null
reg load HKLM\bootwim_NTUSER ($bootImageFolder + "Users\Default\ntuser.dat") >$null
reg load HKLM\bootwim_SYSTEM ($bootImageFolder + "Windows\System32\config\SYSTEM") >$null

# Applying following registry patches on the boot image:
# Bypassing system requirements
regedit /s ./tools/bootwim_patches.reg >$null
reg unload HKLM\bootwim_DEFAULT >$null
reg unload HKLM\bootwim_NTUSER >$null
reg unload HKLM\bootwim_SYSTEM >$null

#Unmount the boot.wim image
Write-Output "Unmounting boot.wim image..." | green
("Unmount Boot.wim file") | Out-File -Append -FilePath $logfile
Dismount-WindowsImage -Path $bootImageFolder -Save >$null

#Moving the wanted image index to a new image
Write-Output "Creating a clean boot.wim image without all unecessary indexes..."
("Prepare Boot.wim with correct new index") | Out-File -Append -FilePath $logfile
Export-WindowsImage -SourceImagePath ($isoFolder + "sources\boot.wim") -SourceIndex 2 -DestinationImagePath ($isoFolder + "sources\boot_patched.wim") -CompressionType max >$null

#Delete the old boot.wim and rename the new one
if (Test-Path -Path $isoFolder) {
   Write-Output "Deleting old boot.wim..."
   ("Delete original Boot.wim file and replace with new") | Out-File -Append -FilePath $logfile
   #takeown /f $isoFolder /r /d $yes >$null
   #icacls $isoFolder /grant ("$env:username"+":F") /T /C >$null
   Remove-Item -Force ($isoFolder + "sources\boot.wim") -Recurse -ErrorAction SilentlyContinue >$null
} 
Rename-Item -Path ($isoFolder + "sources\boot_patched.wim") -NewName "boot.wim" >$null
################# Ending of boot.wim patches ##################

#Copying the setup config file to the iso copy folder
[System.IO.File]::Copy((Get-ChildItem .\autounattend.xml).FullName, ($isoFolder + "autounattend.xml"), $true) >$null
("Copying  autounattend.xml to ISO...") | Out-File -Append -FilePath $logfile

#Building the new trimmed and patched iso file
Write-Output "Building the tiny11..."
("Writing new ISO...") | Out-File -Append -FilePath $logfile
.\oscdimg.exe -m -o -u2 -udfver102 -bootdata:("2#p0,e,b" + $isoFolder + "boot\etfsboot.com#pEF,e,b" + $isoFolder + "efi\microsoft\boot\efisys.bin") $isoFolder ($isotiny + "_tiny.iso") >$null
Write-Output "Removing work folders..."
Remove-Item $isoFolder -Force -Recurse -ErrorAction SilentlyContinue >$null
Remove-Item $installImageFolder -Force -Recurse -ErrorAction SilentlyContinue >$null
Remove-Item $bootImageFolder -Force -Recurse -ErrorAction SilentlyContinue >$null
("Remove temp folders...") | Out-File -Append -FilePath $logfile