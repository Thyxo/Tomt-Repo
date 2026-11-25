; =====================================================================
;  Autoclicker v4  –  AutoHotkey v2  (https://www.autohotkey.com)
;  Venstre + højre klik · Hold/Toggle · Mønstre · Exhaustion · Arraylist
;  Vinduesfilter · Tema · Fonte · Configs
;  F9 = afslut (fast)   ·   Indstillinger gemmes i autoclicker.ini
;  Configs gemmes i mappen \configs ved siden af scriptet
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
global CFGDIR   := A_ScriptDir "\configs"
DirCreate(CFGDIR)
global SpringGem := false
global Moenstre := ["Konstant", "Tilfældig", "Butterfly", "Bølge"]
global Modes    := ["Hold", "Toggle"]
global Fonte    := ["Segoe UI", "Bahnschrift", "Consolas", "Arial", "Verdana", "Tahoma"
                  , "Trebuchet MS", "Courier New", "Impact", "Comic Sans MS", "Georgia"]
global Farver   := Map("Grøn", "00FFAA", "Cyan", "00E5FF", "Rød", "FF4D4D", "Lilla", "B388FF"
                  , "Orange", "FFA040", "Gul", "FFE14D", "Hvid", "FFFFFF", "Regnbue", "")
global FarveNavne := ["Grøn", "Cyan", "Rød", "Lilla", "Orange", "Gul", "Hvid", "Regnbue"]

L(k, std) => IniRead(INI, "Generelt", k, std)
global GuiKey     := L("GuiKey", "Insert")
global PanikKey   := L("PanikKey", "End")
global VisAL      := Integer(L("Arraylist", 1))
global KunVindue  := Integer(L("KunVindue", 0))
global VinduesExe := L("VinduesExe", "")
global Moerk      := Integer(L("Moerk", 1))
global FarveAktiv := L("FarveAktiv", "Grøn")
global FarveVent  := L("FarveVent", "Hvid")
global GuiFont    := L("GuiFont", "Segoe UI")
global ALFont     := L("ALFont", "Segoe UI")
global ALSize     := Integer(L("ALSize", 12))
global ALFed      := Integer(L("ALFed", 1))
global AktivCfg   := L("AktivConfig", "")
global regKeys    := Map()

global Clickers := [Clicker("Venstre", "LButton", "Left", "F6")
                  , Clicker("Højre",   "RButton", "Right", "F7")]

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
        this.ui := {}
    }
    Gem(fil) {
        s := this.navn
        IniWrite(this.key, fil, s, "Key"),         IniWrite(this.enabled, fil, s, "Aktiv")
        IniWrite(this.cps, fil, s, "CPS"),         IniWrite(this.mode, fil, s, "Mode")
        IniWrite(this.pattern, fil, s, "Pattern"), IniWrite(this.delay, fil, s, "Delay")
        IniWrite(this.fade, fil, s, "Exhaustion")
    }
}

; =========================== HOVED-GUI ===============================
global MainGui := Gui("+AlwaysOnTop", "Autoclicker" (AktivCfg != "" ? " – " AktivCfg : ""))
MainGui.SetFont("s10", GuiFont)
if Moerk
    MainGui.BackColor := "1E1E1E", MainGui.SetFont("cE0E0E0")
tab := MainGui.AddTab3("w330 h500", ["Venstre", "Højre", "Vindue", "Udseende", "Keybinds", "Configs"])
W := "w300"

; ---------- Fane 1+2: Clickers ----------
for i, c in Clickers {
    tab.UseTab(i)
    BygClicker(c)
}

; ---------- Fane 3: Vindue ----------
tab.UseTab(3)
cbVin := MainGui.AddCheckbox(W " Checked" KunVindue, "Virker kun i dette program:")
cbVin.OnEvent("Click", (ctl, *) => KunVindue := ctl.Value)
edVin := MainGui.AddEdit(W, VinduesExe)
edVin.OnEvent("Change", (ctl, *) => VinduesExe := Trim(ctl.Value))
btVin := MainGui.AddButton(W, "Vælg vindue (klik på det inden 3 sek)")
btVin.OnEvent("Click", (*) => VaelgVindue())
cbTop := MainGui.AddCheckbox(W " Checked y+20", "Hold dette vindue øverst (pinned)")
cbTop.OnEvent("Click", (ctl, *) => MainGui.Opt((ctl.Value ? "+" : "-") "AlwaysOnTop"))
MainGui.AddText(W " cGray y+20", "Klikkeren stopper med det samme, hvis du`nskifter til et andet vindue. Arraylisten`nbliver grå, når filteret blokerer.")

