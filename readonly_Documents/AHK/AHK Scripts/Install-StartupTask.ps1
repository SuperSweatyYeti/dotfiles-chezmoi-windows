# Install-StartupTask.ps1
# Creates a Windows Task Scheduler task that launches Start-AutoHotkey.ps1
# as admin at logon — WITHOUT a UAC prompt.
#
# Run this script ONCE as administrator. After that, your AHK scripts
# will start elevated automatically at every logon with no UAC popup.

$taskName = "StartAutoHotkeyScriptsElevated"
$scriptPath = Join-Path $PSScriptRoot "Start-AutoHotkey.ps1"

# Prefer pwsh (PowerShell 7+), fall back to powershell.exe (Windows PowerShell 5.1)
$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }

# Must run as admin to create the task
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevating to administrator..." -ForegroundColor Yellow
    Start-Process -FilePath $psExe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Remove existing task if present
$existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Removing existing task '$taskName'..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Build the task
$action = New-ScheduledTaskAction `
    -Execute $psExe `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`"" `
    -WorkingDirectory $PSScriptRoot

$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -RunLevel Highest `
    -LogonType Interactive

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Seconds 0)

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description "Launches AutoHotkey scripts as admin at logon (no UAC prompt)" | Out-Null

Write-Host ""
Write-Host "Task '$taskName' created successfully." -ForegroundColor Green
Write-Host "Your AHK scripts will now start elevated at logon with no UAC prompt." -ForegroundColor Green
Write-Host ""
Write-Host "To remove later:  Unregister-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
Write-Host "To run now:       Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
