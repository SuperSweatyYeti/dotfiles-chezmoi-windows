#Requires AutoHotkey >=v2.0
#SingleInstance Force

; Run as admin to work with elevated windows
if !A_IsAdmin {
    try Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

/*
    Volume control hotkeys
    Alt+/  = Volume Up (+2)       Alt+.  = Volume Down (-2)
    Shift+Alt+/ = Fast Up (+8)    Shift+Alt+. = Fast Down (-8)
*/

; Remove delay between key sends for responsiveness
SendMode("Input")

!/:: VolumeOSD(2)
!.:: VolumeOSD(-2)

+!/:: VolumeOSD(8)
+!.:: VolumeOSD(-8)

; ── OSD ──────────────────────────────────────────────

gFadeAlpha := 245

VolumeOSD(delta) {
    current := SoundGetVolume()
    newVal := current + delta
    if (newVal > 100)
        newVal := 100
    if (newVal < 0)
        newVal := 0
    SoundSetVolume(newVal)
    ShowOSD(Round(newVal))
}

FadeOSD() {
    SetTimer(DoFade, 30)
}

DoFade() {
    global gFadeAlpha

    gFadeAlpha -= 15
    if (gFadeAlpha <= 0) {
        SetTimer(DoFade, 0)
        gFadeAlpha := 245
        ShowOSD("")
        return
    }

    try {
        for hwnd in WinGetList("ahk_class AutoHotkeyGUI") {
            WinSetTransparent(gFadeAlpha, hwnd)
        }
    } catch {
        SetTimer(DoFade, 0)
        gFadeAlpha := 245
        ShowOSD("")
    }
}

ShowOSD(level) {
    static osd := ""
    static progressCtrl := ""
    static textCtrl := ""

    if (level = "") {
        if (osd) {
            try osd.Destroy()
            osd := ""
            progressCtrl := ""
            textCtrl := ""
        }
        return
    }

    if (osd) {
        try {
            SetTimer(DoFade, 0)
            global gFadeAlpha
            gFadeAlpha := 245
            WinSetTransparent(245, osd)
            textCtrl.Value := "🔊  Volume " . level . "%"
            progressCtrl.Value := level
            SetTimer(FadeOSD, -1500)
            return
        } catch {
            osd := ""
            progressCtrl := ""
            textCtrl := ""
        }
    }

    w := 300
    h := 85
    barW := 260
    barH := 16

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

    try isDark := !RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
    catch
        isDark := true

    if (isDark) {
        bgColor := "111111"
        trackColor := "333333"
        fontColor := "White"
    } else {
        bgColor := "F0F0F0"
        trackColor := "CCCCCC"
        fontColor := "000000"
    }

    osd.BackColor := bgColor

    accentRaw := RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\DWM", "AccentColor")
    r := accentRaw & 0xFF
    g := (accentRaw >> 8) & 0xFF
    b := (accentRaw >> 16) & 0xFF
    accentHex := Format("{:02X}{:02X}{:02X}", r, g, b)

    osd.SetFont("s14 c" . fontColor, "Segoe UI")
    textCtrl := osd.Add("Text", "x20 y12 w260 Center", "🔊  Volume " . level . "%")

    progressCtrl := osd.Add("Progress", "x20 y50 w" . barW . " h" . barH . " Background" . trackColor . " c" . accentHex . " Range0-100", level)

    osd.Show("x" . x . " y" . y . " w" . w . " h" . h . " NoActivate")

    WinGetPos(,, &winW, &winH, osd)
    hRgn := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", winW + 1, "Int", winH + 1, "Int", 20, "Int", 20, "Ptr")
    DllCall("SetWindowRgn", "Ptr", osd.Hwnd, "Ptr", hRgn, "Int", true)

    SetTimer(FadeOSD, -1500)
}