# Check if Microsoft Defender is running
$defenderStatus = (Get-Service windefend).Status
if ($defenderStatus -eq "Running") {
    # Update Microsoft Defender signatures
    Update-MpSignature -Verbose
    # Run a quick antivirus scan
    Start-MpScan -ScanType QuickScan
} else {
    # Microsoft Defender is not running
    Write-Host "Microsoft Defender is not running."
    # Check if sophosinterceptxcli.exe exists in the default installation path
    $sophosPath = "C:\Program Files\Sophos\Endpoint Defense\sophosinterceptxcli.exe"
    if (Test-Path $sophosPath) {
      # Run a system scan with no user interface and verbose output
      & $sophosPath scan --noui --system
    }
    else {
      # Write an error message and suggest a third option
      Write-Host "Sophos not found"
      $MaintenancePath = Join-Path $env:SystemDrive "maintenance"
      if (!(Test-Path $MaintenancePath)) {
          New-Item -ItemType Directory -Force -Path $MaintenancePath
      }
      # Set the download URL and file path
      Write-Host "Downloading Norton Power Eraser"
      $DownloadUrl = "https://www.norton.com/npe_latest"
      $FilePath = Join-Path $MaintenancePath "NPE.exe"

      # Download Norton Power Eraser
      Invoke-WebRequest -Uri $DownloadUrl -OutFile $FilePath

      # Run Norton Power Eraser
      Write-Host "Running Norton Power Eraser"
      Start-Process -FilePath $FilePath
    }
}