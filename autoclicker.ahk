; =====================================================================
;  Autoclicker v5  –  AutoHotkey v2  (https://www.autohotkey.com)
;  Kræver AutoHotkey v2.0 eller nyere. Dobbeltklik på filen for at starte.
;
;  F9 = luk programmet (fast)
;  Indstillinger gemmes i autoclicker.ini · Configs i mappen \configs
; =====================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
A_HotkeyInterval := 0
A_MaxHotkeysPerInterval := 5000
ProcessSetPriority("High")
SetMouseDelay(-1)
SetWinDelay(-1)
DetectHiddenWindows(true)
DllCall("winmm\timeBeginPeriod", "UInt", 1)

global VERSION   := "5.0"
global INI       := A_ScriptDir "\autoclicker.ini"
global CFGDIR    := A_ScriptDir "\configs"
global SpringGem := false
try DirCreate(CFGDIR)

; ---------------------------- LISTER ---------------------------------
global Modes    := ["Hold", "Toggle"]
global Moenstre := ["Konstant", "Tilfældig", "Gauss (naturlig)", "Menneskelig"
                  , "Drift", "Bølge", "Butterfly", "Burst", "Spikes"]
global ModeInfo := Map()
ModeInfo["Hold"]   := "Klikker så længe du holder knappen nede."
ModeInfo["Toggle"] := "Ét tryk på knappen starter – næste tryk stopper."
global MoensterInfo := Map()
MoensterInfo["Konstant"]         := "Præcis samme tid mellem hvert klik."
MoensterInfo["Tilfældig"]        := "Jævn, tilfældig variation omkring din CPS."
MoensterInfo["Gauss (naturlig)"] := "Samler sig om din CPS – store udsving er sjældne."
MoensterInfo["Menneskelig"]      := "Naturlig variation, små pauser og let træthed."
MoensterInfo["Drift"]            := "CPS glider langsomt op og ned over tid."
MoensterInfo["Bølge"]            := "CPS svinger roligt op og ned i bølger."
MoensterInfo["Butterfly"]        := "Klik i par: kort, lang, kort, lang."
MoensterInfo["Burst"]            := "Små salver af hurtige klik med korte pauser."
MoensterInfo["Spikes"]           := "Mest jævnt, men ind imellem et drop eller en spurt."
global Fonte := ["Segoe UI", "Bahnschrift", "Consolas", "Arial", "Verdana", "Tahoma"
               , "Trebuchet MS", "Courier New", "Impact", "Comic Sans MS", "Georgia"]
global Farver := Map()
for navn, hex in Map("Grøn", "00D68F", "Cyan", "00C8E6", "Blå", "5B8CFF", "Rød", "FF5A5A"
                   , "Lilla", "A98BFF", "Orange", "FF9F43", "Gul", "FFD93D", "Hvid", "FFFFFF")
    Farver[navn] := hex
global FarveNavne := ["Grøn", "Cyan", "Blå", "Rød", "Lilla", "Orange", "Gul", "Hvid", "Regnbue"]

; ---------------------------- INDSTILLINGER --------------------------
LaesS(sek, k, std) => IniRead(INI, sek, k, std)
LaesI(sek, k, std) {
    try return Integer(IniRead(INI, sek, k, std))
    return std
}
Klem(v, lo, hi) => Max(lo, Min(hi, v))
IListe(v, liste, std) {
    for x in liste
        if x = v
            return x
    return std
}

global S := {}
S.Tema        := IListe(LaesS("Generelt", "Tema", LaesI("Generelt", "Moerk", 1) ? "Mørkt" : "Lyst"), ["Mørkt", "Lyst"], "Mørkt")
S.GuiFont     := IListe(LaesS("Generelt", "GuiFont", "Segoe UI"), Fonte, "Segoe UI")
S.Arraylist   := LaesI("Generelt", "Arraylist", 1) ? 1 : 0
S.ALFont      := IListe(LaesS("Generelt", "ALFont", "Segoe UI"), Fonte, "Segoe UI")
S.ALSize      := Klem(LaesI("Generelt", "ALSize", 12), 8, 28)
S.ALFed       := LaesI("Generelt", "ALFed", 1) ? 1 : 0
S.FarveAktiv  := IListe(LaesS("Generelt", "FarveAktiv", "Grøn"), FarveNavne, "Grøn")
S.FarveVent   := IListe(LaesS("Generelt", "FarveVent", "Hvid"), FarveNavne, "Hvid")
S.KunVindue   := LaesI("Generelt", "KunVindue", 0) ? 1 : 0
S.VinduesExe  := LaesS("Generelt", "VinduesExe", "")
S.Pinned      := LaesI("Generelt", "Pinned", 1) ? 1 : 0
S.AktivConfig := LaesS("Generelt", "AktivConfig", "")

; Farvetema
global T := {}
if S.Tema = "Lyst"
    T := {bg: "F4F5F7", side: "E8EAEE", ctrl: "FFFFFF", text: "1F2328", muted: "6B7280", accent: "3B6FE0"}
else
    T := {bg: "1E1F22", side: "17181A", ctrl: "2B2D31", text: "E6E7EA", muted: "8B9099", accent: "5B8CFF"}

; ---------------------------- BILLEDER -------------------------------
global ASSETDIR := A_Temp "\autoclicker_v5"
try DirCreate(ASSETDIR)
SkrivBilleder()
global HarBilleder := FileExist(Img("toggle_on")) && FileExist(Img("toggle_off"))
                   && FileExist(Img("ico_folder_s")) && FileExist(Img("logo"))

Img(n) => ASSETDIR "\" n ".png"
SkrivBilleder() {
    pfx := (S.Tema = "Lyst" ? "light" : "dark") "_" (A_ScreenDPI > 110 ? "2x" : "1x") "_"
    for navn, b64 in BilledData()
        if SubStr(navn, 1, StrLen(pfx)) = pfx
            try B64Fil(b64, Img(SubStr(navn, StrLen(pfx) + 1)))
}
B64Fil(b64, fil) {
    n := 0
    DllCall("crypt32\CryptStringToBinary", "Str", b64, "UInt", 0, "UInt", 1, "Ptr", 0, "UInt*", &n, "Ptr", 0, "Ptr", 0)
    buf := Buffer(n)
    DllCall("crypt32\CryptStringToBinary", "Str", b64, "UInt", 0, "UInt", 1, "Ptr", buf, "UInt*", &n, "Ptr", 0, "Ptr", 0)
    f := FileOpen(fil, "w")
    f.RawWrite(buf, n)
    f.Close()
}

; ---------------------------- KLIKKER --------------------------------
class Clicker {
    __New(navn, knap, send, stdKey, stdFade) {
        s := navn
        this.navn := navn, this.knap := knap, this.send := send
        this.key     := LaesS(s, "Key", stdKey)
        this.enabled := LaesI(s, "Aktiv", 0) ? 1 : 0
        this.cps     := Klem(LaesI(s, "CPS", 12), 1, 50)
        this.mode    := IListe(LaesS(s, "Mode", "Hold"), Modes, "Hold")
        this.pattern := IListe(LaesS(s, "Pattern", "Konstant"), Moenstre, "Konstant")
        this.rnd     := Klem(LaesI(s, "Tilfaeldighed", 30), 0, 100)
        this.delay   := Klem(LaesI(s, "Delay", 100), 0, 500)
        this.fade    := Klem(LaesI(s, "Exhaustion", stdFade), 0, 2000)
        ; køretidsdata
        this.running := false, this.fadeStart := 0, this.next := 0, this.startT := 0
        this.ned := false, this.opAt := 0, this.count := 0, this.runClicks := 0
        this.flip := false, this.drift := 0, this.burstN := 0, this.burstLeft := 0
        this.ui := {}
    }
    Gem(fil) {
        s := this.navn
        IniWrite(Binds[s].key, fil, s, "Key")
        IniWrite(this.enabled, fil, s, "Aktiv")
        IniWrite(this.cps, fil, s, "CPS")
        IniWrite(this.mode, fil, s, "Mode")
        IniWrite(this.pattern, fil, s, "Pattern")
        IniWrite(this.rnd, fil, s, "Tilfaeldighed")
        IniWrite(this.delay, fil, s, "Delay")
        IniWrite(this.fade, fil, s, "Exhaustion")
    }
}
global Clickers := [Clicker("Venstre", "LButton", "Left", "F6", 300)
                  , Clicker("Højre", "RButton", "Right", "F7", 0)]
global Binds := Map()

; =========================== HOVED-GUI ===============================
global X  := 184          ; venstre kant af indholdet
global CW := 332          ; bredde af indholdet
global WW := X + CW + 24  ; vinduets bredde
global WH := 610          ; vinduets højde

global MainGui := Gui((S.Pinned ? "+AlwaysOnTop " : "") "-MaximizeBox", "Autoclicker")
MainGui.BackColor := T.bg
MainGui.MarginX := 0, MainGui.MarginY := 0
MainGui.SetFont("s10 c" T.text, S.GuiFont)
MainGui.OnEvent("Close", (*) => ExitApp())

; ---------- Sidebar (eget under-vindue, så farven ikke overlapper) ----------
global Side := Gui("-Caption +Parent" MainGui.Hwnd)
Side.BackColor := T.side
Side.MarginX := 0, Side.MarginY := 0
Side.SetFont("s10 c" T.text, S.GuiFont)
if HarBilleder
    Side.AddPicture("x18 y20 w24 h24", Img("logo"))
tl := Side.AddText("x" (HarBilleder ? 50 : 18) " y21 w100 h24 +0x200", "Autoclicker")
tl.SetFont("s12 bold")

global Nav := []
navNavne := ["Venstre klik", "Højre klik", "Vindue", "Udseende", "Keybinds", "Configs"]
navIkon  := ["mouse_l", "mouse_r", "window", "theme", "keyboard", "folder"]
ny := 76
for i, navn in navNavne {
    it := {}
    it.bar := Side.AddText("x0 y" (ny + 6) " w3 h28 Hidden Background" T.accent, "")
    if HarBilleder {
        it.ico  := Side.AddPicture("x20 y" (ny + 11) " w18 h18", Img("ico_" navIkon[i]))
        it.icoS := Side.AddPicture("x20 y" (ny + 11) " w18 h18 Hidden", Img("ico_" navIkon[i] "_s"))
        it.ico.OnEvent("Click", VisSide.Bind(i))
        it.icoS.OnEvent("Click", VisSide.Bind(i))
    }
    it.txt := Side.AddText("x48 y" (ny + 4) " w108 h32 +0x200 c" T.muted, navn)
    it.txt.OnEvent("Click", VisSide.Bind(i))
    Nav.Push(it)
    ny += 40
}
global stV   := Side.AddText("x20 y" (WH - 104) " w130 c" T.muted, "")
global stH   := Side.AddText("x20 y+4 w130 c" T.muted, "")
global stCfg := Side.AddText("x20 y+4 w130 c" T.muted, "")
Side.AddText("x20 y" (WH - 34) " w130 c" T.muted, "F9 = luk · v" VERSION)

; ---------- Hjælpefunktioner til layout ----------
Titel(tekst, sub) {
    h := MainGui.AddText("x" X " y20 w" CW, tekst)
    h.SetFont("s15 bold")
    MainGui.AddText("x" X " y+2 w" CW " c" T.muted, sub)
}
Overskrift(t) {
    h := MainGui.AddText("x" X " y+22 w" CW, t)
    h.SetFont("bold")
}
Raekke(label, val := "", ekstra := 14) {
    MainGui.AddText("x" X " y+" ekstra " w" (CW - 110), label)
    v := MainGui.AddText("x" (X + CW - 110) " yp w110 Right c" T.accent, val)
    v.SetFont("bold")
    return v
}
NySlider(opts, val) => MainGui.AddSlider("x" (X - 6) " y+2 w" (CW + 12) " h28 NoTicks ToolTip " opts, val)
NyDDL(liste, valgt, opts := "") {
    d := MainGui.AddDropDownList("x" X " y+6 w" CW " r12 " opts, liste)
    for i, v in liste
        if v = valgt
            d.Choose(i)
    if !d.Value
        d.Choose(1)
    return d
}
Hint(tekst, opts := "") => MainGui.AddText("x" X " y+4 w" CW " c" T.muted " " opts, tekst)
FladKnap(opts, tekst, fn, primaer := false) {
    k := MainGui.AddText(opts " Center +0x200 Background" (primaer ? T.accent " cFFFFFF" : T.ctrl), tekst)
    k.OnEvent("Click", fn)
    return k
}

; Pæn tænd/sluk-knap (billede) – falder tilbage til almindelig checkbox
class Toggle {
    __New(label, val, cb, yopt := "y+16") {
        this.cb := cb, this.v := val ? 1 : 0
        if HarBilleder {
            this.on  := MainGui.AddPicture("x" X " " yopt " w44 h24", Img("toggle_on"))
            this.off := MainGui.AddPicture("xp yp w44 h24", Img("toggle_off"))
            this.txt := MainGui.AddText("x+12 yp w" (CW - 56) " h24 +0x200", label)
            for ctl in [this.on, this.off, this.txt]
                ctl.OnEvent("Click", ObjBindMethod(this, "Skift"))
        } else {
            this.chk := MainGui.AddCheckbox("x" X " " yopt " w" CW " h24", label)
            this.chk.OnEvent("Click", ObjBindMethod(this, "Skift"))
        }
        this.Vis()
    }
    Skift(*) {
        this.v := !this.v
        this.Vis()
        this.cb.Call(this.v)
    }
    Vis() {
        if HarBilleder {
            this.on.Visible  := this.v
            this.off.Visible := !this.v
        } else
            this.chk.Value := this.v
    }
    Saet(v) {
        this.v := v ? 1 : 0
        this.Vis()
    }
    Tekst(t) {
        if HarBilleder
            this.txt.Value := t
        else
            this.chk.Text := t
    }
}

; ---------- Faner (skjult fanekontrol, styres af sidebaren) ----------
global Faner := MainGui.AddTab2("x0 y0 w0 h0 -Wrap", navNavne)

; ---------- Fane 1+2: klikkere ----------
for i, c in Clickers {
    Faner.UseTab(i)
    BygClicker(c)
}

BygClicker(c) {
    u := c.ui
    Titel(c.navn " klik", "Tip: brug fanen Vindue, så den kun virker i dit spil.")
    u.tog := Toggle("Aktiv", c.enabled, (v) => SaetAktiv(c, v))

    u.cpsV := Raekke("Klik pr. sekund (CPS)", c.cps, 18)
    u.cps := NySlider("Range1-50", c.cps)
    u.cps.OnEvent("Change", (ctl, *) => (c.cps := ctl.Value, u.cpsV.Value := c.cps))

    Raekke("Mode")
    u.mode := NyDDL(Modes, c.mode)
    u.modeInfo := Hint(ModeInfo[c.mode])
    u.mode.OnEvent("Change", (ctl, *) => (StopHelt(c), c.mode := ctl.Text, u.modeInfo.Value := ModeInfo[c.mode]))

    Raekke("Klikmønster")
    u.pat := NyDDL(Moenstre, c.pattern)
    u.patInfo := Hint(MoensterInfo[c.pattern])
    u.pat.OnEvent("Change", (ctl, *) => VaelgMoenster(c, ctl.Text))

    u.rndV := Raekke("Tilfældighed (styrke)", c.rnd " %")
    u.rnd := NySlider("Range0-100 Line5 Page10", c.rnd)
    u.rnd.OnEvent("Change", (ctl, *) => (c.rnd := ctl.Value, u.rndV.Value := c.rnd " %"))

    u.delayV := Raekke("Startforsinkelse", c.delay " ms")
    u.delay := NySlider("Range0-500 Line10 Page50", c.delay)
    u.delay.OnEvent("Change", (ctl, *) => (c.delay := ctl.Value, u.delayV.Value := c.delay " ms"))

    u.fadeV := Raekke("Exhaustion når du slipper", FadeTekst(c.fade))
    u.fade := NySlider("Range0-2000 Line50 Page100", c.fade)
    u.fade.OnEvent("Change", (ctl, *) => (c.fade := ctl.Value, u.fadeV.Value := FadeTekst(c.fade)))

    u.maalt := MainGui.AddText("x" X " y+12 w" CW " c" T.muted, "Målt lige nu: 0 CPS")
    VaelgMoenster(c, c.pattern)
}
FadeTekst(ms) => ms ? ms " ms" : "Fra"
VaelgMoenster(c, navn) {
    c.pattern := navn
    c.ui.patInfo.Value := MoensterInfo[navn]
    c.ui.rnd.Enabled := (navn != "Konstant")
}

; ---------- Fane 3: Vindue ----------
Faner.UseTab(3)
Titel("Vindue", "Bestem hvor klikkeren må virke.")
global tVin := Toggle("Virker kun i ét bestemt program", S.KunVindue, (v) => (S.KunVindue := v))
Raekke("Program (exe-navn)")
global edVin := MainGui.AddEdit("x" X " y+6 w" (CW - 130) " h28 -E0x200 Background" T.ctrl, S.VinduesExe)
edVin.OnEvent("Change", (ctl, *) => (S.VinduesExe := Trim(ctl.Value)))
global btVin := FladKnap("x+10 yp w120 h28", "Vælg vindue", VaelgVindue, true)
Hint("Tryk 'Vælg vindue' og klik så på spillet inden 3 sek. Klikkeren stopper, så snart du skifter til et andet vindue.", "r3")
global tTop := Toggle("Hold dette vindue øverst", S.Pinned, SaetPinned, "y+18")
Overskrift("Administrator")
Hint("Kører spillet som administrator, skal klikkeren også gøre det – ellers når klikkene ikke frem.", "r2")
if A_IsAdmin
    Hint("✓ Kører allerede som administrator")
else
    FladKnap("x" X " y+10 w" CW " h30", "Genstart som administrator", GenstartAdmin)

; ---------- Fane 4: Udseende ----------
Faner.UseTab(4)
Titel("Udseende", "Tema, fonte og arraylist.")
Raekke("Tema (genstarter)", "", 18)
ddTema := NyDDL(["Mørkt", "Lyst"], S.Tema)
ddTema.OnEvent("Change", (ctl, *) => (S.Tema := ctl.Text, Reload()))
Raekke("Font i vinduet (genstarter)")
ddGF := NyDDL(Fonte, S.GuiFont)
ddGF.OnEvent("Change", (ctl, *) => (S.GuiFont := ctl.Text, Reload()))
Overskrift("Arraylist")
global tAL := Toggle("Vis arraylist øverst til højre", S.Arraylist, (v) => (S.Arraylist := v, OpdaterAL(true)), "y+10")
Raekke("Font")
ddAF := NyDDL(Fonte, S.ALFont)
ddAF.OnEvent("Change", (ctl, *) => (S.ALFont := ctl.Text, ALStil()))
global szV := Raekke("Størrelse", S.ALSize)
slSz := NySlider("Range8-28", S.ALSize)
slSz.OnEvent("Change", (ctl, *) => (S.ALSize := ctl.Value, szV.Value := S.ALSize, ALStil()))
Toggle("Fed skrift", S.ALFed, (v) => (S.ALFed := v, ALStil()), "y+8")
halv := (CW - 12) // 2
MainGui.AddText("x" X " y+14 w" halv, "Farve – klikker")
MainGui.AddText("x" (X + halv + 12) " yp w" halv, "Farve – venter")
ddA := MainGui.AddDropDownList("x" X " y+6 w" halv " r12", FarveNavne)
ddA.Choose(S.FarveAktiv)
ddA.OnEvent("Change", (ctl, *) => (S.FarveAktiv := ctl.Text, OpdaterAL(true)))
ddV := MainGui.AddDropDownList("x" (X + halv + 12) " yp w" halv " r12", FarveNavne)
ddV.Choose(S.FarveVent)
ddV.OnEvent("Change", (ctl, *) => (S.FarveVent := ctl.Text, OpdaterAL(true)))

; ---------- Fane 5: Keybinds ----------
Faner.UseTab(5)
Titel("Keybinds", "Klik på en knap og tryk den nye tast.")
KeyRaekke(id, label, std, fn, foerste := false) {
    MainGui.AddText("x" X " y+" (foerste ? 20 : 10) " w" (CW - 150) " h30 +0x200", label)
    Binds[id] := {key: std, fn: fn, navn: label, knap: ""}
    Binds[id].knap := FladKnap("x" (X + CW - 140) " yp w140 h30", "", FangTast.Bind(id))
}
for c in Clickers
    KeyRaekke(c.navn, c.navn " klik til/fra", c.key, SkiftKlikker.Bind(c), c.navn = "Venstre")
KeyRaekke("gui", "Vis / skjul vindue", LaesS("Generelt", "GuiKey", "Insert"), VisSkjul)
KeyRaekke("panik", "Panik – stop alt", LaesS("Generelt", "PanikKey", "F8"), Panik)
MainGui.AddText("x" X " y+10 w" (CW - 150) " h30 +0x200", "Luk programmet")
MainGui.AddText("x" (X + CW - 140) " yp w140 h30 Center +0x200 c" T.muted, "F9 (fast)")
Hint("`nMus 4, Mus 5 og midterknappen virker også.`nEsc = annuller · Backspace = fjern tasten.", "y+14 r3")

; ---------- Fane 6: Configs ----------
Faner.UseTab(6)
Titel("Configs", "Gem og skift mellem forskellige opsætninger.")
global txtCfg := MainGui.AddText("x" X " y+18 w" CW, "")
txtCfg.SetFont("bold")
global lbCfg := MainGui.AddListBox("x" X " y+8 w" CW " r8 -E0x200 Background" T.ctrl)
lbCfg.OnEvent("DoubleClick", IndlaesCfg)
Raekke("Navn til ny config")
global edCfg := MainGui.AddEdit("x" X " y+6 w" (CW - 130) " h28 -E0x200 Background" T.ctrl)
FladKnap("x+10 yp w120 h28", "Gem ny", (*) => GemCfg(edCfg.Value, true), true)
bw := (CW - 20) // 3
FladKnap("x" X " y+12 w" bw " h30", "Indlæs", IndlaesCfg)
FladKnap("x+10 yp w" bw " h30", "Overskriv", OverskrivCfg)
FladKnap("x+10 yp w" bw " h30", "Slet", SletCfg)
Hint("`nDobbeltklik på en config for at indlæse den.`nEn config gemmer ALLE indstillinger – også keybinds og udseende.", "r4")

Faner.UseTab()

; ---------- Vis vinduet ----------
Side.Show("x0 y0 w160 h" WH)
MainGui.Show("w" WW " h" WH " Hide")
GendanPosition()
MainGui.Show()
TemaFinish()
VisSide(1)
ListCfg()
OpdaterStatus()

TemaFinish() {
    if S.Tema != "Mørkt"
        return
    try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MainGui.Hwnd, "Int", 20, "Int*", 1, "Int", 4)
    for hwnd, ctl in MainGui {
        if ctl.Type = "DDL"
            try DllCall("uxtheme\SetWindowTheme", "Ptr", hwnd, "Str", "DarkMode_CFD", "Ptr", 0)
        else if ctl.Type = "Edit" || ctl.Type = "ListBox"
            try DllCall("uxtheme\SetWindowTheme", "Ptr", hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
    }
    WinRedraw(MainGui)
}
GendanPosition() {
    x := LaesI("Generelt", "WinX", ""), y := LaesI("Generelt", "WinY", "")
    if x = "" || y = ""
        return
    vx := SysGet(76), vy := SysGet(77), vw := SysGet(78), vh := SysGet(79)
    if x >= vx && x < vx + vw - 120 && y >= vy && y < vy + vh - 80
        WinMove(x, y, , , MainGui)
}
VisSide(n, *) {
    for i, it in Nav {
        sel := (i = n)
        it.bar.Visible := sel
        it.txt.SetFont(sel ? "c" T.text " bold" : "c" T.muted " norm")
        if it.HasOwnProp("ico") {
            it.ico.Visible := !sel
            it.icoS.Visible := sel
        }
    }
    Faner.Choose(n)
}
SaetPinned(v) {
    S.Pinned := v
    MainGui.Opt((v ? "+" : "-") "AlwaysOnTop")
}
OpdaterStatus() {
    for i, c in Clickers {
        ctl := (i = 1) ? stV : stH
        ctl.Value := "● " c.navn ": " (c.enabled ? "TIL" : "fra")
        ctl.SetFont(c.enabled ? "c" T.accent : "c" T.muted)
        k := Binds[c.navn].key
        c.ui.tog.Tekst(k != "" ? "Aktiv   (" KeyNavn(k) " slår til/fra)" : "Aktiv")
    }
    stCfg.Value := S.AktivConfig != "" ? "Config: " S.AktivConfig : ""
    txtCfg.Value := "Aktiv config: " (S.AktivConfig != "" ? S.AktivConfig : "(ingen)")
    MainGui.Title := "Autoclicker" (S.AktivConfig != "" ? " – " S.AktivConfig : "")
    for id, b in Binds
        b.knap.Value := KeyNavn(b.key)
}
Besked(t) {
    ToolTip(t)
    SetTimer(() => ToolTip(), -1600)
}

; =========================== VINDUESFILTER ===========================
global vaelgN := 0
VaelgVindue(*) {
    global vaelgN
    if vaelgN > 0
        return
    vaelgN := 3
    btVin.Value := "Klik på spillet… 3"
    SetTimer(VaelgTik, 1000)
}
VaelgTik() {
    global vaelgN
    vaelgN -= 1
    if vaelgN > 0 {
        btVin.Value := "Klik på spillet… " vaelgN
        return
    }
    SetTimer(VaelgTik, 0)
    btVin.Value := "Vælg vindue"
    if WinActive("ahk_id " MainGui.Hwnd) {
        MainGui.Show()
        Besked("Du klikkede ikke på et andet vindue – prøv igen.")
        return
    }
    exe := ""
    try exe := WinGetProcessName("A")
    MainGui.Show()
    if exe = "" {
        Besked("Kunne ikke læse programmets navn – prøv igen.")
        return
    }
    S.VinduesExe := exe, S.KunVindue := 1
    edVin.Value := exe
    tVin.Saet(1)
    Besked("Valgt: " exe)
}
VinduOK() {
    if !S.KunVindue || S.VinduesExe = ""
        return true
    return WinActive("ahk_exe " S.VinduesExe) != 0
}
GenstartAdmin(*) {
    global SpringGem
    GemAlt(INI)
    GemPosition()
    SpringGem := true
    try {
        if A_IsCompiled
            Run('*RunAs "' A_ScriptFullPath '" /restart')
        else
            Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
        ExitApp()
    } catch {
        SpringGem := false
        Besked("Genstart som administrator blev annulleret.")
    }
}

; =========================== CONFIGS =================================
ListCfg() {
    lbCfg.Delete()
    loop files CFGDIR "\*.ini"
        lbCfg.Add([SubStr(A_LoopFileName, 1, -4)])
}
GemCfg(navn, spoerg) {
    navn := Trim(RegExReplace(navn, '[\\/:*?"<>|]'))
    if navn = "" {
        Besked("Skriv et navn til din config først.")
        return
    }
    fil := CFGDIR "\" navn ".ini"
    if spoerg && FileExist(fil) && MsgBox("Config '" navn "' findes allerede. Overskriv den?", "Configs", 0x40024) != "Yes"
        return
    S.AktivConfig := navn
    try FileDelete(fil)
    GemAlt(fil)
    edCfg.Value := ""
    ListCfg()
    OpdaterStatus()
    Besked("Config '" navn "' er gemt ✓")
}
OverskrivCfg(*) {
    navn := lbCfg.Text
    if navn = "" {
        Besked("Vælg en config på listen først.")
        return
    }
    if MsgBox("Overskriv '" navn "' med dine nuværende indstillinger?", "Configs", 0x40024) = "Yes"
        GemCfg(navn, false)
}
IndlaesCfg(*) {
    global SpringGem
    navn := lbCfg.Text
    if navn = "" {
        Besked("Vælg en config på listen først.")
        return
    }
    fil := CFGDIR "\" navn ".ini"
    if !FileExist(fil) {
        ListCfg()
        return
    }
    GemPosition()
    x := LaesS("Generelt", "WinX", ""), y := LaesS("Generelt", "WinY", "")
    SpringGem := true
    FileCopy(fil, INI, 1)
    IniWrite(navn, INI, "Generelt", "AktivConfig")
    if x != ""
        IniWrite(x, INI, "Generelt", "WinX"), IniWrite(y, INI, "Generelt", "WinY")
    Reload()
}
SletCfg(*) {
    navn := lbCfg.Text
    if navn = "" {
        Besked("Vælg en config på listen først.")
        return
    }
    if MsgBox("Slet config '" navn "'?", "Configs", 0x40024) != "Yes"
        return
    try FileDelete(CFGDIR "\" navn ".ini")
    if S.AktivConfig = navn
        S.AktivConfig := ""
    ListCfg()
    OpdaterStatus()
}

; =========================== ARRAYLIST ===============================
global AL := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale")
AL.BackColor := "010101"
AL.MarginX := 0, AL.MarginY := 0
global alLin := []
loop 2
    alLin.Push({txt: AL.AddText("x0 y0 w10 h10 Right Background010101 cFFFFFF", "")
              , bar: AL.AddText("x0 y0 w3 h10 Background" T.accent, ""), farve: ""})
WinSetTransColor("010101", AL)
ALStil()

ALStil() {
    sk := A_ScreenDPI / 96
    lh := Round(S.ALSize * sk * 1.75)
    w  := Round(S.ALSize * sk * 30)
    for i, l in alLin {
        l.txt.SetFont("s" S.ALSize " " (S.ALFed ? "bold" : "norm"), S.ALFont)
        l.txt.Move(0, (i - 1) * lh, w - Round(10 * sk), lh)
        l.bar.Move(w - Round(3 * sk), (i - 1) * lh + Round(lh * 0.15), Round(3 * sk), Round(lh * 0.7))
        l.farve := ""
    }
    AL.Show("x" (A_ScreenWidth - w - 6) " y6 w" w " h" (lh * alLin.Length) " NoActivate Hide")
    OpdaterAL(true)
}

OpdaterAL(tving := false, *) {
    static synlig := false, sidstTop := 0
    aktive := []
    for c in Clickers
        if c.enabled
            aktive.Push({c: c, t: c.navn " Clicker  " c.cps " CPS  " c.mode})
    if !S.Arraylist || !aktive.Length {
        if synlig || tving
            AL.Hide(), synlig := false
        return
    }
    if aktive.Length = 2 && StrLen(aktive[2].t) > StrLen(aktive[1].t)
        aktive := [aktive[2], aktive[1]]
    ok := VinduOK()
    for i, l in alLin {
        if i > aktive.Length {
            if l.txt.Visible
                l.txt.Visible := false, l.bar.Visible := false
            continue
        }
        c := aktive[i].c
        hex := !ok ? "6E6E6E" : FarveHex((c.running || c.fadeStart) ? S.FarveAktiv : S.FarveVent, i)
        if l.txt.Value != aktive[i].t
            l.txt.Value := aktive[i].t
        if l.farve != hex {
            l.txt.SetFont("c" hex)
            l.bar.Opt("Background" hex)
            l.bar.Redraw()
            l.farve := hex
        }
        if !l.txt.Visible
            l.txt.Visible := true, l.bar.Visible := true
    }
    if !synlig
        AL.Show("NoActivate"), synlig := true
    if A_TickCount - sidstTop > 2000 {
        WinSetAlwaysOnTop(1, AL)
        sidstTop := A_TickCount
    }
}

FarveHex(navn, i) {
    if navn != "Regnbue"
        return Farver.Has(navn) ? Farver[navn] : "FFFFFF"
    h := Mod(A_TickCount / 12 + i * 50, 360)
    x := 1 - Abs(Mod(h / 60, 2) - 1)
    rgb := [[1, x, 0], [x, 1, 0], [0, 1, x], [0, x, 1], [x, 0, 1], [1, 0, x]][Floor(h / 60) + 1]
    return Format("{:02X}{:02X}{:02X}", Round(rgb[1] * 220 + 35), Round(rgb[2] * 220 + 35), Round(rgb[3] * 220 + 35))
}

; =========================== KEYBINDS ================================
SkiftKlikker(c, *) => SaetAktiv(c, !c.enabled)
VisSkjul(*) {
    if DllCall("IsWindowVisible", "Ptr", MainGui.Hwnd)
        MainGui.Hide()
    else
        MainGui.Show()
}
Panik(*) {
    for c in Clickers
        SaetAktiv(c, 0)
    Besked("PANIK – alt er stoppet")
}
AktiverBinds() {
    for id, b in Binds {
        if b.key = ""
            continue
        try Hotkey(b.key, b.fn, "On")
        catch {
            b.key := ""        ; ugyldig tast i ini-filen
        }
    }
    try Hotkey("F9", (*) => ExitApp(), "On")
}
DeaktiverBinds() {
    for id, b in Binds
        if b.key != ""
            try Hotkey(b.key, "Off")
    try Hotkey("F9", "Off")
}
FangTast(id, *) {
    static travl := false
    if travl
        return
    travl := true
    b := Binds[id]
    b.knap.Value := "Tryk en tast…"
    b.knap.Opt("Background" T.accent)
    b.knap.SetFont("cFFFFFF")
    b.knap.Redraw()
    DeaktiverBinds()
    ny := LaesTast()
    if ny != "#annuller" && ny != b.key {
        konflikt := ""
        if ny = "F9"
            konflikt := "Luk programmet"
        for oid, bb in Binds
            if oid != id && ny != "" && bb.key = ny
                konflikt := bb.navn
        if konflikt != ""
            MsgBox("Tasten " KeyNavn(ny) " bruges allerede til: " konflikt, "Keybinds", 0x40030)
        else
            b.key := ny
    }
    AktiverBinds()
    b.knap.Opt("Background" T.ctrl)
    b.knap.SetFont("c" T.text)
    b.knap.Redraw()
    OpdaterStatus()
    travl := false
}
LaesTast() {
    ih := InputHook("T10")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E")
    mus := ""
    Poll() {
        for k in ["XButton1", "XButton2", "MButton"]
            if GetKeyState(k, "P") {
                mus := k
                ih.Stop()
                return
            }
    }
    SetTimer(Poll, 15)
    ih.Start()
    ih.Wait()
    SetTimer(Poll, 0)
    if mus != "" {
        KeyWait(mus)
        return Mods() mus
    }
    if ih.EndReason != "EndKey"
        return "#annuller"
    k := ih.EndKey
    if k = "Escape"
        return "#annuller"
    if k = "Backspace" || k = "Delete"
        return ""
    em := ih.EndMods
    return (InStr(em, "^") ? "^" : "") (InStr(em, "!") ? "!" : "") (InStr(em, "+") ? "+" : "") (InStr(em, "#") ? "#" : "") k
}
Mods() => (GetKeyState("Ctrl") ? "^" : "") (GetKeyState("Alt") ? "!" : "") (GetKeyState("Shift") ? "+" : "")
        . ((GetKeyState("LWin") || GetKeyState("RWin")) ? "#" : "")
KeyNavn(k) {
    if k = ""
        return "Ingen"
    pre := ""
    while StrLen(k) > 1 && InStr("^!+#", SubStr(k, 1, 1)) {
        f := SubStr(k, 1, 1)
        pre .= f = "^" ? "Ctrl+" : f = "!" ? "Alt+" : f = "+" ? "Shift+" : "Win+"
        k := SubStr(k, 2)
    }
    switch k, "Off" {
        case "XButton1": k := "Mus 4"
        case "XButton2": k := "Mus 5"
        case "MButton":  k := "Midterknap"
        default:
            if StrLen(k) = 1
                k := StrUpper(k)
    }
    return pre k
}
AktiverBinds()

; Bakke-menu (ikonet ved uret)
A_TrayMenu.Delete()
A_TrayMenu.Add("Vis / skjul vindue", VisSkjul)
A_TrayMenu.Add("Stop alt (panik)", Panik)
A_TrayMenu.Add()
A_TrayMenu.Add("Afslut", (*) => ExitApp())
A_TrayMenu.Default := "Vis / skjul vindue"
A_IconTip := "Autoclicker"

; =========================== MUSEKNAPPER =============================
SaetAktiv(c, v) {
    c.enabled := v ? 1 : 0
    c.ui.tog.Saet(c.enabled)
    if !c.enabled
        StopHelt(c)
    OpdaterStatus()
    OpdaterAL(true)
}
StopHelt(c) {
    c.running := false, c.fadeStart := 0
    if c.ned {
        Click(c.send " Up")
        c.ned := false
    }
}

MusAktiv() => IsSet(MainGui) && !WinActive("ahk_id " MainGui.Hwnd)
#HotIf MusAktiv()
~*LButton::KnapNed(Clickers[1])
~*RButton::KnapNed(Clickers[2])
#HotIf

KnapNed(c) {
    if !c.enabled || !VinduOK()
        return
    if c.mode = "Hold" {
        if !c.running
            Start(c)
    } else {
        if c.running
            Stop(c)
        else
            Start(c)
    }
}
Start(c) {
    t := Nu()
    c.running := true, c.fadeStart := 0, c.runClicks := 0
    c.startT := t, c.next := t + c.delay
    c.drift := 0, c.burstLeft := 0, c.flip := false
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
    t := 0
    DllCall("QueryPerformanceCounter", "Int64*", &t)
    return t * 1000 / f
}
Gauss() {
    u1 := Random(0.000001, 1.0), u2 := Random(0.0, 1.0)
    return Klem(Sqrt(-2 * Ln(u1)) * Cos(6.283185 * u2), -2.5, 2.5)
}
Interval(c, t) {
    s := c.rnd / 100
    cps := c.cps
    switch c.pattern {
        case "Bølge":
            cps *= 1 + 0.5 * s * Sin((t - c.startT) / 1000 * 3.2)
        case "Drift", "Menneskelig":
            c.drift := Klem(c.drift + Random(-1.0, 1.0) * 0.06 * s, -0.5 * s, 0.5 * s)
            cps *= 1 + c.drift
    }
    if c.pattern = "Menneskelig"                       ; let træthed over tid
        cps *= 1 - Min(0.2, (t - c.startT) / 1000 * 0.012) * s
    if !c.running && c.fadeStart && c.fade > 0         ; exhaustion
        cps *= Max(0.1, 1 - (t - c.fadeStart) / c.fade)
    cps := Klem(cps, 1.5, 100)
    iv := 1000 / cps
    switch c.pattern {
        case "Tilfældig":
            iv *= 1 + Random(-1.0, 1.0) * s
        case "Gauss (naturlig)":
            iv *= 1 + Gauss() * 0.4 * s
        case "Menneskelig":
            iv *= 1 + Gauss() * 0.3 * s
            if Random(0.0, 1.0) < 0.05 * s
                iv += Random(60, 160) * s
        case "Butterfly":
            c.flip := !c.flip
            iv *= c.flip ? (1 - 0.8 * s) : (1 + 0.8 * s)
        case "Burst":
            if c.burstLeft <= 0 {
                c.burstN := Random(3, 6)
                c.burstLeft := c.burstN
            }
            c.burstLeft -= 1
            f := 1 - 0.6 * s
            iv *= (c.burstLeft > 0) ? f : (c.burstN - (c.burstN - 1) * f)
        case "Spikes":
            r := Random(0.0, 1.0)
            if r < 0.12 * s
                iv *= Random(1.8, 2.8)
            else if r < 0.24 * s
                iv *= Random(0.4, 0.6)
            else
                iv *= 1 + Random(-0.05, 0.05)
    }
    return Max(8, iv)
}
HoldTid(c, iv) {
    base := Min(iv * 0.45, 40)
    if c.pattern != "Konstant"
        base *= Random(0.7, 1.3)
    return Klem(base, 4, iv * 0.7)
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
            if (c.running || c.fadeStart) && !VinduOK()
                c.running := false, c.fadeStart := 0
            if c.ned && t >= c.opAt {
                Click(c.send " Up")
                c.ned := false
            }
            if !(c.running || c.fadeStart) {
                if c.ned
                    travl := true
                continue
            }
            travl := true
            if !c.ned && t >= c.next {
                iv := Interval(c, t)
                Click(c.send " Down")
                c.ned := true
                c.opAt := t + HoldTid(c, iv)
                c.count += 1, c.runClicks += 1
                c.next += iv
                if c.next < t
                    c.next := t + iv
            }
        }
        if !travl
            break
        DllCall("Sleep", "UInt", 1)
    }
    koerer := false
    for c in Clickers
        if c.running || c.fadeStart || c.ned
            SetTimer(Motor, -1)
}

