#Requires AutoHotkey >=v2.0
#SingleInstance Force

; Run as admin to work with elevated windows
if !A_IsAdmin {
    try Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

Run("ms-settings:bluetooth")
WinWaitActive("Settings")
Sleep(2000)
Send("{Tab}{Space}")
WinClose("A")