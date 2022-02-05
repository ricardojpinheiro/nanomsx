{TxtWin.inc by Kari Lammassaari 1997 }

Function MakeWindow (Col, Row, Width, Height: Byte; Header: TString):  Pointer;
{
   MakeWindow stores the underlying screen onto heap. 
   The structure of heap record:  offset 0  = column of the upper left corner
                                         1  = row    of the upper left corner
                                         2  = length of the window
                                         3  = height of the window
                                         4  = the cursor column of the window
                                         5  = the cursor row of the window
                                         6  = underlying screen data
                                         .
}
Const
    ULC = #24;
    URC = #25; {UpperLefCorner ..Charnumbers for the Frame}
    DLC = #26;
    DRC = #27;
    VERTICAL = #22;
    HORIZONTAL = #23;

Var 
    a, b:		Byte;

Begin
    GetMem(pt, Width * Height + 6);
    Mem[at]     := Col;
    Mem[at+1]   := Row;
    Mem[at+2]   := Width;
    Mem[at+3]   := Height;
    Mem[at+4]   := 1;
    Mem[at+5]   := 1;
    Vram    := (Row - 1) * 80 + Col;
    Ram     := At + 6;
    For Count := 1 to Height Do
    Begin
        ReadVram(0, Vram, Ram, Width);
        Vram    := Vram     + 80;
        Ram     := Ram      + Width;
    End;
    FillChar(Line1, sizeof(Line1), chr(32));
    a := (Width - Length(Header)) Div 2;
    For b := 1 To Length(Header) Do
        Line1[a + b] := Header[b];
    Line1[1]       := ULC;
    Line1[Width]   := URC;
    Vram := (Row - 1) * 80 + Col;
    WriteVram(0, Vram, Addr(Line1[1]), Width);

    FillChar(Line1, 81, 32); {Fill with space }
    Line1[1]       := VERTICAL;
    Line1[Width]   := VERTICAL;
    Vram        := Vram + 80;
    For Count := 2 to height - 1 Do
    Begin
        WriteVram(0, Vram, Addr(Line1[1]), Width);
        Vram := Vram + 80;
    End;

    FillChar(Line1, 81, Horizontal); {Fill with horizontal line }
    Line1[1]       := DLC;
    Line1[Width]   := DRC;
    WriteVram(0, Vram, Addr(Line1[1]), Width);

    MakeWindow := pt;
End;  {MakeWindow}

Procedure EraseWindow(WindowPtr: Pointer);
Begin
	pt 		:= WindowPtr;
	Vram 	:= (Mem[at+1]-1)*80 + Mem[at];
	Width 	:= Mem[at+2];
	Height 	:= Mem[at+3];
	Ram 	:= at + 6;

	For Count := 1 To Height Do
	Begin
		WriteVram(0,Vram,Ram,Width);
        Ram := Ram + width;
        Vram := Vram + 80;
	End;
	FreeMem(WindowPtr,Width*Height+6);
End; { EraseWindow }

Procedure ScrollWindowUp(WindowPtr: Pointer);
Var 
	i:	Byte;

Begin
	pt   	:= WindowPtr;
	Ram  	:= Addr(Line1);
	Vram 	:= mem[at] + 1 + Mem[at+1]*80 ;
	Byt 	:= Mem[at+2]-2;

	For i := 1 to Mem[at+3]-3 Do
	Begin
		ReadVram(0,vram+80,Ram,Byt);
        WriteVram(0,Vram,Ram,Byt);
        Vram := Vram + 80;
	End;

	FillChar(Line1,80,32);
	WriteVram(0,Vram,Ram,Byt);

End; {ScrollWindowUp }

Procedure ScrollWindowDown(WindowPtr:Pointer);
Var
	i:	Byte;

Begin
	pt   := WindowPtr;
	Ram  := Addr(Line1);
	Vram := mem[at] + 1 + (Mem[at+1]+mem[at+3]-3) *80 ;
	Byt := Mem[at+2]-2;

	For i := 1 to Mem[at+3]-3 Do
	Begin
		ReadVram(0,vram-80,Ram,Byt);
        WriteVram(0,Vram,Ram,Byt);
        Vram := Vram - 80;
	End;

	FillChar(Line1,80,32);
	WriteVram(0,Vram,Ram,Byt);

