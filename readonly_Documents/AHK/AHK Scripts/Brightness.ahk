#Requires AutoHotkey >=v2.0
#SingleInstance Force

; Run as admin to work with elevated windows
if !A_IsAdmin {
    try Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

gFadeAlpha := 245

BrightnessOSD(delta) {
    wmi := ComObjGet("winmgmts:\\.\root\WMI")

    current := 0
    for item in wmi.ExecQuery("SELECT * FROM WmiMonitorBrightness") {
        current := item.CurrentBrightness
    }

    newVal := current + delta
    if (newVal > 100)
        newVal := 100
    if (newVal < 0)
        newVal := 0

    for item in wmi.ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods") {
        item.WmiSetBrightness(1, newVal)
    }

    ShowOSD(newVal)
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

    ; Apply to OSD window
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

    ; Called with "" to close/reset
    if (level = "") {
        if (osd) {
            try osd.Destroy()
            osd := ""
            progressCtrl := ""
            textCtrl := ""
        }
        return
    }

    ; If OSD already exists, just update the controls and reset the timer
    if (osd) {
        try {
            ; Cancel any in-progress fade and restore opacity
            SetTimer(DoFade, 0)
            global gFadeAlpha
            gFadeAlpha := 245
            WinSetTransparent(245, osd)
            textCtrl.Value := "☀  Brightness " . level . "%"
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

    ; Detect light/dark theme (0 = dark, 1 = light)
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

    ; Get Windows accent color from registry (ABGR format)
    accentRaw := RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\DWM", "AccentColor")
    ; Extract RGB components (stored as 0xAABBGGRR)
    r := accentRaw & 0xFF
    g := (accentRaw >> 8) & 0xFF
    b := (accentRaw >> 16) & 0xFF
    accentHex := Format("{:02X}{:02X}{:02X}", r, g, b)

    osd.SetFont("s14 c" . fontColor, "Segoe UI")
    textCtrl := osd.Add("Text", "x20 y12 w260 Center", "☀  Brightness " . level . "%")

    ; Progress bar
    progressCtrl := osd.Add("Progress", "x20 y50 w" . barW . " h" . barH . " Background" . trackColor . " c" . accentHex . " Range0-100", level)

    osd.Show("x" . x . " y" . y . " w" . w . " h" . h . " NoActivate")

    ; Round the OSD corners
    WinGetPos(,, &winW, &winH, osd)
    hRgn := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", winW + 1, "Int", winH + 1, "Int", 20, "Int", 20, "Ptr")
    DllCall("SetWindowRgn", "Ptr", osd.Hwnd, "Ptr", hRgn, "Int", true)

    ; Auto-hide with fade after 1.5 seconds
    SetTimer(FadeOSD, -1500)
}

!'::BrightnessOSD(5)
!;::BrightnessOSD(-5)