; ---------- Fane 4: Udseende ----------
tab.UseTab(4)
MainGui.AddText(W, "── Vindue ──")
cbMoerk := MainGui.AddCheckbox(W " Checked" Moerk, "Mørkt tema (genstarter)")
cbMoerk.OnEvent("Click", (ctl, *) => (Moerk := ctl.Value, Reload()))
MainGui.AddText(W, "Font i vinduet (genstarter):")
ddGF := MainGui.AddDropDownList(W, Fonte)
ddGF.Text := GuiFont
ddGF.OnEvent("Change", (ctl, *) => (GuiFont := ctl.Text, Reload()))

MainGui.AddText(W " y+16", "── Arraylist ──")
cbAL := MainGui.AddCheckbox(W " Checked" VisAL, "Vis arraylist (øverst til højre)")
cbAL.OnEvent("Click", (ctl, *) => (VisAL := ctl.Value, OpdaterAL()))
MainGui.AddText(W, "Font:")
ddAF := MainGui.AddDropDownList(W, Fonte)
ddAF.Text := ALFont
ddAF.OnEvent("Change", (ctl, *) => (ALFont := ctl.Text, ALStil()))
txtSz := MainGui.AddText(W, "Størrelse: " ALSize)
slSz := MainGui.AddSlider(W " Range8-28", ALSize)
slSz.OnEvent("Change", (ctl, *) => (ALSize := ctl.Value, txtSz.Value := "Størrelse: " ALSize, ALStil()))
cbFed := MainGui.AddCheckbox(W " Checked" ALFed, "Fed skrift")
cbFed.OnEvent("Click", (ctl, *) => (ALFed := ctl.Value, ALStil()))
MainGui.AddText(W, "Farve når den klikker:")
ddA := MainGui.AddDropDownList(W, FarveNavne)
ddA.Text := FarveAktiv
ddA.OnEvent("Change", (ctl, *) => FarveAktiv := ctl.Text)
MainGui.AddText(W, "Farve når den venter:")
ddV := MainGui.AddDropDownList(W, FarveNavne)
ddV.Text := FarveVent
ddV.OnEvent("Change", (ctl, *) => FarveVent := ctl.Text)

; ---------- Fane 5: Keybinds ----------
tab.UseTab(5)
for c in Clickers {
    MainGui.AddText(W, c.navn " klik til/fra:")
    c.ui.hk := MainGui.AddHotkey(W, c.key)
    c.ui.hk.OnEvent("Change", ((cc, ctl, *) => (cc.key := ctl.Value, RegKey(cc.navn, cc.key, (*) => SaetAktiv(cc, !cc.enabled)))).Bind(c))
}
MainGui.AddText(W, "Vis/skjul vindue:")
hkGui := MainGui.AddHotkey(W, GuiKey)
hkGui.OnEvent("Change", (ctl, *) => (GuiKey := ctl.Value, RegKey("gui", GuiKey, VisSkjul)))
MainGui.AddText(W, "Panik – stop alt med det samme:")
hkPan := MainGui.AddHotkey(W, PanikKey)
hkPan.OnEvent("Change", (ctl, *) => (PanikKey := ctl.Value, RegKey("panik", PanikKey, Panik)))
MainGui.AddText(W " cGray y+20", "F9 = luk programmet (kan ikke ændres)`nKlik i feltet og tryk den nye tast.")

