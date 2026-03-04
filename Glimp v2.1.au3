; Glimp
; Copyright (C) 2026 Aurum Prestige Labs
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon logo\GLIMP-AurumPrestigeLabs.ico
#AutoIt3Wrapper_Outfile_x64=Glimp v2.1.exe
#AutoIt3Wrapper_Res_Comment=Glimpse your ideas before they fade.
#AutoIt3Wrapper_Res_Description=Glimp - Fast Note Taker & Idea Capturing Utility
#AutoIt3Wrapper_Res_Fileversion=2.1.0.2
#AutoIt3Wrapper_Res_ProductName=Aurum.Prestige.Labs
#AutoIt3Wrapper_Res_CompanyName=Aurum Prestige Labs
#AutoIt3Wrapper_Res_LegalCopyright=© 2026 Aurum Prestige Labs. Original concept by Luca D'Este
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiListView.au3>
#include <ScreenCapture.au3>
#include <File.au3>
#include <Array.au3>
#include <Misc.au3>
#include <TrayConstants.au3>
#include <ButtonConstants.au3>

; --- 1. CONFIGURAZIONE & LOCALIZZAZIONE ---
Opt("GUIOnEventMode", 1)
Opt("TrayMenuMode", 3)

Global Const $APP_NAME = "Glimp v2.1"
Global $LOG_DIR = @ScriptDir & "\logs", $IMG_DIR = @ScriptDir & "\screenshots", $INI_FILE = @ScriptDir & "\glimp.ini"
Global $hMainGui = 0, $idList, $idSelectAll, $idComboFiltro, $idSearchInput, $hMenuContext
Global $idBtnEditTag, $idBtnEditNote, $idBtnDel, $idBtnExpDoc, $idBtnColor
Global $TagColors = ObjCreate("Scripting.Dictionary")
Global $sLang = "EN"

If StringInStr("0410,0810", @OSLang) Then $sLang = "IT"
$sLang = IniRead($INI_FILE, "Settings", "Language", $sLang)

Global $dTxt = ObjCreate("Scripting.Dictionary")
If $sLang = "IT" Then
    $dTxt.Item("Acq") = "Acquisizione"
    $dTxt.Item("Gest") = "Gestione Note"
    $dTxt.Item("Exp") = "Esportazione"
    $dTxt.Item("Filter") = "Filtra:"
    $dTxt.Item("SelAll") = "Tutti"
    $dTxt.Item("HowTo") = "Istruzioni"
    $dTxt.Item("About") = "Informazioni"
    $dTxt.Item("Exit") = "Esci"
    $dTxt.Item("Minimize") = "Riduci nel Tray"
    $dTxt.Item("Donate") = "Supportaci"
    $dTxt.Item("DelMsg") = "Eliminare definitivamente i record selezionati?"
Else
    $dTxt.Item("Acq") = "Acquisition"
    $dTxt.Item("Gest") = "Note Management"
    $dTxt.Item("Exp") = "Export"
    $dTxt.Item("Filter") = "Filter:"
    $dTxt.Item("SelAll") = "All"
    $dTxt.Item("HowTo") = "Instructions"
    $dTxt.Item("About") = "About"
    $dTxt.Item("Exit") = "Exit"
    $dTxt.Item("Minimize") = "Minimize to Tray"
    $dTxt.Item("Donate") = "Support Us"
    $dTxt.Item("DelMsg") = "Permanently delete selected records?"
EndIf

If Not FileExists($LOG_DIR) Then DirCreate($LOG_DIR)
If Not FileExists($IMG_DIR) Then DirCreate($IMG_DIR)

; --- 2. TRAY MENU ---
Func SetupTray()
    TraySetToolTip($APP_NAME)
    TrayCreateItem($dTxt.Item("About"))
    TrayItemSetOnEvent(-1, "ShowAbout")
    TrayCreateItem($dTxt.Item("HowTo"))
    TrayItemSetOnEvent(-1, "ShowHowTo")
    TrayCreateItem("")
    TrayCreateItem($dTxt.Item("Donate"))
    TrayItemSetOnEvent(-1, "DonateLink")
    TrayCreateItem("")
    TrayCreateItem($dTxt.Item("Exit"))
    TrayItemSetOnEvent(-1, "TerminateApp")
    TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE, "ToggleGUI")
