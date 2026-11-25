; Autoclicker med GUI: hold venstre museknap = gentagne klik
; Kræver AutoHotkey v2 (https://www.autohotkey.com)
; F8 = slå til/fra   |   F9 = afslut
#Requires AutoHotkey v2.0
#SingleInstance Force
A_HotkeyInterval := 0
A_MaxHotkeysPerInterval := 1000

global Aktiv := true
global CPS := 20
global Forsinkelse := 200   ; ms før klik starter (så normale klik ikke påvirkes)
global Taeller := 0

; ---------- GUI ----------
g := Gui("+AlwaysOnTop", "Autoclicker")
g.SetFont("s10", "Segoe UI")
g.AddText("w240", "Klik pr. sekund (CPS):")
sld := g.AddSlider("w240 Range1-100 ToolTip TickInterval10", CPS)
txtCps := g.AddText("w240 Center", CPS " CPS")
txtCps.SetFont("s16 bold")
g.AddText("w240", "Startforsinkelse (ms):")
edtDelay := g.AddEdit("w240 Number", Forsinkelse)
btn := g.AddButton("w240 h32", "Slå FRA (F8)")
txtStatus := g.AddText("w240 Center cGreen", "● AKTIV")
txtMaalt := g.AddText("w240 Center", "Målt: 0 CPS")
g.AddText("w240 Center cGray", "Hold venstre knap nede · F9 = luk")
g.OnEvent("Close", (*) => ExitApp())

sld.OnEvent("Change", (*) => (CPS := sld.Value, txtCps.Value := CPS " CPS"))
edtDelay.OnEvent("Change", (*) => (Forsinkelse := edtDelay.Value = "" ? 0 : Integer(edtDelay.Value)))
btn.OnEvent("Click", (*) => Skift())
g.Show()

; Målt CPS opdateres hvert sekund
SetTimer(Maal, 1000)
Maal() {
    global Taeller
    txtMaalt.Value := "Målt: " Taeller " CPS"
    Taeller := 0
}

Skift() {
    global Aktiv := !Aktiv
    btn.Text := Aktiv ? "Slå FRA (F8)" : "Slå TIL (F8)"
    txtStatus.Value := Aktiv ? "● AKTIV" : "● SLÅET FRA"
    txtStatus.Opt(Aktiv ? "cGreen" : "cRed")
}

F8::Skift()
F9::ExitApp

#HotIf Aktiv && !WinActive("ahk_id " g.Hwnd)
~LButton:: {
    global Taeller
    Sleep Forsinkelse
    DllCall("winmm\timeBeginPeriod", "UInt", 1)   ; præcis timing
    naeste := A_TickCount
    while GetKeyState("LButton", "P") {
        Click
        Taeller++
        naeste += 1000 / CPS
        vent := naeste - A_TickCount
        if (vent > 0)
            DllCall("Sleep", "UInt", Round(vent))
        else
            naeste := A_TickCount
    }
    DllCall("winmm\timeEndPeriod", "UInt", 1)
}
#HotIf