; =========================== TIMERE / GEM ============================
Maal() {
    for c in Clickers {
        c.ui.maalt.Value := "Målt lige nu: " c.count " CPS"
        c.count := 0
    }
}
SetTimer(Maal, 1000)
SetTimer(OpdaterAL, 150)

GemAlt(fil) {
    for c in Clickers
        c.Gem(fil)
    for k in ["Tema", "GuiFont", "Arraylist", "ALFont", "ALSize", "ALFed", "FarveAktiv", "FarveVent"
            , "KunVindue", "VinduesExe", "Pinned", "AktivConfig"]
        IniWrite(S.%k%, fil, "Generelt", k)
    IniWrite(Binds["gui"].key, fil, "Generelt", "GuiKey")
    IniWrite(Binds["panik"].key, fil, "Generelt", "PanikKey")
}
GemPosition() {
    try {
        WinGetPos(&x, &y, , , MainGui)
        if x > -10000 && y > -10000
            IniWrite(x, INI, "Generelt", "WinX"), IniWrite(y, INI, "Generelt", "WinY")
    }
}
OnExit(Afslut)
Afslut(*) {
    for c in Clickers
        if c.ned
            try Click(c.send " Up")
    if !SpringGem {
        GemAlt(INI)
        GemPosition()
    }
    DllCall("winmm\timeEndPeriod", "UInt", 1)
}