EndFunc

; --- 3. INTERFACCIA PRINCIPALE ---
Func ShowGUI()
    If WinExists($APP_NAME) Then
        GUISetState(@SW_SHOW, $hMainGui)
        Return
    EndIf

    $hMainGui = GUICreate($APP_NAME, 1200, 780)
    GUISetOnEvent($GUI_EVENT_CLOSE, "ToggleGUI")
    GUISetBkColor(0xF0F0F0)

    Local $mFile = GUICtrlCreateMenu("File")
    GUICtrlSetOnEvent(GUICtrlCreateMenuItem($dTxt.Item("Minimize"), $mFile), "ToggleGUI")
    GUICtrlCreateMenuItem("", $mFile)
    GUICtrlSetOnEvent(GUICtrlCreateMenuItem($dTxt.Item("Exit"), $mFile), "TerminateApp")

    Local $mHelp = GUICtrlCreateMenu("?")
    GUICtrlSetOnEvent(GUICtrlCreateMenuItem($dTxt.Item("HowTo"), $mHelp), "ShowHowTo")
    GUICtrlSetOnEvent(GUICtrlCreateMenuItem($dTxt.Item("About"), $mHelp), "ShowAbout")
    GUICtrlSetOnEvent(GUICtrlCreateMenuItem($dTxt.Item("Donate"), $mHelp), "DonateLink")

    ; Pulsante Donazione Icona
	;Local $idBtnCoffee = GUICtrlCreateButton("", 1150, 22, 40, 35, BitOR($BS_ICON, $WS_TABSTOP))
    ;GUICtrlSetImage($idBtnCoffee, "shell32.dll", 174) ; L'icona dello scudo/shield
    ;GUICtrlSetTip(-1, $sLang = "IT" ? "Sostieni Aurum Prestige Labs" : "Support Aurum Prestige Labs")
    ;GUICtrlSetOnEvent(-1, "DonateLink")

	; --- PULSANTE DONAZIONE (Stile Emoji Moderna) ---
    Local $idBtnCoffee = GUICtrlCreateButton("☕", 1150, 22, 40, 35)

    ; Impostiamo il font specifico per le Emoji (Segoe UI Emoji)
    ; 18 è la dimensione, 400 è il peso (normale)
    GUICtrlSetFont(-1, 18, 400, 0, "Segoe UI Emoji")

    ; Tooltip e Evento
    GUICtrlSetTip(-1, $dTxt.Item("Donate"))
    GUICtrlSetOnEvent(-1, "DonateLink")

    ; Toolbar
    GUICtrlCreateGroup($dTxt.Item("Acq"), 10, 5, 120, 60)
    GUICtrlCreateButton("SCREENSHOT", 20, 25, 100, 30)
    GUICtrlSetOnEvent(-1, "CaptureWithNote")

    GUICtrlCreateGroup($dTxt.Item("Gest"), 140, 5, 330, 60)
    $idBtnEditTag = GUICtrlCreateButton("TAG", 150, 25, 60, 30)
    GUICtrlSetOnEvent(-1, "EditTag")
    $idBtnEditNote = GUICtrlCreateButton("NOTE", 215, 25, 60, 30)
    GUICtrlSetOnEvent(-1, "EditNote")
    $idBtnColor = GUICtrlCreateButton("COLOR", 280, 25, 70, 30)
    GUICtrlSetOnEvent(-1, "PickColorPalette")
    $idBtnDel = GUICtrlCreateButton("DEL", 355, 25, 100, 30)
    GUICtrlSetBkColor(-1, 0xFFCCCC)
    GUICtrlSetOnEvent(-1, "DeleteNote")

    GUICtrlCreateGroup($dTxt.Item("Exp"), 480, 5, 280, 60)
    $idBtnExpDoc = GUICtrlCreateButton("DOC/TXT", 490, 25, 80, 30)
    GUICtrlSetOnEvent(-1, "ExportMultiTxt")
    GUICtrlCreateButton("CSV", 575, 25, 50, 30)
    GUICtrlSetOnEvent(-1, "ExportCSV")
    GUICtrlCreateButton("HTML", 630, 25, 120, 30)
    GUICtrlSetOnEvent(-1, "ExportAllData")

    GUICtrlCreateLabel($dTxt.Item("Filter"), 800, 33, 40, 20)
    $idComboFiltro = GUICtrlCreateCombo("Tag", 845, 28, 70, 25)
    GUICtrlSetData(-1, "Nota")
    $idSearchInput = GUICtrlCreateInput("", 920, 28, 145, 22)
    GUICtrlSetOnEvent(-1, "LoadData")

    $idSelectAll = GUICtrlCreateCheckbox($dTxt.Item("SelAll"), 10, 75, 60, 20)
    GUICtrlSetOnEvent(-1, "SelectAllAction")

    $idList = GUICtrlCreateListView("Data Ora|Tag|Nota|Path", 10, 100, 1180, 640, $LVS_REPORT)
    _GUICtrlListView_SetExtendedListViewStyle($idList, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_CHECKBOXES, $LVS_EX_DOUBLEBUFFER))
    _GUICtrlListView_SetColumnWidth($idList, 0, 130)
    _GUICtrlListView_SetColumnWidth($idList, 1, 100)
    _GUICtrlListView_SetColumnWidth($idList, 2, 450)
    _GUICtrlListView_SetColumnWidth($idList, 3, 450)

    $hMenuContext = GUICtrlCreateContextMenu($idList)
    GUICtrlSetOnEvent(GUICtrlCreateMenuItem("Edit Tag", $hMenuContext), "EditTag")
    GUICtrlSetOnEvent(GUICtrlCreateMenuItem("Edit Note", $hMenuContext), "EditNote")
    GUICtrlCreateMenuItem("", $hMenuContext)
    Local $idMenuDel = GUICtrlCreateMenuItem("Delete Note", $hMenuContext)
    GUICtrlSetOnEvent($idMenuDel, "DeleteNote")
    GUICtrlSetColor($idMenuDel, 0xFF0000)
    GUICtrlCreateMenuItem("", $hMenuContext)
    GUICtrlSetOnEvent(GUICtrlCreateMenuItem("Open Media", $hMenuContext), "OpenMedia")
    GUICtrlSetOnEvent(GUICtrlCreateMenuItem("Open Folder", $hMenuContext), "OpenMediaFolder")

    GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
    LoadColors()
    LoadData()
    UpdateUIState()
    GUISetState(@SW_SHOW)
