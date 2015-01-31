MCodeH(h,def,p*) { ; allocate memory in static object and write Machine Code there, return DynaCall (callable object)
   static f,DynaCalls
	 If !DynaCalls
      DynaCalls:={}
   If DynaCalls.HasKey(h) ; return already existing function object instead of creating new one
      return DynaCalls[h]
   f:=[h],   f.SetCapacity(f.MaxIndex(),len:=StrLen(h)//2)
   ;~ If A_OSVersion in Win_7,Win_Vista
      ;~ DllCall("VirtualProtect","PTR",addr:=f.GetAddress(f.MaxIndex()),"Uint",len,"UInt",64,"Uint*",0) ;PAGE_EXECUTE_READWRITE
   ;~ else 
   addr:=f.GetAddress(f.MaxIndex())
   Loop % len
      NumPut("0x" . SubStr(h,2*A_Index-1,2), addr+0, A_Index-1, "Char")
   if p.MaxIndex()
      Return DynaCalls[h]:=DynaCall(addr,def,p*)
   else Return DynaCalls[h]:=DynaCall(addr,def)
}