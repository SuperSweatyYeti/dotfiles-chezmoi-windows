#Requires AutoHotkey >=2.0
#SingleInstance Force

; Run as admin to work with elevated windows
if !A_IsAdmin {
    try Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

SendMode "Input"
SetWorkingDir A_ScriptDir

; =============================================
; CapsLock Remapping Script v2.0
; - Remaps CapsLock to Control with reliable key handling
; - Use Ctrl+` to toggle CapsLock state
; - Use Ctrl+1 to toggle the entire remapping on/off
; - Emergency cleanup: Ctrl+Shift+Esc
; =============================================

; ====== Global State ======
global isRemapEnabled := true
global ctrlPressed := false  ; Track Ctrl state to prevent stuck keys

; ====== Core Remapping Logic ======

; Primary CapsLock handler - converts to Ctrl
$CapsLock:: {
    global ctrlPressed, isRemapEnabled
    
    if (!isRemapEnabled) {
        ; When disabled, let CapsLock work normally
        SetCapsLockState !GetKeyState("CapsLock", "T")
        return
    }
    
    ; Prevent CapsLock from toggling
    SetCapsLockState "AlwaysOff"
    
    ; Send Ctrl down and track state
    if (!ctrlPressed) {
        Send "{Ctrl down}"
        ctrlPressed := true
    }
}

; CapsLock release handler
$CapsLock up:: {
    global ctrlPressed, isRemapEnabled
    
    if (!isRemapEnabled) {
        return
    }
    
    ; Release Ctrl and update state
    if (ctrlPressed) {
        Send "{Ctrl up}"
        ctrlPressed := false
    }
}

; ====== User Controls ======

; Ctrl+` - Toggle CapsLock state (when remapping is enabled)
^`:: {
    global isRemapEnabled
    
    if (!isRemapEnabled) {
        ShowOSD("CapsLock State", "⚠ Remapping Disabled")
        return
    }
    
    ; Toggle CapsLock state
    newState := !GetKeyState("CapsLock", "T")
    SetCapsLockState newState
    
    ShowOSD("CapsLock", (newState ? "✓ ON" : "✗ OFF"))
}

; Ctrl+1 - Toggle entire remapping on/off
^1:: {
    global isRemapEnabled
    
    ; Clean up any stuck keys first
    CleanupKeys()
    
    ; Toggle remapping state
    isRemapEnabled := !isRemapEnabled
    
    ; Update CapsLock behavior
    if (isRemapEnabled) {
        SetCapsLockState "AlwaysOff"
        ShowOSD("CapsLock → Ctrl", "✓ ENABLED")
    } else {
        SetCapsLockState "Off"
        ShowOSD("CapsLock → Ctrl", "✗ DISABLED")
    }
}

; Ctrl+Shift+Esc - Emergency cleanup
^+Esc:: {
    CleanupKeys()
    ShowOSD("Emergency Cleanup", "✓ Complete")
}

; ====== Helper Functions ======

; Release all potentially stuck modifier keys
CleanupKeys() {
    global ctrlPressed
    
    Send "{Ctrl up}"
    Send "{Shift up}"
    Send "{Alt up}"
    Send "{LWin up}"
    
    ctrlPressed := false
}

; Global OSD state
gFadeAlpha := 245

; Show OSD with status message
ShowOSD(title, status, duration := 1500) {
    static osd := ""
    static textCtrl := ""
    static statusCtrl := ""

    ; Called with "" to close/reset
    if (title = "") {
        if (osd) {
            try osd.Destroy()
            osd := ""
            textCtrl := ""
            statusCtrl := ""
        }
        return
    }

    ; Close existing OSD
    if (osd) {
        try {
            osd.Destroy()
            SetTimer(FadeOSD, 0)
        }
    }

    ; Reset fade alpha
    global gFadeAlpha
    gFadeAlpha := 245

    w := 300
    h := 100
    
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

    ; Get Windows accent color
    accentRaw := RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\DWM", "AccentColor")
    r := accentRaw & 0xFF
    g := (accentRaw >> 8) & 0xFF
    b := (accentRaw >> 16) & 0xFF
    accentHex := Format("{:02X}{:02X}{:02X}", r, g, b)

    ; Title
    osd.SetFont("s14 bold c" . accentHex, "Segoe UI")
    textCtrl := osd.Add("Text", "x20 y15 w260 Center", title)

    ; Status
    osd.SetFont("s20 bold c" . fontColor, "Segoe UI")
    statusCtrl := osd.Add("Text", "x20 y45 w260 Center", status)

    osd.Show("x" . x . " y" . y . " w" . w . " h" . h . " NoActivate")

    ; Round the OSD corners
    WinGetPos(,, &winW, &winH, osd)
    hRgn := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", winW + 1, "Int", winH + 1, "Int", 20, "Int", 20, "Ptr")
    DllCall("SetWindowRgn", "Ptr", osd.Hwnd, "Ptr", hRgn, "Int", true)

    ; Auto-hide with fade
    SetTimer(FadeOSD, -duration)
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
        ShowOSD("", "")
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
        ShowOSD("", "")
    }
}

; Periodic watchdog to detect and fix stuck Ctrl state
SetTimer WatchdogTimer, 500

WatchdogTimer() {
    global ctrlPressed, isRemapEnabled
    
    if (!isRemapEnabled) {
        return
    }
    
    ; If we think Ctrl is pressed but CapsLock isn't physically down
    if (ctrlPressed && !GetKeyState("CapsLock", "P")) {
        Send "{Ctrl up}"
        ctrlPressed := false
    }
}

; ====== Exit Handler ======

OnExit ExitCleanup

ExitCleanup(ExitReason, ExitCode) {
    ; Clean up before script exits
    CleanupKeys()
    ShowOSD("", "")  ; Close OSD
    SetCapsLockState "Off"
}

; ====== Startup ======

; Initialize CapsLock state
SetCapsLockState "AlwaysOff"
ShowOSD("CapsLock → Ctrl", "✓ Loaded")