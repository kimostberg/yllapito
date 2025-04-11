## Set Updates to Recommended
Write-Host "Disabling driver offering through Windows Update..."
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Type DWord -Value 1
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -Type DWord -Value 0
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Type DWord -Value 1
Write-Host "Disabling Windows Update automatic restart..."
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Type DWord -Value 0
Write-Host "Disabled driver offering through Windows Update"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "BranchReadinessLevel" -Type DWord -Value 20
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferFeatureUpdatesPeriodInDays" -Type DWord -Value 365
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferQualityUpdatesPeriodInDays " -Type DWord -Value 4

Write-Host "================================="
Write-Host "-- Updates Set to Recommended ---"
Write-Host "================================="

# Check if chocolatey is installed and get its version
if ((Get-Command -Name choco -ErrorAction Ignore) -and ($chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion)) {
    Write-Output "Chocolatey Version $chocoVersion is already installed"
}else {
    Write-Output "Seems Chocolatey is not installed, installing now"
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    powershell choco feature enable -n allowGlobalConfirmation
}

    
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

Write-Host "Checking if Windows Update Module is installed."
if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
    Write-Host "Module exists"
    }
else {
    Write-Host "Module does not exist. Installing"
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Install-Module PSWindowsUpdate
    Add-WUServiceManager -MicrosoftUpdate
}

$WingetUpdates = "$env:SystemDrive\maintenance\logs\$env:computername-$(Get-Date -f yyyy-MM-dd_HH-mm)-WingetUpdates.log"
$ChocoUpdates ="$env:SystemDrive\maintenance\logs\$env:computername-$(Get-Date -f yyyy-MM-dd_HH-mm)-ChocoUpdates.log"
$MSUpdates = "$env:SystemDrive\maintenance\logs\$env:computername-$(Get-Date -f yyyy-MM-dd_HH-mm)-MSUpdates.log"

Write-Host "Updating Winget Programs"
Write-Host "Check log $WingetUpdates"
winget upgrade
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements | Out-File $WingetUpdates -Force
winget upgrade
#Write-Host "Updating Chocolatey Programs"
#Write-Host "Check log $ChocoUpdates"
#choco outdated
#choco upgrade all | Out-File $ChocoUpdates -Force
#choco outdated
Write-Host "Updating Windows" 
Write-Host "Check log $MSUpdates"
Get-WindowsUpdate
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll | Out-File $MSUpdates -Force
Get-WindowsUpdate