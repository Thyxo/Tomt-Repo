; =====================================================================
;  Autoclicker v3  –  AutoHotkey v2  (https://www.autohotkey.com)
;  Venstre + højre klik · Hold/Toggle · Mønstre · Exhaustion · Arraylist
;  F9 = afslut (fast)   ·   Indstillinger gemmes i autoclicker.ini
; =====================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
A_HotkeyInterval := 0
A_MaxHotkeysPerInterval := 5000
ProcessSetPriority("High")
SetMouseDelay(-1)
DllCall("winmm\timeBeginPeriod", "UInt", 1)

global INI      := A_ScriptDir "\autoclicker.ini"
global Moenstre := ["Konstant", "Tilfældig", "Butterfly", "Bølge"]
global Modes    := ["Hold", "Toggle"]
global Clickers := [Clicker("Venstre", "LButton", "Left", "F6")
                  , Clicker("Højre",   "RButton", "Right", "F7")]
global GuiKey   := IniRead(INI, "Generelt", "GuiKey", "Insert")
global VisAL    := Integer(IniRead(INI, "Generelt", "Arraylist", 1))
global aktivGuiKey := ""
global KunVindue  := Integer(IniRead(INI, "Generelt", "KunVindue", 0))
global VinduesExe := IniRead(INI, "Generelt", "VinduesExe", "")
global Moerk      := Integer(IniRead(INI, "Generelt", "Moerk", 1))
global FarveAktiv := IniRead(INI, "Generelt", "FarveAktiv", "Grøn")
global FarveVent  := IniRead(INI, "Generelt", "FarveVent", "Hvid")
global Farver := Map("Grøn", "00FFAA", "Cyan", "00E5FF", "Rød", "FF4D4D", "Lilla", "B388FF"
                   , "Orange", "FFA040", "Gul", "FFE14D", "Hvid", "FFFFFF", "Regnbue", "")
global FarveNavne := ["Grøn", "Cyan", "Rød", "Lilla", "Orange", "Gul", "Hvid", "Regnbue"]

class Clicker {
    __New(navn, knap, send, key) {
        s := navn
        this.navn := navn, this.knap := knap, this.send := send
        this.key     := IniRead(INI, s, "Key", key)
        this.enabled := Integer(IniRead(INI, s, "Aktiv", 0))
        this.cps     := Integer(IniRead(INI, s, "CPS", 12))
        this.mode    := IniRead(INI, s, "Mode", "Hold")
        this.pattern := IniRead(INI, s, "Pattern", "Konstant")
        this.delay   := Integer(IniRead(INI, s, "Delay", 100))
        this.fade    := Integer(IniRead(INI, s, "Exhaustion", 400))
        this.running := false, this.fadeStart := 0, this.next := 0
        this.count := 0, this.runClicks := 0, this.flip := false
        this.regKey := "", this.ui := {}
    }
    Gem() {
        s := this.navn
        IniWrite(this.key, INI, s, "Key"),         IniWrite(this.enabled, INI, s, "Aktiv")
        IniWrite(this.cps, INI, s, "CPS"),         IniWrite(this.mode, INI, s, "Mode")
        IniWrite(this.pattern, INI, s, "Pattern"), IniWrite(this.delay, INI, s, "Delay")
        IniWrite(this.fade, INI, s, "Exhaustion")
    }
}

; ---------------------------- HOVED-GUI ------------------------------
global MainGui := Gui("+AlwaysOnTop", "Autoclicker")
MainGui.SetFont("s10", "Segoe UI")
if Moerk
    MainGui.BackColor := "1E1E1E", MainGui.SetFont("cE0E0E0")
tab := MainGui.AddTab3("w300 h560", ["Venstre", "Højre", "Generelt"])
for i, c in Clickers {
    tab.UseTab(i)
    BygTab(c)
}
tab.UseTab(3)
cbAL := MainGui.AddCheckbox("w270 Checked" VisAL, "Vis arraylist (øverst til højre)")
cbAL.OnEvent("Click", (ctl, *) => (VisAL := ctl.Value, OpdaterAL()))
cbTop := MainGui.AddCheckbox("w270 Checked", "Hold vinduet øverst (pinned)")
cbTop.OnEvent("Click", (ctl, *) => MainGui.Opt((ctl.Value ? "+" : "-") "AlwaysOnTop"))
MainGui.AddText("w270", "Keybind: vis/skjul vindue")
hkGui := MainGui.AddHotkey("w270", GuiKey)
hkGui.OnEvent("Change", (ctl, *) => (GuiKey := ctl.Value, RegGuiKey()))
; --- Kun i bestemt vindue ---
MainGui.AddText("w270 y+16", "── Vinduesfilter ──")
cbVin := MainGui.AddCheckbox("w270 Checked" KunVindue, "Virker kun i dette program:")
cbVin.OnEvent("Click", (ctl, *) => KunVindue := ctl.Value)
edVin := MainGui.AddEdit("w270", VinduesExe)
edVin.OnEvent("Change", (ctl, *) => VinduesExe := Trim(ctl.Value))
btVin := MainGui.AddButton("w270", "Vælg vindue (klik på det inden 3 sek)")
btVin.OnEvent("Click", (*) => VaelgVindue())

; --- Tema og farver ---
MainGui.AddText("w270 y+16", "── Udseende ──")
cbMoerk := MainGui.AddCheckbox("w270 Checked" Moerk, "Mørkt tema (genstarter)")
cbMoerk.OnEvent("Click", (ctl, *) => (Moerk := ctl.Value, Reload()))
MainGui.AddText("w270", "Arraylist-farve når den klikker:")
ddA := MainGui.AddDropDownList("w270", FarveNavne)
ddA.Text := FarveAktiv
ddA.OnEvent("Change", (ctl, *) => FarveAktiv := ctl.Text)
MainGui.AddText("w270", "Arraylist-farve når den venter:")
ddV := MainGui.AddDropDownList("w270", FarveNavne)
ddV.Text := FarveVent
ddV.OnEvent("Change", (ctl, *) => FarveVent := ctl.Text)
tab.UseTab()
MainGui.OnEvent("Close", (*) => ExitApp())
MainGui.Show()
if Moerk
    MoerktTema()

MoerktTema() {
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MainGui.Hwnd, "Int", 20, "Int*", 1, "Int", 4)
    for hwnd, ctl in MainGui {
        switch ctl.Type {
            case "Checkbox":  DllCall("uxtheme\SetWindowTheme", "Ptr", hwnd, "Str", "", "Str", "")
            case "Edit":      ctl.Opt("Background2D2D2D"), DllCall("uxtheme\SetWindowTheme", "Ptr", hwnd, "Str", "DarkMode_CFD", "Ptr", 0)
            case "DDL", "Button": DllCall("uxtheme\SetWindowTheme", "Ptr", hwnd, "Str", ctl.Type = "DDL" ? "DarkMode_CFD" : "DarkMode_Explorer", "Ptr", 0)
        }
    }
    WinRedraw(MainGui)
}

