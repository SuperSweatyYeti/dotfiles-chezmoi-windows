#Requires AutoHotkey >=v2.0
#SingleInstance Force

; Run as admin to work with elevated windows
if !A_IsAdmin {
    try Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

!]:: Send("#^{Right}")   ; Alt+] — switch to right desktop

![:: Send("#^{Left}")    ; Alt+[ — switch to left desktop