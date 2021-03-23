Const 
	ctMaxPath = 127;    { Maximum path size - MSXDOS2 }

Type
	TFileName	= String[ctMaxPath];       { File name path type }
	Pointer		= ^Byte;                   { Pointer generic type }
	TString		= String[255];
	Str15 		= String[15];

	TRegs = Record
		IX       : Integer;             { 16Bit index registers }
		IY       : Integer;

		Case Byte Of    { 8Bit registers and 16Bit registers - WORD_REGS }
    			0 : ( C,B,E,D,L,H,F,A  : Byte );      { 8bit registers  }
    			1 : ( BC,DE,HL,AF      : Integer );   { 16bit registers }
		End;

	TTextMode = ( TextMode4080, TextMode32 );

	TCursorStatus = ( CursorEnabled,
                       	CursorDisabled,
                       	CursorBlock,
                       	CursorUnderscore );

	TScreenStatus = Record
			nWidth,
			nBkColor,
			nFgColor,
			nBdrColor : Byte;
			bFnKeyOn : Boolean;
			TextMode : TTextMode;
			End;

Procedure CALSLT( Var regs : TRegs );
Var
        nA, nF         : Byte;
        nHL, nDE, nBC  : Integer;
        nIX, nIY       : Integer;
Begin
  nA  := regs.A;
  nHL := regs.HL;
  nDE := regs.DE;
  nBC := regs.BC;
  nIX := regs.IX;
  nIY := Swap( regs.IY );

  InLine( $F5/                  { PUSH AF      ; Push all registers  }
          $C5/                  { PUSH BC                            }
          $D5/                  { PUSH DE                            }
          $E5/                  { PUSH HL                            }
          $DD/$E5/              { PUSH IX                            }
          $FD/$E5/              { PUSH IY                            }
          $3A/nA/               { LD A , (nA )                       }
          $ED/$4B/nBC/          { LD BC, (nBC)                       }
          $ED/$5B/nDE/          { LD DE, (nDE)                       }
          $2A/nHL/              { LD HL, (nHL)                       }
          $DD/$2A/nIX/          { LD IX, (nIX)                       }
          $FD/$2A/nIY/          { LD IY, (nIY)                       }
          $CD/$1C/$00/          { CALL &H001C; CALL CALSLT           }
          $32/nA/               { LD (nA ), A                        }
          $ED/$43/nBC/          { LD (nBC), BC                       }
          $ED/$53/nDE/          { LD (nDE), DE                       }
          $22/nHL/              { LD (nHL), HL                       }
          $DD/$22/nIX/          { LD (nIX), IX                       }
          $FD/$22/nIY/          { LD (nIY), IY                       }
          $F5/                  { PUSH AF                            }
          $E1/                  { POP HL                             }
          $22/nF/               { LD (nF), HL                        }
          $FD/$E1/              { POP YI       ; Pop all registers   }
          $DD/$E1/              { POP IX                             }
          $E1/                  { POP HL                             }
          $D1/                  { POP DE                             }
          $C1/                  { POP BC                             }
          $F1/                  { POP AF                             }
          $FB                   { EI                                 }
        );

  (* Update the caller register struct *)
  regs.A  := nA;
  regs.F  := nF;
  regs.BC := nBC;
  regs.DE := nDE;
  regs.HL := nHL;
  regs.IY := nIY;
  regs.IX := nIX;
End;

Procedure CHPUT( chChar : Char );
Const
        ctCHPUT   = $00A2;   { Output a character to the console }

Var
        regs    : TRegs;
        EXPTBL  : Byte Absolute $FCC1; { Slot 0 }

Begin
  regs.IX := ctCHPUT;
  regs.IY := EXPTBL;
  regs.A  := Byte( chChar );
  CALSLT( regs );
End;

Procedure Width( nWidth : Byte );
Const
       ctINITXT  = $006C; { Initialize screen for text mode (40x24) }

Var
       regs    : TRegs;
       EXPTBL  : Byte Absolute $FCC1; { Slot 0 }
       LINL40  : Byte Absolute $F3AE; { Width for SCREEN 0 }