; ---------- Fane 6: Configs ----------
tab.UseTab(6)
txtCfg := MainGui.AddText(W, "Aktiv config: " (AktivCfg != "" ? AktivCfg : "(ingen)"))
txtCfg.SetFont("bold")
lbCfg := MainGui.AddListBox(W " r8")
lbCfg.OnEvent("DoubleClick", (*) => IndlaesCfg())
MainGui.AddText(W, "Navn til ny config:")
edCfg := MainGui.AddEdit(W, "")
MainGui.AddButton("w145", "💾 Gem ny").OnEvent("Click", (*) => GemCfg(edCfg.Value))
MainGui.AddButton("x+10 yp w145", "↻ Overskriv valgt").OnEvent("Click", (*) => GemCfg(lbCfg.Text))
MainGui.AddButton("xp-155 y+8 w145", "📂 Indlæs valgt").OnEvent("Click", (*) => IndlaesCfg())
MainGui.AddButton("x+10 yp w145", "🗑 Slet valgt").OnEvent("Click", (*) => SletCfg())
MainGui.AddText("xp-155 y+12 " W " cGray", "Dobbeltklik på en config for at indlæse.`nEn config gemmer ALLE indstillinger.")
ListCfg()

tab.UseTab()
MainGui.OnEvent("Close", (*) => ExitApp())
MainGui.Show()
if Moerk
    MoerktTema()

BygClicker(c) {
    u := c.ui
    u.aktiv := MainGui.AddCheckbox(W " Checked" c.enabled, c.navn " klik aktiv")
    u.aktiv.OnEvent("Click", (ctl, *) => SaetAktiv(c, ctl.Value))
    u.cpsTxt := MainGui.AddText(W " Center", c.cps " CPS")
    u.cpsTxt.SetFont("s16 bold")
    u.cps := MainGui.AddSlider(W " Range1-50 TickInterval5 ToolTip", c.cps)
    u.cps.OnEvent("Change", (ctl, *) => (c.cps := ctl.Value, u.cpsTxt.Value := c.cps " CPS"))
    MainGui.AddText(W, "Mode:")
    u.mode := MainGui.AddDropDownList(W, Modes)
    u.mode.Text := c.mode
    u.mode.OnEvent("Change", (ctl, *) => (c.mode := ctl.Text, c.running := false))
    MainGui.AddText(W, "Klikmønster:")
    u.pat := MainGui.AddDropDownList(W, Moenstre)
    u.pat.Text := c.pattern
    u.pat.OnEvent("Change", (ctl, *) => c.pattern := ctl.Text)
    MainGui.AddText(W, "Startforsinkelse (ms):")
    u.delay := MainGui.AddEdit(W " Number", c.delay)
    u.delay.OnEvent("Change", (ctl, *) => c.delay := (ctl.Value = "" ? 0 : Integer(ctl.Value)))
    u.fadeTxt := MainGui.AddText(W, "Exhaustion ved slip: " c.fade " ms")
    u.fade := MainGui.AddSlider(W " Range0-2000 TickInterval250 Line50 Page100", c.fade)
    u.fade.OnEvent("Change", (ctl, *) => (c.fade := ctl.Value, u.fadeTxt.Value := "Exhaustion ved slip: " c.fade " ms"))
    u.maalt := MainGui.AddText(W " Center y+12", "Målt: 0 CPS")
    u.maalt.SetFont("bold")
    MainGui.AddText(W " cGray", "Konstant = jævnt · Tilfældig = ±30 %`nButterfly = klik i par · Bølge = CPS svinger")
}