EndFunc

; --- 4. FUNZIONI INFORMATIVE (RIPRISTINATE) ---

Func ShowHowTo()
    Local $m = "Glimp Quick Guide:" & @CRLF & @CRLF & _
               "- ALT+SHIFT+N: Add a text note instantly." & @CRLF & _
               "- ALT+SHIFT+V: Show or Hide the dashboard." & @CRLF & _
               "- Use '/mytag text' to tag notes on the fly." & @CRLF & _
               "- Click the ☕ icon to support the project!"
    If $sLang = "IT" Then
        $m = "Guida Rapida Glimp:" & @CRLF & @CRLF & _
               "- ALT+SHIFT+N: Aggiungi una nota testuale al volo." & @CRLF & _
               "- ALT+SHIFT+V: Mostra o Nascondi la dashboard." & @CRLF & _
               "- Usa '/mytag testo' per categorizzare subito." & @CRLF & _
               "- Clicca l'icona ☕ per supportare il progetto!"
    EndIf
    MsgBox(64, $dTxt.Item("HowTo"), $m)
EndFunc

Func ShowAbout()
    ; Creiamo la GUI leggermente più alta per far stare tutto (420px)
    Local $hAboutGui = GUICreate($dTxt.Item("About"), 500, 420, -1, -1, BitOR($DS_MODALFRAME, $WS_CAPTION, $WS_SYSMENU), $WS_EX_TOPMOST)
    GUISetBkColor(0xFFFFFF) ; Sfondo Bianco

    ; Icona Informativa
    GUICtrlCreateIcon("shell32.dll", -278, 20, 20, 32, 32)

    ; Titolo Principale
    GUICtrlCreateLabel("GLIMP - Fast Note Taker", 70, 20, 400, 25)
    GUICtrlSetFont(-1, 14, 800, 0, "Segoe UI")

    ; --- RETTANGOLO "CREDITS & SOCIAL" ---
    GUICtrlCreateGroup(" Original Concept & Credits ", 20, 65, 460, 110)
    GUICtrlSetFont(-1, 9, 600, 0, "Segoe UI")

        GUICtrlCreateLabel("Luca D'Este", 40, 90, 400, 20)
        GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")

        ; Link LinkedIn
        GUICtrlCreateLabel("LinkedIn Profile", 40, 115, 120, 20)
        GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
        GUICtrlSetColor(-1, 0x0000FF)
        GUICtrlSetCursor(-1, 0)
        GUICtrlSetOnEvent(-1, "_OpenLinkedIn")

        ; Link GitHub (Tuo)
        GUICtrlCreateLabel("Personal GitHub", 180, 115, 120, 20)
        GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
        GUICtrlSetColor(-1, 0x0000FF)
        GUICtrlSetCursor(-1, 0)
        GUICtrlSetOnEvent(-1, "_OpenMyGitHub") ; <--- Nuova funzione da aggiungere sotto

    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Chiude il gruppo graficamente

    ; --- SEZIONE PROGETTO & SUPPORTO ---

    ; Descrizione "Why Glimp"
    Local $sDesc = "Glimp captures the glimmer of an idea before it fades."
    If $sLang = "IT" Then $sDesc = "Glimp cattura il barlume di un'idea prima che svanisca."

    GUICtrlCreateLabel($sDesc, 20, 195, 460, 30)
    GUICtrlSetFont(-1, 10, 400, 2, "Segoe UI")

    ; Link Repository Ufficiale
    GUICtrlCreateLabel("Official Project Repository (GitHub)", 20, 235, 400, 20)
    GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
    GUICtrlSetColor(-1, 0x0000FF)
    GUICtrlSetCursor(-1, 0)
    GUICtrlSetOnEvent(-1, "_OpenGitHub")

    ; Link Donazione (Testuale)
    GUICtrlCreateLabel("☕ Support this project (Ko-fi)", 20, 260, 400, 20)
    GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
    GUICtrlSetColor(-1, 0x800000) ; Colore bordeaux/caffè
    GUICtrlSetCursor(-1, 0)
    GUICtrlSetOnEvent(-1, "DonateLink")

    ; Footer Finale
    Local $sFooter = "Developed by Aurum Prestige Labs." & @CRLF & "License: GNU GPL v3"
    GUICtrlCreateLabel($sFooter, 20, 310, 460, 40)
    GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, 0x666666)

    ; Pulsante OK
    Local $idBtnClose = GUICtrlCreateButton("OK", 200, 365, 100, 35)
    GUICtrlSetOnEvent(-1, "_CloseAbout")
    GUISetOnEvent($GUI_EVENT_CLOSE, "_CloseAbout", $hAboutGui)

    GUISetState(@SW_SHOW, $hAboutGui)
