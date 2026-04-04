# Start all AutoHotkey scripts from the startup folder
# This will launch all .ahk files in your shell:startup folder

Write-Host "Starting AutoHotkey scripts from startup folder..." -ForegroundColor Yellow

# Get the startup folder path
$startupFolder = [System.IO.Path]::Combine($env:USERPROFILE, "Documents\AHK\AHK Scripts") + "\"

Write-Host "Startup folder: $startupFolder" -ForegroundColor Gray

# Helper function to check if a process is already running
function IsProcessRunning {
    param($FilePath)
    $runningProcesses = Get-Process | Where-Object { $_.Path -eq $FilePath }
    return $runningProcesses.Count -gt 0
}

# Scripts to exclude from auto-start
$excludeScripts = @(
    "BlueToothToggle.ahk",
    "screenshot.ahk"
)

# Find all .ahk files and .lnk files that point to .ahk files
$ahkFiles = Get-ChildItem -Path $startupFolder -Filter "*.ahk" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notin $excludeScripts }
$shortcuts = Get-ChildItem -Path $startupFolder -Filter "*.lnk" -ErrorAction SilentlyContinue

# Start .ahk files directly
if ($ahkFiles) {
    foreach ($file in $ahkFiles) {
        if (IsProcessRunning -FilePath $file.FullName) {
            Write-Host "Already running: $($file.Name)" -ForegroundColor Yellow
        } else {
            Write-Host "Starting: $($file.Name)" -ForegroundColor Cyan
            Start-Process -FilePath $file.FullName
        }
    }
}

# Start .ahk and .exe files from shortcuts
if ($shortcuts) {
    $shell = New-Object -ComObject WScript.Shell
    foreach ($shortcut in $shortcuts) {
        $targetPath = $shell.CreateShortcut($shortcut.FullName).TargetPath
        if ($targetPath -like "*.ahk" -or $targetPath -like "*.exe") {
            if (Test-Path $targetPath) {
                if (IsProcessRunning -FilePath $targetPath) {
                    Write-Host "Already running: $($shortcut.Name) -> $([System.IO.Path]::GetFileName($targetPath))" -ForegroundColor Yellow
                } else {
                    Write-Host "Starting: $($shortcut.Name) -> $([System.IO.Path]::GetFileName($targetPath))" -ForegroundColor Cyan
                    Start-Process -FilePath $targetPath
                }
            } else {
                Write-Host "Target not found: $targetPath" -ForegroundColor Red
            }
        }
    }
}

if (-not $ahkFiles -and -not $shortcuts) {
    Write-Host "No AutoHotkey scripts found in startup folder." -ForegroundColor Gray
} else {
    Write-Host "All AutoHotkey scripts started." -ForegroundColor Green
}
