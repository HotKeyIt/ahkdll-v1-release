DynaRun(s, pn:="", pr:=""){ ; s=Script,pn=PipeName,n:=,pr=Parameters,p1+p2=hPipes,P=PID
   static AhkPath:="""" A_AhkPath """" (A_IsCompiled||(A_IsDll&&DllCall(A_AhkPath "\ahkgetvar","Str","A_IsCompiled"))?" /E":"") " """
   if (-1=p1 := DllCall("CreateNamedPipe","str",pf:="\\.\pipe\" (pn!=""?pn:"AHK" A_TickCount),"uint",2,"uint",0,"uint",255,"uint",0,"uint",0,"Ptr",0,"Ptr",0))
      || (-1=p2 := DllCall("CreateNamedPipe","str",pf,"uint",2,"uint",0,"uint",255,"uint",0,"uint",0,"Ptr",0,"Ptr",0))
      Return 0
   ; allow compiled executable to execute dynamic scripts. Requires AHK_H
   Run, % AhkPath pf """ " pr,,UseErrorLevel HIDE, P
   If ErrorLevel
      return 0,DllCall("CloseHandle","Ptr",p1),DllCall("CloseHandle","Ptr",p2)
   DllCall("ConnectNamedPipe","Ptr",p1,"Ptr",0),DllCall("CloseHandle","Ptr",p1),DllCall("ConnectNamedPipe","Ptr",p2,"Ptr",0)
   if !DllCall("WriteFile","Ptr",p2,"Wstr",s:=(A_IsUnicode?chr(0xfeff):"﻿") s,"UInt",StrLen(s)*(A_IsUnicode ? 2 : 1)+(A_IsUnicode?4:6),"uint*",0,"Ptr",0)
      P:=0
   DllCall("CloseHandle","Ptr",p2)
   Return P
}