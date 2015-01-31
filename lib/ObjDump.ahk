ObjDump(obj,ByRef var,mode:=0){
  If IsObject(var){ ; FileAppend mode
    If FileExist(obj){
      FileDelete,%obj%
      If ErrorLevel
        return
    }
    f:=FileOpen(obj,"rw-rwd"),VarSetCapacity(v,sz:=RawObjectSize(var,mode),0)
    ,RawObject(var,&v,mode),count:=sz//65536,ptr:=&v
    Loop % count
      f.RawWrite(ptr+0,65536),ptr+=65536
    return sz,f.RawWrite(ptr+0,Mod(sz,65536)),f.Close()
  } else return sz,VarSetCapacity(var,sz:=RawObjectSize(obj,mode),0),RawObject(obj,&var,mode)
}
RawObject(obj,addr,buf:=0){
  ; Type.Enum:    Char.1 UChar.2 Short.3 UShort.4 Int.5 UInt.6 Int64.7 UInt64.8 Double.9 String.10 Object.11
  for k,v in obj
  { ; 9 = Int64 for size and Char for type
    If IsObject(k)
      NumPut(-11,addr+0,"Char"),NumPut(sz:=RawObjectSize(k,buf),addr+1,"UInt64"),RawObject(k,addr+9),addr+=sz+9
    else if (k+0="")
      NumPut(-10,addr+0,"Char"),NumPut(StrPut(k,addr+9)*(A_IsUnicode?2:1),addr+1,"UInt64"),addr+=NumGet(addr+1,"UInt64")+9
    else NumPut( InStr(k,".")?-9:k>4294967295?-8:k>65535?-6:k>255?-4:k>-1?-2:k>-129?-1:k>-32769?-3:k>-2147483649?-5:-7,addr+0,"Char")
        ,NumPut(k,addr+1,InStr(k,".")?"Double":k>4294967295?"UInt64":k>65535?"UInt":k>255?"UShort":k>-1?"UChar":k>-129?"Char":k>-32769?"Short":k>-2147483649?"Int":"Int64")
        ,addr+=InStr(k,".")||k>4294967295?9:k>65535?5:k>255?3:k>-129?2:k>-32769?3:k>-2147483649?5:9
    If IsObject(v)
      NumPut( 11,addr+0,"Char"),NumPut(sz:=RawObjectSize(v,buf),addr+1,"UInt64"),RawObject(v,addr+9),addr+=sz+9
    else if (v+0="")
      NumPut( 10,addr+0,"Char"),NumPut(sz:=buf?obj.GetCapacity(k):StrPut(v)*(A_IsUnicode?2:1),addr+1,"Int64"),DllCall("RtlMoveMemory","PTR",addr+9,"PTR",&v,"PTR",sz),addr+=sz+9
    else NumPut( InStr(v,".")?9:v>4294967295?8:v>65535?6:v>255?4:v>-1?2:v>-129?1:v>-32769?3:v>-2147483649?5:7,addr+0,"Char")
        ,NumPut(v,addr+1,InStr(v,".")?"Double":v>4294967295?"UInt64":v>65535?"UInt":v>255?"UShort":v>-1?"UChar":v>-129?"Char":v>-32769?"Short":v>-2147483649?"Int":"Int64")
        ,addr+=InStr(v,".")||v>4294967295?9:v>65535?5:v>255?3:v>-129?2:v>-32769?3:v>-2147483649?5:9
  }
}
RawObjectSize(obj,buf:=0,sz:=0){
  ; 9 = Int64 for size and Char for type
  for k,v in obj
  {
    If IsObject(k)
      sz+=RawObjectSize(k,buf)+9
    else if (k+0="")
        sz+=StrPut(k)*(A_IsUnicode?2:1)+9
    else sz+=InStr(k,".")||k>4294967295?9:k>65535?5:k>255?3:k>-129?2:k>-32769?3:k>-2147483649?5:9
    If IsObject(v)
      sz+=RawObjectSize(v,buf)+9
    else if (v+0="")
      sz+=(buf?obj.GetCapacity(k):StrPut(v)*(A_IsUnicode?2:1))+9
    else sz+=InStr(v,".")||v>4294967295?9:v>65535?5:v>255?3:v>-129?2:v>-32769?3:v>-2147483649?5:9
  }
  return sz
}



/*
ObjDump(obj,ByRef var){
  If IsObject(var){ ; FileAppend mode
    If FileExist(obj){
      FileDelete,%obj%
      If ErrorLevel
        return
    }
    f:=FileOpen(obj,"rw-rwd"),VarSetCapacity(v,sz:=RawObjectSize(var),0)
    ,RawObject(var,&v),count:=sz//65536,ptr:=&v
    Loop count
      f.RawWrite(ptr+0,65536),ptr+=65536
    return sz,f.RawWrite(ptr+0,Mod(sz,65536)),f.Close()
  } else return sz,VarSetCapacity(var,sz:=RawObjectSize(obj),0),RawObject(obj,&var)
}
RawObject(obj,addr){
  orig:=addr
  for k,v in obj
  {
    If IsObject(k)
      NumPut(-4,addr+0,""),NumPut(szo:=RawObjectSize(k),addr+2,"PTR"),addr+=A_PtrSize+2,RawObject(k,addr),addr+=szo
    else if (k+0="")
      NumPut(-1,addr+0,"Short"),NumPut(StrPut(k),addr+2,"PTR"),StrPut(k,addr+A_PtrSize+2),addr+=NumGet(addr+2,"PTR")*(A_IsUnicode?2:1)+A_PtrSize+2
    else if (k+0!=""&&InStr(k,"."))
      NumPut(-3,addr+0,"Short"),NumPut(k,addr+2,"Double"),addr+=8+2
    else NumPut(-2,addr+0,"Short"),NumPut(k,addr+2,"Int64"),addr+=8+2
    If IsObject(v)
      NumPut( 4,addr+0,"Short"),NumPut(szo:=RawObjectSize(v),addr+2,"PTR"),addr+=A_PtrSize+2,RawObject(v,addr),addr+=szo
    else if (v+0="")
      NumPut( 1,addr+0,"Short"),NumPut(cap:=obj.GetCapacity(k),addr+2,"PTR"),DllCall("RtlMoveMemory","PTR",addr+A_PtrSize+2,"PTR",&v,"PTR",cap),addr+=cap+A_PtrSize+2
    else if (v+0!=""&&InStr(v,"."))
      NumPut( 3,addr+0,"Short"),NumPut(v,addr+2,"Double"),addr+=8+2
    else NumPut( 2,addr+0,"Short"),NumPut(v,addr+2,"Int64"),addr+=8+2
  }
}
RawObjectSize(obj,sz:=0){
  for k,v in obj
  { ; key
    If IsObject(k)
      sz+=RawObjectSize(k)+A_PtrSize+2
    else if (k+0="")
      sz+=StrPut(k)*2+A_PtrSize+2
    else sz+=8+2
    ; value
    If IsObject(v)
      sz+=RawObjectSize(v)+A_PtrSize+2
    else if (v+0="")
      sz+=obj.GetCapacity(k)+A_PtrSize+2
    else sz+=8+2
  }
  return sz
}