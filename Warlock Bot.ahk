#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn All, Off    ; #Warn eables warnings to assist with detecting common errors, while "all, off" makes them all disabled
#HotkeyInterval 1000  ; This is  the default value (milliseconds).
#MaxHotkeysPerInterval 200
#MaxThreadsPerHotkey 1
#SingleInstance
#WinActivateForce ; need to test it
; #NoTrayIcon
DetectHiddenWindows, Off
SendMode Input
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines, -1
SetWinDelay, -1
SetControlDelay, -1
CoordMode, Mouse, Screen
#Include Gdip_all_2.ahk 

If !pToken := Gdip_Startup()                        
{
   MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
   ExitApp
}

global version := "0.9.6 - beta"
IniWrite, %version%, Data/basic_settings.ini, authentication data, version


GOTO_STARTBOT := 0
GOTO_INIT := 0

; created by Mate @tibiapf.com

; official website: www.wrlbot.tk
; project thread: https://tibiapf.com/showthread.php?71-all-versions-Warlock-Bot
; see also: https://tibiapf.com/showthread.php?35-all-versions-Hunter-Bot
; github site: https://github.com/Brazyliszek/Warlock-bot

;################## todos ##################

; po zrobieniu fisha lub fishing roda img w fishing gui 
;zoptymalizowac fishing
;poprawic scp, tam gdzie szuka x1,y1,0,0
; optymalizacja dll i sleepów
; nie wiem czy dzialaja linki
; zmienic hide_client_1 na hide client 1
; zoptymalizowac scp, niepotrzebnie non stop zbiera to samo hwnd, niepotrzebnie caly czas robi bitmapy. Mozna po prostu dodac jakas zmienna iterujaca++ przy kazdej zmianie bmp lub hwnd  do controla i on by tylko to zczytywal i w razie w robil jakis gosub get bmp/hwnd

; add character moved as alarm type
; double alarm effect doesnt work under allc onditiosn



; MAIN RULES USING THIS SCRIPT AND FEW TIPS:
; 1) Bot depends on time instead of mana amount to create runes
; 2) Your main backpack must be different than backpacks in which will you store blank and conjured runes (if you're using hand-mode)
; 3) Your hand slot must be empty, otherwise object you had in hand may be moved to backpack and you can lose it in case of death (if you're using hand-mode)
; 4) You must take screenshot of a free slot using our tool to take ingame images (if you're using hand-mode)
; 5) ImageSearch searches for images from topleft to bottomright side of desired area. Keep that in mind.
; 6) If constantly bot returns "couldn't find free slot on inventory" try to take another image, dont really need to be fully in center.



; latest ver. changelog
;
;   0.9.6
;       added tooltips on each control
;       added possibility to hide/show game window
;       improved tray menu items
;       implemented screen checker platform (scp_wrlbot.exe), that is providing pseudo-multitasking
;       added separated timers for all bot functions for both clients
;       improved pause function
;       added flash client as alarm type
;       added image search by hwnd
;       added mouse control by ext. DLL
;       added fishing feature
;       added default buttons for inital windows
;
;
;   0.9.5.1 & 2
;       fixed anty_logout() on medivia
;       added auto 'sendmode = event' if medivia
;
;   0.9.5
;       reorganized file managment
;       added online bot version confirmation
;       added way more efficient double alarm effect
;       repaired bug if window title has changed after initialization
;       changed spell cast method to send hotkey input instead of string
;       added configuration of such things as: food/anty idle time, anty log direction, distance to walk in case of alarm, hotkey to eat food, if you want notification to be shown or not
;       added auto-shutdown on specific hour
;       added alarm if gm on battle, if lack of soul points
;       repaired bug with screen check false alarm while minimizing or maximizing game window
;
;   0.9.4
;       repaired bug with spellcaster if no blank
;       minor changes to runemake() algorithm
;       added ver 32 and 64 bit
;
;   0.9.3
;       repaired bug with crash if last used client directory has changed
;       now you can change in ini files values of randomization (1-15~), food and antylog time (ms), to show or not notifications (bool), and blank rune spell (string)
;       changed action order in case of alarm execution (now is: logout>walk>sound>shutdown)
;       repaired bug with shutdown/walk alarm type, now you can do both in the same time (in specified oreder)
;       repaired bug with food/anty log delay (it should eat once every 150sec not every each cicle)
;       minor changes to pause(), still not tested
;
;   0.9.2
;       solved problems with not loading previously saved settings
;       removed tests hotkeys f1 and f2 from public bot version
;       changed auth gui to make password and account name unchangable
;   
;   0.9.1   
;       added inital msgbox, informing about version and where to report bugs

 ; ######################################################### VARIABLES ##############################################################################
global refresh_time := 200      ; screen checker frequency
global MainBotWindow
global fishing_time := 1500
global fishing1_stack := []
global fishing1_spot := []
global fishing2_stack := []
global fishing2_spot := []
global transparent_tibia1 := 0
global transparent_tibia2 := 0
global WalkMethod_IfFood 
global WalkMethod_IfBlank 
global WalkMethod_IfPlayer 
global WalkMethod_IfSoul 
global client_screen_checker 
global img_filename
global sc_temp_img_dir1 = "Data\Images\select_area1.png"
global sc_temp_img_dir2 = "Data\Images\select_area2.png"
global execution_allowed := 1
global rune_spellkey1 
global spelltime1 
global rune_spellkey2 
global spelltime2 
global blank_spellname
global hand_slot_pos_x
global hand_slot_pos_y
global house_pos_x      ; to dele soon
global house_pos_y           ; to dele soon
global house_pos_x1
global house_pos_y1
global house_pos_x2
global house_pos_y2
global title_tibia1
global title_tibia2
global pid_tibia1
global pid_tibia2
global Bot_protection = 0
global current_time1 := 0       ; prev. was a_tickcount, not sure if will work
global deviation1 := 0
global planned_time1
global current_time2 := 0       ; prev. was a_tickcount, not sure if will work
global deviation2 := 0
global planned_time2
global randomization := 5          ; level of randomness in functions 
global steps_to_walk          ; how many sqm bot has to go incase of alarm
global show_notifications     ; if you want notification to be displayed set 1, else 0
global food_time         ; bot doesnt eat each cicle but rather checks if last eating wasn't earlier than current time - food_time (ms)
global anty_log_time      ; same as above, but relate of anty_log function
global eat_using_hotkey
global eat_hotkey 
global check_x1
global check_y1
global check_x2
global check_y2
global hwnd1
global hwnd2
global area_start_x1
global area_start_y1
global area_start_x2
global area_start_y2
global bmparea_check1
global bmparea_check2
global rm1 := 0
global al1 := 0
global fe1 := 0
global fi1 := 0
global a1 := 0
global paused := 0
global rm2 := 0
global al2 := 0
global fe2 := 0
global fi2 := 0
global a2 := 0
coord_var = 0
tab_window_size_x = 465 
tab_window_size_y = 260 
pic_window_size_x = % tab_window_size_x+40
pic_window_size_y = % tab_window_size_y+40
global BOTnameTR := "Warlock"
global BOTName := "Warlock Bot"
global Fishing_gui1_title := "Fishing setup - client 1"
global Fishing_gui2_title := "Fishing setup - client 2"
If WinExist("WarlockBot"){
	MsgBox, 16, Error, There is other Warlock bot already running. Application will close now.                   ; prevent from running bot multiple times. may interact in unexpected way, prevention move
	ExitApp
}

