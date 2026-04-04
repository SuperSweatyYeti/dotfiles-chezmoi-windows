#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.

; Run as admin to work with elevated windows
if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

#W::Run, "C:\Users\Andre\Documents\AHK Scripts\MinicapScreenshot\MiniCap.exe" -clipimage -captureregselect -save "C:\Users\Andre\Desktop\Screenshots\$appname$$uniquenum$_$date$.jpg" -exit

#Q::Run, "C:\Users\Andre\Documents\AHK Scripts\MinicapScreenshot\MiniCap.exe" -clipimage -capturescreen  -save "C:\Users\Andre\Desktop\Screenshots\$appname$$uniquenum$_$date$.jpg" -exit

!#Q::Run, "C:\Users\Andre\Documents\AHK Scripts\MinicapScreenshot\MiniCap.exe" -clipimage -scrollcap  -save "C:\Users\Andre\Desktop\Screenshots\$appname$$uniquenum$_$date$.jpg" -exit
