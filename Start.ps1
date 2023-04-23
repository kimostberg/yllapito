
# test
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
New-Item -Path "$env:SystemDrive\maintenance\logs" -ItemType Directory 
Start-Transcript \maintenance\logs\$env:computername-$(Get-Date -f yyyy-MM-dd)-Yllapito.log -Append

Start-Process powershell.exe -Verb RunAs -ArgumentList "-command irm https://raw.githubusercontent.com/kimostberg/yllapito/main/Winget.ps1 | iex | Out-Host" -WindowStyle Normal -ErrorAction Stop


If (!(((gp HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Match "CrystalDiskInfo").Length -gt 0)) {
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
        If (!(((gp HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Match "Git").Length -gt 0)) {
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