EndFunc

; Link LinkedIn
    Local $idLnk1 = GUICtrlCreateLabel("LinkedIn: clicca qui", 70, 75, 400, 20)
    GUICtrlSetColor(-1, 0x0000FF)
    GUICtrlSetFont(-1, 10, 400, 4) ; Sottolineato
    GUICtrlSetOnEvent(-1, "_OpenLinkedIn")

    ; Link GitHub
    Local $idLnk2 = GUICtrlCreateLabel("GitHub: clicca qui", 70, 100, 400, 20)
    GUICtrlSetColor(-1, 0x0000FF)
    GUICtrlSetFont(-1, 10, 400, 4)
    GUICtrlSetOnEvent(-1, "_OpenGitHub")

Func DonateLink()
    ShellExecute("https://ko-fi.com/aurumprestigelabs")
EndFunc

; --- 5. LOGICA CORE ---
Func QuickNote()
    Local $sIn = InputBox($APP_NAME, "Quick Note:", "", "", 400, 130)
    If @error Or $sIn = "" Then Return
    Local $tag = "General", $txt = $sIn
    If StringLeft($sIn, 1) = "/" Then
        Local $sp = StringInStr($sIn, " ")
        If $sp > 0 Then
            $tag = StringTrimLeft(StringLeft($sIn, $sp - 1), 1)
            $txt = StringTrimLeft($sIn, $sp)
        EndIf
    EndIf
    SaveNote($tag, $txt)