Begin
  LINL40  := nWidth;
  regs.IX := ctINITXT;
  regs.IY := EXPTBL;
  CALSLT( regs );
End;

Procedure SetTextMode( mode : TTextMode );
Const
        ctINITXT  = $006C;    { Initialize screen for text mode (40x24) }
        ctINIT32  = $006F;    { Initialize screen mode for text (32x24) }

Var
        regs    : TRegs;
        EXPTBL  : Byte Absolute $FCC1; { Slot 0 }

Begin
  If( mode = TextMode4080 )  Then
    regs.IX := ctINITXT
  Else
    regs.IX := ctINIT32;

  regs.IY := EXPTBL;
  CALSLT( regs );
End;

Procedure InitFnKeys;
Const
	ctINIFNK = $003E;
Var
	regs	: TRegs;
        EXPTBL  : Byte Absolute $FCC1; { Slot 0 }	

Begin
	regs.IX := ctINIFNK;
	regs.IY := EXPTBL;
  	CALSLT( regs );
End;

Procedure SetFnKeyStatus( bFnKeyStatus : Boolean );
Const
          ctERAFNK  = $00CC;    { Erase the function key display   }
          ctDSPFNK  = $00CF;    { Display the function key display }

Var
        regs    : TRegs;
        EXPTBL  : Byte Absolute $FCC1; { Slot 0 }

Begin
  If( bFnKeyStatus )  Then
    regs.IX := ctDSPFNK
  Else
    regs.IX := ctERAFNK;

  regs.IY := EXPTBL;
  CALSLT( regs );
End;

Procedure SetCursorStatus( cursor : TCursorStatus );
Var
     nCount      : Byte;
     strCtrlCode : String[3];

Begin   { Procedure entry point }
  Case( cursor ) Of
    CursorEnabled    : strCtrlCode := 'x5';
    CursorDisabled   : strCtrlCode := 'y5';
    CursorBlock      : strCtrlCode := 'x4';
    CursorUnderscore : strCtrlCode := 'y4';
  End;

  strCtrlCode := #27 + strCtrlCode;

  For nCount := 1 To Length( strCtrlCode ) Do
    CHPUT( strCtrlCode[nCount] );
End;

Procedure GetScreenStatus( Var scrStatus : TScreenStatus );
Var
      LINLEN : Byte Absolute $F3B0; { Width for the current text mode         }
      CNSDFG : Byte Absolute $F3DE; { =0 when function keys are not displayed }
      SCRMOD : Byte Absolute $FCAF; { Current screen number }
      FORCLR : Byte Absolute $F3E9; { Foreground color }
      BAKCLR : Byte Absolute $F3EA; { Background color }
      BDRCLR : Byte Absolute $F3EB; { Border color     }

Begin
  With scrStatus Do
  Begin
    nWidth    := LINLEN;
    nBkColor  := BAKCLR;
    nBdrColor := BDRCLR;
    nFgColor  := FORCLR;
    bFnKeyOn  := ( CNSDFG <> 0 );

    If( SCRMOD = 0 )  Then
      TextMode := TextMode4080
    Else
      TextMode := TextMode32;
  End;
End;

procedure SetFnKey(i: byte; st: str15);
var 
    ei, a, c: integer;
    cm: str15;

begin
  if (length(st) = 0) then
    exit;

  fillchar(cm, sizeof(cm), chr(0));
  for a := 1 to 14 do
    cm := cm + chr(0);

  st := st + cm;
  ei := $F87f + 16 * (i - 1) - 1;

  for a := 1 to 15 do
  begin
    c := ord(copy(st, a, 1)); 
    mem[ei + a] := c;
  end;
  mem[ei + a + 1] := 0;
end;

function msx_version: byte;
var 
	version :	byte;
begin
  inline($3e/$80/              { LD A,&H80        }
         $21/$2d/$00/          { LD HL,&H002D     }
         $cd/$0c/$00/          { CALL &H000C      }
         $32/version/          { LD (VERSIE),A    }
         $fb);                 { EI               }
  msx_version := version + 1;
end;
