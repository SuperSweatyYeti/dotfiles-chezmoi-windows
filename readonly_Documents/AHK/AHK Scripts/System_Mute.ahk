#Requires AutoHotkey >=v2.0
#SingleInstance Force

gFadeAlpha := 245

; Toggle with ctrl + alt + m
!^m::
{
	speakerMuted := GetMuteState(0)  ; eRender
	micMuted := GetMuteState(1)      ; eCapture

	if (speakerMuted && micMuted) {
		; Both muted → unmute both
		SetMuteState(0, false)
		SetMuteState(1, false)
		ShowMuteOSD(false)
	} else {
		; Either is unmuted → mute both
		SetMuteState(0, true)
		SetMuteState(1, true)
		ShowMuteOSD(true)
	}
}

GetEndpointVolume(dataFlow) {
	devEnum := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}"
		, "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
	ComCall(4, devEnum, "UInt", dataFlow, "UInt", 0, "Ptr*", &device := 0)
	iid := Buffer(16)
	DllCall("ole32\CLSIDFromString", "Str", "{5CDF2C82-841E-4546-9722-0CF74078229A}", "Ptr", iid)
	ComCall(3, device, "Ptr", iid, "UInt", 23, "Ptr", 0, "Ptr*", &epVol := 0)
	ObjRelease(device)
	return epVol
}

GetMuteState(dataFlow) {
	epVol := GetEndpointVolume(dataFlow)
	ComCall(15, epVol, "Int*", &muted := 0)
	ObjRelease(epVol)
	return muted
}

SetMuteState(dataFlow, mute) {
	epVol := GetEndpointVolume(dataFlow)
	ComCall(14, epVol, "Int", mute, "Ptr", 0)
	ObjRelease(epVol)
}

; ── OSD ──────────────────────────────────────────────

FadeOSD() {
	SetTimer(DoFade, 30)
}

DoFade() {
	global gFadeAlpha

	gFadeAlpha -= 15
	if (gFadeAlpha <= 0) {
		SetTimer(DoFade, 0)
		gFadeAlpha := 245
		ShowMuteOSD("")
		return
	}

	try {
		for hwnd in WinGetList("ahk_class AutoHotkeyGUI") {
			WinSetTransparent(gFadeAlpha, hwnd)
		}
	} catch {
		SetTimer(DoFade, 0)
		gFadeAlpha := 245
		ShowMuteOSD("")
	}
}

ShowMuteOSD(state) {
	static osd := ""
	static textCtrl := ""
	static iconCtrl := ""

	; Called with "" to close/reset
	if (state = "") {
		if (osd) {
			try osd.Destroy()
			osd := ""
			textCtrl := ""
			iconCtrl := ""
		}
		return
	}

	label := state ? "🔇  🎙️✕" : "🔊  🎙️"

	; If OSD already exists, update and reset timer
	if (osd) {
		try {
			SetTimer(DoFade, 0)
			global gFadeAlpha
			gFadeAlpha := 245
			WinSetTransparent(245, osd)
			textCtrl.Value := label
			SetTimer(FadeOSD, -1500)
			return
		} catch {
			osd := ""
			textCtrl := ""
			iconCtrl := ""
		}
	}

	w := 140
	h := 60

	CoordMode("Mouse", "Screen")
	MouseGetPos(&mx, &my)
	monCount := MonitorGetCount()
	monIdx := 1
	loop monCount {
		MonitorGet(A_Index, &l, &t, &r, &b)
		if (mx >= l && mx < r && my >= t && my < b) {
			monIdx := A_Index
			break
		}
	}

	MonitorGetWorkArea(monIdx, &mL, &mT, &mR, &mB)
	x := mL + (mR - mL - w) // 2
	y := mB - h - 60

	osd := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
	WinSetTransparent(245, osd)

	; Detect light/dark theme
	try isDark := !RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
	catch
		isDark := true

	if (isDark) {
		bgColor := "111111"
		fontColor := "White"
	} else {
		bgColor := "F0F0F0"
		fontColor := "000000"
	}

	osd.BackColor := bgColor
	osd.SetFont("s22 c" . fontColor, "Segoe UI")
	textCtrl := osd.Add("Text", "x0 y10 w140 Center", label)

	osd.Show("x" . x . " y" . y . " w" . w . " h" . h . " NoActivate")

	; Round corners
	WinGetPos(,, &winW, &winH, osd)
	hRgn := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", winW + 1, "Int", winH + 1, "Int", 20, "Int", 20, "Ptr")
	DllCall("SetWindowRgn", "Ptr", osd.Hwnd, "Ptr", hRgn, "Int", true)

	SetTimer(FadeOSD, -1500)
}