#Requires AutoHotkey >=2.0
#SingleInstance Force
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
        ShowTooltip("Remapping disabled - CapsLock works normally")
        return
    }
    
    ; Toggle CapsLock state
    newState := !GetKeyState("CapsLock", "T")
    SetCapsLockState newState
    
    ShowTooltip("CapsLock: " . (newState ? "ON" : "OFF"))
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
        ShowTooltip("CapsLock → Ctrl: ENABLED", 3000)
    } else {
        SetCapsLockState "Off"
        ShowTooltip("CapsLock → Ctrl: DISABLED`nCapsLock works normally", 3000)
    }
}

; Ctrl+Shift+Esc - Emergency cleanup
^+Esc:: {
    CleanupKeys()
    ShowTooltip("Emergency cleanup: All keys released", 2000)
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

; Show tooltip with auto-hide timer
ShowTooltip(message, duration := 2000) {
    ToolTip message
    SetTimer () => ToolTip(), -duration
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
    ToolTip()
    SetCapsLockState "Off"
}

; ====== Startup ======

; Initialize CapsLock state
SetCapsLockState "AlwaysOff"
ShowTooltip("CapsLock → Ctrl remapping loaded`nCtrl+1 to toggle | Ctrl+` for CapsLock", 3000)