VaelgVindue() {
    btVin.Text := "Klik på spillet/programmet nu…"
    SetTimer(Fang, -3000)
    Fang() {
        global VinduesExe, KunVindue
        try VinduesExe := WinGetProcessName("A")
        edVin.Value := VinduesExe
        KunVindue := 1, cbVin.Value := 1
        btVin.Text := "Valgt: " VinduesExe "  (vælg igen)"
        MainGui.Show()
    }
}

VinduOK() {
    if !KunVindue || VinduesExe = ""
        return true
    return WinActive("ahk_exe " VinduesExe) != 0
}

BygTab(c) {
    u := c.ui
    u.aktiv := MainGui.AddCheckbox("w270 Checked" c.enabled, c.navn " klik aktiv")
    u.aktiv.OnEvent("Click", (ctl, *) => SaetAktiv(c, ctl.Value))

    u.cpsTxt := MainGui.AddText("w270 Center", c.cps " CPS")
    u.cpsTxt.SetFont("s16 bold")
    u.cps := MainGui.AddSlider("w270 Range1-50 TickInterval5 ToolTip", c.cps)
    u.cps.OnEvent("Change", (ctl, *) => (c.cps := ctl.Value, u.cpsTxt.Value := c.cps " CPS"))

    MainGui.AddText("w270", "Mode:")
    u.mode := MainGui.AddDropDownList("w270", Modes)
    u.mode.Text := c.mode
    u.mode.OnEvent("Change", (ctl, *) => (c.mode := ctl.Text, c.running := false))

    MainGui.AddText("w270", "Klikmønster:")
    u.pat := MainGui.AddDropDownList("w270", Moenstre)
    u.pat.Text := c.pattern
    u.pat.OnEvent("Change", (ctl, *) => c.pattern := ctl.Text)

    MainGui.AddText("w270", "Startforsinkelse (ms):")
    u.delay := MainGui.AddEdit("w270 Number", c.delay)
    u.delay.OnEvent("Change", (ctl, *) => c.delay := (ctl.Value = "" ? 0 : Integer(ctl.Value)))

    u.fadeTxt := MainGui.AddText("w270", "Exhaustion ved slip: " c.fade " ms")
    u.fade := MainGui.AddSlider("w270 Range0-2000 TickInterval250 Line50 Page100", c.fade)
    u.fade.OnEvent("Change", (ctl, *) => (c.fade := ctl.Value, u.fadeTxt.Value := "Exhaustion ved slip: " c.fade " ms"))

    MainGui.AddText("w270", "Keybind: slå til/fra")
    u.hk := MainGui.AddHotkey("w270", c.key)
    u.hk.OnEvent("Change", (ctl, *) => (c.key := ctl.Value, RegKey(c)))

    u.maalt := MainGui.AddText("w270 Center y+12", "Målt: 0 CPS")
    u.maalt.SetFont("bold")
    RegKey(c)
}

