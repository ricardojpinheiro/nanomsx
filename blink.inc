{Needs wrtvram.inc }

Procedure _WrtVdp(Port, Value: Byte);
Begin
    Inline ($F3/$3A/ Value  /$D3/$99/$3A/ Port /$F6/$80/$D3/$99 );
End;

Procedure SetBlinkRate(OnTime, OffTime: Byte);
Begin
    _WrtVdp(Vdp14,  OnTime * 16 + OffTime);
End;

Procedure SetBlinkColors(ForegroundColor, BackgroundColor:  Byte);
Begin
    _WrtVdp(Vdp13,  ForegroundColor * 16 + BackgroundColor);
End;

Procedure SetBit(TableAddr, BitNumber: Byte; Operation: Boolean);
Begin
    Byt := ColTbl[TableAddr];
    If Operation = SetB Then
        Byt := Byt Or MaskTable[BitNumber]
    Else
        Byt := Byt and (255 - MaskTable[BitNumber]);
    ColTbl[TableAddr] := Byt;
End;

Procedure BlinkChar(Col, Row: Byte);
Begin
    TableAddr :=  ((Row - 1) * 80 + Col - 1) Div 8;
    Byt       :=  ((Row - 1) * 80 + Col - 1) Mod 8;
    SetBit(TableAddr, Byt, SetB);
    WriteVram(0, TXTCOL + TableAddr, Addr(ColTbl[TableAddr]), 1);
End;

Procedure ClearBlinkChar(Col, Row: Byte);
Begin
    TableAddr :=  ((Row - 1) * 80 + Col - 1) Div 8;
    Byt       :=  ((Row - 1) * 80 + Col - 1) Mod 8;
    SetBit(TableAddr, Byt, ResB);
    WriteVram(0, TXTCOL + TableAddr, Addr(ColTbl[TableAddr]), 1);
End;

Procedure Blink(Col, Row, Len: Byte);
Var
    TableAddr:  Integer;
    Byt, i:     Byte;

Begin
    TableAddr :=  ((Row - 1) * 80 + Col - 1) Div 8;
    Byt       :=  ((Row - 1) * 80 + Col - 1) Mod 8;

    For i:= 1 to Len Do
    Begin
        SetBit(TableAddr, Byt, SetB);
        Byt := Byt + 1;
        If Byt = 8 Then
        Begin
            Byt := 0;
            TableAddr := TableAddr + 1;
        End;
    End;
    WriteVram(0, TXTCOL, Addr(ColTbl), 256);
End;

Procedure ClearBlink(Col, Row, Len: Byte);
Var
    Byt, i:     Byte;
    TableAddr:  Integer;

Begin
    TableAddr :=  ((Row - 1) * 80 + Col - 1) Div 8;
    Byt       :=  ((Row - 1) * 80 + Col - 1) Mod 8;

    For i:= 1 to Len Do
    Begin
        SetBit(TableAddr, Byt, ResB);
        Byt := Byt + 1;
        If Byt = 8 Then
        Begin
            Byt := 0;
            TableAddr := TableAddr + 1;
        End;
    End;
    WriteVram(0, TXTCOL, Addr(ColTbl), 256);
End;

Procedure ClearAllBlinks;
Begin
    FillChar(ColTbl, 256, 0);
    WriteVram(0, TXTCOL, Addr(ColTbl), 256);
End;

Procedure CursorBlink(Len: Byte);
Begin
    Blink(CSRX, CSRY, Len);
End;

Procedure ClearCursorBlink(Len: Byte);
Begin
    ClearBlink(CSRX, CSRY, Len);
End;
