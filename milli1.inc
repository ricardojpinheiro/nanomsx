(*
*  milli1.inc - Pascal library which is used with the milli text editor.
*  So, some routines were taken from the main program to be placed here.
*)

const
    CONTROLA    = 1;
    CONTROLB    = 2;
    CONTROLC    = 3;
    CONTROLD    = 4;
    CONTROLE    = 5;
    CONTROLF    = 6;
    CONTROLG    = 7;
(*    CONTROLH    = 8; *)
(*    CONTROLI    = 9; *)
    CONTROLJ    = 10;
(*    CONTROLK    = 11; *)
(*    CONTROLL    = 12; *)
(*    CONTROLM    = 13; *)
    CONTROLN    = 14;
    CONTROLO    = 15;
    CONTROLP    = 16;
    CONTROLQ    = 17;
(*    CONTROLR    = 18; *)
    CONTROLS    = 19;
    CONTROLT    = 20;
(*    CONTROLU    = 21; *)
    CONTROLV    = 22;
    CONTROLW    = 23;
(*    CONTROLX    = 24; *)
    CONTROLY    = 25;
    CONTROLZ    = 26;
    BS          = 8;
    TAB         = 9;
    HOME        = 11;
    CLS         = 12;
    ENTER       = 13;
    INSERT      = 18;
    SELECT      = 24;
    ESC         = 27;
    RightArrow  = 28;
    LeftArrow   = 29;
    UpArrow     = 30;
    DownArrow   = 31;
    Space       = 32;
    DELETE      = 127;

    maxlines    = 1568;
    maxcols     = 80;
    maxwidth    = 78;
    maxlength   = 21;

    startvram       = 5120;
    limitvram       = 65280;

type
    RStructure          = record
        VRAMBank:           byte;
        VRAMposition:       integer;
    end;
    
    linestring          = string [maxcols];
    KeystrokeLines      = (main, search, replace, align);
    Directions          = (forwardsearch, backwardsearch);
    LocationOptions     = (Position, HowMany);
    BlockMarkings       = (BlockBegin, BlockFinish);
    ASCII               = set of 0..255;

var
    textlines:          array [1..maxlines] of RStructure;
    emptylines:         array [1..maxlines] of boolean;
    temp:               linestring;
    StatusWindowPtr:    Pointer;
    NoPrint, Print, 
    AllChars:           ASCII;

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

(* Finds the last occurence of a char into a string. *)

function RPos(Character: char; Phrase: linestring): integer;
var
    i: byte;
    Found: boolean;

begin
    i := length(Phrase);
    Found := false;
    repeat
        if Phrase[i] = Character then
        begin
            RPos := i + 1;
            Found := true;
        end;
        i := i - 1;
    until Found;
    if Not Found then RPos := 0;
end;

(*  Finds the first occurence of a char which is different into a
*   string. *)

function DifferentPos(Character: char; Phrase: linestring): byte;
var
    i: byte;
    Found: boolean;

(* Só é usado dentro da rotina AlignText. *)

begin
    i := 1;
    Found := false;

    repeat
        if Phrase[i] <> Character then
        begin
            DifferentPos := i;
            Found := true;
        end;
        i := i + 1;
    until (Found) or (i >= length(Phrase));

    if Not Found then DifferentPos := 0;
end;

(*  Finds the last occurence of a char which is different into a
*   string. *)

function RDifferentPos(Character: char; Phrase: linestring): integer;
var
    i: byte;
    Found: boolean;

(* Só é usado dentro da rotina AlignText. *)
    
begin
    i := length(Phrase);
    Found := false;

    repeat
        if Phrase[i] <> Character then
        begin
            RDifferentPos := i;
            Found := true;
        end;
        i := i - 1;
    until Found or (i <= 1);

    if Not Found then RDifferentPos := 0;
end;

(*  Finds the n-th occurence of a char which is into a string. *)
(*
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
*)

procedure CheatAPPEND (FileName: linestring);
var
    i, FirstTwoDotsFound, LastBackSlashFound: byte;
    APPEND: string[7];
    Path, Temporary: linestring;
    Registers: TRegs;
    
begin

(* Initializing some variables... *)
    fillchar(Path, sizeof(Path), ' ' );
    fillchar(Temporary, sizeof(Temporary), ' ' );
    APPEND[0] := 'A';   APPEND[1] := 'P';   APPEND[2] := 'P';
    APPEND[3] := 'E';   APPEND[4] := 'N';   APPEND[5] := 'D';
    APPEND[6] := #0;
    
