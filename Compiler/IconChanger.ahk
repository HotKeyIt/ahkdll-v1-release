
; This code is based on Ahk2Exe's changeicon.cpp

ReplaceAhkIcon(re, IcoFile, ExeFile, iconID := 159)
{
	global _EI_HighestIconID
	ids := EnumIcons(ExeFile, iconID)
	if !IsObject(ids)
		return false
	
	f := FileOpen(IcoFile, "r")
	if !IsObject(f)
		return false
	
	VarSetCapacity(igh, 8), f.RawRead(igh, 6)
	if NumGet(igh, 0, "UShort") != 0 || NumGet(igh, 2, "UShort") != 1
		return false
	
	wCount := NumGet(igh, 4, "UShort")
	
	VarSetCapacity(rsrcIconGroup, rsrcIconGroupSize := 6 + wCount*14)
	NumPut(NumGet(igh, "Int64"), rsrcIconGroup, "Int64") ; fast copy
	
	ige := &rsrcIconGroup + 6
	
	; Delete all the images
	Loop, % ids.MaxIndex()
		UpdateResource(re, 3, ids[A_Index], 0x409)
	
	Loop, %wCount%
	{
		thisID := ids[A_Index]
		if !thisID
			thisID := ++ _EI_HighestIconID
		
		f.RawRead(ige+0, 12) ; read all but the offset
		NumPut(thisID, ige+12, "UShort")
		
		imgOffset := f.ReadUInt()
		oldPos := f.Pos
		f.Pos := imgOffset
		
		VarSetCapacity(iconData, iconDataSize := NumGet(ige+8, "UInt"))
		f.RawRead(iconData, iconDataSize)
		f.Pos := oldPos
		
		if !DllCall("UpdateResource", "ptr", re, "ptr", 3, "ptr", thisID, "ushort", 0x409, "ptr", &iconData, "uint", iconDataSize, "uint")
			return false
		
		ige += 14
	}
	
	return !!DllCall("UpdateResource", "ptr", re, "ptr", 14, "ptr", iconID, "ushort", 0x409, "ptr", &rsrcIconGroup, "uint", rsrcIconGroupSize, "uint")
}

EnumIcons(ExeFile, iconID)
{
	; RT_GROUP_ICON = 14
	; RT_ICON = 3
	global _EI_HighestIconID
	static pEnumFunc := RegisterCallback("EnumIcons_Enum")
	
	hModule := LoadLibraryEx(ExeFile, 0, 2)
	if !hModule
		return
	
	_EI_HighestIconID := 0
	if DllCall("EnumResourceNames","PTR",hModule,"PTR",3,"PTR", pEnumFunc) = 0
	{
		FreeLibrary(hModule)
		return
	}
	
	hRsrc := DllCall("FindResource", "PTR", hModule, "PTR", iconID, "PTR", 14)
	,hMem := LoadResource(hModule, hRsrc)
	,pDirHeader := LockResource(hMem)
	,pResDir := pDirHeader + 6
	
	wCount := NumGet(pDirHeader+4, "UShort")
	,iconIDs := []
	Loop, %wCount%
	{
		pResDirEntry := pResDir + (A_Index-1)*14
		iconIDs[A_Index] := NumGet(pResDirEntry+12, "UShort")
	}
	
	FreeLibrary(hModule)
	return iconIDs
}

EnumIcons_Enum(hModule, type, name, lParam)
{
	global _EI_HighestIconID
	if (name < 0x10000) && name > _EI_HighestIconID
		_EI_HighestIconID := name
	return 1
}
