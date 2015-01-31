ObjLoad(addr,sz:=""){
  ; Arrays to retrieve type and size from number type
  static type:=["Char","UChar","Short","UShort","Int","UInt","Int64","UInt64","Double"],num:=[1,1,2,2,4,4,8,8,8]
  If (sz=""){ ; FileRead Mode
    If !FileExist(addr)
      return
    FileGetSize,sz,%addr%
    FileRead,v,*c %addr%
    If ErrorLevel||!sz
      return
    addr:=&v
  }
  end:=addr+sz,  obj:=[]
  While % addr<end{ ; 9 = Int64 for size and Char for type
    If NumGet(addr+0,"Char")=-11
      k:=ObjLoad(addr+9,sz:=NumGet(addr+1,"UInt64")),addr+=sz+9
    else if NumGet(addr+0,"Char")=-10
      k:=StrGet(addr+9),addr+=NumGet(addr+1,"UInt64")+9
    else      k:=NumGet(addr+1,type[sz:=-1*NumGet(addr+0,"Char")]),addr+=num[sz]+1
    If NumGet(addr+0,"Char")= 11
      obj[k]:=ObjLoad(addr+9,sz:=NumGet(addr+1,"PTR")),addr+=sz+9
    else if NumGet(addr+0,"Char")= 10
      obj.SetCapacity(k,sz:=NumGet(addr+1,"UInt64")),DllCall("RtlMoveMemory","PTR",obj.GetAddress(k),"PTR",addr+9,"PTR",sz),addr+=sz+9
    else obj[k]:=NumGet(addr+1,type[sz:=NumGet(addr+0,"Char")]),addr+=num[sz]+1
  }
  return obj
}

/*
ObjLoad(addr,sz:=""){
  If (sz=""){ ; FileRead Mode
    If !FileExist(addr)
      return
    FileGetSize,sz,%addr%
    FileRead,v,*c %addr%
    If ErrorLevel||!sz
      return
    addr:=&v
  }
  end:=addr+sz,  obj:=[]
  While addr<end{
    If (NumGet(addr+0,"Short")=-4)
      k:=ObjLoad(addr+A_PtrSize+2,sz:=NumGet(addr+2,"PTR")),addr+=sz+2+A_PtrSize
    else if (NumGet(addr+0,"Short")=-1)
      k:=StrGet(addr+2+A_PtrSize),addr+=NumGet(addr+2,"PTR")*(A_IsUnicode?2:1)+A_PtrSize+2
    else      k:=NumGet(addr+2,NumGet(addr+0,"Short")=-3?"Double":"Int64"),addr+=8+2
    If (NumGet(addr+0,"Short")= 4)
      obj[k]:=ObjLoad(addr+A_PtrSize+2,sz:=NumGet(addr+2,"PTR")),addr+=sz+2+A_PtrSize
    else if (NumGet(addr+0,"Short")= 1)
      obj.SetCapacity(k,NumGet(addr+2,"PTR")),DllCall("RtlMoveMemory","PTR",obj.GetAddress(k),"PTR",addr+2+A_PtrSize,"PTR",NumGet(addr+2,"PTR")),addr+=NumGet(addr+2,"PTR")+A_PtrSize+2
    else obj[k]:=NumGet(addr+2,NumGet(addr+0,"Short")=3?"Double":"Int64"),addr+=8+2
  }
  return obj
}