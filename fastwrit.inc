Type
    FibName = Array[0..12] Of Char;
    
var 
    MsxIoResult: byte;

Procedure WriteVram (VramBlockUsed: Byte; VramAddr,RamAddr,ByteCount:Integer);
Var
	Expansion, AddrHi, AddrMid, AddrLo: Byte;
Begin
	If VramBlockUsed = 2 Then Expansion := $40 {Set the bit 6 (MXC) }
   	Else Expansion := 0 ; {No expansion vram used}
  	AddrHi := Hi(VramAddr) Div $40;
  	If VramBlockUsed = 1 Then AddrHi := AddrHi + 4; {Set addr bit 16 in reg 14 = bit 2 }
  	AddrLo := Lo(VramAddr);
  	AddrMid := Hi(Vramaddr) And 63 ;
	Inline(
      	$F3/$3A/ Expansion /$D3/$99/$3E/$2D/$F6/$80/$D3/$99/$3A/ AddrHi /$D3/
      	$99/$3E/$0E/$F6/$80/$D3/$99/$3A/ AddrLo /$00/$D3/$99/$3A/ AddrMid /$F6/
      	$40/$D3/$99/$2A/ RamAddr /$ED/$4B/ ByteCount /$7E/$D3/$98/$23/$0B/$79/
      	$B0/$20/$F7/ $F3/$3e/ 0  /$D3/$99/$3E/$2D/$F6/$80/$D3/$99
        );
End;

Procedure FastWrite (St : TString);
Var
	CSRX : Byte Absolute $F3DD;
    	CSRY : Byte Absolute $F3DC;
    	TXTNAM : Integer Absolute $f3b3;
    	len : Byte;
    	VramLocation : Integer;
    	Width : Byte;
Begin
	Width := Mem[$F3B0];
   	If Width < 80 then Width := 40 else Width := 80;
	Len := Ord(St[0]);
   	VramLocation := (CSRY - 1) * Width + CSRX - 1 + TXTNAM;
   	If VramLocation > 2000 Then VramLocation := 0;
   	WriteVram(0, VramLocation, Addr(St) + 1, Len);
   	CSRY := ((VramLocation + Len) Div Width) + 1;
   	CSRX := ((VramLocation + Len) Mod Width) + 1;
End; {FastWrite}


Procedure FastWriteln (St : TString);
Var
	CSRX : Byte Absolute $F3DD;
	CSRY : Byte Absolute $F3DC;
	TXTNAM : Integer Absolute $f3b3;
	len  : Byte;
	VramLocation :Integer;
	Width : Byte;
Begin
	Width := Mem[$F3B0];
	If Width < 80 then Width := 40 else Width := 80;
	Len := Ord(St[0]);
	VramLocation := (CSRY - 1) * Width + CSRX - 1 + TXTNAM;
	If VramLocation > 2000 Then VramLocation := 0;
	WriteVram(0, VramLocation, Addr(St) + 1, Len);
	CSRY := (VramLocation + Len) Div Width + 2;
	CSRX := 1;
End; {FastWriteln}
