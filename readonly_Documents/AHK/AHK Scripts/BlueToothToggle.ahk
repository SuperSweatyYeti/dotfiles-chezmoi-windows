#Requires AutoHotkey >=v2.0
#SingleInstance Force

Run("ms-settings:bluetooth")
WinWaitActive("Settings")
Sleep(2000)
Send("{Tab}{Space}")
WinClose("A")