// DLL containing function to mouse clicks, mouseclick drag and useOn directly into desired hwnds
// it also sends 'enter' key after each execution

// modified version of c script created by Vash @tibiapf.com forum
// https://tibiapf.com/showthread.php?23-OTClient-C-How-to-properly-post-messages-in-client-window

// specifiy 'type' = 0 to operate on otclient, 1 for normal client

#include <stdio.h>
#include <windows.h>
#include <iostream>

POINT currentPos;
HWND hWindow;

extern "C" __declspec(dllexport) void RightClick(const char* title, INT posx, INT posy){	
	hWindow = FindWindow(NULL, title);
    ScreenToClient(hWindow, &currentPos);   
	DWORD coordinates = MAKELPARAM(posx, posy);
    PostMessage(hWindow, WM_MOUSEMOVE, 0, coordinates);
    PostMessage(hWindow, WM_RBUTTONDOWN, MK_RBUTTON, coordinates);
    PostMessage(hWindow, WM_MOUSEMOVE, MK_RBUTTON, coordinates);
    PostMessage(hWindow, WM_RBUTTONUP, 0, coordinates);
    coordinates = MAKELPARAM(currentPos.x, currentPos.y);
    PostMessage(hWindow, WM_MOUSEMOVE, 0, coordinates);
}

extern "C" __declspec(dllexport) void LeftClick(const char* title, INT posx, INT posy){	
	hWindow = FindWindow(NULL, title);
    ScreenToClient(hWindow, &currentPos);   
    DWORD coordinates = MAKELPARAM(posx, posy);
    PostMessage(hWindow, WM_MOUSEMOVE, 0, coordinates);
    PostMessage(hWindow, WM_LBUTTONDOWN, MK_LBUTTON, coordinates);	
	PostMessage(hWindow, WM_MOUSEMOVE, MK_LBUTTON, coordinates);
    PostMessage(hWindow, WM_LBUTTONUP, 0, coordinates);
    coordinates = MAKELPARAM(currentPos.x, currentPos.y);
    PostMessage(hWindow, WM_MOUSEMOVE, 0, coordinates);
}
 
extern "C" __declspec(dllexport) void dragDrop(const char* title, BOOL type, INT from_posx, INT from_posy, INT to_posx, INT to_posy){
    hWindow = FindWindow(NULL, title);
    if (type){
		ScreenToClient(hWindow, &currentPos);   
	    DWORD coordinates = MAKELPARAM(from_posx, from_posy);
	    PostMessage(hWindow, WM_MOUSEMOVE, 0, coordinates);
	    PostMessage(hWindow, WM_LBUTTONDOWN, MK_LBUTTON, coordinates);
		POINT cursor_pos;
		POINT cursor_pos2;
	   	GetCursorPos(&cursor_pos);
		if (cursor_pos.x < 20){
			cursor_pos2.x = cursor_pos.x + 10;
		}
		else{
			cursor_pos2.x = cursor_pos.x - 10;	
		}
		Sleep(10);
		SetCursorPos(cursor_pos2.x,cursor_pos.y);
		Sleep(10);
		SetCursorPos(cursor_pos.x,cursor_pos.y);
		Sleep(10);
	    coordinates = MAKELPARAM(to_posx, to_posy);
	    PostMessage(hWindow, WM_MOUSEMOVE, MK_LBUTTON, coordinates);
	    Sleep(10);
	    PostMessage(hWindow, WM_LBUTTONUP, 0, coordinates);
	    coordinates = MAKELPARAM(currentPos.x, currentPos.y);
	    PostMessage(hWindow, WM_MOUSEMOVE, 0, coordinates);
	}
	else{
		ScreenToClient(hWindow, &currentPos);   
	    DWORD coordinates = MAKELPARAM(from_posx, from_posy);
	    PostMessage(hWindow, WM_MOUSEMOVE, 0, coordinates);
	    PostMessage(hWindow, WM_LBUTTONDOWN, MK_LBUTTON, coordinates);
	    coordinates = MAKELPARAM(to_posx, to_posy);
	    PostMessage(hWindow, WM_MOUSEMOVE, MK_LBUTTON, coordinates);
	    PostMessage(hWindow, WM_LBUTTONUP, 0, coordinates);
	    coordinates = MAKELPARAM(currentPos.x, currentPos.y);
	    PostMessage(hWindow, WM_MOUSEMOVE, 0, coordinates);
	}
    Sleep(100);
    PostMessage(hWindow, WM_KEYUP, VK_RETURN, (MapVirtualKey(VK_RETURN, MAPVK_VK_TO_VSC)) * 0x10000 + 0xC0000000 + 1);
    PostMessage(hWindow, WM_KEYDOWN, VK_RETURN, (MapVirtualKey(VK_RETURN, MAPVK_VK_TO_VSC)) * 0x10000 + 1);
}

