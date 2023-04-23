

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
New-Item -Path "$env:SystemDrive\maintenance\logs" -ItemType Directory 
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

Start-Process powershell.exe -Verb RunAs -ArgumentList "-command irm https://raw.githubusercontent.com/ChrisTitusTech/winutil/$BranchToUse/winget.ps1 | iex | Out-Host" -WindowStyle Normal

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
    0 { Write-Host "Yes"
        #irm christitus.com/win | iex
        Write-Host "Creating Restore Point in case something bad happens"
            Enable-ComputerRestore -Drive "$env:SystemDrive"
            Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"
            Write-Host "Checking if Git is Installed..."
            If (!(((gp HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Match "Git").Length -gt 0)) {
                Write-Host "Installing Git. Run script again after install."
                winget install git -e
                exit
        }
        cd $env:SystemDrive\maintenance
        rm -r -Force $env:SystemDrive\maintenance\yllapito
        git.exe clone https://github.com/kimostberg/yllapito.git
        .\yllapito\tweaks.ps1
        .\yllapito\SetServicesToManual.ps1
        .\yllapito\Update.ps1
        .\yllapito\DiskClean.ps1
        }
    1 { Write-Host "No - Exiting"
        exit
        }
}