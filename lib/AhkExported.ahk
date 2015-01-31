
AhkExported(mapping=""){
	static init
	static functions="
  (Join
ahkFunction:s=sssssssssss|ahkPostFunction:s=sssssssssss|ahkExec:ui=s|
addFile:ut=sucuc|addScript:ut=si|ahkassign:ui=ss|ahkExecuteLine:ut=utuiui|
ahkFindFunc:ut=s|ahkFindLabel:ut=s|ahkgetvar:s=sui|ahkLabel:ui=sui|ahkPause:s
)"
	If (!init && init := Object())
   {
		If !A_IsCompiled	
			functions .= "|addFile:ui=sucuc|addScript:ui=sucuc"
      VarSetCapacity(file,512)
      DllCall("GetModuleFileName","UInt",DllCall("GetModuleHandle","UInt",0),"Uint",&file,"UInt",512)
      DllCall("LoadLibrary","Str",(A_IsCompiled ? A_ScriptFullPath : A_AhkPath))
      Loop,Parse,functions,|
      {
        StringSplit,v,A_LoopField,:
        v=
    		if (mapping){
    			loop,Parse,Mapping,%A_Space%
    				If (SubStr(A_LoopField,1,InStr(A_LoopField,"=")-1)=v1)
    					v:=SubStr(A_LoopField,InStr(A_LoopField,"=")+1)
    				else if (A_LoopField=v1)
    					v:=A_LoopField
    			if (v && !init[v])
    				init[v]:=DynaCall((A_IsCompiled ? A_ScriptFullPath : A_AhkPath) . "\" . v1,v2)
    			continue
    		} else v:=v1
        init[v]:=DynaCall((A_IsCompiled ? A_ScriptFullPath : A_AhkPath) . "\" . v1,v2)
      }
   }
	return init
}