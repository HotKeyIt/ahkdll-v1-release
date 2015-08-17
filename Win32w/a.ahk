global wait
DetectHiddenWindows On
OnMessage(0x4a, "Receive_WM_COPYDATA")
regex:=match_case:=match_whole_word:=match_path:=0,num:=2,meirong:="h"
everything_hwnd := WinExist("ahk_class EVERYTHING_TASKBAR_NOTIFICATION")
len := StrLen(meirong),size := 22 + len*2,VarSetCapacity(query,size),NumPut(A_ScriptHwnd,query)
NumPut(regex<<3|match_case<<2|match_whole_word<<1|match_path,query,A_PtrSize*2)
NumPut(num,query,A_PtrSize*4),DllCall("RtlMoveMemory",Uint,&query+A_PtrSize*5,Uint,&meirong,Uint,(len+1)*(A_IsUnicode?2:1))
VarSetCapacity(cds,A_PtrSize*3),NumPut(2,cds),NumPut(size,cds,A_PtrSize),NumPut(&query,cds,A_PtrSize*2),tick:=wait:=A_TickCount
SendMessage,0x4A,A_ScriptHwnd,&cds,,ahk_id %everything_hwnd%
While (tick=wait)
	sleep 500
ExitApp
Receive_WM_COPYDATA(wParam, lParam){
	if *lParam 
		MsgBox % "Error " lparam " - " (*lparam)
	wait:=0
}