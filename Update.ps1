﻿## Set Updates to Recommended
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

    
Start-Process powershell.exe -Verb RunAs -ArgumentList "-command irm https://raw.githubusercontent.com/kimostberg/yllapito/main/Winget.ps1 | iex | Out-Host" -WindowStyle Normal -ErrorAction Stop

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

Write-Host "Updating Winget Programs"
Write-Host "Check log $PWD\logs\$env:computername-$(Get-Date -f yyyy-MM-dd_HH-mm)-WingetUpdates.log"
winget upgrade --all --silent | Out-File "$PWD\logs\$env:computername-$(Get-Date -f yyyy-MM-dd_HH-mm)-WingetUpdates.log" -Force
Write-Host "Updating Chocolatey Programs"
Write-Host "Check log $PWD\logs\$env:computername-$(Get-Date -f yyyy-MM-dd_HH-mm)-ChocoUpdates.log"
choco upgrade all | Out-File "$PWD\logs\$env:computername-$(Get-Date -f yyyy-MM-dd_HH-mm)-ChocoUpdates.log" -Force
Write-Host "Updating Windows" 
Write-Host "Check log $PWD\logs\$env:computername-$(Get-Date -f yyyy-MM-dd_HH-mm)-MSUpdates.log"
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll | Out-File "$PWD\logs\$env:computername-$(Get-Date -f yyyy-MM-dd_HH-mm)-MSUpdates.log" -Force