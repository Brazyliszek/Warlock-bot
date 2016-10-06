#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn All, Off    ; #Warn eables warnings to assist with detecting common errors, while "all, off" makes them all disabled
#HotkeyInterval 1000  ; This is  the default value (milliseconds).
#MaxHotkeysPerInterval 200
#MaxThreadsPerHotkey 1
#SingleInstance
; #NoTrayIcon
SendMode Input
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines, -1
SetWinDelay, -1
SetControlDelay, -1
CoordMode, Mouse, Screen 
#Include Gdip_all.ahk                               ; IMPORTANT LIBRARY, AVAILABLE HERE > http://www.autohotkey.net/~Rseding91/Gdip%20All/Gdip_All.ahk

global version := "0.9.4 - beta"
MsgBox, 262208, Important, Hi! `nPlease keep in mind this is version %version%`, which means it still has some bugs and not all function may work propely. Please report all bugs, false alerts, crashes on forum tibiapf.com with every important details in valid thread. `n`nThanks for using my software`, hope you like it. `nMate/Brazyliszek

; created by Mate @tibiapf.com

; project thread: https://tibiapf.com/showthread.php?71-all-versions-Warlock-Bot
; see also: https://tibiapf.com/showthread.php?35-all-versions-Hunter-Bot
; github site: https://github.com/Brazyliszek/Warlock-bot

;################## todos ###################
; pause() might not work propely
; should add to pause as alarm type with its checkboxes
; add record and play macro depending on runemake cycle time
; add reminder to change blank runes (less important)
; add more efficient randomization
; add restore previous active window
; screen alarm goes fuck up when maximizing affected on window from state of deskopt with 0 wins wactive
; lines 261 - should add notification()
; if alarm pauses the bot it stops makking runes after enabling runemaker




; MAIN RULES USING THIS SCRIPT AND FEW TIPS:
; 1) Bot depends on time instead of mana amount to create runes
; 2) Your main backpack must be different than backpacks in which will you store blank and conjured runes (if you're using hand-mode)
; 3) Your left weapon slot must be empty, otherwise object you had in hand may be moved to backpack and you can lose it in case of death (if you're using hand-mode)
; 4) You must take screenshot of a free slot using our tool to take ingame images (if you're using hand-mode)
; 5) Your inventory must be on right side of the screen.
; 6) ImageSearch searches for images from topleft to bottomright side of desired area. Keep that in mind.
; 7) If constantly bot returns "couldn't find free slot on inventory" try to take another image, dont really need to be fully in center.



; latest ver. changelog
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
;
;   0.9.2
;       solved problems with not loading previously saved settings
;       removed tests hotkeys f1 and f2 from public bot version
;       changed auth gui to make password and account name unchangable
;   
;   0.9.1   
;       added inital msgbox, informing about version and where to report bugs

 ; ######################################################################### VARIABLES ##############################################################################
global WalkMethod_IfFood 
global WalkMethod_IfBlank 
global WalkMethod_IfPlayer 
global client_screen_checker 
global img_filename
global sc_temp_img_dir = "Images\select_area.png"
global execution_allowed := 1
global rune_spellname1 
global spelltime1 
global rune_spellname2 
global spelltime2 
global blank_rune_spell
global hand_slot_pos_x
global hand_slot_pos_y
global house_pos_x      
global house_pos_y
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
global steps_to_walk := 7          ; how many sqm bot has to go incase of alarm
global show_notifications := 1     ; if you want notification to be displayed set 1, else 0
global food_time := 100000         ; bot doesnt eat each cicle but rather checks if last eating wasn't earlier than current time - food_time (ms)
global anty_log_time := 300000     ; same as above, but relate of anty_log function
coord_var = 0
tab_window_size_x = 465 
tab_window_size_y = 260 
pic_window_size_x = % tab_window_size_x+40
pic_window_size_y = % tab_window_size_y+40
global BOTnameTR := "Warlock"
global BOTName := "Warlock Bot"
If WinExist("WarlockBot"){
	MsgBox, 16, Error, There is other Warlock bot already running. Application will close now.                   ; prevent from running bot multiple times. may interact in unexpected way, prevention move
	ExitApp
}

checkfiles:
ImgFolder :=  A_ScriptDir . "\Images" 
IfNotExist, %ImgFolder%
   FileCreateDir, %ImgFolder%
