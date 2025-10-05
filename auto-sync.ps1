# Auto-sync without commits
# Run this script and it will watch for file changes and sync automatically

$sourcePath = "D:\Development\IsKeyDepleted"
$targetPath = "D:\WoW\Interface\AddOns\IsKeyDepleted"

Write-Host "Auto-sync started..."
Write-Host "Source: $sourcePath"
Write-Host "Target: $targetPath"
Write-Host "Press Ctrl+C to stop"
Write-Host ""

# Create target directory if it doesn't exist
if (!(Test-Path $targetPath)) {
    New-Item -ItemType Directory -Path $targetPath -Force
}

# Function to sync files
function Sync-Files {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Syncing files..."
    Copy-Item "$sourcePath\*" $targetPath -Recurse -Force
}

# Initial sync
Sync-Files

# Watch for changes every 2 seconds
while ($true) {
    Start-Sleep -Seconds 2
    Sync-Files
}