(*  Sees if in the path there is a ':', used with drive letter. *)    
    FirstTwoDotsFound := Pos (chr(58), FileName);

(*  If there is a two dots...  *)
    if FirstTwoDotsFound <> 0 then
    begin
    
(*  Let me see where is the last backslash character...  *)
        LastBackSlashFound := RPos (chr(92), FileName);
        Path := copy (FileName, 1, LastBackSlashFound);

(*  Copy the path to the variable. *)
        for i := 1 to LastBackSlashFound - 1 do
            Temporary[i - 1] := Path[i];
        Temporary[LastBackSlashFound] := #0;
        Path := Temporary;

(*  Sets the APPEND environment variable. *)
        with Registers do
        begin
            B := sizeof (Path);
            C := ctSetEnvironmentItem;
            HL := addr (APPEND);
            DE := addr (Path);
        end;
        MSXBDOS (Registers);
    end;
end;

procedure TRZ80mode;
begin
    inline($3e/$00/$fd/$2a/$c0/$fc/$dd/$21/$80/$01/$cd/$1c/$00/$fb);
end;

procedure TRR800mode;
begin
    inline($3e/$00/$fd/$2a/$c0/$fc/$dd/$21/$80/$01/$cd/$1c/$00/$fb);
end;

procedure FromRAMToVRAM(var tempstr: linestring; linenumber: integer);
begin
    with textlines[linenumber] do
        WriteVRAM(VRAMBank, VRAMposition, addr(tempstr), maxcols);
end;

procedure FromVRAMToRAM(var tempstr: linestring; linenumber: integer);
begin
    with textlines[linenumber] do
        ReadVRAM(VRAMBank, VRAMposition, addr(tempstr), maxcols);
end;

procedure InitVRAM(linenumber: integer; var counter: real);
begin
    with textlines[linenumber] do
    begin
        if linenumber = 1 then
        begin
            VRAMposition    := startvram;
            VRAMBank        := 0;
        end
        else
        begin
            VRAMposition    :=  textlines[linenumber - 1].VRAMposition
                                                            + maxcols;
            VRAMBank        :=  textlines[linenumber - 1].VRAMBank;
        end;

        if counter >= limitvram then
        begin
            VRAMBank        := VRAMBank + 1;
            VRAMposition    := $0000;
            counter         := 0;
        end;
    end;
    emptylines[linenumber] := true;
end;

function SearchForBlankBlock(BlankLines: integer): integer;
var
    i, k: integer;
    LastPosition: boolean;

begin
    i := 0;
    k := 0;
    LastPosition := true;

    while (i <= maxlines) and (k < BlankLines) do
    begin
        i := i + 1;
        if emptylines[i] = true then
            k := k + 1
        else
            k := 0;
    end;

    SearchForBlankBlock := i - BlankLines;
end;   

procedure InsertLinesIntoText(CurrentLine   : integer;
                            var TotalLines  : integer;
                                BlankLines  : integer); 
var
    i, NewBeginBlock: integer;
    
begin

(*  Move o bloco de texto, até o fim, BlankLines para baixo. *)
    i := (TotalLines + 1) - CurrentLine;
    Move(textlines[CurrentLine], textlines[CurrentLine + BlankLines],
        sizeof(textlines[BlankLines]) * i);

(*  Bloqueia as linhas novas, de forma que na busca por trechos em
*   branco, elas não sejam consideradas. *)
    for i := (TotalLines + 1) to (TotalLines + BlankLines) do 
        emptylines[i] := false;

(*  Procura por blocos vazios do tamanho exato que precisamos, para 
*   redirecionar o bloco de texto na VRAM. *)
    NewBeginBlock := SearchForBlankBlock(BlankLines);

    for i := (CurrentLine + 1) to (CurrentLine + BlankLines) do 
    begin

(*  Reposiciona, na tabela de alocações, o bloco de texto da VRAM. *)
        textlines[i].VRAMBank       := textlines[NewBeginBlock + 
                                    (i - CurrentLine) + 1].VRAMBank;
        textlines[i].VRAMPosition   := textlines[NewBeginBlock + 
                                    (i - CurrentLine) + 1].VRAMPosition;
    end;