End; {ScrollWindowDown }

Function WhereXWindow (WindowPtr: Pointer): byte;
begin
	pt := WindowPtr;
    WhereXWindow := Mem[at + 4];
end;    { WhereXWindow }

Function WhereYWindow (WindowPtr: Pointer): byte;
begin
	pt := WindowPtr;
    WhereYWindow := Mem[at + 5];
end;    { WhereYWindow }

Procedure DelLineWindow (WindowPtr: Pointer);
Var
	i, CurRow, CurCol:	byte;

Begin
	pt		:= WindowPtr;
    Ram  	:= Addr(Line1);
    CurRow 	:= Mem[at + 5];
    CurCol 	:= Mem[at + 4] ;
    Vram 	:= Mem[at] + (Mem[at + 1] + CurRow - 1) * 80 + 1;
    Byt 	:= Mem[at + 2] - 2;

	For i := CurRow to Mem[at + 3] - 3 Do
	Begin
		ReadVram(0, vram + 80, Ram, Byt);
        WriteVram(0, Vram, Ram, Byt);
        Vram := Vram + 80;
    End;

    FillChar(Line1, 80, 32);
    WriteVram(0, Vram, Ram, Byt);

  End; { DelLineWindow }

Procedure InsLineWindow (WindowPtr: Pointer);
Var
    i, CurRow, CurCol:	byte;

Begin
    pt   	:= WindowPtr;
    Ram  	:= Addr(Line1);
    CurRow 	:= Mem[at + 5];
	CurCol 	:= Mem[at + 4] ;
    Vram 	:= Mem[at] + (Mem[at + 1] + CurRow - 1) * 80 + 1;
    Vram 	:= mem[at] + 1 + (Mem[at + 1] + mem[at + 3] - 3) * 80;
    Byt 	:= Mem[at + 2] - 2;

    For i := (CurRow - 1) to Mem[at + 3] - 3 Do
    Begin
        ReadVram(0, vram - 80, Ram, Byt);
        WriteVram(0, Vram, Ram, Byt);
        Vram := Vram - 80;
    End;

    FillChar(Line1, 80, 32);
    WriteVram(0, Vram, Ram, Byt);

End; { InsLineWindow }

Procedure _WriteWindowOperation(WindowPtr: Pointer; St: TString;
								LineFeed: Boolean);
Label Out;
Type WindowInfoType = Record
		WinCol: 	Byte;   {The coordinates of upper left}
		WinRow:		Byte;   {corner of the window.}
		WinLen:		Byte;   {Window measures including border}
		WinHeigth:	Byte; 	{chars.}
		CurCol:		Byte;   {The cursor coordinates of }
		CurRow:		Byte;   {this window}
	End;

Var
	pt:					Integer;
	at:					WindowInfoType;
	WrtLen, LinLen, 
	Bottom, StIndex:	Byte;

	Procedure FillRow(Var StringIndex:Byte);
	Begin
		With at Do
		Begin
			If (CurRow = Bottom) And (WinHeigth > 3 ) Then { No scroll for one }
			Begin                                       { line window ! }
				ScrollWindowUp(WindowPtr);
				CurRow 	:= Bottom - 1;
				Vram 	:= Vram	  -	80;
			End;
		    Ram 			:= Addr(St[StringIndex]);
		    WrtLen 			:= WinLen - CurCol - 1;
		    StringIndex 	:= StringIndex + WrtLen;
		    WriteVram(0,Vram,Ram,WrtLen);

			CurCol 	:= 1;
			CurRow 	:= CurRow + 1;
			Vram 	:= WinCol+  1 + (WinRow+CurRow-1)*80;

		End; {With}
	End;

	Procedure WriteRow(Var StringIndex:Byte);
	Begin
		With At Do
		Begin
			If (CurRow = Bottom) And (WinHeigth > 3 ) Then { No scroll for one }
			Begin                                       { line window ! }
				ScrollWindowUp(WindowPtr);
				CurRow 	:= Bottom -1;
				Vram 	:= Vram - 80;
			End;
			Ram 		:= Addr(St[StringIndex]);
			WrtLen 		:= Length(St) - StringIndex + 1 ;
			StringIndex := StringIndex + WrtLen;
			WriteVram(0, Vram, Ram, WrtLen);

			If LineFeed Then
			Begin
				CurRow 	:=	CurRow + 1;
				CurCol 	:= 	1;
				Vram 	:= 	Vram + 80;
			End
			Else
			Begin
				CurCol 	:= CurCol + WrtLen;
				Vram   	:= Vram + WrtLen;
			End;
		End; {with}
	End;


