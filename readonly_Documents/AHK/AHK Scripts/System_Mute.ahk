#Requires AutoHotkey >=v2.0
#SingleInstance Force

; Toggle speakers + microphone mute with Ctrl+Alt+M
!^m::
{
    Send("{Volume_Mute}")
}

; Need version from laptop still