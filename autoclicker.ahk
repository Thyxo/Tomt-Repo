; Autoclicker: hold venstre museknap = gentagne klik
; Kræver AutoHotkey v2 (https://www.autohotkey.com)
; F8 = slå til/fra   |   F9 = afslut
#Requires AutoHotkey v2.0
#SingleInstance Force

global Aktiv := true
global Interval := 50   ; ms mellem klik (50 = ca. 20 klik/sek)

F8:: {
    global Aktiv := !Aktiv
    ToolTip("Autoclicker: " (Aktiv ? "TIL" : "FRA"))
    SetTimer(() => ToolTip(), -1000)
}
F9::ExitApp

#HotIf Aktiv
~LButton:: {
    Sleep 200                          ; kort pause, så normale klik ikke påvirkes
    while GetKeyState("LButton", "P") {
        Click
        Sleep Interval
    }
}
#HotIf
