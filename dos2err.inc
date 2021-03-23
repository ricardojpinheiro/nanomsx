(*<dos2err.pas> CopyLeft (c) since 1995 by PopolonY2k. *)

Const       ctMSXDOSMsgSize = 65;  { Error message buffer size }

(* MSXDOS error and message string. *)
Type TMSXDOSString = String[ctMSXDOSMsgSize];

(* Get the error code, caused by the previous MSX-DOS function call. *)

Function GetLastErrorCode : Byte;
Var
       regs  : TRegs;

Begin
  regs.C := ctGetPreviousErrorCode;
  MSXBDOS( regs );
  GetLastErrorCode := regs.B;
End;

(* Get the error message based on MSX-DOS error code passed by parameter; *)
Procedure GetErrorMessage( nErrorCode : Byte; Var strErrMsg : TMSXDOSString );
Var
      regs      : TRegs;
      szErrMsg  : Array[0..ctMSXDOSMsgSize] Of Char;
      nZeroPos  : Byte;

Begin
  strErrMsg := '';
  regs.C    := ctExplainErrorCode;
  regs.B    := nErrorCode;
  regs.DE   := Addr( szErrMsg );
  MSXBDOS( regs );

  If( ( regs.B = 0 ) Or ( regs.B = nErrorCode ) )  Then
  Begin
    nZeroPos := Pos( #0, szErrMsg );

    If( nZeroPos > 0 )  Then
    Begin
      strErrMsg[0] := Char( nZeroPos );
      Move( szErrMsg, strErrMsg[1], nZeroPos );
    End;
  End;
End;
