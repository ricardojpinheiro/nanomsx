program teste;
type 
    linestring = string[255];
    
var
    S: linestring;
    a, b, c, d: integer;
    tempnumber0, tempnumber1: string[6];

procedure switch_to_Z80;
begin
    inline($3e/$00/              { LD A,0           }
           $fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$80/$01/      { LD IX,&H0180     }
           $cd/$1c/$00/          { CALL &H001C      }
           $fb)                  { EI               }
end;

procedure switch_to_R800;
begin
    inline($3e/$00/              { LD A,1           }
           $fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$80/$01/      { LD IX,&H0180     }
           $cd/$1c/$00/          { CALL &H001C      }
           $fb)                  { EI               }
end;

function processor_type:byte;
var soort:byte;

begin
    inline($fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$83/$01/      { LD IX,&H0183     }
           $cd/$1c/$00/          { CALL &H001C      }
           $32/soort/            { LD (SOORT),A     }
           $fb);                 { EI               }
    processor_type:=soort
end;

function msx_version:byte;
var v:byte;

begin
     inline($3a/$c1/$fc/          { LD A,(&HFCC1) ; slot da ROM BIOS }
            $21/$2d/$00/          { LD HL,&H002D     }
            $cd/$0c/$00/          { CALL &H000C      }
            $32/v);               { LD (V),A    }

    msx_version:=v+1
end;

function Readkey: char;
var
    bt: integer;
    qqc: byte absolute $FCA9;
 
begin
    Readkey := chr(0);
    qqc := 1;
    Inline($f3/$fd/$2a/$c0/$fc/$DD/$21/$9F/00/$CD/$1c/00/$32/bt/$fb);
    Readkey := chr(bt);
    qqc := 0;
end;

(*  Finds the n-th occurence of a char which is into a string. *)

function NNPos(SearchPhrase, Phrase: linestring; Ntuple: byte): byte;
var
    HowManyPos, ResultPos, counter, LengthPhrase, LengthSearchPhrase: byte;
    temp: linestring;
begin
    LengthPhrase := length (Phrase);
    LengthSearchPhrase := length (SearchPhrase);
    counter := 1;
    ResultPos := 0;
    HowManyPos := 0;
    while (counter <= LengthPhrase) and (HowManyPos < Ntuple) do
    begin
        temp := copy(Phrase, counter, LengthSearchPhrase);
        if SearchPhrase = temp then
        begin
            ResultPos := counter;
            HowManyPos := HowManyPos + 1;
        end;
        counter := counter + 1;
    end;    
    NNPos := ResultPos;
end;

function readstring: linestring;
type
    ASCII = set of 0..127;
var
    NoPrint, Print, AllChars: ASCII;
    c: char;
    fallback: linestring;
    
begin
    AllChars := [0..127];
    NoPrint := [0..31, 127];
    Print := AllChars - NoPrint;
    c := ' ';
    fallback := ' ';
    while c <> #13 do
    begin
        c := readkey;
        if ord(c) in Print then
        begin
            fallback := fallback + c;
            write(c);
        end;
    end;
    readstring := fallback;
end;

function Percentage (a, b: real): integer;

(* Só é usado na rotina Location. *)

begin
    if b <> 0 then
        Percentage := round(int((a*100)/b))
    else
        Percentage := 0;
end;

(*  Finds the n-th occurence of a char which is into a string. *)

function NPos(SearchPhrase, Phrase: linestring; Ntuple: byte): byte;
var
    HowManyPos, ResultPos, counter, LengthPhrase, 
    LengthSearchPhrase: byte;
    temp: linestring;

begin
    LengthPhrase := length (Phrase);
    LengthSearchPhrase := length (SearchPhrase);
    counter := 1;
    ResultPos := 0;
    HowManyPos := 0;

    while (counter <= LengthPhrase) and (HowManyPos < Ntuple) do
    begin
        temp := copy(Phrase, counter, LengthSearchPhrase);
        if SearchPhrase = temp then
        begin
            ResultPos := counter;
            HowManyPos := HowManyPos + 1;
        end;
        counter := counter + 1;
    end;    

    NPos := ResultPos;
end;

begin
    S := readstring;
    delete (s, 1, 1);
    a := Pos(chr(32), S);
    tempnumber0 := copy(S, 1, a - 1);
    tempnumber1 := copy(S, a + 1, length(S));
    writeln;
    writeln('a: ', a, ' tempnumber0: ', tempnumber0, ' tempnumber1: ', tempnumber1);
    val (tempnumber0, b,   d);
    writeln(b, ' -> ', d);
    val (tempnumber1, c,   d);
    writeln(c, ' -> ', d);
    exit;
    
    writeln(abs(3 - 10));
    S := 'abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz';
    writeln(S, ' ', length(S));
    writeln(NNPos('a', S, 1));
    writeln(NNPos('o', S, 1));
    writeln(NNPos('z', S, 1));
    writeln(NNPos('o', S, 2));
    writeln(NNPos('t', S, 1));
    writeln(NNPos('Ricardo', S, 1));
    a := -32736;
    b := hi (a) div $40;
    c := lo (a);
    d := hi (a) and 63;
    writeln(a, ' ', b, ' ', c, ' ', d);
    b := a div $4000;
    c := a mod 256;
    d := (a Div 256 ) And 63;
    writeln(a, ' ', b, ' ', c, ' ', d);
    
    writeln(msx_version);
end.