Begin
	pt := Addr(at);
    Inline($f3/$01/6/0/ $2a/WindowPtr/ $ed/$5b/ pt/$ed/$b0 );
    With at Do
	Begin
		Bottom 	:= WinHeigth - 1;
		Vram 	:= WinCol + CurCol + (WinRow + CurRow - 1) * 80;
		If St = '' Then
		Begin
			CurRow := CurRow+1;
			CurCol := 1;
			If (CurRow >= Bottom) And (WinHeigth > 3 ) Then { No scroll for one }
			Begin                                       	{ line window ! }
				ScrollWindowUp(WindowPtr);
				CurRow := Bottom-1;
			End;
			Goto Out;
		End;

		StIndex := 1;
		WrtLen 	:= WinLen  - CurCol - 1;
		LinLen 	:= WinLen - 2;

		If Length(St) > WrtLen Then     {String long,exceeds to next row}
		Begin
			FillRow(StIndex);
			While (Length(st)-StIndex+1) >= LinLen Do
				FillRow(StIndex);
			If Length(St) - StIndex >= 0 Then
				WriteRow(StIndex);
        End
		Else
        Begin
			If Length(St) < WrtLen Then  {Str short, doesn't exceed to next row}
				WriteRow(StIndex)
			Else
				FillRow(StIndex);	{Str just fills the line}
		End;
	End; {With}
    Out:
		Inline($f3/$01/6/0/ $2a/pt / $ed/$5b/ WindowPtr/$ed/$b0/$fb );
End; {WritelnWindow}

Procedure WritelnWindow(WindowPtr: Pointer; St: TString);
Begin
	_WriteWindowOperation(WindowPtr,St,True); {True -> do linefeed }
End;

Procedure WriteWindow(WindowPtr: Pointer; St: TString);
Begin
	_WriteWindowOperation(WindowPtr,St,False);
End;

Procedure GotoWindowXY(WindowPtr:Pointer; Col, Row: Byte);
Begin
	pt 	:= WindowPtr;
	GotoXY(Mem[at] + Col + 1, Mem[at+1] + Row);
    Mem[at+4] := Col;
    Mem[At+5] := Row;
End;

Procedure ClrEolWindow(WindowPtr:Pointer);
Var
	CurCol,CurRow:	Byte;
	WrtLen:			Byte;

Begin
	pt 		:= WindowPtr;
	CurRow 	:= Mem[at+5];
	CurCol 	:= Mem[at+4] ;
	Vram 	:= Mem[at] + (Mem[at+1] + CurRow - 1) * 80 + CurCol;
	WrtLen 	:= Mem[at+2] - 1 - CurCol;
	FillVram(0, Vram, 32, WrtLen);
	CURSAV 	:= 32;
End;

Procedure ClrWindow (WindowPtr: Pointer);
Var 
	i:	Byte;
Begin
	pt 		:= WindowPtr;
	Vram 	:= Mem[at] + 1 + (Mem[at+1]) * 80;
	For i := 1 to Mem[at+3]-2 Do
	Begin
		FillVram(0,Vram,32,Mem[at+2]-2);
		Vram := Vram + 80;
	End;
	Mem[at+4] := 1;
	Mem[at+5] := 1;
End;
