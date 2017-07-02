#Include ScriptParser.ahk
#Include IconChanger.ahk
#Include Directives.ahk

AhkCompile(ByRef AhkFile, ExeFile := "", ByRef CustomIcon := "", BinFile := "", UseMPRESS := "",UseCompression := "", UseInclude := "", UseIncludeResource := "", UsePassword := "AutoHotkey")
{
	global ExeFileTmp
	AhkFile := Util_GetFullPath(AhkFile)
	if (AhkFile = "")
		Util_Error("Error: Source file not specified.")
	SplitPath,AhkFile,, AhkFile_Dir,, AhkFile_NameNoExt
	
	if (ExeFile = "")
		ExeFile := AhkFile_Dir "\" AhkFile_NameNoExt ".exe"
	else
		ExeFile := Util_GetFullPath(ExeFile)
	
	ExeFileTmp := ExeFile
	
	if (BinFile = "")
		BinFile := A_ScriptDir "\AutoHotkeySC.bin"
	SetCursor(LoadCursor(0, 32514)) ; Util_DisplayHourglass()
	FileCopy, %BinFile%, %ExeFile%, 1
	if ErrorLevel
		Util_Error("Error: Unable to copy AutoHotkeySC binary file to destination.")
	
	BundleAhkScript(ExeFile, AhkFile, CustomIcon, UseCompression, UsePassword)
	
	if FileExist(A_ScriptDir "\mpress.exe") && UseMPRESS
	{
		SB_SetText("Compressing final executable...")
		if UseCompression ; do not compress resources
			RunWait, "%A_ScriptDir%\mpress.exe" -q -x -r "%ExeFile%",, Hide
		else RunWait, "%A_ScriptDir%\mpress.exe" -q -x "%ExeFile%",, Hide
	}
	
	SetCursor(LoadCursor(0, 32512)) ; Util_HideHourglass()
	SB_SetText("")
}

BundleAhkScript(ExeFile, AhkFile, IcoFile := "", UseCompression := 0, UsePassword := "")
{
	SplitPath,AhkFile,, ScriptDir
	ExtraFiles := []
	,Directives := PreprocessScript(ScriptBody, AhkFile, ExtraFiles)
	,ScriptBody :=Trim(ScriptBody,"`n")
	,VarSetCapacity(BinScriptBody, BinScriptBody_Len:=StrPut(ScriptBody, "UTF-8"))
	,StrPut(ScriptBody, &BinScriptBody, "UTF-8")
	If UseCompression {
		VarSetCapacity(buf,bufsz:=65536,00),totalsz:=0,VarSetCapacity(buf1,65536)
		Loop, Parse,ScriptBody,`n,`r
		{
			len:=StrPutVar(A_LoopField,data,"UTF-8")
			,sz:=ZipRawMemory(&data, len, zip, UsePassword)
			,DllCall("crypt32\CryptBinaryToStringA","PTR", &zip,"UInt", sz,"UInt", 0x1|0x40000000,"UInt", 0,"UIntP", cryptedsz)
			,tosavesz:=cryptedsz
			,DllCall("crypt32\CryptBinaryToStringA","PTR", &zip,"UInt", sz,"UInt", 0x1|0x40000000,"PTR", &buf1,"UIntP", cryptedsz)
			,NumPut(10,&buf1,cryptedsz)
			if (totalsz+tosavesz>bufsz)
				VarSetCapacity(buf,bufsz*=2)
			RtlMoveMemory((&buf) + totalsz,&buf1,tosavesz)
			,totalsz+=tosavesz
		}
		NumPut(0,&buf,totalsz-1,"UShort")
		If !BinScriptBody_Len := ZipRawMemory(&buf,totalsz,BinScriptBody,UsePassword)
			Util_Error("Error: Could not compress the source file.")
	}
	
	module := BeginUpdateResource(ExeFile)
	if !module
		Util_Error("Error: Error opening the destination file.")
	
	tempWD := new CTempWD(ScriptDir)
	dirState := ProcessDirectives(ExeFile, module, Directives, IcoFile, UseCompression, UsePassword)
	IcoFile := dirState.IcoFile
	
	if outPreproc := dirState.OutPreproc
	{
		f := FileOpen(outPreproc, "w", "UTF-8-RAW")
		f.RawWrite(BinScriptBody, BinScriptBody_Len)
		f := ""
	}
	
	SB_SetText("Adding: Master Script")
	if !DllCall("UpdateResource", "ptr", module, "ptr", 10, "str", "E4847ED08866458F8DD35F94B37001C0"
				  , "ushort", 0x409, "ptr", &BinScriptBody, "uint", BinScriptBody_Len, "uint")
		goto _FailEnd
		
	for each,file in ExtraFiles
	{
		SB_SetText("Adding: " file)
		StringUpper, resname, file
		
		If !FileExist(file)
			goto _FailEnd2
		If UseCompression{
			FileRead, tempdata, *c %file%
			FileGetSize, tempsize, %file%
			If !filesize := ZipRawMemory(&tempdata, tempsize, filedata)
				Util_Error("Error: Could not compress the file to: " file)
		} else {
			FileRead, filedata, *c %file%
			FileGetSize, filesize, %file%
		}
		
		if !DllCall("UpdateResource", "ptr", module, "ptr", 10, "str", resname
				  , "ushort", 0x409, "ptr", &filedata, "uint", filesize, "uint")
			goto _FailEnd2
	}
	VarSetCapacity(filedata, 0)
	
	gosub _EndUpdateResource
	
	if dirState.ConsoleApp
	{
		SB_SetText("Marking executable as a console application...")
		if !SetExeSubsystem(ExeFile, 3)
			Util_Error("Could not change executable subsystem!")
	}
	
	for each,cmd in dirState.PostExec
	{
		SB_SetText("PostExec: " cmd)
		RunWait, % cmd,, UseErrorLevel
		if (ErrorLevel != 0)
			Util_Error("Command failed with RC=" ErrorLevel ":`n" cmd)
	}
	
	
	return
	
_FailEnd:
	gosub _EndUpdateResource
	Util_Error("Error adding script file:`n`n" AhkFile)
	
_FailEnd2:
	gosub _EndUpdateResource
	Util_Error("Error adding FileInstall file:`n`n" file)
	
_EndUpdateResource:
	if !EndUpdateResource(module)
		Util_Error("Error: Error opening the destination file.")
	return
}

class CTempWD
{
	__New(newWD)
	{
		this.oldWD := A_WorkingDir
		SetWorkingDir % newWD
	}
	__Delete()
	{
		SetWorkingDir % this.oldWD
	}
}

Util_GetFullPath(path)
{
	VarSetCapacity(fullpath, 260 * (!!A_IsUnicode + 1))
	if GetFullPathName(path, 260, fullpath, 0)
		return fullpath,VarSetCapacity(fullpath,-1)
}
