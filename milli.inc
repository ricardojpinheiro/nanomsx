(*
*  milli.inc - Pascal library which is used with the milli text editor.
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
    CONTROLU    = 21;
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

    startvram   = 5120;
    limitvram   = 65408;

    maxlines    = 980;
    maxwidth    = 78;
    maxlength   = 21;
    maxcols     = 128;

type
    RStructure          = record
        VRAMBank:           byte;
        VRAMposition:       integer;
    end;
    
    str80               =   string [80];
    linestring          =   string [128];
    KeystrokeLines      =   (main, search, replace, align);
    Directions          =   (forwardsearch, backwardsearch);
    LocationOptions     =   (Position, HowMany);

var
    textlines:          array [1..maxlines] of RStructure;
    emptylines:         array [1..maxlines] of boolean;
    temp:               linestring;
    StatusWindowPtr:    Pointer;

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

function NPos(SearchPhrase, Phrase: linestring; Ntuple: byte): byte;
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
    NPos := ResultPos;
end;


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

(* Here we use MSX-DOS 2 to do the error handling. *)

procedure ErrorCode (ExitsOrNot: boolean);
var
    ErrorCodeNumber: byte;
    ErrorMessage: TMSXDOSString;
    
begin
    ErrorCodeNumber := GetLastErrorCode;
    GetErrorMessage (ErrorCodeNumber, ErrorMessage);
    WriteLn (ErrorMessage);
    if ExitsOrNot = true then
        Exit;
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

procedure InsertLinesIntoText(CurrentLineText: integer;
                            var TotalLinesText: integer;
                                BlankLinesText: integer); 
var
    i, NewBeginBlock: integer;
    
begin
(*  Move o bloco de texto, até o fim, BlankLinesText para baixo. *)

    i := (TotalLinesText + 1) - CurrentLineText;
    Move(textlines[CurrentLineText], textlines[CurrentLineText + BlankLinesText],
        sizeof(textlines[BlankLinesText]) * i);

(*  Bloqueia as linhas novas, de forma que na busca por trechos em
*   branco, elas não sejam consideradas. *)

    for i := (TotalLinesText + 1) to (TotalLinesText + BlankLinesText) do 
        emptylines[i] := false;

(*  Procura por blocos vazios do tamanho exato que precisamos, para 
*   redirecionar o bloco de texto na VRAM. *)

    NewBeginBlock := SearchForBlankBlock(BlankLinesText);

    for i := CurrentLineText to (CurrentLineText + BlankLinesText - 1) do 
    begin

(*  Reposiciona, na tabela de alocações, o bloco de texto da VRAM. *)

        textlines[i].VRAMBank       := textlines[NewBeginBlock + 
                                        (i - CurrentLineText) + 1].VRAMBank;
        textlines[i].VRAMPosition   := textlines[NewBeginBlock + 
                                    (i - CurrentLineText) + 1].VRAMPosition;
    end;

(*  Novo máximo, acrescido de BlankLinesText. *)

    TotalLinesText := TotalLinesText + BlankLinesText - 1;

(*  Marca no vetor emptylines, que essas linhas estão bloqueadas. *)
    
    for i := (CurrentLineText + 1) to TotalLinesText do
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

procedure CommandLineBanner;
begin
    FastWriteln('              ##     mmmm      mmmm         ##    ');
    FastWriteln('              ""     ""##      ""##         ""    ');
    FastWriteln(' ####m##m   ####       ##        ##       ####    ');
    FastWriteln(' ## ## ##     ##       ##        ##         ##    ');
    FastWriteln(' ## ## ##     ##       ##        ##         ##    ');
    FastWriteln(' ## ## ##  mmm##mmm    ##mmm     ##mmm   mmm##mmm ');
    FastWriteln(' "" "" ""  """"""""     """"      """"   """""""" ');
end;

(*  Command version.*)

procedure CommandLineVersion;
begin
    clrscr;
    CommandLineBanner;
    FastWriteln('Version 0.2 - Copyright (c) 2020, 2021 Brazilian MSX Crew.');
    FastWriteln('Some rights reserved.');
    writeln;
    FastWriteln('This editor resembles the GNU nano editor <https://www.nano-editor.org>,');
    FastWriteln('using the same look-and-feel and a lot of keystrokes.');
    writeln;
    FastWriteln('License GPLv3+: GNU GPL v. 3 or later <https://gnu.org/licenses/gpl.html>');
    FastWriteln('This is free software: you are free to change and redistribute it.');
    FastWriteln('There is NO WARRANTY to the extent permitted by law.');
    writeln;
    FastWriteln('By the way, the name, ''milli'', may come from two places:');
    FastWriteln('1 - A unit prefix in the metric system denoting a factor of one thousandth.');
    FastWriteln('2 - The restaurant at the end of the Universe, called Milliways, from');
    FastWriteln('the Hitchhiker''s Guide to the Galaxy series, written by Douglas Adams.');
    FastWriteln('Personally, I would prefer the last one. ');
    ClearAllBlinks;
    halt;
end;

procedure CommandLineHelp;
begin
    clrscr;
    CommandLineBanner;
    FastWriteln('Usage: milli <file> <parameters>');
    FastWriteln('Text editor.');
    writeln;
    FastWriteln('File: Text file which will be edited.');
    writeln;
    FastWriteln('Parameters: ');
{    
    FastWriteln('/b             - Save backups of existing files.');
    FastWriteln('/e             - Convert typed tabs to spaces.');
}
    FastWriteln('/l<l>          - Start at line l.');
    FastWriteln('/c<c>          - Start at column c.');
    FastWriteln('/t<n>          - Make a tab this number (n) of columns wide.');
    FastWriteln('/h             - Show this help text and exit.');
    FastWriteln('/v             - Output version information and exit.');
    writeln;
    ClearAllBlinks;
    halt;
end;

{
procedure locate;
var
    pointer, position, len          : integer;
    c                               : char;

begin
    SetBlinkRate (5, 0);
    temp := 'String to be located: ';
    j := length (temp);
    StatusWindowPtr := MakeWindow (1, 12, 79, 3, 'Search');
    GotoWindowXY (StatusWindowPtr, 1, 1);
    WriteWindow(StatusWindowPtr, temp);
    GotoWindowXY (StatusWindowPtr, j + 1, 1);
    temp := '';
    readln(temp);

    if temp <> '' then
        searchstring := temp;
    len := length (searchstring);

    if len = 0 then
    begin
        BeginFile;
        exit;
    end;

    temp := 'Searching... ';
    j := length (temp);
    GotoXY (1, maxlength + 2);
    ClrEol;
    Write(temp);

    StatusWindowPtr := MakeWindow (1, 2, 79, 22, 'Located strings:');
    GotoWindowXY (StatusWindowPtr, 1, 1);

    for i := 1 to highestline do
    begin
    (* look for matches on this line *)
        pointer := pos (searchstring, linebuffer [i]^);

   (* if there was a match then get ready to print it *)
        if (pointer > 0) then
        begin
            temp := linebuffer [i]^;
            position := pointer;
            WritelnWindow(StatusWindowPtr, copy(temp, 1, 79));

        (* print all of the matches on this line *)
            while pointer > 0 do
            begin
                temp := copy (temp, pointer + len + 1, 128);
                pointer := pos (searchstring, temp);
                position := position + pointer + len;
            end;

        (* go to next line and keep searching *)
        end;
    end;

    WritelnWindow(StatusWindowPtr, 'End of locate.  Press any key to exit...');
    c := readkey;
    ClrWindow(StatusWindowPtr);
    BeginFile;
end;
}
