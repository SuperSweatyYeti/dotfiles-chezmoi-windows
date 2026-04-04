#Requires AutoHotkey >=2.0
#SingleInstance Force

; Run as admin to work with elevated windows
if !A_IsAdmin {
    try Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

; Up/Down Arrow Remapping Script
; - Ctrl+p sends Up Arrow
; - Ctrl+n sends Down Arrow

^p::Send "{Up}"
^n::Send "{Down}"