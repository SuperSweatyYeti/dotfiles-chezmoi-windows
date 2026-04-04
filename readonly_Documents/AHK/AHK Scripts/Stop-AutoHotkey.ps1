# Stop all AutoHotkey processes running from your AHK Scripts folder
# This will close all running scripts from <UserProfile>\Documents\AHK\AHK Scripts\

Write-Host "Stopping all AutoHotkey scripts from AHK Scripts folder..." -ForegroundColor Yellow

$ahkScriptsPath = [System.IO.Path]::Combine($env:USERPROFILE, "Documents\AHK\AHK Scripts") + "\"

$ahkProcesses = Get-Process | Where-Object { 
    $_.Path -and $_.Path -like "$ahkScriptsPath*"
}

if ($ahkProcesses) {
    $ahkProcesses | ForEach-Object {
        $scriptName = Split-Path $_.Path -Leaf
        Write-Host "Stopping: $scriptName (PID: $($_.Id))" -ForegroundColor Cyan
        Stop-Process -Id $_.Id -Force
    }
    Write-Host "All AutoHotkey scripts stopped." -ForegroundColor Green
} else {
    Write-Host "No AutoHotkey scripts found running from: $ahkScriptsPath" -ForegroundColor Gray
}
