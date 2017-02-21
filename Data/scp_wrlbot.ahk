#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn All, Off    ; #Warn eables warnings to assist with detecting common errors, while "all, off" makes them all disabled
#HotkeyInterval 1000  ; This is  the default value (milliseconds).
#MaxHotkeysPerInterval 200
#MaxThreadsPerHotkey 1
#SingleInstance
#WinActivateForce ; need to test it
#NoTrayIcon
;DetectHiddenWindows, on
SendMode Input
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines, -1
SetWinDelay, -1
SetControlDelay, -1
CoordMode, Mouse, Screen 
; #Include Gdip_all.ahk                               ; IMPORTANT LIBRARY, AVAILABLE HERE > http://www.autohotkey.net/~Rseding91/Gdip%20All/Gdip_All.ahk
#Include Gdip_all_2.ahk                                 
If !pToken := Gdip_Startup()                        
{
   MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
   ExitApp
}

;	screen checker platform
ControlGet, isActive_checker1, Line,1,edit1, CP_WRLBOT
ControlGet, client_HWND1, Line,1,edit2, CP_WRLBOT
ControlGet, check1_x1, Line,1,edit4, CP_WRLBOT
ControlGet, check1_y1, Line,1,edit4, CP_WRLBOT
ControlGet, isActive_checker2, Line,1,edit5, CP_WRLBOT
ControlGet, client_HWND2, Line,1,edit6, CP_WRLBOT
ControlGet, check2_x1, Line,1,edit7, CP_WRLBOT
ControlGet, check2_y1, Line,1,edit8, CP_WRLBOT
ControlGet, bot_HWND, Line,1,edit9, CP_WRLBOT

Gui, +HwndScreenCheckerPlatform +Caption +LastFound +ToolWindow +E0x20 +AlwaysOnTop ; WS_EX_TRANSPARENT 
Gui, Add, Edit, x12 y10 w60 h20 Disabled vScreen_check_result1,s
Gui, Add, Edit, x12 y30 w60 h20 Disabled vScreen_check_result2,s
Gui, Add, Edit, x12 y50 w60 h20 Disabled, %ScreenCheckerPlatform%
; DllCall("SetParent", UInt, WinExist() , UInt, ahk_id ScreenCheckerPlatform)
WinSet, Transparent, 0 ;, ahk_id %ScreenCheckerPlatform%
Gui, Show, w85 h120 NoActivate Center, SCP_WRLBOT
ControlGet, CP_HWND, Line,1,edit10, CP_WRLBOT
sleep, 100
WinSet, Transparent, 0 , ahk_id %ScreenCheckerPlatform%
SetTimer, screen_check, 300
return

screen_check:
	IfWinNotExist, ahk_id %bot_HWND%
		ExitApp
	ControlGet, isActive_checker1, Line,1,edit1, CP_WRLBOT
	if (isActive_checker1){
		ControlGet, client_HWND1, Line,1,edit2, CP_WRLBOT
		bmpHaystack1 := Gdip_BitmapFromHWND(client_HWND1)
		bmparea_check1 := Gdip_CreateBitmapFromFile("Images\area_check1.bmp")
		ControlGet, check1_x1, Line,1,edit4, CP_WRLBOT
		ControlGet, check1_y1, Line,1,edit4, CP_WRLBOT
		RET1 := Gdip_ImageSearch(bmpHaystack1,bmparea_check1, result1, check1_x1, check1_y1, 0, 0,,,8)
		Gdip_DisposeImage(bmpHaystack1)
		Gdip_DisposeImage(bmparea_check1)
		if (RET1 != 1)
			a := 0
		else
			a := 1
		WinGet, win_status, MinMax, ahk_id %client_HWND1%
		if (win_status = "") or (win_status = -1)
			a := "NA"
		IfWinNotExist, ahk_id %client_HWND1%
			a := "NE"
	}
	else
		a := "x"
	
	ControlGet, isActive_checker2, Line,1,edit5, CP_WRLBOT
	if (isActive_checker2){
		ControlGet, client_HWND2, Line,1,edit6, CP_WRLBOT
		bmpHaystack2 := Gdip_BitmapFromHWND(client_HWND2)
		bmparea_check2 := Gdip_CreateBitmapFromFile("Images\area_check2.bmp")
		ControlGet, check2_x1, Line,1,edit7, CP_WRLBOT
		ControlGet, check2_y1, Line,1,edit8, CP_WRLBOT
		RET2 := Gdip_ImageSearch(bmpHaystack2,bmparea_check2, result2, check2_x1, check2_y1, 0, 0,,,8)
		Gdip_DisposeImage(bmpHaystack2)
		Gdip_DisposeImage(bmparea_check2)
		if (RET2 != 1)
			b := 0
		else
			b := 1
		WinGet, win_status, MinMax, ahk_id %client_HWND2%
		if (win_status = "") or (win_status = -1)
			b := "NA"
		IfWinNotExist, ahk_id %client_HWND2%
			b := "NE"
	}
	else
		b := "x"
	guicontrol,,Screen_check_result1, %a%
	guicontrol,,Screen_check_result2, %b%
return

GuiClose:
ExitApp

