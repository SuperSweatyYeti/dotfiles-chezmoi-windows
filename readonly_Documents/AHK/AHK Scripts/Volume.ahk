#Requires AutoHotkey >=v2.0
#SingleInstance Force

/*
    Volume control hotkeys
    Alt+/  = Volume Up       Alt+.  = Volume Down
    Shift+Alt+/ = Fast Up    Shift+Alt+. = Fast Down
*/

!/:: Send("{Volume_Up}")
!.:: Send("{Volume_Down}")
+!/:: Send("{Volume_Up 4}")
+!.:: Send("{Volume_Down 4}")
 