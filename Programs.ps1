$wingetinstall = 
"Brave.Brave",
"Google.Chrome",
"Mozilla.Firefox",
"OpenWhisperSystems.Signal",
"WhatsApp.WhatsApp",
"Zoom.Zoom",
"Foxit.FoxitReader",
"TheDocumentFoundation.LibreOffice",
"RustDesk.RustDesk",
"Microsoft.PowerToys",
"File-New-Project.EarTrumpet",
"GIMP.GIMP",
"DuongDieuPhap.ImageGlass",
"ShareX.ShareX",
"VideoLAN.VLC",
"7zip.7zip",
"voidtools.Everything",
"stnkl.EverythingToolbar.Beta",
"Malwarebytes.Malwarebytes",
"TeamViewer.TeamViewer",
"AntibodySoftware.WizTree",
#"",
#"",
"ALCPU.CoreTemp"

# Install all winget programs in new window
        #$wingetinstall.ToArray()
        # Define Output variable
        $wingetResult = New-Object System.Collections.Generic.List[System.Object]
        foreach ( $node in $wingetinstall ) {
            try {
                Start-Process powershell.exe -Verb RunAs -ArgumentList "-command Start-Transcript $PWD\logs\winget-install-$node.log -Append; winget install -e --accept-source-agreements --accept-package-agreements --silent $node | Out-Host" -WindowStyle Normal
                $wingetResult.Add("$node`n")
                Start-Sleep -s 6
                Wait-Process winget -Timeout 90 -ErrorAction SilentlyContinue
            }
            catch [System.InvalidOperationException] {
                Write-Warning "Allow Yes on User Access Control to Install"
            }
            catch {
                Write-Error $_.Exception
            }
        }
        $wingetResult.ToArray()
        $wingetResult | ForEach-Object { $_ } | Out-Host
        
        if ($wingetResult -ne "") {
            $Messageboxbody = "Installed Programs `n$($wingetResult)"
        }
        else {
            $Messageboxbody = "No Program(s) are installed"
        }

        Write-Host "================================="
        Write-Host "---  Installs are Finished    ---"
        Write-Host "================================="