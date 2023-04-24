# Check if Microsoft Defender is running
$defenderStatus = (Get-Service windefend).Status
if ($defenderStatus -eq "Running") {
    # Update Microsoft Defender signatures
    Update-MpSignature
    # Run a full antivirus scan
    Start-MpScan -ScanType FullScan
} else {
    # Microsoft Defender is not running
    Write-Host "Microsoft Defender is not running."
}

# Check if sophosinterceptxcli.exe exists in the default installation path
if (Test-Path "C:\Program Files\Sophos\Endpoint Defense\sophosinterceptxcli.exe") {
  # Run a system scan with no user interface and verbose output
  & "C:\Program Files\Sophos\Endpoint Defense\sophosinterceptxcli.exe" scan --noui --verbose --system
}
else {
  # Write an error message
  Write-Host "sophosinterceptxcli.exe not found"
}