MoerktTema() {
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MainGui.Hwnd, "Int", 20, "Int*", 1, "Int", 4)
    for hwnd, ctl in MainGui {
        switch ctl.Type {
            case "Checkbox": DllCall("uxtheme\SetWindowTheme", "Ptr", hwnd, "Str", "", "Str", "")
            case "Edit", "ListBox":
                ctl.Opt("Background2D2D2D")
                DllCall("uxtheme\SetWindowTheme", "Ptr", hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
            case "DDL":    DllCall("uxtheme\SetWindowTheme", "Ptr", hwnd, "Str", "DarkMode_CFD", "Ptr", 0)
            case "Button": DllCall("uxtheme\SetWindowTheme", "Ptr", hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
        }
    }
    WinRedraw(MainGui)
}

; =========================== VINDUESFILTER ===========================
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

; =========================== CONFIGS =================================
ListCfg() {
    lbCfg.Delete()
    loop files CFGDIR "\*.ini"
        lbCfg.Add([SubStr(A_LoopFileName, 1, -4)])
}
GemCfg(navn) {
    navn := RegExReplace(Trim(navn), '[\\/:*?"<>|]')
    if navn = "" {
        MsgBox("Skriv et navn eller vælg en config.", "Configs", 0x30)
        return
    }
    fil := CFGDIR "\" navn ".ini"
    try FileDelete(fil)
    GemAlt(fil)
    global AktivCfg := navn
    txtCfg.Value := "Aktiv config: " navn
    MainGui.Title := "Autoclicker – " navn
    edCfg.Value := ""
    ListCfg()
    ToolTip("Config '" navn "' gemt"), SetTimer(() => ToolTip(), -1500)
}
IndlaesCfg() {
    navn := lbCfg.Text
    if navn = ""
        return
    global AktivCfg := navn, SpringGem := true
    FileCopy(CFGDIR "\" navn ".ini", INI, 1)
    IniWrite(navn, INI, "Generelt", "AktivConfig")
    Reload()
}
SletCfg() {
    navn := lbCfg.Text
    if navn = "" || MsgBox("Slet config '" navn "'?", "Configs", 0x24) != "Yes"
        return
    FileDelete(CFGDIR "\" navn ".ini")
    ListCfg()
}

; =========================== ARRAYLIST ===============================
global AL := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
AL.BackColor := "010101"
AL.MarginX := 0, AL.MarginY := 0
global alTxt := []
loop 3
    alTxt.Push(AL.AddText("x0 w420 Right Background010101 cFFFFFF", ""))
WinSetTransColor("010101", AL)
ALStil()

ALStil() {
    lh := Round(ALSize * 2)
    for i, t in alTxt {
        t.SetFont("s" ALSize " " (ALFed ? "bold" : "norm"), ALFont)
        t.Move(0, (i - 1) * lh, 420, lh)
        t.farve := ""
    }
    AL.Show("x" (A_ScreenWidth - 430) " y6 w420 h" (lh * 3) " NoActivate Hide")
    OpdaterAL(true)
}

OpdaterAL(tving := false) {
    static synlig := false
    linjer := []
    for c in Clickers
        if c.enabled
            linjer.Push(c)
    if !VisAL || !linjer.Length {
        if synlig || tving
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
            if t.farve != farve
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

; =========================== KEYBINDS ================================
RegKey(id, key, fn) {
    if regKeys.Has(id) && regKeys[id] != ""
        try Hotkey(regKeys[id], "Off")
    regKeys[id] := key
    if key != ""
        try Hotkey(key, fn, "On")
}
VisSkjul(*) {
    if DllCall("IsWindowVisible", "Ptr", MainGui.Hwnd)
        MainGui.Hide()
    else
        MainGui.Show()
}
Panik(*) {
    for c in Clickers
        SaetAktiv(c, 0)
    ToolTip("PANIK – alt stoppet"), SetTimer(() => ToolTip(), -1200)
}
for c in Clickers
    RegKey(c.navn, c.key, ((cc, *) => SaetAktiv(cc, !cc.enabled)).Bind(c))
RegKey("gui", GuiKey, VisSkjul)
RegKey("panik", PanikKey, Panik)

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

; =========================== KLIK-MOTOR ==============================
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
            if !VinduOK() {
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

; =========================== TIMERE / GEM ============================
Maal() {
    for c in Clickers
        c.ui.maalt.Value := "Målt: " c.count " CPS", c.count := 0
}
SetTimer(Maal, 1000)
SetTimer(OpdaterAL, 150)

GemAlt(fil) {
    for c in Clickers
        c.Gem(fil)
    for k, v in Map("GuiKey", GuiKey, "PanikKey", PanikKey, "Arraylist", VisAL
                  , "KunVindue", KunVindue, "VinduesExe", VinduesExe, "Moerk", Moerk
                  , "FarveAktiv", FarveAktiv, "FarveVent", FarveVent, "GuiFont", GuiFont
                  , "ALFont", ALFont, "ALSize", ALSize, "ALFed", ALFed, "AktivConfig", AktivCfg)
        IniWrite(v, fil, "Generelt", k)
}
OnExit(Afslut)
Afslut(*) {
    if !SpringGem
        GemAlt(INI)
    DllCall("winmm\timeEndPeriod", "UInt", 1)
}