; =========================== BILLED-DATA =============================
; Små PNG-billeder (tænd/sluk-knapper og ikoner), pakket ind i scriptet,
; så det hele kan ligge i én fil. Skrives til %TEMP%\autoclicker_v5.
BilledData() {
    d := Map()
    d["dark_1x_toggle_on"] := "iVBORw0KGgoAAAANSUhEUgAAACwAAAAYCAIAAAAODYjtAAAEYElEQVR42q1WTWxUVRT+zr3vf6Yzb0pbGQMtBTtoKQgaNQYRE0NEYwJhoSSsXKkLEzauJHGjC3fducAYFrI1aORfQ0wkCDGg4a8MBEptmTBT2+l0Zt68v3tczFgqMZWZcvKW97z73XO+852P+gfW4p8gocVhTUVBKru5L/e22/+K7a7VTBedBgEghI2yV75dnvilmP+hUvhdaIbUE6yiB8cWQJCQoTeb6Hl6zcv7e4fe0iybFTgGc9t3CwIISiFWACAlNA0kEHhe6eax8XOjtekx3c6wipvnZdrNACASYaOc3bhv056v3dWbWekqUlC88J5HfTqBCJ6PRghdImnDMhBFXK2z77NpGJlVw33D7wTV6bmpC1K3AQagLdRg4KX9uR2fxD7CekxCEom2CyDgh1AKzz2Frc9g7RPIJAHCXI3uFul8HudvwCvHCSc5smvUcHrvnh9t1oMGBnOhN5PduG9k12joRQQJog7aLwRqDfT34L0d2LTmv8/cuodDP+HqBHfZsTC1K9/tL1w+rNvdsitpOd1Dm/YcYiWJxXIQPDuIA+9idQ8UP8wkZjCwIoVXRzBdoRtTZErODGyfvnUiqBdl0jFzr3/hrh6JA0VCdDIChCDCkyvw6V44FmIFKVrkeOhTClLixRyuT9JkSXWlTKH3FMe+Fanslt6hnZHPJGTHoxgrvP8GbLOFYImCKQUifLATlil9j3uHdqayW0RfbrdmGay4s+sFoe7j+XUY7odaEsFiHNlubB9B1WPTMfpyu4Xbv5UVaBl6pBS2bWgvhRnbhqFLqBhu/1Zhu4McozM+AlAKjonBvhY5HlFGibCqB5kuCkI47qDQzBRze4q0mJKxQtJGOtleFoCkjVSCogialRJ4HEEdpSxkicivEKEpn+0GM6RA3ce8114WgFoD83XWJKJGRXjlOyTRyZpaJFN3i+BH/gcDDBRmMTPPuoF6+Y4oT5wlAV5eO87daKcjDAJ+HUMQQUqUJ86KYv5I1AhILGs6zo1h/H5LA/63FyRQruLHP5CwKPCCYv6IqBQulW6e0Exa2O4d6JVSOHgKsYIQWEL2mhuEgK9Oo1KLLYeK+ROVwiWZdjO16Wsrh/eS1MGdCAYDho57f6E0hxdyLUy8aBqbdyuGECDCN2dw8iKnEgg879rRD+NgXmZWZBuVP/1qaeWGN+MoJlAnOBimgfwUxiaxbiXcZGtjLXY6glCaw5fHcfIiJ61YmPL68Y9nxs9oZlqm02lpOHNTF2I/7Fv/GitiFXfgaJo4pmbw8xWUKrB0mAZMrTWNt+/j2G84eAq3puJUQghT5E9/PnnxYMvUND3mgr1bv+Mz3UlGPlgpahWU2uJHzPB8SAE3ibQDIlTqPDvPQQTHEnYCXrWaP32gcPmwbrnM6oHHBLhZj9LNk1JPO5lBzTJIEJja5QcBpgFNwg9QrqFcQxSTaVHCIRV6havfXzv60cz4Gd3ONBH8y20/dsvf5AQBYaNcX9Ly/w2wMgdrkN850AAAAABJRU5ErkJggg=="
    d["dark_1x_toggle_off"] := "iVBORw0KGgoAAAANSUhEUgAAACwAAAAYCAIAAAAODYjtAAAEMUlEQVR42rVW328VRRSec2Z29+6Pu3vv3bZAoq1tVcAnQ2LwBxDQWIvyt/hiiDHqizFGIoYoIfwRaGwk8UVbmr6LFTAmhYiVhxa4bW939+52786c8WHj9ZJU2i7xvE0yM/vt+c583wejYxOsXwCaSGttWZbt1ms12zAMRM4Y01qzqkVEUhZbW1nWjfM8BwBAZAMXikd2K2UYZtBoOa4rhMEYk1JKKRljiCgEZ5opor2CQETLqtVqtl8P0rS72Vkvih4i9jfwoNHs4/U8f3jfAcdxGYMojrM0M03D933btouiiKKk1+uZpomIFRqjtWYAVs12vTopledbAPBIJ4jID5qtcBgA0jQlohPHXpt68/XDhw4ODYUAsL6xsbR0e+7awrX5BSml67pKqSrUKIkIQyP7kfNoc6PsB4yOTRIpr+4PDe8HgCiKnp2cPPveu0ePvrTtLbd++/3LC1//fH2xEQTVcPQ5aj9YTZIIkXM/aBimOTxygHMeRdErLx+9dPH8xMQ4EdEA/Vqzcrlv38iZt6dXVu7fuHnLtu3KA6uZrtlOlnVJKe77jVZr2HHcLMvGnxm7fOmC53lKKc45IsJAlUullBDi1MkT13/5dXn5nmWZVXFozjkCpt0ELctyXJeIlFIffnC2JJtz/l9HOedEBAAff/R+rWbR3h9LXw+IyHZdy7LQcepCGHGcHD/26pEjLxLRYxD06VRKjT791Jl3puMk2XH/Y4oDd5w6WrbNGCNSp6en9K5FCQC01qenpwwhnkTHNNOWbaMhDCml53kHn38OGAPAXYIAgInxsTAMi6Lov/i9g2BCGIicK6Xq9XoYNhlju7yt/Krv+61WU0pZFQNjWmNfO8s/2/NoVTq1zZARKc55kiSdzmapB7vVYMaSOOl0NoUQ1acCgIiwKAohRBTHt+/8obXWmnYJQmu9/Ne9drttGEbl2QTGpCwwzzLGGDD4cXZu973VWgPAT3PzpTVXJgIY5FmGaRpLKet1b3Z2fmnpDudcKdoxHyBiu7323cxV13WJqjuI0ipNY8zzPO0mnAsp1WfnziulEOExoaGUSAA498WFzuamYRiV3QMRs243z3MeNJpF0XMcr1ar3b27vLKyeurkcY7Yd8iy2+UQlHoKAF9dvHzl25nA96sbKQARrbXvayLeaIRKSlLKcT3btm7cvLW4ePOFw4fCsDX4AvsetrKy+smnn1/5ZiYI/CcwDoaI6+0HW1mKyKHMmIOhJkkS27ZPT0+9NfXG5OR4IwgAIIriu38uX5tf+P7qDxsbHd+vV+yB1oAAgOtrDwdDzcRgvGuGw6ZpFr1enHQNQ4Rh2Go1AaDT6bTba3meu65rGEZlFhC5UnJj7WGSRP9K5WDaJqJ/gq4nhNBaF0VRFJIxJgQXQiAiEVVQhZJNUmrboAs7RX6zdOpyMP+nyP83HEZMvF7dZakAAAAASUVORK5CYII="
    d["dark_1x_logo"] := "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAACvElEQVR42p2VzW9UVRiHn/ece2duL/QObR2m5VOsNCbED0JKCCGhsGAjbBDQBRviwoVh4wJi/APcuTONif4DQIgrQ0QTgyQlREMhtCmBwbBQAhmb6Tgzduaee143Bto6wwye7XvOc57z9TsyOrY1c01jctv3frRp14l4eKeYEIQXNVWfNhfv/zF36dHNr7xv2yCWYnEkv670zvFvRl7b51N8Rp/NWEzInw9vzF7+sNV4YgcHN+x5/2Jx595W3aGCSJ8g9eraWWHTtqS07/HdC3bX4XPbJz9oNZyxwUpKb6CIGJO2XLJxS7rctJPHp8OBEVWRFUO9kmUEFu3PLh+Pmnh43GciYp5TPOsjRoeoL2NNTy3jM4mHx42YYHUBr4QBn57krVepNbG2t5GYwHSahLZjaD2fnWL3ONV6by+gcxcjtNqEAeffY/8b1Jq9WV3rxqCQDzl/gsNvU230YL2oKOA9qpw9ypHdVBsY879Az26TKh+/y8kDLHVnBb1PRFDwntNToFy4ThK/vJFXVBH+FTl9iLPH8PqSRl6fb/DVW1ybI47IWQZy/N3GSH+gzGOEn+cpFZjYzI5RvvwOa1BlILeW0nVpXklifnnA5xf5YRbg9TGm3gRI4s7v2XRKLaKQH2/zxbcUYm7e5+kSXjk2SS7AdQkso96toVhLrcnX3wPkQ6p1frqDEdZFFAu4rIORehc0F8uDpYnM6bMAEHCewIDgMqIc1+ZYrDOzQOoILaqrQtcG8lelbJOhjaWJgy7NVibJyimtodnm3u9YgzVrE0o1CyP7cGbauqWFoa1ThbEt6bIT6Ry1RsjnEFZTVL3PoiSolH+dv/KJjeN8pXw1Ke0ZLG0DUe32b/yHHkgQmUr5xuzlM65ds0nhlbRVfXz3Urpcz8fFMNogYvr5jhqVhd9mpuevnHPtmg3ifwCgYglm2SC4hQAAAABJRU5ErkJggg=="
    d["dark_1x_ico_mouse_l"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACRUlEQVR42nWT30sUURTH7zn37szsztr+stx2tbI2FYmySOkXvUQPQQ8VVgoVUU/9QUEQCEFEIdVLL1EPIUTvUSZWav5KM0hnd2d2ftx7ehidxtW+j+eeD/d7v+ceaCuWWEwAQESe60olGTHkqOtGWIy3iSbG930A2F/pKrd3IOLiwvzM9Hff9zVNi5Oiicnl8hcvDXZ2VjjnRJRIJObnfrx8/vTn4oKm6UQqbMaIkVKmUubwzTuVSrfj2K7bWJiffTTywEgmb9+9l88XgsADgGbMdd2TZ84Wi6Vq1cINjX/+OPLwvhDi3PkLvh80Y0qpVCpVOdjtug1EJCIikkpyLmanp8beve3q6c1kMkGwTorIoWmmk8kUACQ0DRhDxFy+cOXqsJQym8sDgGm21Os1zvmmSIgUANTrtaplhXkAYseefUSUSGhSyu0HoJQyjOSH92NvXr8yzbRS66HZdr1/4NTlwSG1EeO/t/1PYTBREv/FtnZsW8T4GQAoJbdALDQch5ExRkQA4Hme4zjZbJ6IIWJkUkmVyeb8IGg4DgBuuo1zbtv25MT4kaPHd7UVLWuNMWCM1Wu1dMuOgROnZ6a+ra7+EUKEP5On0y2RyaWlxb5j/YcO9638Wq5aa0RULJWvDd0qFFpHnz22N4bGGINocQDQ89xSuX3w+o3i7vLvlWWlVOvONmtt9cXok6+TE4ZhRFOB+L4Boue6uq539/Tu7TzAkc/Nzkx8+VSrVXU9SbG5wZY1RaWk22isbxcwXTeEENE9of4CpeALFNW9qqEAAAAASUVORK5CYII="
    d["dark_1x_ico_mouse_l_s"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACWUlEQVR42nWTT08TURTF773vTad/aUuhVKQilchGAkEhwsZEY4zGmGiMiXEhO3Xryi/gB2Dhzpiw1qALXLnTROJClI0hYCIqWlJsKDO0ZWbevOtisEwD3uXN+73zcs472FPohdAgEjMr12bfBQAkQ5pJRMnsh4/Jdkb4XgNQdJXOZ46eQZLbvxera+98z5aRVJiUYR3fq8eypeGrM10DUygAGMiA2vrq0ssH2+WPYZJakPY9I54bvz3XPTjlNpVyVO3X6ofZu0a04+z0q0TnCV81EakNQxTKsUqTDzsKRcd2kQhJIonylxfvn10hGRm68Fh7TUBsw1h7kXhn9+Al5WgkYtbAmn2PhLn1Y/Hr2yf5kxej6aJWTkDKQIt9ZSSyRiwHSNIgRkCCeLY0emOWfS+W6UekSCLv1iskIgwccpI1Irr1LceuoDCYGZGyxUlgFkZM+wCgD3FSay2jqW8LM8tvHkUSedYq2LuNav/4vZHrM6z3MYJDhvdTIYFELQP/hzEgHlhSy8DDMERAbL2t7bJgGdIkAABmROG7ddW045kSs0b6lydJ1iqWHtAeqN0aomDgUNzC8BrVysp838i1VH541yoDIAC69YqZPHJ8Yrq6ttCsfScZBWYAEMlkak8XhbWx1Dd6p/fUjZ3NlV17nVmnC2Onb80mcsc+PZ92GhUSRmAYtoqDKJRrp3snxm4+7SgUd/5YrFWyq7NpWZ/n7m+uvpbRNOu9r4zhvgWkNNM9Q5dz/edQyK2fCxvL885O2TAz4eLggZoKrT3lWMwaAQBQmimSZksnmL92eAvY6qjrGQAAAABJRU5ErkJggg=="
    d["dark_1x_ico_mouse_r"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACSklEQVR42nWT20tUURSH91r7OHvPzc6MOnNS85JdTKwsNLoQFNG7YGRQCIFP/Ue9FIQUIfVQPURvQUhYT1FqdpPMSTNormfOba/dw5mGGcd+j2uvb687ZK1u1iAA0Fp7rquUYowhRyFkaGx0M3Ywvu8DY4NDB3r39QPiZm5j7dsXz/MiEaE17YKFjGmmJqemDx464gc+MCCi3Mb6syePchvrkYiskzyRSIaMIiWlvDl7qyuTfTB3Nwj8rqxVtSvpjs7hkdGPy0u2XeKchxjWQ7mOe/b8xYxl3btz+83iAiniyAHRtivJZPuFS5eDIACAJoyIpJSjR8feLr5e+vDOMNqCwGeMaa0B0HGc/oH9ppmuk0YtQ6VisXhbm5HJZK/PzDJgfX0DWutIRAACKRJCxmLxUqkQ5tnUySBQZiotpOTIPd/7mfsBAEQko9FEIkm7dpJIRaPRhVcvXzx/Go8nGNOMASLadmV84szk1HTj6JA1CwAQEREZA/Z/7YK1OrUasfENAIhUC8SIaAeM/7oMnudVq1XTTGvNEGvfISIp2mOm/CBwqlUAbIrGObdte3Vl6fiJ8UzWKhYLYW2VcjmRbD91+tza18/5/B/DMMLG1JYrzGFzMzd2cmL02Nj2r61SsaC1trp7rl6b6ejonH84Z1fK9eWC+uEAoOe53T29V6ZvWHt7fm9vEVFnV7ZYyD+ev/9pdUVKGRbZhDHGANFzXSHE4eGR/sEhjnz9+9rK8vtyuSREtPFwoOVMkUi5jlMbLjAhpGEY9Tih/gKSnArDicceHwAAAABJRU5ErkJggg=="
    d["dark_1x_ico_mouse_r_s"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACW0lEQVR42m2Tv09TURTHz7n3vr629NEnhVIapIBBHVAMmhoZxNXFoCEsLDhoHB2Mo/+CTk4O6uJgdDDFwdVETCRRYvyFMUI0tIKN8Apt33v3neNQaF4p3/Hk+7n35Jzzxd5MFkJCFMysvQoHHgCgMJSZQFTMQdim9jGBXwPE7qFJu/8sonRKS+WV19qrqIgVJlUrU43ZQ2NT93tG8uQDIDDB1tqnj4WbW2uLYVImElYD4kAb0eS5qy8TPUcWn1wjzVbPiF/THV19meOX/3yb96obQhoADABi7yupXWd44paVHnj7eHr13UMmX0iFKL2qb1rW0Qt3SNcBseHfxZh8FbWzozOriy9KnwtSQaBdAGImROHXqSt3PmbnSLsNUjU7jMRTwohb6ZH87DMAODQwwSxURCACESjTMuLdbqUoZISBw5Nk0l7MHjTMFEgVeDtbxR+IwBQYUTuSSAMdNEkiMmKdP9/c+/LqdqQjDUAAiEJ61XLuzPWTU3eZqWkWsE+IKAQKCYDNLqBN+zAGxLaiaA7wIAwREJl0+9u7RRStGDOiDLwdXavE7WFmQrG3T6GYdCw5RD7o+iai5JZ1S8OvlteXC/1jl6z0ibpTBEAA9HbWzUTfYH6uvLJQ21wVKgrMoeMCECid0lL/qdns6JXtjeV65TczJTPjp2cedaQG3j+dc6vrzePCZnAQpfYqyWx+fPpBZ+bw9l+HSSe6u2qO8+H5jY3v8yqa5L3VYThvDVKZyd5jF1O5SZTq36+F0teCu100TDscHGyLqSTyteswEwIAoDItoUymlpj+B2NHDmh9Yx7BAAAAAElFTkSuQmCC"
    d["dark_1x_ico_window"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAABxElEQVR42n2TzWtTQRTF585nJ5kg2EVjK4LQUEUUQZFEWsF1SwvtRnTlP6iLSgSLH4XS7oS6cCPoRnHZSDMvb14y97qY5jXkJb2rmYHfzL3nnIGl5jIbFwCw+UVE5VqWABHFGK/AAIBznmCZ9kVRKKWstZNXTjHD4TDPc2MMEcnErLbWNrd3nWsg4sxWASCE/MP7d99Ov2qtJREppTa394ZFOPx8oLWuPji++s7Wzt6vnz+yLJOIaK11zn35dNLdf+NcI+L0hIIL7/vtpxsvXr22ttY/P7+YbZBl68+eP37S4RzmyMikFINBlkaQSVkhRK939vfPb6kkq4oCLI7i9cXFlZu3LpUkIm3M95PT7v5b5xoRsdIk977f7mzcftm6xBKplK47V6vXsYJxzhkwbUyplpwMAY6rOhsizkhJGQLOeZVJ55N+XiiZnPHeA8DMJr33IYQytzKlJoSw2lprd9bNwgJhxW4OIQ93792PcRRCAM6heWOlCOHBw0dbO7vGWCKqZouIAbDRKH486B4fHWqtYam5DABFERqNa7ZWI0Q2P5P/emdKacYYpP8GADFGxMjYvC9HAFxKOe2bEEIIwa6s0oP/8qTpWpvOV4sAAAAASUVORK5CYII="
    d["dark_1x_ico_window_s"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAAB7ElEQVR42n2TMWhTURSGz3/vee/lJS9a24akiaKtWYRSUBwyiEMHF8XZwU2K4OYmTk4u6tStODoKbh0E0cndIFUcBIWSRcUmeUnezb33OCSGaNIcONPl4/z3/89BuVKlcYFAi0rGTUQ8JqBEnDi3gAIUVCDi/mKANV0dFIK4KCI0Z6gAcMOBHRzpKCERBrQ1nVL92ub1Z1FyWjwBc9QBZLOfn14/Omy+4LCIcmWNCFfvNd3w12HzJYeJiJ+VZ01aqm8vVS+93d0a9n6weMfxqVyy8uXd3sf9h1ESi7P/Y1pn6WCjcWf11vMwXs66LSYiBZh++/yV+2cv3yWljrFRFEfDvhBABCYiEVI66P3+3m59UJybuDw9zztTWN5Yql0cPY4wp8O4dfDqYP9BmBTnijRpd72xs7K+NxUAEQlxkA8LSZhfFT+DKU2kOCxOdPCUeC/einfi54Qu3k47zFOBKiiG0rN/g9JQDKh/MYAAa1KTdglqrkiTdmzWGWVIJAwoP+zbrFeqb59r7HB0gmRGJLTNOpULN70jm3UARmXtjDXt2tbtzRtPgig+ZiUJIG/l85vHX98/5TBBuVIlwJk0V6wF8cljVnm0k2n/6JsO8kSE0b0ByjvjvV10cdCao5GfPHEfOmAdLrxSmWTwB3dq3hFL9KsEAAAAAElFTkSuQmCC"
    d["dark_1x_ico_theme"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACV0lEQVR42oVTXU8TQRSde3dmupDth0RLASOJH6DGoJEIKjSBUMFUfPDv+eSD/4AHookkIJ+FaDQBQYJgFCvlo1st7HZ2d64PGypuRO/bTebMOffce6A508oiBYAA9Y6IiCjyhEd6RAx83/E80poYIaCQknOutT4VBgDO0ZGVSFzpvH4u3WwYuLtb2trcqNi2aZoAUKf9A6Zqtd772f7sYCKZQgOVUmbMrLnu1OSr6akJRETEEGlYVjzk8ZTKP36SG84DglLK87znz54uzE1LGRscGmlqOruy/B6OZzYsK46IruP03OvPjeSr1R9EDBEBoDA/u/31y/Lyu7290oOHo1rrj6srUkoi4gAQBIGVSPRlB1zHAcD6l4goY2YsJpcKc21tF7IDQ2/fLNrlfc4FAoBSqr39YjJ5xvd9OGE9Y4xIa63NhoalwiwAdHRc9TwPAJAxRlqHvrG/FRFxg9t22S4ftLSeD73EuvXsf6W1BjzWzxgDhIP9vchCTy4zCIJ4PJFKNZV2vjNGjDEkIiHk561P1epPwzAidwQAhmG4zlHXrW4u+PraByEEESERcc7L5YPFhdnGxsYIp+97FdvuvHYjN5IvzM8Ui9+EiBERD0Wbpvl6cqI509p18/bhYTUEE+lkMtV9525u+NHm5sbL8TEpRSgSwgQAgNaaiAaGhnt6+0yzgTGqVCqWFRdSLM7PvBgf832/PgXUgxNeas1105mWS5c70ukMF3y3tLO+tlosbkspEH9PDpG8IaKnlOd7jAEjIsaE4ELIcIGn5k1rzYUQUv47pr8AA2govUR21CYAAAAASUVORK5CYII="
    d["dark_1x_ico_theme_s"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACeUlEQVR42n2Ty2tTQRSHzzkzk3uT3CT10dRWxEKtja0obipoBZUWfCz8C1ypC0EpVhAE94rgykXFhbgQXEjduPC10nZjWvCBrdAoJpZaaLVpTHpzk3tnjos0tY3i2c0wH8P5PbBlSxs0DiIRAAIAADMbYG54IRsJEkZXg7LLrIEZSQgVIWmxMQD8TwwBwS/nLac12Xks1tyNIlRamPqZHfMK36SdAMTVb+UfBlhXl9v3X+zoGwzHW5AgqIKyIaiYzOtbX8ZuEkkgUSOF48Rq22i/1HPidqp/CNHRVa19k35w8uubezIU6zpyNrpx7/epEcSVnYXjxJCE7+Xbey+k+ocqJZ8ZkQQiZdPDhdn03OTj5R/fdw0MsnHmp5+IUASYCRCNrlpOW8fBK75nEAUi1eWRMhS34225ibvTr+7vOHTe2dytfReRCJF01d20vS+caDIBQJ2pq6/ZaGU35SbuAEJy53Htu1DzhzmINnejYAADfw8bkpa3NFNeWoq37qu5QKsGw3+HwbAxiKJ2JAAAFO5ihg3Wk9GYAKOrdqw13LShOP9xBWPWUkUWc6OVkksCG3KESCSU7+W37jktJC5knpIKAxsCZpLWcj6bGx9WETLGXxsiHXjlwkxL16lU/6Vc+lFh7p1UUWZDAMBGKzvxefTG7IeXdjxUu2ETALOd2JYauH7gzMhi9u3Ui8siFGEwAIArDUBko4G58/C19t5zyrYYwCsULScmFGTHH356ftUELgmLeS0GAIjAJqgUY8ndzR1HnWSPkJHiwuR85tmvufciFCFSNWY9VpdA+672vRXZGUjZUkUZ1rWuoW/MRgsZFiq61m5m3WDKbymHJDVE2mqQAAAAAElFTkSuQmCC"
    d["dark_1x_ico_keyboard"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACXklEQVR42pWTy08TURTGzzn3Du1M2TBNhI5dSCGAhPKIgUZRYiRx4cZoYkyMiRv3EGWj/C8uWBijG2MgKUIwceGGpwhYW8DKK0WxdGqdPujMcTHY+CBBv839Lc5378nN92FtnQH/L/kLI+Ix08z8mw0Rbds+9hEhhGuW7nFwUNJ81QgI4N53JIBl5YiEEEIyAxFdvXazrb2zsgMggssVACCitUT8xfNnhUJeFgv57si5yNnzU5NRy7IUKQGhXLalFACHwAyOYwsh+y9fSaV2JqKj5LBTo/vT6a8rS4vh9s7V1Q/zs9Nt4Y6FuZmFuZm2cMf87PRaIhZu73r3dm5ne1P3+w+/xHFsRFRVlYhUVbPLNhFpms9dTNN8qqoRkappQgjHdg5tzKAoyu5uamJ8bGd7q1w+eBkdTaf3AMAF08xMjI993k1JKRkYAAgAiLBYLNaHGgfuP2xuaQ0YwcGhYcMIGkZwcGg4YARbTrcO3HtQH2osFYtEBADC4/GGGppO1YemJqOx2PJG8mM2m4nH329vbeRy31zImmYiEUsm17sjvZlMemVpUQIAIgGAmc0kk+u67r99564Q4kLfJUQslYp9F/sfjzx68/qVqvmY2Y2SREDre87nq+6J9ObzlterBoyg16vadhkREZGZu870NDQ2SSlrdD0eWwYAPFEbqKqqun7jVlNzq+M4AFAo5P/IlMfjRUJC2tr89PTJSNY0sS5w0k2jrvsBEQAI0Y1SRQ47AIyA+/tp27allJKZhRDMvLf35Wf8jhQCsJSKa5GVOiiKcmwDmNkdln936V/0A9q5GLuOEqv4AAAAAElFTkSuQmCC"
    d["dark_1x_ico_keyboard_s"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACVklEQVR42pVTS0iUYRQ993vMy2BwHGacicgpyRYjlGhtKptq2QOkZQm1aCGBtmlVe2kvEi4MwQjbtQhSaqEQRaKWmRZOCDOZOjgvdZzX/90WjqEFWnd1FvdwuPecQ/7aIP5/1A5MoP3WmXfSiIiMVQJ4bxZJvUVWADFbVilvc3mJBFd08TcAuJhbJaFIagU2Qqjwtb5guA0s9pISSERff3rRUc6nVamQrmvpCJ2+/vXN42IuKbUGyJQtoSSACmA2xgipGy7eyy7dnRu5L9gYZ3VoI5n7+eV5sPFSYn44NtkfCLfGpwbiUwOBcGtssj8RfRVsvLA4PZhZXKjyHKm8hE2JSGpnNQmtnR5jFYXQNlcNACG0zeXVTg8JrZ01QipjytufZJbatrY8MzfSnVkcN+XC7HD3RnIewOxwdy4ZzWficyOP1lY+C+XY8kAAgFClQs4bOh/pfOZvuOIONEW6htzBZnewOdI15A40+Y5fjnQO1oQiVnGdhNhWM2Vlc6bi78d6b6d+jFvF9dGe9uzSRwCjPe3Z5emN1Pex3jvp2Dupq9hYFRqRBJDPxJMLEy6Pr+XGSyFF/dkHICoX1+vPPfzw9Gr0bZ/daWdmIgVAgaiQS9irxOFTHaXNVeVwuwNN2kFsAVTx+9DJW96jcakcrmrf8rcVgMnn9yvbgRNtT3zHzrABgHKeeXfKtF2AQALp+MzE0M3NbIz8gYNslQByeeoAARAJ+WdAjMVgIuRSMWPlhXKQvzYIIjCbcn6f9ANS2UESbNTvOkjtwv69YbDZ1Tfeuuzf5hcp+gLnmLv8fAAAAABJRU5ErkJggg=="
    d["dark_1x_ico_folder"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAABq0lEQVR42p2TP2sUURTF77lzd3bGmYgSzC4pFMGwkSgWQWIRBCvBQgixUAQbEaz8MjYWfgULYcH4BwtBJWAVJBBQY61JVmLCDs7MPRajmzWbTdTbPR6/9+6551w0muPy76XyX2UiIgJV7Lpw9wMw9zLLfpAuUsFUDaIoIjkUI5mmI7MXL0VR7HShBGafVz++W3xTC8NBAABJK4r88pWrZ86eW/v6BaokzWz6/EwQBG9fv6rX6/3dqmpRFKpq7kySZPXTh4cP7kdxTNLd567dmJu/PnNhFn2aSarq8vul50/b1jurKgAIXLz9+NG3zvqRo6PuJSrBQJHnpyZardNTL18s2K7WKTSzsiyePWn3D0RVt7e3bt66ffzESZI2KJokgENJIn9iIlKr1QD0fNujBn1z954lOxhUARXZ2ysAUK2+2sHcPet2RTjMYlXNut2yLH5h1QNxHE+0JsMwHBYMAFmWpenhSrkJ+X1zszU5defuPWC/ZFdJWFlZdnccG2um6chYo1mWxe9M7odtrK91OhtoNMfdPc9z4OB9IcWqEpEgCMyMf7FmqIZG/gTUXL6YNCi+BAAAAABJRU5ErkJggg=="
    d["dark_1x_ico_folder_s"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAABuklEQVR42p2TvWtTYRTGn3Pec3NjSIK1cBMVqoMSKA6idNE6OIgOijg7ipO76ORfII4ugn+AqwgqdHBQB50Ev4YSl/qB1IhJe5t773kc2sSYNlY94/vy4zznec6RRnMP/r0U/1UGABDRcZ5ebIPRsyztgT58FTUr10EA3Boji7jamJ2/auU6nAQ0YLn9/MOL2yGqADJOiIA0z9dmT9/cfehU9+snkQgs1OKZo+c1lBaf3bK4Sh9VoZ73VSOZnqodu/SE4NM7J6JynSQ9P3zh7r65s52lLyIjM5Oiqx9fP3z7+JoBIAvRSDSIKAT0/NX9KyudxcrO/XRC1nVKka8mB042WufeL9zYcHKoAvRgZRb9N4+ugxyRF/q97tzFe7tm5km3zS6RDgmlyvRvRmgARKPyenObEAw350bPh/3tl68SRMIWjm98B5EwmHOA0fMs7QDkSOhjIrO0yyIbYCIAoh215OAZK1UnYqJZ+j2uJqCLqAFc+7HUaB05fvmByJ/Wl0QwfH730j2XJEniarOWtLzwbdaeVAu95fbKt7Y0mnvpWZGlkL84GEKtpBYbQAlRZPGEXR8bESRB/wlokLUo0bEB2AAAAABJRU5ErkJggg=="
    d["dark_2x_toggle_on"] := "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"
    d["dark_2x_toggle_off"] := "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"
    d["dark_2x_logo"] := "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAIAAADYYG7QAAAFmklEQVR42s2ZTWwbRRTH/+/N7trrXScxjZsECJSgKCGFClWliPJRcYGIABIICuTAgc9LuXFARagVcOAAJ25ckWgBtYVAbiDgwEdAFSRpQwMqpYWmcUPzZTtexzvzONhJqKiE46wTnua6M7997//ezLyhltYrsWTEli4VdGnBT3e19TyUat+VTPfEki1iABDWakKMYjaTnRqb+eOb82NHc1Pjyk4o2xUTrjAsAxGrUmHGbdrSufullq6+mNckAqMhBhEaMViBCMX8bGZ88Nev3ijM/m67KTH6EiAiLgWzmzv7bnrw7UQqHQYwxgAgoih8c4mfRAQAM1txLMxMjQ68cOHXQTveJGIAKN9PElulYOaaHc9vf/QdVl5YDEFExHWgKf8jEREgelFbsWT7zY8EuemZs18rx4MYlWxIlQrTmzv7tj/6TrioxYBY1YHjsmQsxogxbT29s+dGspkR5XgqEXfiyat2PPEBW64YEDHW0YhIBCA0d9w9OfZRGMypuEM9vW+lr98ZBppYYd2NiETreIOvnE2TY4fZb+5u6eoLAyHaAJolJhUG0tLV5zd3c+vWh2Oeb4wBETaOyBgT8/zWrQ9zqv12kVV9Wy/BiyDVfjsn0z1GV6tlJiyGMIjem0RsNJLpHo756Wp2BiKEGo0enrwbpRBGwBEzkRjE/DRL1QEjQrCIvluwtw+FIkIdORNEhFdVA5mQLeCuG3GgH24MxRJUxGVr9WWQGSLYtgUvPwYvjiBqJq5JgAg1OlrwyuPwYhEz1TiTYmiD65aY8kFkTLVPs8y0vx8drcgVomFa0xyKYQyuTeNAP7rbkS3A4g0FKmvcGCRieHkPbmjHfAGW2lCgCpOsMM3l1xS7aKTIVGHatwfbtmB+oXamyPKVCSLwYtjfj/t2YLZWP0VZ1IggAgKevRcP7KyRKerKTwBgBM/cUyOTVYfDFiAVJgADQ2jyIECVm3jEHhKBNjACIyhpPH0PnutFLkCoqz1CWZG7R1268P23oKUJb38CIyBA6g1UXqYiZ8LpDIbGEXdgDMrra4Hr4OpmnDoPx/5vImuNAfrnGU0A38XAELIFWGpFNOUS5VhVyah2DWkDIpw6j4nppYUN0g147C44NlI+Gr3KSPmwLUhd014bKMbvF7DvXXz0bcU9TBDgtm4kHCyG0GZlVH+x4doiZSmczuDVgzAGx05hbqESOxFsbsQdW5EL1qtSaw0i/DaJ1w4hH8CPYzqLz4crWinbg7eiwYU29QcygoYEzlzAa4eQLyLuIDSI2fj8JxRDMIMAI2hLYdt1WCjWci1hVKs2GEHMxomzeP195IuI2xVxxCxMzuD7Xyo05cDdu722S5KUu1LV6YaxUMSbRzFfqNAsZzszPh2ClpWCdNO12HUD8qt0EhFxMTdFjGr8RIRiCYslONaKXMqecx2czmD8TzBBMQqL+HIUExfhVJ3tlZZobsrKTo25TbtDbappx5Q7DZfNYS34+Du0pfDZML4YQWYGSiFmV5vwIkYplZ0aU5vaOtMddxota+mdCWArXMziq+P49iRKIdwYFGM1fRVRFv/503s8eeJIMZ9jXt3Xl1e9wfwCGhOwLZjVFEOIMHMxn5s8cYRzf53MjA9acRLRa9/tLbW6urzEo604ZcYHc3+dVMlk09zEsdaePVbcEyO07n00EcM2B/MXh488JXqR2XYLc2dGB/YqRUQi0Tbuq6AhEqVodGBvYe4M267yPE85XjYzEuSm23p6ARId1qdl/m8YzZaybB755MWJ4wdt9woxofL9JMQo2505+/XsuZHmjt3xhqRoEjGAEKE+TwvCzHaCg+zUjx8+PXH8oB1vKotY+X6yknVOIpsZmfz5Y2U3JlLXOK7LigCCRIlDTMomZVEpmD03cnj46LNzEz/YbmpZKvR/e576G558nRCcF5InAAAAAElFTkSuQmCC"
    d["dark_2x_ico_mouse_l"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAEsUlEQVR42u2X229UVRSH19rnsuecmQrS6fQyFFpK78UqQU1QCBcpUTSNygNPGuOD8d/SmJAQjSGBoAYSEUJ8MFxV6LTcDBXaKu3MmXPb+6zlwxgc6HQuoj65HuZhzt7nO3utvX5rLezs6oEWDREBgJlb3Wg2v1QIAQBJkhBRBSkMAwGYuUmw2SSGiILAZ2bHTUspgUEnuuyVmNm2pWmalS94WpgQIgwCmUqNjT83ODSa37jJTacBWMXq/v17c4WZwsz15eXfHcdt6FtsFDMMgvLw6PiBqUNd3XlE0FpXu1GgKBZXzp098/2F70zTMgyjDs/IZNrqkCjRe/ZNvTV9OJ3JhGGolKqQiIiZTcPQWhmGMT4xmc123LpZUEpVQtsaTAjh++U9+6YOvj7t+16SJEIIRETESpzm7909/c2pjlznuvXPlsulzX0D2Y7clcs/CGG0BkMUURQMj4y9OX048L2Kz6qes2laCwv3Txz//Mdrl4mS/i1Dvu/19PQSUWHmZ9uWNZ1Z88jITFKm9k8dwqrEWp1tbjqNQnx18vjpr0+6bsb3yzt37cnne+M4qrlF1HxLFIVbBoa6u/NRFD1+pseMiBDgmXXrL5z/dm72hmXZUsptk9uVUs3DgJkHh0ZqbnjC23/+Il44fxaAtVL9A4OO4xDR6t1i9bGSJHFdN7+xV2tVh0dEYRhEURgEPhHNzd5YWlpAxA3t7dlsp9Zq9ctrJDUzS5ly05m1RQGJyHXdoeFR07KAARGUUlEYMYNt2em2NpqnZhWkWu6YGeCJq4VxHOU6u9/74KPqP5NEa61sW/IaX9lYrqSUgLgKB8CPixMCJE+hjYhIRDfnCkSEgAx1dA+ZqbOrx3EcWHtZHRgjolLxsaOf+n65vughYhxF73/48dbBEWb6+6pv27bWuiFsrdxvDcZVVn9Z42oF/6H9D/sXYZUiCa10TgDwSDjWupa1S4zWOo5jZpBSum66YefEzJZlpTNtzEREzdYzZhZCeF7pwa/zQgjHcXs39dWXf0ShtWrP5rK5HDOvrCwvLjwwTWu1lNQ+GTPPzc4IIZRSO17aKWWKiNZ0jkCl1Isv77QtaRjm3Tu3Pa9UUwRETZ/YtiwUrheLK0TUnc+/unufVyoi4hOdEyIahlEsroyMTjz/wo4wDADgp2uXhBA1A1274TEMo1QqMvP4xGS57PVv2crEt27Naa2EMCtdFgBorcIwGB2bmH7nCCI4jnvl8sVzZ89Imap5rWrDmNmy7Du3b7ZnO/r6Bny/PDq2bdPmPs/zPK8Yx3GitWEYHbmu/VNvHDh4CAFsmVpaWjx29JNK1FvriCv9gUyl3n73yPDIuO97lmUzwMPflpaXHzJzOp3JduRsW4Zh4Lru4uLiF8c+m7/3SyXALbffFR4lye69r72ya68tpVYKAIUQgMBEzGwYBgBevXLx1Ikv/XJZplJ18qRBr1+JTRD4+Xzvtsnt/QODGza0W5YNwERUXFm+e+f2tauXZgvXTdNqOMtgM8OgECKOY6Vix3Gz2Vw6kwHgOI4XFx54nicESplqpspgk5NnRcCISGtFCQECIj4aW/7JYbBaJC3LRvsv2WxmBnxkfwAXt40QjVoA5QAAAABJRU5ErkJggg=="
    d["dark_2x_ico_mouse_l_s"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAE9klEQVR42uVXTWxUVRQ+59z73uv8MKXttDOlohQKQ8ECJjZoQEIyIf6ioDHqRlfGBBdu1GjiRl25MLjTxMSVO5JqSDAkxcSYJmiigIqNWofyZwszdGin8/fe/TkuOiDQmekUjBtvMovJy73fueee833nw0RyFSxvISAAAHDt1/qSrWMgEQCw0WwNAAASkQMIzBaY/zUwJMFWq0qB2bihTsdbCQBW+34px2ylGyHp1SK4QzAkqaqz0mtPbtrXs/6RlX3DbrgbAIwqFS6dzGWO5SZGy7Pn3FAHAwDbZkc1fTMEAFXJJ1J7N+55L5ZMIYLRtQMRAQmQoFrIZcYOTn7/sZAuCZcb44lodEUTMGuDDbvfGdp70IvEddUYde0oC8xIEqwGEpHezelofPPM5DdGlZFko8KhZtmr5Ad2vrXp4dd1oHVgkQSSQCRmFi4WLp06NXKglP9DeuAXg9Xb9m7b/5m1qkmx1L8ZolD+XCL1+NATHwYVjSARbwzLCknz2YnTR16d/vULazne/1BQ9ttXrWXrZCe+km607uPVBUMAQzJ039Ofe9FOa/BmJABgIal89a/Lvx8m4V4aH2GG5GBaVUzX3duzma/9wkUU7uJkUt2G0n4xvjYd612rfbMI6R9IthoQ2mJ9k8cPXsl8Jx0hPHnX0AtGVeruorrty2x61j+KyE05AhEFAiEKADpz/CMGthri/Wkn1MFW1YimGRgiG+WGuzr6ho3GxtcCtlpVZ5U/F1TybFUuM1q6ch4QQp33ROIpo31cdLislx0jvU433M221mqL78QWnHBnz4bHhAwxMCIaVdH+HDBL1/EiCbZ68V7ZKGxmcx178XcdmBU9925/8fBNmwwYbaWLzHq5dLUQF0pPYMMKufnvrXuXxY0IbNXMmRPWKkRqSu3IbGKJLTIUux0iZmBE0Kr446HnVHkGhdMEDJF0MP/AS8e6B3Y1CWlJ1kfpRln7S4IBAKK8U4lhtswWllJIZrukcBP8h+t/CcbNm6Zxa8IyxRMRUAAAMzOb1vD4OnEgilbBENFq3wYlYHC8kBuO1yW6W0pROGEvkmQGtkYHxdYkhhnJDYrZwuWfkNgJtXWsftDoShP6RySjq5GuVCTeDwzVuVwxNy5kG4NtUc9sLjOKhFbxmvtfkV47WwOIjaYVqyprhg9I1yHB+fNjQTFblwSovsS4kezEUb8wZy3HegfW7XzDL04jEpK4MZ+IRMKtFC4mNj7Zt+0ZVTUAODV+CEjULZH6Aw8J15+fZra9m9NByY/372Dm/OS3RleJHCSBiABsdUVVZ5OD+7Y+9Qmg64Tk1M9HMmMfOF6MWx54ANhKJzxzbizataVrzWBQVsnBdMfdO4Jizi9e1sG8NT4JJ9o9mEq/v3HPu4iu48rSlQsnDj0PbIFomRMxEptAerGt+z9NpHYHZSMcAQzlqxfLs2eB2Y30ROMD0hWqapywKOXOnhx5eW7qB+mtaDT3Nxu/EcmawFq9ftfb63a8JlzH6oUwrikn115n6pcvx4++GZSz0os1cRi4hD9DAmBVubqyb3jV0LPx/nSkc4AcuWAhqoUL+fNj06dHsn+OCukt6WWwFTOIJExQMqrqhNoj8Q1epAcATFCcz/0WFHNA5HgxBl7SpWGLzhORAImttrpqra7VvWwj4QDXH4pu33nW9BNAOGGx0N3MzNyKB7y+/gYRg34DptoGtgAAAABJRU5ErkJggg=="
    d["dark_2x_ico_mouse_r"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAEu0lEQVR42u1XW48URRSuqu6u6u6ZfWFmZ9mdXdx12WV2l5sENEEkgLBEkeAFE16MDz75r4xEg9nEGBPjJRETJFET5bJcxJ2FBQwILMJceqa763KODw0DunMV9cnz0E9V/VWdr853vkMHVg+RHoNSSghBxF432t0vZYwRQowxAJBAMsuihCBil8B2lzAAEIZ1RPT8lBCCINFG14IqInIubNtOTvCkYIyxKAyF607PbJyYnMoPr/FTKUJQSXXr1o3LxYXiwqVS6Z7n+R1zSztxRsOwtq4ws2//KwODgwTRGJP8kVJq2w6ltFwunTxx/IfvvrVtx7KsNnhWOt3XBgmM3rVn9uCrhz3f10pZlo0IxhhCCAAopZRSQojpmY3ZbP/SlaJSKqG2NzDGWL1e27Vndv9Lh4KgyjmPovCbr79cLP4yWZg2xtCHAQBxHI+OjWf7c/Nnf2LM6g2MUhbH4brC9MFDh4Og6rrexQvzc8eOnjt7yvP8zVu2JWCNSmCMhWE4NDQMYIoLP3Mumiaz6ZUpIgjh7p09AACe5128MP/Rh+/VakEq3edw3ioTYVjfvmN3Pj8iZdw4SgcwSmkcR0+PTw4MDhljqtXqV59/6jjcth0A04r/JJ+e523YtEUp1T0YQcSJyQJBFEKc+vH7UumeEAIRKWNN/9LYqJQcG5/wPA8AVi5kKw9ojPF9Pz88AgBSxhfOz2ttwjCM4ygKQyllm5rUWmcy2Wx2QGu18udNihoRhXD9VBoRoyjKZLLpdB+zGCFUyTg/PIIIrW6W7E319cFN6FZB8GFwLt488tafKg9BSkkpXQlJKXuwt4V02d1p/KP0W8yybZtgU8JUUu9/RxuTB7Z0ZREACKGEtNQhSiggDKwe8jyvzbI2YEgpVUrOHTtar9faix6lVMbx2++8u3ai0IrRrtLIOddadwRrfJ+oxeBj0X5Z525F/sP4H+xfBEu6IunFORFCGsLR6lk2bzFaayklIhFC+H6qo3NCRMdxUuk+REjku6sWg4iMsSCo3v7tJmPM8/yRNaNaq7adhWmtMtlcNpdDxHK5tHzntm07K6Wk+c0Q8fLiAmNMKbX12e1CuADQMjmMKqW2PbedO8Ky7OvXrgZBtakIsKY54VwUi5cqlTIADObzO3buCaqVxGv85ViWZVUq5cLU+s3PbI2ikBBy8fwZxlhTopsbHsuyqtUKIs6s31SrBWNPr0XApaXLWivGbMYePB+tVRSFU9PrD71+hFLief782dMnTxwXwm36rJqDIaLj8GtXr2Sy/aOj4/V6bWp6w5qnRoMgCIKKlNJobVlWf271i7Mv79t/gBLChXv37vLcsfcT1ntzxIk/EK772htH1hVm6vXAcTgScv/3u6XSfURMpdLZ/hznIopC3/eXl5c/nvvg5o1fE4J7tt8JHhizc/fe51/YzYXQShFCGWOEEgRARMuyCKHn5k9/8dkn9VpNuG6bOung9RNuwrCez49s2LRlbHxi1aqM43BCEAAq5dL1a1fPnzuzWLxk207HWYZ2MwwyxqSUSknP87PZXCqdJgSllMt3bgdBwBgVwu2my9AuJ8+GrddagQFCH0wxST39k8Pg4yLpOJzyR7LZzQzYiD8A7Wmoqt7EML8AAAAASUVORK5CYII="
    d["dark_2x_ico_mouse_r_s"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAE+ElEQVR42uVXTWxUVRQ+5/681/lh2jLTTqGgFArT1hTQ2ESFEJJK1BgQYoiwMK6MiQvdKNGEhT8L40aWmpgYXUoT4kIJAhtNNyYCUbSYYFMK2ErH/k3fzLz37s9x0bHB8mbmIcaNN3mb9+47373n5zvfwXzXeri7hYAAAEC1J/4S8TGQMQAgo8kaAABkjElAILJA9K+BIeNktaqWiIyTWCvdNgCwOgjKRSIrnBQTbu0E9wiGTCh/QbitXQMHO7c+2dY95CQ7AMCocun3S8Xx88Wr5yoLk06inQCAbCNTDWOGAKCqc/nC/r5972TyBQCwpuYzRGACEKG6WBwfPTHx3YdcOIw7VB+Pp9NrGoBZG27be3xw/wknkTMaGAciIFO7g1HWKBJuumtgOJ0bmJ34xqgKMlEvcVgj71Xnene/MfDEa8oPkYNRc2Nfv3Xl7HEukQgAERlHxslQ4KmNDx7YcegTa1WDZIm+GSJXwWK+8PTg/g8CL5At7vTYl5dGnv/t8kmZaNuw86g1hIgru5FxVQ1b128mK2eunhZOOjJ4kTdDIi3cTN/j75EFmXCnx05f+PxIUC66qSyXyWgXMamqdstjr7R2D5nQA2SxwBCZDrzc5uFMfjMZCpfmr5w9JmSSixZrVd34I5K1IiE2DB41qooxwQCRyHRufYqAuIuTFz+rLkxyNw1EiDzSysopjYJcz7BMtJNVgE3BEMkoJ5lt6x4iizpU0z+fNNpX1XkVlJS/oMNy/exlVlMye38qVzA6wDuMRxQ1kRHuWifZAQTa91PZbS3pdcA4AtOq3NY9RFQrwTvLkoiEK91Unqy+c08dBiELZIhAOGseOvzpqi8mNIARGV7zMAGRvlu6wr9M/P0tBy545HajavUefe8m3IhAVs1OXLRWYZ3/b0tFk8lvF4nMPyFiAkIErbwLI8+pyixy2YAaEJkOlx554XxH754G3aYp66Nw0qSDpmAAgCjutcUQWSILzTokkW3auBn8h+t/CUarCi6W8Fr9bxwwREAOAEREZOLh0QpxIPK4YIhodWDDMhBIN+Ekc5FEtyoVuUy6qS4iIGt06MVrMUTInNCbKd36ARnJREv7xkeNrjbpLNpPZQupXA8Q+ItFrzjGRQuBjdnPbHH8HDK0ijY9/JJwW8ma1Sx5m1qxqrpp6GXhSMZp7vpo6M1EkgCLbjFOaubqmaC0aC1l1vVu2f164E0jMmT8dn8iMsadaulmvu9A985nlW8AcGpsBBiPTJFowcO4EyxNE9l1DwyH5SDXs4uI5ia+NdpnTCLjiAhAVleVv9DVf3DHMx8BOjIhpn78anz0felmItVDHd1IVsjk7ORoOrs9u6k/rKiu/uH2+3aFXjHwbulwyZqAcZnu6C8Mv9u3721ERzqi/MeNiyNHgCwwdpeKGBmZULiZHYc+zhf2hhXDJQeCyvzNysI1IHJSnelcr3C48o1M8nLx2qVTLy5OfS/cNfV0fyP5jcisCa3VW/e8uWXXq9yRVi8fYzm0AFSLztTlL8bOHAsrM8LNNJgwsMl8hgyAVHW+rXto/eDhXM9wam0vk2JZH/ilG3PXR6d/OjXz6zku3KazDMYZBpFxE5aN8mWiNZXb5qY6AcCE3lLxl9ArAmPSzRBQ0ykNY06eiAyQkdVW+9bqWt6LFsYlEBCZOEbiTp61/gnAZZIvVzcREcWZAVfWnyvCf299V47pAAAAAElFTkSuQmCC"
    d["dark_2x_ico_window"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAC1ElEQVR42u1XTU8TURS9931NqR0S0XZoExYCBn+DUXHRsGBtwgJjiDv/lBtN1JiYmLDQKBs0caE/wAQlQqHAQlo7VKedmXdcTKilfHaILMTJrN7kzXnn3nPPvY+94RKd1SPoDJ8zBVOHfWDm1D8FiAjHgzEzM8dxbK09DQkpJREBOBSMmaMoCsO26w5KqUDolx2ImAgg328wszGmG0/tRQpz7uCtyfLo2FWp1IGhOGEYtzaq7xYX1iorxjgdPE6kn3ByXffe/Qf5QqHdap0iZwxYpVQUxU8eP/yy9NlxBgD7hxkzh2H75mQ5n/eaOz4TB61f6fAAaG3iONLalKemV1eWAUvMBKgEKo5j1x0cHRtvtwNmev700fp6xWiTnKgvWhbWMc7M7NzQ0OV8wSuWRla/LRvHQYcZAKWU0pqZgyDYqFbarVYcRT1yOhEas/+jXq9t5/MeYLs1orrpJ6vMDFAURZ2VfsFiazspOFiNu7mF1ubOzF1rbSLjdALxhktRFCqljipqAEKIK6PjROkdhJiiMNw97nF2BSB1kREdurUHDEkNvHzxLAgCIUWqKFIUhuWp6WJp5Ci7StJrrV3+uvSz2ZRKphNIq9W6fuO2EKKncg4Oo+M4cWylTAnGLIQQJ20xAAALcAqwRI3nrFP/B/snpqvE7JlFuubJLIgIB81LvS0GgNbaGKder+lUzROAEJwZyCZ797UYQErp+43NjY2JaxeVUjOzc/XadgoHYWILm8kMeMNFa22z2dzarGqtsZcZM4v3iwvjVye0NkNDlwoFD+l8nwnWWmuz2dybV/O+38gMZJOoylzOTaKolKrVvq+vVTyveCGX220V/b8AiJo7O29fz3/6+EFrQz2jXJdhB8aYYmnEmCRhacZUAFubVb/RcDKZPZx7rkzMArBhuw0gZa8GEZPWWkrVM8PvHwssERnHOdVYQACw/7bwd8aCc2dXvwEgU52sLypScgAAAABJRU5ErkJggg=="
    d["dark_2x_ico_window_s"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAC7klEQVR42u2Xz2oTURTGz7n3zp00nbS0NabtprYVVCIiWlAE/2EfQSgi+AbuRPAFii7EtU/QRXHhTvyzsgvBUikK3ZQioSUGlaaJTZOZufdzkdjGmKbNhHYhPTCbzMz9zbnnO9+54dTgMB1WCDrEOFSY2uV3Ju5gVdSuvWDMzMKagKztaMekJiLA7gpjFjasBEEplhgUUgMg5rZzYiLYSjFHTEp79TxVTzJh2fWG0tceDozdlDKOiFsJginkFpbfP8uvfqjncU36zAh9nRi8fO+Vlxw2PnVYM6HIhubjzJ3vy68dtwcwO5kxiyAopa8+SiSHK5sBsQjLG8SyaZ1bBhOsdLqEcaUjz0xOr2fmqqRtGMP4bmLw2Nit0AexWZi9u7E2L3W8ocL7QDGska43MTXb3X/CS473DF1cz8wpnQBMLTMAQrmsXGIOylsb2QXj/zKmTEDbOmRZLq5u5TNechQgpbu3v7hOjQDBVsVPsCbcYugIMLCwJmQWf1Y1u0ifBEDK6b5we8baIGpjM2ASqXMmhFRcrzT1r5BYOAOjlzp0JhuStbZB003tCgAfuDeCwExBsPnl5X1TLpCQUTaR2IRbpyene4fSDRVXzfok+Lnyzi/9YBlFIMwirBTHrzxgwXvBiIhYub0wIUsnGoxZslD7HTGAAQxBRIARATBNref/ndRHsAOFdegg3HQF1Vy6MMySWbQ/PIlZEgEIW8IAAggkHEdpr5zPCCcWpc8AEtKJ9dZerVuhCoOQulLMFr4tpk7dkCo2MfWilP8qIjgIM2yoYn2JVBrW+pv5Qm5ROl3V+VmXGYvluSfJk9elo+L9I97xEULEilXHsI7T0punlWLWifVVR6j0vET1Aanc0vrKxtqnntRZ3Z3sSB8gfzO79PZxZv65dDyihqPcjmEXpPZ6h85LHQeiyJIJgC3kPleKWeX2/HWr4S8TswSMCUrtnqsaQjpdQmpY00r6tdOk9jpsNcA2kFqMGHvkje3EbwXRZlCfdhpDAAAAAElFTkSuQmCC"
    d["dark_2x_ico_theme"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAFCklEQVR42r1XW28TRxSeOTMe2+t14lxNQhMSEjshfUJIEYJwS1X6gIS4qBU88d/6AqpAQSoSRQjKA6USl5AEGohpSyGxE2Lnir3r2bn1YRXXOHYubst5XO3Ot9853znfGRzf04k+VwD6jEHr+AZjjBAyBiFk/hcwjDHG2BijtdZa+w8JIf5DY8x/A+bzEMKTUgKAZdmUUoSMMaZQyEspAQhjDABKP1EnGABwXkQIx+Md/cmB7n37W1pbGAsZY7RWK8vL85m51Mx0em7WdZ1QKIwQ2oIlrqVGn5DjFHp6+06Onu7q7g2FQsZoKaUxBsBXFgYApWR2cfGXhz9PTTxjjBFCa1GsDoYxVkopJU+c+vrosVHGApxzrTXeqB7nHGNs2zbG2PM8AKA0MDU5fvvWmOM4oVCoKh6x7WhVJBYMnrtw6cjRE0J4Qgi8EQghxoJjN67dv/tTJjO3troSa2q2IrbrFrq6e/b3Jedm/1pbW6M0sFmr1cGkFOfOXzp4aHh9fRUAfIx/viF0YvxJJj2byy6mZqanf3shPNG7P8F5sampqbcv+fLFcyHERqprgwGA4xROffXNkZET6+urhFRRECH0xdTztdWVcNgKBJjHeWpmej4zNzAwZJCJRhvi7R2TE083fwufcgLOiz29fUePjTpOgRCyhVA3ek4RQmw7+vrVyx+ufQ9AikU3OTg0fHjEdZ0KchVMDUb45OhpxpjWGiG8k1Y1xiilotGGP/94c+/u7XA4zLk7cnw01tQspSwvAZTTEsJr39PR1d3LeXFzxrcOpXQ4bD19/Gg+k8YYGhob+xODnsdrgSEpZX9isJZwt2UIAJzzJ49/pYGAVio5cIAQUt7jUJ4NAOje16O1xrieoW4MojSQnn3n8aJSqqNzbyRiK6VK5KAkd611JGK3tLQpJXdYrU2hKaXLy0u5XBYALCtScdonzCilLBjc4QivygxjLIRXyOcxBkIqT4MKXdWNVEOnpqb0/db5l8cDEMaC/n9XnAallwghhUJ+ZTnn21V9Dq6UisWa2trjxmjXdZaXsuVDEj4diXI+kwYg9eYSSyniezosy8IYL+Wy+fxHACgls1wgCICkZqaFFLg+7SMDAAcPDWutCaGpmdec8/LhUA6mGWOZ9Gz2wwJjzJjdFc+fionkgf7EoBCC8+LvqVeBAKupRn8EPHr4YLeZJIRw7jY2xs6cvSiEFw6Hn48/WVjIbAWmtQ6FwpMTz6Ymx/3m31YRAIAxOE4hGm347vKVaDRKCF1cXHxw7w5jrEJoVewqEGC3b421tbV37u0qFPJVjcZ3bSmlEBwwDAx+eebsRduOKqWMMTdvXC0WXcZCFbWgmxuFUuo4zs0b1769fKW1tc11ndJCUArheVLKltb29vb4wUPD/YlBITy/i3+8ef39u7eWFdncstUXHr94ViRy/uKl5MCQ53EpZWnbAYD5TFoqGY93WJaltRZChMNWdvHD2PWr79+/tSxba7WLVQ4ApJRKyeHDIyPHRxsbY8ZoIYS/ETPGMMZKa8CYEMo5nxh/fP/eHV50g8HQ7la58tXRdZ1YrLk/MZAcHOro/CISiVBKtTb+jFjK5d7MTKdSrz8sZLZeGrcBK6foeZwQEonYzS2twaC/EevlpdzHj+uexwMBxhjbdo7jndzPSrcKf3M12iCEEEaUUgDiD6Sd2AXdqVUY47MkJLhhhma3RkHrMJH6POFz3zz/BtOG3VckIMoNAAAAAElFTkSuQmCC"
    d["dark_2x_ico_theme_s"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAFWklEQVR42r1XTWxUVRQ+59z73sy86dAfmJYSKAhDSUBsEHFhGyHxL4ILcaHRxIXBqIkJC6KJ0Sgbly50ZUhMdCGQkCgYBRb4txATA6S0KoEWUMG2lNKfKTNv5r177zkuCk1pZ6CthDszm8nM+d5373e+71xsWrwE7tUiuIdLz/0vCAgAAHLjc/fBEAkQQYDZAPPEd6Q8QAQREb47YIgEANaEbCMklQgWkU4IAAhHxatsYyKt/DSSEnb/CwxJ22gcgDJNaxtzTza0dAQLW7VfIyLCLhztHR/oHOw5nO/rNKUxL1krICBV9xarqhEJAeJwuGHFo61b3qlf1uEltQiwBRHAm8IiAnZQGDpz4fgnfd37lR+Q8qtRrAyGSOxidvHqze+uat+lfGUjEHaAEy+0UQGR/Jo0IrgYkIA09HUf+vPoWya8ppO1wnZmWVVTk5nJSVys/Ezbs3tWPvKKM+gMI9LEW0C0T10HX+v58f18/+lSfiCoW+EHQVwyDcvWZVc+NvrvqXL+stLJmVqtAIaIzoZtz362bMMz5fEYSSFObUchhZdP7x3rP1m81nu158jAma+dMdn72k3kgvqmRfc90f/HAWdCJD0Nj2YqIg6vrd78wdK2raV8TMqHG2017YEU6YSXqvPTWVMaOXvsvRP7XmB73UYmvXBp2/bP2cU4gxlNOyobjTes2LyqfWccOlJedZ0KiAg7YYvKS9Q0Xjn7zakDLyORKdum1o4VD78Zl8aQ9G3tCrF1y27la2GoyKkSrrAzyUzz8MXvz/3woZfSJuJcx9upuuVsy4BYCQzJmjDTeH/Dsk02EiQ1JytiZ7xUwz8nPx0fOE+IiQW12dxTNi4gqgpgiMS23Jh7Wif1Hb2gIkEkbaPC3yf2kEZhWdy6jZQPU5xsCjNhIt3Q0i4MU7nPAU1Y6cRY3282NuxwQfODfrqRnZmsRpO8hI2XzqYX5tgBzjN6mHQyHLlQvPYXEnhBJr0wxy6arEZTnktIJ7SfEZlvXgkgkjPFqDiICKS09jNSeRsnAGcXFnfIiZsynlZtGhhX9LQ5nRuSp/w0CIiwsJvaPzT5I1J+XBwKRy8qDQI8P0rORam6lprsGhYwpbA40qu0P1ntlj5ztpwf6EQCmNe5ISi25UzTei8IECEc7o0KV4j8yWo0bQcGe75zZkpezbnVVMuGHcBACgZ7jrioAFSpqUWc9tNj/ScLQxe1j3NVCpJnyqPZ1duyuQ5n2EX26vmjyguqqhFJuej6hV8/QkKYCxgqz0b5ZG3L+m0fO+N0ii537r1+pUt5AVQDE3Zesr6v68v+7sN+WrMzd1QEkkJUJhxOZJZsfH5fIpMlRYWrl8/9vFv56WlCoxl9ycpL/3F0Z77vrJ/2quFNTHZsY1MatfF405pn2nf8VNvcJk7YRV2Hdthyfqo0qkSMCGnfhMOnD71eHPrbDzyZGHFuXc4U2UapuqXN657b9NKhh17c76WyACAS/v7trpFLx3VigYib3cBD2kbjftDYtn1PU+sWGwPbiWmHAAEJ8wPdYuNM01ovCISBjegUFob+On3wjdFLv/jBolkPPAAgrLykM8W+rv1xmK9d8kAyU0OaRBAExXFQvzioX4LkAQApYBdfOvlF51evlkYveKn6ajaEt7vFIAGIKY0FdcuzuccbW7fWNm/004tIgzCAQFzKh8O9g72Hh3qOjQ92335ovBPYzX5gG9m4QMpPpLNBQ04nakQA2BVHesrXB11cUF6g/ECEb289OKv7GSKiAmF2hl0kN+cT0kkkD0mB8GxMQM/Sy0XshHC08iaNXIBBZPZBoeccIfPP1nt78/wPz7C4/PSjYtMAAAAASUVORK5CYII="
    d["dark_2x_ico_keyboard"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAE00lEQVR42u1XW29UVRT+1r6dM3NmIBbbaasYwyX4brgEAoTQtEhJw0UCRqPGN3+P+qKIkEChQSsmFNtpxyreHvQHmGgItNApD9rOTGd6zpzL8mFPh9aWWq2QmLAzmTmzzsxee33rW99ah3LtnXhSS+AJrqfO/pOlVrQS0Tr3ZQbAqzkjIiKK4zhJkvXHIaUEwMwrOCOiKIrCsJ7NbpBSMfjfRccAAcyoVMpEZIxp+lOLPIWZ7IYDB7u2bN0ulVoOwj+F8UFx6ttbhXuTd41xrD/KtXeCKI6ibDb75jvvtra11YNg3Tkj5kQpFUXxlUvnf/v1F8dxmVkBEER+WN9/sKu1NVedqwCoB4EQgu0R7aFAsCdgZjzCQgQQAQknSqk4Vlqbru6jE3dvMzMByjIim92wZeu2et0nwrWrlyYn7hARMwsptdIA4iSOwhCA0loKuaIljMIkjgFIqVLp1JnX3mrZ1Nraluvo3Dxx97ZxXGVPppRSWhOR7weTE3dIiO6eXi+THS8MTxeLUkrHcXqO9gEYGxmq1moAHNd9aJmfj+O4vaPj0OEjlUrl68LwdHGqVJppbWtnTpocUQv5bMAlpQCo58ixPXsPRFHU0vLsJ+fer1arfSdO79y1F4AU8vrgAICeV/p27t5rKT54rd/zvFOn32jv6JRKGq0H+i9KqZubr1zUzI2bzc/GLxk2MdygNxgNS+ONFxLMWLTHqgrCzMroQv6mlNLzsuOF4SAIjHFG80OWomP5ISmVvRBEAEbzQ8Y4QRBcHxw4dPjI3Fz5q9EvtdGLy/lRcsVKylKpdPXyBQBa61QqDaBWneu/dB5AOp3W2iy3CCEmJ+58/OF7zOx5npRyLc4oimPP8068etZGVpy6L6VMe5njJ88CyI/c8OfnASy2BL4fx/HmF15sRlYqzS4vVrVcgqN62NPbt3P3vigMN27ceP6jD2q16rG+Uy/v2gMgYf5i8CqAru5ea2HmwU/702nv+MkzufZOpRSRGLh8YbkzsZrGPe4Ww8za6LGRIUHkZbLjhZEgCBzHHcvftHpRyA9pZexFkzKO4wZB8PlnV2ydjReG10oQKWWtVrs+OACGkFIpFYVh4PsD/RfA0FoLKQEEJX/AkshoIYRSerpYvHzxHIONcdZIEDCzlQxmTpLEGHP81FnXTTEnVsMaaklkI0uSRCk9lh8qTt1zU2mbgCgK1wQjMwPEC1UqpdqydXva8+IoJkFLcml1OGHjOD98/41tucxMJADwsg68RK6YWWttjDM7O6O1ATiOY6WU7/tSyjiOVmw99o/1wK8HAZGwX4UgN5VmTpbIlQWtUilPF4s7XnpGKXXm9bdnZ/6QUtrYhBCu6zKzEPIRAwviOOrq7t23/xCRsC3GdVO59o4kSarV6oPpKa01bD8DQCS+u1XYtn2H1qalZVNbW25Rdrlery/P9tLgks7nnichGiATOEmSJEmnM6PDNyrlso1SZjJZAEqpmZnf79+bzOU6vExmodAaYqqUllKt/mqqOMAWuOrc3NjIjZ9/+lEbY/eh5qxPREHgG2M6OjcbY5iTBgH+1cjDzA+mpyrlsuO6DwFf/GBBJJiT0IK2nimEAYLWWkq1eCpUf4EegHEcgNatTWzL9O+L+rEo49OnmP+jsz8BObio31ivW38AAAAASUVORK5CYII="
    d["dark_2x_ico_keyboard_s"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAE7UlEQVR42u1X3W8UVRT/nXvvzOxn15auLQ1YUozYFmMNNYEQFQLSF2MQUD5iJKaJf4IJhcToQ1WU+OQDMeCLX2DA+magyIOVGgWkasLWoDGtTSmf7a673fm49/gw23a1WyDQEGO4mUlmfjNzz7nn/s7vnKG6+gbcrSFwF8c9Y/MyVCWQQHc8MZfOuY0REQmjfRgzD0GTNgBmU8EYkTCB6/uFSLJeSJuZQXSbayKAjZsbA0HZiWl7atqSDopOYmHrk68uaForZYzvKJQM1tmxsxe+eW/8z++m7VFdfQNArD07Wb/ypa8S6QbtYV72TCiYQP/w6fbLF45ZThWzVgBICL9YaH1iVzLd4OZ9QAReloQKN7nkFNEUdQ0zz4GIkFxstFARqR1pyeb13deG+pg1CApErD0nWV/btC7wGKTPfv7i+HA/iMBMQkkrCsBoXweTAKSKCmlVRLQ/ySYAIKSlojXtWw/Ha5Yk0kvvW7ji2lCfspMidF4oh5QDoqBYHB/uB4nmDd1tm/ZHU4uK2RE3f4lZt3TsbenYy6zd/JibH/sncqmYHYmmFrVt2t/8dDcJmbs4MDkxTJJApOx4GJ4pNjIjDJeUADV3vNO08nkdIF7TeurDNV7+Ssuz7zY+/hwAISMDPZ0AWjpmkHNHd9rx2sc2f5Ssf0BICDt59tAWIZ2pufXsPKMSj2DADA6vGcyYuim5FV7xFFJ6ylz2DrPhmaSmORSEjVTRwRNdQgonXjN4sjtws9JOZI53hZ9kertClzO9XSE/Mse7pJ0I3OxAT+eytV3uX1cHv35NWjGwuYlcMVgouzgxfPqzFwAhLceOLmAYr3D59CebAdixGmnFAJQjwooKEb8+3P/tgQ1g7cRrhbTBfBMhJpAJPDuebt92eHXnserFq7SfZ6PtWLp9x5H2HUfsWNpo32i/HGGjtZ+vXrxqdeex9m2H7XjaaG+2AM0KIwkdTLZ07Fvy+BYdIJJa2n9wjVe48sgz7zeu2AQABgNfdgJ4eH13CWGcO7rTjtU+uvFAVV2jUABZZw5tBon/VIlhI61opncXCXbiNb+efDNwc8qpyvTuDkmYObEnTPPMid0gBpDp3aOcqsDNDXzx8kNrd7m5q4MnX79VgpC0/MLVgZ5XAAihhIrqoBC42TOHtgKQVpSEBSBwc2WIkiqavfjT9x9vAbOy4ySt2QRRFTWUpGU5CTCzCaQda9t4UEUSzAQisCnNQhTuChstFTK9b0yMnrEj1QwDAEFxtpzPDiMza4IozcgspLOgaZ0dk6wrVwNmKBu/nao1Rof3RBIAczCHMeZQEYRlKTtRHB8SVgQAa5+UExQnSKZYVy6nzIZZaC+nvVxAklmDGUJakdSUw6V4Ul19A5EI3Fz79p66ZWsCL5gcHymM/yGkFSqQEFaqYQUJdYPaRUTZsV/8yWtECgQ2gYpUV9W1koCXH+/7YGXgZkkoNZ1eF/reTj/4lLRUrKYxcX9jebeiPWa+UVfCzKmG5eXLDoXdjuH88X1ubtSKVDNrmUgkAZbKKVz/fWLkx6q65XY8/e9kVCTkTY7ZLPPyo+d73xo6vV9aCWCmLSi1IaHmpha2STsW1t7bS14CM5vs2M9ublQ5VTN4+Y8FkWTW2i/cOGi3OKQVFdJmoytTP6xyyk7MR8cDZlNuqXJSz8uy7v3F/E+M/Q1s+Hkz15B2wQAAAABJRU5ErkJggg=="
    d["dark_2x_ico_folder"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAACw0lEQVR42u2Xz0tUURTHzznvvnff03FEkbQZM0yTUnIfLVpEZUQFgYsocBG1679pFdQqhAiEEKKihURFRUi0k/yR0Q9c5CA578e8d89pMTpO4+iUY1Lgl7d5cDmfd8/vh+0dGdgpEeygdmH/H0yVvyAiAG58WERk22BRFIFIVZwIEJGjtTDXC2NmIjrQ00tkiQgiVtyIiMIw+DQ/p7VbF0wAlFLpdPPwpRHP80ySVMIACDFJzMvnE88mniqltuZPK51uDoPg6LHjF4cvG5MgolIKAMtFhMycJEn/wGA+/2P6w5TWHlQc2lRlNxOxbdtr8CTPudxibvG7ZVmlb0dEY0wq1dSRyS4t5U6fOR+GwZtXL7R2RWrGD4VZ2XbRoCpFJYljrfX7d5NPHo2nUileSwRkZs/zroxcy3bui6Lw1NC5/oEjhJZADWcSURD4jx+O+37esiz1a96DUkpr7Ti6DAaIFMeF0bu3r16/0da2Jwj8g32Ha0cNAUQ8rzGKogdj95RqoCqltE7MxrbtwPfH7o8uLHzTrmsMi2z+iDEmDAPfz7e0tBLRmhtripm1dr9++Xzn1s1sZxciAsiGHQAxLkTZzq4TJ4eKIa9S1DV5juMYY2amp2r4DykMAwBEpFKA/gxWdDIiau1u2tUAEQHBcZzN2tXvI6FGHpIwry/83Xm2C/tH14JiiRARUV0fUbSB64xU7iBxoZBfXgZAZlMHzIoiPwqC6rBia4jjuLund+jsBdt26tltEDFJ4tbWNmZjWVQytQJTSiFSGIb7u3t6+w5BfVvU6hQ0YeBbnq3UKkUAlLLmP84yczrdzMLbQQIAIbIaU02Oo+dmZ5gFEbG9I4OIhULUPzC4N9MZx3HFtlMnL59fnnz7emVhKf4yIWIUhSYxsDKotkUIIIjoul5lgmjtoftXyqu0YaiywcEiu+1qa/oJbo12kZ/KXikAAAAASUVORK5CYII="
    d["dark_2x_ico_folder_s"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAACxUlEQVR42u2XzUtUURTAzzn33nnz5RvHFEclKiuk2URIgQgtDKy11a6df0E7N0GLaNMmCFq6FNoEtUuCQsJFQoGbog/DpCCU8XM+3rsfp8XoNIymgzNIwVzu5j4u73fPvb973nnYnemFo2oER9hasP8PJqsHiGLfyczsmgJDADbBBgP/BQRIJCNtzLZBGLIzSOJY/wiRZGZArAkJCU1pM/f9jfT88soOC2Mm6UX93sGbT1RMOQuAu8MCZ3hh9uHnmftCesyH4Yk2P61Luf6h2xfGHjkrACVJQADEqk7ADpyxmexwmC8sf5lWng8AWFejytK3IxMqrmI+sy2sLhVWF0goYK5o46z2kplUZqC4HmSv3tWltcW3j6XXVo8vzE7IKAoFzHLnkXWGpSd+zE99nJ6IJDvZmYo77IyKpS/det7ed94EJjv6oCc7hiT/LGhvpZgIw2Luw4uJsLCCQlXZiAgAJCPSS8hIsgoGgGR1YW7q+vD4q0TncV20XWcv13lkKgYmKM4/G1cyTXvcJXa13Rmh4rq48v7p+OavT9ITbIH5gO4s6FKoCzaePolUtY0Hb70z0vPXf87NTo629w0iEtcqW7URQEbn2/suDly5A4hsdVldWb+47KyMJNmGy19f7j8TUejSWlnX8niPdFWPWoCkvNSBMACQkcR+ubFeYh0Zi9nuvhit71kL9o+WBQCASEgSSTbyUkSBJHcXGbImzxidD/Ob5fzUCEwHWzpY+wuMGRCcdp2nRrLX7gmVaKS2QURrgnjHaXaMAitfojKMSXqIrEthx4mhrjNDTTkhdqBLAQlJ0tsRhJmkl1ucYYdRPypU03RAgkjCUzGx8u01OwOI2J3pRSQTbvVkb/g955x2gM1SlJEgzK8uvZvc3tztXyYkE2yw1c33HUlFUzWCOOWlasvFJsXHztaqz2wPVXm20hUA/AY8t1bFYG2G6gAAAABJRU5ErkJggg=="
    d["light_1x_toggle_on"] := "iVBORw0KGgoAAAANSUhEUgAAACwAAAAYCAIAAAAODYjtAAAEFklEQVR42rWWX4hUZRjGn/f99pw9Z87Mju6Y6IqJtpVWhmzaBqFBhhpe700IoUTQvXohBNWNiHVRl124UEGEQYF5YbhJQqQ345JEYhu64KrI7ujMnDPn7Jn53reL444Sto1H++4OfH9+3/M+33kfCqMYC8MKfJcch/6YTn+aTKpT6cxcJ4wVeQcRVFHyeahiRobd1zd5G9a47bbGqRq+b1oXwgoGAr5yo33sx/Dsb0kzVsNwDDE/9NnMIMAKrABQgFTRsRp4tO1Fb9+O4tqVTiOSLsddCFGUCnTyfHz0eL3WlJLPxkAV+pAqMEGBKBErKHpcKjARwljCWJjI76cwkSUBHxgr7x71my1lWoDINPjqdHj0eD3w2HFgbR7xDSNOVQSvPu/v2BysX92/rGyIUGvay9fSM5OtM5ORKlyH6pEcHCvveaOY6UH1ZjwQ8MnzrUPHbpcDVjz07bsEjZYMD7n7xwZHN/gPnPP71flPvq1dmErKgak17eF9S3ePFhqR0Px8MjPX2fvxbNpGVoJ8BM2WvPKcf+Sd5aUCi0IVRCAgM4UqCGBGx+qHX87+cC4s+mwY4/uXrar0sevQ+Kmw1hTHyUlAhCTVdSvdo+8uLxXYCphgGEwgAtHCJ8MK+gx99PYTm5/x07bWIx0/FboO8aXp9OeLSanA+XwAgICOxaG3KoHHVmB4McFEQIT391ScPir009mLyaXplCcmk2ZLDeckYEYYy9aN/sjTnixK0J1vBU8ud3aPFuN5iRKdmEy4OpUazlmITAYr2LUlUEB7XqKKXVsCY4gJ1amUZ+Y6Th8hL4QVFH1+dnU/AUS9eogI61a4lQED4Hqtw2GsnJeBCNZqKeBKyWRX7HEVgIEiLy0ZUUSxMh559K7BP1d1jVL0SRSU63hVGENhLHcii549kfkvjKUeWSIEPvGqSl+7k5di4Tf150zae6PJZk7fas/WLQFDg308MuxayaPn/cKerrZ630EBIkxUo7SjohgZdnn7Jq9UICuP9DomqtHla6lh/Oc+omDCbN1+/0vouRx4vH2Tx+vXuK9t9JotMSZ/crGCw1/PWVFmiCxGAAURjnwz14wlSXXbxv71a1xO27p3Z3GwxO12zqKIIvDowlTywRezKnf/iSL3LKIKUWQ9hRmffXf7dDXyHCoHtHdnMW0rJ6muXeEcGCtHieR7bFlRygGf+DV879Obf11Ps3bV3arbw27UOgc/vzV+6k45MI2WHBgrr13hJKk+5lATxuL385svF3e8FDw15CwpGgIaLbl6s31mMjpxLmxE4rmUEdwLNY853jGsRZRIn6HKgBksGSLcCe1cw6Yd9VxKUpQDekC8e+xBN+uIbYuO1bvNYsE6W1/w9u38l6D7f0T+7GwFij4PDS4W+f8G2GlPwhD4WbgAAAAASUVORK5CYII="
    d["light_1x_toggle_off"] := "iVBORw0KGgoAAAANSUhEUgAAACwAAAAYCAIAAAAODYjtAAADKUlEQVR42s1Wa3MaVwzV4971LmAWGz/GZeI0cdP//286k46d+BXXJoDB7LJmr6R+uDV23ZQx8KHVVyRx9lwd6eC0mMFTmBkREWE5q8bj6bSYzeu5iMJmwUyJT1rNLM9bjSxVNVVFxEUCLkCYmXNcVfPb/mDyUIgoIgAggAEAIsYyM1sVhMUqM2ZubzcP97tpmoQgCxzPIJhpOJpc39yFIMykqmbGzMyMAEFERACAmRFhdSQQq0TEOdc7OtjdaS84dgsO7vqj65tbZiZCVe3k293dvNnIEu8Boa5DWVbD+/FwNFE1Zl6VkpjunDOz88tvIcjB/k7kAx+mpXM8HE3OL2+c4yDSSLd+Pv4pb7d+2GtalF8vbyYPhXdujadZhIi+f3e0u9MOQbAoq/m8/v3swsxEtJO3Pp0cO+bI0MvxiX+JiGZ2+vWq/33kNsBhAIT46eNxkngiwtv+IAQxsCzb+vXk2D1R/RLBYjYjsl8+vGu3W0HkVc7bgxBDCLf9ARFSOasmDwUzmdrH97342EtaRxwAcPK+x0TrM2HGzJOHopxVNB5PRTROYnu7uRzBSxxpurXf7WxCBgCIyHg8pWlRIoKZ7XU7q7bY2+3QEzFrBuK0KGle11H9zSz75xwsIQMAsmzLe78JCASY1zXFjeGYfeJWbeGc834joSKiiBL8D4KYCQCCSKjDqsWxapPBNDNmosT7OKXl7PHt9ymmVdXjvK43AgGQeE+tZsMMAHEwGq/aYjia6BskvfxrWs0G5XmLmZhoOBqXZYVvkxwi1nW46w832VdRlXneokaWtrebUSNn59dxWS3vG3/9cvGtDkJEG+hC2tvNRpaSqh3ud53jeFFPv1yZ/bUTXyExe75hF1d/fB/eO8dr06BmzrnD/a6qkaqmadI7OhBR57g/uP/t81k5q56c1N9cCSI+zuvPpxdXN3d+AwQAoKK9o4M0TVQVp8XslalRNSLc63b2dvMsTb13ABCCzKrH4WjcH4zqWtbmIHIsIr2jw2dT8wN7J8JE0WN6771jQAx1mNdBTZmYaJ17scTe/bvRVcUXtiy+Ba51rlYwuv+h5f8TS7FT8Jo/+ucAAAAASUVORK5CYII="
    d["light_1x_logo"] := "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAACp0lEQVR42q2VT0iUURTFz73vfd84/7TRzJD+QBgYgotcmEQLiTZBpCsXQbVpEUW2C1yVC6FNBNGmlm1yIUkRtQiKJESDoNq4iNoNVjPq9DVjM/PevS2CytGcEbrLy3uH33v3vPMou7gUC+AE07OV5+8q2bx4Qd0yjM42HuwNhwZCyyhXQfml5eXvMjFZevPBhQEFBg1W1aNS1YNddmwkkUkxO68Tk6W5BdeSpNCi8QotWpI0t+AmJkvOq9l/5PLDuUprmpxfs46ovpYoUnH69FnScTKpntFoFUy1K7zXwJJqHS0FiKhQVM7mJTD4e4MXNCd41/agUBRT78pUERhk88I1MyKCiIaWbl7o6D8QX4nEmvqH9AJe32VCuartLebWxY7DPfH8N28bGCVv3GWsljW0dON8x7GDyeVI6mrxJpZTRSykG+d3nDycyhXqcG3mHCKIAITxM+1MNDUTtab5X77nzYF/uUkUV09vP3d821IkhkFbJfqjpfCCS8MZAHceL29LmS0TiUAVRDAMAJeGM+Nn20W2SCSK34acmomezH9PxTkMKBmn4qoyNybkRJnw9HWxs8327ot17wmv3fthGaJINDFzY0cTQSZlXr4vjd7+/OBVBKBnb+zEoZQCmbRhamxqokjEaPpVdOXu10zavHhbyuadCE4dbW4K2bmN3zEbrn2E1tBS5K/fzxMhHlKu4B/NRsxIJ3hnq6k6XZ8whmE72/jjooT2TwAQwXlYQyA4r8kmejxf/LLin70pVhxqsoUIFYfd7cyDvUG5qjVcRFBAFQoElnIrfmomqnpYhq5jKVd1sDfgoYFYX5fNFdSajVNRFcagJcmG1qgQwRrkCtrXZYcGYmwNjY0k+rttoagV98/08lLLUnEoFLW/246NJKwh+l/f0U/Uui+3lXs+uwAAAABJRU5ErkJggg=="
    d["light_1x_ico_mouse_l"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACRElEQVR42n2TyWsUQRTG61VVb9OTGQWVkJkkjNEYDXgUJChRkRxEL6KgeBL04H8UwQXEYIhIQEHBi4jigsGDoNmHLM5kIbMk0z3dPdXveejMYmL8jo/3q3r1vvpgZa3AWkREAGAYuuCCAcMQPd+Piq1tcgejaZKIzcxml5bziJhKtfdkujVNBkGtlZR/M1qhWHox/nouu6BCBGC1muru7Lh+9XKqoz0IggbJ6wwTgrtu9fGTsenZrGVZpqF3pjvu3r7pVv3hB083CkUpJRHtwNAwjPcfvuRW1trabKzrZH/fvTu3lFJv3r7TtF0Y59x1q1Mz86ahIxIAAIDgQoUqk0lfGBz4NTlbLm9KKSNQNiZ0HNetVokoCALGABELheKzsZdCiGKxREQVx7VtOwxDxqC5EgAgItuOJRPxMCQGjJAWFpcZQK1WE0L82wDOwfP8MwOnLg2drzgO59H8ZMfsT18nRp+/4sCbzey/QiREbGxiT2xXw7ale2JERESCw+6DooFbYc4YA2BEpOu6ZZnFUpkBQ6T6kMgFlEqbUkrTMoiIMWjeFoZhLGad6Dv67fuP1dX1RCIe1eNxe2vL+fh54sjhrv37kkqp6HvxxvaDIDh39rRlmsMPR6am56Li4lLu/qORiuMMXRzEEJtuNYKDRIauL//Oj4yO5/Krhw4eAA7r6xvJZOLGtSvHens8z+f1l0Nr3hDJNHTP939OzsxnFxGxuyvdf7y3LW5XfZ+3BAd2xBSJBOemaWxnhMjzA6VU3f1t/QGc2D35gxyF5QAAAABJRU5ErkJggg=="
    d["light_1x_ico_mouse_l_s"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACHElEQVR42n3TPWgUQRQH8P+b2b3dvb18SRRRoqioMVpoJUJAsRGsRUGw0iKt2oiWgthoYelHYyOmCdhpKxxKULGQRBOChpDkDN5dvNu9u72Z9yw2Jnu56DAw8GZ+zOM9Hi3/LCOzWECEvEeuBgDLiJrCAkXZV3A2Gc+FCD7MmOkFYxmHduvj+53ApUYiWelkje9iqSwPJ+JPc8ZYENAyMjLk3LqYP7hLZ6VKDxE4Gqux3HkeTc6YnoDyHg0P6QfXCrWGXH9cX/xlPQcinYwFoUfjb1uzi3ZbD1lGuk8fcx+NFRIjz940cy7xJqYVfscy+c2EPjGDCERwNdoWw/v0lbN+ccqsrHLu74fOeobVSGqxsKCRCEDMWCzzvZexo7FcYRFU6tIfkrGdJVEEFvSHNNirDIMAFnz5YYjQakNr0JYNUApRUy6MemPn/UpdtAIAAfpCevUuuT8eK7XBFP67mMG8UcB/su4XWwZV9k4EWkO6zFrC0smIwIIgR4WAShUmgHnt2jK0QqnKOYfCoKtvxqI3T6eOOK8/Jt9LPNi7VraBApVrMlFsnTigd/arxIAowxShkcjlM37BpxtP6u+/mjQ4NW9uPq1XI7l6LrC8kSStDw4z8h5NL9i7L6LZJbtnu9YK8yu8o49uX8qfPOxGTVnvAWXnLZVRS4pT7c9zxjKO7nVGR5yBgsqazSyVWiP0KZ0REcQtaRuozk79AZDAFaSn4P2+AAAAAElFTkSuQmCC"
    d["light_1x_ico_mouse_r"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACRklEQVR42n2T20tUURTG91p7n8ucGbWgm5eUsrQyiIrMIKSIyIfwIejB3gqiv6kIDR8kBaGHeooeQgKjGyFIWpqNjs44qUdnzpyL56zVw/Eyzkjf47fXb1++zQfZ5VVRJmYGAMPQpZRCCIrI8/3YLB9TFYymKSHEr5k/6fkMETU0HG090aLrehAE5aTay2hr9vrI6Oup6RmlFAuBCE2N9fd6e4431vtlJG4zQiK6rvv8xcv0wuLjh31XLl9QUqaSViaTHRgcya+sakoxcwVGhmm8H/uYzS4/efSgq/MSSiQiIrasxEah+PbdmKzGENHz/O8Tk12dF893tG+GoaYkCAEAzGSaxuxc2rbXlVIxqLZuKLFUcoPNMLf8t39wWLCYSy8IEH4QMDFK9P3AKZVqalJRFAkBe5JUSq6u2Z7nRcS6pjU2HGNmRHRdr1B0cN8kEcF1ve7rV+/23Co6TmwSUdKyxj99HRl9A4C7w2KvmJmIiEj8V9XYPkNc5WL5GjNLhOqNELECRiEEgGBmXdcTCXPNXhcgiHjnbSjBtjeUUmbCYGYhYPe0KIosK3HuzOnP3yZyuXxtbSr2U6lkoeB8GP9y6mTzwQN1YRjGcW5hABAEwc3uawnTfNo/NDU9E5vp+cVnA0NFx7lz+wZFuznBTnGI2dD1hczS0PCrxaXckcOHACGfX6mrq+2739ve1up5Pm6/HMr7RsSmoXu+P/nj5+zvNBG1NDd1nG2rSSVd3y//bqioKTFLRNM0tjrC7PlBGIZxmDv6B0J7NtkA+BbjAAAAAElFTkSuQmCC"
    d["light_1x_ico_mouse_r_s"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACI0lEQVR42n2Ty2tTURDGvznn3EdyY2PxgVRRUGnxsVAQqqjgTqQguBDBbd24rbjQLl0VxH9AkbpSUHDhShAEF4VsCgGxVtRqq5hYaVqbe5ObnDPjIqW9TYrf5sDM+TGPj6HK7yVkxAIiRAEZDQDWIUmFBYqyv2C6mMADgOkv9sO8ZcbhAX3ioMn51GhJljRZJvRQqcnEi6Q02w4MCaAVBvfqsSu5oX0mSTdI1XlEYDRWG7j9uD6z4O6PFi6d8j2DYkSffro7k/HCogs8iGzGWBAF9Oxdc67iHtyIRk77RsM6MKOYpz9/5cmb1NfEXZhWqDflbbl9eTg4e9xzbXgGRFAEJyiEVJ6zlWX2zVpBs97hSiJpG3NVHp+MRfD+uwWQpGARrShJZSWWHdvIup5NegaVGsdNdozQp8EBLQKlEDdlaVWU2mqTWqHekKvng5sjYa0uChDAMYoRvSq1Jp4nWQMUNksEzGCG4H/aAutVb1BlcyLQuruOCLTqhhUAIrAg51MhR9UaE8C8lnYMrVBdZt9QlOvxzTr05enMEfN6uvWtyjv71sbvL9DSqrycSk8e0nu2q5YFUQZThEZLrl8ICyGNPayXZm0nODNvbz2qL8cyejHneKNJWj8cZuQD+vjD3Xsaf/7l9u/SWmF+kXcX6e61/PCQFzc3rKPsvXXIOJWpmXb5q3WMYwfMuaOmv6CyTDfWIbVGFFLHXBEkqbQt1Gan/gF3ThSJUGfcJQAAAABJRU5ErkJggg=="
    d["light_1x_ico_window"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAABzUlEQVR42n2Tz0tVQRTHz5mZO3N/JOqqRS0iXLSQpFUFJiYWSAj1J7bQVTzR1VtKSS/sBy1soQ8eEVEmPCPefffHzJ05Lkav5r16VjMDH+Z7vt9z8PDoGM6KiODqQsT6LGoAETnn12BE5JzzsPB3KaUxJs8LRARo/olEFAQiDFVZakQUnjnoDza2uqN0zBhrk4pELlTqxcrSg7lZrbVARGNMZ6urZLD8dF5rfbGHWp6Ucr8/6Gx2Z+7eieNIMMbyvEjT8aOlJ69Wl0dpzhi7hDnnbiTRu/efXq+9yfJ8YiI57S2Oo+23vQ+7n8kRADbtAMSqsnEU+RaEd9ZaOz01efvWTWNsQyMQgRB8OPz74+evcycRsSz1/cf3Xq4+9660iUx2erv99e/nmCe1MWmajcdZKwYE3vr/4vYkO6tm1oyxlimph8A512T8+8U8T530ySRJTEStIpMkVkrWcyuIKAgCpdRBf7DT+1gWJTJsYBSGau/bvuBcKekc4e8/Q6Xkl697nc1uUZaI2DaSAARc8JVniwvzD7XWeHh0TERKyn+jUZYVjLVhAESklJyemtTGAAD6fSMizjln7KqFQwBHVFXV5dystdZauLbqDE4AzoADZNrourIAAAAASUVORK5CYII="
    d["light_1x_ico_window_s"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAABv0lEQVR42n1TPWtUURScufft+9rdqFikSCt2FtpbBUGrgIWl2AgBf4N/wfgbbGw3tlaiKWQhlSAEOyEkQRfNfrx9X2csdtdNsm9zuHAvF4YzZ2YOT84GWJSE64rg4hnMLhM84f11KBNqg+MCJiEJmZcaZiKbMRLiFtOYWS4SgQlJyP5R+XY/GwzlHKBmWBpz90n86H44KRQ4Ii+118uSkM+3w6yY07hCLwnRP6re9LIHd4KNlIF3GGYajPRiO9rdiScjeXcVVhvSDre+FK/fjf9OdLvr5rPdSPn+0/TD19wMWB1PIFFW6KakoJkkJKoam7fc3S1flFhVRUIrwPFv+/6zxn8lSUxyPb0XvdqJh8Nmkt0OewfF4Y8xecE3Enmh0Uh/xs0wAZN8aU+wzADh3fyslneXFF50AyTUhtoaMLN/0+VwSTAhDtlp06whYnWNjTbbEW2R28BmqYnYPyr3Dziewq2QNEMa4/O3KgyQRqxNPD4dpBE/HhZ7vWw8XZ9JoOXx8nHy7GGUFeLJ2UBCEvHXuZ1P5Lg2/u2ImzfdtBQAzvbNhJaH91y7c6SZiurC4gBwRFWjrLWmGQQRSw/+ATo424bA8MLUAAAAAElFTkSuQmCC"
    d["light_1x_ico_theme"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACWklEQVR42n1TQU8TYRCd+fbb7W4ttMViAU0VSISTCRKx9iABLhJJvHHw4MEf5oWbJ41GI0ZtoFYaVDRRURSNQaGthLQLtLv7ffuNh8UNbZB3m2Re5uXNe1iu7kAriIBIhSMiImLbDm+blVKca7puMsYAgIg8T0gpg/FoGhFFo5Zt761+Wa9Ut33fT3enBvoziUSn47hEFJ5toUUiRqG4nF9cqtVt5SvDMBzXMU1zcjw3cfWKUkopFTB5eCcSMe49mF94WbJM0zIjAHj71iznWuHV6/sP5ze3Kjdnb7RcU0pFo1ahuLxQKHV0xIhIKQIg04yc7us5mzlzfrD/ztzd7lTX9WuTjUaTMcaJSNM0297LLy5ZlklERBTa47ie57rZsZGN31vP88VLFy90JRNCSkZEhqH/+LlRq9uc85ATgCEyxppNNzs2QkSf19Z1XSciBgCMsUp1W/kKjgIiSl8mEp1dyfivzTIgAAALLYFjgQCMMVIHawwASFHqZLLtoYefqWna7u7+Tq3ek+4OxaMnxMC5TCwW9X2/LUZE5PvKssy37z5IIYeHBqWQiMgQUUqZTMZzl0cbjSZj2mGaznki0flp9eujJy9y2dG+3rQrBCLywBLHcSfGc5vl6sr7j7ET0UAwItbqdml55fF8fqA/MzM95XkCAQEAgwYQEWMMEZ8+WyyW3jQdBwHj8Y7dvX3hiVx2dGZ6inPu+34QFAyLEyTVNCPl8p+1b98r1W0hZPpUanhosK837XkiDGQL7V8yyDC4znWCg7xLIT0hAs3/7RtjKIT0PHF8Tf8Crfw3ZW4lpFkAAAAASUVORK5CYII="
    d["light_1x_ico_theme_s"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACO0lEQVR42n2Ty0tVURTGv7XOvvvccx+klpYWmWI5KWogmDObRVI5TRo0i/oPGjRuXLNoUtBAEKHHoCAhRLQHgdCkS1IohHkNzdTr3eex92pwrnm9WWu2YP/2t14fLS2vYneIQASynTKBqOEJVEPuHJRCNkMeA4ATmEjiBMz/xkRQzNHKuntbShbKNnHobOXT3aqtiStGRHZkd2GBT+PT4ehkuLzmrENWU8VIPktXz/kjg37i4FyNVH90Ap/uPq2OTYWFgPIBEXDnWl4rGp8J7z2rzi3a21dyUq/mHIo5Gp8Ox6bC/UWyAucAIJ+lE4e9k525vh5161HlaCtfvxBsbAkzlAiUh5V1NzoZFgKyAtkeYuKwZaQa4WK/Ln2zj1+H5/t0ezNHCVgEWU0f5215zWm1wwAggBnM2DRyqV+L4F0p8TU5AQvgMRbK1jrsGUSIE7Q1c3sLf160aXe1dTjB/yNVdttfczqSIwfY472BtPnVDVn66boOeTWMCSaWU12qpcCxbbwjEViLYkCvZqMoRn+vCmNhAqeltzfz5QG9viWKUQ9mFLU10cyn5P4LMzygj3d4JgYRFABmVIyMDPpfvtuJ2bipUDtIJvz45Z6/jx68NGe61c2hwES1hVPqABF4DCI8nDBP3kSbVSFC6z5e3XBhjOEBfWMo0AqxBVMdlpJMyGXp65L9MJfMl20Y49hBPtub6enwTCTW7XRODX5zDr6GnyEIQCAgTJDWVj+tRr8xI4phIqlfN/9l098z5gus9ZqJiwAAAABJRU5ErkJggg=="
    d["light_1x_ico_keyboard"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACUUlEQVR42pWTz0tUURTHz7n3Oe/NWDM65o8ZHYshTSqUHGlpWIFmLYogWkSLxFUhCP4N4aLahasWrQpcBEEQQSERE1KCjuRYmiCIjcY8DfS9mXn3ntPijdIPyjpwuR8u59zz5fA9mFu34f/D2CUun78F4s9lzCyl3LOJ1hoAENHwr0BFxda2w8D45xoG2BcKaSKttYEIRDT+5Nl0Zg53RDCX9ewCABBRa0vy8sVzQcsyLMtKT069efu+92x3KBRUSgOzNKRWGgDKgCiFUFo/fzERa6g733daIKJtb9ZEq9uPt81ksq2Hk12pjsxsNtXZnupsz8xmu1IdR1qS05kPJzqONTXG8vmN8kikEMzkuAUicl1XGkITbTsOAPjgui4RO46rtRZS7EwS0fNUrL62v7enqTFmGPJC35kD0WoA8KEqEu7v7YnV1yqlEBAABAAwkWkGFpeWR++Ozc0vrKzmbt+5v7Ka24VsdmH03tji0rJpBoio3A2FKJW85kR8+NZAIhE3A4GRocF4Qx0AjAwNxurraqJVwzcHmhPxYskTYkckMwNAJBxOHkrk7W8PHj7Wml69TjODGQi8nEjfuH7lVPdJxykiop9sAEBlZWhr20lPTlUGg26huLKaKxSKhpTMwEyI4t3UzKfF/Upp29482tYCALj2daNUKj0afzr/8TMKREDLMn/xR6FYZGJiOphovHb1UiQSxi9red+NeXvDtzIx/eZgREAGjlZXSSmVUphbt5kZEQ3D2MP+AJ5S5WT/MwDwPG/PDUBEP9n48enf1/Q7xEIX7HW5cN8AAAAASUVORK5CYII="
    d["light_1x_ico_keyboard_s"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAACMElEQVR42pWTz0tUURTHv+fe957PmdEJzRhNBfuhONAisRYRFETIuKyVtqmV7kQIWraKcP4GyU0tWhSugiC0TRq0MN0ohsvJsnpor3mO7917TouZsTBo6qy+i/Ph3vM930OfdgL8fzmHSqRxN9FvmAAicHVjzNga7AigCZ5Lu2UWAehvWDalLIuxcBTBMorPooXVRBFqPz3k64IAyxg+69y92Zzxycn4NL8cP186uHPdz6YoNgDgaiT2lyDA0YgNZl9WTnfqyVFfEWE74K42ffWcu7CaXOx3C8Pe4loyMuSNDHmLa0lh2LvQ7756n1w77w5069I3rlmiNVgQ7otlfI/Y0coy9iIBYBl7ZQn32TLCSIyFo+tOEhAn0pfTEwV/oFt7Dk2O+t3tCsDkqH+yXZ3I0kTB78vp2Eh1ZAWABakmWtky48Vwad1sluzYTLhRshslOzYTbpbsm3UzXgxXtkzKI8v11xQhiiXfq2enMvlep9mjuemWM50KwNx0y6mc7mpTs1OZfI+OYtGqjrGAgI5WNXjZ+RrwvUdlw3jyWkSQaqLHi5WHt9M3rviViBWBpY4dS9NuWeaX49YUlSuyWbI/KuI6EAELFOHFu7jjg0mMbAd8aZAA0M6XYD+WB0+jtxtGEYiQ9ulIVMoHwgxm5Hv1/VvpjizR9ueg6unHgKtpZsaRVFfnEUGuTXkasYFDBGNBhJ7jqmH+40RiA6Lq3ggADpKGByBEtWbnz1v6l/oJc2L6JjQRyAMAAAAASUVORK5CYII="
    d["light_1x_ico_folder"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAABq0lEQVR42p1TTWsUQRR89eYNu0PUuIm5KkZEEb14UEJQEIUoOQT8A149+HM8eBL0FtFTxJsEBFERCUFYE5YE9ZSssmqccWZnut/zMLI77mbjx7s0VHcVVV3d2Gp36N+H6b9GykVVf8fBjD/QmLlerwH9c6qaZd0qMkgDEMfJ8rMXaZYxmEDe+emjh2fOn83zYphgZgAkFFl68nT1bXNqatJUATjnX71e8d5fmD3X7eYVt1BVEVFVASNOkmPTR27dvJGmGQBmXny4tPjo8fOXb6yfGQQytTOnT87PXRIiAqCqqmpmRsbE1xeuTjTGO1++MTOREZEZhaGstzab71pzVy7KgHUQnHNBEMxfu1zFVXXf2Njd+w/ef/gIQIZDAzCzJPkxQCOioijMKr3t8g6Yh5FeJVLRMyuldhszU+3vS08pimogGlWxqkZRTYJfFqRUSNNsbX0jz4uRNNOoXt+JkzK5ABg/sL+51rp9556ONllelXPu1InjzIz256/f42R7+1MQBGVFe/Cc84cmGxONg9hqd5g5DGVvSq9W57xzTojIe++c/7uPZgAA/AQC7swOV2ZX/wAAAABJRU5ErkJggg=="
    d["light_1x_ico_folder_s"] := "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAABm0lEQVR42p2TvWsUURTFz7nzJrsDE0GJoCAWSSWkECstxC5FCsEmf4CNktLaWrCWpE0vFilSi42K2ikYYqVVQj5GhNmd3Xnv3Wsx2azrZtR4ywu/+8655z7u7Rc4ewn+qxwAA1QnugRE/oY5QdYlOe5GRW9gINiGCfG9tLVXg3JgQpDwwa7Pu7s3O4PapgEzkHAzKde3+i8/+qsXRRUUeI+t93UdsHK7Uw2NMlYeFalD1Oa1nt1YcM9W815lQiSCJ8+rpy/6m2+HahOGo+HOYvpgOXMAhIgKVajBDCJ4dC+7fEF2i+iENtI2k+LDl/Bm299f6rrfpJPwAS7Bw+Xur/uIitmcjzf6n755Idy0aRJq+NGb2EdUABh6MxsFcAoJJFO5JYKTkI6xJnG11nzVoAqzSSwR5BlBSEvAUZFnTJMR1gwoK3u346u69UbVkHdxVFrj3JGYOyevPw9X18o/iGwM+2C3rqWJgAeHRVHa173oHMfaT8XIOtiVObl0Xri7XzhBJ6UZWi93tDcSdTAf4AiECB/sH38aCRI/AYnUs0qx0m+WAAAAAElFTkSuQmCC"
    d["light_2x_toggle_on"] := "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"
    d["light_2x_toggle_off"] := "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"
    d["light_2x_logo"] := "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAIAAADYYG7QAAAFVUlEQVR42s2ZXWgcVRTHzzn3zs7MZnabbGo2tLRbsGACLYhfKX2o0FQQ0RcjWCsNPkpbNQ/xA998VPJiq9D6pBEfQxV9kRqEWkPzIFYabLQKrmljNrabj53szs7MvceHSdZQCt2PSdLLPN6d+e35uuf8L87NF2FtKQ2mAZaB+X/1xavBVD78q6CKJRYEDK0uBFAaMinckxX7cvLQfiP3AHkBVwMQtG5bDUhpSNlYWNSj497EtXDB1YhgCFy/u/WlNASKmaHDoYO9crDfyrZTqcK1r6wCaQbHxsnpYGSsMlvUjo1SADAwx2CbO+yECIAQKnArvCNDwwN2X4/hVphwDUhpSCXx60l/ZKyckGgaoDRswhIE1QD8kIcHks/1JUplFgQUeWpyOhgZKydNTMhNooncl5CQNHFkrDw5HaRsVBrINKCwqEfGKgmJhKAZNnNpBkJISBwZqxQWtWkAWQaOjnuzRW0am01TYzINmC3q0XHPMpDy82riWuhYuCU0NSbHwolrYX5e0cWpcMHVUgJvHRAzSAkLrr44FdLVfEhYLw0DIAJuDBMhXM2HlC8oKbBOIIFQDVgzIG6AkQTmC4qKLtdTixEhCDmTFkPPZ/yQo+yIvSwVXSZR93uJoFLlY4fT7w1uL3s6UEwUNxMCNRTKhLC4op/pc84OdTsWeVWO96RjAGrCsJqhr8c+81p3KkkVP2amZl5GCIHinl2Jj1/vTtlU8VkK3EogAJCESkONabms4mKiVpIiYjo31N2721xaiYeJWkxUpWHvzsS5oe6HH7QW3BiYqPXioTQ4Np05lX1kbwxMFEtB0+uYiqWWmOJJWVpjOn0qe6DXXiippmtBbDWECJghZdPZN7pfOpy+XdJCbClQdN4xAyK8c7TzeH/69pJqginm0yjqArSGt492Hj+y7faSkqKxdkXG3tmsZwKA0QtLnWkRNRhbYCFmCBVrZs0chPzWi53vHtu+XNah4jpbqPhdJgUKQinQkIgIL/enPzyZTUjUXJfvWnVZ9JlaOP8244//vJI0Sa95SGlos2hPd+Javmom8J6DsGyRZn3fyADb2ujz75ajc60WNMzs2GQm6mqUm3eZ0kAIv+ar+UKwyqehOyNffbbdNGj7NpFJrT6daWlI3NigVpoFwe83/Fc++OfTb5dqYwMDHHm0zbHRD1gxK7361D9jUXOekgKnZ/wTp+c0ww9T5QVXRf01a9jZKZ9+3Fkua9HUaNIwUKiYEKb/9k+enlte0ek2ml9U5y+5EWiUSMePpNvbhKozr1oBUgwdjrh+wz9xZq5U0baJQci2iecvlTyfiQABNMPuLuNAr+VWdBOjUgM/0RqSJv503Tv1UaFU1nYClQZmsAycuRV8f6Uc0UQy1wtPpgmxUbULAUhxvSVYCCyV9ZufzC+4yjaxJiMxgCT4YnxJ6f8L0hMPWU891laq6IZmN8VAGQfrVKgIwfO56rNloNZ3WI6mZ/xf/vQIQQhY8fQ3l918ITANrD+/lIaMgzKXFYXFoM7xHhHwrqIWQqj5swtLu7qML38sfTXh3rwVSIFWol4gRAgV57JS7s/Jy9MB1i+A8N3Dq82iK394g+/P3rwV2iamk6S5AYkn+p/7c5IO7ZMdDoVhq4JGJEMvurrDoYRcjff6acIQOhw6tE9Srksc7JWux7GoGVJAQyi16HQ9Ptgrc12CvIAH+60dGaoGMSgsTchwhFANYEeGBvstL2CqBpBtp+EBe4NUn3vSaI6kajvbTtUASBCUKtzXYwwPJMtV9kMQtEk0gsAPoVzl4YFkX48RXTDcl1cLtbp0H12+1HZv+fXUf1U8AJwjimC6AAAAAElFTkSuQmCC"
    d["light_2x_ico_mouse_l"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAEr0lEQVR42u2X328UVRTHzzlz7/zY3e7WlhZba5S2LBIU8UcgQCBglAdUYkxIMDE8aqL/kIkxPmGCUWMiwYSAW34VMEADpbRQahDoL/ojmLIzc+/s3OPDIGC7u7MFfPM+TObh3vnMOfec7zkHp+7OwzIXMwMAIi73oGh8qzEMwJZFRFaCjGMDwIjYIFg0iCFCz3MJsewHSvmAICyRy2UISWldqVSI6BnAjDGe54ahGhwauXZ97NadiXLZB0Dblp3PtxdXd68pdrc0F/wgTPUtpt5ZxnOHhkcPHylNTk4zgxBWYkTiRsOmkG/auX3L1s1vVyqVOI7r8FJglmWVjvcfLZ0CAMdxEgYzIyIza62FEETkB+GbG9Z99MEux3Hq8Ki+90rH+3/59Zht27ZtG2OMMQlJad3ZsXLf3j0rWltCpZpy2fMXLx/84ZBFVMcyqhXcnuteHR49WjpVyDcl9iza4Dj25k1vffn5/l3vbFNaF/L5qyOjx/pOe65rjFkGjBBDpQ4fKQEgAPwb9Ijnl31j+MPd7+7etaPs+5mM13fy7O3xSdu2udoZqvoV23FujN2cmJx2nOrHHhwmAuB7fy1s27qx2Nuto0gpPXDpipRiGTBCHLk+BpyWFcwAYNgww/atGxFASnFj7GYYhFXTjqpGoO8Ht+5MCGExmzpmea7jOk7Gc4mo2LuqbUUrM8/N3bs7Oy+FWGqbWGIWEGGoVLns1xEFIvL9YPjaWBRFSRpIKV3XAUQd6YWFMnUSACdXnqIgj8td8rboLx3bnpqe+frb7xa5RAqhtCbCJ5QrpRQv/kUABkSAx1OKwbKeQhuZmYh6e162yOK0aCGkianpIAjxCWAIyMy2tD/d93E248WxqaOxSY5/9c2Ba6N/UO196W7UWgthpcIePp+qxOCjlbIt9VPpFe8Zrv9h/yEsKceLpCQljgAeCketsKyu+kII25aAqJQq+0Fq54SIOooW7vuESESN1jNEMMbkcpmOjnZjjB+Ef966I4WoI//MLIWYmZ2fuTuHiIVCfmX7iqhSWSJxNSxDxGJvtzEspTjz+8VQKSKqlbLGGClF/7kLKtKVOF71Ulcul4njeKn7qZpPSOtozeqeQj5HROPjU30nzjQ15Zh5UXPBzHEcF/L5oeHR8wODnusCwOuvrmXDVW+6KgwqlbjlufzO7Vv8IMxmM6UTZ47+dtJ1bc91k+qVXIktZVMuOzg08v1Ph2whfT94Y/26YrEnVKoqrGbfmGjrgYM/n794uZDPl32/2Nu9Y9umF7s6XccBBK2j2dn5/nMXLgwMSilCpdtaW774bL/j2LWEtB7MsiwVqoM/HhoaGc1mvCiKALC1tbmluRkQ7pf9mZk5rbXrur4ftLe1frJ3T9cLHaGqWTzrdcQJz7LoWOl038mzSmkpBQMYY4CBCBExjmMA2LB+3Z7338tmvTCsSUpvv5kZADOee3t8cuDSlRtjN+fm7+koQgAiKhTyq17qWv/a2ldW90SVSuosg40Mg8YY27alFEEQzszOLdz3EcC25cr2tlwuw4ZDpRqpMtjg5JlEIBFJIcgiYGDm6J+x5VkOg4+LpI4i1g8yBBEbmQEfrr8Bj/SGNNfzXboAAAAASUVORK5CYII="
    d["light_2x_ico_mouse_l_s"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAEiUlEQVR42uVXTYhVZRh+3vc7P/ece2fujM2YiamQM7YoJWyGiApFpEVU0ELDVi2CigiipYugjbQugqRFKKnYxkUwCCrqYtJwisC4WhOBt1Sccpy5957/73tb3PnRPPfcO+auj7M6nPc83/v3PO9LN27ewgqPCACAQCs0tHr/1BgIYCkoXoDMNARgAtGDAzMGilHxiBnzgTQiAWBbNFghJoSJJNnCDf4rmDbo86gVyblL6YUraa2u51pCgOtg01prbMQaH7XWDHIjFKCLi1SQs3Zq+j2arKUHJqLp61oEtkV3hFGMYKif9253X3vWTTJJNZjuF8xWOHwmPngqAuC7BMAIIADBCKJEHIsUoxHKrqfs91/xfJcy3dE/Lohev0eHz8Sffxt6DnkOaQNtIAIQwlhG1qp9e/x1Q9yKZFWFJi6m+4+Fliqq0XwwI6h4NFlLD56KhqssbYeWogGIwHfp1Wfcz96pvLmrFCRYXaXJWnrodNTnkTYrAWNGEMkXE9FdjXXPheYCMQbvvuS99WLpdiBVn46eja/Utefkm3DuX3yHpqbT6Wvad8lIx7AohgA358zu592xETtKJIjl5E+Ja+dbcS5BMOPCFd2FRxbb3BgYwe7nHBBcm6ams2YkuW2X885SmA+kVs9sq4tbFY/KJer3STG2jdrrh5URXPvbXL2pnTznrHvdUoxGJLdb0okUBGBGI5Dzl9MoFSYYQckmv0REEiU028i3zWcQIqjFCs5tUs+l32/oD79sYrnSxVLkWhTEHW9pFdOHAEEsyA3mAv/KsoG6y3Zl3CgCi7HtMUspavdyQbUw47fruhlKAT12BKN2Jhz66I1ytUxZBuIiWfBL9MGB5ve/pNwZrTvrh4nYFgoYb4EwCQWl2ysY08JTLB/cg372IHkP7vyfwaTnf8n9gYksaMSdVFJ8iBanLnQsy3zWdyxyHSJCEMtcS5i7V2yUyGxDmMhi+A71pGdESA0GKrTpEaWNNAL5+WrWSZ+WmsyxUZ/R9RnNhOEB3vCwSlKhnsIoYMLYiDIark3HzydBJMz54tumD9ei4+eTMJY0kyc3qIEKpXkkwLkxCRMZH7WHqqwYv/6pj5yNh/rYCP41XBhBpjFUpclaemIqqXgEwo4ttpF8BuDcVCcZ1qzivdvdRigDZfr6TPzVyahcoopHbc5sR7Xk0GAfnbuUfvJN6No0H8jOrc74qN2KJJdQOs6N7fnp4yPBxMVkdZXmWvL0qLXnhdLjj6qyS0SIE6n/ZY5/F5/4IXVtBJGsG1afvl0uGB2LwCyFIJb9x8LJWlr1KUqFQGsf4jWDTITZpqnPmDCRSonmA1k/zPte9zevs1pRR/EsmoiNwFawFB06HR09GwexODZBoEUgYCYmpFoA7NzqvPdyqVrmAqQuYEsTY59Pl//Qp35Mpqaza7dMnAgIFtNwlZ/YqHZsscc320kqaYbijqRelkFt4Dnk2miGcnXGzDYNASWXNq5WAxUyglYkhO5bGvW4eYrACBTDsZe3mCSVTAPUk5itYPNcIskoWZx/CETglcjGP/jpQeWOEF64AAAAAElFTkSuQmCC"
    d["light_2x_ico_mouse_r"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAEvElEQVR42u2X328VRRTHzzkzsz/uvb330kqxWENoodAAFQ0JESMBCVEDEqMxUWOITyaa+P/44iOJGH8lEowGbPlVQCkNQqVQahBaSvpLY3t3d2Z35/hwoWJ7fxXRJ+dhX3Z2PjvfM+c75+DdyVlY5mBmAEDE5X4oG59qLQOwEEQkysg0tQCMiA2CZYMYIvR9jxBLQah1AAhSyFwuQ0jamCRJiOgRwKy1vu9Fkb48NHzt+uitsTulUgCAjqNWP97atb5jQ1dHc7EQhFFdbbFuzDK+NzQ8cvTb3omJSUQQQpRXZOY4SZi5WMjv3rnjuWe3JUmSpmkNXh2YEKL3RP+x3tNEJITQxkghpJTMfD9SmCRJpPUzW7e8un+v67o1eFRbvd4T/V9/c9zzvDRNHaVeeXnPvpdeMCZGRGa2lq21QoimXPbHgUuHPzsiiGrsjKodbt/zfr46cqz39IpiIYyins3dH77/7ot7d7W1rWLgRZPT1BYL+aHhkeN9Z3zPs9YuA0aIkdZHv+slojAMezZtPPj269lsZn6+FJu4ihJpxvf6Tp+7PT7hOE45F+vDmNlx3RujNycmJoUQTU25/S/vMbGJk6SGSsxARFGoBy9dUUouA0aIw9dHEVFrs33b1hXFgtYGEa3liqvc/9AqJW+M3ozCqGLaUcUTGAThrbE7ROg6Ts/mbillxvd91/V913FUrbSVcnrmt8npWSXl0r+SldTASOugFCKi57lTM7N/zM/blAHYcdTtsQmqriQiRlrPzZVoNQEwANZ3EEQEBETURh/65Mu/v6Jy/BcFDwHsfYMmwoe0qwejhADWpkmSwNLVGJSSQoiH9EZmJqLOjjWCxKLcqpgtd+5OhmGEDwFDQGZ2lPPOm69lM36a2hoey8yu63z08aFrI79Q9Xn1ZTTGSCnqwhae/+iKwb9GnWl1lyL4D8f/sH8RxswL9VqDlRMCLBhHtWNZ2fWllI6jAFFrXQrCupUTIpo4npsPCJGIGr3PEMFam8tl2tparbVBGP16a0xJyWxrJJmScmp6dmpyBhELhfyq1sfiJIElnlZ5Z4jYta7DWlZKnv3hYqQ1EVVLWWutUrL//ICOTZKma9e053KZNE2Xyk+VNCFj4g3rOwv5HBGNj9/tO3m2qSnHzIuKC2ZO07SQzw9dHbkweNn3PAB4anM3W64Y6YowSJK0eUV+984dQRhls5nek2ePfX/K8xzf88p1VTkkjlJNuezloeFPvzjiSBUE4dM9m7q6OiOtK8Kq1o1lbz10+KsLF38q5POlIOha17Hr+e1Ptq/2XBcQjImnp2f7zw8MDF5WSkbarGxp/uC9g67rVDPSWjAhhI704c+PDA2PZDN+HMcA2NJSbC4WAWG+FExNzRhjPM8LgrB1Zctbbxxof6It0qba5VmrIi7zhKDjvWf6Tp3T2iglGcBaCwxEiIhpmgLA1p5NB/btzWb9KKpKql9+MzMAZnzv9vjE4KUrN0Zvzsz+buIYAYioUMivXdPes6V74/rOOEnq9jLYSDNorXUcRykZhtHU9MzcfIAAjqNWta7M5TJsOdK6kVsGG+w8yyeQiJSUJAj4XhdTbiMeZTP4oEmaOGZzL0MQsZEecGH8CXVSh9AbDmOeAAAAAElFTkSuQmCC"
    d["light_2x_ico_mouse_r_s"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAEjklEQVR42uWXS4wUVRSG///cenT1g55BZhgIKokwuBCIRmbhQiHEmOBj4UZD4s7EZ0xcuzDqgrg2xsjKQASCGxYmExIgwGIEw2hMMCMKGxrEMMhkprur63mPix5H1OqeHjRurNSqcu/96p7Hf87hLzdvY4WPKgCA4Ao3OoMvtRYKOAZGFpFZDgWEIP89mLUwgmpAESyE2owUgOtwuEohOokm2eIf/FNYblEL2I707MX0/KV0ppHPt5WA72HTemfHZmdi3BkblmZHgWWuyD4+67pmVcCpmXT/ZHTlRg7CMRQumjFJ1SpGh2TvTv/5x/wk0zSH8G5hrsGh0/GBk5EROgadRF1D1wEUIEgQSDKEkT75iPvWc0HZZ5b3vJ/0sd6qgIdOxx9/2amUmOVa8vDanuCVPaUoURCqsBa5hWMwXOPkhXTf0Y5j+sVoMcwqqgGnZtIDJ6OxYWl19Imt7idv1F5+qrRpnVH904HdsBytc2omPXgqqgXM7UpgIggj/XQyMoIu6YOXKkMVzrU0TrRwS2ZRC3jkTHypkQfe77m4LMwqyh6nL6dXbuSO4eqavP500Ek0TmFMT3+owghakZ74LvFd2gFhqhDB+Us5iTDWZya8tcMSxiBhLaz2TkeF73L6ct6KtDDtCr45BguhzjQyIwx87tzqug5WlVkJWA0YeOwTvZ6D67fyqzdzr+hyTqE1mpHOh0qiUmLjlv21aXMLBUoeL13LRKA9aEK0I51rFt+sWEFICCBEGOt7h8I7zxOy5BH6N+cRahf39pIup798EFBVVSwFu7WaZsXrSy5d88felWlj16QPP+AY4Z28YgMKrtzIWx3tI489YSSsouTx3b2VeoVZBkq/slAu8e39ra9/TKU3bXnV7yTqOuijeN2gB/tlxaAw4eLbv3zIAPVT8B8+/2eYDnyW3h1MdbFGkDCDdU5LwqHoGZbFqu859D12VX++rSLLR2yU6FxThXQEZY8D1TMSqcVQlZvWmdxqM9Tvr2a96tNSknkuGrN5YzYXYmRI7l9rklQ5kBkVQuzYbGwO3+Wxc0kYqUhx8e3Kh+/w2LmkE2ua6db7zVCVaZEISKFNOolOjLtr6mIEP13PD5+J19TEKv7SXFhFlmNNnVMz6fHppBoQxK5trtViBZBCVycZxlbL3p1+s6NDFX5+Ov7sRFQpsRqwq5ldq5Y8Dtd49mL64Rcd3+VCqLu3exPjbjvSQkHp2Teqouzz/cPh5IVktM75tj467rzweOnBe03FJ4k40cYte+yr+Pg3qe8ijHTDiPno1Uqf1rEfzDEIY913tDM1k9bLjFIluP4eGRsWEnMt25i1nUSrJS6Eet+IvPNiecsGp92jAVmmI7YK18AxPHgqOnImDmP1XEKRq0IhQiHSXAHs3u69+WypXpE+pGVgS6NYrcwfruUnv02mL2c/37ZxoiAc4UhdHtpodm1zJ7a4Sapphv4ZyUGGwdwi8Oi7aHX06qyda1kCJZ8bR81QlVbRjpRYfkrjgJOnKqzCCDyXS8NgkmqWAxyomK1g8lwSySjRpWaIhKykbPwG6sNDbrRN88gAAAAASUVORK5CYII="
    d["light_2x_ico_window"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAACz0lEQVR42u1XTU8UQRCtV9Mzg+4H7AVYEAW/7h5M0ESiXDTxpInGRC/+LC8mHDDxYLxhQqKERI2/wGgAkYTwMayQuMLuTH+Uh8VlXWCzzCYc0D72pOf1q6p+9Qpr0SYd12I6xnWsYOqwDyJChJR/xcEn1X4MEfE8j7kj0tZaIgJwKJiIKOX5vl8ubxtr0AGzfC4nIkmSNOKpRiRfqZ/lX29nP84vfDcmNZgQMFDsuzV27ezQYCMeaqUvQkpxubz97PmLKCqFYSAiqWMIwBjrKe/pkweXL52vxjEDe8xEnO+H72Y/RBulbDZDJF1h6ESOTk4AJNp4ntFaT03PjJwb4j/MVI2W53nl8vbcwlIYBCT0+NG9M4NFrXVThtuIIDGQJMnE5KvS5lYUlZZXVkeGh+I4AaAaiBujrYh0dYWDA/1hGCilcPSsiUhPd65Q6F7fKDGQJHs3Vo2Brm2KCAClFGDTgTFzPeUHVyMRyW7Ek8mXrz32hFLWCINX1yJfKWNMq0cNwDm38G1JOnnSQr6vmFnakSuAQR3AoQ1tBEFEAj94eP922BU4K+ly5vv+m+mZ5ZW1VnJVT+/FC8OZzClrXDqwMAxm339yznFrsNqK45g9djYlmBNxzrXbYgAwIACQrhrxj3Xq/2Anwl0BAOBE0jXr2ilmtAIDQCAAWuskSXp68lpbPuI7EyKAxEmlsmsFmlsMQNbaXC4zUOz9/GVeGzMx+apQ6HbWpbA8DK5Uq6trETNnMqeL/b1a65o2q/qNRGh87PrXuUWt9Y/NrfWohHTKL8QMZt7eqdy9M57PZXcq1VpUUR8sRCQIgrn5xanpmSgqdeKuiCiXy968MTp69Yqxdi9TjVOMiIRhqBO9vLLa6B2ObuWo2N+Xz2er1fiv/aaRyYkwEAQ+kLZ9gkhIa22sbfLw6kDBjuMk9VhROwhg/7RwaItJa/NbXfHkytVvpAlgkAjtks0AAAAASUVORK5CYII="
    d["light_2x_ico_window_s"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAACtElEQVR42u2XsWsUQRTGv+/N7O0lZ6IxEIxiEQ4Ui1QiWIm2gqUgprC0t7FRBAv/iFgq+C+kE2wsFO0ENYYEEo0HJ2KSu92d2XkWt+p5bmKyhynU4a4ZWH77zfvme2+53vqE/VqCfVz7CrOlu1r8qy9yFzBVBEVkwOE0uxwAhNvDVBFZ1CO2N9R5LX27XcqaHJOg6Gbaz7P9pFrE9pfw8HH3xaLPPCrCFCSa02buQnzquO3nsWf9nqZPG3rj/uZKK4zGDNVrpkI6r9bg3rXGmRPRVlrwCmVBUY/48HGy0goTB6hAI6YqwAqymDp1honT+YVkdsZ+V2YLWQbtDX2x6EdjKnDn6ujJYzZxKtwrC0IkGW492HrfDiut8GY1n52xnVSF35SRcF4zr0HRqPPEUTMSI7KsULagmDrEIxOy3MoNmWQ/jGb7LdTbVQWJmqUQ1WBGGLSoALm99YVIMr37qGOkUs0AKESw9CGPLTOvO11qEnnAy3e+IukbrxbRClR3EVdCKocJq/L3tAOygqJe483LI40YeaiiLQD1iPMLyZs1P2Cwkmy0gtNNO96gzysapBHz0ZPUBxj+7hgV2ErVGFSGaSg/le1qVvyqxaNI+fn/vZ36P+wPwvTPwGzpBGGIEPA9ufd6z3ru3wlGgoAQqdNuplOHJHXlz+yUwAoSqtjsFo13sMWQcDkmx6R51Dx95Zzj7QedIxPi8ypjgRFsdHVpPbfCgw02p03qilS3/fLnzsfPXvvE6Vo7LH/MUXW6EqEVfN4K1y+OTo7Ll44a6ZuuerCRGp+/dfcXkpVWCEM0NEIPj8mVc/GlszXn+/b7v2J6gZ04fb2aJ5mK7N2XLNp9c9pMjstm8lNb5MAnU1AIUa9RONQFSJ16P+gv+2veA+ikimHGAoAscfK2LWYY0r+XjV8BHOA8B+t3tqsAAAAASUVORK5CYII="
    d["light_2x_ico_theme"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAFH0lEQVR42r1X308UVxSee+6duTvDUhFWQKDU2CLBErWkNZoYY7RqTGk10h/2wTZ96kv/Kx+MD4XE+qDGQKJGjQ22toYCaxcFocuy/FjYmZ25c++5fRi7XZbl17bxPm52zne+755zvnNJOrNgvKkDxhs81YBprbU29PY/ZNsB0IQQAAB4naJSKvqREPL/gGmtDcOwTJMxhoh5z5NSEoMQQuI1DmNMoRIiRMRiElWCISLn3DB0enZubDw18XIqm10IhCCEUID6+rrWlub9nR1tbbtt2/Z93zCMDViS9aoxIlTjOKmJl7cH77+YnPL9AAgwRgkhiNowDG1oRGSUNjYmThw70nOoWwghlVqPYmUwrTWllFF6Z+j+0L2HoQg55wAQ5aC15tzSWufzntbaskxElFJ9cPD9872nHcf2/aAiXgWwCEkEYuCnW09+feY4NgAg4usPCAmE+Obri+3tranU5NT0X78/+2NhMec4tut6bW27v+rrbW5qDISANXpW5ssoHbhx6+cnv9XWxqObK/uDZVk7d+w4eKDrQu+ZH77/9uOTxwIhHMeemZm9cnXAcz1GaXQRG4EhYo1j3xm6/+SXZ3U73lJKrXejUspCIci7ru3Yn5w9+d3lL5jJYtzKzi9c67/BKN2kqbXWnPPUxOTQvYeOY6+HVNQTgACAUmol73Z37bt86aJEtGOxkdHkg0fDth2L6mgDGfXtwXuhkABki/1OCKEUllfyHe/uOXf6RKHg25wP3n2wuJhjjJZqCSW0DMs00+m5F5OvOLfKktr0UEq9QuHo4Z6WlibUOpfLjydT3LK0xopgSBkdS6YCX2w6C9afAObRwz1hKCmFkbHnSqnSHodSNTTqiZdTBMjaQtqanhBK1f52a4xzSmF6Jp13PUr/VRKKGgKA63rZ+QVGqVHNTDcMw5BSNtTXJRL1iOh5hSha0SFWMQulDAKxxRFeiZmhtbZMMx53UGupyqNBWV1VjVQB2yiPBmta5z95NyFEIQohorzL+geKCiil4jVOQ32dlNIwquGntUEpXVzKzWbmgRDHthMN9aGU5J9opaWvGaOtLc0KsVoxtclYOp3xvILWOpHYWRuPI2IxGJQpsL+zw2SsutKPWu3x8FMAIhV2dXZY3Cwd4qvAhAjbWnc3Ne0SItwuOYVox2Kj43+OJVOmaXJude7bG4aSEKhcIIja4taJY0cUqm2BKYU250u55f7rNy3TLBT8j3oOtDQ3hWFYGmYVGADxfb/nUHfPwe6869JKNlHmEoiota5x7OWV/JWr/SsrrlKqsbHh7KnjQgiyutDWLjxEhOJ87+nMXPbVdLqmxqloNNFmxxizTBM1jowm+6/fXMm7lAIh5FLfZzzG15o1WzsFpETHsb/s671ydWAuO+/YdhR6tVObjLFMdiGTmXs8/HQsmbJMkxgGIaTvwrk977S5nre2ZSsvPNEG57netR9vjIwluWUxxorbDqJubWmilKZnM57nAxDTNAsFv7ExcenzT/e0V0baaJVD1IxRSunDR8ODdx8s5ZaBgGkyAAAgQoRaawCqNUqlYpx/2HPgzKnjsRgPgmB7q1zp6ujYsYWl3HgyNTL6fHom7bqelJIAACG2HduVaOjqfK9z396W5qZACKVwA4snmz6ZEJExxi1LKZV33ez8YjTLAUiiob62Nm5ZZhjKqDU37heylfdZ8VURba4ESDQJlZQKERG3aBdsi7M8ioWIgVL6tYNs2yhYFSZSteO90Zfn3z651FlDD1MhAAAAAElFTkSuQmCC"
    d["light_2x_ico_theme_s"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAE5UlEQVR42s1XS2gVZxT+zv//M3dmbh4+Qqwxtkqtj7ZQEUGFIpRqXwtbCtoupBShUCiuutGV0kXdlbroXqRacNN040IUsqnBB21FqRohia0p1xhz87i5c2f++c/p4sYmubl52koPzGaYOR/nnO+c8x0qDAzhWZnCMzSz2B9k4gEAov8GTAQsIIJRoCfpyNzES0X/EhgLCMj55Bs4xnBJbCZEIMKyPPkeZQ6VVJih1NOBOUaUIwC9BXelO7vZmz14zHEiiqAVVq9QG9foXVu8Te26IaRSRWjO3NJsbBQBgKY83ejJTl2s3Opz4xVRCr4hRXBc/UYcwxha16o+2p17a5sfp2IzaLUYMBZ4Gp6h05cqP3QmFStRjrSCACIQQZQjFgyXmAWBT8xIM9mz1T+8L2yOqFSRunh1wERgNOJUTnbEF361TRFpNREKAEUoJ/LVwfzLz5vfeuzdB67zpi0UuTmi4rhsbtdH9kfrn9NxIjNLqOqS2zN08qfK+et2ZSNVK1djoY/W5fTGa/7h98Pvvmj45M2gnEhTRPf+csfOlEfL7JmJQswF5hjNEZ2+VLnwS7pqGVk3C3EENkMpluGSNIX0+XvB15/mc4byAfUPuhPnYk/TPBOEBVGObvRmZzuTpogyNzuvACIoBa2QOQyNyeuveMcPRtahIaSu2/bHrqQxopqU1EnjqYtJYqVKh4UYEYzG41HZtsF89nYwFks+oLOdSWGI/enJVFPDCnz0FtytvizK0cw6zW1aY6ws7+/0N7RpFjwa4WvdNswR1wUTga/pSrcdn4W488QHOEaYow92+qkVo3H5Tpa5aT2upmbDCW72Oa3qEGlBG4SQWtmy1oQBGU33+l2xxEZPelOTvaUwMi4PBtkztCQsEJBmaFup1rZoxxgpS/8g+1O8TYsstRInstjFMRWNBaFPyxuIRWyG8nRvqoZXS0eaMhPkibea1VMLpp9udROhunGqSDUTS/3zkXVY3qDaVmqbydLCE4Gn8bDo7j90mqgxovYWbe2kt2nU9ww2rlE1fF24MeB71FNwI2VhkfYWtaJRWZ70pmoysGuz53tLpD4BzDh/3WqFLMOuzSb0wVyvZopQSWVTu16/SsepqEUGlzEaQ7pyx17ttjmPwoB2bPQqdpofVTPyQ58+3p3LeHGZzBwaAhoY5m864sCjsVje3e6/2KYTi1mprxVKFdm7zd+71S+WxNPzM8IxWNCcp8ejfOz7crHENpN1rfrQniBOa1vWzMx7nMrhfcH9Adfd75rz9RdNVRx4BqFPjvHz7/bbjnhojLUmRTh6IIwCmrmszcxGsRmaInVkf3T8zPgfj7gpIpZplJEnyu7PR9z3kM9fT6/etYFPICjClx+Gr64zI+N1pnl9wVNVcKNlPnEu7rptwxz5ZkLtQOAYL63RRqOn4MbKohRyHpVieaFVHz0wK9JcUo4ZnoHR1NGVnO1MBoa56lQrKIVKChHRilhgM8kH9M52/9CeIAqonMjipNxU6dgYUqHI17qzy3fsvX43PC5pJpqgFDWG1N6idm7xdmwyG1brOJHMzaWLad6TyTF8gzBHmUOxxP2DXJ3lWlF7i1rRSKFPiZVKOv8cp4XcZ5NXhYavSamJW8Y6sQ7MUAtbF2aBs7yqzByj7AQC0KTGWviiMIudfkQTSP/3y/Nvws9+Unb3H18AAAAASUVORK5CYII="
    d["light_2x_ico_keyboard"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAE0klEQVR42u1XW29UVRT+1j636dwKL6VToA0m+u6DETWOLY1TWgiJhYpQLCFeEuIv8sVEEzEgYORSoLFWIHIz4pvRUAKYSss4lODMmZlz9mX5sKdTbAtWijwY9ss5Z2Wfvfb69rfWtzbNFGfxtIbAUxzPnD2R4S5pZWaAVrQwLfG/u8AHMzuOI8QTiFhrDYCIlnDGzK7reJ5XLodKK1pxZNlMhpnjOG76c5uePNf9s1wZP3th8vpNpVbojEHUkVvTk3+lc/3apj+aKc4yw3VFuRx+/MmBYrEUBD4zrxBDIlJKO66zb8/QC88/F0UREbkAmI3nBd+e/b74RymdTgEcBIExxh6z3RSD7Q6IyAa9hIWZwQAECamU4ygp5ejYxIau9XYR1zKiXA6vXb8V+D4Yw++81dW5lhlE0NpIJQkkhPA8F4CUShsNwBFO02KMYbDneo4jACita9X6Z18cKd29VyyWpm5Pb+haX49idy5kpaRm5iDhd3WuNYZHz0xUKpVCbz6Xa9PaRFF0fHQcwEBfdzKZAlCvz1taWpKOI6ani2Pj5zKZdKE335FrW93aeqdYEkRxLBuRNSG2lDHaMHDy9Pj5Cz94rluavbf//XfTqeThr0YvXbkKwBg9NLgVwIlT4xcvX7UU3zW0rRJWD3z59fR0USkVSzmye7vSqrn4QyoIQZB92sScm0mPYjkAIju9kc6Nz0dXECKKY9Vf6NHaVMKwrzcfBEEUxwOFHkuH/kKP1sq+GGYAA4WeKI6DIHh7cMuZ8XOZdHrzm2/IWD2Yzg9xBtJat7Zm9w7vAFhKVa3VAKRTyX17hgCE1ZqUEkBqzlKt1mIpjTFdnes++nCEiCphVWu9GAx3UTay4zhhWD14+LiNrKOjXWtdCasHj54AsKVvU0tLACAMq4fmLIlE4DjOrd+mmpGtas2C/9EZs++7x05+c/Hyj67n3r9f3v/BnlQyefTY6ctXfgIgiCxBTo01LES0a8e2sFo9dPTk7Zk7SilmMzK8fXFlEI8+9v9WYixBBvp6mFGuVPp680Hg16NooNBtYekvdEsl7Yvd+kChux5FQeDv3L71zPi5TCbd15v/FwRJJtNDg1uJWGujlPI8N5EIRnYPgiCl0toASLQGI8ODAGSstDFKqVxuzXt7dwIUx/GyCGKD01pHkSSCEBTH8uCR4/V6RETM8+nPbDUWQpBSur/Qva6jvVarAwSw57rLgpGIGCCaK95aT16/GYY1xxVs/n6WDAAkKIri/GsvW8klgoVXiIfAaAs3EUkp4zhetSorpSbAcYRSOpFIaG1cR5illEcQEVEi8BvaREQENlyrRcLKWFM8LWiZTKoj1/bzL5NSqU8/P7J6davRxtYfbbTFUJulRU4zu44zOjbx3flLho2VmFq9Pj1TFEKkUslce5uUkmheqbEp/+qv125IKe/O3rtTLBE1kpIA3/cXU2tBcFO/zxhjGiAzhCAhRFitbdm8KZtNV2t1QUS2/WZm3/evTd4YHZsoFksL8tEsQ7hp0XYymXT36xs3vvSi0roxp9nrM3MQBDKWU7enmwq0grYAufY12Wy6Xo/mjQ9eLAyzIPJ9j5ogPm5rBYaUUmn9YFfoLoAeQBTFK2xR7e9EtKD/dJeD/mME9uwW8z9x9hegUpyse/8UaQAAAABJRU5ErkJggg=="
    d["light_2x_ico_keyboard_s"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAAEe0lEQVR42u1XXYhVVRhd3z7n3HPuOTPOOII6UohMCSH1FvRS1IM5Br1ZGSaiMTMRPfViCPVgYgwEhST9CAXhQ6BCmYbUgy+BSeVbwdQYDvgz3ZjRmbn3nr+99+rhnLlenXGaHDEINxzY9+Psu7717fX9HBmvTeJuLYW7uO6B3ZHlzjWxfJa6RBYEI2EJz4HcCcK5AQAl84GR8FwEnkzMMNec69e/pbWiU1kiztjCc1tIFU8mpu3h0/G5UZ1pLAmMEEFfr7PtKf+h+90WnozXJgtOkzN8/VB9rGZDX+xS74xKJNd0HezfET263mukVAIXgCUCTw6fTsZqdnmHEAh9MRYFN6VK6mQZn4L0XIu1pb4cJVnO3JEk5yenkofXuQUzl4TnYGKG50Z16AuBt14MN6x1SYjAGKQ5IXAVfE8ApDm1BTDHQvieOE4pjXqTbx5uXJ6wYzU7ctE8ss5tJnQL13LNTNMSkS8b1rqW/Pib5GqdOzcGD/Q6uWEz5cETMYChzUFnqAA0E1tYBjcH3VXxHBm9Yj77LunplJ0bg741anW3ulAzjkiSlXJzW+IpfmsDEB+eTI59n1Y8uTRhDwxFXR3q3WPx8bMpAG2xe0sVwMGTyfEf0uLInq3hVN3u+6J5/orJNNMMe7eHmaYQkOtac+dKVlSJLaUTIm0ZKijvUtqPACJSbmZd/4ekLk6mGQc2Bdrg6gx3Pe2HvjRTDvYHhUQH+4PMlJuWpZky9GX3luqn36Y9nfLypiDNUYIvDJYbrOySfS9FFKQ5p5sUoCtS+3dEAKYaTHNijiWx3LDW/eBVTwTX6jY3i2BWiPNag+8caRTMHlzj5oZTDTt8NAHwyuYgqgqAdksYiOfIL2O6xWxVt5CLAPMrcvBE/NWZtOLKX9P2wFBHVyTvfxl/fTYtal0hkPdOJS3LnhfCqQaHj8bnL5tMk8Te7SFJEO2R/E9bTCGQwf7AWhR5FvrSSDgwK4eB/iDR5aZlaSSs+njjubDIs10bFy0QbdATyu4toQi0YaoZeBIF8vb2EECaQxsAiLquW4xBqvlArxreGQGIM+rFCKSFF6dllUozDh9p1mMoRbLMp9naSMxWwoH+YP197nRMBRDwvcWFUQk4e7EiyDV+HtXTDboOOF83UIJGyucf9x1VZnvxmlK3ACvCqwRpzjjjym6V5hCB6yDTiAIxBq4L2vnAFEQQ+qj6YllWEBL1eLaNtarPeG2yqL97Pm+c+TUPfVm1XK1eroqLEYGxHLlotMWtuqkAhuhb7SwLxVgAcBRmYv4xbqxFVyQfvdYRFu4WByyx7Un/xxGd5Lw0YS/8acr/JkQQVMRZsHG7gt8uGVPwAkAoJa7CtYYdeiZcsUxNN+koSDF+W6JakZ9+zw+dSsZq1vKGbLRFei48E6r24gwBezrV1if8Zx+r5LotjC1ykS9JzpGLJsmo1O0OdAISStDX66xYpuoJr/eH9g8LSyhBUBEld2ByTHNqfYMm3ZtEDKCZ3lzTbnuau0n97rx5s3Ske18x/xOwvwGdr2MHZTWG0gAAAABJRU5ErkJggg=="
    d["light_2x_ico_folder"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAACxklEQVR42u2XS2sUQRDHq6q757WBxBwU8RGNggcvQYX4gqjkIBE9CBEEPXjx4OfxJHhQD+LFS8QHGvUgfgAlEEMWNQlrEk2i62bn1d3lYdzNkqzZxI1BMc0c5tHTP7rqX/+pwcnpWVivQbCOYwP278Fk7QUzMwDWm5fdR8Q1g7muiwjA9SYiWMtxnBBhszAitJZH8x+MNYi4mIdgrfU9b3fHjiiOm4Sh1qZYLN25ez8MIymJF28Oma2Qsud4d++JY6k2vxdOaa0NAn/w5evBF6+UUkpJrU3t3hCAmYUgKcTDJ88DzzvZc6RYmqfVALNky+wsTdNyOcrlsH1TW3t7mzV2QScMJOh7ab5QmGprbR149Mzz3KOHD0Zx0pDHAESYptoYi1jJGSIqJeM4OdC1v+/0qflSmYhqXqAwDG/eujc+UXBc58HjwbdD7yzbBrsBMJYD3zvb1xsEvjFG1uoeALQ2cZzESVKFZY+UUlcu9V+/cfvzl5nA94ZH8oANSMyAiOUwdF33wvkzZa1paXCXDiJK0zQI/Iv957Zu2RxFCQkixGUORBRCeJ4TBP7c3FdrLSLKlToNURQn27dtvXb18thEoX4t1kTCcdT4xKfHT18ysxCiTlE34mGSJEKIfXs7G+iC2fPcamq4UklyVYWCiMwcxfGvXG3B9hiSJF3OrlaOxBWEYemsje/ZBuwvbQuyErHWWmubWbSyCDfoQRxHtbTkMn9qBua7nu+79WGZNSilRvMfBx4+S5O0md6GAaQQM7NzRGSNqS71E6a1zgwt/35seCTfZBcFAAwsSPi+q0Ojta7C0GjTuWsnEn4rFgmpeRIAIKCxplQqx0myp7MDiZgZJ6dnmdl1nDdDw4XClFQSmNdKfsbaXC7oPtSVJRKzXyZm9lxXSMFrR6p+r8MoWiyQMI4h4j9SyxVhL0ifEGEtsvVf2tUPXD5VKQAEqLkAAAAASUVORK5CYII="
    d["light_2x_ico_folder_s"] := "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAIAAABuYg/PAAACrElEQVR42u2XzYscRRjGn6eqe3q6Z2Y37EUigpiDOSnsQQ85BBQ8BD14EAKC4M0Q73rwkFv+gkQJiAfjn5APvATibS+LkBBcVr2sLMuuyersfHRPV9WTw+xmxsm4s7szBIV5qUtDVf+6nvet563m1vYTvKgweIExh/3/YNHwQ9C/TxRAGM4CJoBALSGJsUQCPqBbyJipYdYgBKz+5pwXiVEg4QMaKd94NWoXmhZWOvzZDFd+aO91FUeUntuWVLG8eD755N2k58AT6Rn5gMWMN+/l398rqjGSmKUTOJqwyDKOcONut5Hy43eSx81j6Ensf1wEgEReYq8jU+PpJfPyknEeA55gLXb3wvqmf+mUuX67W6vyw3OVTo6JPAnGoFfKeZAHMhqiEqNd6L3l+LML6V8tWTtYYA1aXX3xXfuXP1xW4Td3uj89LH0AOGFDPqiRmssfVBczOj9U+hIIlA6dQp2erBmsCUIS4+qntc+/bm3s+IWMK2slJqZNINHsKEvw5UdZ02lUCBLmn4OENShKLGT86mJ65rRt57KGhocPRJa1Khcybu3KhyEZJ4Y16OQ6+0p07VL90YaTMOaEPDMHoFrh2ob79sdCQmTHOcgEZzPo9mQt3no9PnxmEOpVUggqQDw7SNHxnJSQ0M41EQah29Nh3nh05FFkeH7avJ/NYf/Ra0HfIX2AD1O9NAg+IIRDYRKqFTbq7PvTNLB6ynpKjYWRkJDEWP3V3biV56WmudtIiCNuPvaxwXBbj/pNpHT7hvbz725lrSSnTU/ffxspS4eeO4AR6Hm8+Zo1xM7fMgbTk/pSOY/dljqFls9YYwCBW9tPJKQJ7z8o1zd9EkGzKz/vsVjj+29X9ptz/5dJQpYwjiDNuNwltA66xKBA2vnMQYPGO1r6xszt6sTxFHyrJFRQGlyQAAAAAElFTkSuQmCC"
    return d
}
