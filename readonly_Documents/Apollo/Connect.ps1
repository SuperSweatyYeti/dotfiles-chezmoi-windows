# Disables the PRIMARY monitor if more than 1 display is connected
$tool = "C:\Users\Andre\Documents\Apollo\MultiMonitorTool.exe"

# Wait for 
Start-Sleep -Seconds 5
# Count active displays
$activeCount = (Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams |
  Where-Object { $_.Active -eq $true }).Count

if ($activeCount -gt 1) {
    # Disable primary monitor (commonly DISPLAY1, but confirm from monitors.csv)
    & $tool /disable "\\.\DISPLAY1"
}