IncludeImages := "area_to_check.bmp|background.png|backpack1.bmp|backpack2.bmp|blank_rune.bmp|conjured_rune1.bmp|conjured_rune2.bmp|food1.bmp|food2.bmp|free_slot.bmp|picbp.bmp|select_area.png|tabledone.png|icon.ico|warlockbot_startwin.png"
Loop, Parse, IncludeImages, |
{
   If (!FileExist("Images\" A_LoopField))
   {
   MsgBox, 262193, Something is wrong..., There is lack in files. Couldn't find some images. Do you want to restore them?
   IfMsgBox Ok
      goto Installfiles
   else
      ExitApp
   }
}
IncludeFiles := "alarm_food.mp3|alarm_screen.mp3|alarm_blank.mp3|basic_settings.ini"
Loop, Parse, IncludeFiles, |
{
   If (!FileExist(A_LoopField))
   {
   MsgBox, 262193, Something is wrong..., There is lack in files. Couldn't find some files. Do you want to restore them?
   IfMsgBox Ok
      goto Installfiles
   else
      ExitApp
   }
}




;goto, start_bot                    ; <<----------------------------------------------------------------------------------- temprarly, for tests purpose
;goto, start_initialization
; ######################################################################### AUTHENTICATION #########################################################################

pass_authentication:
Gui, New, +Caption
IniRead, last_used_login, basic_settings.ini, authentication data, last_used_login
IniRead, last_used_pass, basic_settings.ini, authentication data, last_used_pass
last_used_login := "demo"
last_used_pass := "demo"
Gui, Add,edit,x5 y26 w80 h17 vuser, %last_used_login%
Gui, Add,edit,x5 y60 w80 h17 password vpass, %last_used_pass%
Gui, Add,button,x5 y80 h20 w55 gLogin center +BackgroundTrans, Login
Gui, Add,button,x65 y80 h20 w20 gHelp_button center, ?
Gui, Add, Pic, x0 y0 0x4000000, %A_WorkingDir%\Images\warlockbot_startwin.png
Gui, font, bold s8
Gui, Add, Text, x95 y130 w200 vauth_text cWhite +BackgroundTrans, Enter your license account data.
Gui, Show, w287 h149,Authentication
GuiControl, Disable, pass
GuiControl, Disable, user
start_value := 1
return

Help_button:
MsgBox, 0, Help, Version: %version%`nStandard password for beta version is demo/demo. If any other problems occured contact me using data below.`n`nSupport: via privmassage on forum tibiapf.com @Mate`n`n`ngithub site: https://github.com/Brazyliszek/Warlock-bot`nproject thread: https://tibiapf.com/showthread.php?71-all-versions-Warlock-Bot`nsee also: https://tibiapf.com/showthread.php?35-all-versions-Hunter-Bot
return

Login:   
Gui, Font, c00ABFF
Guicontrol, move, auth_text, x200 y130
GuiControl, font, auth_text
GuiControl, text, auth_text, connecting...
If (start_value = 1){
   start_value := 0
   user_name := "demo"
   user_pass := "demo"
   sleep 500
   GuiControlGet, user,, user
   GuiControlGet, pass,, pass
   IniWrite, %user%, basic_settings.ini, authentication data, last_used_login
   IniWrite, %pass%, basic_settings.ini, authentication data, last_used_pass
   If (user != user_name) or (pass != user_pass){
      Guicontrol, move, auth_text, x100 y130
      Gui, Font, cRed
      GuiControl, font, auth_text
      GuiControl, text, auth_text, Wrong login name or password.
      start_value := 1
      return
      }
   else{
      Guicontrol, move, auth_text, x170 y130
      Gui, Font, c00FF11
      GuiControl, font, auth_text
      GuiControl, text, auth_text, Account confirmed!
      sleep, 1500
      Gui, Destroy
      start_value := 1
      gosub, start_initialization
      }
   }
else{
   sleep 1000
   Guicontrol, move, auth_text, x95 y130
   Gui, Font, cRed
   GuiControl, font, auth_text
   GuiControl, text, auth_text, Check your internet connection.
   start_value := 1
   return
}
start_value := 1
return


; ######################################################################### INITIALIZATION  AND GUI ################################################################
start_initialization:
sleep, 500            ; auth gui destroy somehow minimized initial window if it was open too fast
Gui, New, +Caption
IniRead, last_used_client_dir, basic_settings.ini, initialization data, last_used_client_dir
IniRead, last_used_mc_count, basic_settings.ini, initialization data, last_used_mc_count
IniRead, Bot_protection, basic_settings.ini, initialization data, Bot_protection
Gui, Add, Text, x5 y15 +BackgroundTrans, Client location:
Gui, Add, Text, x5 y40 +BackgroundTrans, How many mc?
Gui, Add, edit, x85 y15 w140 h17 vedit_client_dir +ReadOnly, %last_used_client_dir%
Gui, Add, DropDownList, x85 y35 w30 Choose%last_used_mc_count% vmc_count, 1|2
Gui, Add, button, x233 y15 h18 gselect_file,Browse
Gui, Add, button, x187 y128 h20 w50 gCheck_initial_settings,Start
Gui, Add, button, x237 y128 h20 w50 gHelp_initial_button, Help
Gui, Add, Text, x5 y65 +BackgroundTrans, On some servers with good bot protecion functions like`nmove() or use() might not work propely. If you experienced`nsuch issues click on this checkbox to enable mouse`nsimulation on lower level. 
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
IniWrite, %edit_client_dir%, basic_settings.ini, initialization data, last_used_client_dir
IniWrite, %mc_count%, basic_settings.ini, initialization data, last_used_mc_count
IniWrite, %Bot_protection%, basic_settings.ini, initialization data, Bot_protection
IfNotInString, edit_client_dir, exe 
   {   
   TrayTip, %BOTName%, You should enter valid tibia clients file path (*.exe).
   SetTimer, RemoveTrayTip, 3500
   return
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
else{      Gui, Destroy
   gosub, run_clients
   sleep, 500
}
return


run_clients:
SplitPath, edit_client_dir, client_name, client_only_dir        
run, %client_name%, %client_only_dir%, min, pid_tibia1           ; Use ahk_pid to identify a window belonging to a specific process. The process identifier (PID) is typically retrieved by WinGet, Run or Process.
title_tibia1 := "Game client 1 - identyfied by " pid_tibia1
WinActivate, ahk_pid %pid_tibia1%
WinWait, ahk_pid %pid_tibia1% 
WinSetTitle, %title_tibia1%
sleep, 50
WinMinimize, %title_tibia1%
sleep, 500
if (mc_count = 2){
   run, %client_name%, %client_only_dir%, min, pid_tibia2
   title_tibia2 := "Game client 2 - identyfied by " pid_tibia2
   WinActivate, ahk_pid %pid_tibia2%
   WinWait, ahk_pid %pid_tibia2% 
   WinSetTitle, %title_tibia2%
   sleep, 50
   WinMinimize, %title_tibia2%
   sleep, 500
}
if (mc_count = 1 and WinExist(title_tibia1)) or (mc_count = 2 and WinExist(title_tibia1) and WinExist(title_tibia2)){
   last_time_antylog%pid_tibia1% := 0
   last_time_antylog%pid_tibia2% := 0
   last_time_eatfood%pid_tibia1% := 0
   last_time_eatfood%pid_tibia2% := 0
   gosub, start_bot
}
else{
   msgbox,,Error 1098,Tibia clients couldn't be open. Bot will close now.
   ExitApp
}
return

start_bot:
Gui, +HwndMainWindow
Gui, Add, Tab3,x20 y20 w%tab_window_size_x% h%tab_window_size_y%,Main|Alarms|Settings
Gui, Add, GroupBox, x32 y50 w280 h100 , Runemaker
Gui, Add, Text, x72 y70 w40 h20 , Client id
Gui, Add, Text, x132 y70 w90 h20 +Center, Spell name
Gui, Add, Text, x227 y60 w70 h30 +Center, Time bewteen conjuring
Gui, Add, Text, x295 y96 +Center, s
Gui, Add, Text, x295 y126 +Center, s
Gui, Add, Edit, x62 y90 w60 h20 Disabled +Center, %pid_tibia1%
Gui, Add, Edit, x62 y120 w60 h20 Disabled +Center vNotNeeded_pid2, %pid_tibia2%
Gui, Add, Edit, x132 y90 w90 h20 +Center vRune_spellname1, %rune_spellname1%
Gui, Add, Edit, x132 y120 w90 h20 +Center vRune_spellname2, %rune_spellname2%
Gui, Add, Edit, x232 y90 w60 h20 Limit4 Number r1 +Center gCheck_spelltime1 vSpelltime1, %spelltime1%
Gui, Add, Edit, x232 y120 w60 h20 Limit4 Number r1 +Center gCheck_spelltime2 vSpelltime2, %spelltime2%
Gui, Add, CheckBox, x42 y90 w20 h20 +Left vEnabled_runemaking1 gEnabled_runemaking1,
Gui, Add, CheckBox, x42 y120 w20 h20 +Left vEnabled_runemaking2 gEnabled_runemaking2,

Gui, Add, GroupBox, x322 y50 w150 h220 , Configuration
Gui, Add, CheckBox, x332 y70 w120 h20 vEat_food, eat food
Gui, Add, CheckBox, x332 y90 w120 h20 vAnty_log, anty logout
Gui, Add, CheckBox, x332 y110 w130 h20 vOpenNewBackpack, open new backpacks
Gui, Add, CheckBox, x332 y150 w130 h20 vCreate_blank, create blank runes
Gui, Add, CheckBox, x332 y130 w130 h20 vHand_mode, move blanks to hand
Gui, Add, CheckBox, x332 y170 w130 h20 vHouse_deposit, throw runes out
Gui, Add, CheckBox, x332 y190 w130 h20 vAlarms_enabled, alarms enabled
Gui, font, s7
Gui, Add, Text, x332 y235 , Press Ctrl+Alt+F11 to pause
Gui, Add, Text, x332 y250 , Press Ctrl+Alt+F12 to close
Gui, font

Gui, Add, GroupBox, x32 y157 w136 h110 , Screen check config.       
Gui, Add, Text, x42 y179 w50 h20 , Affect on:
Gui, Add, DropDownList, x94 y177 w60 h20 r2 vClient_screen_checker gClient_screen_checker Choose%client_screen_checker%, client 1|client 2
Gui, Add, Text, x42 y204 w53 h20 , Frequency:
Gui, Add, Edit, x102 y202 w35 h18 limit4 center Number vFrequency_screen_checker gFrequency_screen_checker, 500
Gui, Add, Text, x140 y207 w20 h20 , ms
Gui, Add, Checkbox, x42 y222 h20 vDouble_alarm_screen_checker,  Double alarm effect

Gui, Add, Button, x135 y241 w20 h20 gHelp_screen_checker center, ?
Gui, Add, Checkbox, x42 y242 w60 h20 gEnabled_screen_checker vEnabled_screen_checker, Enabled
Gui, Add, GroupBox, x178 y157 w134 h110 , "Alarm" region
Gui, Add, Pic, x202 y178 gArea_screen_checker vImage_screen_checker, %sc_temp_img_dir%

Gui, Tab, 2
Gui, Add, Pic, x33 y57, Images/tabledone.png
Gui, Add, GroupBox, x32 y50 w439 h135 , Alarms setup
Gui, Add, Text, x46 y100 w80 h20 +Right, if no food
Gui, Add, Text, x46 y130 w80 h20 +Right, if no blank runes
Gui, Add, Text, x46 y160 w80 h20 +Right, if screen change
Gui, Add, Text, x142 y60 w40 h30 +Center, do nothing
Gui, Add, Text, x192 y67 w40 h20 +Center, logout
Gui, Add, Text, x242 y60 w40 h30 +Center, play sound
Gui, Add, Text, x289 y60 w46 h30 +Center, shut pc`ndown
Gui, Add, Text, x352 y67 w40 h20 +Center, walk
Gui, Add, Text, x422 y60 w40 h30 +Center, cast`nspell

Gui, Add, CheckBox, x155 y98 w20 h20 vDoNothing_IfFood gDoNothing_IfFood, 
Gui, Add, CheckBox, x205 y98 w20 h20 vLogout_IfFood gLogout_IfFood, 
Gui, Add, CheckBox, x255 y98 w20 h20 vPlaySound_IfFood gPlaySound_IfFood, 
Gui, Add, CheckBox, x305 y98 w20 h20 vShutDown_IfFood gShutDown_IfFood,
Gui, Add, CheckBox, x435 y98 w20 h20 vCastSpell_IfFood,
GuiControl, Disable, CastSpell_IfFood

Gui, Add, CheckBox, x155 y128 w20 h20 vDoNothing_IfBlank gDoNothing_IfBlank, 
Gui, Add, CheckBox, x205 y128 w20 h20 vLogout_IfBlank gLogout_IfBlank,
Gui, Add, CheckBox, x255 y128 w20 h20 vPlaySound_IfBlank gPlaySound_IfBlank,
Gui, Add, CheckBox, x305 y128 w20 h20 vShutDown_IfBlank gShutDown_IfBlank,
Gui, Add, CheckBox, x435 y128 w20 h20 vCastSpell_IfBlank gCastSpell_IfBlank,

Gui, Add, CheckBox, x155 y158 w20 h20 vDoNothing_IfPlayer gDoNothing_IfPlayer,
Gui, Add, CheckBox, x205 y158 w20 h20 vLogout_IfPlayer gLogout_IfPlayer,
Gui, Add, CheckBox, x255 y158 w20 h20 vPlaySound_IfPlayer gPlaySound_IfPlayer,
Gui, Add, CheckBox, x305 y158 w20 h20 vShutDown_IfPlayer gShutDown_IfPlayer,
Gui, Add, CheckBox, x435 y158 w20 h20 vCastSpell_IfPlayer,
GuiControl, Disable, CastSpell_IfPlayer

Gui, Add, DropDownList, x342 y97 w64 h20 r5 vWalkMethod_IfFood gWalkMethod_IfFood Choose%WalkMethod_IfFood% , disabled|north|east|south|west
Gui, Add, DropDownList, x342 y127 w64 h20 r5 vWalkMethod_IfBlank gWalkMethod_IfBlank Choose%WalkMethod_IfBlank% , disabled|north|east|south|west
Gui, Add, DropDownList, x342 y157 w64 h20 r5 vWalkMethod_IfPlayer gWalkMethod_IfPlayer Choose%WalkMethod_IfPlayer% , disabled|north|east|south|west

Gui, Add, text, x33 y190, "Do nothing" means that under this condition bot will continue its procedures. Same with "Play`nsound". Whereas checked any other option will result in immediately stop of rune making and`nlaunching the selected actions. "Walk" means that bot will make few steps to desired direction.`nIt is useful when you are botting runes near houses doors. Few checkbox can be selected`nsimultaneously, for example play sound, logout and walk. In that case you will be alarmed by`nsound instantly, after it bot will try to logout and then will make your character to walk few steps.



Gui, Tab, 3
Gui, Add, GroupBox, x32 y50 w199 h215 , Store your images
Gui, Add, Pic, x43 y77, Images/picbp.bmp
Gui, Add, Pic, x56 y98 gTake_image_conjured_rune1 vconjured_rune1, Images/conjured_rune1.bmp
Gui, Add, Pic, x167 y98 gTake_image_conjured_rune2 vconjured_rune2, Images/conjured_rune2.bmp
Gui, Add, Pic, x56 y135 gTake_image_backpack1 vbackpack1, Images/backpack1.bmp
Gui, Add, Pic, x167 y135 gTake_image_backpack2 vbackpack2, Images/backpack2.bmp
Gui, Add, Pic, x139 y181 gTake_image_food1 vfood1, Images/food1.bmp
Gui, Add, Pic, x176 y181 gTake_image_food2 vfood2, Images/food2.bmp
Gui, Add, Pic, x93 y209 gTake_image_blank_rune vblank_rune, Images/blank_rune.bmp
Gui, Add, Pic, x161 y203 gTake_image_free_slot vfree_slot, Images/free_slot.bmp

Gui, Add, GroupBox, x240 y50 w232 h140 , Basic settings
Gui, Add, Text, x250 y70 w100 h40 , Spell to cast in case of no blank runes:
Gui, Add, Text, x250 y104 w100 h20, say this spell
Gui, Add, Text, x340 y104 w100 h20, times each cicle.

Gui, Add, Text, x250 y130 w100 h20 , throw made runes to:
Gui, Add, Text, x440 y130 w30 h20 , (x`, y)
Gui, Add, Text, x250 y160 w100 h20 , hand slot position:
Gui, Add, Text, x440 y160 w30 h20 , (x`, y)

Gui, Add, Edit, x354 y74 w100 h20 center vSpell_to_cast_name, %Spell_to_cast_name%
Gui, Add, Edit, x314 y100 w20 h20 center number limit2 vSpell_to_cast_count gCheck_spell_to_cast_count, %Check_spell_to_cast_count%
Gui, Add, Edit, x354 y128 w40 h20 center vhouse_pos_x gCheck_house_pos_x, %house_pos_x%
Gui, Add, Edit, x395 y128 w40 h20 center vhouse_pos_y gCheck_house_pos_y, %house_pos_y%
Gui, Add, Edit, x354 y158 w40 h20 center vhand_slot_pos_x gCheck_hand_slot_pos_x, %hand_slot_pos_x%
Gui, Add, Edit, x395 y158 w40 h20 center vhand_slot_pos_y gCheck_hand_slot_pos_y, %hand_slot_pos_y%

; set position of coordinates shower
Gui, Add, GroupBox, x240 y195 w232 h70 , Obtain on-screen position
posx_coord_zero = % (tab_window_size_x - 227)
posy_coord_zero = % (tab_window_size_y - 34)
x1 = % posx_coord_zero+13
y1 = % posy_coord_zero+0
x2 = % posx_coord_zero+27
y2 = % posy_coord_zero-4
x3 = % posx_coord_zero+67
y3 = % posy_coord_zero+0
x4 = % posx_coord_zero+81
y4 = % posy_coord_zero-4
x5 = % posx_coord_zero+125
y5 = % posy_coord_zero-11
Gui,Add,Text,x%x1% y%y1% w10 h13,X:
Gui,Add,Edit,x%x2% y%y2% w35 h21 vposx_mouse_coord center +ReadOnly,%posx_mouse_coord%
Gui,Add,Text,x%x3% y%y3% w10 h13,Y:
Gui,Add,Edit,x%x4% y%y4% w35 h21 vposy_mouse_coord center +ReadOnly,%posy_mouse_coord%
Gui,Add,Button,x%x5% y%y5% w100 h35 gdisplay_coord vdisplay_coord,Display coordinates


Gui,Tab
if (mc_count = 1){                                       ; disabling few functions in case if only one client was turned on
   GuiControl, Disable, Enabled_runemaking2
   GuiControl, Disable, Rune_spellname2
   GuiControl, Disable, Spelltime2
   GuiControl, Disable, Client_screen_checker
   GuiControl, Choose, Client_screen_checker, 1
   GuiControl, Disable, Double_alarm_screen_checker
   GuiControl,, Double_alarm_screen_checker, 0
   GuiControl,, NotNeeded_pid2, 0000
}


Gui,Add, Pic, x0 y0 w%pic_window_size_x% h%pic_window_size_y% 0x4000000, %A_WorkingDir%\Images\background.png
Gui,Show, w%pic_window_size_x% h%pic_window_size_y%, %BOTName%

IniRead, randomization, basic_settings.ini, conf values, randomization
IniRead, steps_to_walk, basic_settings.ini, conf values, steps_to_walk
IniRead, show_notifications, basic_settings.ini, conf values, show_notifications
IniRead, blank_rune_spell, basic_settings.ini, conf values, blank_rune_spell
IniRead, food_time, basic_settings.ini, conf values, food_time
IniRead, anty_log_time, basic_settings.ini, conf values, anty_log_time

IniRead, Rune_spellname1, basic_settings.ini, bot variables, Rune_spellname1
IniRead, Rune_spellname2, basic_settings.ini, bot variables, Rune_spellname2
IniRead, Spelltime1, basic_settings.ini, bot variables, Spelltime1
IniRead, Spelltime2, basic_settings.ini, bot variables, Spelltime2
IniRead, Eat_food, basic_settings.ini, bot variables, Eat_food
IniRead, Anty_log, basic_settings.ini, bot variables, Anty_log
IniRead, OpenNewBackpack, basic_settings.ini, bot variables, OpenNewBackpack
IniRead, Create_blank, basic_settings.ini, bot variables, Create_blank
IniRead, Hand_mode, basic_settings.ini, bot variables, Hand_mode
IniRead, House_deposit, basic_settings.ini, bot variables, House_deposit
IniRead, Frequency_screen_checker, basic_settings.ini, bot variables, Frequency_screen_checker
IniRead, DoNothing_IfFood, basic_settings.ini, bot variables, DoNothing_IfFood
IniRead, Logout_IfFood, basic_settings.ini, bot variables,  Logout_IfFood
IniRead, PlaySound_IfFood, basic_settings.ini, bot variables,  PlaySound_IfFood
IniRead, ShutDown_IfFood, basic_settings.ini, bot variables, ShutDown_IfFood
IniRead, DoNothing_IfBlank, basic_settings.ini, bot variables, DoNothing_IfBlank
IniRead, Logout_IfBlank, basic_settings.ini, bot variables, Logout_IfBlank
IniRead, PlaySound_IfBlank, basic_settings.ini, bot variables,  PlaySound_IfBlank
IniRead, ShutDown_IfBlank, basic_settings.ini, bot variables, ShutDown_IfBlank
IniRead, CastSpell_IfBlank, basic_settings.ini, bot variables, CastSpell_IfBlank 
IniRead, DoNothing_IfPlayer, basic_settings.ini, bot variables, DoNothing_IfPlayer
IniRead, Logout_IfPlayer, basic_settings.ini, bot variables, Logout_IfPlayer
IniRead, PlaySound_IfPlayer, basic_settings.ini, bot variables, PlaySound_IfPlayer
IniRead, ShutDown_IfPlayer, basic_settings.ini, bot variables, ShutDown_IfPlayer
IniRead, WalkMethod_IfFood, basic_settings.ini, bot variables, WalkMethod_IfFood
IniRead, WalkMethod_IfBlank, basic_settings.ini, bot variables, WalkMethod_IfBlank
IniRead, WalkMethod_IfPlayer, basic_settings.ini, bot variables, WalkMethod_IfPlayer
IniRead, Spell_to_cast_name, basic_settings.ini, bot variables, Spell_to_cast_name
IniRead, Spell_to_cast_count, basic_settings.ini, bot variables, Spell_to_cast_count
IniRead, house_pos_x, basic_settings.ini, bot variables, house_pos_x
IniRead, house_pos_y, basic_settings.ini, bot variables, house_pos_y
IniRead, hand_slot_pos_x, basic_settings.ini, bot variables, hand_slot_pos_x
IniRead, hand_slot_pos_y, basic_settings.ini, bot variables, hand_slot_pos_y

GuiControl,, Rune_spellname1, %Rune_spellname1%
GuiControl,, Rune_spellname2, %Rune_spellname2%
GuiControl,, Spelltime1, %Spelltime1%
GuiControl,, Spelltime2, %Spelltime2%
GuiControl,, Eat_food, %Eat_food%
GuiControl,, Anty_log, %Anty_log%
GuiControl,, OpenNewBackpack, %OpenNewBackpack%
GuiControl,, Create_blank, %Create_blank%
GuiControl,, Hand_mode, %Hand_mode%
GuiControl,, House_deposit, %House_deposit%
GuiControl,, Frequency_screen_checker, %Frequency_screen_checker%
GuiControl,, DoNothing_IfFood, %DoNothing_IfFood%
GuiControl,, Logout_IfFood, %Logout_IfFood%
GuiControl,, PlaySound_IfFood, %PlaySound_IfFood%
GuiControl,, ShutDown_IfFood, %ShutDown_IfFood%
GuiControl,, DoNothing_IfBlank, %DoNothing_IfBlank%
GuiControl,, Logout_IfBlank, %Logout_IfBlank%
GuiControl,, PlaySound_IfBlank, %PlaySound_IfBlank%
GuiControl,, ShutDown_IfBlank, %ShutDown_IfBlank%
GuiControl,, CastSpell_IfBlank, %CastSpell_IfBlank%
GuiControl,, DoNothing_IfPlayer, %DoNothing_IfPlayer%
GuiControl,, Logout_IfPlayer, %Logout_IfPlayer%
GuiControl,, PlaySound_IfPlayer, %PlaySound_IfPlayer%
GuiControl,, ShutDown_IfPlayer, %ShutDown_IfPlayer%
GuiControl, Choose, WalkMethod_IfFood, %WalkMethod_IfFood%
GuiControl, Choose, WalkMethod_IfBlank, %WalkMethod_IfBlank%
GuiControl, Choose, WalkMethod_IfPlayer, %WalkMethod_IfPlayer%
GuiControl,, Spell_to_cast_name, %Spell_to_cast_name%
GuiControl,, Spell_to_cast_count, %Spell_to_cast_count%
GuiControl,, house_pos_x, %house_pos_x%
GuiControl,, house_pos_y, %house_pos_y%
GuiControl,, hand_slot_pos_x, %hand_slot_pos_x%
GuiControl,, hand_slot_pos_y, %hand_slot_pos_y%

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


#Persistent               ; to overwrite settings only if main window has been shown
OnExit("save")


return

; ######################################################################### MAIN #########################################################################
Enabled_runemaking1:
   GuiControlGet, Enabled_runemaking1,, Enabled_runemaking1
   GuiControlGet, Enabled_runemaking2,, Enabled_runemaking2
   GuiControlGet, Spelltime1,, Spelltime1
   GuiControlGet, Rune_spellname1,, Rune_spellname1
   IfWinNotExist, %title_tibia1%
      {
      notification(client_id, "Window " . title_tibia1 . " doesn't exist.")
      GuiControl,, Enabled_runemaking1, 0
      Check_gui()
      return
   }
   if (Spelltime1 = ""){
      Notification(title_tibia1, "Please enter valid spell time.")
      GuiControl,, Enabled_runemaking1, 0
      Check_gui()
      return
   }
   if (Rune_spellname1 = ""){
      Notification(title_tibia1, "Please enter valid spell name.")
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
   GuiControlGet, Rune_spellname2,, Rune_spellname2
   IfWinNotExist, %title_tibia2%
      {
      notification(client_id, "Window " . title_tibia2 . " doesn't exist.")
      GuiControl,, Enabled_runemaking2, 0      
      Check_gui()
      return
   }
   if (Spelltime2 = ""){
      Notification(title_tibia2, "Please enter valid spell time.")
      GuiControl,, Enabled_runemaking2, 0
      Check_gui()
      return
   }
   if (Rune_spellname2 = ""){
      Notification(title_tibia2, "Please enter valid spell name.")
      GuiControl,, Enabled_runemaking2, 0      
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
   IfWinNotExist, %title_tibia1%
      {
      notification(client_id, "Window " . title_tibia1 . " doesn't exist.")
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
   eat_food(title_tibia1)
   sleep_random(10,100)
   anty_logout(title_tibia1)
   sleep_random(10,100)
   if (mc_count = 2){
      GuiControlGet, Enabled_runemaking1,, Enabled_runemaking1
      GuiControlGet, Enabled_runemaking2,, Enabled_runemaking2
      GuiControlGet, Client_screen_checker,,Client_screen_checker
      if ((client_screen_checker = "client 1") and (Enabled_runemaking1 = 1)){
         IfWinNotActive, %title_tibia1%
            WinActivate, %title_tibia1%
         WinWaitActive, %title_tibia1%
      }
      else if ((client_screen_checker = "client 2") and (Enabled_runemaking2 = 1)){
         IfWinNotActive, %title_tibia2%
            WinActivate, %title_tibia2%
         WinWaitActive, %title_tibia2%
      }
   }
   global execution_allowed := 1
return

Rune_execution2:
   Critical
   global execution_allowed := 0
   IfWinNotExist, %title_tibia2%
      {
      notification(client_id, "Window " . title_tibia2 . " doesn't exist.")
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
   eat_food(title_tibia2)
   sleep_random(10,100)
   anty_logout(title_tibia2)
   sleep_random(10,100)
   if (mc_count = 2){
      GuiControlGet, Enabled_runemaking1,, Enabled_runemaking1
      GuiControlGet, Enabled_runemaking2,, Enabled_runemaking2
      GuiControlGet, Client_screen_checker,,Client_screen_checker
      if ((client_screen_checker = "client 1") and (Enabled_runemaking1 = 1)){
         IfWinNotActive, %title_tibia1%
            WinActivate, %title_tibia1%
         WinWaitActive, %title_tibia1%
      }
      if ((client_screen_checker = "client 2") and (Enabled_runemaking2 = 1)){
         IfWinNotActive, %title_tibia2%
            WinActivate, %title_tibia2%
         WinWaitActive, %title_tibia2%
      }
   }
   global execution_allowed := 1
return

; ######################################################################### FUNCTIONS ##############################################################################


runemake(client_id, client_number){
   GuiControlGet, Enabled_runemaking1,, Enabled_runemaking1
   GuiControlGet, Enabled_runemaking2,, Enabled_runemaking2
   if (((client_id = title_tibia1) and (Enabled_runemaking1 = 0)) or ((client_id = title_tibia2) and (Enabled_runemaking2 = 0)))
      return
   backpack_id := "backpack" . client_number                  ; this declaration is needed for now
   rune_spellname_id := "rune_spellname" . client_number
   conjured_rune_id := "conjured_rune" . client_number
   GuiControlGet, openNewBackpack,, openNewBackpack
   GuiControlGet, hand_mode,, hand_mode
   GuiControlGet, house_deposit,, house_deposit
   GuiControlGet, create_blank,, create_blank
   GuiControlGet, rune_spellname,, %rune_spellname_id%
   GuiControlGet, DoNothing_IfBlank,,DoNothing_IfBlank
   if (create_blank = 1){
      say(client_id, blank_rune_spell)        
      sleep_random(1500,2000)
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
      if (find(client_id, "blank_rune", "hand_slot", 1, 0) = 0)
         notification(client_id, "Couldn't find blank rune on hand slot.")
   }
   sleep_random(300,700)
   say(client_id, rune_spellname)
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
         notification(client_id, "Couldn't find conjured rune on screen. Can't throw it on desired position.")
   }
   else if (house_deposit = 1 and hand_mode = 0){
      if (find(client_id, conjured_rune_id, "inventory", 1, 0) = 1){
         sleep_random(300,700)
         move(client_id, conjured_rune_id, "house")
         return
      }
      else
         notification(client_id, "Couldn't find conjured rune on screen. Can't throw it on desired position.")
   }
   else if (house_deposit = 0 and hand_mode = 1){
      freeslot_check:
      if (find(client_id, "free_slot", "inventory", 1, 0) = 0){
         if (find(client_id, backpack_id, "inventory", 1, 0) = 0){
            notification(client_id, "Couldn't find free slot.")
         }
         else{
            use(client_id, backpack_id)
            goto freeslot_check
         }
      }
      else{
         sleep_random(300,700)
         move(client_id, "hand", "free_slot")
         return
      }
   }
   else
      return
sleep_random(500,900)
return
}


alarm(client_id, type){
   GuiControlGet, Alarms_enabled,,Alarms_enabled
   if Alarms_enabled = 0
      return   
   IfInString, client_id, Game client 1             
      client_number := 1
   else
      client_number := 2
   if (type = "food"){
      GuiControlGet, DoNothing_IfFood,,DoNothing_IfFood
      GuiControlGet, Logout_IfFood,,Logout_IfFood
      GuiControlGet, PlaySound_IfFood,,PlaySound_IfFood
      GuiControlGet, ShutDown_IfFood,,ShutDown_IfFood
      GuiControlGet, WalkMethod_IfFood,,WalkMethod_IfFood
      Notification(client_id, "Couldn't find food in inventory.")
      if (DoNothing_IfFood = 1)
         return
      if (Logout_IfFood = 1){         
         GuiControl,, Enabled_runemaking%client_number%, 0
         Check_gui()
         logout(client_id)
      }
      if (WalkMethod_IfFood != "disabled"){         
         GuiControl,, Enabled_runemaking%client_number%, 0
         Check_gui()
         walk(client_id, WalkMethod_IfFood, steps_to_walk)
      }
      if (PlaySound_IfFood = 1){
         sound("alarm_food.mp3")
      }
      if (ShutDown_IfFood = 1){
         GuiControl,, Enabled_runemaking%client_number%, 0
         Check_gui()
         shutdown()
         pause("on", 1)
      }
      return 1
   }
   if (type = "blank_runes"){
      GuiControlGet, DoNothing_IfBlank,,DoNothing_IfBlank
      GuiControlGet, Logout_IfBlank,,Logout_IfBlank
      GuiControlGet, PlaySound_IfBlank,,PlaySound_IfBlank
      GuiControlGet, ShutDown_IfBlank,,ShutDown_IfBlank
      GuiControlGet, WalkMethod_IfBlank,,WalkMethod_IfBlank
      GuiControlGet, CastSpell_IfBlank,,CastSpell_IfBlank
      Notification(client_id, "Couldn't find blank rune in inventory.")
      if (DoNothing_IfBlank = 1)
         return
      if (Logout_IfBlank = 1){
         GuiControl,, Enabled_runemaking%client_number%, 0
         Check_gui()
         logout(client_id)
      }
      if (WalkMethod_IfBlank != "disabled"){
         GuiControl,, Enabled_runemaking%client_number%, 0
         Check_gui()
         walk(client_id, WalkMethod_IfBlank, steps_to_walk)
      }
      if (PlaySound_IfBlank = 1){
         sound("alarm_blank.mp3")
      }
      if (ShutDown_IfBlank = 1){
         GuiControl,, Enabled_runemaking%client_number%, 0
         Check_gui()
         shutdown()
         pause("on", 1)
      }
      if (CastSpell_IfBlank = 1){
         GuiControlGet, Spell_to_cast_name,,Spell_to_cast_name
         GuiControlGet, Spell_to_cast_count,,Spell_to_cast_count
         say(client_id,Spell_to_cast_name)
         temp_count = 1
         emergency_spellcaster:
         if (Spell_to_cast_count - temp_count > 0){
            sleep_random(2000,2200)
            say(client_id,Spell_to_cast_name)
            temp_count = % temp_count + 1
            goto, emergency_spellcaster
         }
      }
      
      return 1
   }
   if (type = "player"){
      GuiControlGet, DoNothing_IfPlayer,,DoNothing_IfPlayer
      GuiControlGet, Logout_IfPlayer,,Logout_IfPlayer
      GuiControlGet, PlaySound_IfPlayer,,PlaySound_IfPlayer
      GuiControlGet, ShutDown_IfPlayer,,ShutDown_IfPlayer
      GuiControlGet, WalkMethod_IfPlayer,,WalkMethod_IfPlayer
      Notification(client_id, "There was a change on screen-check region.")
      if (DoNothing_IfPlayer = 1)
         return
      if (Logout_IfPlayer = 1){
         GuiControl,, Enabled_runemaking%client_number%, 0
         Check_gui()
         logout(client_id)
      }
      if (WalkMethod_IfPlayer != "disabled"){
         walk(client_id, WalkMethod_IfPlayer, steps_to_walk)
         GuiControl,, Enabled_runemaking%client_number%, 0
         Check_gui()
      }
      if (PlaySound_IfPlayer = 1){
         sound("alarm_screen.mp3")
      }
      if (ShutDown_IfPlayer = 1){
         GuiControl,, Enabled_runemaking%client_number%, 0
         Check_gui()
         shutdown()
         pause("on", 1)
      }
      return 1
   }
   
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
   if (((client_id = title_tibia1) and (Enabled_runemaking1 = 0)) or ((client_id = title_tibia2) and (Enabled_runemaking2 = 0)))
      return
   GuiControlGet, eat_food,,eat_food
   if eat_food = 0
      return
   if (client_id contains pid_tibia1)
      pid_tibia = %pid_tibia1%
   else
      pid_tibia = %pid_tibia2%
   if (A_tickcount - last_time_eatfood%pid_tibia%) < food_time
      return
   IfWinNotActive, %client_id%
      WinActivate, %client_id%
   WinWaitActive, %client_id%
   if (find(client_id, "food1", "inventory", 1, 0) = 1){
      last_time_eatfood%pid_tibia% := A_TickCount
      use(client_id, "food1")
      sleep_random(200,500)
      use(client_id, "food1")
      sleep_random(200,500)
      use(client_id, "food1")
      sleep_random(200,500)
   }
   else if (find(client_id, "food2", "inventory", 1, 0) = 1){
      last_time_eatfood%pid_tibia% := A_TickCount
      use(client_id, "food2")
      sleep_random(200,500)
      use(client_id, "food2")
      sleep_random(200,500)
      use(client_id, "food2")
      sleep_random(200,500)
   }
   else
      alarm(client_id, "food")
 ;  msgbox, client_id %client_id%,`n Enabled_runemaking1 %Enabled_runemaking1%,`n Enabled_runemaking2 %Enabled_runemaking2%,`n title_tibia1 %title_tibia1%,`n eat_food %eat_food%,`n pid_tibia %pid_tibia%,`n last_time_eatfood%pid_tibia%
}
return


anty_logout(client_id){                       ;  don't need window to be active
   GuiControlGet, Enabled_runemaking1,, Enabled_runemaking1
   GuiControlGet, Enabled_runemaking2,, Enabled_runemaking2
   if (((client_id = title_tibia1) and (Enabled_runemaking1 = 0)) or ((client_id = title_tibia2) and (Enabled_runemaking2 = 0)))
      return
   GuiControlGet, anty_log,,anty_log
   if anty_log = 0
      return
   if (client_id contains pid_tibia1)
      pid_tibia = %pid_tibia1%
   else
      pid_tibia = %pid_tibia2%
   if (A_tickcount - last_time_antylog%pid_tibia%) < anty_log_time
      return
   BlockInput, On
   ControlSend,, {Ctrl down}, %client_id%
   sleep_random(10, 50)
   ControlSend,, {Up}, %client_id%
   sleep_random(100, 500)
   ControlSend,, {Down}, %client_id%
   sleep_random(10, 50)
   ControlSend,, {ctrl up}, %client_id%
   sleep_random(100, 500)
   BlockInput, Off
   last_time_antylog%pid_tibia% := A_TickCount
   sleep_random(500,900)
}
return

move(client_id,object,destination){
   IfWinNotExist, %client_id%
   {
      notification(client_id, "Window " . client_id . " doesn't exist.")
      return
   }
   IfWinNotActive, %client_id%
      WinActivate, %client_id%
   WinWaitActive, %client_id%
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
      GuiControlGet, house_pos_x,, house_pos_x
      GuiControlGet, house_pos_y,, house_pos_y
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
      BlockInput, On
      MouseGetPos, prev_pos_x, prev_pos_y
      CoordMode, Mouse, Screen 
      SendMode, Event
      MouseClickDrag, left, %object_pos_x%, %object_pos_y%, %destination_pos_x%, %destination_pos_y%,2
      SendMode, Input
      MouseMove, prev_pos_x, prev_pos_y
      BlockInput, Off
   }
   else
      notification(client_id, "There was a problem with position in function move()")
}
return

use(client_id, object){
   IfWinNotExist, %client_id%
   {
       notification(client_id, "Window " . client_id . " doesn't exist.")
      return
   }
   IfWinNotActive, %client_id%
      WinActivate, %client_id%
   WinWaitActive, %client_id%
   global item_pos_x
   global item_pos_y
   if ((object = "blank_rune") or (object = "conjured_rune1") or (object = "conjured_rune2") or (object = "free_slot") or (object = "food1") or (object = "food2") or (object = "backpack1") or (object = "backpack2")){
      region = "inventory"
   }
   else
      region = "screen"
   find(client_id, object, region, 1, 0)
   if ((item_pos_x != "") and (item_pos_y != "")){
      BlockInput, On
      SetControlDelay -1
      if (Bot_protection = 1){
         MouseClick, Right, %item_pos_x%, %item_pos_y%, 1
      }
      else{
         ControlClick, x%item_pos_x% y%item_pos_y%, %Client_id%,, Right, 1, NA
         if (ErrorLevel = 1){
            notification(client_id, "There was a problem in use " . object . " on position x" . %item_pos_x% . " y" . %item_pos_y% . ".")
         }
      }
   }
   else
      notification(client_id, "There was a problem in use " . object . " on position x(empty) y(empty).")
   BlockInput, Off
}
return



logout(client_id){
   pause("on", 1)
   IfWinNotExist, %client_id%
   {
       notification(client_id, "Window " . client_id . " doesn't exist. Logout procedure cannot continue.")
      return
   }
   BlockInput, On
   ControlSend,, {Ctrl down}{l}{ctrl up}, %client_id%
   BlockInput, Off
   sleep_random(100, 200)
   BlockInput, On
   ControlSend,, {Ctrl down}{l}{ctrl up}, %client_id%
   BlockInput, Off
   sleep_random(100, 200)
   BlockInput, On
   ControlSend,, {Ctrl down}{l}{ctrl up}, %client_id%
   BlockInput, Off
}
return


sound(file_dir){
   SoundPlay, %file_dir%, wait
}
return



walk(client_id, walk_dir, steps){
   local i := 0
   walk_label:
   if ((walk_dir = "north") and (i <= steps)){
      ControlSend,,{Up}, %client_id%
      sleep_random(200, 250)
      i++
      goto, walk_label
   }
   if ((walk_dir = "south") and (i <= steps)){
      ControlSend,,{Down}, %client_id%
      sleep_random(200, 250)
      i++
      goto, walk_label
   }
   if ((walk_dir = "east") and (i <= steps)){
      ControlSend,,{Right}, %client_id%
      sleep_random(200, 250)
      i++
      goto, walk_label
   }
   if ((walk_dir = "west") and (i <= steps)){
      ControlSend,,{Left}, %client_id%
      sleep_random(200, 250)
      i++
      goto, walk_label
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

pause(status, finish_current_thread){              ; set 1 to let finish current thread, set 0 to pause immediately
   if (status = "on"){
     ; Suspend, On 
      Pause, On, %finish_current_thread%

   }
   if (status = "off"){
     ; Suspend, Off  
      Pause, Off, %finish_current_thread%
   }
   if (status = "toggle"){
     ; Suspend, Toggle  
      Pause, Toggle, %finish_current_thread%
   }
   
   if (A_IsPaused = 1){
      WinSetTitle,, Warlock, Warlock Bot - paused 
      global BOTName = "Warlock Bot - paused"
   }
   else{
      GuiControlGet, Spelltime1,, Spelltime1
      GuiControlGet, Spelltime2,, Spelltime2
      if ((A_TickCount - planned_time1) > Spelltime1*1000){
         global planned_time1 := % A_TickCount + 5000
      }
      if ((A_TickCount - planned_time2) > Spelltime2*1000){
         global planned_time2 := % A_TickCount + 10000
      }
      WinSetTitle,, Warlock, Warlock Bot
      global BOTName = "Warlock Bot"
   }
}
return



notification(client_id, text){
   global show_notifications
   if (show_notifications = 1){
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
         notification(client_id, "Window " . client_id . " doesn't exist.")
         return
      }
   IfWinNotActive, %client_id%
      WinActivate, %client_id%
   WinWaitActive, %client_id%
   global image_name := A_WorkingDir . "\Images\" . object . ".bmp"
   if ( region = "inventory" ){
      start_x := % 3*A_ScreenWidth/4
      start_y := 0
      end_x := A_ScreenWidth
      end_y := A_ScreenHeight
   }
   else if ( region = "hand_slot" ){
      GuiControlGet, hand_slot_pos_x,, hand_slot_pos_x
      GuiControlGet, hand_slot_pos_y,, hand_slot_pos_y
      start_x := % hand_slot_pos_x - 30
      start_y := % hand_slot_pos_y - 30
      end_x := % hand_slot_pos_x + 30
      end_y := % hand_slot_pos_y + 30
   }
   else{
      start_x := 0
      start_y := 0
      end_x := A_ScreenWidth
      end_y := A_ScreenHeight
   }
   CoordMode, Pixel
   Imagesearch, object_pos_x, object_pos_y, %start_x%, %start_y%, %end_x%, %end_y%, *20 %image_name%
   if (ErrorLevel = 1){
      if (notification != 0)
         notification(client_id, "Couldn't find " . object . " on " . region . ".")
      global item_pos_x := ""
      global item_pos_y := ""
      return 0
   }
   else if (ErrorLevel = 2){
      if (notification != 0)
         notification(client_id, "Couldn't find " . object . " image file.")
      global item_pos_x := ""
      global item_pos_y := ""
      return 0
   }
   else{
      global item_pos_x := object_pos_x
      global item_pos_y := object_pos_y
      if (center = 1){
         GDIPToken := Gdip_Startup()                                     
         pBM := Gdip_CreateBitmapFromFile( image_name )                 
         image_width := Gdip_GetImageWidth( pBM )
         image_height := Gdip_GetImageHeight( pBM )   
         Gdip_DisposeImage( pBM )                                          
         Gdip_Shutdown( GDIPToken )
         global item_pos_x := % Round(object_pos_x + image_width/2)
         global item_pos_y := % Round(object_pos_y + image_height/2)
      }
      return 1
   }
}
CoordMode, Mouse, Screen
return




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
   WinMinimize, %MainWindow%
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
   outfile := "Images\" . img_filename . ".bmp"
   pic_name := "pic_" . img_filename
   Area := ess_x "|" ess_y "|" img_width "|" img_height
   pToken := Gdip_Startup()
   pBitmap := Gdip_BitmapFromScreen(Area)
   Gdip_SaveBitmapToFile(pBitmap, outfile, 100)
   Gdip_DisposeImage(pBitmap)
   Gdip_Shutdown(pToken)
   Gui, Screenshoot_window: Hide
   WinRestore, %BOTnameTR%
   Notification("Succes!", "Item saved as " . outfile . ".")
   global screenshooter_active := 0
   if (img_filename = "area_to_check"){
      area_start_x := round(ess_x)
      area_start_y := round(ess_y)
      GuiControl,, Image_screen_checker, %outfile%
      global sc_temp_img_dir = % outfile
   }
   else
      GuiControl,, %img_filename%, %outfile%
return

take_screen_shot_off:
   Hotkey, LButton, take_screen_shot, Off
   Hotkey, Esc, take_screen_shot_off, Off
   Gui, Screenshoot_window: Hide
   Gui, screen_box: Cancel
   SetTimer, move_box, Off
   WinRestore, %BOTnameTR%
   global screenshooter_active := 0
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
   take_screenshot("free_slot", 38, 38)
return


ConnectedToInternet(flag=0x40) { 
Return DllCall("Wininet.dll\InternetGetConnectedState", "Str", flag,"Int",0) 
}


WM_MOUSEMOVE()
{
   if winactive(%BotName%){
    static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
    CurrControl := A_GuiControl
    If (CurrControl <> PrevControl and not InStr(CurrControl, " "))
    {
        ToolTip  ; Turn off any previous tooltip.
        SetTimer, DisplayToolTip, 1000
        PrevControl := CurrControl
    }
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

Display_coord:
GuiControl,, display_coord, Press space to stop
SetTimer, Check_coordinates, 100
coord_var = % coord_var + 1
return

Check_coordinates:
If mod(coord_var, 2) == 1
{
Hotkey, space, coordinates_stop, on
CoordMode, Mouse, Screen 
MouseGetPos, posx_temp, posy_temp
GuiControl,,posx_mouse_coord,%posx_temp%
GuiControl,,posy_mouse_coord,%posy_temp%
}
else{
   Hotkey, space, coordinates_stop, off
   GuiControl,, display_coord, Display coordinates
}
return

coordinates_stop:                               ; needed in show coordinates displayer
If mod(coord_var, 2) == 1
    coord_var = % coord_var + 1
return


save(){
   GuiControlGet, Rune_spellname1,, Rune_spellname1
   GuiControlGet, Rune_spellname2,, Rune_spellname2
   GuiControlGet, Spelltime1,, Spelltime1
   GuiControlGet, Spelltime2,, Spelltime2
   GuiControlGet, Eat_food,, Eat_food
   GuiControlGet, Anty_log,, Anty_log
   GuiControlGet, OpenNewBackpack,, OpenNewBackpack
   GuiControlGet, Create_blank,, Create_blank
   GuiControlGet, Hand_mode,, Hand_mode
   GuiControlGet, House_deposit,, House_deposit
   GuiControlGet, Frequency_screen_checker,, Frequency_screen_checker
   GuiControlGet, DoNothing_IfFood ,, DoNothing_IfFood
   GuiControlGet, Logout_IfFood,,  Logout_IfFood
   GuiControlGet, PlaySound_IfFood,,  PlaySound_IfFood
   GuiControlGet, ShutDown_IfFood,, ShutDown_IfFood
   GuiControlGet, DoNothing_IfBlank,, DoNothing_IfBlank
   GuiControlGet, Logout_IfBlank,, Logout_IfBlank
   GuiControlGet, PlaySound_IfBlank,,  PlaySound_IfBlank
   GuiControlGet, ShutDown_IfBlank,, ShutDown_IfBlank
   GuiControlGet, CastSpell_IfBlank,, CastSpell_IfBlank 
   GuiControlGet, DoNothing_IfPlayer,, DoNothing_IfPlayer
   GuiControlGet, Logout_IfPlayer,, Logout_IfPlayer
   GuiControlGet, PlaySound_IfPlayer,, PlaySound_IfPlayer
   GuiControlGet, ShutDown_IfPlayer,, ShutDown_IfPlayer
   GuiControlGet, WalkMethod_IfFood,, WalkMethod_IfFood
   GuiControlGet, WalkMethod_IfBlank,, WalkMethod_IfBlank
   GuiControlGet, WalkMethod_IfPlayer,, WalkMethod_IfPlayer
   GuiControlGet, Spell_to_cast_name,, Spell_to_cast_name
   GuiControlGet, Spell_to_cast_count,, Spell_to_cast_count
   GuiControlGet, house_pos_x,, house_pos_x
   GuiControlGet, house_pos_y,, house_pos_y
   GuiControlGet, hand_slot_pos_x,, hand_slot_pos_x
   GuiControlGet, hand_slot_pos_y,, hand_slot_pos_y

   IniWrite, %Rune_spellname1%, basic_settings.ini, bot variables, Rune_spellname1
   IniWrite, %Rune_spellname2%, basic_settings.ini, bot variables, Rune_spellname2
   IniWrite, %Spelltime1%, basic_settings.ini, bot variables, Spelltime1
   IniWrite, %Spelltime2%, basic_settings.ini, bot variables, Spelltime2
   IniWrite, %Eat_food%, basic_settings.ini, bot variables, Eat_food
   IniWrite, %Anty_log%, basic_settings.ini, bot variables, Anty_log
   IniWrite, %OpenNewBackpack%, basic_settings.ini, bot variables, OpenNewBackpack
   IniWrite, %Create_blank%, basic_settings.ini, bot variables, Create_blank
   IniWrite, %Hand_mode%, basic_settings.ini, bot variables, Hand_mode
   IniWrite, %House_deposit%, basic_settings.ini, bot variables, House_deposit
   IniWrite, %Frequency_screen_checker%, basic_settings.ini, bot variables, Frequency_screen_checker
   IniWrite, %DoNothing_IfFood%, basic_settings.ini, bot variables, DoNothing_IfFood
   IniWrite, %Logout_IfFood%, basic_settings.ini, bot variables,  Logout_IfFood
   IniWrite, %PlaySound_IfFood%, basic_settings.ini, bot variables,  PlaySound_IfFood
   IniWrite, %ShutDown_IfFood%, basic_settings.ini, bot variables, ShutDown_IfFood
   IniWrite, %DoNothing_IfBlank%, basic_settings.ini, bot variables, DoNothing_IfBlank
   IniWrite, %Logout_IfBlank%, basic_settings.ini, bot variables, Logout_IfBlank
   IniWrite, %PlaySound_IfBlank%, basic_settings.ini, bot variables,  PlaySound_IfBlank
   IniWrite, %ShutDown_IfBlank%, basic_settings.ini, bot variables, ShutDown_IfBlank
   IniWrite, %CastSpell_IfBlank%, basic_settings.ini, bot variables, CastSpell_IfBlank 
   IniWrite, %DoNothing_IfPlayer%, basic_settings.ini, bot variables, DoNothing_IfPlayer
   IniWrite, %Logout_IfPlayer%, basic_settings.ini, bot variables, Logout_IfPlayer
   IniWrite, %PlaySound_IfPlayer%, basic_settings.ini, bot variables, PlaySound_IfPlayer
   IniWrite, %ShutDown_IfPlayer%, basic_settings.ini, bot variables, ShutDown_IfPlayer
   IniWrite, %WalkMethod_IfFood%, basic_settings.ini, bot variables, WalkMethod_IfFood
   IniWrite, %WalkMethod_IfBlank%, basic_settings.ini, bot variables, WalkMethod_IfBlank
   IniWrite, %WalkMethod_IfPlayer%, basic_settings.ini, bot variables, WalkMethod_IfPlayer
   IniWrite, %Spell_to_cast_name%, basic_settings.ini, bot variables, Spell_to_cast_name
   IniWrite, %Spell_to_cast_count%, basic_settings.ini, bot variables, Spell_to_cast_count
   IniWrite, %house_pos_x%, basic_settings.ini, bot variables, house_pos_x
   IniWrite, %house_pos_y%, basic_settings.ini, bot variables, house_pos_y
   IniWrite, %hand_slot_pos_x%, basic_settings.ini, bot variables, hand_slot_pos_x
   IniWrite, %hand_slot_pos_y%, basic_settings.ini, bot variables, hand_slot_pos_y
;   IniWrite, %randomization%, basic_settings.ini, bot variables, randomization 
;  IniWrite, %steps_to_walk%, basic_settings.ini, bot variables, steps_to_walk
;  IniWrite, %show_notifications%, basic_settings.ini, bot variables, show_notifications
}
return




 ; ######################################################################### CHECKING VALUES ############################################################################

Installfiles:
FileCreateDir, %ImgFolder%
FileInstall, Images\area_to_check.bmp, Images\area_to_check.bmp
FileInstall, Images\backpack1.bmp, Images\backpack1.bmp
FileInstall, Images\backpack2.bmp, Images\backpack2.bmp
FileInstall, Images\blank_rune.bmp, Images\blank_rune.bmp
FileInstall, Images\conjured_rune1.bmp, Images\conjured_rune1.bmp
FileInstall, Images\conjured_rune2.bmp, Images\conjured_rune2.bmp
FileInstall, Images\food1.bmp, Images\food1.bmp
FileInstall, Images\food2.bmp, Images\food2.bmp
FileInstall, Images\free_slot.bmp, Images\free_slot.bmp
FileInstall, Images\picbp.bmp, Images\picbp.bmp
FileInstall, Images\select_area.png, Images\select_area.png
FileInstall, Images\tabledone.png, Images\tabledone.png
FileInstall, Images\icon.ico, Images\icon.ico
FileInstall, Images\warlockbot_startwin.png, Images\warlockbot_startwin.png
FileInstall, Images\background.png, Images\background.png
FileInstall, alarm_food.mp3, alarm_food.mp3
FileInstall, alarm_screen.mp3, alarm_screen.mp3
FileInstall, alarm_blank.mp3, alarm_blank.mp3
FileInstall, basic_settings.ini, basic_settings.ini
goto checkfiles
return


Bot_protection:
GuiControlGet, Bot_protection,, Bot_protection
if Bot_protection = 1
   global Bot_protection = 1
else
   global Bot_protection = 0
return

Check_gui(){
   GuiControlGet, Enabled_runemaking1,, Enabled_runemaking1
   GuiControlGet, Enabled_runemaking2,, Enabled_runemaking2
   GuiControl, disable%Enabled_runemaking1%, Spelltime1
   GuiControl, disable%Enabled_runemaking1%, Rune_spellname1
   GuiControl, disable%Enabled_runemaking2%, Spelltime2
   GuiControl, disable%Enabled_runemaking2%, Rune_spellname2
   if ((Enabled_runemaking1 = 1) or (Enabled_runemaking2 = 1))
      check_var = 1
   else{
      BlockInput, Off
      check_var = 0
      SetTimer, check_runes, Off        ; the only one way to set timer off is by check_gui
   }
   GuiControl, disable%check_var%, Eat_food
   GuiControl, disable%check_var%, Anty_log
   GuiControl, disable%check_var%, OpenNewBackpack
   GuiControl, disable%check_var%, Create_blank
   GuiControl, disable%check_var%, Hand_mode
   GuiControl, disable%check_var%, House_deposit
   GuiControl, disable%check_var%, house_pos_x
   GuiControl, disable%check_var%, house_pos_y
   GuiControl, disable%check_var%, hand_slot_pos_x
   GuiControl, disable%check_var%, hand_slot_pos_y
}
return


Check_spell_to_cast_count:
sleep, 1000
   GuiControlGet, spell_to_cast_count,,spell_to_cast_count
   if ((spell_to_cast_count < 1) or (spell_to_cast_count > 10)){
      Notification("Error", "The amount of times choosen spell will be casted can't be lower than 1 and higher than 10.")
      GuiControl,,spell_to_cast_count,1
   }
return

Check_hand_slot_pos_x:
sleep, 1000
   GuiControlGet, hand_slot_pos_x,,hand_slot_pos_x
   if (hand_slot_pos_x < 1){
      Notification(BOTName, "X coordinate of hand slot can't be lower than 1.")
      GuiControl,,hand_slot_pos_x, 666
   }
   if (hand_slot_pos_x > A_ScreenWidth){
      Notification(BOTName, "X coordinate of hand slot can't be higher than screen width.")
      GuiControl,,hand_slot_pos_x, 666
   }
return

Check_hand_slot_pos_y:
sleep, 1000
   GuiControlGet, hand_slot_pos_y,,hand_slot_pos_y
   if (hand_slot_pos_y < 50){
      Notification(BOTName, "Y coordinate of hand slot can't be lower than 50.")
      GuiControl,,hand_slot_pos_y, 666
   }
   if (hand_slot_pos_y > A_Screenheight){
      Notification(BOTName, "Y coordinate of hand slot can't be higher than screen height.")
      GuiControl,,hand_slot_pos_y, 666
   }
return


Check_house_pos_x:
sleep, 1000
   GuiControlGet, house_pos_x,,house_pos_x
   if (house_pos_x < 50){
      Notification(BOTName, "X coordinate of sqm to throw can't be lower than 50.")
      GuiControl,,house_pos_x, 666
   }
   if (house_pos_x > A_ScreenWidth){
      Notification(BOTName, "X coordinate of sqm to throw can't be higher than screen width.")
      GuiControl,,house_pos_x, 666
   }
return


Check_house_pos_y:
sleep, 1000
   GuiControlGet, house_pos_y,,house_pos_y
   if (house_pos_y < 1){
      Notification(BOTName, "Y coordinate of sqm to throw can't be lower than 1.")
      GuiControl,,house_pos_y, 666
   }
   if (house_pos_y > A_Screenheight){
      Notification(BOTName, "Y coordinate of sqm to throw can't be higher than screen height.")
      GuiControl,,house_pos_y, 666
   }
return


Check_spelltime1:
sleep, 1000
   GuiControlGet, spelltime1,,spelltime1
   if (spelltime1 < 15){
      Notification(title_tibia1, "Rune make cycle can't take less then 15 seconds.")
      GuiControl,,spelltime1, 15
   }
return

Check_spelltime2:
sleep, 1000
   GuiControlGet, spelltime2,,spelltime2
   if (spelltime2 < 15){
      Notification(title_tibia2, "Rune make cycle can't take less then 15 seconds.")
      GuiControl,,spelltime2, 15
   }
return

DoNothing_IfFood:
GuiControlGet, DoNothing_IfFood,,DoNothing_IfFood
GuiControlGet, Logout_IfFood,,Logout_IfFood
GuiControlGet, PlaySound_IfFood,,PlaySound_IfFood
GuiControlGet, ShutDown_IfFood,,ShutDown_IfFood
GuiControlGet, WalkMethod_IfFood,,WalkMethod_IfFood
if (DoNothing_IfFood = 1){
   GuiControl,,Logout_IfFood,0
   GuiControl,,PlaySound_IfFood,0
   GuiControl,,ShutDown_IfFood,0
   GuiControl,Choose,WalkMethod_IfFood,1
}
return

Logout_IfFood:
GuiControlGet, DoNothing_IfFood,,DoNothing_IfFood
GuiControlGet, Logout_IfFood,,Logout_IfFood
GuiControlGet, PlaySound_IfFood,,PlaySound_IfFood
GuiControlGet, ShutDown_IfFood,,ShutDown_IfFood
GuiControlGet, WalkMethod_IfFood,,WalkMethod_IfFood
if (Logout_IfFood = 1){
   GuiControl,,DoNothing_IfFood,0
}
return

PlaySound_IfFood:
GuiControlGet, DoNothing_IfFood,,DoNothing_IfFood
GuiControlGet, Logout_IfFood,,Logout_IfFood
GuiControlGet, PlaySound_IfFood,,PlaySound_IfFood
GuiControlGet, ShutDown_IfFood,,ShutDown_IfFood
GuiControlGet, WalkMethod_IfFood,,WalkMethod_IfFood
if (PlaySound_IfFood = 1){
   GuiControl,,DoNothing_IfFood,0
}
return

ShutDown_IfFood:
GuiControlGet, DoNothing_IfFood,,DoNothing_IfFood
GuiControlGet, Logout_IfFood,,Logout_IfFood
GuiControlGet, PlaySound_IfFood,,PlaySound_IfFood
GuiControlGet, ShutDown_IfFood,,ShutDown_IfFood
GuiControlGet, WalkMethod_IfFood,,WalkMethod_IfFood
if (ShutDown_IfFood = 1){
   GuiControl,,DoNothing_IfFood,0
}
return

WalkMethod_IfFood:
GuiControlGet, DoNothing_IfFood,,DoNothing_IfFood
GuiControlGet, Logout_IfFood,,Logout_IfFood
GuiControlGet, PlaySound_IfFood,,PlaySound_IfFood
GuiControlGet, ShutDown_IfFood,,ShutDown_IfFood
GuiControlGet, WalkMethod_IfFood,,WalkMethod_IfFood
if (WalkMethod_IfFood != 1)
   GuiControl,,DoNothing_IfFood,0
return


DoNothing_IfBlank:
GuiControlGet, DoNothing_IfBlank,,DoNothing_IfBlank
GuiControlGet, Logout_IfBlank,,Logout_IfBlank
GuiControlGet, PlaySound_IfBlank,,PlaySound_IfBlank
GuiControlGet, ShutDown_IfBlank,,ShutDown_IfBlank
GuiControlGet, WalkMethod_IfBlank,,WalkMethod_IfBlank
GuiControlGet, CastSpell_IfBlank,,CastSpell_IfBlank
if (DoNothing_IfBlank = 1){
   GuiControl,,Logout_IfBlank,0
   GuiControl,,PlaySound_IfBlank,0
   GuiControl,,ShutDown_IfBlank,0
   GuiControl,Choose,WalkMethod_IfBlank,1
   GuiControl,,CastSpell_IfBlank,0
}
return

Logout_IfBlank:
GuiControlGet, DoNothing_IfBlank,,DoNothing_IfBlank
GuiControlGet, Logout_IfBlank,,Logout_IfBlank
GuiControlGet, PlaySound_IfBlank,,PlaySound_IfBlank
GuiControlGet, ShutDown_IfBlank,,ShutDown_IfBlank
GuiControlGet, WalkMethod_IfBlank,,WalkMethod_IfBlank
GuiControlGet, CastSpell_IfBlank,,CastSpell_IfBlank
if (Logout_IfBlank = 1){
   GuiControl,,DoNothing_IfBlank,0
   GuiControl,,CastSpell_IfBlank,0
}


return

PlaySound_IfBlank:
GuiControlGet, DoNothing_IfBlank,,DoNothing_IfBlank
GuiControlGet, Logout_IfBlank,,Logout_IfBlank
GuiControlGet, PlaySound_IfBlank,,PlaySound_IfBlank
GuiControlGet, ShutDown_IfBlank,,ShutDown_IfBlank
GuiControlGet, WalkMethod_IfBlank,,WalkMethod_IfBlank
GuiControlGet, CastSpell_IfBlank,,CastSpell_IfBlank
if (PlaySound_IfBlank = 1){
   GuiControl,,DoNothing_IfBlank,0
}
return

ShutDown_IfBlank:
GuiControlGet, DoNothing_IfBlank,,DoNothing_IfBlank
GuiControlGet, Logout_IfBlank,,Logout_IfBlank
GuiControlGet, PlaySound_IfBlank,,PlaySound_IfBlank
GuiControlGet, ShutDown_IfBlank,,ShutDown_IfBlank
GuiControlGet, WalkMethod_IfBlank,,WalkMethod_IfBlank
GuiControlGet, CastSpell_IfBlank,,CastSpell_IfBlank
if (ShutDown_IfBlank = 1){
   GuiControl,,DoNothing_IfBlank,0
   GuiControl,,CastSpell_IfBlank,0
}
return

WalkMethod_IfBlank:
GuiControlGet, DoNothing_IfBlank,,DoNothing_IfBlank
GuiControlGet, Logout_IfBlank,,Logout_IfBlank
GuiControlGet, PlaySound_IfBlank,,PlaySound_IfBlank
GuiControlGet, ShutDown_IfBlank,,ShutDown_IfBlank
GuiControlGet, WalkMethod_IfBlank,,WalkMethod_IfBlank
GuiControlGet, CastSpell_IfBlank,,CastSpell_IfBlank
if (WalkMethod_IfBlank != 1){
   GuiControl,,CastSpell_IfBlank,0
   GuiControl,,DoNothing_IfBlank,0
}
return

CastSpell_IfBlank:
GuiControlGet, DoNothing_IfBlank,,DoNothing_IfBlank
GuiControlGet, Logout_IfBlank,,Logout_IfBlank
GuiControlGet, PlaySound_IfBlank,,PlaySound_IfBlank
GuiControlGet, ShutDown_IfBlank,,ShutDown_IfBlank
GuiControlGet, WalkMethod_IfBlank,,WalkMethod_IfBlank
GuiControlGet, CastSpell_IfBlank,,CastSpell_IfBlank
GuiControlGet, Spell_to_cast_count,,Spell_to_cast_count
GuiControlGet, Spell_to_cast_name,,Spell_to_cast_name
if (Spell_to_cast_name = ""){
   Notification("Error", "You should enter first valid spell name to cast in case of no blank runes, configurable in settings.")
   GuiControl,,CastSpell_IfBlank,0
   return
}
if (Spell_to_cast_count = ""){
   Notification("Error", "You should enter first how many times spell will be cast in case of no blank runes, configurable in settings.")
   GuiControl,,CastSpell_IfBlank,0
   return
}
if ((Spell_to_cast_count < 1) or (Spell_to_cast_count > 10)){
   Notification("Error", "The amount of times choosen spell will be casted can't be lower than 1 and higher than 10.")
   GuiControl,,CastSpell_IfBlank,0
   return
}
if (CastSpell_IfBlank = 1){
   GuiControl,,DoNothing_IfBlank,0
   GuiControl,,ShutDown_IfBlank,0
   GuiControl,Choose,WalkMethod_IfBlank,1
   GuiControl,,Logout_IfBlank,0
}
return

DoNothing_IfPlayer:
GuiControlGet, DoNothing_IfPlayer,,DoNothing_IfPlayer
GuiControlGet, Logout_IfPlayer,,Logout_IfPlayer
GuiControlGet, PlaySound_IfPlayer,,PlaySound_IfPlayer
GuiControlGet, ShutDown_IfPlayer,,ShutDown_IfPlayer
GuiControlGet, WalkMethod_IfPlayer,,WalkMethod_IfPlayer
if (DoNothing_IfPlayer = 1){
   GuiControl,,Logout_IfPlayer,0
   GuiControl,,PlaySound_IfPlayer,0
   GuiControl,,ShutDown_IfPlayer,0
   GuiControl,Choose,WalkMethod_IfPlayer,1
}
return

Logout_IfPlayer:
GuiControlGet, DoNothing_IfPlayer,,DoNothing_IfPlayer
GuiControlGet, Logout_IfPlayer,,Logout_IfPlayer
GuiControlGet, PlaySound_IfPlayer,,PlaySound_IfPlayer
GuiControlGet, ShutDown_IfPlayer,,ShutDown_IfPlayer
GuiControlGet, WalkMethod_IfPlayer,,WalkMethod_IfPlayer
if (Logout_IfPlayer = 1){
   GuiControl,,DoNothing_IfPlayer,0
}
return

PlaySound_IfPlayer:
GuiControlGet, DoNothing_IfPlayer,,DoNothing_IfPlayer
GuiControlGet, Logout_IfPlayer,,Logout_IfPlayer
GuiControlGet, PlaySound_IfPlayer,,PlaySound_IfPlayer
GuiControlGet, ShutDown_IfPlayer,,ShutDown_IfPlayer
GuiControlGet, WalkMethod_IfPlayer,,WalkMethod_IfPlayer
if (PlaySound_IfPlayer = 1){
   GuiControl,,DoNothing_IfPlayer,0
}
return

ShutDown_IfPlayer:
GuiControlGet, DoNothing_IfPlayer,,DoNothing_IfPlayer
GuiControlGet, Logout_IfPlayer,,Logout_IfPlayer
GuiControlGet, PlaySound_IfPlayer,,PlaySound_IfPlayer
GuiControlGet, ShutDown_IfPlayer,,ShutDown_IfPlayer
GuiControlGet, WalkMethod_IfPlayer,,WalkMethod_IfPlayer
if (ShutDown_IfPlayer = 1){
   GuiControl,,DoNothing_IfPlayer,0
}
return

WalkMethod_IfPlayer:
GuiControlGet, DoNothing_IfPlayer,,DoNothing_IfPlayer
GuiControlGet, Logout_IfPlayer,,Logout_IfPlayer
GuiControlGet, PlaySound_IfPlayer,,PlaySound_IfPlayer
GuiControlGet, ShutDown_IfPlayer,,ShutDown_IfPlayer
GuiControlGet, WalkMethod_IfPlayer,,WalkMethod_IfPlayer
if (WalkMethod_IfPlayer != 1)
   GuiControl,,DoNothing_IfPlayer,0
return


; ######################################################################### SCREEN CHECKER #########################################################################
Client_screen_checker:
return

Frequency_screen_checker:
   sleep, 600
   GuiControlGet, Frequency_screen_checker,,Frequency_screen_checker
   if (Frequency_screen_checker < 150){
      Notification("Screen checker", "Check cycle can't be faster than once every 150 ms (recommended 500ms).")
      GuiControl,,Frequency_screen_checker, 50
   }
return
   
Area_screen_checker:
   take_screenshot("area_to_check", 85, 75)
return

Help_screen_checker:
MsgBox, 32, Screen checker - help, "Affect on" determines on which window bot has to check if region of screen haven't changed. Bot relay on what is actually on screen so its impossible to check both windows at once. Runemake algorithm is constructed that way if there are two game windows the choosen game window will be active most of the time. What else there will be a short period about 3-10 seconds while the other window will be active to make rune and druing this time the choosen window will be not checked, what means there is still a risk to be killed.`n`n "Frequency" means how long each check will take. It is limited to once every 150ms but recommended value is about 400-500.`n`n"Select area" is a tool to obtain region to check and its position on screen. It is wise to use it for example on battelist or hp bar. Keep it mind that change of image will result in "if screen change" alert configurable in alarms tab. And it work only if game window is active and maximized (but not fullscreened)!`n`n"Double alarm effect" is while having two mc and screen region changes on one of the clients then alarm result affects two clients, not only choosen one. It is useful while having runemaking two characters in the same place, near house doors and in case of alarm both of them will go north.
return

Enabled_screen_checker:
   GuiControlGet, Frequency_screen_checker,,Frequency_screen_checker
   GuiControlGet, Client_screen_checker,,Client_screen_checker
   GuiControlGet, Enabled_screen_checker,,Enabled_screen_checker
   if (Frequency_screen_checker < 50){
      Notification("Screen checker", "Check cycle can't be faster than once every 50 ms.")
      GuiControl,,Enabled_screen_checker,0
      GuiControl,,Frequency_screen_checker,50
      return
   }
   else if ((Client_screen_checker != "client 1") and (Client_screen_checker != "client 2")){
      Notification("Screen checker", "There is problem with choosen game client.")
      GuiControl,,Enabled_screen_checker,0
      return
   }
   else if ((Client_screen_checker = "client 1") and (!WinExist(title_tibia1))){
      Notification("Screen checker", "Window titled: " . title_tibia1 . "does not exist.")
      GuiControl,,Enabled_screen_checker,0
      GuiControl,, Enabled_runemaking1, 0
      Check_gui()
      return
   }
   else if ((Client_screen_checker = "client 2") and (!WinExist(title_tibia2))){
      Notification("Screen checker", "Window titled: " . title_tibia2 . "does not exist.")
      GuiControl,,Enabled_screen_checker,0
      GuiControl,, Enabled_runemaking2, 0
      Check_gui()
      return
   }
   else if (!FileExist("Images\area_to_check.bmp") or (area_start_x = "") or (area_start_y = "") or (sc_temp_img_dir !contains "area_to_check.bmp")){
      Notification("Screen checker", "Capture image of region to check first")
      GuiControl,,Enabled_screen_checker,0
      return
   }
   if (Enabled_screen_checker = 1){
      if (Client_screen_checker = "client 1"){
         window_to_check = %title_tibia1%
         window_to_check_short = "client1"
      }
      else{
         window_to_check = %title_tibia2%
         window_to_check_short = "client2"
      } 
      check_x1 := % area_start_x + 5
      check_y1 := % area_start_y + 5
      check_x2 := % area_start_x + 91
      check_y2 := % area_start_y + 81
      refresh_time := frequency_screen_checker
      SetTimer, Screen_check, %refresh_time%
   }
   else
      SetTimer, Screen_check, Off
return

Screen_check:
   if WinActive(window_to_check){
      ImageSearch, notneeded_x, notneeded_y, %check_x1%, %check_y1%, %check_x2%, %check_y2%, *10 Images/area_to_check.bmp
      if (ErrorLevel = 1){
         GuiControlGet, Double_alarm_screen_checker,,Double_alarm_screen_checker
         if (Double_alarm_screen_checker = 1 and mc_count = 2){
            alarm(title_tibia1, "player")
            alarm(title_tibia2, "player")
         }
         else
            alarm(window_to_check, "player")
         GuiControl,,Enabled_screen_checker,0
         SetTimer, Screen_check, Off
      }
   }
return



; ################################################################################# HOTKEYS ################################################################################
!^F11::
pause("toggle", 1)
return

!^F12::
ExitApp
return

; ################################################################################### END ##################################################################################
Exit:
FileExit:     ; User chose "Exit" from the File menu.
GuiClose:  ; User closed the window.
ExitApp
