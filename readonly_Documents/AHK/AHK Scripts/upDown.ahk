#Requires AutoHotkey >=2.0
#SingleInstance Force
; Up/Down Arrow Remapping Script
; - Ctrl+p sends Up Arrow
; - Ctrl+n sends Down Arrow

^p::Send "{Up}"
^n::Send "{Down}"