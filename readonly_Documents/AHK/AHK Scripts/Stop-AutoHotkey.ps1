# Stop all AutoHotkey processes running from your AHK Scripts folder
# This will close all running scripts from <UserProfile>\Documents\AHK\AHK Scripts\

Write-Host "Stopping all AutoHotkey scripts from AHK Scripts folder..." -ForegroundColor Yellow

$ahkScriptsPath = [System.IO.Path]::Combine($env:USERPROFILE, "Documents\AHK\AHK Scripts") + "\"

$ahkProcesses = Get-CimInstance Win32_Process | Where-Object {
    $_.CommandLine -and $_.CommandLine -like "*$ahkScriptsPath*"
}

if ($ahkProcesses) {
    $ahkProcesses | ForEach-Object {
        $scriptName = if ($_.CommandLine -match '([^\\]+\.ahk)') { $Matches[1] } else { $_.Name }
        Write-Host "Stopping: $scriptName (PID: $($_.ProcessId))" -ForegroundColor Cyan
        Stop-Process -Id $_.ProcessId -Force
    }
    Write-Host "All AutoHotkey scripts stopped." -ForegroundColor Green
} else {
    Write-Host "No AutoHotkey scripts found running from: $ahkScriptsPath" -ForegroundColor Gray
}