extern "C" __declspec(dllexport) void useOn(const char* title, BOOL type, INT from_posx, INT from_posy, INT to_posx, INT to_posy){
    hWindow = FindWindow(NULL, title);
    if (type){
		ScreenToClient(hWindow, &currentPos);   
	    DWORD coordinates = MAKELPARAM(from_posx, from_posy);
	    PostMessage(hWindow, WM_MOUSEMOVE, 0, coordinates);
	    Sleep(10);
   		PostMessage(hWindow, WM_RBUTTONDOWN, MK_RBUTTON, coordinates);
   		Sleep(10);
    	PostMessage(hWindow, WM_MOUSEMOVE, MK_RBUTTON, coordinates);
    	Sleep(10);
   		PostMessage(hWindow, WM_RBUTTONUP, 0, coordinates);  
		POINT cursor_pos;
		POINT cursor_pos2;
	   	GetCursorPos(&cursor_pos);
		if (cursor_pos.x < 20){
			cursor_pos2.x = cursor_pos.x + 10;
		}
		else{
			cursor_pos2.x = cursor_pos.x - 10;	
		}
		Sleep(10);
		SetCursorPos(cursor_pos2.x,cursor_pos.y);
		Sleep(10);
		SetCursorPos(cursor_pos.x,cursor_pos.y);
		Sleep(10);
	    coordinates = MAKELPARAM(to_posx, to_posy);
	   	PostMessage(hWindow, WM_MOUSEMOVE, 0, coordinates);
	    Sleep(10);
   		PostMessage(hWindow, WM_LBUTTONDOWN, MK_RBUTTON, coordinates);
   		Sleep(10);
    	PostMessage(hWindow, WM_MOUSEMOVE, MK_RBUTTON, coordinates);
    	Sleep(10);
   		PostMessage(hWindow, WM_LBUTTONUP, 0, coordinates);
		Sleep(10);  
	    coordinates = MAKELPARAM(currentPos.x, currentPos.y);
	    PostMessage(hWindow, WM_MOUSEMOVE, 0, coordinates);
	}
	else{
		ScreenToClient(hWindow, &currentPos);   
	    DWORD coordinates = MAKELPARAM(from_posx, from_posy);
	    PostMessage(hWindow, WM_MOUSEMOVE, 0, coordinates);
   		PostMessage(hWindow, WM_RBUTTONDOWN, MK_RBUTTON, coordinates);
  		PostMessage(hWindow, WM_MOUSEMOVE, MK_RBUTTON, coordinates);
  		PostMessage(hWindow, WM_RBUTTONUP, 0, coordinates);
		coordinates = MAKELPARAM(to_posx, to_posy);
	    PostMessage(hWindow, WM_MOUSEMOVE, MK_LBUTTON, coordinates);
	    PostMessage(hWindow, WM_LBUTTONDOWN, 0, coordinates);
	    PostMessage(hWindow, WM_LBUTTONUP, 0, coordinates);
	    coordinates = MAKELPARAM(currentPos.x, currentPos.y);
	    PostMessage(hWindow, WM_MOUSEMOVE, 0, coordinates);
	}
}