EndFunc

Func SaveNote($sTag, $sText, $bScreenshot = False)
    Local $sDate = @YEAR & "-" & @MON & "-" & @MDAY, $sTime = @HOUR & ":" & @MIN
    If $bScreenshot Then
        Local $sImg = "scr_" & @HOUR & @MIN & @SEC & ".jpg"
        _ScreenCapture_Capture($IMG_DIR & "\" & $sImg)
        $sText &= " [IMG: " & $sImg & "]"
    EndIf
    Local $hFile = FileOpen($LOG_DIR & "\notes_" & $sDate & ".txt", 1)
    FileWriteLine($hFile, $sDate & " " & $sTime & "|" & $sTag & "|" & $sText)
    FileClose($hFile)
    If $hMainGui <> 0 Then LoadData()
EndFunc

Func LoadData()
    _GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($idList))
    Local $sSearch = GUICtrlRead($idSearchInput), $sMode = GUICtrlRead($idComboFiltro)
    Local $aFiles = _FileListToArray($LOG_DIR, "*.txt", 1)
    If @error Then Return
    _ArraySort($aFiles, 1, 1)
    For $i = 1 To $aFiles[0]
        Local $hFile = FileOpen($LOG_DIR & "\" & $aFiles[$i], 0)
        While 1
            Local $line = FileReadLine($hFile)
            If @error Then ExitLoop
            Local $aP = StringSplit($line, "|", 2)
            If UBound($aP) < 3 Then ContinueLoop
            If $sSearch <> "" And Not StringInStr($aP[($sMode="Tag"?1:2)], $sSearch) Then ContinueLoop
            Local $img = ""
            If StringInStr($aP[2], "[IMG: ") Then
                Local $res = StringRegExp($aP[2], "\[IMG:\s*(.*?)\]", 1)
                If Not @error Then $img = $IMG_DIR & "\" & $res[0]
            EndIf
            GUICtrlCreateListViewItem($aP[0] & "|" & $aP[1] & "|" & $aP[2] & "|" & $img, $idList)
        WEnd
        FileClose($hFile)
    Next
    UpdateUIState()
EndFunc

Func UpdateFileRecord($idx, $sNewTag, $sNewNote, $bDelete = False)
    Local $sDateOra = _GUICtrlListView_GetItemText($idList, $idx, 0)
    Local $sDataFile = StringLeft($sDateOra, 10), $sTargetFile = $LOG_DIR & "\notes_" & $sDataFile & ".txt"
    Local $sOldLine = $sDateOra & "|" & _GUICtrlListView_GetItemText($idList, $idx, 1) & "|" & _GUICtrlListView_GetItemText($idList, $idx, 2)
    If FileExists($sTargetFile) Then
        Local $sContent = FileRead($sTargetFile)
        If $bDelete Then
            $sContent = StringReplace($sContent, $sOldLine & @CRLF, "")
            $sContent = StringReplace($sContent, $sOldLine, "")
        Else
            $sContent = StringReplace($sContent, $sOldLine, $sDateOra & "|" & $sNewTag & "|" & $sNewNote)
        EndIf
        Local $hFile = FileOpen($sTargetFile, 2)
        FileWrite($hFile, $sContent)
        FileClose($hFile)
        LoadData()
    EndIf
EndFunc

Func ExportCSV()
    Local $sSave = FileSaveDialog("Export CSV", @DesktopDir, "CSV (*.csv)", 18, "glimp_export.csv")
    If @error Then Return
    Local $hFile = FileOpen($sSave, 2), $iCount = _GUICtrlListView_GetItemCount($idList)
    FileWriteLine($hFile, "Data;Tag;Nota;Path")
    For $i = 0 To $iCount - 1
        FileWriteLine($hFile, _GUICtrlListView_GetItemText($idList, $i, 0) & ";" & _GUICtrlListView_GetItemText($idList, $i, 1) & ";" & _GUICtrlListView_GetItemText($idList, $i, 2) & ";" & _GUICtrlListView_GetItemText($idList, $i, 3))
    Next
    FileClose($hFile)
EndFunc

Func ExportMultiTxt()
    Local $sCombined = ""
    For $i = 0 To _GUICtrlListView_GetItemCount($idList) - 1
        If _GUICtrlListView_GetItemChecked($idList, $i) Or _GUICtrlListView_GetItemSelected($idList, $i) Then
            $sCombined &= "DATE: " & _GUICtrlListView_GetItemText($idList, $i, 0) & @CRLF & "TAG: " & _GUICtrlListView_GetItemText($idList, $i, 1) & @CRLF & "NOTE: " & _GUICtrlListView_GetItemText($idList, $i, 2) & @CRLF & "---" & @CRLF
        EndIf
    Next
    If $sCombined <> "" Then FileWrite(FileSaveDialog("Export", @DesktopDir, "Text (*.txt)", 18), $sCombined)
EndFunc

Func ExportAllData()
    Local $sHtml = "<html><head><meta charset='UTF-8'><style>" & _
            "body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #f8f9fa; padding: 30px; margin: 0; }" & _
            "h2 { color: #2c3e50; font-weight: 300; border-bottom: 2px solid #e1e4e8; padding-bottom: 10px; }" & _
            ".filter-container { margin-bottom: 20px; background: #eee; padding: 15px; border-radius: 5px; display: flex; gap: 10px; }" & _
            ".filter-container input { padding: 8px; border: 1px solid #ccc; border-radius: 4px; flex: 1; }" & _
            "table { width: 100%; border-collapse: collapse; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }" & _
            "th { background-color: #212529; color: #ffffff; padding: 12px; text-align: left; font-size: 13px; text-transform: uppercase; }" & _
            "td { padding: 10px 12px; border-bottom: 1px solid #dee2e6; font-size: 14px; }" & _
            ".path { font-family: 'Consolas', monospace; font-size: 11px; color: #6c757d; word-break: break-all; }" & _
            "</style>" & _
            "<script>" & _
            "function filterTable() {" & _
            "  var inputTag = document.getElementById('searchTag').value.toUpperCase();" & _
            "  var inputNote = document.getElementById('searchNote').value.toUpperCase();" & _
            "  var table = document.getElementById('noteTable');" & _
            "  var tr = table.getElementsByTagName('tr');" & _
            "  for (var i = 1; i < tr.length; i++) {" & _
            "    var tdTag = tr[i].getElementsByTagName('td')[1];" & _
            "    var tdNote = tr[i].getElementsByTagName('td')[2];" & _
            "    if (tdTag && tdNote) {" & _
            "      var txtTag = tdTag.textContent || tdTag.innerText;" & _
            "      var txtNote = tdNote.textContent || tdNote.innerText;" & _
            "      if (txtTag.toUpperCase().indexOf(inputTag) > -1 && txtNote.toUpperCase().indexOf(inputNote) > -1) {" & _
            "        tr[i].style.display = '';" & _
            "      } else {" & _
            "        tr[i].style.display = 'none';" & _
            "      }" & _
            "    }" & _
            "  }" & _
            "}" & _
            "</script>" & _
            "</head><body>" & _
            "<h2>Glimp - Notes Export</h2>" & _
            "<div class='filter-container'>" & _
            "  <input type='text' id='searchTag' onkeyup='filterTable()' placeholder='Filter by Tag...'>" & _
            "  <input type='text' id='searchNote' onkeyup='filterTable()' placeholder='Filter in the text of the note...'>" & _
            "</div>" & _
            "<table id='noteTable'>" & _
            "<tr><th>Data Ora</th><th>Tag</th><th>Nota</th><th>Path</th></tr>"

    Local $iCount = _GUICtrlListView_GetItemCount($idList)
    For $i = 0 To $iCount - 1
        Local $sDate = _GUICtrlListView_GetItemText($idList, $i, 0)
        Local $sTag = _GUICtrlListView_GetItemText($idList, $i, 1)
        Local $sNote = _GUICtrlListView_GetItemText($idList, $i, 2)
        Local $sPath = _GUICtrlListView_GetItemText($idList, $i, 3)

        Local $sRowStyle = ""
        Local $sTextColor = "#000000"

        If $TagColors.Exists($sTag) Then
            Local $nCol = $TagColors.Item($sTag)
            Local $nBlue  = BitAND(BitShift($nCol, 16), 0xFF)
            Local $nGreen = BitAND(BitShift($nCol, 8), 0xFF)
            Local $nRed   = BitAND($nCol, 0xFF)
            Local $sHex = "#" & Hex($nRed, 2) & Hex($nGreen, 2) & Hex($nBlue, 2)
            Local $brightness = (($nRed * 299) + ($nGreen * 587) + ($nBlue * 114)) / 1000
            If $brightness < 128 Then $sTextColor = "#ffffff"
            $sRowStyle = " style='background-color: " & $sHex & "; color: " & $sTextColor & ";'"
        EndIf

        $sHtml &= "<tr" & $sRowStyle & ">" & _
                "<td>" & $sDate & "</td>" & _
                "<td><b>" & $sTag & "</b></td>" & _
                "<td>" & $sNote & "</td>" & _
                "<td class='path'>" & $sPath & "</td></tr>"
    Next

    $sHtml &= "</table></body></html>"

    Local $hFile = FileOpen(@ScriptDir & "\Report_Glimp.html", 2 + 128)
    FileWrite($hFile, $sHtml)
    FileClose($hFile)
    ShellExecute(@ScriptDir & "\Report_Glimp.html")
EndFunc

Func UpdateUIState()
    Local $iSel = _GUICtrlListView_GetSelectedCount($idList)
    Local $state = ($iSel > 0) ? $GUI_ENABLE : $GUI_DISABLE
    GUICtrlSetState($idBtnEditTag, $state)
    GUICtrlSetState($idBtnEditNote, $state)
    GUICtrlSetState($idBtnDel, $state)
EndFunc

Func WM_NOTIFY($hWnd, $iMsg, $iwParam, $ilParam)
    Local $tNMHDR = DllStructCreate($tagNMHDR, $ilParam), $hWndFrom = DllStructGetData($tNMHDR, "hWndFrom"), $iCode = DllStructGetData($tNMHDR, "Code")
    If $hWndFrom = GUICtrlGetHandle($idList) Then
        If $iCode = $NM_CUSTOMDRAW Then
            Local $tNMLVCUSTOMDRAW = DllStructCreate($tagNMLVCUSTOMDRAW, $ilParam), $dwDrawStage = DllStructGetData($tNMLVCUSTOMDRAW, "dwDrawStage")
            If $dwDrawStage = $CDDS_PREPAINT Then Return $CDRF_NOTIFYITEMDRAW
            If $dwDrawStage = $CDDS_ITEMPREPAINT Then
                Local $iItem = DllStructGetData($tNMLVCUSTOMDRAW, "dwItemSpec"), $sTag = _GUICtrlListView_GetItemText($idList, $iItem, 1)
                If $TagColors.Exists($sTag) Then DllStructSetData($tNMLVCUSTOMDRAW, "clrTextBk", $TagColors.Item($sTag))
                Return $CDRF_NEWFONT
            EndIf
        ElseIf $iCode = $NM_CLICK Or $iCode = $LVN_ITEMCHANGED Then
            UpdateUIState()
        EndIf
    EndIf
    Return $GUI_RUNDEFMSG
EndFunc

Func CaptureWithNote()
    GUISetState(@SW_HIDE, $hMainGui)
    Sleep(250)
    Local $sIn = InputBox($APP_NAME, "Screenshot comment:", "Screenshot")
    If Not @error Then SaveNote("Screenshot", $sIn, True)
    GUISetState(@SW_SHOW, $hMainGui)
EndFunc

Func EditTag()
    Local $idx = _GUICtrlListView_GetNextItem($idList)
    If $idx <> -1 Then
        Local $new = InputBox("Edit Tag", "New tag:", _GUICtrlListView_GetItemText($idList, $idx, 1))
        If Not @error Then UpdateFileRecord($idx, $new, _GUICtrlListView_GetItemText($idList, $idx, 2))
    EndIf
EndFunc

Func EditNote()
    Local $idx = _GUICtrlListView_GetNextItem($idList)
    If $idx <> -1 Then
        Local $new = InputBox("Edit Note", "New text:", _GUICtrlListView_GetItemText($idList, $idx, 2))
        If Not @error Then UpdateFileRecord($idx, _GUICtrlListView_GetItemText($idList, $idx, 1), $new)
    EndIf
EndFunc

Func DeleteNote()
    Local $idx = _GUICtrlListView_GetNextItem($idList)
    If $idx <> -1 And MsgBox(36, $APP_NAME, $dTxt.Item("DelMsg")) = 6 Then UpdateFileRecord($idx, "", "", True)
EndFunc

Func OpenMedia()
    Local $idx = _GUICtrlListView_GetNextItem($idList)
    If $idx <> -1 Then ShellExecute(_GUICtrlListView_GetItemText($idList, $idx, 3))
EndFunc

Func OpenMediaFolder()
    Local $idx = _GUICtrlListView_GetNextItem($idList)
    If $idx <> -1 Then ShellExecute("explorer.exe", "/select," & _GUICtrlListView_GetItemText($idList, $idx, 3))
EndFunc

Func PickColorPalette()
    Local $idx = _GUICtrlListView_GetNextItem($idList)
    If $idx = -1 Then Return
    Local $sTag = _GUICtrlListView_GetItemText($idList, $idx, 1)
    Local $iCol = _ChooseColor(2, 0, 2, $hMainGui)
    If $iCol <> -1 Then
        Local $iRGB = BitOR(BitAnd($iCol, 0x00FF00), BitShift(BitAnd($iCol, 0x0000FF), -16), BitShift(BitAnd($iCol, 0xFF0000), 16))
        IniWrite($INI_FILE, "colors", $sTag, $iRGB)
        LoadColors()
        _GUICtrlListView_RedrawItems($idList, 0, _GUICtrlListView_GetItemCount($idList) - 1)
    EndIf
EndFunc

Func LoadColors()
    $TagColors.RemoveAll()
    Local $aCol = IniReadSection($INI_FILE, "colors")
    If Not @error Then
        For $i = 1 To $aCol[0][0]
            $TagColors.Item($aCol[$i][0]) = Int($aCol[$i][1])
        Next
    EndIf
EndFunc

Func SelectAllAction()
    Local $b = (GUICtrlRead($idSelectAll) = $GUI_CHECKED)
    For $i = 0 To _GUICtrlListView_GetItemCount($idList) - 1
        _GUICtrlListView_SetItemChecked($idList, $i, $b)
    Next
EndFunc

Func ToggleGUI()
    If $hMainGui <> 0 And BitAnd(WinGetState($hMainGui), 2) Then
        GUISetState(@SW_HIDE, $hMainGui)
    Else
        If $hMainGui = 0 Then ShowGUI()
        GUISetState(@SW_SHOW, $hMainGui)
        WinActivate($hMainGui)
    EndIf
EndFunc

Func TerminateApp()
    Exit
EndFunc

; --- 8. START ---
SetupTray()
HotKeySet("+!n", "QuickNote")
HotKeySet("+!v", "ToggleGUI")

While 1
    Sleep(100)
WEnd

Func _OpenLinkedIn()
    ShellExecute("https://linkedin.com/feed/update/urn:li:activity:7434843833432985600/")
EndFunc

Func _OpenGitHub()
    ShellExecute("https://github.com/luca-deste/Fnote")
EndFunc

Func _OpenMyGitHub()
    ; Sostituisci il link qui sotto quando avrai creato il tuo profilo
    ShellExecute("https://github.com/tuo-username-qui")
EndFunc

Func _CloseAbout()
    ; @GUI_WinHandle restituisce l'handle della finestra che ha generato l'evento
    GUIDelete(@GUI_WinHandle)
EndFunc


