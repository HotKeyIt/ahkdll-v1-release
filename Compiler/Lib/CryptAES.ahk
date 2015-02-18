CryptAES(ByRef lp,sz,pw,e:=1,SID:=256){
	static AES_128:=0x660E,AES_192:=1+AES_128,AES_256:=1+AES_192,SHA1:=1+0x8003 ; MD5
	if e
		VarSetCapacity(lp,sz+16)
	If !DllCall("Advapi32\CryptAcquireContextW","Ptr*",hP,"Uint",0,"Uint",0,"Uint",24,"UInt",0xF0000000) ;PROV_RSA_AES, CRYPT_VERIFYCONTEXT
	|| !DllCall("Advapi32\CryptCreateHash","Ptr",hP,"Uint",SHA1,"Uint",0,"Uint",0,"Ptr*",H )
	|| !CryptHashData(H,&pw,StrLen(pw)*2,0)
	|| !CryptDeriveKey(hP,AES_%SID%,H,SID<<16,getvar(hK:=0))
	|| !CryptDestroyHash(H)
		return 0
	if e
		CryptEncrypt(hK,0,1,0,&lp,getvar(sz),sz+16)
	else
		CryptDecrypt(hK,0,1,0,&lp,sz)
	CryptDestroyKey(hK),CryptReleaseContext(hP,0)
	return sz
}