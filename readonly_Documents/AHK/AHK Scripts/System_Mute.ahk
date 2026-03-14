#NoEnv ; Recommended for Performance and compat with future AHK releases
SendMode Input ; Recommended for new scripts
SetWorkingDir %A_ScriptDir%

; Toggle with ctrl + alt + m
!^m::

	Send {Volume_Mute}
	Run nircmd.exe mutesysvolume 2 microphone
	Return