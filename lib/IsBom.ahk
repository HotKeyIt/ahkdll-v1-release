;~ MsgBox % DownloadedString:=NoBOM(DownloadToString("http://learningone.ahk4.net/Temp/Test3.ahk"))
IsBOM(ByRef String){
 if (0xBFBBEF=NumGet(&String,"UInt") & 0xFFFFFF)
   return 3
 else if (0xFFFE=NumGet(&String,"UShort") || 0xFEFF=NumGet(&String,"UShort"))
  return 2
 else return 0
}
NoBOM(ByRef String){
 if (0xBFBBEF=NumGet(&String,"UInt") & 0xFFFFFF)
   return String:=StrGet(&String+3,"UTF-8")
 else if (0xFFFE=NumGet(&String,"UShort") || 0xFEFF=NumGet(&String,"UShort"))
  return String:=SubStr(&String+2,"UTF-16")
 else return String
}