; ---------------------------- ARRAYLIST ------------------------------
global AL := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
AL.BackColor := "010101"
AL.MarginX := 0, AL.MarginY := 0
AL.SetFont("s12 bold", "Segoe UI")
global alTxt := []
loop 3
    alTxt.Push(AL.AddText("x0 w340 h24 Right Background010101 cFFFFFF", ""))
WinSetTransColor("010101", AL)
AL.Show("x" (A_ScreenWidth - 350) " y6 w340 h80 NoActivate Hide")

OpdaterAL() {
    static synlig := false
    linjer := []
    for c in Clickers
        if c.enabled
            linjer.Push(c)
    if !VisAL || !linjer.Length {
        if synlig
            AL.Hide(), synlig := false
        return
    }
    for i, t in alTxt {
        if i <= linjer.Length {
            c := linjer[i]
            tekst := c.navn "Clicker  " c.cps " CPS  [" c.mode "]"
            farve := !VinduOK() ? "c707070"
                   : "c" FarveHex((c.running || c.fadeStart) ? FarveAktiv : FarveVent, i)
            if t.Value != tekst
                t.Value := tekst
            if !t.HasOwnProp("farve") || t.farve != farve
                t.SetFont(farve), t.farve := farve
        } else if t.Value != ""
            t.Value := ""
    }
    if !synlig
        AL.Show("NoActivate"), synlig := true
    WinSetAlwaysOnTop(1, AL)
}

FarveHex(navn, i) {
    if navn != "Regnbue"
        return Farver.Has(navn) ? Farver[navn] : "FFFFFF"
    h := Mod(A_TickCount / 8 + i * 60, 360)
    x := 1 - Abs(Mod(h / 60, 2) - 1)
    rgb := [[1,x,0],[x,1,0],[0,1,x],[0,x,1],[x,0,1],[1,0,x]][Floor(h / 60) + 1]
    return Format("{:02X}{:02X}{:02X}", Round(rgb[1]*255), Round(rgb[2]*255), Round(rgb[3]*255))
}