(*  Novo máximo, acrescido de BlankLines. *)
    TotalLines := TotalLines + BlankLines;

(*  Marca no vetor emptylines, que essas linhas estão bloqueadas. *)
    for i := (CurrentLine + 1) to TotalLines do
        emptylines[i] := false;
end;

procedure DeleteLinesFromText(CurrentLine: integer;
                            var TotalLines: integer;
                                DeletedLines: integer); 
var
    i, NewBeginBlock: integer;
    
begin

(*  Move o bloco de texto, até o fim, DeletedLines para cima. *)
    i := TotalLines - CurrentLine;
    Move(textlines[CurrentLine + DeletedLines], textlines[CurrentLine],
        sizeof(textlines[DeletedLines]) * i);

(*  Libera as linhas novas no final, de forma que na busca por trechos
*   em branco, elas sejam consideradas. *)
    for i := (TotalLines - DeletedLines) to TotalLines do 
        emptylines[i] := true;

(*  Novo máximo, acrescido de BlankLines. *)
    TotalLines := TotalLines - DeletedLines;
end;

procedure ClearStatusLine;
begin
    ClearBlink(1, maxlength + 1, maxwidth + 2);
    FillChar(temp, maxwidth + 3, #23);
    temp[1]             := #26;
    temp[maxwidth + 2]  := #27;
    WriteVRAM(0, (maxwidth + 2) * maxlength, Addr(temp[1]), maxwidth + 3);
end;

procedure CommandLine (KindOf: byte);
(*
*  1 - Version
*  2 - Help
*)

begin
    clrscr;
    FastWriteln('              ##     mmmm      mmmm         ##    ');
    FastWriteln('              ""     ""##      ""##         ""    ');
    FastWriteln(' ####m##m   ####       ##        ##       ####    ');
    FastWriteln(' ## ## ##     ##       ##        ##         ##    ');
    FastWriteln(' ## ## ##     ##       ##        ##         ##    ');
    FastWriteln(' ## ## ##  mmm##mmm    ##mmm     ##mmm   mmm##mmm ');
    FastWriteln(' "" "" ""  """"""""     """"      """"   """""""" ');

    case KindOf of
        1: begin (* Version *)
                FastWriteln('Version 0.6 - Copyright (c) 2020-2022 Brazilian MSX Crew.');
                FastWriteln('Some rights reserved (not many!).');
                writeln;
                FastWriteln('This editor resembles the GNU nano editor, with the same');
                FastWriteln('look and feel and many of the same keystrokes.');
                writeln;
                FastWriteln('It''s licensed under the GPLv3+ license. Yep, free software.');
                FastWriteln('You are free to change and redistribute it. But don''t ask me');
                FastWriteln('about any warranties... Use it at your own risk.');
                FastWriteln('http://www.nano-editor.org http://gnu.org/licenses/gpl.html');
                writeln;
                FastWriteln('By the way, ''milli'' may came from two places:');
                FastWriteln('1) Unit prefix in the metric system - factor of 1/1000.');
                FastWriteln('2) Milliways, the restaurant at the end of the Universe, from');
                FastWriteln('The Hitchhiker''s Guide to the Galaxy book series.');
                FastWriteln('Personally, I would prefer the last one. ');
            end;
        2: begin (* Help *)
                FastWriteln('Usage: milli <file> <parameters>');
                FastWriteln('Text editor.');
                writeln;
                FastWriteln('File: Text file which will be edited.');
                writeln;
                FastWriteln('Parameters: ');
{    
    FastWriteln('/b      - Save backups of existing files.');
    FastWriteln('/e      - Convert typed tabs to spaces.');
}
                FastWriteln('/l<l>   - Start at line l.');
                FastWriteln('/c<c>   - Start at column c.');
                FastWriteln('/t<n>   - Make a tab this number (n) of columns wide.');
                FastWriteln('/h      - Show this help text and exit.');
                FastWriteln('/v      - Output version information and exit.');
                writeln;
            end;
        end;
    ClearAllBlinks;
    halt;
end;

procedure CopyBlock(FirstLineBlock, LastLineBlock, FirstLineCopy: integer);
var
    i: integer;

begin
    for i := FirstLineBlock to LastLineBlock do
    begin
        textlines   [FirstLineCopy + i - FirstLineBlock]    := textlines[i];
        emptylines  [FirstLineCopy + i - FirstLineBlock]    := false;
    end;
end;