checkfiles:
IncludeImages := "area_check1.bmp|area_check2.bmp|background.png|backpack1.bmp|backpack2.bmp|blank_rune.bmp|conjured_rune1.bmp|conjured_rune2.bmp|food1.bmp|food2.bmp|free_slot.bmp|picbp.bmp|select_area1.png|select_area2.png|tabledone.png|table_main_f.png|icon.ico|msinfo32.ico|warlockbot_startwin.png|pp_donate.bmp|soul0.bmp|soul1.bmp|soul2.bmp|soul3.bmp|soul4.bmp|soul5.bmp|fishing_rod_bp.bmp|fishing_rod.bmp|fish.bmp"
Loop, Parse, IncludeImages, |
{
   If (!FileExist("Data\Images\" A_LoopField))
   {
   MsgBox, 262193, Something is wrong..., There is lack in files. Couldn't find some images. Do you want to restore them?
   IfMsgBox Ok
      goto Installfiles
   else
      ExitApp
   }
}
IncludeFiles := "alarm_food.mp3|alarm_screen.mp3|alarm_blank.mp3|alarm_soul.mp3"
Loop, Parse, IncludeFiles, |
{
   If (!FileExist("Data\Sounds\" A_LoopField))
   {
   MsgBox, 262193, Something is wrong..., There is lack in files. Couldn't find some sounds. Do you want to restore them?
   IfMsgBox Ok
      goto Installfiles
   else
      ExitApp
   }
}

IncludeFiles := "basic_settings.ini|mousehook64.dll|scp_wrlbot.exe"
Loop, Parse, IncludeFiles, |
{
   If (!FileExist("Data\" A_LoopField))
   {
   MsgBox, 262193, Something is wrong..., There is lack in files. Couldn't find some files. Do you want to restore them?
   IfMsgBox Ok
      goto Installfiles
   else
      ExitApp
   }
}

if GOTO_STARTBOT 
   goto, start_bot       ; <<----------------------------------------------------------------------------------- temprarly, for tests purpose
if GOTO_INIT
   goto, start_initialization



MsgBox, 262208, Important, Hi! `nPlease keep in mind this is version %version%`, which means it still has some bugs and not all function may work properly. Please report all bugs, false alerts, crashes on forum tibiapf.com with every important details in valid thread or directly on official webiste wrlbot.tk. `n`nThanks for using my software`, hope you like it. `nMate/Brazyliszek
; ######################################################### AUTHENTICATION #########################################################################

pass_authentication:
Gui, New, +Caption
IniRead, last_used_login, Data/basic_settings.ini, authentication data, last_used_login
IniRead, last_used_pass, Data/basic_settings.ini, authentication data, last_used_pass
IniRead, version, Data/basic_settings.ini, authentication data, version
last_used_login := "demo"
last_used_pass := "demo"
Gui, Add,edit,x5 y26 w80 h17 vuser, %last_used_login%
Gui, Add,edit,x5 y60 w80 h17 password vpass, %last_used_pass%
Gui, Add,button,x5 y80 h20 w55 gLogin center +BackgroundTrans Default , Login
Gui, Add,button,x65 y80 h20 w20 gHelp_button center, ?
Gui, Add, Pic, x0 y0 0x4000000, %A_WorkingDir%\Data\Images\warlockbot_startwin.png
Gui, font, bold s8
Gui, Add, Text, x95 y130 w300 vauth_text_box cWhite +BackgroundTrans, Enter your license account data.
Gui, Show, w287 h149,Authentication
GuiControl, Disable, pass
GuiControl, Disable, user
start_value := 1
return

Help_button:
MsgBox, 0, Help, Version: %version%`nStandard password for beta version is demo/demo. If any other problems occured contact me using data below.`n`nSupport: via privmassage on forum tibiapf.com @Mate`nThrough contact page on official site: http://wrlbot.tk/contact`n`n`ngithub site: https://github.com/Brazyliszek/Warlock-bot`nproject thread: https://tibiapf.com/showthread.php?71-all-versions-Warlock-Bot`nsee also: https://tibiapf.com/showthread.php?35-all-versions-Hunter-Bot
return

Login:
if start_value = 2
   goto check_version
Gui, Font, c00ABFF
Guicontrol, move, auth_text_box, x200 y130
GuiControl, font, auth_text_box
GuiControl, text, auth_text_box, connecting...
If (start_value = 1){
   start_value := 0
   user_name := "demo"
   user_pass := "demo"
   sleep 500
   GuiControlGet, user,, user
   GuiControlGet, pass,, pass
   IniWrite, %user%, Data/basic_settings.ini, authentication data, last_used_login
   IniWrite, %pass%, Data/basic_settings.ini, authentication data, last_used_pass
   If (user != user_name) or (pass != user_pass){
      Guicontrol, move, auth_text_box, x100 y130
      Gui, Font, cRed
      GuiControl, font, auth_text_box
      GuiControl, text, auth_text_box, Wrong login name or password.
      start_value := 1
      return
      }
   else{
      Guicontrol, move, auth_text_box, x170 y130
      Gui, Font, c00FF11
      GuiControl, font, auth_text_box
      GuiControl, text, auth_text_box, Account confirmed!
      sleep, 1000
      goto, check_version
      }
   }
else{
   sleep 1000
   Guicontrol, move, auth_text_box, x95 y130
   Gui, Font, cRed
   GuiControl, font, auth_text_box
   GuiControl, text, auth_text_box, Check your internet connection.
   start_value := 1
   return
}
start_value := 1
return

check_version:
start_value := 2
Gui, Font, c00ABFF
Guicontrol, move, auth_text_box, x170 y130
GuiControl, font, auth_text_box
GuiControl, text, auth_text_box, Version checking...
sleep 800
If (ConnectedToInternet() and start_value = 2){
   ComObjError(false)
   whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
   whr.Open("GET", "http://wrlbot.000webhostapp.com/version.txt", true)
   whr.Send()
   whr.WaitForResponse()
   version_current := whr.ResponseText
   if ((StrLen(version_current) < 5) or (StrLen(version_current) > 15) or (version_current == "")){
      Guicontrol, move, auth_text_box, x15 y130
      Gui, Font, cRed
      GuiControl, font, auth_text_box
      GuiControl, text, auth_text_box, There was problem with obtaining version info.
      sleep, 2500
      Gui, Destroy
      start_value := 2
      goto, start_initialization
      return
    }  
   IniRead, version, Data/basic_settings.ini, authentication data, version
   If (version != version_current){
      Guicontrol, move, auth_text_box, x50 y130 w300
      Gui, Font, cRed
      GuiControl, font, auth_text_box
      GuiControl, text, auth_text_box, Warlock bot outdated. Please update it.
      sleep, 500
      Msgbox,,Warlock bot,You are using old version. There is a newer one available to download. Update your bot if you want to have bugs repaired and new features built in it.
      sleep, 1000
      Gui, Destroy
      start_value := 2
      goto, start_initialization
      return
      }
   else{
      Guicontrol, move, auth_text_box, x150 y130
      Gui, Font, c00FF11
      GuiControl, font, auth_text_box
      GuiControl, text, auth_text_box, Bot version confirmed!
      sleep, 1500
      Gui, Destroy
      start_value := 2
      goto, start_initialization
      return
      }
   }
else{
   Guicontrol, move, auth_text_box, x98 y130
   Gui, Font, cRed
   GuiControl, font, auth_text_box
   GuiControl, text, auth_text_box, Check your internet connection.
   Gui, Destroy
   goto, start_initialization
   start_value := 2
   return
}
start_value := 2
return



; ######################################################### INITIALIZATION  AND GUI ################################################################
start_initialization:
sleep, 500            ; auth gui destroy somehow minimized initial window if it was open too fast
Gui, New, +Caption
IniRead, last_used_client_dir, Data/basic_settings.ini, initialization data, last_used_client_dir
IniRead, last_used_mc_count, Data/basic_settings.ini, initialization data, last_used_mc_count
IniRead, Bot_protection, Data/basic_settings.ini, initialization data, Bot_protection
Gui, Add, Text, x5 y15 +BackgroundTrans, Client location:
Gui, Add, Text, x5 y40 +BackgroundTrans, How many mc?
Gui, Add, edit, x85 y15 w140 h17 vedit_client_dir +ReadOnly, %last_used_client_dir%
Gui, Add, DropDownList, x85 y35 w30 Choose%last_used_mc_count% vmc_count, 1|2
Gui, Add, button, x233 y15 h18 gselect_file,Browse
Gui, Add, button, x187 y128 h20 w50 gCheck_initial_settings Default ,Start
Gui, Add, button, x237 y128 h20 w50 gHelp_initial_button, Help
Gui, Add, Text, x5 y65 +BackgroundTrans, On some servers with good bot protecion functions like`nmove() or use() might not work properly. If you experienced`nsuch issues click on this checkbox to enable mouse`nsimulation on lower level. 
Gui, Add, Checkbox, x5 y128 gBot_protection vBot_protection checked%Bot_protection%,SendMode = Event
Gui, Show, w287 h149, Initial setup
return

select_file:
FileSelectFile, client_dir, 3, , Select tibia client, executable files  (*.exe)
if client_dir =           
    return
else
	GuiControl,,edit_client_dir,%client_dir%
return

Help_initial_button:
MsgBox, 0, Help, First you have to do is to enter valid game client location. Is neccesery for bot to obtain its unique process id.`nSecondly you got to choose on how many clients will you operate. You can use Warlock Bot on up to two clients.`nAnd the last thing - select SendMode Event - only if bot returns errors like "There was problem with function use()" or for example bot has problems with eating food or moving items in inventory. It means that server owners made their client bot unfriendly. It will slow the bot a little bit and make mouse movements visible.
return

Check_initial_settings:
GuiControlGet, edit_client_dir,,edit_client_dir
GuiControlGet, mc_count,,mc_count
GuiControlGet, Bot_protection,,Bot_protection
IniWrite, %edit_client_dir%, Data/basic_settings.ini, initialization data, last_used_client_dir
IniWrite, %mc_count%, Data/basic_settings.ini, initialization data, last_used_mc_count
IniWrite, %Bot_protection%, Data/basic_settings.ini, initialization data, Bot_protection
IfNotInString, edit_client_dir, exe 
   {   
   TrayTip, %BOTName%, You should enter valid tibia clients file path (*.exe).
   SetTimer, RemoveTrayTip, 3500
   return
}
IfInString, edit_client_dir, medivia
   {   
   GuiControlGet, Bot_protection,,Bot_protection
   if (Bot_protection = 0 and temp_var_bp != 1){
      MsgBox, 64, Highly edited otclient detected!, It is recommended to have 'SendMode = Event' enabled.
      GuiControl,,Bot_protection,1
      temp_var_bp := 1
      return
   }
}
IfNotExist, %edit_client_dir%
   {
   TrayTip, %BOTName%, Couldn't find client in given directory.
   SetTimer, RemoveTrayTip, 3500
   return
}
If (mc_count = "" ){
   TrayTip, %BOTName%, You should enter tibia multiclient count to run.
   SetTimer, RemoveTrayTip, 3500      
   return
}   
else{      
   Gui, Destroy
   goto, run_clients
   sleep, 500
}
return


run_clients:
   SplitPath, edit_client_dir, client_name, client_only_dir        
   run, %client_name%, %client_only_dir%, min, pid_tibia1           ; Use ahk_pid to identify a window belonging to a specific process. The process identifier (PID) is typically retrieved by WinGet, Run or Process.
   title_tibia1 := "Game client 1 - identyfied by " pid_tibia1
   WinActivate, ahk_pid %pid_tibia1%
   WinWait, ahk_pid %pid_tibia1% 
   WinSetTitle, ahk_pid %pid_tibia1%,, %title_tibia1%
   sleep, 500
   WinGet, hwnd1, ID, %title_tibia1%
   Dwm_SetWindowAttributeTransistionDisable(hwnd1, 1)                            ; to disable windows animation while minimizing/maximizing
   ;    WinMinimize, %title_tibia1%
   sleep, 500
   if (mc_count = 2){
      run, %client_name%, %client_only_dir%, min, pid_tibia2
      title_tibia2 := "Game client 2 - identyfied by " pid_tibia2
      WinActivate, ahk_pid %pid_tibia2%
      WinWait, ahk_pid %pid_tibia2% 
      WinSetTitle, ahk_pid %pid_tibia2%,, %title_tibia2%
      sleep, 50
      WinGet, hwnd2, ID, %title_tibia2%
      Dwm_SetWindowAttributeTransistionDisable(hwnd2, 1)                 
      ; WinMinimize, %title_tibia2%
      sleep, 500
   }
   sleep 500
   if (mc_count = 1 and WinExist(title_tibia1)) or (mc_count = 2 and WinExist(title_tibia1) and WinExist(title_tibia2)){
      goto, start_bot
   }
   else{
      msgbox,,Error 1098,Tibia clients couldn't be open. The most common reason is that the client doesn't have built in mc. Bot will close now.
      ExitApp
}
return

start_bot:
;Gui, New
Gui, +HwndMainBotWindow
Gui, Add, Tab3, vTab2 x32 y55 w280 h216, Client 1|Client 2

Gui, Tab, 1
Gui, Add, GroupBox, x42 y85 w138 h70, Runemaker
Gui, Add, Text, x50 y106 w70 h20 , Hotkey to use:
Gui, Add, Hotkey, x128 y102 w40 h20 Center vRune_spellkey1, %rune_spellkey1%
Gui, Add, Text, x50 y127 w70 h20 , Conjuring time:
Gui, Add, Edit, x128 y124 w40 h20 Limit4 Number r1 gCheck_spelltime1 vSpelltime1, %spelltime1%

Gui, Add, GroupBox, x42 y160 w138 h48, Fishing
Gui, Add, Button, x52 y178 w120 h20 gFishing_setup1 vFishing_setup1, setup for client 1

Gui, Add, GroupBox, x190 y85 w110 h123, Screen checker
Gui, Add, Picture, x203 y105 gArea_screen_checker1 vImage_screen_checker1, %sc_temp_img_dir1%
Gui, Add, CheckBox, x204 y184 w80 h20 gEnabled_screen_checker1 vEnabled_screen_checker1, enabled

Gui, Add, GroupBox, x42 y213 w257 h47 , Throw conjured runes?
Gui, Add, Button, x52 y232 w50 h20 ggetpos_house_1 vgetpos_house_1, get pos
Gui, Add, Edit, x110 y232 w40 h20 +Disabled +center vhouse_pos_x1, %house_pos_x1%
Gui, Add, Edit, x151 y232 w40 h20 +Disabled +center vhouse_pos_y1, %house_pos_y1%
Gui, Add, CheckBox, x200 y232 w90 h20 vdeposit_runes_1, throw runes
Rune_spellkey1_TT := "Set key you want to be pressed while runemake"
Spelltime1_TT := "How much time it take to conjure one rune"
Fishing_setup1_TT := "Configure your fishing setup"
Image_screen_checker1_TT := "Click the box to set part of screen to be checked for change,`nfor example: battle list, hp bar, minimap, vip list"
Enabled_screen_checker1_TT := "Enable screen checker function for game client 1"
getpos_house_1_TT := "Obtain position on screen where to throw conjured runes - house, ground etc."
house_pos_x1_TT := "Obtain position on screen where to throw conjured runes - house, ground etc."
house_pos_y1_TT := "Obtain position on screen where to throw conjured runes - house, ground etc."
deposit_runes_1_TT := "Throw conjured runes on this exact position"



Gui, Tab, 2
Gui, Add, GroupBox, x42 y85 w138 h70, Runemaker
Gui, Add, Text, x50 y106 w70 h20 , Hotkey to use:
Gui, Add, Hotkey, x128 y102 w40 h20 Center vRune_spellkey2, %rune_spellkey2%
Gui, Add, Text, x50 y127 w70 h20 , Conjuring time:
Gui, Add, Edit, x128 y124 w40 h20 Limit4 Number r1 gCheck_spelltime2 vSpelltime2, %spelltime2%

Gui, Add, GroupBox, x42 y160 w138 h48 +Disabled, Fishing
Gui, Add, Button, x52 y178 w120 h20 vFishing_setup2 gFishing_setup2 vFishing_setup2, setup for client 2

Gui, Add, GroupBox, x190 y85 w110 h123, Screen checker
Gui, Add, Picture, x203 y105 gArea_screen_checker2 vImage_screen_checker2, %sc_temp_img_dir2%
Gui, Add, CheckBox, x204 y184 w80 h20 gEnabled_screen_checker2 vEnabled_screen_checker2 , enabled

Gui, Add, GroupBox, x42 y213 w257 h47 , Throw conjured runes?
Gui, Add, Button, x52 y232 w50 h20 vgetpos_house_2 ggetpos_house_2 vgetpos_house_2, get pos
Gui, Add, Edit, x110 y232 w40 h20 +Disabled +center vhouse_pos_x2, %house_pos_x2%
Gui, Add, Edit, x151 y232 w40 h20 +Disabled +center vhouse_pos_y2, %house_pos_y2%
Gui, Add, CheckBox, x200 y232 w90 h20 vdeposit_runes_2, throw runes

Rune_spellkey2_TT := "Set key you want to be pressed while runemake"
Spelltime2_TT := "How much time it take to conjure one rune"
Fishing_setup2_TT := "Configure your fishing setup"
Image_screen_checker2_TT := "Click the box to set part of screen to be checked for change,`nfor example: battle list, hp bar, minimap, vip list"
Enabled_screen_checker2_TT := "Enable screen checker function for game client 2"
getpos_house_2_TT := "Obtain position on screen where to throw conjured runes - house, ground etc."
house_pos_x2_TT := "Obtain position on screen where to throw conjured runes - house, ground etc."
house_pos_y2_TT := "Obtain position on screen where to throw conjured runes - house, ground etc."
deposit_runes_2_TT := "Throw conjured runes on this exact position"



Gui, Add, Tab2, +Theme vTab1 gTab1 x20 y20 w%tab_window_size_x% h%tab_window_size_y%,Main|Alarms|Settings|Advanced
; Gui, Add, Text, x130 y55 w190 h20 ; to white gray bar right to tab control
Gui, Color, White
Gui, Tab, 1
Gui, Add, Pic, x322 y65, Data/Images/table_main_f.png
Gui, Add, GroupBox, x322 y50 w150 h165, Main functions

Gui, Font, bold cGray
Gui, Add, Text, x352 y71, client:
Gui, Add, Text, x410 y71, 1
Gui, Add, Text, x449 y71, 2
Gui, Font
Gui, Add, Text, x333 y94 w58 -Right , runemaking
Gui, Add, Text, x333 y119 w58 -Right , anty logout
Gui, Add, Text, x333 y144 w58 -Right ,  food eater
Gui, Add, Text, x333 y169 w58 -Right ,  fishing
Gui, Add, Text, x333 y194 w58 -Right ,  alarms

Gui, Add, CheckBox, x407 y91 w20 h20 vEnabled_runemaking1 gEnabled_runemaking1
Gui, Add, CheckBox, x407 y116 w20 h20 vEnabled_anty_logout1 gEnabled_anty_logout1
Gui, Add, CheckBox, x407 y141 w20 h20 vEnabled_food_eater1 gEnabled_food_eater1
Gui, Add, CheckBox, x407 y165 w20 h20 gFishing_enabled1 vFishing_enabled1,
Gui, Add, CheckBox, x407 y191 w20 h20 vAlarms_enabled1

Gui, Add, CheckBox, x446 y91 w20 h20 vEnabled_runemaking2 gEnabled_runemaking2
Gui, Add, CheckBox, x446 y116 w20 h20 vEnabled_anty_logout2 gEnabled_anty_logout2
Gui, Add, CheckBox, x446 y141 w20 h20 vEnabled_food_eater2 gEnabled_food_eater2
Gui, Add, CheckBox, x446 y165 w20 h20 gFishing_enabled2 vFishing_enabled2,
Gui, Add, CheckBox, x446 y191 w20 h20 vAlarms_enabled2

Gui, Add, GroupBox, x322 y219 w150 h49, Show/hide
Gui, Add, Button, x335 y238 w60 h20 vToggle_hide1 gToggle_hide1, client 1
Gui, Add, Button, x400 y238 w60 h20 vToggle_hide2 gToggle_hide2, client 2

Enabled_runemaking1_TT := "Make sure you configured all the neccesary shit`n - hand slot position, spell time, took proper images etc"
Enabled_anty_logout1_TT := "It will change your character direction as specified in advanced settings"
Enabled_food_eater1_TT := "It will eat food you took image of in settings`n or set hotkey in advanced settings for tibia 7.8 and newer"
Fishing_enabled1_TT := "Enable the fisher, wish you succesful fishing"
Alarms_enabled1_TT := "Alarms need to be enabled in order to be alarmed"
Toggle_hide1_TT := "Use this button to minimize or activate your game client"

Enabled_runemaking2_TT := "Make sure you configured all the neccesary shit`n - hand slot position, spell time, took proper images etc"
Enabled_anty_logout2_TT := "It will change your character direction as specified in advanced settings"
Enabled_food_eater2_TT := "It will eat food you took image of in settings`n or set hotkey in advanced settings for tibia 7.8 and newer"
Fishing_enabled2_TT := "Enable the fisher, wish you succesful fishing"
Alarms_enabled2_TT := "Alarms need to be enabled in order to be alarmed"
Toggle_hide2_TT := "Use this button to minimize or activate your game client"


Gui, Tab, 2
Gui, Add, Pic, x33 y57, Data/Images/tabledone.png
Gui, Add, GroupBox, x32 y50 w439 h217 , Alarms setup
Gui, Add, Text, x38 y106 w80 h20 +Right vifnofood +0x0100, if no food
Gui, Add, Text, x38 y139 w80 h20 +Right vifnoblank +0x0100, if no blank runes
Gui, Add, Text, x38 y174 w80 h20 +Right vifscreen +0x0100, if screen change
Gui, Add, Text, x38 y207 w80 h20 +Right vifnosoul +0x0100, if no soul                 ; 8<<<
Gui, Add, Text, x38 y240 w80 h20 +Right vifmoved +0x0100, if char moved                ; 8<<<

Gui, Add, Text, x129 y62 w40 h30 +Center valarmPause +0x0100, pause`nbot
Gui, Add, Text, x176 y69 w40 h20 +Center valarmLogout +0x0100, logout
Gui, Add, Text, x223 y62 w40 h30 +Center valamrSound +0x0100, play sound
Gui, Add, Text, x268 y62 w46 h30 +Center valarmShutdown +0x0100, shut pc`ndown
Gui, Add, Text, x324 y69 w40 h20 +Center valarmWalk +0x0100, walk
Gui, Add, Text, x380 y62 w40 h30 +Center valarmSpell +0x0100, cast`nspell
Gui, Add, Text, x427 y62 w40 h30 +Center valarmFlash +0x0100, flash`nclient

ifnofood_TT := "Alarm executed when bot couldn't find food"
ifnoblank_TT := "Alarm executed when bot couldn't find blank rune`nwhile using hand-mode setting"
ifscreen_TT := "Decide how the bot should act`nwhen part of screen has changed"
ifnosoul_TT := "Bot will check each runemake cicle if`nyou still have soul points"
ifmoved_TT := "Function currently disabled.`nWill be released in upcoming updates."

alarmPause_TT := "It will result in pause all bot functions`nas rune making, food eating and anty-`nlogout for the specified client"
alarmLogout_TT := "Instant character logout (you can set 'double alarm effect'`nin settings in order to all characters to logout)"
alamrSound_TT := "Short sound alarm repeated loudly few times"
alarmShutdown_TT := "Force your PC to shut down"
alarmWalk_TT := "It will make you character walk few sqms in desired direction.`nAmount of steps configurable in advanced settings.`nYou can also set 'double alarm effect' in order to make both`n   of your characters move simultaneously"
alarmSpell_TT := "Good function to use if you are out of blank runes or souls. Configurable in settings. "
alarmFlash_TT := "It will instantly activate the client"

Gui, Add, CheckBox, x141 y103 w20 h20 vPauseRunemaking_IfFood gPauseRunemaking_IfFood, 
Gui, Add, CheckBox, x189 y103 w20 h20 vLogout_IfFood gLogout_IfFood, 
Gui, Add, CheckBox, x236 y103 w20 h20 vPlaySound_IfFood gPlaySound_IfFood, 
Gui, Add, CheckBox, x285 y103 w20 h20 vShutDown_IfFood gShutDown_IfFood,
Gui, Add, CheckBox, x394 y103 w20 h20 vCastSpell_IfFood,
Gui, Add, CheckBox, x440 y103 w20 h20 vFlash_IfFood,
GuiControl, Disable, CastSpell_IfFood

Gui, Add, CheckBox, x141 y136 w20 h20 vPauseRunemaking_IfBlank gPauseRunemaking_IfBlank, 
Gui, Add, CheckBox, x189 y136 w20 h20 vLogout_IfBlank gLogout_IfBlank,
Gui, Add, CheckBox, x236 y136 w20 h20 vPlaySound_IfBlank gPlaySound_IfBlank,
Gui, Add, CheckBox, x285 y136 w20 h20 vShutDown_IfBlank gShutDown_IfBlank,
Gui, Add, CheckBox, x394 y136 w20 h20 vCastSpell_IfBlank gCastSpell_IfBlank,
Gui, Add, CheckBox, x440 y136 w20 h20 vFlash_IfBlank,

Gui, Add, CheckBox, x141 y170 w20 h20 vPauseRunemaking_IfPlayer gPauseRunemaking_IfPlayer,
Gui, Add, CheckBox, x189 y170 w20 h20 vLogout_IfPlayer gLogout_IfPlayer,
Gui, Add, CheckBox, x236 y170 w20 h20 vPlaySound_IfPlayer gPlaySound_IfPlayer,
Gui, Add, CheckBox, x285 y170 w20 h20 vShutDown_IfPlayer gShutDown_IfPlayer,
Gui, Add, CheckBox, x394 y170 w20 h20 vCastSpell_IfPlayer,
Gui, Add, CheckBox, x440 y170 w20 h20 vFlash_IfPlayer,
GuiControl, Disable, CastSpell_IfPlayer

Gui, Add, CheckBox, x141 y203 w20 h20 vPauseRunemaking_IfSoul gPauseRunemaking_IfSoul,
Gui, Add, CheckBox, x189 y203 w20 h20 vLogout_IfSoul gLogout_IfSoul,
Gui, Add, CheckBox, x236 y203 w20 h20 vPlaySound_IfSoul gPlaySound_IfSoul,
Gui, Add, CheckBox, x285 y203 w20 h20 vShutDown_IfSoul gShutDown_IfSoul,
Gui, Add, CheckBox, x394 y203 w20 h20 vCastSpell_IfSoul gCastSpell_IfSoul,
Gui, Add, CheckBox, x440 y203 w20 h20 vFlash_IfSoul,

Gui, Add, CheckBox, x141 y238 w20 h20 +Disabled vPauseRunemaking_IfCharMoved ;gPauseRunemaking_IfCharMoved,
Gui, Add, CheckBox, x189 y238 w20 h20 +Disabled vLogout_IfCharMoved ;gLogout_IfCharMoved,
Gui, Add, CheckBox, x236 y238 w20 h20 +Disabled vPlaySound_IfCharMoved ;gPlaySound_IfCharMoved,
Gui, Add, CheckBox, x285 y238 w20 h20 +Disabled vShutDown_IfCharMoved ;gShutDown_IfCharMoved,
Gui, Add, CheckBox, x394 y238 w20 h20 +Disabled vCastSpell_IfCharMoved ;gCastSpell_IfCharMoved,
Gui, Add, CheckBox, x440 y238 w20 h20 +Disabled vFlash_IfCharMoved,



Gui, Add, DropDownList, x320 y103 w50 h20 r5 vWalkMethod_IfFood gWalkMethod_IfFood Choose%WalkMethod_IfFood% , off|north|east|south|west                 ; -14<<<<<<<
Gui, Add, DropDownList, x320 y136 w50 h20 r5 vWalkMethod_IfBlank gWalkMethod_IfBlank Choose%WalkMethod_IfBlank% , off|north|east|south|west
Gui, Add, DropDownList, x320 y170 w50 h20 r5 vWalkMethod_IfPlayer gWalkMethod_IfPlayer Choose%WalkMethod_IfPlayer% , off|north|east|south|west
Gui, Add, DropDownList, x320 y203 w50 h20 r5 vWalkMethod_IfSoul Choose%WalkMethod_IfSoul% Choose%WalkMethod_IfSoul% , off|north|east|south|west
Gui, Add, DropDownList, x320 y238 w50 h20 r5 +Disabled  vWalkMethod_IfCharMoved Choose1 , off|north|east|south|west


Gui, Tab, 3
Gui, Add, GroupBox, x32 y50 w199 h215 , Store your images
Gui, Add, Pic, x43 y77, Data/Images/picbp.bmp
Gui, Add, Pic, x56 y98 gTake_image_conjured_rune1 vconjured_rune1, Data/Images/conjured_rune1.bmp
Gui, Add, Pic, x167 y98 gTake_image_conjured_rune2 vconjured_rune2, Data/Images/conjured_rune2.bmp
Gui, Add, Pic, x56 y135 gTake_image_backpack1 vbackpack1, Data/Images/backpack1.bmp
Gui, Add, Pic, x167 y135 gTake_image_backpack2 vbackpack2, Data/Images/backpack2.bmp
Gui, Add, Pic, x139 y181 gTake_image_food1 vfood1, Data/Images/food1.bmp
Gui, Add, Pic, x176 y181 gTake_image_food2 vfood2, Data/Images/food2.bmp
Gui, Add, Pic, x93 y209 gTake_image_blank_rune vblank_rune, Data/Images/blank_rune.bmp
Gui, Add, Pic, x164 y206 gTake_image_free_slot vfree_slot, Data/Images/free_slot.bmp

conjured_rune1_TT := "Take picture of rune you will conjure on client 1"
conjured_rune2_TT := "Take picture of rune you will conjure on client 2"
backpack1_TT := "Take picture of new backpack on client 1`n(necessary if you are using 'open new backpack')"
backpack2_TT := "Take picture of new backpack on client 2`n(necessary if you are using 'open new backpack')"
food1_TT := "Take piture of food"
food2_TT := "Take piture of food"
blank_rune_TT := "Take piture of blank rune`n(necessary if you are using 'hand mode')"
free_slot_TT := "Take piture of free slot`n(necessary if you are using 'hand mode')"


Gui, Add, GroupBox, x240 y50 w232 h110 , Runemaker configuration
Gui, Add, Edit, x251 y68 w34 h20 +Disabled +center vhand_slot_pos_x, %hand_slot_pos_x%
Gui, Add, Edit, x289 y68 w34 h20 +Disabled +center vhand_slot_pos_y , %hand_slot_pos_y%
Gui, Add, Button, x332 y68 h20 vGetpos_hand_slot gGetpos_hand_slot, get hand slot position
Gui, Add, CheckBox, x254 y94 w130 h20 vHand_mode, move blanks to hand
Gui, Add, CheckBox, x254 y114 w130 h20 vOpenNewBackpack, open new backpacks
Gui, Add, CheckBox, x254 y134 w130 h20 vCreate_blank, create blank runes

Gui, Add, GroupBox, x240 y170 w232 h95, Alarms configuration

Gui, Add, Edit, x251 y188 w60 h20 center vSpell_to_cast_name, %Spell_to_cast_name%
Gui, Add, Text, x320 y191 w140 h20 , spell to cast in case of alarm
Gui, Add, Text, x251 y211 w60 h20 , say this spell
Gui, Add, Edit, x314 y208 w20 h20 center number limit2 vSpell_to_cast_count gCheck_spell_to_cast_count, %Check_spell_to_cast_count%
Gui, Add, Text, x340 y211 w130 h20, times each runemake cicle.
Gui, Add, Checkbox, x254 y236 h20 vDouble_alarm_screen_checker,  Double alarm effect

hand_slot_pos_x_TT := "Obtained hand slot position"
hand_slot_pos_y_TT := "Obtained hand slot position"
Getpos_hand_slot_TT := "Click and move your mouse to center of left or right hand slot"
Hand_mode_TT := "Use it if you need move blank rune to hand in order to create rune.`n(hand slot position, image of blank rune and free slot MUST be configured!)"
OpenNewBackpack_TT := "Make sure you have took picture for new backpack"
Create_blank_TT := "If its possible to cast 'adori blank' on your OT"

Spell_to_cast_name_TT := "Type here the incantation of spell you want to cast,`nunder certain alarm condition"
Spell_to_cast_count_TT := "The count of times spell should be casted each runemake cycle"
Double_alarm_screen_checker_TT := "It will enable you to execute alarm simultaneously on both clients.`nWorks only for 'walk', 'logout' and 'pause' "



Gui, Tab, 4
Gui, Add, GroupBox, x32 y49 w210 h219 , Advanced settings
Gui Add, Text, x46 y69 w107 h23 +0x200, blank rune spell name:
Gui Add, Text, x46 y93 w130 h23 +0x200, use hotkey to eat food?
Gui Add, Text, x46 y117 w97 h23 +0x200, eat food once every
Gui Add, Text, x46 y141 w110 h23 +0x200, antylogout dance every
Gui Add, Text, x46 y165 w102 h23 +0x200, antylogout directions
Gui Add, Text, x46 y189 w92 h23 +0x200, show notifications
Gui Add, Text, x46 y213 w156 h23 +0x200, steps to walk in case of alarm
Gui Add, Text, x46 y237 w136 h23 +0x200, shut down your pc at:


Gui Add, Edit, x158 y69 w68 h21 Center vBlank_spellname gCheck_blank_spellname, %blank_spellname%
Gui Add, Hotkey, x162 y93 w40 h21 Center vEat_hotkey, %eat_hotkey%
Gui Add, CheckBox, x210 y93 w22 h23 Center veat_using_hotkey geat_using_hotkey,
Gui Add, Edit, x144 y117 w35 h21 Center vFood_time gCheck_food_time, %food_time%
Gui Add, Text, x185 y117 w25 h23 +0x200, sec
Gui Add, Edit, x159 y141 w35 h21 Center vAnty_log_time gCheck_anty_log_time, %anty_log_time%
Gui Add, Text, x198 y141 w25 h23 +0x200, sec
Gui Add, DropDownList, x150 y165 w36 Center vAnty_log_dir1 gCheck_dir1, n|e|s|w
Gui Add, DropDownList, x190 y165 w36 Center vAnty_log_dir2 gCheck_dir2, n|e|s|w
Gui Add, DropDownList, x137 y189 w90 Center vShow_notifications, always|only important|never
Gui Add, DropDownList, x193 y213 w34 Center vSteps_to_walk, 1|2|3|4|5|6|7|8
Gui, Add, DateTime, x152 y237 w55 vAuto_shutdown_time Choose 1, HH:mm
Gui Add, CheckBox, x214 y237 w23 vAuto_shutdown_enabled gAuto_shutdown_enabled h23,

Blank_spellname_TT := "Usually 'adori blank'..."
Eat_hotkey_TT := "If you are playing on tibia 7.8 and newer`nit might suit you to set food on hotkey"
eat_using_hotkey_TT := "If you are playing on tibia 7.8 and newer`nit might suit you to set food on hotkey"
Food_time_TT := "Decide how ofter character should eat food"
Anty_log_time_TT := "Decide how often character should do anty-logout"
Anty_log_dir1_TT := "Choose character direction of anty-logout"
Anty_log_dir2_TT := "Choose character direction of anty-logout"
Show_notifications_TT := "It is recommended to set 'only-importnant' notifications"
Steps_to_walk_TT := "Decide how many sqm character should move in case of emergency"
Auto_shutdown_time_TT := "Determine if you want bot to force shutdown your pc at specific time"
Auto_shutdown_enabled_TT := "Enable auto-shutdown your pc"


Gui, Add, GroupBox, x253 y49 w217 h219 , Credits and contacts
Gui Add, Text, x261 y71 w200 h53, Official project forum - you can report your bugs or share your opinion about the bot here:
Gui Add, Link, x290 y97 w150 h23 vTibiaPf, <a href="https://tibiapf.com/showthread.php?71-all-versions-Warlock-Bot">tibiapf.com - warlockbot</a>
Gui Add, Text, x261 y117 w140 h23 +0x200, Warlock bot's official website:
Gui Add, Link, x321 y137 w80 h23 vWrlbottk, <a href="http://wrlbot.tk">www.wrlbot.tk</a>
Gui Add, Text, x261 y160 w198 h63,If you like it you can support me with a few bucks through PayPal donation. I would be really grateful!
Gui, Add, Pic, x313 y205 vPayPal gPayPal, Data/Images/pp_donate.bmp
Gui Add, Text, x261 y240 w198 h23, Software created by Brazyliszek/Mate

TibiaPf_TT := "Open link"
Wrlbottk_TT := "Open link"
PayPal_TT := "Open link"

Gui,Tab

Gui,Add, Pic, x0 y0 w%pic_window_size_x% h%pic_window_size_y% 0x4000000, %A_WorkingDir%\Data\Images\background.png
Gui,Show, w%pic_window_size_x% h%pic_window_size_y%, %BOTName%

IniRead, randomization, Data/basic_settings.ini, conf values, randomization
IniRead, rune_spellkey1, Data/basic_settings.ini, bot variables, rune_spellkey1
IniRead, rune_spellkey2, Data/basic_settings.ini, bot variables, rune_spellkey2
IniRead, Spelltime1, Data/basic_settings.ini, bot variables, Spelltime1
IniRead, Spelltime2, Data/basic_settings.ini, bot variables, Spelltime2

IniRead, deposit_runes_1, Data/basic_settings.ini, bot variables, deposit_runes_1
IniRead, house_pos_x1, Data/basic_settings.ini, bot variables, house_pos_x1
IniRead, house_pos_y1, Data/basic_settings.ini, bot variables, house_pos_y1
IniRead, deposit_runes_2, Data/basic_settings.ini, bot variables, deposit_runes_2
IniRead, house_pos_x2, Data/basic_settings.ini, bot variables, house_pos_x2
IniRead, house_pos_y2, Data/basic_settings.ini, bot variables, house_pos_y2

IniRead, PauseRunemaking_IfCharMoved, Data/basic_settings.ini, bot variables, PauseRunemaking_IfCharMoved
IniRead, PauseRunemaking_IfFood, Data/basic_settings.ini, bot variables, PauseRunemaking_IfFood
IniRead, PauseRunemaking_IfBlank, Data/basic_settings.ini, bot variables, PauseRunemaking_IfBlank
IniRead, PauseRunemaking_IfPlayer, Data/basic_settings.ini, bot variables, PauseRunemaking_IfPlayer
IniRead, PauseRunemaking_IfSoul, Data/basic_settings.ini, bot variables, PauseRunemaking_IfSoul

IniRead, Logout_IfCharMoved, Data/basic_settings.ini, bot variables, Logout_IfCharMoved
IniRead, Logout_IfFood, Data/basic_settings.ini, bot variables,  Logout_IfFood
IniRead, Logout_IfBlank, Data/basic_settings.ini, bot variables, Logout_IfBlank
IniRead, Logout_IfPlayer, Data/basic_settings.ini, bot variables, Logout_IfPlayer
IniRead, Logout_IfSoul, Data/basic_settings.ini, bot variables, Logout_IfSoul

IniRead, PlaySound_IfCharMoved, Data/basic_settings.ini, bot variables,  PlaySound_IfCharMoved
IniRead, PlaySound_IfFood, Data/basic_settings.ini, bot variables,  PlaySound_IfFood
IniRead, PlaySound_IfBlank, Data/basic_settings.ini, bot variables,  PlaySound_IfBlank
IniRead, PlaySound_IfPlayer, Data/basic_settings.ini, bot variables, PlaySound_IfPlayer
IniRead, PlaySound_IfSoul, Data/basic_settings.ini, bot variables,  PlaySound_IfSoul

IniRead, ShutDown_IfCharMoved, Data/basic_settings.ini, bot variables, ShutDown_IfCharMoved
IniRead, ShutDown_IfFood, Data/basic_settings.ini, bot variables, ShutDown_IfFood
IniRead, ShutDown_IfBlank, Data/basic_settings.ini, bot variables, ShutDown_IfBlank
IniRead, ShutDown_IfPlayer, Data/basic_settings.ini, bot variables, ShutDown_IfPlayer
IniRead, ShutDown_IfSoul, Data/basic_settings.ini, bot variables, ShutDown_IfSoul

IniRead, WalkMethod_IfFood, Data/basic_settings.ini, bot variables, WalkMethod_IfFood
IniRead, WalkMethod_IfBlank, Data/basic_settings.ini, bot variables, WalkMethod_IfBlank
IniRead, WalkMethod_IfPlayer, Data/basic_settings.ini, bot variables, WalkMethod_IfPlayer
IniRead, WalkMethod_IfSoul, Data/basic_settings.ini, bot variables, WalkMethod_IfSoul
IniRead, WalkMethod_IfCharMoved, Data/basic_settings.ini, bot variables, WalkMethod_IfCharMoved

IniRead, CastSpell_IfBlank, Data/basic_settings.ini, bot variables, CastSpell_IfBlank 
IniRead, CastSpell_IfSoul, Data/basic_settings.ini, bot variables, CastSpell_IfSoul 

IniRead, Flash_IfCharMoved, Data/basic_settings.ini, bot variables, Flash_IfCharMoved
IniRead, Flash_IfFood, Data/basic_settings.ini, bot variables, Flash_IfFood
IniRead, Flash_IfBlank, Data/basic_settings.ini, bot variables, Flash_IfBlank
IniRead, Flash_IfPlayer, Data/basic_settings.ini, bot variables, Flash_IfPlayer
IniRead, Flash_IfSoul, Data/basic_settings.ini, bot variables, Flash_IfSoul

IniRead, OpenNewBackpack, Data/basic_settings.ini, bot variables, OpenNewBackpack
IniRead, Create_blank, Data/basic_settings.ini, bot variables, Create_blank
IniRead, Hand_mode, Data/basic_settings.ini, bot variables, Hand_mode
IniRead, hand_slot_pos_x, Data/basic_settings.ini, bot variables, hand_slot_pos_x
IniRead, hand_slot_pos_y, Data/basic_settings.ini, bot variables, hand_slot_pos_y

IniRead, Spell_to_cast_name, Data/basic_settings.ini, bot variables, Spell_to_cast_name
IniRead, Spell_to_cast_count, Data/basic_settings.ini, bot variables, Spell_to_cast_count
IniRead, Double_alarm_screen_checker, Data/basic_settings.ini, bot variables, Double_alarm_screen_checker

IniRead, Blank_spellname, Data/basic_settings.ini, bot variables, Blank_spellname
IniRead, Eat_hotkey, Data/basic_settings.ini, bot variables, Eat_hotkey
IniRead, eat_using_hotkey, Data/basic_settings.ini, bot variables, eat_using_hotkey 
IniRead, Food_time, Data/basic_settings.ini, bot variables, Food_time
IniRead, Anty_log_time, Data/basic_settings.ini, bot variables, Anty_log_time
IniRead, Anty_log_dir1, Data/basic_settings.ini, bot variables, Anty_log_dir1
IniRead, Anty_log_dir2, Data/basic_settings.ini, bot variables, Anty_log_dir2
IniRead, Show_notifications, Data/basic_settings.ini, bot variables, Show_notifications
IniRead, Steps_to_walk, Data/basic_settings.ini, bot variables, Steps_to_walk
IniRead, Auto_shutdown_time, Data/basic_settings.ini, bot variables, Auto_shutdown_time 

GuiControl,, rune_spellkey1, %rune_spellkey1%
GuiControl,, rune_spellkey2, %rune_spellkey2%
GuiControl,, Spelltime1, %Spelltime1%
GuiControl,, Spelltime2, %Spelltime2%

GuiControl,, deposit_runes_1, %deposit_runes_1%
GuiControl,, house_pos_x1, %house_pos_x1%
GuiControl,, house_pos_y1, %house_pos_y1%
GuiControl,, deposit_runes_2, %deposit_runes_2%
GuiControl,, house_pos_x2, %house_pos_x2%
GuiControl,, house_pos_y2, %house_pos_y2%

GuiControl,, PauseRunemaking_IfCharMoved, %PauseRunemaking_IfCharMoved%
GuiControl,, PauseRunemaking_IfFood, %PauseRunemaking_IfFood%
GuiControl,, PauseRunemaking_IfBlank, %PauseRunemaking_IfBlank%
GuiControl,, PauseRunemaking_IfPlayer, %PauseRunemaking_IfPlayer%
GuiControl,, PauseRunemaking_IfSoul, %PauseRunemaking_IfSoul%

GuiControl,, Logout_IfCharMoved, %Logout_IfCharMoved%
GuiControl,, Logout_IfFood, %Logout_IfFood%
GuiControl,, Logout_IfBlank, %Logout_IfBlank%
GuiControl,, Logout_IfPlayer, %Logout_IfPlayer%
GuiControl,, Logout_IfSoul, %Logout_IfSoul%

GuiControl,, PlaySound_IfCharMoved, %PlaySound_IfCharMoved%
GuiControl,, PlaySound_IfFood, %PlaySound_IfFood%
GuiControl,, PlaySound_IfBlank, %PlaySound_IfBlank%
GuiControl,, PlaySound_IfPlayer, %PlaySound_IfPlayer%
GuiControl,, PlaySound_IfSoul, %PlaySound_IfSoul%

GuiControl,, ShutDown_IfCharMoved, %ShutDown_IfCharMoved%
GuiControl,, ShutDown_IfFood, %ShutDown_IfFood%
GuiControl,, ShutDown_IfBlank, %ShutDown_IfBlank%
GuiControl,, ShutDown_IfPlayer, %ShutDown_IfPlayer%
GuiControl,, ShutDown_IfSoul, %ShutDown_IfSoul%

GuiControl,Choose, WalkMethod_IfFood, %WalkMethod_IfFood%
GuiControl,Choose, WalkMethod_IfBlank, %WalkMethod_IfBlank%
GuiControl,Choose, WalkMethod_IfPlayer, %WalkMethod_IfPlayer%
GuiControl,Choose, WalkMethod_IfSoul, %WalkMethod_IfSoul%
GuiControl,Choose, WalkMethod_IfCharMoved, %WalkMethod_IfCharMoved%

GuiControl,, CastSpell_IfBlank, %CastSpell_IfBlank%
GuiControl,, CastSpell_IfSoul, %CastSpell_IfSoul% 

GuiControl,, Flash_IfCharMoved, %Flash_IfCharMoved%
GuiControl,, Flash_IfFood, %Flash_IfFood%
GuiControl,, Flash_IfBlank, %Flash_IfBlank%
GuiControl,, Flash_IfPlayer, %Flash_IfPlayer%
GuiControl,, Flash_IfSoul, %Flash_IfSoul%

GuiControl,, OpenNewBackpack, %OpenNewBackpack%
GuiControl,, Create_blank, %Create_blank%
GuiControl,, Hand_mode, %Hand_mode%
GuiControl,, hand_slot_pos_x, %hand_slot_pos_x%
GuiControl,, hand_slot_pos_y, %hand_slot_pos_y%

GuiControl,, Spell_to_cast_name, %Spell_to_cast_name%
GuiControl,, Spell_to_cast_count, %Spell_to_cast_count%
GuiControl,, Double_alarm_screen_checker, %Double_alarm_screen_checker%

GuiControl,, Blank_spellname, %Blank_spellname%
GuiControl,, Eat_hotkey, %Eat_hotkey%
GuiControl,, eat_using_hotkey, %eat_using_hotkey%
GuiControl,, Food_time, %Food_time%
GuiControl,, Anty_log_time, %Anty_log_time%
GuiControl,Choose, Anty_log_dir1, %Anty_log_dir1%
GuiControl,Choose, Anty_log_dir2, %Anty_log_dir2%
GuiControl,Choose, Show_notifications, %Show_notifications%
GuiControl,Choose, Steps_to_walk, %Steps_to_walk%
GuiControl,, Auto_shutdown_time, %Auto_shutdown_time%



if (mc_count = 1){                                       ; disabling few functions in case if only one client was turned on
   GuiControl, Disable, rune_spellkey2
   GuiControl, Disable, Spelltime2
   GuiControl, Disable, Image_screen_checker2, 
   GuiControl, Disable, Enabled_screen_checker2 
   GuiControl, Disable, Fishing_setup2, 
   GuiControl, Disable, getpos_house_2, 
   GuiControl, Disable, deposit_runes_2
   GuiControl, Disable, Enabled_runemaking2 
   GuiControl, Disable, Enabled_anty_logout2 
   GuiControl, Disable, Enabled_food_eater2 
   GuiControl, Disable, Fishing_enabled2 
   GuiControl, Disable, Alarms_enabled2
   GuiControl, Disable, Double_alarm_screen_checker
   GuiControl, Disable, Toggle_hide2
   GuiControl,, Double_alarm_screen_checker, 0
   GuiControl,, NotNeeded_pid2, 0000
}

;sleep, 100
gosub, CP_GUI
gosub, MENU_CREATE

Gui, Fishing_gui1: New
Gui, Fishing_gui1: +hwndFishing_gui1 +AlwaysOnTop +Caption +ToolWindow 
Gui, Fishing_gui1: Add, Button, x6 y10 w68 h35 gFishing_getSpots1 vFishing_button_text1 , get fishing spots
Gui, Fishing_gui1: Add, Button, x77 y10 w68 h35 gFishing_reset1, reset
Gui, Fishing_gui1: Add, CheckBox, x12 y50 w140 h20 vFishing_noFood_enabled1, fish only if no food
Gui, Fishing_gui1: Add, CheckBox, x12 y70 w120 h30 vFishing_noSlot_enabled1, fish only if found empty slot in bp
Gui, Fishing_gui1: Add, Pic, x8 y104, Data/Images/fishing_rod_bp.bmp
Gui, Fishing_gui1: Add, Pic, x95 y125 gTake_image_fishing_rod1 vfishing_rod1, Data/Images/fishing_rod.bmp
Gui, Fishing_gui1: Add, Pic, x104 y172 gTake_image_fish1 vfish1, Data/Images/fish.bmp
Gui, Fishing_gui1: Add, Button, x28 y217 w90 h20 gFishing_done1 default , done

Gui, Fishing_selectTopLeft1: New
Gui, Fishing_selectTopLeft1: +hwndFishing_selectTopLeft1
Gui, Fishing_selectTopLeft1: -SysMenu +ToolWindow -Caption +Border +AlwaysOnTop +OwnerFishing_gui1
Gui, Fishing_selectTopLeft1: Font,norm bold s10
Gui, Fishing_selectTopLeft1: Add,Text,,Select top left corner of game window
Gui, Fishing_selectTopLeft1: Font
Gui, Fishing_selectTopLeft1: Add,Text,, Move your mouse to TOP LEFT corner of game window`nand click left mouse button. Or click escape to cancel.

Gui, Fishing_selectBottomRight1: New
Gui, Fishing_selectBottomRight1: +hwndFishing_selectBottomRight1
Gui, Fishing_selectBottomRight1: -SysMenu +ToolWindow -Caption +Border +AlwaysOnTop +OwnerFishing_gui1
Gui, Fishing_selectBottomRight1: Font,norm bold s10
Gui, Fishing_selectBottomRight1: Add,Text,,Select bottom right corner of game window
Gui, Fishing_selectBottomRight1: Font
Gui, Fishing_selectBottomRight1: Add,Text,, Move your mouse to BOTTOM RIGHT corner of game window`nand click left mouse button. Or click escape to cancel.


Gui, Fishing_gui2: New
Gui, Fishing_gui2: +hwndFishing_gui2 +AlwaysOnTop +Caption +ToolWindow 
Gui, Fishing_gui2: Add, Button, x6 y10 w68 h35 gFishing_getSpots2 vFishing_button_text2 , get fishing spots
Gui, Fishing_gui2: Add, Button, x77 y10 w68 h35 gFishing_reset2, reset
Gui, Fishing_gui2: Add, CheckBox, x12 y50 w140 h20 vFishing_noFood_enabled2, fish only if no food
Gui, Fishing_gui2: Add, CheckBox, x12 y70 w120 h30 vFishing_noSlot_enabled2, fish only if found empty slot in bp
Gui, Fishing_gui2: Add, Pic, x8 y104, Data/Images/fishing_rod_bp.bmp
Gui, Fishing_gui2: Add, Pic, x95 y125 gTake_image_fishing_rod2 vfishing_rod2, Data/Images/fishing_rod.bmp
Gui, Fishing_gui2: Add, Pic, x104 y172 gTake_image_fish2 vfish2, Data/Images/fish.bmp
Gui, Fishing_gui2: Add, Button, x28 y217 w90 h20 gFishing_done2 default , done

Gui, Fishing_selectTopLeft2: New
Gui, Fishing_selectTopLeft2: +hwndFishing_selectTopLeft2
Gui, Fishing_selectTopLeft2: -SysMenu +ToolWindow -Caption +Border +AlwaysOnTop +OwnerFishing_gui2
Gui, Fishing_selectTopLeft2: Font,norm bold s10
Gui, Fishing_selectTopLeft2: Add,Text,,Select top left corner of game window
Gui, Fishing_selectTopLeft2: Font
Gui, Fishing_selectTopLeft2: Add,Text,, Move your mouse to TOP LEFT corner of game window`nand click left mouse button. Or click escape to cancel.

Gui, Fishing_selectBottomRight2: New
Gui, Fishing_selectBottomRight2: +hwndFishing_selectBottomRight2
Gui, Fishing_selectBottomRight2: -SysMenu +ToolWindow -Caption +Border +AlwaysOnTop +OwnerFishing_gui2
Gui, Fishing_selectBottomRight2: Font,norm bold s10
Gui, Fishing_selectBottomRight2: Add,Text,,Select bottom right corner of game window
Gui, Fishing_selectBottomRight2: Font
Gui, Fishing_selectBottomRight2: Add,Text,, Move your mouse to BOTTOM RIGHT corner of game window`nand click left mouse button. Or click escape to cancel.


Gui, Screenshoot_window: New
Gui, Screenshoot_window: -SysMenu +ToolWindow -Caption +Border +AlwaysOnTop
Gui, Screenshoot_window: Font,norm bold s10
Gui, Screenshoot_window: Add,Text, vText_to_display,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Gui, Screenshoot_window: Font
Gui, Screenshoot_window: Add,Text,, Move your mouse to center of item you want to save`nand click left mouse button. Or click escape to cancel.


Gui, screen_box: New
Gui screen_box: +alwaysontop -Caption +Border +ToolWindow +LastFound
Gui, screen_box: Color, ADEBDA
WinSet, Transparent, 50 ; Else Add transparency



OnMessage(0x200, "WM_MOUSEMOVE")
#Persistent               ; to overwrite settings only if main window has been shown
OnExit("save")
return

; ######################################################### MAIN #########################################################################
Enabled_runemaking1:
   GuiControlGet, Enabled_runemaking1,, Enabled_runemaking1
   GuiControlGet, Enabled_runemaking2,, Enabled_runemaking2
   GuiControlGet, Spelltime1,, Spelltime1
   GuiControlGet, rune_spellkey1,, rune_spellkey1
   IfWinNotExist, ahk_pid %pid_tibia1%
      {
      if (pid_tibia1 != ""){
         title_tibia1 := "Game client 1 - identyfied by " pid_tibia1
         WinActivate, ahk_pid %pid_tibia1%
         WinWait, ahk_pid %pid_tibia1% 
         WinSetTitle, %title_tibia1%
         sleep, 50
      }
      IfWinNotExist, ahk_pid %pid_tibia1%
      {
         notification(2, title_tibia1, "Window " . title_tibia1 . " doesn't exist.")
         GuiControl,, Enabled_runemaking1, 0
         Check_gui()
         return
      }
   }
   if (Spelltime1 = ""){
      notification(1, title_tibia1, "Please enter valid spell time.")
      GuiControl,, Enabled_runemaking1, 0
      Check_gui()
      return
   }
   if (rune_spellkey1 = ""){
      notification(1, title_tibia1, "Please enter valid spell key.")
      GuiControl,, Enabled_runemaking1, 0
      Check_gui()
      return
   }
   GuiControlGet, hand_mode,, hand_mode
    if ((Hand_mode = 1) and ((hand_slot_pos_x = "") or (hand_slot_pos_y = ""))){ 
      notification(1, title_tibia1, "Please get your hand slot position in settings.")
      GuiControl,, Enabled_runemaking1, 0
      Check_gui()
      return
   }
   if (Enabled_runemaking1 = 1){
      global planned_time1 := % A_TickCount + 5000
      SetTimer, check_runes, 1000
   }
   check_gui()
return
   
   
Enabled_runemaking2:
   GuiControlGet, Enabled_runemaking1,, Enabled_runemaking1
   GuiControlGet, Enabled_runemaking2,, Enabled_runemaking2
   GuiControlGet, Spelltime2,, Spelltime2
   GuiControlGet, rune_spellkey2,, rune_spellkey2
   IfWinNotExist, ahk_pid %pid_tibia2%
      {
      if (pid_tibia2 != ""){
         title_tibia2 := "Game client 2 - identyfied by " pid_tibia2
         WinActivate, ahk_pid %pid_tibia2%
         WinWait, ahk_pid %pid_tibia2% 
         WinSetTitle, %title_tibia2%
         sleep, 50
      }
      IfWinNotExist, ahk_pid %pid_tibia2%
         {
         notification(2, title_tibia2, "Window " . title_tibia2 . " doesn't exist.")
         GuiControl,, Enabled_runemaking2, 0
         Check_gui()
         return
      }
   }
   if (Spelltime2 = ""){
      notification(1, title_tibia2, "Please enter valid spell time.")
      GuiControl,, Enabled_runemaking2, 0
      Check_gui()
      return
   }
   if (rune_spellkey2 = ""){
      notification(1, title_tibia2, "Please enter valid spell key.")
      GuiControl,, Enabled_runemaking2, 0      
      Check_gui()
      return
   }
   GuiControlGet, hand_mode,, hand_mode
   if ((Hand_mode = 1) and ((hand_slot_pos_x = "") or (hand_slot_pos_y = ""))){ 
      notification(1, title_tibia1, "Please get your hand slot position in settings.")
      GuiControl,, Enabled_runemaking1, 0
      Check_gui()
      return
   }
   if (Enabled_runemaking2 = 1){
      global planned_time2 := % A_TickCount + 10000
      SetTimer, check_runes, 1000
   }
   check_gui()
return


check_runes:
   GuiControlGet, Enabled_runemaking1,, Enabled_runemaking1
   GuiControlGet, Enabled_runemaking2,, Enabled_runemaking2
   if (execution_allowed = 1) and ((A_TickCount - planned_time1) > 0) and (Enabled_runemaking1 = 1)
      goto Rune_execution1
   if (execution_allowed = 1) and ((A_TickCount - planned_time2) > 0) and (Enabled_runemaking2 = 1)
      goto Rune_execution2
return


Rune_execution1:
   Critical
   global execution_allowed := 0
   IfWinNotExist, ahk_pid %pid_tibia1%
      {
      notification(2, title_tibia1, "Window " . title_tibia1 . " doesn't exist.")
      GuiControl,, Enabled_runemaking1, 0
      Check_gui()
      
      global execution_allowed := 1
      return
   }
   GuiControlGet, Spelltime1,, Spelltime1
   global current_time1 := A_TickCount
   global deviation1 := % current_time1 - planned_time1
   global planned_time1 := % current_time1 + Spelltime1*1000 - deviation1
   runemake(title_tibia1, 1)
   sleep_random(10,100)
   check_soul(title_tibia1)
   global execution_allowed := 1
return

Rune_execution2:
   Critical
   global execution_allowed := 0
   IfWinNotExist, ahk_pid %pid_tibia2%
      {
      notification(2, title_tibia2, "Window " . title_tibia2 . " doesn't exist.")
      GuiControl,, Enabled_runemaking2, 0
      Check_gui()
      global execution_allowed := 1
      return
   }
   GuiControlGet, Spelltime2,, Spelltime2
   global current_time2 := A_TickCount
   global deviation2 := % current_time2 - planned_time2
   global planned_time2 := % current_time2 + Spelltime2*1000 - deviation2
   runemake(title_tibia2, 2)
   sleep_random(10,100)
   check_soul(title_tibia2)
   global execution_allowed := 1
return

Enabled_food_eater1:
   GuiControlGet, Enabled_food_eater1,, Enabled_food_eater1
   GuiControlGet, Enabled_food_eater2,, Enabled_food_eater2
   GuiControlGet, food_time,, food_time
   IfWinNotExist, ahk_pid %pid_tibia1%
      {
      if (pid_tibia1 != ""){
         title_tibia1 := "Game client 1 - identyfied by " pid_tibia1
         WinActivate, ahk_pid %pid_tibia1%
         WinWait, ahk_pid %pid_tibia1% 
         WinSetTitle, %title_tibia1%
         sleep, 50
      }
      IfWinNotExist, ahk_pid %pid_tibia1%
      {
         notification(2, client_id, "Window " . title_tibia1 . " doesn't exist.")
         GuiControl,, Enabled_food_eater1, 0
         return
      }
   }
   if (food_time = "") or (food_time < 15) or (food_time > 2000){
      notification(1, title_tibia1, "Please enter valid food time")
      GuiControl,, Enabled_food_eater1, 0
      return
   }
   if (Enabled_food_eater1 = 1){
      SetTimer, food_eater1, % food_time*1000
      GuiControl, Disable%Enabled_food_eater1%, food_time
   }
   else if ((Enabled_food_eater1 = 0) and (Enabled_food_eater1 = 0))
      GuiControl, Disable%Enabled_food_eater1%, food_time
return

food_eater1:
IfWinNotExist, ahk_pid %pid_tibia1%
   return
GuiControlGet, Enabled_food_eater1,, Enabled_food_eater1
if (Enabled_food_eater1 = 1){
   sleep_random(10,3000)
   eat_food(title_tibia1)
}
else
   SetTimer, food_eater1, off
return

Enabled_food_eater2:
   GuiControlGet, Enabled_food_eater1,, Enabled_food_eater1
   GuiControlGet, Enabled_food_eater2,, Enabled_food_eater2
   GuiControlGet, food_time,, food_time
   IfWinNotExist, ahk_pid %pid_tibia2%
      {
      if (pid_tibia2 != ""){
         title_tibia2 := "Game client 2 - identyfied by " pid_tibia2
         WinActivate, ahk_pid %pid_tibia2%
         WinWait, ahk_pid %pid_tibia2% 
         WinSetTitle, %title_tibia2%
         sleep, 50
      }
      IfWinNotExist, ahk_pid %pid_tibia2%
      {
         notification(2, client_id, "Window " . title_tibia2 . " doesn't exist.")
         GuiControl,, Enabled_food_eater2, 0
         return
      }
   }
   if (food_time = "") or (food_time < 15) or (food_time > 2000){
      notification(1, title_tibia2, "Please enter valid food time")
      GuiControl,, Enabled_food_eater2, 0
      return
   }
   if (Enabled_food_eater2 = 1){
      SetTimer, food_eater2, % food_time*1000
      GuiControl, Disable%Enabled_food_eater2%, food_time
   }
   else if ((Enabled_food_eater1 = 0) and (Enabled_food_eater1 = 0))
      GuiControl, Disable%Enabled_food_eater2%, food_time
   
return

food_eater2:
IfWinNotExist, ahk_pid %pid_tibia2%
   return
GuiControlGet, Enabled_food_eater2,, Enabled_food_eater2
if (Enabled_food_eater2 = 1){
   sleep_random(10,3000)
   eat_food(title_tibia2)
}
else
   SetTimer, food_eater2, off
return

Enabled_anty_logout1:
   GuiControlGet, Enabled_anty_logout1,, Enabled_anty_logout1
   GuiControlGet, Enabled_anty_logout2,, Enabled_anty_logout2
   GuiControlGet, anty_log_time,, anty_log_time
   IfWinNotExist, ahk_pid %pid_tibia1%
      {
      if (pid_tibia1 != ""){
         title_tibia1 := "Game client 1 - identyfied by " pid_tibia1
         WinActivate, ahk_pid %pid_tibia1%
         WinWait, ahk_pid %pid_tibia1% 
         WinSetTitle, %title_tibia1%
         sleep, 50
      }
      IfWinNotExist, ahk_pid %pid_tibia1%
      {
         notification(2, client_id, "Window " . title_tibia1 . " doesn't exist.")
         GuiControl,, Enabled_anty_logout1, 0
         return
      }
   }
   if (anty_log_time = "") or (anty_log_time < 15) or (anty_log_time > 2000){
      notification(1, title_tibia1, "Please enter valid anty logout time.")
      GuiControl,, Enabled_anty_logout1, 0
      return
   }
   if (Enabled_anty_logout1 = 1){
      SetTimer, anty_logout_timer1, % anty_log_time*1000
      GuiControl, Disable%Enabled_anty_logout1%, anty_log_time
   }
   else if ((Enabled_anty_logout1 = 0) and (Enabled_anty_logout2 = 0))
      GuiControl, Disable%Enabled_anty_logout1%, anty_log_time
return

anty_logout_timer1:
IfWinNotExist, ahk_pid %pid_tibia1%
   return
GuiControlGet, Enabled_anty_logout1,, Enabled_anty_logout1
if (Enabled_anty_logout1 = 1){
   sleep_random(10,3000)
   anty_logout(title_tibia1)
}
else
   SetTimer, anty_logout_timer1, off
return

Enabled_anty_logout2:
   GuiControlGet, Enabled_anty_logout1,, Enabled_anty_logout1
   GuiControlGet, Enabled_anty_logout2,, Enabled_anty_logout2
   GuiControlGet, anty_log_time,, anty_log_time
   IfWinNotExist, ahk_pid %pid_tibia2%
      {
      if (pid_tibia2 != ""){
         title_tibia2 := "Game client 2 - identyfied by " pid_tibia2
         WinActivate, ahk_pid %pid_tibia2%
         WinWait, ahk_pid %pid_tibia2% 
         WinSetTitle, %title_tibia2%
         sleep, 50
      }
      IfWinNotExist, ahk_pid %pid_tibia2%
      {
         notification(2, client_id, "Window " . title_tibia2 . " doesn't exist.")
         GuiControl,, Enabled_anty_logout2, 0
         return
      }
   }
   if (anty_log_time = "") or (anty_log_time < 15) or (anty_log_time > 2000){
      notification(1, title_tibia2, "Please enter valid anty logout time.")
      GuiControl,, Enabled_anty_logout2, 0
      return
   }
   if (Enabled_anty_logout2 = 1){
      SetTimer, anty_logout_timer2, % anty_log_time*1000
      GuiControl, Disable%Enabled_anty_logout2%, anty_log_time
   }
   else if ((Enabled_anty_logout1 = 0) and (Enabled_anty_logout2 = 0))
      GuiControl, Disable%Enabled_anty_logout2%, anty_log_time
return

anty_logout_timer2:
IfWinNotExist, ahk_pid %pid_tibia2%
   return
GuiControlGet, Enabled_anty_logout2,, Enabled_anty_logout2
if (Enabled_anty_logout2 = 1){
   sleep_random(10,3000)

   anty_logout(title_tibia2)
}
else
   SetTimer, anty_logout_timer2, off
return



; ######################################################### FUNCTIONS ##############################################################################


runemake(client_id, client_number){
   GuiControlGet, Enabled_runemaking1,, Enabled_runemaking1
   GuiControlGet, Enabled_runemaking2,, Enabled_runemaking2
   if (((client_id = title_tibia1) and (Enabled_runemaking1 = 0)) or ((client_id = title_tibia2) and (Enabled_runemaking2 = 0)))
      return
   backpack_id := "backpack" . client_number                  ; this declaration is needed for now
   rune_spellkey_id := "rune_spellkey" . client_number
   conjured_rune_id := "conjured_rune" . client_number
   house_deposit_id := "deposit_runes_" . client_number
   GuiControlGet, openNewBackpack,, openNewBackpack
   GuiControlGet, hand_mode,, hand_mode
   GuiControlGet, house_deposit,, %house_deposit_id%
   GuiControlGet, create_blank,, create_blank
   GuiControlGet, rune_spellkey,, %rune_spellkey_id%
   global mc_count
   if (create_blank = 1){
      if (find(client_id, "blank_rune", "inventory", 1, 0) = 0){
         say(client_id, blank_spellname)        
         sleep_random(1500,2000)
      }
   }
   if (openNewBackpack = 1){
      blankrune_check:
      if (find(client_id, "blank_rune", "inventory", 1, 0) = 0){
         sleep_random(100,250)
         if (find(client_id, backpack_id, "inventory", 1, 0) = 0)
            alarm(client_id, "blank_runes")
         else{
            use(client_id, backpack_id)
            sleep_random(500,1000)
            goto blankrune_check
         }
      }
   }
   if (hand_mode = 1){
      move(client_id, "blank_rune", "hand")
      sleep_random(300,500)
      if (find(client_id, "blank_rune", "hand_slot", 1, -1) = 0){
         move(client_id, "blank_rune", "hand")                              ; duplication try of move blank rune to hand
         sleep_random(300,500)
         if (find(client_id, "blank_rune", "hand_slot", 1, 0) = 0)
            notification(0, client_id, "Couldn't find blank rune on hand slot.")
      }
   }
   sleep_random(300,700)
   cast(client_id, rune_spellkey)
   sleep_random(500,800)
   if (house_deposit = 1 and hand_mode = 1){
      if (find(client_id, conjured_rune_id, "hand_slot", 1, 0) = 1){
         sleep_random(100,200)
         move(client_id, "hand", "house")
         return
      }
      else if (find(client_id, conjured_rune_id, "inventory", 1, 0) = 1){
         sleep_random(100,200)
         move(client_id, conjured_rune_id, "house")
         return
      }
      else
         notification(0, client_id, "Couldn't find conjured rune on screen. Can't throw it on desired position.")
   }
   else if (house_deposit = 1 and hand_mode = 0){
      if (find(client_id, conjured_rune_id, "inventory", 1, 0) = 1){
         sleep_random(300,700)
         move(client_id, conjured_rune_id, "house")
         return
      }
      else
         notification(0, client_id, "Couldn't find conjured rune on screen. Can't throw it on desired position.")
   }
   else if (house_deposit = 0 and hand_mode = 1){
      freeslot_check:
      if (find(client_id, "free_slot", "inventory", 1, 0) = 0){
         if (openNewBackpack = 1){
            if (find(client_id, backpack_id, "inventory", 1, 0) = 0){
               notification(0, client_id, "Couldn't find free slot.")
            }
            else{
               use(client_id, backpack_id)
               goto freeslot_check
            }
         }
         else{
            notification(0, client_id, "Couldn't find free slot.")
            return
         }
      }
      else{
         sleep_random(300,700)
         move(client_id, "hand", "free_slot")
         if (find(client_id, conjured_rune_id, "hand_slot", 1, -1) = 1)
            move(client_id, "hand", "free_slot")
         return
      }
   }
   else
      return
sleep_random(500,900)
return
}

check_soul(client_id){
   GuiControlGet, PauseRunemaking_IfSoul,,PauseRunemaking_IfSoul
   GuiControlGet, Logout_IfSoul,,Logout_IfSoul
   GuiControlGet, PlaySound_IfSoul,,PlaySound_IfSoul
   GuiControlGet, ShutDown_IfSoul,,ShutDown_IfSoul
   GuiControlGet, WalkMethod_IfSoul,,WalkMethod_IfSoul
   GuiControlGet, CastSpell_IfSoul,,CastSpell_IfSoul
   GuiControlGet, Flash_IfSoul,,Flash_IfSoul
   if (PauseRunemaking_IfSoul or Logout_IfSoul or PlaySound_IfSoul or ShutDown_IfSoul or CastSpell_IfSoul or Flash_IfSoul or (WalkMethod_IfSoul != "off")){
      if ((find(client_id, "soul0", "inventory", 1, 0) = 1) or (find(client_id, "soul1", "inventory", 1, 0) = 1) or (find(client_id, "soul2", "inventory", 1, 0) = 1) or (find(client_id, "soul3", "inventory", 1, 0) = 1) or (find(client_id, "soul4", "inventory", 1, 0) = 1)){
         alarm(client_id, "soul")
      }
   }
}
return
   

alarm(client_id, type){
   GuiControlGet, Double_alarm_screen_checker,,Double_alarm_screen_checker
   GuiControlGet, Steps_to_walk,,Steps_to_walk
   GuiControlGet, Alarms_enabled1,,Alarms_enabled1
   GuiControlGet, Alarms_enabled2,,Alarms_enabled2
   global mc_count
   ; msgbox, client_id:%client_id%`ntitle_tibia1:%title_tibia1%`n:Alarms_enabled1%Alarms_enabled1%`ntitle_tibia2:%title_tibia2%`nAlarms_enabled2:%Alarms_enabled2%
   if ((client_id = title_tibia1) and (Alarms_enabled1 = 0)) or ((client_id = title_tibia2) and (Alarms_enabled2 = 0)){
      return   
   }
   IfInString, client_id, Game client 1             
      client_number := 1
   else
      client_number := 2
    if (type = "player"){
      GuiControlGet, PauseRunemaking_IfPlayer,,PauseRunemaking_IfPlayer
      GuiControlGet, Logout_IfPlayer,,Logout_IfPlayer
      GuiControlGet, PlaySound_IfPlayer,,PlaySound_IfPlayer
      GuiControlGet, ShutDown_IfPlayer,,ShutDown_IfPlayer
      GuiControlGet, WalkMethod_IfPlayer,,WalkMethod_IfPlayer
      GuiControlGet, Flash_IfPlayer,,Flash_IfPlayer
      notification(0, client_id, "There was a change on screen-check region.")
      if (Logout_IfPlayer = 1){
         logout(client_id)
      }
      if (WalkMethod_IfPlayer != "off"){
            walk(client_id, WalkMethod_IfPlayer, steps_to_walk)
      }
      if (PlaySound_IfPlayer = 1){
         sound("Data/Sounds/alarm_screen.mp3")
      }
      if (Flash_IfPlayer = 1){
         if (transparent_tibia%client_number% = 1)
            gosub, hide_client_%client_number%
         else
            WinActivate, %client_id%
         Winget, temp_hwnd, ID, %client_id%
         Loop 8{
            DllCall( "FlashWindow", UInt,temp_hwnd, Int,True )
            Sleep 250
         }
         DllCall( "FlashWindow", UInt,temp_hwnd, Int,False )
      }
      if (PauseRunemaking_IfPlayer = 1){
         if ((Double_alarm_screen_checker = 1) and (mc_count = 2)){
            GuiControl,, Enabled_runemaking1,0
            GuiControl,, Enabled_anty_logout1,0
            GuiControl,, Enabled_food_eater1,0
            GuiControl,, Fishing_enabled1,0
            GuiControl,, Enabled_runemaking2,0
            GuiControl,, Enabled_anty_logout2,0
            GuiControl,, Enabled_food_eater2,0
            GuiControl,, Fishing_enabled2,0
            Check_gui()
         }
         else{
            GuiControl,, Enabled_runemaking%client_number%, 0
            GuiControl,, Enabled_runemaking%client_number%,0
            GuiControl,, Enabled_anty_logout%client_number%,0
            GuiControl,, Enabled_food_eater%client_number%,0
            GuiControl,, Fishing_enabled%client_number%,0
            Check_gui()
         }
      }
      if (ShutDown_IfPlayer = 1){
         shutdown()
      }
   }
   if (type = "food"){
      GuiControlGet, PauseRunemaking_IfFood,,PauseRunemaking_IfFood
      GuiControlGet, Logout_IfFood,,Logout_IfFood
      GuiControlGet, PlaySound_IfFood,,PlaySound_IfFood
      GuiControlGet, ShutDown_IfFood,,ShutDown_IfFood
      GuiControlGet, WalkMethod_IfFood,,WalkMethod_IfFood
      GuiControlGet, Flash_IfFood,,Flash_IfFood
      notification(0, client_id, "Couldn't find food in inventory.")
      if (Logout_IfFood = 1){         
         logout(client_id)
      }
      if (WalkMethod_IfFood != "off"){
            walk(client_id, WalkMethod_IfFood, steps_to_walk)
      }
      if (PlaySound_IfFood = 1){
         sound("Data/Sounds/alarm_food.mp3")
      }
      if (PauseRunemaking_IfFood = 1){
         if ((Double_alarm_screen_checker = 1) and (mc_count = 2)){
            GuiControl,, Enabled_runemaking1,0
            GuiControl,, Enabled_anty_logout1,0
            GuiControl,, Enabled_food_eater1,0
            GuiControl,, Fishing_enabled1,0
            GuiControl,, Enabled_runemaking2,0
            GuiControl,, Enabled_anty_logout2,0
            GuiControl,, Enabled_food_eater2,0
            GuiControl,, Fishing_enabled2,0
            Check_gui()
         }
         else{
            GuiControl,, Enabled_runemaking%client_number%, 0
            GuiControl,, Enabled_runemaking%client_number%,0
            GuiControl,, Enabled_anty_logout%client_number%,0
            GuiControl,, Enabled_food_eater%client_number%,0
            GuiControl,, Fishing_enabled%client_number%,0
            Check_gui()
         }
      }
      if (Flash_IfFood = 1){
         if (transparent_tibia%client_number% = 1)
            gosub, hide_client_%client_number%
         else
            WinActivate, %client_id%
         Winget, temp_hwnd, ID, %client_id%
         Loop 8{
            DllCall( "FlashWindow", UInt,temp_hwnd, Int,True )
            Sleep 250
         }
         DllCall( "FlashWindow", UInt,temp_hwnd, Int,False )
      }
      if (ShutDown_IfFood = 1){
         shutdown()
      }
   }
   if (type = "blank_runes"){
      GuiControlGet, PauseRunemaking_IfBlank,,PauseRunemaking_IfBlank
      GuiControlGet, Logout_IfBlank,,Logout_IfBlank
      GuiControlGet, PlaySound_IfBlank,,PlaySound_IfBlank
      GuiControlGet, ShutDown_IfBlank,,ShutDown_IfBlank
      GuiControlGet, WalkMethod_IfBlank,,WalkMethod_IfBlank
      GuiControlGet, CastSpell_IfBlank,,CastSpell_IfBlank
      GuiControlGet, Flash_IfBlank,,Flash_IfBlank
      notification(0, client_id, "Couldn't find blank rune in inventory.")
      if (Logout_IfBlank = 1){
         logout(client_id)
      }
      if (WalkMethod_IfBlank != "off"){
            walk(client_id, WalkMethod_IfBlank, steps_to_walk)
      }
      if (PlaySound_IfBlank = 1){
         sound("Data/Sounds/alarm_blank.mp3")
      }
      if (ShutDown_IfBlank = 1){
         shutdown()
      }
      if (PauseRunemaking_IfBlank = 1){
         if ((Double_alarm_screen_checker = 1) and (mc_count = 2)){
            GuiControl,, Enabled_runemaking1,0
            GuiControl,, Enabled_anty_logout1,0
            GuiControl,, Enabled_food_eater1,0
            GuiControl,, Fishing_enabled1,0
            GuiControl,, Enabled_runemaking2,0
            GuiControl,, Enabled_anty_logout2,0
            GuiControl,, Enabled_food_eater2,0
            GuiControl,, Fishing_enabled2,0
            Check_gui()
         }
         else{
            GuiControl,, Enabled_runemaking%client_number%, 0
            GuiControl,, Enabled_runemaking%client_number%,0
            GuiControl,, Enabled_anty_logout%client_number%,0
            GuiControl,, Enabled_food_eater%client_number%,0
            GuiControl,, Fishing_enabled%client_number%,0
            Check_gui()
         }
      }
      if (Flash_IfBlank = 1){
         if (transparent_tibia%client_number% = 1)
            gosub, hide_client_%client_number%
         else
            WinActivate, %client_id%
         Winget, temp_hwnd, ID, %client_id%
         Loop 8{
            DllCall( "FlashWindow", UInt,temp_hwnd, Int,True )
            Sleep 250
         }
         DllCall( "FlashWindow", UInt,temp_hwnd, Int,False )
      }
      if (CastSpell_IfBlank = 1){
         GuiControlGet, Spell_to_cast_name,,Spell_to_cast_name
         GuiControlGet, Spell_to_cast_count,,Spell_to_cast_count
         cast(client_id,Spell_to_cast_name)
         temp_count = 1
        ; emergency_spellcaster_blank:
         while (Spell_to_cast_count - temp_count > 0){
            sleep_random(2000,2200)
            cast(client_id,Spell_to_cast_name)
            temp_count = % temp_count + 1
        ;    goto, emergency_spellcaster_blank
         }
      }
      
      return 1
   }
   if (type = "Soul"){
      GuiControlGet, PauseRunemaking_IfSoul,,PauseRunemaking_IfSoul
      GuiControlGet, Logout_IfSoul,,Logout_IfSoul
      GuiControlGet, PlaySound_IfSoul,,PlaySound_IfSoul
      GuiControlGet, ShutDown_IfSoul,,ShutDown_IfSoul
      GuiControlGet, WalkMethod_IfSoul,,WalkMethod_IfSoul
      GuiControlGet, Flash_IfSoul,,Flash_IfSoul
      notification(0, client_id, "Bot recognized lack of soul points.")
      if (Logout_IfSoul = 1){
         logout(client_id)
      }
      if (WalkMethod_IfSoul != "off"){
            walk(client_id, WalkMethod_IfSoul, steps_to_walk)
      }
      if (PlaySound_IfSoul = 1){
         sound("Data/Sounds/alarm_soul.mp3")
      }
      if (ShutDown_IfSoul = 1){
         shutdown()
      }
      if (PauseRunemaking_IfSoul = 1){
         if ((Double_alarm_screen_checker = 1) and (mc_count = 2)){
            GuiControl,, Enabled_runemaking1,0
            GuiControl,, Enabled_anty_logout1,0
            GuiControl,, Enabled_food_eater1,0
            GuiControl,, Fishing_enabled1,0
            GuiControl,, Enabled_runemaking2,0
            GuiControl,, Enabled_anty_logout2,0
            GuiControl,, Enabled_food_eater2,0
            GuiControl,, Fishing_enabled2,0
            Check_gui()
         }
         else{
            GuiControl,, Enabled_runemaking%client_number%, 0
            GuiControl,, Enabled_runemaking%client_number%,0
            GuiControl,, Enabled_anty_logout%client_number%,0
            GuiControl,, Enabled_food_eater%client_number%,0
            GuiControl,, Fishing_enabled%client_number%,0
            Check_gui()
         }
      }
      if (Flash_IfSoul = 1){
         if (transparent_tibia%client_number% = 1)
            gosub, hide_client_%client_number%
         else
            WinActivate, %client_id%
         Winget, temp_hwnd, ID, %client_id%
         Loop 8{
            DllCall( "FlashWindow", UInt,temp_hwnd, Int,True )
            Sleep 250
         }
         DllCall( "FlashWindow", UInt,temp_hwnd, Int,False )
      }
      if (CastSpell_IfSoul = 1){
         GuiControlGet, Spell_to_cast_name,,Spell_to_cast_name
         GuiControlGet, Spell_to_cast_count,,Spell_to_cast_count
         cast(client_id,Spell_to_cast_name)
         temp_count = 1
    ;     emergency_spellcaster_soul:
         while (Spell_to_cast_count - temp_count > 0){
            sleep_random(2000,2200)
            cast(client_id,Spell_to_cast_name)
            temp_count = % temp_count + 1
       ;     goto, emergency_spellcaster_soul
         }
      }
   }
}
return


cast(client_id, key){                          ;  don't need window to be active
   ControlSend,,{%key%}, %client_id%
}
return


say(client_id,text){                          ;  don't need window to be active
   BlockInput, On
   ControlSend,,{enter}, %client_id%
   ControlSend,, %text%, %client_id%
   sleep_random(70,150)
   ControlSend,, {Enter}, %client_id%
   BlockInput, Off
}
return

eat_food(client_id){
   GuiControlGet, Enabled_runemaking1,, Enabled_runemaking1
   GuiControlGet, Enabled_runemaking2,, Enabled_runemaking2
   GuiControlGet, eat_using_hotkey,, eat_using_hotkey
   GuiControlGet, eat_hotkey,, eat_hotkey
   GuiControlGet, food_time,, food_time
;   if (((client_id = title_tibia1) and (Enabled_runemaking1 = 0)) or ((client_id = title_tibia2) and (Enabled_runemaking2 = 0)))
 ;     return
   if (eat_using_hotkey = 1){
      cast(client_id, eat_hotkey)
      sleep_random(500, 800)
      cast(client_id, eat_hotkey)
      sleep_random(500, 800)
      cast(client_id, eat_hotkey)
      sleep_random(500, 800)
      return
   }
   else{
      sleep_random(50,100)
      if (find(client_id, "food1", "inventory", 1, 0) = 1){
         use(client_id, "food1")
         sleep_random(200,500)
         use(client_id, "food1")
         sleep_random(200,500)
         use(client_id, "food1")
         sleep_random(200,500)
      }
      else if (find(client_id, "food2", "inventory", 1, 0) = 1){
         use(client_id, "food2")
         sleep_random(200,500)
         use(client_id, "food2")
         sleep_random(200,500)
         use(client_id, "food2")
         sleep_random(200,500)
      }
      else if (find(client_id, "fish", "inventory", 1, 0) = 1){
         use(client_id, "fish")
         sleep_random(200,500)
         use(client_id, "fish")
         sleep_random(200,500)
         use(client_id, "fish")
         sleep_random(200,500)
      }
      else
         alarm(client_id, "food")
   }
}
return



anty_logout(client_id){                       ;  don't need window to be active
   GuiControlGet, Enabled_anty_logout1,, Enabled_anty_logout1
   GuiControlGet, Enabled_anty_logout2,, Enabled_anty_logout2
   GuiControlGet, Anty_log_dir1,, Anty_log_dir1
   GuiControlGet, Anty_log_dir2,, Anty_log_dir2
   if (((client_id = title_tibia1) and (Enabled_anty_logout1 = 0)) or ((client_id = title_tibia2) and (Enabled_anty_logout2 = 0)))
      return
   GuiControlGet, anty_log,,anty_log
   if anty_log = 0
      return
   if (((Anty_log_dir1 != "") and (Anty_log_dir2 != "")) and (Anty_log_dir1 != Anty_log_dir2)){
      if Anty_log_dir1 = n
         direction1 = up
      if Anty_log_dir1 = e
         direction1 = right
      if Anty_log_dir1 = s
         direction1 = down
      if Anty_log_dir1 = w
         direction1 = left
      if Anty_log_dir2 = n
         direction2 = up
      if Anty_log_dir2 = e
         direction2 = right
      if Anty_log_dir2 = s
         direction2 = down
      if Anty_log_dir2 = w
         direction2 = left
   }
   else{
      direction1 = up
      direction2 = down
   }
   KeyWait, Up
   KeyWait, Down
   KeyWait, Right
   KeyWait, Left
   BlockInput, On
   sleep_random(15,30)
   ControlSend,, {Ctrl down}, %client_id%
   sleep_random(45,70)
   ControlSend,, {%direction1%}, %client_id%
   sleep_random(15,30)
   ControlSend,, {Ctrl up}, %client_id%
   BlockInput, Off
   sleep_random(500,900)
   KeyWait, Up
   KeyWait, Down
   KeyWait, Right
   KeyWait, Left
   BlockInput, On
   sleep_random(15,30)
   ControlSend,, {Ctrl down}, %client_id%
   sleep_random(45,70)
   ControlSend,, {%direction2%}, %client_id%
   sleep_random(15,30)
   ControlSend,, {Ctrl up}, %client_id%
   BlockInput, Off
   sleep_random(500,900)
}
return

move(client_id,object,destination){
   IfWinNotExist, %client_id%
   {
      notification(2, client_id, "Window " . client_id . " doesn't exist.")
      return
      
   }
   global item_pos_x
   global item_pos_y  
   Random, random_pos_x, -randomization, randomization
   Random, random_pos_y, -randomization, randomization
   sleep 10
   if (object = "hand"){
      GuiControlGet, hand_slot_pos_x,, hand_slot_pos_x
      GuiControlGet, hand_slot_pos_y,, hand_slot_pos_y
      object_pos_x := hand_slot_pos_x + random_pos_x
      object_pos_y := hand_slot_pos_y + random_pos_y
   }
   else{
      find(client_id, object, "inventory", 1, 1)
      object_pos_x := item_pos_x + random_pos_x
      object_pos_y := item_pos_y + random_pos_y
   }
   if (destination = "house"){
      IfInString, client_id, Game client 1             
         client_number := 1
      else
         client_number := 2
      GuiControlGet, house_pos_x,, house_pos_x%client_number%
      GuiControlGet, house_pos_y,, house_pos_y%client_number%
      destination_pos_x := house_pos_x + random_pos_x
      destination_pos_y := house_pos_y + random_pos_y
   }
   if (destination = "hand"){
      GuiControlGet, hand_slot_pos_x,, hand_slot_pos_x
      GuiControlGet, hand_slot_pos_y,, hand_slot_pos_y
      destination_pos_x := hand_slot_pos_x + random_pos_x
      destination_pos_y := hand_slot_pos_y + random_pos_y
   }
   if (destination = "free_slot"){
      find(client_id, "free_slot", "inventory", 1, 1)
      destination_pos_x := item_pos_x + random_pos_x
      destination_pos_y := item_pos_y + random_pos_y
   }
   if ((object_pos_x != "") and (object_pos_y != "") and (destination_pos_x != "") and (destination_pos_y != "")){
      object_pos_y := object_pos_y - 25
      destination_pos_y := destination_pos_y - 25
      KeyWait, LButton
      KeyWait, RButton
      BlockInput, MouseMove
      Hotkey, LButton, do_nothing, On
      Hotkey, RButton, do_nothing, On
      sleep_random(5, 10)
      if (Bot_protection = 1)
         DllCall("Data\mousehook64.dll\dragDrop", "AStr", client_id, "INT", false, "INT", object_pos_x, "INT", object_pos_y, "INT", destination_pos_x, "INT", destination_pos_y)
      else
         DllCall("Data\mousehook64.dll\dragDrop", "AStr", client_id, "INT", true, "INT", object_pos_x, "INT", object_pos_y, "INT", destination_pos_x, "INT", destination_pos_y)
      sleep_random(5, 10)
      Hotkey, LButton, do_nothing, Off
      Hotkey, RButton, do_nothing, Off
      BlockInput, MouseMoveOff
      Sleep_random(150, 180)
   }
   else
      notification(1, client_id, "There was a problem with position in function move()")
}
return

do_nothing:
return


use(client_id, object){
   IfWinNotExist, %client_id%
   {
       notification(2, client_id, "Window " . client_id . " doesn't exist.")
      return
   }
   global item_pos_x
   global item_pos_y
   if ((object = "blank_rune") or (object = "conjured_rune1") or (object = "conjured_rune2") or (object = "free_slot") or (object = "food1") or (object = "food2") or (object = "backpack1") or (object = "backpack2")){
      region = "inventory"
   }
   else
      region = "screen"
   find(client_id, object, region, 1, 0)
   if ((item_pos_x != "") and (item_pos_y != "")){
      KeyWait, LButton
      KeyWait, RButton
      BlockInput, Mouse
      Hotkey, LButton, do_nothing, On
      Hotkey, RButton, do_nothing, On
;      Sleep_random(40, 60)
      item_pos_y := item_pos_y - 35
      DllCall("Data\mousehook64.dll\RightClick", "AStr", client_id, "INT", item_pos_x, "INT", item_pos_y)
      Sleep_random(150, 180)
      Hotkey, LButton, do_nothing, Off
      Hotkey, RButton, do_nothing, Off
      BlockInput, Off
   }
   else
      notification(1, client_id, "There was a problem in use " . object . " on position x(empty) y(empty).")
}
return



logout(client_id){
   GuiControlGet, Double_alarm_screen_checker,,Double_alarm_screen_checker
   global mc_count
   if ((Double_alarm_screen_checker == 1) and (mc_count == 2)){
      BlockInput, On
      ControlSend,, {Ctrl down}{l}{Ctrl up}, %title_tibia1%
      ControlSend,, {Ctrl down}{l}{Ctrl up}, %title_tibia2%
      ControlSend,, {Ctrl down}{l}{Ctrl up}, %title_tibia1%
      ControlSend,, {Ctrl down}{l}{Ctrl up}, %title_tibia2%
      ControlSend,, {Ctrl down}{l}{Ctrl up}, %title_tibia1%
      ControlSend,, {Ctrl down}{l}{Ctrl up}, %title_tibia2%
      ControlSend,, {Ctrl down}{l}{Ctrl up}, %title_tibia1%
      ControlSend,, {Ctrl down}{l}{Ctrl up}, %title_tibia2%
      BlockInput, Off
   }
   else{
      BlockInput, On
      ControlSend,, {Ctrl down}{l}{Ctrl up}, %client_id%
      ControlSend,, {Ctrl down}{l}{Ctrl up}, %client_id%
      ControlSend,, {Ctrl down}{l}{Ctrl up}, %client_id%
      BlockInput, Off
   }
   ; msgbox, %Double_alarm_screen_checker%, %mc_count%, %title_tibia1%, %title_tibia2%, %client_id%
}


return


sound(file_dir){
   SoundPlay, %file_dir%
}
return


walk(client_id, walk_dir, steps){
   local i := 0
   IniRead, mc_count, Data/basic_settings.ini, initialization data, last_used_mc_count
   GuiControlGet, Double_alarm_screen_checker,,Double_alarm_screen_checker
   
   if walk_dir = North
      arrow_to_press := "Up"
   else if walk_dir = East
      arrow_to_press := "Right"
   else if walk_dir = West
      arrow_to_press := "Left"
   else
      arrow_to_press := "Down"
   
  ; walk_label:                                    
   while (i < steps){
      if ((Double_alarm_screen_checker = 1) and (mc_count = 2)){
         ControlSend,,{%arrow_to_press%}, %title_tibia1%
         sleep_random(90,100)
         ControlSend,,{%arrow_to_press%}, %title_tibia2%
      }
      else
         ControlSend,,{%arrow_to_press%}, %client_id%
      sleep_random(200, 250)
      i++
 ;     goto, walk_label
   }
}

return

shutdown(){
 ;  pause("on", 1)
   shutdown, 1 ; Temporarly 1, in final version should be 4+1 = 5   (1 - shutdown, 4 - force)
}
return


sleep_random(min, max){
   random, delay, %min%, %max%
   sleep, %delay%
}
return

pause(){ 
   global paused
   if (paused = 0){
      GuiControlGet, rm1,, Enabled_runemaking1
      GuiControlGet, al1,, Enabled_anty_logout1
      GuiControlGet, fe1,, Enabled_food_eater1
      GuiControlGet, fi1,, Fishing_enabled1
      GuiControlGet, a1,, Alarms_enabled1
      GuiControlGet, rm2,, Enabled_runemaking2
      GuiControlGet, al2,, Enabled_anty_logout2
      GuiControlGet, fe2,, Enabled_food_eater2
      GuiControlGet, fi2,, Fishing_enabled2
      GuiControlGet, a2,, Alarms_enabled2
      GuiControl,, Enabled_runemaking1,0
      GuiControl,, Enabled_anty_logout1,0
      GuiControl,, Enabled_food_eater1,0
      GuiControl,, Fishing_enabled1,0
      GuiControl,, Alarms_enabled1,0
      GuiControl,, Enabled_runemaking2,0
      GuiControl,, Enabled_anty_logout2,0
      GuiControl,, Enabled_food_eater2,0
      GuiControl,, Fishing_enabled2,0
      GuiControl,, Alarms_enabled2,0
      GuiControl,Disabled, Enabled_runemaking1
      GuiControl,Disabled, Enabled_anty_logout1
      GuiControl,Disabled, Enabled_food_eater1
      GuiControl,Disabled, Fishing_enabled1
      GuiControl,Disabled, Alarms_enabled1
      GuiControl,Disabled, Enabled_runemaking2
      GuiControl,Disabled, Enabled_anty_logout2
      GuiControl,Disabled, Enabled_food_eater2
      GuiControl,Disabled, Fishing_enabled2
      GuiControl,Disabled, Alarms_enabled2
      WinSetTitle, ahk_id %MainBotWindow%,,Warlock Bot - paused
      paused := 1
   }
   else{
      GuiControl,, Enabled_runemaking1,%rm1%
      GuiControl,, Enabled_anty_logout1,%al1%
      GuiControl,, Enabled_food_eater1,%fe1%
      GuiControl,, Fishing_enabled1,%fi1%
      GuiControl,, Alarms_enabled1,%a1%
      GuiControl,, Enabled_runemaking2,%rm2%
      GuiControl,, Enabled_anty_logout2,%al2%
      GuiControl,, Enabled_food_eater2,%fe2%
      GuiControl,, Fishing_enabled2,%fi2%
      GuiControl,, Alarms_enabled2,%a2%
      GuiControl,Enabled, Enabled_runemaking1
      GuiControl,Enabled, Enabled_anty_logout1
      GuiControl,Enabled, Enabled_food_eater1
      GuiControl,Enabled, Fishing_enabled1
      GuiControl,Enabled, Alarms_enabled1
      GuiControl,Enabled, Enabled_runemaking2
      GuiControl,Enabled, Enabled_anty_logout2
      GuiControl,Enabled, Enabled_food_eater2
      GuiControl,Enabled, Fishing_enabled2
      GuiControl,Enabled, Alarms_enabled2
      WinSetTitle, ahk_id %MainBotWindow%,,Warlock Bot
      paused := 0
   } 
   GuiControlGet, Spelltime1,, Spelltime1
   GuiControlGet, Spelltime2,, Spelltime2
   if ((A_TickCount - planned_time1) > Spelltime1*1000){
      global planned_time1 := % A_TickCount + 1000
   }
   if ((A_TickCount - planned_time2) > Spelltime2*1000){
      global planned_time2 := % A_TickCount + 4000
   }
}
return


notification(emergency_level, client_id, text){
   if emergency_level < 0
      return
   GuiControlGet, show_notifications,, show_notifications
   if ((show_notifications = "always") or (show_notifications = "only important" and emergency_level >= 1) or (show_notifications = "never" and emergency_level = 2)){
      global old_text
      global notification_isbeing_show
      if (notification_isbeing_show = 1) and (old_text != text)
         TrayTip, %client_id%, %old_text%`n%text%
      else
         TrayTip, %client_id%, %text%
      SetTimer, RemoveTrayTip, 4500
      global notification_isbeing_show := 1
      global old_text := text
   }
}
return

RemoveTrayTip:
SetTimer, RemoveTrayTip, Off
global notification_isbeing_show := 0
global old_text := ""
TrayTip
return


find(client_id, object, region, center, notification){
   IfWinNotExist, %client_id%
      {
         notification(2, client_id, "Window " . client_id . " doesn't exist.")
         return
      }
   global image_name := A_WorkingDir . "\Data\Images\" . object . ".bmp"
   if ( region = "inventory" ){
      start_x := 0 ; % 3*A_ScreenWidth/4
      start_y := 0
      end_x := 0
      end_y := 0
   }
   else if ( region = "hand_slot" ){
      GuiControlGet, hand_slot_pos_x,, hand_slot_pos_x
      GuiControlGet, hand_slot_pos_y,, hand_slot_pos_y
      start_x := % hand_slot_pos_x - 20
      start_y := % hand_slot_pos_y - 20
      end_x := % hand_slot_pos_x + 30
      end_y := % hand_slot_pos_y + 30
   }
   else{
      start_x := 0
      start_y := 0
      end_x := 0
      end_y := 0
   }
   CoordMode, Mouse, Screen 
   WinGet, client_HWND, ID, %client_id%
   bmpArea := Gdip_BitmapFromHWND(client_HWND)
   bmpObject := Gdip_CreateBitmapFromFile(image_name)
   RET := Gdip_ImageSearch(bmpArea,bmpObject, OutputList, start_x, start_y, 0, 0) ;, start_x, start_y, end_x, end_y)
   Gdip_DisposeImage(bmpObject)
   Gdip_DisposeImage(bmpArea)
   Sleep, 150
   if (RET != 1){
      notification(notification, client_id, "Couldn't find " . object . " on " . region . ". (Ret: " . RET ")")
      global item_pos_x := ""
      global item_pos_y := ""
      ; msgbox,,Test board, RET: %RET%,`n object: %object%,`n region: %region%,`n OutputList: %OutputList%,`n object_pos_x: %object_pos_x%,`n object_pos_y: %object_pos_y%,`n item_pos_x: %item_pos_x%,`n item_pos_y: %item_pos_y%
      return 0
   }
   else{
      sleep, 100
      StringGetPos, Comma_pos, OutputList, `,
      StringLen, OutputLen, OutputList
      Comma_pos_y := Comma_pos + 1
      Comma_pos_x := OutputLen - Comma_pos
      StringTrimRight, object_pos_x, OutputList, Comma_pos_x 
      StringTrimLeft, object_pos_y, OutputList, Comma_pos_y
      global item_pos_x := object_pos_x
      global item_pos_y := object_pos_y
      if ( region = "hand_slot" and ((item_pos_x > end_x) or (item_pos_y > end_y))){
         notification(notification, client_id, "Couldn't find " . object . " on " . region . ".")
         global item_pos_x := ""
         global item_pos_y := ""
         ; msgbox,,Test board, RET: %RET%,`n object: %object%,`n region: %region%,`n OutputList: %OutputList%,`n object_pos_x: %object_pos_x%,`n object_pos_y: %object_pos_y%,`n item_pos_x: %item_pos_x%,`n item_pos_y: %item_pos_y%
      return 0
      }
      if (center = 1){                                    
         pBM := Gdip_CreateBitmapFromFile( image_name )                 
         image_width := Gdip_GetImageWidth( pBM )
         image_height := Gdip_GetImageHeight( pBM )   
         Gdip_DisposeImage( pBM )                                          
         global item_pos_x := % Round(object_pos_x + image_width/2)
         global item_pos_y := % Round(object_pos_y + image_height/2)
      }
      ; msgbox,,Test board, RET: %RET%,`n object: %object%,`n region: %region%,`n OutputList: %OutputList%,`n object_pos_x: %object_pos_x%,`n object_pos_y: %object_pos_y%,`n item_pos_x: %item_pos_x%,`n item_pos_y: %item_pos_y%
      return 1
   }
}
return



find_instances(client_id, object, notification, return_list := 0){
   IfWinNotExist, %client_id%
      {
         notification(notification, client_id, "Window " . client_id . " doesn't exist.")
         return
      }
   global image_name := A_WorkingDir . "\Data\Images\" . object . ".bmp"
   CoordMode, Mouse, Screen 
   WinGet, client_HWND, ID, %client_id%
   bmpArea := Gdip_BitmapFromHWND(client_HWND)
   bmpObject := Gdip_CreateBitmapFromFile(image_name)
   RET := Gdip_ImageSearch(bmpArea,bmpObject,OutputList, 0, 0, 0, 0,,,,0) 
   Gdip_DisposeImage(bmpObject)
   Gdip_DisposeImage(bmpArea)
   Sleep, 150
   if (RET > 200 or RET < 0){
      notification(1, client_id, "Couldn't find count of instances of" . object . " on " . region . ". (Ret: " . RET ")")
      return 0
   }
   if (return_list)
      return OutputList
   else
      return RET
}




take_screenshot(filename, width, height){
   global screenshooter_active
   if screenshooter_active = 1
      return
   screenshooter_active = 1
   global img_filename := filename
   global img_width := width
   global img_height := height
   Gui, Screenshoot_window: Show, AutoSize xCenter yCenter
   text := "Take screenshoot of " . img_filename 
   GuiControl,Screenshoot_window:, Text_to_display, %text%
   CoordMode, Mouse, Screen 
   MouseGetPos, actual_pos_x, actual_pos_y
   actual_pos_x = % actual_pos_x - img_width/2
   actual_pos_y = % actual_pos_y - img_height/2
   Gui, screen_box: Show, w%img_width% h%img_height% x%actual_pos_x% y%actual_pos_y% NoActivate, ScreenBoxID
   sleep, 20
   SetTimer, move_box, 50
;   Winget, winstatus_MainBotWindow, minmax, ahk_id %MainBotWindow%
;   if winstatus_MainBotWindow != -1
      WinMinimize, ahk_id %MainBotWindow%
   Hotkey, LButton, take_screen_shot, On
   Hotkey, Esc, take_screen_shot_off, On
}
return

move_box:
   MouseGetPos, even_more_actual_pos_x, even_more_actual_pos_y
   even_more_actual_pos_x = % even_more_actual_pos_x - img_width/2
   even_more_actual_pos_y = % even_more_actual_pos_y - img_height/2
   WinMove, ScreenBoxID,, %even_more_actual_pos_x%, %even_more_actual_pos_y%
return

take_screen_shot:
   CoordMode, Mouse, Screen 
   MouseGetPos, ss_x, ss_y
   ess_x := % ss_x - img_width/2  + 1
   ess_y := % ss_y - img_height/2  + 1
   Hotkey, LButton, take_screen_shot, Off
   SetTimer, move_box, Off
   Gui, screen_box: Cancel
   outfile := "Data\Images\" . img_filename . ".bmp"
   pic_name := "pic_" . img_filename
   Area := ess_x "|" ess_y "|" img_width "|" img_height
   pToken := Gdip_Startup()
   pBitmap := Gdip_BitmapFromScreen(Area)
   Gdip_SaveBitmapToFile(pBitmap, outfile, 100)
   Gdip_DisposeImage(pBitmap)
   ; Gdip_Shutdown(pToken)
   Gui, Screenshoot_window: Hide
   WinActivate, ahk_id %MainBotWindow%
   notification(0, "Succes!", "Item saved as " . outfile . ".")
   if (img_filename = "area_check1"){
      global area_start_x1 := round(ess_x)
      global area_start_y1 := round(ess_y)
      GuiControl,, Image_screen_checker1, %outfile%
      global sc_temp_img_dir1 = % outfile
      bmparea_check1 := Gdip_CreateBitmapFromFile(outfile)
   }
   else if (img_filename = "area_check2"){
      global area_start_x2 := round(ess_x)
      global area_start_y2 := round(ess_y)
      GuiControl,, Image_screen_checker2, %outfile%
      global sc_temp_img_dir2 = % outfile
      bmparea_check2 := Gdip_CreateBitmapFromFile(outfile)
   }
   else if (img_filename = "fishing_rod"){
      GuiControl, Fishing_gui1:, fishing_rod1, %outfile%
      GuiControl, Fishing_gui2:, fishing_rod2, %outfile%
   }
   else if (img_filename = "fish"){
      GuiControl, Fishing_gui1:, fish1, %outfile%
      GuiControl, Fishing_gui2:, fish2, %outfile%
   }
   else
      GuiControl,, %img_filename%, %outfile%
   global screenshooter_active := 0
return

take_screen_shot_off:
   Hotkey, LButton, take_screen_shot, Off
   Hotkey, Esc, take_screen_shot_off, Off
   Gui, Screenshoot_window: Hide
   Gui, screen_box: Cancel
   SetTimer, move_box, Off
   if (img_filename != "fishing_rod") and (img_filename != "fish")
      WinActivate, ahk_id %MainBotWindow%
   global screenshooter_active := 0
return

Take_image_fishing_rod1:
   take_screenshot("fishing_rod", 28, 28)
return
Take_image_fishing_rod2:
   take_screenshot("fishing_rod", 28, 28)
return
Take_image_fish1:
   take_screenshot("fish", 10, 10)
return
Take_image_fish2:
   take_screenshot("fish", 10, 10)
return
Take_image_conjured_rune1:
   take_screenshot("conjured_rune1", 28, 28)
return
Take_image_conjured_rune2:
   take_screenshot("conjured_rune2", 28, 28)
return
Take_image_backpack1:
   take_screenshot("backpack1", 28, 28)
return
Take_image_backpack2:
   take_screenshot("backpack2", 28, 28)
return
Take_image_food1:
   take_screenshot("food1", 10, 10)
return
Take_image_food2:
   take_screenshot("food2", 10, 10)
return
Take_image_blank_rune:
   take_screenshot("blank_rune", 28, 28)
return
Take_image_free_slot:
   take_screenshot("free_slot", 32, 32)         ; 38 prev iously
return

getpos_hand_slot:
   IfWinNotExist, ahk_pid %pid_tibia1%
      {
         IfWinNotExist, ahk_pid %pid_tibia2%
            {
            notification(1,"Get hand slot position tool", "None of clients does work.")
            return
         }
         else{
            if (transparent_tibia2 = 1)
               gosub, hide_client_2
            WinMinimize, ahk_id %MainBotWindow%
            WinActivate, ahk_pid %pid_tibia2%
            WinWait, ahk_pid %pid_tibia2% 
            SetSystemCursor("IDC_CROSS")
            Hotkey, LButton, mouse_getpos_hand_slot, on
            return
         }
   }
   if (transparent_tibia1 = 1)
      gosub, hide_client_1
   WinMinimize, ahk_id %MainBotWindow%
   WinActivate, ahk_pid %pid_tibia1%
   WinWait, ahk_pid %pid_tibia1% 
   SetSystemCursor("IDC_CROSS")
   Hotkey, LButton, mouse_getpos_hand_slot, on
return

mouse_getpos_hand_slot:
   MouseGetPos, hand_slot_pos_x, hand_slot_pos_y
   Hotkey, LButton, mouse_getpos_hand_slot, Off
   WinActivate, ahk_id %MainBotWindow%
   RestoreCursors()
   if (hand_slot_pos_x > 1) and (hand_slot_pos_x < A_ScreenWidth) and (hand_slot_pos_y > 50) and (hand_slot_pos_y < A_Screenheight){
      GuiControl,, hand_slot_pos_x, %hand_slot_pos_x%
      GuiControl,, hand_slot_pos_y, %hand_slot_pos_y%
   }
   else{
      notification(1,"Get hand slot position tool", "Coordinates are not valid.")
   }
return

getpos_house_1:
   IfWinNotExist, ahk_pid %pid_tibia1%
      {
         notification(1, client_id, "Window " . title_tibia1 . " doesn't exist.")
         return
      }
   if (transparent_tibia1 = 1)
      gosub, hide_client_1
   WinMinimize, ahk_id %MainBotWindow%
   WinActivate, ahk_pid %pid_tibia1%
   WinWait, ahk_pid %pid_tibia1% 
   SetSystemCursor("IDC_CROSS")
   Hotkey, LButton, mouse_getpos_house_1, on
return

mouse_getpos_house_1:
   MouseGetPos, house_pos_x1, house_pos_y1
   Hotkey, LButton, mouse_getpos_house_1, Off
   GuiControl,, house_pos_x1, %house_pos_x1%
   GuiControl,, house_pos_y1, %house_pos_y1%
   WinActivate, ahk_id %MainBotWindow%
   RestoreCursors()
return

getpos_house_2:
   IfWinNotExist, ahk_pid %pid_tibia2%
      {
         notification(1, client_id, "Window " . title_tibia2 . " doesn't exist.")
         return
      }
   if (transparent_tibia2 = 1)
      gosub, hide_client_2
   WinMinimize, ahk_id %MainBotWindow%
   WinActivate, ahk_pid %pid_tibia2%
   WinWait, ahk_pid %pid_tibia2% 
   SetSystemCursor("IDC_CROSS")
   Hotkey, LButton, mouse_getpos_house_2, on
return

mouse_getpos_house_2:
   MouseGetPos, house_pos_x2, house_pos_y2
   Hotkey, LButton, mouse_getpos_house_2, Off
   GuiControl,, house_pos_x2, %house_pos_x2%
   GuiControl,, house_pos_y2, %house_pos_y2%
   WinActivate, ahk_id %MainBotWindow%
   RestoreCursors()
return

RestoreCursors()
{
   SPI_SETCURSORS := 0x57
   DllCall( "SystemParametersInfo", UInt,SPI_SETCURSORS, UInt,0, UInt,0, UInt,0 )
}
return


SetSystemCursor( Cursor = "", cx = 0, cy = 0 )
{
   BlankCursor := 0, SystemCursor := 0, FileCursor := 0 ; init
   
   SystemCursors = 32512IDC_ARROW,32513IDC_IBEAM,32514IDC_WAIT,32515IDC_CROSS
   ,32516IDC_UPARROW,32640IDC_SIZE,32641IDC_ICON,32642IDC_SIZENWSE
   ,32643IDC_SIZENESW,32644IDC_SIZEWE,32645IDC_SIZENS,32646IDC_SIZEALL
   ,32648IDC_NO,32649IDC_HAND,32650IDC_APPSTARTING,32651IDC_HELP
   
   If Cursor = ; empty, so create blank cursor 
   {
      VarSetCapacity( AndMask, 32*4, 0xFF ), VarSetCapacity( XorMask, 32*4, 0 )
      BlankCursor = 1 ; flag for later
   }
   Else If SubStr( Cursor,1,4 ) = "IDC_" ; load system cursor
   {
      Loop, Parse, SystemCursors, `,
      {
         CursorName := SubStr( A_Loopfield, 6, 15 ) ; get the cursor name, no trailing space with substr
         CursorID := SubStr( A_Loopfield, 1, 5 ) ; get the cursor id
         SystemCursor = 1
         If ( CursorName = Cursor )
         {
            CursorHandle := DllCall( "LoadCursor", Uint,0, Int,CursorID )   
            Break               
         }
      }   
      If CursorHandle = ; invalid cursor name given
      {
         Msgbox,, SetCursor, Error: Invalid cursor name
         CursorHandle = Error
      }
   }   
   Else If FileExist( Cursor )
   {
      SplitPath, Cursor,,, Ext ; auto-detect type
      If Ext = ico 
         uType := 0x1   
      Else If Ext in cur,ani
         uType := 0x2      
      Else ; invalid file ext
      {
         Msgbox,, SetCursor, Error: Invalid file type
         CursorHandle = Error
      }      
      FileCursor = 1
   }
   Else
   {   
      Msgbox,, SetCursor, Error: Invalid file path or cursor name
      CursorHandle = Error ; raise for later
   }
   If CursorHandle != Error 
   {
      Loop, Parse, SystemCursors, `,
      {
         If BlankCursor = 1 
         {
            Type = BlankCursor
            %Type%%A_Index% := DllCall( "CreateCursor"
            , Uint,0, Int,0, Int,0, Int,32, Int,32, Uint,&AndMask, Uint,&XorMask )
            CursorHandle := DllCall( "CopyImage", Uint,%Type%%A_Index%, Uint,0x2, Int,0, Int,0, Int,0 )
            DllCall( "SetSystemCursor", Uint,CursorHandle, Int,SubStr( A_Loopfield, 1, 5 ) )
         }         
         Else If SystemCursor = 1
         {
            Type = SystemCursor
            CursorHandle := DllCall( "LoadCursor", Uint,0, Int,CursorID )   
            %Type%%A_Index% := DllCall( "CopyImage"
            , Uint,CursorHandle, Uint,0x2, Int,cx, Int,cy, Uint,0 )      
            CursorHandle := DllCall( "CopyImage", Uint,%Type%%A_Index%, Uint,0x2, Int,0, Int,0, Int,0 )
            DllCall( "SetSystemCursor", Uint,CursorHandle, Int,SubStr( A_Loopfield, 1, 5 ) )
         }
         Else If FileCursor = 1
         {
            Type = FileCursor
            %Type%%A_Index% := DllCall( "LoadImageA"
            , UInt,0, Str,Cursor, UInt,uType, Int,cx, Int,cy, UInt,0x10 ) 
            DllCall( "SetSystemCursor", Uint,%Type%%A_Index%, Int,SubStr( A_Loopfield, 1, 5 ) )         
         }          
      }
   }   
}
return

ConnectedToInternet(flag=0x40) { 
   Return DllCall("Wininet.dll\InternetGetConnectedState", "Str", flag,"Int",0) 
}


WM_MOUSEMOVE()
{
    static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
    CurrControl := A_GuiControl
    If (CurrControl <> PrevControl and not InStr(CurrControl, " "))
    {
        ToolTip  ; Turn off any previous tooltip.
        SetTimer, DisplayToolTip, 500
        PrevControl := CurrControl
    }
    return

    DisplayToolTip:
    SetTimer, DisplayToolTip, Off
    ToolTip % %CurrControl%_TT  ; The leading percent sign tell it to use an expression.
    SetTimer, RemoveToolTip, 10000
    return

    RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
    return
}



save(){

   GuiControlGet, rune_spellkey1,, rune_spellkey1
   GuiControlGet, rune_spellkey2,, rune_spellkey2
   GuiControlGet, Spelltime1,, Spelltime1
   GuiControlGet, Spelltime2,, Spelltime2

   GuiControlGet, deposit_runes_1,, deposit_runes_1
   GuiControlGet, house_pos_x1,, house_pos_x1
   GuiControlGet, house_pos_y1,, house_pos_y1
   GuiControlGet, deposit_runes_2,, deposit_runes_2
   GuiControlGet, house_pos_x2,, house_pos_x2
   GuiControlGet, house_pos_y2,, house_pos_y2

   GuiControlGet, PauseRunemaking_IfCharMoved,, PauseRunemaking_IfCharMoved
   GuiControlGet, PauseRunemaking_IfFood,, PauseRunemaking_IfFood
   GuiControlGet, PauseRunemaking_IfBlank,, PauseRunemaking_IfBlank
   GuiControlGet, PauseRunemaking_IfPlayer,, PauseRunemaking_IfPlayer
   GuiControlGet, PauseRunemaking_IfSoul,, PauseRunemaking_IfSoul

   GuiControlGet, Logout_IfCharMoved,, Logout_IfCharMoved
   GuiControlGet, Logout_IfFood,,  Logout_IfFood
   GuiControlGet, Logout_IfBlank,, Logout_IfBlank
   GuiControlGet, Logout_IfPlayer,, Logout_IfPlayer
   GuiControlGet, Logout_IfSoul,, Logout_IfSoul

   GuiControlGet, PlaySound_IfCharMoved,,  PlaySound_IfCharMoved
   GuiControlGet, PlaySound_IfFood,,  PlaySound_IfFood
   GuiControlGet, PlaySound_IfBlank,,  PlaySound_IfBlank
   GuiControlGet, PlaySound_IfPlayer,, PlaySound_IfPlayer
   GuiControlGet, PlaySound_IfSoul,,  PlaySound_IfSoul

   GuiControlGet, ShutDown_IfCharMoved,, ShutDown_IfCharMoved
   GuiControlGet, ShutDown_IfFood,, ShutDown_IfFood
   GuiControlGet, ShutDown_IfBlank,, ShutDown_IfBlank
   GuiControlGet, ShutDown_IfPlayer,, ShutDown_IfPlayer
   GuiControlGet, ShutDown_IfSoul,, ShutDown_IfSoul

   GuiControlGet, WalkMethod_IfFood,, WalkMethod_IfFood
   GuiControlGet, WalkMethod_IfBlank,, WalkMethod_IfBlank
   GuiControlGet, WalkMethod_IfPlayer,, WalkMethod_IfPlayer
   GuiControlGet, WalkMethod_IfSoul,, WalkMethod_IfSoul
   GuiControlGet, WalkMethod_IfCharMoved,, WalkMethod_IfCharMoved

   GuiControlGet, CastSpell_IfBlank,, CastSpell_IfBlank 
   GuiControlGet, CastSpell_IfSoul,, CastSpell_IfSoul 

   GuiControlGet, Flash_IfCharMoved,, Flash_IfCharMoved
   GuiControlGet, Flash_IfFood,, Flash_IfFood
   GuiControlGet, Flash_IfBlank,, Flash_IfBlank
   GuiControlGet, Flash_IfPlayer,, Flash_IfPlayer
   GuiControlGet, Flash_IfSoul,, Flash_IfSoul

   GuiControlGet, OpenNewBackpack,, OpenNewBackpack
   GuiControlGet, Create_blank,, Create_blank
   GuiControlGet, Hand_mode,, Hand_mode
   GuiControlGet, hand_slot_pos_x,, hand_slot_pos_x
   GuiControlGet, hand_slot_pos_y,, hand_slot_pos_y

   GuiControlGet, Spell_to_cast_name,, Spell_to_cast_name
   GuiControlGet, Spell_to_cast_count,, Spell_to_cast_count
   GuiControlGet, Double_alarm_screen_checker,, Double_alarm_screen_checker

   GuiControlGet, Blank_spellname,, Blank_spellname
   GuiControlGet, Eat_hotkey,, Eat_hotkey
   GuiControlGet, eat_using_hotkey,, eat_using_hotkey 
   GuiControlGet, Food_time,, Food_time
   GuiControlGet, Anty_log_time,, Anty_log_time
   GuiControlGet, Anty_log_dir1,, Anty_log_dir1
   GuiControlGet, Anty_log_dir2,, Anty_log_dir2
   GuiControlGet, Show_notifications,, Show_notifications
   GuiControlGet, Steps_to_walk,, Steps_to_walk
   GuiControlGet, Auto_shutdown_time,, Auto_shutdown_time
   
   
   
   IniWrite, %rune_spellkey1%, Data/basic_settings.ini, bot variables, rune_spellkey1
   IniWrite, %rune_spellkey2%, Data/basic_settings.ini, bot variables, rune_spellkey2
   IniWrite, %Spelltime1%, Data/basic_settings.ini, bot variables, Spelltime1
   IniWrite, %Spelltime2%, Data/basic_settings.ini, bot variables, Spelltime2

   IniWrite, %deposit_runes_1%, Data/basic_settings.ini, bot variables, deposit_runes_1
   IniWrite, %house_pos_x1%, Data/basic_settings.ini, bot variables, house_pos_x1
   IniWrite, %house_pos_y1%, Data/basic_settings.ini, bot variables, house_pos_y1
   IniWrite, %deposit_runes_2%, Data/basic_settings.ini, bot variables, deposit_runes_2
   IniWrite, %house_pos_x2%, Data/basic_settings.ini, bot variables, house_pos_x2
   IniWrite, %house_pos_y2%, Data/basic_settings.ini, bot variables, house_pos_y2

   IniWrite, %PauseRunemaking_IfCharMoved%, Data/basic_settings.ini, bot variables, PauseRunemaking_IfCharMoved
   IniWrite, %PauseRunemaking_IfFood%, Data/basic_settings.ini, bot variables, PauseRunemaking_IfFood
   IniWrite, %PauseRunemaking_IfBlank%, Data/basic_settings.ini, bot variables, PauseRunemaking_IfBlank
   IniWrite, %PauseRunemaking_IfPlayer%, Data/basic_settings.ini, bot variables, PauseRunemaking_IfPlayer
   IniWrite, %PauseRunemaking_IfSoul%, Data/basic_settings.ini, bot variables, PauseRunemaking_IfSoul

   IniWrite, %Logout_IfCharMoved%, Data/basic_settings.ini, bot variables, Logout_IfCharMoved
   IniWrite, %Logout_IfFood%, Data/basic_settings.ini, bot variables,  Logout_IfFood
   IniWrite, %Logout_IfBlank%, Data/basic_settings.ini, bot variables, Logout_IfBlank
   IniWrite, %Logout_IfPlayer%, Data/basic_settings.ini, bot variables, Logout_IfPlayer
   IniWrite, %Logout_IfSoul%, Data/basic_settings.ini, bot variables, Logout_IfSoul

   IniWrite, %PlaySound_IfCharMoved%, Data/basic_settings.ini, bot variables,  PlaySound_IfCharMoved
   IniWrite, %PlaySound_IfFood%, Data/basic_settings.ini, bot variables,  PlaySound_IfFood
   IniWrite, %PlaySound_IfBlank%, Data/basic_settings.ini, bot variables,  PlaySound_IfBlank
   IniWrite, %PlaySound_IfPlayer%, Data/basic_settings.ini, bot variables, PlaySound_IfPlayer
   IniWrite, %PlaySound_IfSoul%, Data/basic_settings.ini, bot variables,  PlaySound_IfSoul

   IniWrite, %ShutDown_IfCharMoved%, Data/basic_settings.ini, bot variables, ShutDown_IfCharMoved
   IniWrite, %ShutDown_IfFood%, Data/basic_settings.ini, bot variables, ShutDown_IfFood
   IniWrite, %ShutDown_IfBlank%, Data/basic_settings.ini, bot variables, ShutDown_IfBlank
   IniWrite, %ShutDown_IfPlayer%, Data/basic_settings.ini, bot variables, ShutDown_IfPlayer
   IniWrite, %ShutDown_IfSoul%, Data/basic_settings.ini, bot variables, ShutDown_IfSoul

   IniWrite, %WalkMethod_IfFood%, Data/basic_settings.ini, bot variables, WalkMethod_IfFood
   IniWrite, %WalkMethod_IfBlank%, Data/basic_settings.ini, bot variables, WalkMethod_IfBlank
   IniWrite, %WalkMethod_IfPlayer%, Data/basic_settings.ini, bot variables, WalkMethod_IfPlayer
   IniWrite, %WalkMethod_IfSoul%, Data/basic_settings.ini, bot variables, WalkMethod_IfSoul
   IniWrite, %WalkMethod_IfCharMoved%, Data/basic_settings.ini, bot variables, WalkMethod_IfCharMoved

   IniWrite, %CastSpell_IfBlank%, Data/basic_settings.ini, bot variables, CastSpell_IfBlank 
   IniWrite, %CastSpell_IfSoul%, Data/basic_settings.ini, bot variables, CastSpell_IfSoul 

   IniWrite, %Flash_IfCharMoved%, Data/basic_settings.ini, bot variables, Flash_IfCharMoved
   IniWrite, %Flash_IfFood%, Data/basic_settings.ini, bot variables, Flash_IfFood
   IniWrite, %Flash_IfBlank%, Data/basic_settings.ini, bot variables, Flash_IfBlank
   IniWrite, %Flash_IfPlayer%, Data/basic_settings.ini, bot variables, Flash_IfPlayer
   IniWrite, %Flash_IfSoul%, Data/basic_settings.ini, bot variables, Flash_IfSoul

   IniWrite, %OpenNewBackpack%, Data/basic_settings.ini, bot variables, OpenNewBackpack
   IniWrite, %Create_blank%, Data/basic_settings.ini, bot variables, Create_blank
   IniWrite, %Hand_mode%, Data/basic_settings.ini, bot variables, Hand_mode
   IniWrite, %hand_slot_pos_x%, Data/basic_settings.ini, bot variables, hand_slot_pos_x
   IniWrite, %hand_slot_pos_y%, Data/basic_settings.ini, bot variables, hand_slot_pos_y

   IniWrite, %Spell_to_cast_name%, Data/basic_settings.ini, bot variables, Spell_to_cast_name
   IniWrite, %Spell_to_cast_count%, Data/basic_settings.ini, bot variables, Spell_to_cast_count
   IniWrite, %Double_alarm_screen_checker%, Data/basic_settings.ini, bot variables, Double_alarm_screen_checker

   IniWrite, %Blank_spellname%, Data/basic_settings.ini, bot variables, Blank_spellname
   IniWrite, %Eat_hotkey%, Data/basic_settings.ini, bot variables, Eat_hotkey
   IniWrite, %eat_using_hotkey%, Data/basic_settings.ini, bot variables, eat_using_hotkey 
   IniWrite, %Food_time%, Data/basic_settings.ini, bot variables, Food_time
   IniWrite, %Anty_log_time%, Data/basic_settings.ini, bot variables, Anty_log_time
   IniWrite, %Anty_log_dir1%, Data/basic_settings.ini, bot variables, Anty_log_dir1
   IniWrite, %Anty_log_dir2%, Data/basic_settings.ini, bot variables, Anty_log_dir2
   IniWrite, %Show_notifications%, Data/basic_settings.ini, bot variables, Show_notifications
   IniWrite, %Steps_to_walk%, Data/basic_settings.ini, bot variables, Steps_to_walk
   IniWrite, %Auto_shutdown_time%, Data/basic_settings.ini, bot variables, Auto_shutdown_time 
}
return




 ; ######################################################### CHECKING VALUES ############################################################################

Installfiles:
DataFolder :=  A_ScriptDir . "\Data" 
IfNotExist, %DataFolder%
   FileCreateDir, %DataFolder%
ImgFolder :=  A_ScriptDir . "\Data\Images" 
IfNotExist, %ImgFolder%
   FileCreateDir, %ImgFolder%
SoundsFolder :=  A_ScriptDir . "\Data\Sounds" 
IfNotExist, %SoundsFolder%
   FileCreateDir, %SoundsFolder%

FileInstall, Data\Images\area_check1.bmp, Data\Images\area_check1.bmp
FileInstall, Data\Images\area_check2.bmp, Data\Images\area_check2.bmp
FileInstall, Data\Images\backpack1.bmp, Data\Images\backpack1.bmp
FileInstall, Data\Images\backpack2.bmp, Data\Images\backpack2.bmp
FileInstall, Data\Images\blank_rune.bmp, Data\Images\blank_rune.bmp
FileInstall, Data\Images\conjured_rune1.bmp, Data\Images\conjured_rune1.bmp
FileInstall, Data\Images\conjured_rune2.bmp, Data\Images\conjured_rune2.bmp
FileInstall, Data\Images\fishing_rod_bp.bmp, Data\Images\fishing_rod_bp.bmp
FileInstall, Data\Images\fish.bmp, Data\Images\fish.bmp
FileInstall, Data\Images\fishing_rod.bmp, Data\Images\fishing_rod.bmp
FileInstall, Data\Images\food1.bmp, Data\Images\food1.bmp
FileInstall, Data\Images\food2.bmp, Data\Images\food2.bmp
FileInstall, Data\Images\free_slot.bmp, Data\Images\free_slot.bmp
FileInstall, Data\Images\picbp.bmp, Data\Images\picbp.bmp
FileInstall, Data\Images\select_area1.png, Data\Images\select_area1.png
FileInstall, Data\Images\select_area2.png, Data\Images\select_area2.png
FileInstall, Data\Images\tabledone.png, Data\Images\tabledone.png
FileInstall, Data\Images\table_main_f.png, Data\Images\table_main_f.png
FileInstall, Data\Images\icon.ico, Data\Images\icon.ico
FileInstall, Data\Images\msinfo32.ico, Data\Images\msinfo32.ico
FileInstall, Data\Images\warlockbot_startwin.png, Data\Images\warlockbot_startwin.png
FileInstall, Data\Images\background.png, Data\Images\background.png
FileInstall, Data\Images\pp_donate.bmp, Data\Images\pp_donate.bmp
FileInstall, Data\Images\soul0.bmp, Data\Images\soul0.bmp
FileInstall, Data\Images\soul1.bmp, Data\Images\soul1.bmp
FileInstall, Data\Images\soul2.bmp, Data\Images\soul2.bmp
FileInstall, Data\Images\soul3.bmp, Data\Images\soul3.bmp
FileInstall, Data\Images\soul4.bmp, Data\Images\soul4.bmp
FileInstall, Data\Images\soul5.bmp, Data\Images\soul5.bmp

FileInstall, Data\Sounds\alarm_food.mp3, Data\Sounds\alarm_food.mp3
FileInstall, Data\Sounds\alarm_screen.mp3, Data\Sounds\alarm_screen.mp3
FileInstall, Data\Sounds\alarm_blank.mp3, Data\Sounds\alarm_blank.mp3
FileInstall, Data\Sounds\alarm_soul.mp3, Data\Sounds\alarm_soul.mp3

FileInstall, Data/basic_settings.ini, Data/basic_settings.ini
FileInstall, Data/mousehook64.dll, Data/mousehook64.dll
FileInstall, Data/scp_wrlbot.exe, Data/scp_wrlbot.exe

goto checkfiles
return

Bot_protection:
GuiControlGet, Bot_protection,, Bot_protection
if Bot_protection = 1
   global Bot_protection = 1
else
   global Bot_protection = 0
return

Check_gui(){                                    ; it grays out gui controls
   GuiControlGet, Enabled_runemaking1,, Enabled_runemaking1
   GuiControlGet, Enabled_runemaking2,, Enabled_runemaking2
   GuiControl, disable%Enabled_runemaking1%, Spelltime1
   GuiControl, disable%Enabled_runemaking1%, rune_spellkey1
   GuiControl, disable%Enabled_runemaking2%, Spelltime2
   GuiControl, disable%Enabled_runemaking2%, rune_spellkey2
   GuiControlGet, Enabled_anty_logout1,, Enabled_anty_logout1
   GuiControlGet, Enabled_anty_logout2,, Enabled_anty_logout2
   if ((Enabled_anty_logout1 = 1) or (Enabled_anty_logout2 = 1))
      GuiControl, Disabled, Anty_log_time
   else
      GuiControl, Enabled, Anty_log_time
   GuiControlGet, Enabled_food_eater1,, Enabled_food_eater1
   GuiControlGet, Enabled_food_eater2,, Enabled_food_eater2
   if ((Enabled_food_eater1 = 1) or (Enabled_food_eater2 = 1))
      GuiControl, Disabled, Food_time
   else
      GuiControl, Enabled, Food_time
   if ((Enabled_runemaking1 = 1) or (Enabled_runemaking2 = 1))
      check_var = 1
   else{
      BlockInput, Off
      check_var = 0
      SetTimer, check_runes, Off        ; the only one way to set timer off is by check_gui
   }
}
return

getRandomArrayValue1(arr,arrayChanged:=0){
	static ind1:=""
	if (arrayChanged || !ind1){
		ind1:=[]
		for k in arr
			ind1.push(k)
	}
	Random,num,1,ind1.length()
	return arr[ind1[num]]
}

getRandomArrayValue2(arr,arrayChanged:=0){
	static ind2:=""
	if (arrayChanged || !ind2){
		ind2:=[]
		for k in arr
			ind2.push(k)
	}
	Random,num,1,ind2.length()
	return arr[ind2[num]]
}

auto_stack(client_id, object){
	start_time := A_tickcount
	count1 := find_instances(client_id, object, 2, 0)
	stacker_loop1:
	if (count1 > 1){
	   list = % find_instances(client_id, object, 2, 1)
	   coords := ""
      coords := Object()
		for i, obj in strsplit(list, "`n")
			coords.push({x: strsplit(obj, ",").1, y: strsplit(obj, ",").2})
		object_pos_x := coords.1.x
		object_pos_y := coords.1.y
		destination_pos_x := coords.2.x ; + 14
		destination_pos_y := coords.2.y ; + 14
	   if ((object_pos_x != "") and (object_pos_y != "") and (destination_pos_x != "") and (destination_pos_y != "")){
		  object_pos_y := object_pos_y - 25
		  destination_pos_y := destination_pos_y - 25
		  KeyWait, LButton
		  KeyWait, RButton
		  BlockInput, MouseMove
		  Hotkey, LButton, do_nothing, On
		  Hotkey, RButton, do_nothing, On
		  sleep_random(5, 10)
		  if (Bot_protection = 1)
			 DllCall("Data\mousehook64.dll\dragDrop", "AStr", client_id, "INT", false, "INT", object_pos_x, "INT", object_pos_y, "INT", destination_pos_x, "INT", destination_pos_y)
		  else
			 DllCall("Data\mousehook64.dll\dragDrop", "AStr", client_id, "INT", true, "INT", object_pos_x, "INT", object_pos_y, "INT", destination_pos_x, "INT", destination_pos_y)
		  sleep_random(5, 10)
		  Hotkey, LButton, do_nothing, Off
		  Hotkey, RButton, do_nothing, Off
		  BlockInput, MouseMoveOff
		  Sleep_random(150, 180)
	   }
	   count2 := find_instances(client_id, object, 2, 0)
	   if (count2 < count1){
		  count1 := count2
		  goto stacker_loop1
	   }
	   else if ((count2 = count1) and (count2 > 2)){
		stacker_loop2:
		list = % find_instances(client_id, object, 2, 1)
		coords := ""
         coords := Object()
		for i, obj in strsplit(list, "`n")
			coords.push({x: strsplit(obj, ",").1, y: strsplit(obj, ",").2})
			object_pos_x := coords.1.x 
			object_pos_y := coords.1.y 
			destination_pos_x := coords.3.x 
			destination_pos_y := coords.3.y 
			if ((object_pos_x != "") and (object_pos_y != "") and (destination_pos_x != "") and (destination_pos_y != "")){
				object_pos_y := object_pos_y - 25
				destination_pos_y := destination_pos_y - 25
				KeyWait, LButton
				KeyWait, RButton
				BlockInput, MouseMove
				Hotkey, LButton, do_nothing, On
				Hotkey, RButton, do_nothing, On
				sleep_random(5, 10)
				if (Bot_protection = 1)
					DllCall("Data\mousehook64.dll\dragDrop", "AStr", client_id, "INT", false, "INT", object_pos_x, "INT", object_pos_y, "INT", destination_pos_x, "INT", destination_pos_y)
				else
					DllCall("Data\mousehook64.dll\dragDrop", "AStr", client_id, "INT", true, "INT", object_pos_x, "INT", object_pos_y, "INT", destination_pos_x, "INT", destination_pos_y)
				sleep_random(5, 10)
				Hotkey, LButton, do_nothing, Off
				Hotkey, RButton, do_nothing, Off
				BlockInput, MouseMoveOff
				Sleep_random(150, 180)
			}
			count3 := find_instances(client_id, object, 2, 0)
			if ((count3 < count2) and (count3 > 1)){
				count2 := count3
				count1 := count3
				goto stacker_loop1
			}
		}
	}
;	Msgbox, % A_tickcount - start_time
}
return


Dwm_SetWindowAttributeTransistionDisable(hwnd,bool:=1)
{
	;
	;	DWMWA_TRANSITIONS_FORCEDISABLED=3
	;	Use with DwmSetWindowAttribute. Enables or forcibly disables DWM transitions.
	;	The pvAttribute parameter points to a value of TRUE to disable transitions or FALSE to enable transitions.
	;	
	;	Input:
	;		hwnd, handle to the window to for which the transistion is to be disabled/enabled
	;		bool, specify true (1) to disable, or false (0) to enable transition.
	;
	dwAttribute:=3
	cbAttribute:=4
	VarSetCapacity(pvAttribute,4,0)
	NumPut(bool,pvAttribute,0,"Int")
	hr:=DllCall("Dwmapi.dll\DwmSetWindowAttribute", "Uint", hwnd, "Uint", dwAttribute, "Uint", &pvAttribute, "Uint", cbAttribute)
	return hr ; 0 is ok!
}
return


PayPal:
Run, http://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=C9FXNFELYMDH8
return

 
Eat_using_hotkey:
   GuiControlGet, eat_using_hotkey,, eat_using_hotkey
   if (eat_using_hotkey = 1){
      GuiControlGet, eat_hotkey_temp,, eat_hotkey
      if (eat_hotkey_temp = ""){
         notification(1, BOTName, "You should first enter hotkey on which eating food is setted up on your Tibia client.")
         GuiControl,,eat_using_hotkey,0
         return
      }
   }
return

Check_food_time:
   sleep, 1300
   GuiControlGet, food_time,, food_time
   if (food_time < 15){
      notification(1, BOTName, "Food time can not be shorter than 15 seconds.")
      GuiControl,,food_time, %shorter_spelltime%
   }
   if (food_time > 2000){
      notification(1, BOTName, "Food time can not be longer than 2000 seconds.")
      GuiControl,,food_time, %shorter_spelltime%
   }
return

Check_anty_log_time:
   sleep, 1300
   GuiControlGet, anty_log_time,, anty_log_time
   if (anty_log_time > 2000){
      notification(1, BOTName, "Anty logout time can not be longer than 2000 seconds.")
      GuiControl,,anty_log_time, %shorter_spelltime%
      return
   }
   if (anty_log_time < 15){
      notification(1, BOTName, "Anty logout time can not be shorter than 15 seconds.")
      GuiControl,,anty_log_time, %shorter_spelltime%
   }
return


Check_dir1:
GuiControlGet, Anty_log_dir1,, Anty_log_dir1
GuiControlGet, Anty_log_dir2,, Anty_log_dir2
if Anty_log_dir2 == ""
   return
if (Anty_log_dir1 == Anty_log_dir2){
   GuiControl, Choose, Anty_log_dir2,0
   notification(1, BOTName, "You can not set the same direction twice.")
}
return

Check_dir2:
GuiControlGet, Anty_log_dir1,, Anty_log_dir1
GuiControlGet, Anty_log_dir2,, Anty_log_dir2
if Anty_log_dir1 == ""
   return
if (Anty_log_dir1 == Anty_log_dir2){
   GuiControl, Choose, Anty_log_dir1,0
   notification(1, BOTName, "You can not set the same direction twice.")
}
return

Auto_shutdown_enabled:
GuiControlGet, Auto_shutdown_enabled,, Auto_shutdown_enabled
GuiControlGet, Auto_shutdown_time,, Auto_shutdown_time
if (Auto_shutdown_enabled = 1){
   global hour_shutdown := SubStr(Auto_shutdown_time, 9,2)
   global min_shutdown := SubStr(Auto_shutdown_time, 11,2)
   if ((A_Hour != hour_shutdown) or (A_Min != min_shutdown )){
      notification(2, BOTName, "Shutdown is planned at " . hour_shutdown . ":" . min_shutdown ".")
      GuiControl, Disable, Auto_shutdown_time
      Settimer, Planned_shutdown, 60000
      return
   }
   else{
      GuiControl,, Auto_shutdown_enabled, 0
      notification(1, BOTName, "You can not plan to shutdown your pc immediately.")
      Settimer, Planned_shutdown, Off
   }
}
else
   GuiControl, Enable, Auto_shutdown_time
   Settimer, Planned_shutdown, off
   notification(2, BOTName, "Shutdown deactivated.")
return

Planned_shutdown:
if ((hour_shutdown == "") or (min_shutdown == ""))
   return
if (A_Hour >= hour_shutdown) and (A_Min >= min_shutdown)
   shutdown, 1
return

Check_spell_to_cast_count:
sleep, 1000
   GuiControlGet, spell_to_cast_count,,spell_to_cast_count
   if ((spell_to_cast_count < 1) or (spell_to_cast_count > 10)){
      notification(1, BOTName, "The amount of times choosen spell will be casted can't be lower than 1 and higher than 10.")
      GuiControl,,spell_to_cast_count,1
   }
return


Check_house_pos_x:
sleep, 1000
   GuiControlGet, house_pos_x,,house_pos_x
   if (house_pos_x < 50){
      notification(1, BOTName, "X coordinate of sqm to throw can't be lower than 50.")
      GuiControl,,house_pos_x, 666
   }
   if (house_pos_x > A_ScreenWidth){
      notification(1, BOTName, "X coordinate of sqm to throw can't be higher than screen width.")
      GuiControl,,house_pos_x, 666
   }
return


Check_house_pos_y:
sleep, 1000
   GuiControlGet, house_pos_y,,house_pos_y
   if (house_pos_y < 1){
      notification(1, BOTName, "Y coordinate of sqm to throw can't be lower than 1.")
      GuiControl,,house_pos_y, 666
   }
   if (house_pos_y > A_Screenheight){
      notification(1, BOTName, "Y coordinate of sqm to throw can't be higher than screen height.")
      GuiControl,,house_pos_y, 666
   }
return


Check_spelltime1:
sleep, 1000
   GuiControlGet, spelltime1,,spelltime1
   if (spelltime1 < 15){
      notification(1, title_tibia1, "Rune make cycle can't take less then 15 seconds.")
      GuiControl,,spelltime1, 15
   }
return

Check_spelltime2:
sleep, 1000
   GuiControlGet, spelltime2,,spelltime2
   if (spelltime2 < 15){
      notification(1, title_tibia2, "Rune make cycle can't take less then 15 seconds.")
      GuiControl,,spelltime2, 15
   }
return

Check_blank_spellname:
   sleep, 1000
   GuiControlGet, blank_spellname,,blank_spellname
   if (blank_spellname = ""){
      notification(1, BotName, "'Spell to conjure blank runes' control field can't be left empty.")
      GuiControl,,blank_spellname, adori blank
   }
   GuiControlGet, blank_spellname_temp,,blank_spellname
   global blank_spellname := blank_spellname_temp
return

PauseRunemaking_IfFood:
GuiControlGet, PauseRunemaking_IfFood,,PauseRunemaking_IfFood
GuiControlGet, Logout_IfFood,,Logout_IfFood
GuiControlGet, PlaySound_IfFood,,PlaySound_IfFood
GuiControlGet, ShutDown_IfFood,,ShutDown_IfFood
GuiControlGet, WalkMethod_IfFood,,WalkMethod_IfFood
GuiControlGet, CastSpell_IfFood,,CastSpell_IfFood
if (Logout_IfFood = 1 or ShutDown_IfFood = 1){
   GuiControl,,PauseRunemaking_IfFood,1
   return
}
if (PauseRunemaking_IfFood = 0){
   GuiControl,,Logout_IfFood,0
   GuiControl,,ShutDown_IfFood,0
   GuiControl,,CastSpell_IfFood,0
}
return

Logout_IfFood:
GuiControlGet, PauseRunemaking_IfFood,,PauseRunemaking_IfFood
GuiControlGet, Logout_IfFood,,Logout_IfFood
GuiControlGet, PlaySound_IfFood,,PlaySound_IfFood
GuiControlGet, ShutDown_IfFood,,ShutDown_IfFood
GuiControlGet, WalkMethod_IfFood,,WalkMethod_IfFood
if (Logout_IfFood = 1){
   GuiControl,,PauseRunemaking_IfFood,1
}
return

PlaySound_IfFood:
return

ShutDown_IfFood:
GuiControlGet, PauseRunemaking_IfFood,,PauseRunemaking_IfFood
GuiControlGet, Logout_IfFood,,Logout_IfFood
GuiControlGet, PlaySound_IfFood,,PlaySound_IfFood
GuiControlGet, ShutDown_IfFood,,ShutDown_IfFood
GuiControlGet, WalkMethod_IfFood,,WalkMethod_IfFood
if (ShutDown_IfFood = 1){
   GuiControl,,PauseRunemaking_IfFood,1
}
return

WalkMethod_IfFood:
return


PauseRunemaking_IfBlank:
GuiControlGet, PauseRunemaking_IfBlank,,PauseRunemaking_IfBlank
GuiControlGet, Logout_IfBlank,,Logout_IfBlank
GuiControlGet, PlaySound_IfBlank,,PlaySound_IfBlank
GuiControlGet, ShutDown_IfBlank,,ShutDown_IfBlank
GuiControlGet, WalkMethod_IfBlank,,WalkMethod_IfBlank
GuiControlGet, CastSpell_IfBlank,,CastSpell_IfBlank
if (Logout_IfBlank = 1 or ShutDown_IfBlank = 1){
   GuiControl,,PauseRunemaking_IfBlank,1
   return
}
if (PauseRunemaking_IfBlank = 1){
   GuiControl,,Logout_IfBlank,0
   GuiControl,,ShutDown_IfBlank,0
   GuiControl,,CastSpell_IfBlank,0
}
return

Logout_IfBlank:
GuiControlGet, PauseRunemaking_IfBlank,,PauseRunemaking_IfBlank
GuiControlGet, Logout_IfBlank,,Logout_IfBlank
GuiControlGet, PlaySound_IfBlank,,PlaySound_IfBlank
GuiControlGet, ShutDown_IfBlank,,ShutDown_IfBlank
GuiControlGet, WalkMethod_IfBlank,,WalkMethod_IfBlank
if (Logout_IfBlank = 1){
   GuiControl,,CastSpell_IfBlank,0
   GuiControl,,PauseRunemaking_IfBlank,1
}
return

PlaySound_IfBlank:
return

ShutDown_IfBlank:
GuiControlGet, PauseRunemaking_IfBlank,,PauseRunemaking_IfBlank
GuiControlGet, Logout_IfBlank,,Logout_IfBlank
GuiControlGet, PlaySound_IfBlank,,PlaySound_IfBlank
GuiControlGet, ShutDown_IfBlank,,ShutDown_IfBlank
GuiControlGet, WalkMethod_IfBlank,,WalkMethod_IfBlank
if (ShutDown_IfBlank = 1){
   GuiControl,,CastSpell_IfBlank,0
   GuiControl,,PauseRunemaking_IfBlank,1
}
return

WalkMethod_IfBlank:
return

CastSpell_IfBlank:
GuiControlGet, PauseRunemaking_IfBlank,,PauseRunemaking_IfBlank
GuiControlGet, Logout_IfBlank,,Logout_IfBlank
GuiControlGet, PlaySound_IfBlank,,PlaySound_IfBlank
GuiControlGet, ShutDown_IfBlank,,ShutDown_IfBlank
GuiControlGet, WalkMethod_IfBlank,,WalkMethod_IfBlank
GuiControlGet, CastSpell_IfBlank,,CastSpell_IfBlank
GuiControlGet, Spell_to_cast_count,,Spell_to_cast_count
GuiControlGet, Spell_to_cast_name,,Spell_to_cast_name
if (Spell_to_cast_name = ""){
   notification(1, BOTName, "You should enter first valid spell key to casted, configurable in settings.")
   GuiControl,,CastSpell_IfBlank,0
   return
}
if (Spell_to_cast_count = ""){
   notification(1, BOTName, "First you should enter how many times spell will be casted, configurable in settings.")
   GuiControl,,CastSpell_IfBlank,0
   return
}
if ((Spell_to_cast_count < 1) or (Spell_to_cast_count > 10)){
   notification(1, BOTName, "The amount of times choosen spell will be casted can't be lower than 1 and higher than 10.")
   GuiControl,,CastSpell_IfBlank,0
   return
}
if (CastSpell_IfBlank = 1){
   GuiControl,,PauseRunemaking_IfBlank,0
   GuiControl,,ShutDown_IfBlank,0
   GuiControl,Choose,WalkMethod_IfBlank,1
   GuiControl,,Logout_IfBlank,0
}
return

PauseRunemaking_IfPlayer:
GuiControlGet, PauseRunemaking_IfPlayer,,PauseRunemaking_IfPlayer
GuiControlGet, Logout_IfPlayer,,Logout_IfPlayer
GuiControlGet, PlaySound_IfPlayer,,PlaySound_IfPlayer
GuiControlGet, ShutDown_IfPlayer,,ShutDown_IfPlayer
GuiControlGet, WalkMethod_IfPlayer,,WalkMethod_IfPlayer
GuiControlGet, CastSpell_IfPlayer,,CastSpell_IfPlayer
if (Logout_IfPlayer = 1 or ShutDown_IfPlayer = 1){
   GuiControl,,PauseRunemaking_IfPlayer,1
   return
}
if (PauseRunemaking_IfPlayer = 1){
   GuiControl,,Logout_IfPlayer,0
   GuiControl,,ShutDown_IfPlayer,0
   GuiControl,,CastSpell_IfPlayer,0
}
return

Logout_IfPlayer:
GuiControlGet, PauseRunemaking_IfPlayer,,PauseRunemaking_IfPlayer
GuiControlGet, Logout_IfPlayer,,Logout_IfPlayer
GuiControlGet, PlaySound_IfPlayer,,PlaySound_IfPlayer
GuiControlGet, ShutDown_IfPlayer,,ShutDown_IfPlayer
GuiControlGet, WalkMethod_IfPlayer,,WalkMethod_IfPlayer
if (Logout_IfPlayer = 1){
   GuiControl,,PauseRunemaking_IfPlayer,1
}
return

PlaySound_IfPlayer:
return

ShutDown_IfPlayer:
GuiControlGet, PauseRunemaking_IfPlayer,,PauseRunemaking_IfPlayer
GuiControlGet, Logout_IfPlayer,,Logout_IfPlayer
GuiControlGet, PlaySound_IfPlayer,,PlaySound_IfPlayer
GuiControlGet, ShutDown_IfPlayer,,ShutDown_IfPlayer
GuiControlGet, WalkMethod_IfPlayer,,WalkMethod_IfPlayer
if (ShutDown_IfPlayer = 1){
   GuiControl,,PauseRunemaking_IfPlayer,1
}
return

WalkMethod_IfPlayer:
return

PauseRunemaking_IfSoul:
GuiControlGet, PauseRunemaking_IfSoul,,PauseRunemaking_IfSoul
GuiControlGet, Logout_IfSoul,,Logout_IfSoul
GuiControlGet, PlaySound_IfSoul,,PlaySound_IfSoul
GuiControlGet, ShutDown_IfSoul,,ShutDown_IfSoul
GuiControlGet, WalkMethod_IfSoul,,WalkMethod_IfSoul
GuiControlGet, CastSpell_IfSoul,,CastSpell_IfSoul
if (Logout_IfSoul = 1 or ShutDown_IfSoul = 1){
   GuiControl,,PauseRunemaking_IfSoul,1
   return
}
if (PauseRunemaking_IfSoul = 1){
   GuiControl,,Logout_IfSoul,0
   GuiControl,,ShutDown_IfSoul,0
   GuiControl,,CastSpell_IfSoul,0
}
return

Logout_IfSoul:
GuiControlGet, PauseRunemaking_IfSoul,,PauseRunemaking_IfSoul
GuiControlGet, Logout_IfSoul,,Logout_IfSoul
GuiControlGet, PlaySound_IfSoul,,PlaySound_IfSoul
GuiControlGet, ShutDown_IfSoul,,ShutDown_IfSoul
GuiControlGet, WalkMethod_IfSoul,,WalkMethod_IfSoul
if (Logout_IfSoul = 1){
   GuiControl,,CastSpell_IfSoul,0
   GuiControl,,PauseRunemaking_IfSoul,1
}
return

PlaySound_IfSoul:
return

ShutDown_IfSoul:
GuiControlGet, PauseRunemaking_IfSoul,,PauseRunemaking_IfSoul
GuiControlGet, Logout_IfSoul,,Logout_IfSoul
GuiControlGet, PlaySound_IfSoul,,PlaySound_IfSoul
GuiControlGet, ShutDown_IfSoul,,ShutDown_IfSoul
GuiControlGet, WalkMethod_IfSoul,,WalkMethod_IfSoul
if (ShutDown_IfSoul = 1){
   GuiControl,,CastSpell_IfSoul,0
   GuiControl,,PauseRunemaking_IfSoul,1
}
return

WalkMethod_IfSoul:
return

CastSpell_IfSoul:
GuiControlGet, PauseRunemaking_IfSoul,,PauseRunemaking_IfSoul
GuiControlGet, Logout_IfSoul,,Logout_IfSoul
GuiControlGet, PlaySound_IfSoul,,PlaySound_IfSoul
GuiControlGet, ShutDown_IfSoul,,ShutDown_IfSoul
GuiControlGet, WalkMethod_IfSoul,,WalkMethod_IfSoul
GuiControlGet, CastSpell_IfSoul,,CastSpell_IfSoul
GuiControlGet, Spell_to_cast_count,,Spell_to_cast_count
GuiControlGet, Spell_to_cast_name,,Spell_to_cast_name
if (Spell_to_cast_name = ""){
   notification(1, BOTName, "You should enter first valid key of spell to casted, configurable in settings.")
   GuiControl,,CastSpell_IfSoul,0
   return
}
if (Spell_to_cast_count = ""){
   notification(1, BOTName, "You should enter first how many times spell will be casted, configurable in settings.")
   GuiControl,,CastSpell_IfSoul,0
   return
}
if ((Spell_to_cast_count < 1) or (Spell_to_cast_count > 10)){
   notification(1, BOTName, "The amount of times choosen spell will be casted can't be lower than 1 and higher than 10.")
   GuiControl,,CastSpell_IfSoul,0
   return
}
if (CastSpell_IfSoul = 1){
   GuiControl,,PauseRunemaking_IfSoul,0
   GuiControl,,ShutDown_IfSoul,0
   GuiControl,Choose,WalkMethod_IfSoul,1
   GuiControl,,Logout_IfSoul,0
}
return



Tab1:
Gui, Submit, NoHide
if ((Tab1 = "Alarms") or (Tab1 = "Settings") or (Tab1 = "Advanced"))
	GuiControl, Move, tab2, x800 y800
else
	GuiControl, Move, tab2, x32 y50
WinSet, Redraw, , A
return

; ######################################################### SCREEN CHECKER #########################################################################

Area_screen_checker1:
   SetTimer, Read_scp_board1, Off
   GuiControl,,Enabled_screen_checker1,0
   GuiControl,CP:,CP_isActive_checker1,0
   Gdip_DisposeImage(bmparea_check1)
   if (!WinExist(title_tibia1)){
      notification(2, "Screen checker", "Window titled: " . title_tibia1 . " does not exist.")
      return
   }
   if (transparent_tibia1 = 1)
      gosub, hide_client_1
   WinActivate, ahk_pid %pid_tibia1%
   WinWait, ahk_pid %pid_tibia1% 
   take_screenshot("area_check1", 85, 75)
return

Area_screen_checker2:
   SetTimer, Read_scp_board2, Off
   GuiControl,,Enabled_screen_checker2,0
   GuiControl,CP:,CP_isActive_checker2,0
   Gdip_DisposeImage(bmparea_check2)
   if (!WinExist(title_tibia2)){
      notification(2, "Screen checker", "Window titled: " . title_tibia2 . " does not exist.")
      return
   }
   if (transparent_tibia2 = 1)
      gosub, hide_client_2
   WinActivate, ahk_pid %pid_tibia2%
   WinWait, ahk_pid %pid_tibia2% 
   take_screenshot("area_check2", 85, 75)
return

Help_screen_checker:
MsgBox, 32, Screen checker - help, "Affect on" determines on which window bot has to check if region of screen haven't changed. Bot relay on what is actually on screen so its impossible to check both windows at once. Runemake algorithm is constructed that way if there are two game windows the choosen game window will be active most of the time. What else there will be a short period about 3-10 seconds while the other window will be active to make rune and druing this time the choosen window will be not checked, what means there is still a risk to be killed.`n`n "Frequency" means how long each check will take. It is limited to once every 150ms but recommended value is about 400-500.`n`n"Select area" is a tool to obtain region to check and its position on screen. It is wise to use it for example on battelist or hp bar. Keep it mind that change of image will result in "if screen change" alert configurable in alarms tab. And it work only if game window is active and maximized (but not fullscreened)!`n`n"Double alarm effect" is while having two mc and screen region changes on one of the clients then alarm result affects two clients, not only choosen one. It is useful while having runemaking two characters in the same place, near house doors and in case of alarm both of them will go north.
return

Enabled_screen_checker1:
   GuiControlGet, Enabled_screen_checker1,,Enabled_screen_checker1
   if (!WinExist(title_tibia1)){
      notification(2, "Screen checker", "Window titled: " . title_tibia1 . " does not exist.")
      GuiControl,,Enabled_screen_checker1,0
      GuiControl,CP:,CP_isActive_checker1,0
      GuiControl,, Enabled_runemaking1, 0
      SetTimer, Read_scp_board1, Off
      Check_gui()
      return
   }
   else if (!FileExist("Data\Images\area_check1.bmp") or (area_start_x1 = "") or (area_start_y1 = "") or (sc_temp_img_dir1 !contains "area_check1.bmp")){
      notification(2, "Screen checker", "Capture image of region to check first")
      GuiControl,,Enabled_screen_checker1,0
      GuiControl,CP:,CP_isActive_checker1,0
      SetTimer, Read_scp_board1, Off
      return
   }
   IfWinNotExist, ahk_id %CommunicationPlatform%
   {
      GoSub, CP_GUI
      Sleep, 300
      Msgbox, CP_GUI launched.
   }
   ControlGet, SCP_HWND, Line,1,edit3, SCP_WRLBOT
   IfWinNotExist, ahk_id %SCP_HWND%
   {
      Run, Data\scp_wrlbot.exe, scp_pid
      sleep, 300
      ControlGet, SCP_HWND, Line,1,edit3, SCP_WRLBOT
      IfWinNotExist, ahk_id %SCP_HWND%
      {
         notification(1, "Screen checker", "There was communication problem with scp_wrlbot - (error 4001).")
         SetTimer, Read_scp_board2, Off
         GuiControl,,Enabled_screen_checker1,0
         GuiControl,CP:,CP_isActive_checker1,0
         return
      }
   }
   if (Enabled_screen_checker1 = 1){
      check1_x1 := 0 ; % area_start_x1 + 5
      check1_y1 := 0 ; % area_start_y1 + 5
      check1_x2 := 0 ; % area_start_x1 +100
      check1_y2 := 0 ; % area_start_y1 +90
      GuiControl,CP:,CP_check1_x1, %check1_x1%
      GuiControl,CP:,CP_check1_y1, %check1_y1%
      GuiControl,CP:,CP_isActive_checker1,1
      SetTimer, Read_scp_board1, %refresh_time%
   }
   else{
      GuiControl,CP:,CP_isActive_checker1,0
   }
return

Enabled_screen_checker2:
   GuiControlGet, Enabled_screen_checker2,,Enabled_screen_checker2
   if (!WinExist(title_tibia2)){
      notification(2, "Screen checker", "Window titled: " . title_tibia2 . " does not exist.")
      GuiControl,,Enabled_screen_checker2,0
      GuiControl,CP:,CP_isActive_checker2,0
      GuiControl,, Enabled_runemaking2, 0
      SetTimer, Read_scp_board2, Off
      Check_gui()
      return
   }
   else if (!FileExist("Data\Images\area_check2.bmp") or (area_start_x2 = "") or (area_start_y2 = "") or (sc_temp_img_dir2 !contains "area_check2.bmp")){
      notification(2, "Screen checker", "Capture image of region to check first")
      GuiControl,,Enabled_screen_checker2,0
      GuiControl,CP:,CP_isActive_checker2,0
      SetTimer, Read_scp_board2, Off
      return
   }
   IfWinNotExist, ahk_id %CommunicationPlatform%
   {
      GoSub, CP_GUI
      Sleep, 300
      Msgbox, CP_GUI launched.
   }
   ControlGet, SCP_HWND, Line,1,edit3, SCP_WRLBOT
   IfWinNotExist, ahk_id %SCP_HWND% 
   {
      Run, Data\scp_wrlbot.exe, scp_pid
      sleep, 300
      ControlGet, SCP_HWND, Line,1,edit3, SCP_WRLBOT
      IfWinNotExist, ahk_id %SCP_HWND%
      {
         notification(1, "Screen checker", "There was communication problem with scp_wrlbot - (error 4001).")
         SetTimer, Read_scp_board2, Off
         GuiControl,,Enabled_screen_checker2,0
         GuiControl,CP:,CP_isActive_checker2,0
         return
      }
   }
   if (Enabled_screen_checker2 = 1){
      check2_x1 := 0 ; % area_start_x2 + 5
      check2_y1 := 0 ; % area_start_y2 + 5
      check2_x2 := 0 ; % area_start_x2 +100
      check2_y2 := 0 ; % area_start_y2 +90
      GuiControl,CP:,CP_check2_x1, %check2_x1%
      GuiControl,CP:,CP_check2_y1, %check2_y1%
      GuiControl,CP:,CP_isActive_checker2,1
      SetTimer, Read_scp_board2, %refresh_time%
   }
   else{
      GuiControl,CP:,CP_isActive_checker2,0
   }
return


Screen_check1:
return

Screen_check2:
return




CP_GUI:
   GuiControlGet, Enabled_screen_checker1,,Enabled_screen_checker1
   GuiControlGet, Enabled_screen_checker2,,Enabled_screen_checker2
   Gui, CP: New
   Gui, CP: +HwndCommunicationPlatform  +Caption +LastFound +ToolWindow +AlwaysOnTop +E0x20   ; WS_EX_TRANSPARENT ; communication panel
   Gui, CP: Add, Edit, x12 y10 w60 h20 vCP_isActive_checker1 Disabled, %Enabled_screen_checker1%
   Gui, CP: Add, Edit, x12 y30 w60 h20 vCP_hwnd1 Disabled, empty
   Gui, CP: Add, Edit, x12 y50 w60 h20 vCP_check1_x1 Disabled, empty
   Gui, CP: Add, Edit, x12 y70 w60 h20 vCP_check1_y1 Disabled, empty
   Gui, CP: Add, Edit, x82 y10 w60 h20 vCP_isActive_checker2 Disabled, %Enabled_screen_checker2%
   Gui, CP: Add, Edit, x82 y30 w60 h20 vCP_hwnd2 Disabled, empty
   Gui, CP: Add, Edit, x82 y50 w60 h20 vCP_check2_x1 Disabled, empty
   Gui, CP: Add, Edit, x82 y70 w60 h20 vCP_check2_y1 Disabled, empty
   Gui, CP: Add, Edit, x12 y90 w60 h20 vCP_BOT_HWND Disabled, %MainBotWindow%
   Gui, CP: Add, Edit, x82 y90 w60 h20 vCP_CP_HWND Disabled, %CommunicationPlatform%
;   DllCall("SetParent", UInt, WinExist() , UInt, ahk_id MainBotWindow)
   WinSet, Transparent, 0 ;, CP_WRLBOT ; ahk_id %CommunicationPlatform%
   Gui, CP: Show, w155 h120 NoActivate Center, CP_WRLBOT
   GuiControl,CP:,CP_hwnd1, %hwnd1%
   GuiControl,CP:,CP_hwnd2, %hwnd2%
   WinSet, Transparent, 0, ahk_id %CommunicationPlatform%
return


Read_scp_board1:
   GuiControlGet, Enabled_screen_checker1,,Enabled_screen_checker1
   if (Enabled_screen_checker1 = 1){
      ControlGet, result1, Line,1,edit1, SCP_WRLBOT
      if (result1 = 0){
         if (transparent_tibia1 = 1){                                                                ; double check with 100ms sleep to make sure if its not false positive in result of min/max hidden win fast
            sleep, 100
            ControlGet, result1, Line,1,edit1, SCP_WRLBOT
             if (result1 = 0){
               alarm(title_tibia1, "player")
               SetTimer, Read_scp_board1, Off
               GuiControl,,Enabled_screen_checker1,0
               GuiControl,CP:,CP_isActive_checker1,0
               return
            }
         }
         alarm(title_tibia1, "player")
         SetTimer, Read_scp_board1, Off
         GuiControl,,Enabled_screen_checker1,0
         GuiControl,CP:,CP_isActive_checker1,0
         return
      }
      if (result1 != "1"){
         if (result1 = "NE"){
            SetTimer, Read_scp_board1, Off
            GuiControl,,Enabled_screen_checker1,0
            GuiControl,CP:,CP_isActive_checker1,0
            notification(2, "Screen checker", "Window titled: " . title_tibia1 . " does not exist.")
         }
         if (result1 = "NA"){
            if (transparent_tibia1 = 1)
               WinActivate, %title_tibia1%
            else
               notification(2, "Screen checker", "Screen checker: window 1 must be active to be checked. Use 'hide/show' button if you want to hide game.")
         }
      }
   }
return

Read_scp_board2:
   GuiControlGet, Enabled_screen_checker2,,Enabled_screen_checker2
   if (Enabled_screen_checker2 = 1){
      ControlGet, result2, Line,1,edit2, SCP_WRLBOT
      if (result2 = 0){
         if (transparent_tibia2 = 1){
            sleep, 100
            ControlGet, result2, Line,1,edit2, SCP_WRLBOT
             if (result2 = 0){
               alarm(title_tibia2, "player")
               SetTimer, Read_scp_board2, Off
               GuiControl,,Enabled_screen_checker2,0
               GuiControl,CP:,CP_isActive_checker2,0
               return
            }
         }
         alarm(title_tibia2, "player")
         SetTimer, Read_scp_board2, Off
         GuiControl,,Enabled_screen_checker2,0
         GuiControl,CP:,CP_isActive_checker2,0
         return
      }
      if (result2 != "1"){
         if (result2 = "NE"){
            SetTimer, Read_scp_board2, Off
            GuiControl,,Enabled_screen_checker2,0
            GuiControl,CP:,CP_isActive_checker2,0
            notification(2, "Screen checker", "Window titled: " . title_tibia2 . " does not exist.")
         }
         if (result2 = "NA"){
            if (transparent_tibia2 = 1)
               WinActivate, %title_tibia2%
            else
               notification(2, "Screen checker", "Screen checker: window 2 must be active to be checked. Use 'hide/show' button if you want to hide game.")
         }
      }
   }
return

; ################################################################# FISHING 1 ################################################################################
Fishing_setup1:
   if (!WinExist(title_tibia1)){
      notification(2, "Fishing tool", "Window titled: " . title_tibia1 . " does not exist.")
      GuiControl,,Fishing_enabled1, 0
      return
   }
   If !(WinExist(Fishing_gui1_title)){
      GuiControl,,Fishing_enabled1, 0
      Hotkey, ESC, Fishing_restore_windows1, On
      if (DllCall("IsWindowVisible", "UInt", WinExist(Fishing_gui2_title))){
         WinGetPos, win_temp_posX, win_temp_posY, , ,%Fishing_gui2_title%
         Gui, Fishing_gui1: Show, x%win_temp_posX% y%win_temp_posY% w149 h242, %Fishing_gui1_title%  
      }
      else
         Gui, Fishing_gui1: Show, xCenter yCenter w149 h242, %Fishing_gui1_title%  
   }
   if (DllCall("IsWindowVisible", "UInt", WinExist(Fishing_gui2_title))){
      global execution_allowed := 1
      i := 0
      j := 0
      while (i < 15){
          while (j < 11){
              Gui, second_sqm%i%x%j%: Hide
              j := j + 1
          }
          j := 0
          i := i + 1
      }
      GuiControl, Fishing_gui2:, Fishing_button_text2, show fishing spots
      Hotkey, ESC, Fishing_restore_windows2, Off
      RestoreCursors()
      Gui, Fishing_gui2: Hide
      Gui, Fishing_selectTopLeft2: Hide
      Gui, Fishing_selectBottomRight2: Hide
      Hotkey, ~LButton, Fishing_selectSqm2, Off
      Hotkey, LButton, Fishing_Mouse_selectTopLeft2, off
      Hotkey, LButton, Fishing_Mouse_selectBottomRight2, off
   }
return

Fishing_getSpots1:
   DetectHiddenWindows, On
   if winexist("x0y0zAABBCC1"){
         DetectHiddenWindows, Off
         goto, Fishing_showSqmsNet1
   }
   DetectHiddenWindows, Off
   Gui, Fishing_gui1: Hide
   Gui, Fishing_selectTopLeft1: Show, AutoSize xCenter yCenter
   if (transparent_tibia1 = 1)
      gosub, hide_client_1
   WinMinimize, ahk_id %MainBotWindow%
   WinActivate, ahk_pid %pid_tibia1%
   WinWait, ahk_pid %pid_tibia1% 
   SetSystemCursor("IDC_CROSS")
   global execution_allowed := 0
   Hotkey, LButton, Fishing_Mouse_selectTopLeft1, on
return

Fishing_Mouse_selectTopLeft1:
   MouseGetPos, topleft_gamewindow1_x, topleft_gamewindow1_y
   Gui, Fishing_selectTopLeft1: Hide
   Hotkey, LButton, Fishing_Mouse_selectTopLeft1, off
   Sleep, 200
   Gui, Fishing_selectBottomRight1: Show, AutoSize xCenter yCenter
   Hotkey, LButton, Fishing_Mouse_selectBottomRight1, on
return

Fishing_Mouse_selectBottomRight1:
   MouseGetPos, bottomright_gamewindow1_x, bottomright_gamewindow1_y
   If ((bottomright_gamewindow1_x-topleft_gamewindow1_x) < 300) or  ((bottomright_gamewindow1_y-topleft_gamewindow1_y) < 300){
      GoSub, Fishing_restore_windows1
      MsgBox, Take proper measurments of top left and right bottom of game window. 
      return
   }
   Hotkey, LButton, Fishing_Mouse_selectBottomRight1, off
   Gui, Fishing_selectBottomRight1: Hide
   RestoreCursors()
   Goto, Fishing_showSqmsNet1
return

Fishing_showSqmsNet1:
   sqm_width1 := round((bottomright_gamewindow1_x - topleft_gamewindow1_x)/15)
   sqm_height1 := round((bottomright_gamewindow1_y - topleft_gamewindow1_y)/11)
   i := 0
   j := 0
   a := 0
   DetectHiddenWindows, On
   if DllCall("IsWindowVisible", "UInt", WinExist("x0y0zAABBCC1"))
      fishing_sqms_hidden1 := 0
   else 
       fishing_sqms_hidden1 := 1
   if (winexist("x0y0zAABBCC1") and (fishing_sqms_hidden1 = 0)){
      global execution_allowed := 1
      GuiControl, Fishing_gui1:, Fishing_button_text1, show fishing spots
      while (i < 15){
         while (j < 11){
              Gui, first_sqm%i%x%j%: Hide
              j := j + 1
          }
          j := 0
          i := i + 1
      }
   }
   else if (winexist("x0y0zAABBCC1") and (fishing_sqms_hidden1 = 1)){
      global execution_allowed := 0
      GuiControl, Fishing_gui1:, Fishing_button_text1, hide fishing spots
      if (transparent_tibia1 = 1)
         gosub, hide_client_1
      WinMinimize, ahk_id %MainBotWindow%
      WinActivate, ahk_pid %pid_tibia1%
      WinWait, ahk_pid %pid_tibia1% 
      while (i < 15){
         while (j < 11){
              Gui, first_sqm%i%x%j%: Show
              j := j + 1
          }
          j := 0
          i := i + 1
      }
   }
   else{
      global execution_allowed := 0
      GuiControl, Fishing_gui1:, Fishing_button_text1, hide fishing spots
      while (i < 15){
          while (j < 11){
              Gui, first_sqm%i%x%j%: New
              Gui, first_sqm%i%x%j%: +alwaysontop -Caption +Border +ToolWindow +LastFound +OwnerFishing_gui1
              Gui, first_sqm%i%x%j%: Color, ADEBDA
              WinSet, Transparent, 50 ; Else Add transparency
              posx := topleft_gamewindow1_x + i*sqm_width1 
              posy := topleft_gamewindow1_y + j*sqm_height1 
              Gui, first_sqm%i%x%j%: Show, x%posx% y%posy% w%sqm_width1% h%sqm_height1% NoActivate, x%i%y%j%zAABBCC1
              fishing1_spot[i, j] 	:= a
              a := a + 1
              j := j + 1
          }
          j := 0
          i := i + 1
      }
   }
   DetectHiddenWindows, Off
   moveFishing_gui1_posx := topleft_gamewindow1_x + 15*sqm_width1
   Gui, Fishing_gui1: Show, x%moveFishing_gui1_posx% y%topleft_gamewindow1_y% w149 h242, %Fishing_gui1_title%
   ; WinMove, ahk_id %Fishing_gui1%,, 
   Hotkey, ~LButton, Fishing_selectSqm1, ON
return


Fishing_reset1:
global execution_allowed := 1
GuiControl, Fishing_gui1:, Fishing_button_text1, get fishing spots
i := 0
j := 0
while (i < 15){
          while (j < 11){
              Gui, first_sqm%i%x%j%: Destroy
              first_value%i%x%j% := 0
              fishing1_stack.delete(fishing1_spot[i, j])
            j := j + 1
         }
j := 0
i := i + 1
}
return

Fishing_selectSqm1:
   Sleep, 30
   WinGetTitle, title, A
   if title contains AABBCC1
   {
       FoundPosX := InStr(title, "x")
       FoundPosY := InStr(title, "y")
       FoundPosZ := InStr(title, "z")
       FoundPosX2 := FoundPosX + 1
       length1 := FoundPosY - FoundPosX2
       FoundPosY2 := FoundPosY + 1
       length2 := FoundPosZ - FoundPosY2
       nr_i := SubStr(title, FoundPosX2, Length1)
       nr_j := SubStr(title, FoundPosY2, Length2)
       if (first_value%nr_i%x%nr_j% != 1){
           Gui, first_sqm%nr_i%x%nr_j%: Color, FF0000
           first_value%nr_i%x%nr_j% := 1
           pos_toFish := "x" . round(topleft_gamewindow1_x + sqm_width1*(nr_i + 0.5)) . "y" . round(topleft_gamewindow1_y + sqm_height1*(nr_j + 0.5))
           fishing1_stack[fishing1_spot[nr_i, nr_j]] := pos_toFish
           arrayChanged1:=1
       }
       else{
           Gui, first_sqm%nr_i%x%nr_j%: Color, ADEBDA
           first_value%nr_i%x%nr_j% := 0
           fishing1_stack.delete(fishing1_spot[nr_i, nr_j])
           arrayChanged1:=1
       }
   }
return

Fishing_gui1GuiClose:
   gosub,Fishing_done1
return

Fishing_done1:
   global execution_allowed := 1
   i := 0
   j := 0
   while (i < 15){
       while (j < 11){
           Gui, first_sqm%i%x%j%: Hide
           j := j + 1
       }
       j := 0
       i := i + 1
   }
   DetectHiddenWindows, On 
   if (winexist("x0y0zAABBCC1"))
      GuiControl, Fishing_gui1:, Fishing_button_text1, show fishing spots
   DetectHiddenWindows, Off
   Gosub, Fishing_restore_windows1
   Gui, Fishing_gui1: Hide
   WinActivate, ahk_id %MainBotWindow%
return


Fishing_restore_windows1:
   Hotkey, ESC, Fishing_restore_windows1, Off
   RestoreCursors()
   Gui, Fishing_selectTopLeft1: Hide
   Gui, Fishing_selectBottomRight1: Hide
   Hotkey, ~LButton, Fishing_selectSqm1, Off
   Hotkey, LButton, Fishing_Mouse_selectTopLeft1, off
   Hotkey, LButton, Fishing_Mouse_selectBottomRight1, off
return

fishing_enabled1:
   GuiControlGet, fishing_enabled1,, fishing_enabled1
   IfWinNotExist, ahk_pid %pid_tibia1%
      {
      if (pid_tibia1 != ""){
         title_tibia1 := "Game client 1 - identyfied by " pid_tibia1
         WinActivate, ahk_pid %pid_tibia1%
         WinWait, ahk_pid %pid_tibia1% 
         WinSetTitle, %title_tibia1%
         sleep, 50
      }
      IfWinNotExist, ahk_pid %pid_tibia1%
      {
         notification(2, title_tibia1, "Window " . title_tibia1 . " doesn't exist.")
         GuiControl,, fishing_enabled1, 0
         return
      }
   }
   random_posToFish_template1 := getRandomArrayValue1(fishing1_stack,arrayChanged1)
   arrayChanged1:=0
   DetectHiddenWindows, On
    if (!(winexist("x0y0zAABBCC1")) or random_posToFish_template1 = ""){
      notification(2, title_tibia1, "You should first get spots you want to fish on.")
      GuiControl,, fishing_enabled1, 0
      DetectHiddenWindows, Off
   }
   if DllCall("IsWindowVisible", "UInt", WinExist("x0y0zAABBCC1"))
      fishing_sqms_hidden1 := 0
   else 
       fishing_sqms_hidden1 := 1
   if (winexist("x0y0zAABBCC1") and (fishing_sqms_hidden1 = 0)){
      GuiControl, Fishing_gui1:, Fishing_button_text1, show fishing spots
      while (i < 15){
         while (j < 11){
              Gui, first_sqm%i%x%j%: Hide
              j := j + 1
          }
          j := 0
          i := i + 1
      }
   }
   DetectHiddenWindows, Off
   if (fishing_enabled1 = 1){
      SetTimer, fishing_execution, %fishing_time%
   }
return

; ################################################################# FISHING 2 ################################################################################


Fishing_setup2:
   if (!WinExist(title_tibia2)){
      notification(2, "Fishing tool", "Window titled: " . title_tibia2 . " does not exist.")
      GuiControl,,Fishing_enabled2, 0
      
      return
   }
   If !(WinExist(Fishing_gui2_title)){
      GuiControl,,Fishing_enabled2, 0
      
      Hotkey, ESC, Fishing_restore_windows2, On
      if (DllCall("IsWindowVisible", "UInt", WinExist(Fishing_gui1_title))){
         WinGetPos, win_temp_posX, win_temp_posY, , ,%Fishing_gui1_title%
         Gui, Fishing_gui2: Show, x%win_temp_posX% y%win_temp_posY% w149 h242, %Fishing_gui2_title%  
      }
      else
         Gui, Fishing_gui2: Show, xCenter yCenter w149 h242, %Fishing_gui2_title%  
   }
   if (DllCall("IsWindowVisible", "UInt", WinExist(Fishing_gui1_title))){
      global execution_allowed := 1
      i := 0
      j := 0
      while (i < 15){
          while (j < 11){
              Gui, first_sqm%i%x%j%: Hide
              j := j + 1
          }
          j := 0
          i := i + 1
      }
      GuiControl, Fishing_gui1:, Fishing_button_text1, show fishing spots
      Hotkey, ESC, Fishing_restore_windows1, Off
      RestoreCursors()
      Gui, Fishing_gui1: Hide
      Gui, Fishing_selectTopLeft1: Hide
      Gui, Fishing_selectBottomRight1: Hide
      Hotkey, ~LButton, Fishing_selectSqm1, Off
      Hotkey, LButton, Fishing_Mouse_selectTopLeft1, off
      Hotkey, LButton, Fishing_Mouse_selectBottomRight1, off
   }
return

Fishing_getSpots2:
   DetectHiddenWindows, On
   if winexist("x0y0zAABBCC2"){
         DetectHiddenWindows, Off
         goto, Fishing_showSqmsNet2
   }
   DetectHiddenWindows, Off
   Gui, Fishing_gui2: Hide
   Gui, Fishing_selectTopLeft2: Show, AutoSize xCenter yCenter
   if (transparent_tibia2 = 1)
      gosub, hide_client_2
   WinMinimize, ahk_id %MainBotWindow%
   WinActivate, ahk_pid %pid_tibia2%
   WinWait, ahk_pid %pid_tibia2% 
   SetSystemCursor("IDC_CROSS")
   global execution_allowed := 0
   Hotkey, LButton, Fishing_Mouse_selectTopLeft2, on
return

Fishing_Mouse_selectTopLeft2:
   MouseGetPos, topleft_gamewindow2_x, topleft_gamewindow2_y
   Gui, Fishing_selectTopLeft2: Hide
   Hotkey, LButton, Fishing_Mouse_selectTopLeft2, off
   Sleep, 200
   Gui, Fishing_selectBottomRight2: Show, AutoSize xCenter yCenter
   Hotkey, LButton, Fishing_Mouse_selectBottomRight2, on
return

Fishing_Mouse_selectBottomRight2:
   MouseGetPos, bottomright_gamewindow2_x, bottomright_gamewindow2_y
   If ((bottomright_gamewindow2_x-topleft_gamewindow2_x) < 300) or  ((bottomright_gamewindow2_y-topleft_gamewindow2_y) < 300){
      GoSub, Fishing_restore_windows2
      MsgBox, Take proper measurments of top left and right bottom of game window. 
      return
   }
   Hotkey, LButton, Fishing_Mouse_selectBottomRight2, off
   Gui, Fishing_selectBottomRight2: Hide
   RestoreCursors()
   Goto, Fishing_showSqmsNet2
return

Fishing_showSqmsNet2:
   sqm_width2 := round((bottomright_gamewindow2_x - topleft_gamewindow2_x)/15)
   sqm_height2 := round((bottomright_gamewindow2_y - topleft_gamewindow2_y)/11)
   i := 0
   j := 0
   a := 0
   DetectHiddenWindows, On
   if DllCall("IsWindowVisible", "UInt", WinExist("x0y0zAABBCC2"))
      fishing_sqms_hidden2 := 0
   else 
       fishing_sqms_hidden2 := 1
   if (winexist("x0y0zAABBCC2") and (fishing_sqms_hidden2 = 0)){
      global execution_allowed := 1
      GuiControl, Fishing_gui2:, Fishing_button_text2, show fishing spots
      while (i < 15){
         while (j < 11){
              Gui, second_sqm%i%x%j%: Hide
              j := j + 1
          }
          j := 0
          i := i + 1
      }
   }
   else if (winexist("x0y0zAABBCC2") and (fishing_sqms_hidden2 = 1)){
      global execution_allowed := 0
      GuiControl, Fishing_gui2:, Fishing_button_text2, hide fishing spots
       if (transparent_tibia2 = 1)
      gosub, hide_client_2
      WinMinimize, ahk_id %MainBotWindow%
      WinActivate, ahk_pid %pid_tibia2%
      WinWait, ahk_pid %pid_tibia2% 
      while (i < 15){
         while (j < 11){
              Gui, second_sqm%i%x%j%: Show
              j := j + 1
          }
          j := 0
          i := i + 1
      }
   }
   else{
      global execution_allowed := 0
      GuiControl, Fishing_gui2:, Fishing_button_text2, hide fishing spots
      while (i < 15){
          while (j < 11){
              Gui, second_sqm%i%x%j%: New
              Gui, second_sqm%i%x%j%: +alwaysontop -Caption +Border +ToolWindow +LastFound +OwnerFishing_gui2
              Gui, second_sqm%i%x%j%: Color, ADEBDA
              WinSet, Transparent, 50 ; Else Add transparency
              posx := topleft_gamewindow2_x + i*sqm_width2 
              posy := topleft_gamewindow2_y + j*sqm_height2 
              Gui, second_sqm%i%x%j%: Show, x%posx% y%posy% w%sqm_width2% h%sqm_height2% NoActivate, x%i%y%j%zAABBCC2
              fishing2_spot[i, j] 	:= a
              a := a + 1
              j := j + 1
          }
          j := 0
          i := i + 1
      }
   }
   DetectHiddenWindows, Off
   moveFishing_gui2_posx := topleft_gamewindow2_x + 15*sqm_width2
   Gui, Fishing_gui2: Show, x%moveFishing_gui2_posx% y%topleft_gamewindow2_y% w149 h242, %Fishing_gui2_title%
   ; WinMove, ahk_id %Fishing_gui2%,, 
   Hotkey, ~LButton, Fishing_selectSqm2, ON
return


Fishing_reset2:
global execution_allowed := 1
GuiControl, Fishing_gui2:, Fishing_button_text2, get fishing spots
i := 0
j := 0
while (i < 15){
          while (j < 11){
              Gui, second_sqm%i%x%j%: Destroy
              first_value%i%x%j% := 0
              fishing2_stack.delete(fishing2_spot[i, j])
            j := j + 1
         }
j := 0
i := i + 1
}
return

Fishing_selectSqm2:
   Sleep, 30
   WinGetTitle, title, A
   if title contains AABBCC2
   {
       FoundPosX := InStr(title, "x")
       FoundPosY := InStr(title, "y")
       FoundPosZ := InStr(title, "z")
       FoundPosX2 := FoundPosX + 1
       length1 := FoundPosY - FoundPosX2
       FoundPosY2 := FoundPosY + 1
       length2 := FoundPosZ - FoundPosY2
       nr_i := SubStr(title, FoundPosX2, Length1)
       nr_j := SubStr(title, FoundPosY2, Length2)
       if (first_value%nr_i%x%nr_j% != 1){
           Gui, second_sqm%nr_i%x%nr_j%: Color, FF0000
           first_value%nr_i%x%nr_j% := 1
           pos_toFish := "x" . round(topleft_gamewindow2_x + sqm_width2*(nr_i + 0.5)) . "y" . round(topleft_gamewindow2_y + sqm_height2*(nr_j + 0.5))
           fishing2_stack[fishing2_spot[nr_i, nr_j]] := pos_toFish
           arrayChanged2:=1
       }
       else{
           Gui, second_sqm%nr_i%x%nr_j%: Color, ADEBDA
           first_value%nr_i%x%nr_j% := 0
           fishing2_stack.delete(fishing2_spot[nr_i, nr_j])
           arrayChanged2:=1
       }
   }
return

Fishing_gui2GuiClose:
   gosub,Fishing_done2
return

Fishing_done2:
   global execution_allowed := 1
   i := 0
   j := 0
   while (i < 15){
       while (j < 11){
           Gui, second_sqm%i%x%j%: Hide
           j := j + 1
       }
       j := 0
       i := i + 1
   }
   DetectHiddenWindows, On 
   if (winexist("x0y0zAABBCC2"))
      GuiControl, Fishing_gui2:, Fishing_button_text2, show fishing spots
   DetectHiddenWindows, Off
   Gosub, Fishing_restore_windows2
   Gui, Fishing_gui2: Hide
   WinActivate, ahk_id %MainBotWindow%
return


Fishing_restore_windows2:
   Hotkey, ESC, Fishing_restore_windows2, Off
   RestoreCursors()
   Gui, Fishing_selectTopLeft2: Hide
   Gui, Fishing_selectBottomRight2: Hide
   Hotkey, ~LButton, Fishing_selectSqm2, Off
   Hotkey, LButton, Fishing_Mouse_selectTopLeft2, off
   Hotkey, LButton, Fishing_Mouse_selectBottomRight2, off
return

fishing_enabled2:
   GuiControlGet, fishing_enabled2,, fishing_enabled2
   IfWinNotExist, ahk_pid %pid_tibia2%
      {
      if (pid_tibia2 != ""){
         title_tibia2 := "Game client 2 - identyfied by " pid_tibia2
         WinActivate, ahk_pid %pid_tibia2%
         WinWait, ahk_pid %pid_tibia2% 
         WinSetTitle, %title_tibia2%
         sleep, 50
      }
      IfWinNotExist, ahk_pid %pid_tibia2%
      {
         notification(2, title_tibia2, "Window " . title_tibia2 . " doesn't exist.")
         GuiControl,, fishing_enabled2, 0
         
         return
      }
   }
   random_posToFish_template2 := getRandomArrayValue2(fishing2_stack,arrayChanged2)
   arrayChanged2:=0
   DetectHiddenWindows, On
    if (!(winexist("x0y0zAABBCC2")) or random_posToFish_template2 = ""){
      notification(2, title_tibia2, "You should first get spots you want to fish on.")
      GuiControl,, fishing_enabled2, 0
      
      DetectHiddenWindows, Off
   }
   if DllCall("IsWindowVisible", "UInt", WinExist("x0y0zAABBCC2"))
      fishing_sqms_hidden2 := 0
   else 
       fishing_sqms_hidden2 := 1
   if (winexist("x0y0zAABBCC2") and (fishing_sqms_hidden2 = 0)){
      GuiControl, Fishing_gui2:, Fishing_button_text2, show fishing spots
      while (i < 15){
         while (j < 11){
              Gui, second_sqm%i%x%j%: Hide
              j := j + 1
          }
          j := 0
          i := i + 1
      }
   }
   DetectHiddenWindows, Off
   if (fishing_enabled2 = 1){
      SetTimer, fishing_execution, %fishing_time%
   }
return


;################################################################# FISHING EXECUTION ################################################################################
   fishing_execution:
   GuiControlGet, fishing_enabled1,, fishing_enabled1
   if (fishing_enabled1 = 1 and execution_allowed = 1){
      if (!WinExist(title_tibia1)){
         notification(1, "Fishing tool", "Window titled: " . title_tibia1 . " does not exist.")
         GuiControl,,Fishing_enabled1, 0
      }
      If (!WinActive(title_tibia1)){
         goto, Fishing2
      }
      GuiControlGet, Fishing_noFood_enabled1,Fishing_gui1:,Fishing_noFood_enabled1
      if (Fishing_noFood_enabled1 = 1){
         if (find(title_tibia1, "food1", "inventory", 1, 0) = 1) or (find(title_tibia1, "food2", "inventory", 1, 0) = 1) or (find(title_tibia1, "fish", "inventory", 1, 0) = 1) 
            goto, Fishing2
      }
      GuiControlGet, Fishing_noSlot_enabled1,Fishing_gui1:,Fishing_noSlot_enabled1
      if (Fishing_noSlot_enabled1 = 1){
         if find_instances(title_tibia1, "free_slot", 1) < 2
            goto, Fishing2
      }
      pos_notEdited := getRandomArrayValue1(fishing1_stack,arrayChanged1)
      arrayChanged1:=0
      if (pos_notEdited = ""){
         notification(1, "Fishing tool", "Error while loading sqms to fish (0010)")
         goto, Fishing2
      }
      FoundPosY := InStr(pos_notEdited, "y")
      FoundPosY2 := FoundPosY + 1
      length1 := StrLen(pos_notEdited)-FoundPosY
      lenght2 := FoundPosY - 2
      posToFish1_x := SubStr(pos_notEdited, 2, lenght2)
      posToFish1_y := SubStr(pos_notEdited, FoundPosY2, length1)
      if (posToFish1_x = ""){
         notification(1, "Fishing tool", "Error while loading sqms to fish (0011)")
         GuiControl,,Fishing_enabled1, 0
         goto, Fishing2
      }
      if (posToFish1_y = ""){
         notification(1, "Fishing tool", "Error while loading sqms to fish (0012)")
         GuiControl,,Fishing_enabled1, 0
         goto, Fishing2
      }
      if (posToFish1_x < 0 or posToFish1_x > A_ScreenWidth){
         notification(1, "Fishing tool", "Error while loading sqms to fish (0013)")
         GuiControl,,Fishing_enabled1, 0
         goto, Fishing2
      }
      if (posToFish1_y < 0 or posToFish1_y > A_ScreenHeight){
         notification(1, "Fishing tool", "Error while loading sqms to fish (0014)")
         GuiControl,,Fishing_enabled1, 0
         goto, Fishing2
      }
      if (find(title_tibia1, "fishing_rod", "inventory", 1, 0) = 1){
         Random, random_pos_x, -randomization, randomization
         Random, random_pos_y, -randomization, randomization
         posToFish1_x := posToFish1_x + random_pos_x
         posToFish1_y := posToFish1_y + random_pos_y
         KeyWait, LButton
         KeyWait, RButton
         BlockInput, Mouse
         Hotkey, LButton, do_nothing, On
         Hotkey, RButton, do_nothing, On
         sleep_random(5, 10)
         posToFish1_y := posToFish1_y - 35
         item_pos_y := item_pos_y - 35
         if (Bot_protection = 1)
            DllCall("Data\mousehook64.dll\useOn", "AStr", title_tibia1, "INT", false, "INT", item_pos_x, "INT", item_pos_y, "INT", posToFish1_x, "INT", posToFish1_y)
         else
            DllCall("Data\mousehook64.dll\useOn", "AStr", title_tibia1, "INT", true, "INT", item_pos_x, "INT", item_pos_y, "INT", posToFish1_x, "INT", posToFish1_y)   
         sleep_random(5, 10)
         Hotkey, LButton, do_nothing, Off
         Hotkey, RButton, do_nothing, Off
         BlockInput, Off
         Sleep_random(100,200)
         Auto_stack(title_tibia1, "fish")
      }
      else{
         ;notification(1, title_tibia1, "Couldn't find fishing rod in inventory. Fishing will stop now.")
         GuiControl,,Fishing_enabled1, 0
         
      }
   }
   fishing2:
   GuiControlGet, fishing_enabled2,, fishing_enabled2
   if (fishing_enabled2 = 1 and execution_allowed = 1){
      sleep_random(100,300)
      if (!WinExist(title_tibia2)){
         notification(2, "Fishing tool", "Window titled: " . title_tibia2 . " does not exist.")
         GuiControl,,Fishing_enabled2, 0
         return
      }
      If (!WinActive(title_tibia2)){
         return
      }
      GuiControlGet, Fishing_noFood_enabled2,Fishing_gui2:,Fishing_noFood_enabled2
      if (Fishing_noFood_enabled2 = 1){
         if (find(title_tibia1, "food1", "inventory", 1, 0) = 1) or (find(title_tibia1, "food2", "inventory", 1, 0) = 1) or (find(title_tibia1, "fish", "inventory", 1, 0) = 1) 
            return
      }
      GuiControlGet, Fishing_noSlot_enabled2,Fishing_gui2:,Fishing_noSlot_enabled2
      if (Fishing_noSlot_enabled2 = 1){
         if find_instances(title_tibia2, "free_slot", 1) < 2
            return
      }
      pos_notEdited := getRandomArrayValue2(fishing2_stack,arrayChanged2)
      arrayChanged2:=0
      if (pos_notEdited = ""){
         notification(1, "Fishing tool", "Error while loading sqms to fish (0010)")
         return
      }
      FoundPosY := InStr(pos_notEdited, "y")
      FoundPosY2 := FoundPosY + 1
      length1 := StrLen(pos_notEdited)-FoundPosY
      lenght2 := FoundPosY - 2
      posToFish2_x := SubStr(pos_notEdited, 2, lenght2)
      posToFish2_y := SubStr(pos_notEdited, FoundPosY2, length1)
      if (posToFish2_x = ""){
         notification(1, "Fishing tool", "Error while loading sqms to fish (0011)")
         GuiControl,,Fishing_enabled2, 0
         
         return
      }
      if (posToFish2_y = ""){
         notification(1, "Fishing tool", "Error while loading sqms to fish (0012)")
         GuiControl,,Fishing_enabled2, 0
         
         return
      }
      if (posToFish2_x < 0 or posToFish2_x > A_ScreenWidth){
         notification(1, "Fishing tool", "Error while loading sqms to fish (0013)")
         GuiControl,,Fishing_enabled2, 0
         
         return
      }
      if (posToFish2_y < 0 or posToFish2_y > A_ScreenHeight){
         notification(1, "Fishing tool", "Error while loading sqms to fish (0014)")
         GuiControl,,Fishing_enabled2, 0
         
         return
      }
      if  (find(title_tibia2, "fishing_rod", "inventory", 1, 0) = 1){
         Random, random_pos_x, -randomization, randomization
         Random, random_pos_y, -randomization, randomization
         posToFish2_x := posToFish2_x + random_pos_x
         posToFish2_y := posToFish2_y + random_pos_y
         KeyWait, LButton
         KeyWait, RButton
         BlockInput, Mouse
         Hotkey, LButton, do_nothing, On
         Hotkey, RButton, do_nothing, On
         sleep_random(5, 10)
         posToFish2_y := posToFish2_y - 35
         item_pos_y := item_pos_y - 35
         if (Bot_protection = 1)
            DllCall("Data\mousehook64.dll\useOn", "AStr", title_tibia2, "INT", false, "INT", item_pos_x, "INT", item_pos_y, "INT", posToFish2_x, "INT", posToFish2_y)
         else
            DllCall("Data\mousehook64.dll\useOn", "AStr", title_tibia2, "INT", true, "INT", item_pos_x, "INT", item_pos_y, "INT", posToFish2_x, "INT", posToFish2_y)   
         sleep_random(5, 10)
         Hotkey, LButton, do_nothing, Off
         Hotkey, RButton, do_nothing, Off
         BlockInput, Off
         Sleep_random(100,200)
         Auto_stack(title_tibia2, "fish")
      }
      else{
         ;notification(1, title_tibia2, "Couldn't find fishing rod in inventory. Fishing will stop now.")
         GuiControl,,Fishing_enabled2, 0
      }
   }
   GuiControlGet, fishing_enabled1,, fishing_enabled1
   GuiControlGet, fishing_enabled2,, fishing_enabled2
   if (fishing_enabled1 = 0 and fishing_enabled2 = 0)
      Settimer, fishing_execution, off
   return
   
   
;################################################################# MENU ################################################################################

MENU_CREATE:
menu, tray, NoStandard
menu, tray, add, Hide_client_1
menu, tray, add, Hide_client_2
menu, tray, add ; separator
menu, tray, add, Pause
menu, tray, add, Exit
If mc_count = 1
   menu, tray, Disable, Hide_client_2
return


Toggle_hide1:
Hide_client_1:
if NewName1 <> Show_client_1
{
   if winexist(title_tibia1){
      ;WinGetActiveTitle, currently_active_title
      WinSet, Trans, 0,  %title_tibia1%
      WinActivate,  %title_tibia1%
      global transparent_tibia1 := 1
  ;    WinActivate, %currently_active_title%
   }
    OldName1 = Hide_client_1
    NewName1 = Show_client_1
}
else
{
   WinSet, Trans, 255,  %title_tibia1%
   WinActivate, %title_tibia1%
   global transparent_tibia1 := 0
    OldName1 = Show_client_1
    NewName1= Hide_client_1
}
menu, tray, rename, %OldName1%, %NewName1%
return

Toggle_hide2:
Hide_client_2:
if NewName2 <> Show_client_2
{
   if winexist(title_tibia2){
      ;WinGetActiveTitle, currently_active_title
      WinSet, Trans, 0,  %title_tibia2%
      WinActivate,  %title_tibia2%
      global transparent_tibia2 := 1
  ;    WinActivate, %currently_active_title%
   }
    OldName2 = Hide_client_2
    NewName2 = Show_client_2
}
else
{
   WinSet, Trans, 255,  %title_tibia2%
   WinActivate, %title_tibia2%
   global transparent_tibia2 := 0
    OldName2 = Show_client_2
    NewName2= Hide_client_2
}
menu, tray, rename, %OldName2%, %NewName2%
return



; ################################################################# HOTKEYS ################################################################################

!^F11::
Pause:
menu, tray, ToggleCheck, Pause
pause()
return

!^F12::
ExitApp
return


; ################################################################### END ##################################################################################
Exit:
FileExit:     ; User chose "Exit" from the File menu.
GuiClose:  ; User closed the window.
WinSet, Trans, 255,  %title_tibia1%
WinSet, Trans, 255,  %title_tibia2%
ExitApp
