# This script checks if winget is installed and installs it if not
# It requires PowerShell 5.1 or higher and Windows 10 version 1809 or higher

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
New-Item -Path "$env:SystemDrive\maintenance\logs" -ItemType Directory -Force
Start-Transcript \maintenance\logs\$env:computername-$(Get-Date -f yyyy-MM-dd)-Yllapito.log -Append

# Check if winget is installed
Write-Host "Checking if Winget is Installed..." -NoNewline
if (Test-Path "$env:APPDATA\Microsoft\WindowsApps\winget.exe" -ErrorAction SilentlyContinue) {
    #Checks if winget executable exists and if the Windows Version is 1809 or higher
    Write-Host "Winget Already Installed"
}
else {
    #Gets the computer's information
    $ComputerInfo = Get-ComputerInfo -ErrorAction Stop

    #Gets the Windows Edition
    $OSName = if ($ComputerInfo.OSName) {
$ComputerInfo.OSName
    }else {
$ComputerInfo.WindowsProductName
    }

    if (((($OSName.IndexOf("LTSC")) -ne -1) -or ($OSName.IndexOf("Server") -ne -1)) -and (($ComputerInfo.WindowsVersion) -ge "1809")) {

Write-Host "Running Alternative Installer for LTSC/Server Editions" -NoNewline

# Switching to winget-install from PSGallery from asheroto
# Source: https://github.com/asheroto/winget-installer

$process = Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile","-command irm https://raw.githubusercontent.com/ChrisTitusTech/winutil/$BranchToUse/winget.ps1 | iex | Out-Host" -WindowStyle Normal -PassThru
Wait-Process -InputObject $process

    }
    elseif (((Get-ComputerInfo).WindowsVersion) -lt "1809") {
#Checks if Windows Version is too old for winget
Write-Host "Winget is not supported on this version of Windows (Pre-1809)"
    }
    else {
#Installing Winget from the Microsoft Store
Write-Host "Winget not found, installing it now." -NoNewline
$process = Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget" -PassThru
Wait-Process -InputObject $process
Write-Host "Winget Installed"
    }
} 

# Write a block comment to describe the purpose and usage of this script
<#
    This script checks if CrystalDiskInfo is installed and installs it if not.
    Then it runs CrystalDiskInfo and prompts the user to check if the disk is OK.
    If the user answers yes, it performs some maintenance tasks using Git and other scripts.
    If the user answers no, it exits the script.
#>

# Use full cmdlet names and named parameters
Write-Output "Checking if CrystalDiskInfo is Installed..."
If (!(((Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Match "CrystalDiskInfo").Length -gt 0)) {
    Write-Output "Installing CrystalDiskInfo."
    winget install crystaldiskinfo -e
}
Start-Process "$env:SystemDrive\Program Files\CrystalDiskInfo\DiskInfo64.exe"

# PromptForChoice Args
$Title = "Is disk OK?"
$Prompt = "Wait that CrystalDiskInfo shows result. Is disk OK? Enter your choice"
$Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes", "&No")
$Default = 1

# Prompt for the choice
$Choice = $host.UI.PromptForChoice($Title, $Prompt, $Choices, $Default)

# Action based on the choice
switch($Choice)
{
    0 { 
        Write-Output "Yes"
        #irm christitus.com/win | iex
        Write-Output "Creating Restore Point in case something bad happens"
        Enable-ComputerRestore -Drive "$env:SystemDrive"
        Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"
        Write-Output "Checking if Git is Installed..."
        If (!(((Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Match "Git").Length -gt 0)) {
            Write-Output "Installing Git. Run script again after install."
            winget install git -e
            Write-Output "Git Installed. Script will exit now. Please run script again to continue."
            Read-Host -Prompt "Press any key to continue"
            exit
        }
        # Use consistent indentation and spacing
        cd $env:SystemDrive\maintenance
        Remove-Item -Path $env:SystemDrive\maintenance\yllapito -Recurse -Force
        git.exe clone https://github.com/kimostberg/yllapito.git
        .\yllapito\Update.ps1
        .\yllapito\AntiVirus.ps1
        .\yllapito\DiskClean.ps1
        .\yllapito\tweaks.ps1
        .\yllapito\SetServicesToManual.ps1
    }
    1 { 
        Write-Output "No - Exiting"
        exit
    }
}