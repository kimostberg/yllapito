Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
$folderPath = "$env:SystemDrive\maintenance\logs"
if (!(Test-Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory
} 
Start-Transcript \maintenance\logs\$env:computername-$(Get-Date -f yyyy-MM-dd)-Yllapito.log -Append

# Check if winget is installed
Write-Host "Checking if Winget is Installed..."
if (Test-Path ~\AppData\Local\Microsoft\WindowsApps\winget.exe) {
    #Checks if winget executable exists and if the Windows Version is 1809 or higher
    Write-Host "Winget Already Installed"
}
else {
    #Gets the computer's information
    $ComputerInfo = Get-ComputerInfo

    #Gets the Windows Edition
    $OSName = if ($ComputerInfo.OSName) {
$ComputerInfo.OSName
    }else {
$ComputerInfo.WindowsProductName
    }

    if (((($OSName.IndexOf("LTSC")) -ne -1) -or ($OSName.IndexOf("Server") -ne -1)) -and (($ComputerInfo.WindowsVersion) -ge "1809")) {

Write-Host "Running Alternative Installer for LTSC/Server Editions"

# Switching to winget-install from PSGallery from asheroto
# Source: https://github.com/asheroto/winget-installer

Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Script -Name winget-install -Force
winget-install.ps1
Write-Host "WinGet Installed. Script will exit now. Please run script again to continue."
Read-Host -Prompt "Press any key to continue"
exit
    }
    elseif (((Get-ComputerInfo).WindowsVersion) -lt "1809") {
#Checks if Windows Version is too old for winget
Write-Host "Winget is not supported on this version of Windows (Pre-1809)"
    }
    else {
#Installing Winget from the Microsoft Store
Write-Host "Winget not found, installing it now."
Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget"
$nid = (Get-Process AppInstaller).Id
Wait-Process -Id $nid
Write-Host "Winget Installed"
    }
} 

Write-Host "Checking if CrystalDiskInfo is Installed..."
If (!(((gp HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Match "CrystalDiskInfo").Length -gt 0)) {
    Write-Host "Installing CrystalDiskInfo."
    winget install CrystalDewWorld.CrystalDiskInfo -e -s winget
}

$diskInfoExe = "$env:SystemDrive\Program Files\CrystalDiskInfo\DiskInfo64.exe"
$diskInfoTxt = "$env:SystemDrive\Program Files\CrystalDiskInfo\diskinfo.txt"

# Remove any stale result file so we know a fresh one was actually written
if (Test-Path $diskInfoTxt) {
    Remove-Item $diskInfoTxt -Force
}

# Run CrystalDiskInfo with /copyexit parameter and actually wait for it to exit
Start-Process -FilePath $diskInfoExe -ArgumentList "/copyexit" -Wait

# Belt-and-suspenders: poll for the output file to appear (and stop growing/being locked)
# in case CrystalDiskInfo relaunches itself and the -Wait above returns early.
$timeoutSeconds = 60
$elapsed = 0
$pollInterval = 1

while (-not (Test-Path $diskInfoTxt) -and $elapsed -lt $timeoutSeconds) {
    Start-Sleep -Seconds $pollInterval
    $elapsed += $pollInterval
}

if (-not (Test-Path $diskInfoTxt)) {
    Write-Warning "diskinfo.txt was not created after waiting $timeoutSeconds seconds. CrystalDiskInfo may have failed to run."
    Stop-Transcript
    break
}

# Make sure the file is done being written: wait until the file handle is no
# longer locked by another process (CrystalDiskInfo has fully released it).
$fileReady = $false
$elapsed = 0
while (-not $fileReady -and $elapsed -lt $timeoutSeconds) {
    try {
        $stream = [System.IO.File]::Open($diskInfoTxt, 'Open', 'Read', 'None')
        $stream.Close()
        $fileReady = $true
    } catch {
        Start-Sleep -Seconds $pollInterval
        $elapsed += $pollInterval
    }
}

if (-not $fileReady) {
    Write-Warning "diskinfo.txt is still locked after waiting $timeoutSeconds seconds. Continuing anyway, but results may be incomplete."
}

notepad $diskInfoTxt

# Read diskinfo.txt
$diskInfo = Get-Content "$env:SystemDrive\Program Files\CrystalDiskInfo\diskinfo.txt" -Raw
$diskInfo = $diskInfo -split "`r?`n"

# Get Health Status and Drive Letter
$healthStatus = $diskInfo | Where-Object { $_ -match "Health Status :" }
$driveLetter = $diskInfo | Where-Object { $_ -match "Drive Letter :" }

# Print summary
Write-Output "Summary:"
for ($i = 0; $i -lt $driveLetter.Count; $i++) {
    Write-Output $driveLetter[$i]
    Write-Output $healthStatus[$i]
}

# Check if all drives health is good
if ($diskInfo -match "Health Status : Good" -and !($diskInfo -match "Health Status : (?!Good)")) {
    Write-Output "All drives health is good"
} elseif ($diskInfo -match "Virtual Disk") {
    Write-Output "Virtual Disk found. Continuing with maintenance tasks."
} else {
    Write-Warning "Not all drives health is good. Check $destinationPath"
    $continue = Read-Host -Prompt "Do you want to continue with maintenance tasks even if the disk is not healthy? (y/n)"
    if ($continue -ne "y") {
        Write-Host "Script will exit now."
        Stop-Transcript
        break
    }
}

# Set source and destination paths
$sourcePath = "$env:SystemDrive\Program Files\CrystalDiskInfo\diskinfo.txt"
$destinationPath = "$env:SystemDrive\maintenance\logs\$env:computername-$(Get-Date -f yyyy-MM-dd)-diskinfo.log"
Start-Sleep -Seconds 10
# Copy diskinfo.txt to new location with specific file name format
Copy-Item $sourcePath $destinationPath

# Delete original diskinfo.txt file
Remove-Item $sourcePath

Write-Host "Creating Restore Point in case something bad happens"
Enable-ComputerRestore -Drive "$env:SystemDrive"
Checkpoint-Computer -Description "Before Maintenance" -RestorePointType "MODIFY_SETTINGS"
Write-Host "Checking if Git is Installed..."
If (!(((gp HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Match "Git").Length -gt 0)) {
    Write-Host "Installing Git. Run script again after install."
    winget install git -e -s winget
    Write-Host "Git Installed. Script will exit now. Please run script again to continue."
    Read-Host -Prompt "Press any key to continue"
    Stop-Transcript
    exit
}
$yllapitoPath = "$env:SystemDrive\maintenance\scripts"
if (Test-Path $yllapitoPath) {
    cd $yllapitoPath
    git.exe pull
} else {
    cd $env:SystemDrive\maintenance
    git.exe clone https://github.com/kimostberg/yllapito.git $yllapitoPath
    git config --global --add safe.directory $yllapitoPath
}

$scripts = @(
    "Update.ps1",
    "AntiVirus.ps1",
    "tweaks.ps1",
    "SetServicesToManual.ps1",
    "DiskClean.ps1" #,
#    "SendLogs.ps1"
)

foreach ($script in $scripts) {
    $scriptPath = Join-Path $yllapitoPath $script
    if (Test-Path $scriptPath) {
        & $scriptPath
    }
}
Stop-Transcript
