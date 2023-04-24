# Check if Microsoft Defender is running
$defenderStatus = (Get-Service windefend).Status
if ($defenderStatus -eq "Running") {
    # Update Microsoft Defender signatures
    Update-MpSignature -Verbose
    # Run a quick antivirus scan
    Start-MpScan -ScanType QuickScan -WhatIf
} else {
    # Microsoft Defender is not running
    Write-Warning "Microsoft Defender is not running."
    # Check if sophosinterceptxcli.exe exists in the default installation path
    $sophosPath = "C:\Program Files\Sophos\Endpoint Defense\sophosinterceptxcli.exe"
    if (Test-Path $sophosPath) {
      # Run a system scan with no user interface and verbose output
      & $sophosPath scan --noui --system
    }
    else {
      # Write an error message and suggest a third option
      Write-Error "Sophos not found"
      Write-Host "You may want to try another antivirus software, such as McAfee or Norton."
    }
}