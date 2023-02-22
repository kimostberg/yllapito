Start-Transcript .\logs\$env:computername-$(Get-Date -f yyyy-MM-dd)-Winutil.log -Append

If (!(((gp HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Match "CrystalDiskInfo").Length -gt 0)) {
    winget install crystaldiskinfo -e
}
Start-Process 'C:\Program Files\CrystalDiskInfo\DiskInfo64.exe'
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
        .\tweaks.ps1
        .\SetServicesToManual.ps1
        .\Update.ps1
        .\DiskClean.ps1

        }
    1 { Write-Host "No - Exiting"
        exit
        }
}