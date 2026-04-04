#Requires AutoHotkey >=2.0
#SingleInstance Force

; Run as admin to work with elevated windows
if !A_IsAdmin {
    try Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

; Media pause / play
; RightAlt + p
; Media stop  /stop
>!p:: Media_Play_Pause
>!o:: Media_Stop
