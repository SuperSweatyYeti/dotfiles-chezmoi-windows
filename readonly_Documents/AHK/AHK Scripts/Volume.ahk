/*
	Based on the example from: http://l.autohotkey.net/docs/commands/_If.htm
	parts "forked" from Update.ahk
	----------------------------------------
	This version, joedf, April 8th, 2013
	- Update  May  23rd, 2013 [r1] - Added Tooltip to display volume %
	- Update June   4th, 2013 [r2] - Added Volume OSD
	- Update June   6th, 2013 [r3] - Added Hotkeys & over_tray options, Suggested by DataLife
*/

	;_______[Settings]_______
		Volume_Delay:=1000
		BG_color=1A1A1A
		Text_color=FFFFFF
		Bar_color=666666
		Volume_OSD_Center:=1
		over_tray:=0
	;________________________
		
	;________[HOTKEYS]_______
			   vol_up = !/
			 vol_down = !.
		  vol_up_fast = +%vol_up%   ;shift + (vol_up) hotkey
		vol_down_fast = +%vol_down% ;shift + (vol_down) hotkey
	;________________________


;//////////////[Do not edit after this line]///////////////
#If % (over_tray) ? MouseIsOver("ahk_class Shell_TrayWnd") : "(1)"
	Hotkey, If, % (over_tray) ? MouseIsOver("ahk_class Shell_TrayWnd") : "(1)"
	Hotkey,%vol_up%,vol_up
	Hotkey,%vol_down%,vol_down
	Hotkey,%vol_up_fast%,vol_up_fast
	Hotkey,%vol_down_fast%,vol_down_fast
return
vol_up:
	Send {Volume_Up}
	
return
vol_up_fast:
	Send {Volume_Up 4}
	
return
vol_down:
	Send {Volume_Down}
	
return
vol_down_fast:
	Send {Volume_Down 4}
	
return



MouseIsOver(WinTitle) {
	MouseGetPos,,, Win
	return WinExist(WinTitle . " ahk_id " . Win)
}
 