; ---------------------------- KEYBINDS -------------------------------
RegKey(c) {
    if c.regKey != ""
        try Hotkey(c.regKey, "Off")
    c.regKey := c.key
    if c.key != ""
        try Hotkey(c.key, (*) => SaetAktiv(c, !c.enabled), "On")
}
RegGuiKey() {
    global aktivGuiKey
    if aktivGuiKey != ""
        try Hotkey(aktivGuiKey, "Off")
    aktivGuiKey := GuiKey
    if GuiKey != ""
        try Hotkey(GuiKey, (*) => (WinExist("ahk_id " MainGui.Hwnd) && DllCall("IsWindowVisible", "Ptr", MainGui.Hwnd)) ? MainGui.Hide() : MainGui.Show(), "On")
}
RegGuiKey()

SaetAktiv(c, v) {
    c.enabled := v, c.ui.aktiv.Value := v
    if !v
        c.running := false, c.fadeStart := 0
    OpdaterAL()
}

F9::ExitApp

#HotIf !WinActive("ahk_id " MainGui.Hwnd)
~*LButton::KnapNed(Clickers[1])
~*RButton::KnapNed(Clickers[2])
#HotIf

KnapNed(c) {
    if !c.enabled || !VinduOK()
        return
    if c.mode = "Hold"
        (!c.running) && Start(c)
    else
        c.running ? Stop(c) : Start(c)
}

Start(c) {
    c.running := true, c.fadeStart := 0, c.runClicks := 0
    c.next := Nu() + c.delay
    SetTimer(Motor, -1)
}
Stop(c) {
    c.running := false
    c.fadeStart := (c.fade > 0 && c.runClicks > 0) ? Nu() : 0
}

; ---------------------------- KLIK-MOTOR -----------------------------
Nu() {
    static f := 0
    if !f
        DllCall("QueryPerformanceFrequency", "Int64*", &f)
    DllCall("QueryPerformanceCounter", "Int64*", &t := 0)
    return t * 1000 / f
}

Interval(c, t) {
    cps := c.cps
    if c.pattern = "Bølge"
        cps *= 1 + 0.3 * Sin(t / 1000 * 3.7)
    if !c.running && c.fadeStart                       ; exhaustion
        cps := Max(2, cps * (1 - (t - c.fadeStart) / c.fade))
    iv := 1000 / cps
    switch c.pattern {
        case "Tilfældig": iv *= Random(0.7, 1.3)
        case "Butterfly": c.flip := !c.flip, iv *= c.flip ? 0.4 : 1.6
    }
    return iv
}

Motor() {
    static koerer := false
    if koerer
        return
    koerer := true
    loop {
        travl := false
        for c in Clickers {
            t := Nu()
            if c.running && c.mode = "Hold" && !GetKeyState(c.knap, "P")
                Stop(c)
            if c.fadeStart && (t - c.fadeStart >= c.fade)
                c.fadeStart := 0
            if !(c.running || c.fadeStart)
                continue
            if !VinduOK() {                     ; skiftet væk fra valgt vindue
                c.running := false, c.fadeStart := 0
                continue
            }
            travl := true
            if t >= c.next {
                Click(c.send)
                c.count++, c.runClicks++
                c.next += Interval(c, t)
                if c.next < t
                    c.next := t + Interval(c, t)
            }
        }
        if !travl
            break
        DllCall("Sleep", "UInt", 1)
    }
    koerer := false
    for c in Clickers
        if c.running || c.fadeStart
            SetTimer(Motor, -1)
}

; ---------------------------- TIMERE / EXIT --------------------------
Maal() {
    for c in Clickers
        c.ui.maalt.Value := "Målt: " c.count " CPS", c.count := 0
}
SetTimer(Maal, 1000)
SetTimer(OpdaterAL, 150)
OpdaterAL()

OnExit(Afslut)
Afslut(*) {
    for c in Clickers
        c.Gem()
    IniWrite(GuiKey, INI, "Generelt", "GuiKey")
    IniWrite(VisAL, INI, "Generelt", "Arraylist")
    IniWrite(KunVindue, INI, "Generelt", "KunVindue")
    IniWrite(VinduesExe, INI, "Generelt", "VinduesExe")
    IniWrite(Moerk, INI, "Generelt", "Moerk")
    IniWrite(FarveAktiv, INI, "Generelt", "FarveAktiv")
    IniWrite(FarveVent, INI, "Generelt", "FarveVent")
    DllCall("winmm\timeEndPeriod", "UInt", 1)
}
