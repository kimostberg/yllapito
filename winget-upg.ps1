
# Check if the script is running on PowerShell 7 or higher
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "This script requires PowerShell 7 or higher. Installing PowerShell 7 using winget..."
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Winget is not available. Please install it manually to proceed."
        exit
    }
    winget install --id Microsoft.Powershell --source winget
    Write-Host "PowerShell 7 installed. Please restart the script in PowerShell 7."
    exit
}

# Check if the Microsoft.WinGet.Client module is installed and up-to-date
if (Get-Module -ListAvailable -Name Microsoft.WinGet.Client) {
    Write-Host "Microsoft.WinGet.Client Module is installed."
    $moduleVersion = (Get-Module -Name Microsoft.WinGet.Client).Version
    if ($moduleVersion -lt [Version]"1.6.3133.0") {
        Write-Host "Updating Microsoft.WinGet.Client Module..."
        Update-Module -Name Microsoft.WinGet.Client -RequiredVersion 1.6.3133.0
    } else {
        Write-Host "Microsoft.WinGet.Client Module is up to date."
    }
} else {
    Write-Host "Microsoft.WinGet.Client Module is not installed. Installing..."
    Install-Module -Name Microsoft.WinGet.Client -RequiredVersion 1.6.3133.0 -Force
}

# Run the winget upgrade command to check for available updates
Write-Host "`nChecking for available package updates..."
winget upgrade -h --all

# Get the list of installed packages and identify those with available updates
$installed = Get-WinGetPackage -Source winget
$updatable = $installed | Where-Object IsUpdateAvailable | Select-Object -ExpandProperty Id

# If there are updatable packages, update them
if ($updatable) {
    Write-Host "`nUpdating available packages...`n"
    foreach ($packageId in $updatable) {
        Write-Host "Updating package: $packageId"
        winget update $packageId --accept-package-agreements --accept-source-agreements
        Write-Host ""
    }
} else {
    Write-Host "`nNo updates available for installed packages."
}