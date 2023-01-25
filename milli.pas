(* milli.pas - This wannabe GNU nano-like text editor is based on Qed-Pascal
 * (http://bit.ly/qedpascal). Our main approach is to have all GNU nano
 * funcionalities. MSX version by Ricardo Jurczyk Pinheiro - 2020/2023.  *)

program milli;
var
	maxlinesforreal: integer;
	FnKeys: boolean;

{$i d:defs.inc}
{$i d:conio.inc}
{$i d:dos.inc}
(* {$i d:dos2err.inc} *)
{$i d:readvram.inc}
{$i d:fillvram.inc}
{$i d:fastwrit.inc}
{$i d:txtwin.inc}
{$i d:blink.inc}
{$i d:milli1.inc}
{$i d:milli2.inc}

{$u-}

procedure ReadFile (AskForName: boolean);
var
    maxlinesnotreached: boolean;
    VRAMAddress:        integer;

begin
    maxlinesnotreached  := false;

    if AskForName then
    begin
        GotoXY(1, maxlength + 1);
        ClrEol;
        Blink(1, maxlength + 1, maxwidth + 2);
        temp := concat('File Name to Read: ');
        FastWrite(temp);
        filename := readstring(40);
    end;

    InitStructures;
    
    assign(textfile, filename);
    {$i-}
    reset(textfile);
    {$i+}

    if (ioresult <> 0) then
        StatusLine('New file')
    else
    begin
        currentline := 1;

        while not eof(textfile) and (currentline <= maxlinesforreal) do
        begin
            FillChar(line, sizeof(line), chr(32));
            readln(textfile, line);
            FromRAMToVRAM(line, currentline);
            emptylines[currentline] := false;
            currentline := currentline + 1;
        end;
        emptylines[currentline] := false;
        
(*  Problema, gravidade baixa: Se o arquivo for grande demais pro
*   editor, ele tem que ler somente a parte que dá pra ler e parar.*)
        str(currentline - 1, tempnumber0);

        if maxlinesnotreached then
            temp := concat('File is too long. Read ', tempnumber0, ' lines. ')
        else
            temp := concat('Read ', tempnumber0, ' lines.');

        StatusLine (temp);
    end;

    close(textfile);

    highestline := currentline - 1; currentline := 1;   column := 1;
    screenline  := 1;               insertmode  := true;

    DisplayFileNameOnTop;

    DrawScreen(currentline, screenline, 1);
end;

procedure BackupFile;
begin
    StatusLine('Backup file in progress...');
    Path := concat (copy (filename, 1, pos(chr(46), filename)), 'BAK');

    assign(textfile,  filename);
    assign(backuptextfile,    Path);
    {$i-}
    reset   (textfile);
    rewrite (backuptextfile);
    {$i+}

    while not eof (textfile) do
    begin
        FillChar(line, sizeof(line), chr(32));
        readln(textfile, line);
        writeln(backuptextfile, line);
    end;
    
    close(backuptextfile);
    close(textfile);
    ClearStatusLine;
end;

procedure WriteOut (AskForName: boolean);
var
    tempfilename: TString;
    
begin
    if AskForName then
    begin
        GotoXY(1, maxlength + 1);
        ClrEol;
        Blink(1, maxlength + 1, maxwidth + 2);
        if ord(filename[1]) <> 32 then
            temp := concat('File Name to Write [', filename, ']: ')
        else
            temp := concat('File Name to Write: ');
    
        tempfilename := filename;

        FastWrite(temp);
        filename := readstring(40);
    end;
    
    assign(textfile, filename);
    {$i-}
    rewrite(textfile);
    {$i+}
    
    filename := tempfilename;
    
    temp := 'Saving file... Line     ';
    StatusLine(temp);
    
    for i := 1 to highestline do
    begin
        FillChar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, i);
        writeln(textfile, line);
        if (i mod tabnumber = 0) then
        begin
            str(i,  tempnumber0);
            GotoXY(47,  maxlength + 1);
            FastWrite(tempnumber0);
        end;
    end;

    close(textfile);
    savedfile := true;
    
    ClearBlink(1,   maxlength + 1, maxwidth + 2);
    str(highestline + 1,    tempnumber0);
    temp := concat('Wrote ',    tempnumber0, ' lines ');
    StatusLine(temp);
end;

procedure ExitToDOS;
begin
    GotoXY(1, maxlength + 1);
    ClrEol;
    Blink(1, maxlength + 1, maxwidth + 2);
    temp := 'Save file? (Y/N)';
    FastWrite(temp);
    
    c := chr(32);
    
    while ((c <> 'N') and (c <> 'Y')) do
        c := upcase(readkey);
    
    ClearStatusLine;
    
    if c = 'Y' then
        WriteOut(true);

    EraseWindow(EditWindowPtr);

(*  Restore function keys. *)
    ClearAllBlinks;
    ClrScr;
    
    InitFnKeys;
   
    if FnKeys then
		SetFnKeyStatus (true);
    Halt;
end;

procedure SearchAndReplace;
var
    position, linesearch, searchlength,
    replacementlength:                  integer;
    tempsearchstring:                   TString;
   
begin
    DisplayKeys (search);

    SetBlinkRate (5, 0);
    GotoXY(1, maxlength + 1);
    ClrEol;
    Blink(1, maxlength + 1, maxwidth + 2);

    tempsearchstring := searchstring;
    if searchstring[1] <> ' ' then
        temp := concat('Search (to replace) [',tempsearchstring, ']: ')
    else
        temp := 'Search (to replace): ';
        
    FastWrite (temp);
    searchstring := readstring(40);
    
    searchlength := length(searchstring);

    if searchlength = 0 then
        if length(tempsearchstring) = 0 then
        begin
            BeginFile;
            exit;
        end
        else
            searchstring := tempsearchstring;

    GotoXY(1, maxlength + 1);
    ClrEol;
    DisplayKeys (replace);

    temp := concat('Replace with: ');
    FastWrite (temp);
    replacestring := readstring(40);
    
    replacementlength := length (replacestring);

    c := chr(32);    

    for linesearch := 1 to highestline do
    begin
        FillChar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, linesearch);
    
        position := pos (searchstring, line);

        if (position > 0) then
        begin
            currentline := linesearch;
            if currentline >= 12 then
                screenline := 12
            else
                screenline := currentline;

            DrawScreen(currentline, screenline, 1);
            column := position;
            Blink(column + 1, screenline + 1, searchlength);

            GotoXY(1, maxlength + 1);

            if not (c in ['a', 'A']) then
            begin
                FastWrite('Replace this instance?');
                c := readkey;
            end;

            ClearBlink(column + 1, screenline + 1, searchlength);

            case ord (c) of
            CONTROLC:          begin
                                    ClrEol;
                                    StatusLine('Cancelled');
                                    DisplayKeys (main);
                                    BeginFile;
                                    exit;
                                end;
                                
(* a, A, y, Y *)
            65, 97, 89, 121:    begin
                                    line := concat(copy (line, 1, 
                                    position - 1), replacestring, 
                                    copy (line, position + 
                                    length (searchstring), maxcols));

                                    position := pos (searchstring, 
                                    copy (line, position + 
                                    replacementlength + 1, maxcols)) + 
                                    position + replacementlength;
                                end;
(* n, N *)                                
            78, 110:            position := pos (searchstring,
                                copy (line, position + 
                                length(searchstring) + 1, maxcols)) +
                                position + length(searchstring);
            end;
            FromRAMToVRAM(line, currentline);
            GotoWindowXY(EditWindowPtr, 1, screenline);
            ClrEolWindow(EditWindowPtr);
            temp := copy(line, 1, maxcols + 1);
            WriteWindow(EditWindowPtr, temp);
        end;
    end;
    ClearStatusLine;
    DisplayKeys(main);
end;

procedure AlignText;
var
    lengthline, k, blankspaces, l:  byte;
    justifyvector:                  array [1..maxwidth] of byte;

begin
    FillChar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, currentline);
        
    lengthline := length(line);
    
(*  Remove blank spaces in the beginning and in the end of the line. *)
    i := DifferentPos   (chr(32), line) - 1; 
    j := RDifferentPos  (chr(32), line) + 1;

    if i > 1 then
        delete(line, 1, i)
    else
        i := 0;
        
    if j < maxwidth then
        delete(line, j, lengthline - j)
    else
        j := maxwidth;

    lengthline := length(line);

    DisplayKeys(align);
    c := upcase(readkey);

    case c of
        #76: begin
(* left - L *)
                blankspaces := (maxwidth - lengthline) + 1;
                for i := 1 to blankspaces do
                    insert(#32, line, lengthline + 1);
                    temp := 'Text aligned to the left.';
            end;
                    
        #82: begin
(* right - R *)        
                blankspaces := (maxwidth - lengthline);
                for i := 1 to blankspaces do
                    insert(#32, line, 1);
                    temp := 'Text aligned to the right.';
                end;
                    
        #67: begin
(* center - C *)
                blankspaces := (maxwidth - lengthline) div 2;
                for i := 1 to blankspaces do
                    insert(#32, line, 1);
                temp := 'Text centered.';
            end;
                    
        #74: begin
(* justify - J *)
                j := 1;
                        
(*  Find all blank spaces in the phrase and save their positions. *)
                for i := 1 to (RDifferentPos(chr(32), line)) do
                    if ord(line[i]) = 32 then
                    begin
                        justifyvector[j] := i;
                        j := j + 1;
                    end;

(*  Insert blank spaces in the previous saved vector's positions. *)
                j := j - 1;
                k := (maxwidth - lengthline) div j;
                
                for i := j downto 1 do
                begin
                    for l := 1 to k do
                        insert(#32, line, justifyvector[i]);
                    justifyvector[i] := justifyvector[i] + k;
                end;

                k := (maxwidth - lengthline) mod j;
                
                for l := 1 to k do
                    insert(#32, line, justifyvector[1]);
                justifyvector[1] := justifyvector[1] + k;
                temp := 'Text justified.';
            end;
    end;

    DisplayKeys(main);
    if ord(c) in [67, 74, 76, 82] then
        StatusLine(temp);

    FromRAMToVRAM(line, currentline);
    DrawScreen(currentline, screenline, 1);

(*  Problema, gravidade baixa: O ideal é que ele só redesenhe a linha, e não a
*   página toda. Mas no momento, não está funcionando. A ser resolvido depois.*)
{
    quick_display(1, currentline, line);

    j := 1;
    if upcase(c) = 'J' then

        for i := (currentline + 1) to (maxlength - 1) do
        begin
            FillChar(line, sizeof(line), chr(32));
            FromVRAMToRAM(line, i);
            quick_display(1, screenline + j, line);
            j := j + 1;
        end;
}
end;

procedure BlockHide(HideOrNot: boolean);
begin
    for i := maxlength downto 1 do
        if BlockMarked then
            if  ((currentline - screenline + i) >= BlockStart) and
                ((currentline - screenline + i) <= BlockEnd) then
                    if HideOrNot then
                        ClearBlink(2, i, maxwidth)
                    else
                        Blink(2, i, maxwidth);
    Blink(2, 1, maxwidth);
end;

procedure BlockCover;
begin
    if BlockMarked then
    begin
        str(BlockStart, tempnumber0);
        str(BlockEnd,   tempnumber1);
        BlockHide(false);
        temp := concat( 'Block from line ', tempnumber0, 
                        ' to line ', tempnumber1);
        StatusLine(temp);
        c := readkey;
        BlockHide(true);
        ClearStatusLine;
    end;
end;

procedure BlockMark (TypeOfMarks: BlockMarkings; var BlockLine: integer);
begin
    SetBlinkRate (5, 0);
    GotoXY(1, maxlength + 1);
    ClrEol;
    Blink(1, maxlength + 1, maxwidth + 2);

    BlockLine := currentline;

    str(BlockLine, tempnumber0);

    if TypeOfMarks = BlockBegin then
    begin
        temp := 'First block line: ';
        BlockMarked := false;
    end
    else
        begin
            temp := 'Last block line: ';
            BlockMarked := true;
        end;

    temp := concat (temp, tempnumber0);
    BlockLine := BlockLine + 1;
    BlockHide(false);

    StatusLine (temp);
    c := readkey;
    BlockHide(true);
    ClearStatusLine;
end;

procedure BlockOperations (KindOf: byte; StartBlock, EndBlock, DestBlock: integer);
(*
*   0   - Copia bloco. 
*   1   - Move bloco.
*   2   - Apaga bloco. 
*)

begin
    str (StartBlock , tempnumber0);
    str (EndBlock   , tempnumber1);
    str (DestBlock  , tempnumber2);

    case KindOf of
        0: searchstring := 'copied';
        1: searchstring := 'moved';
    end;

    if KindOf = 2 then
        temp := concat( 'Block from line ', tempnumber0, ' to line ', tempnumber1, 
                        ' will be deleted.')
    else
        temp := concat( 'Block from line ', tempnumber0, ' to line ', tempnumber1, 
                        ' will be ', searchstring, ' to line ', tempnumber2, '.');
    
    StatusLine(temp);
    c := readkey;

    if KindOf = 2 then
        DeleteLinesFromText(StartBlock, highestline, (EndBlock - StartBlock))
    else
    begin
        InsertLinesIntoText (DestBlock - 1, highestline, (EndBlock - StartBlock) + 1);
        CopyBlock(StartBlock, EndBlock, DestBlock);
    end;
    
    if KindOf = 1 then
        DeleteLinesFromText(StartBlock, highestline, (EndBlock - StartBlock) + 1);

    if KindOf < 2 then
    begin
        StartBlock  := DestBlock;
        EndBlock    := DestBlock + (StartBlock - EndBlock);
    end
    else
    begin
        StartBlock  := -1;
        EndBlock    := -1;
    end;

    BlockMarked := false;
    DrawScreen(currentline, screenline, 1);
    ClearStatusLine;
end;

procedure handlefunc(keynum: byte);
var
    key         : byte;
    iscommand   : boolean;
    
begin
    case keynum of
        BS:         backspace;
        TAB:        tabulate;
        ENTER:      Return;
        UpArrow:    CursorUp;
        LeftArrow:  CursorLeft;
        RightArrow: CursorRight;
        DownArrow:  CursorDown;
        INSERT:     ins;
        DELETE:     del;
        HOME:       BeginFile;
        CLS:        EndFile;
        CONTROLA:   BeginLine;
        CONTROLB:   PreviousWord;
        CONTROLC:   Location(Position); 
        CONTROLD:   del;
        CONTROLE:   EndLine;    
        CONTROLF:   NextWord;
        CONTROLG:   Help;
        CONTROLJ:   AlignText;
        CONTROLN:   SearchAndReplace;
        CONTROLO:   WriteOut(true);
        CONTROLP:   ReadFile(true);
        CONTROLS:   WriteOut(false);
        CONTROLQ:   WhereIs (backwardsearch, false);
        CONTROLT:   GoToLine;
        CONTROLV:   PageDown;
        CONTROLW:   WhereIs (forwardsearch,  false);
        CONTROLY:   PageUp;
        CONTROLZ:   ExitToDOS;
        SELECT:     begin
                        key := ord(readkey);
                        case key of
                           DELETE:  deleteline;
                           TAB:     backtab;
(* B *)                    66, 98:  BlockMark       (BlockBegin, BlockStart);
(* C *)                    67, 99:  BlockOperations (0, BlockStart, BlockEnd, currentline);
(* D *)                    68, 100: Location        (HowMany);
(* E *)                    69, 101: BlockMark       (BlockFinish, BlockEnd);           
(* F *)                    70, 102: BlockOperations (2, BlockStart, BlockEnd, currentline);
(* H *)                    72, 104: BlockCover;
(* Q *)                    81, 113: WhereIs         (backwardsearch, true);
(* V *)                    86, 118: BlockOperations (1, BlockStart, BlockEnd, currentline);
(* W *)                    87, 119: WhereIs         (forwardsearch , true);
(* Y *)                    89, 121: RemoveLine;
                           else    delay(10);
                        end;
                    end;
        else    delay(10);
    end;
end;

(* main *)

begin
    newline     	:= 1;
    newcolumn   	:= 1;
    tabnumber   	:= 8;
    maxlinesforreal	:= maxlines;
    AllChars    	:= [0..255];
    NoPrint     	:= [0..31, 127, 255];
    Print       	:= AllChars - NoPrint;

(*  If it's a MSX 1, exits. If it's a Turbo-R, turns on R800 mode.*)
    case msx_version of
        1:  begin
                writeln('MSX 1 detected. This program needs at least a MSX 2.');
                halt;
            end;
        2:  writeln('MSX 2 detected.');
        3:  writeln('MSX 2+ detected.');
        4:  begin
                writeln('MSX Turbo-R detected.');
                TRR800mode;
            end;
    end;

    GetMSXDOSVersion (MSXDOSversion);

(*  Init text editor routines and variables. *)    
    InitTextEditor;
        
    if paramcount > 0 then
    begin

(*  Read parameters, and upcase them. *)
        for i := 1 to paramcount do
        begin
            temp := paramstr(i);
            for j := 1 to length(temp) do
                temp[j] := upcase(temp[j]);

            c := temp[2];
            if temp[1] = '/' then
            begin
                delete(temp, 1, 2);

(*  Parameters. *)
                case c of
                    'V': CommandLine(1);
                    'H': CommandLine(2);
                    'L': val(copy(temp, 1, length(temp)), newline,   	rtcode);
                    'C': val(copy(temp, 1, length(temp)), newcolumn, 	rtcode);
                    'T': val(copy(temp, 1, length(temp)), tabnumber, 	rtcode);
                    'Z': val(copy(temp, 1, length(temp)), maxlinesforreal, rtcode);
{
                    'E': ConvertTabsToSpaces;
}
                end;
            end;
        end;
        
        InitMainScreen;

(* The first parameter should be the file. *)
        filename    := paramstr(1);
        
(* Cheats the APPEND environment variable. *)    
        if (MSXDOSversion.nKernelMajor >= 2) then
            CheatAPPEND(filename);

        if c = 'B' then
            BackupFile;
        
(* Reads file from the disk. *)
        ReadFile(false);

        if newcolumn <> column then
            column  := newcolumn;
    
        if newline <> currentline then
        begin
            currentline := newline;
            if newline >= (maxlength - 1) then
            begin
                screenline  := maxlength - 1;
                DrawScreen(currentline, screenline, 1);
            end
            else
                screenline := newline;
        end;
    end
    else
    begin
        InitMainScreen;
        InitStructures;
        currentline := 1;   highestline := 1;
        StatusLine('New file');
    end;

    for i := 1 to maxwidth do
        tabset[i] := (i mod tabnumber) = 1;

    ins;

(* main loop - get a key and process it *)
    repeat
        GotoWindowXY(EditWindowPtr, column, screenline);
        CursorOn;
        GetKey (key, iscommand);
        CursorOff;
        ClearStatusLine;
        if iscommand then
            handlefunc(key)
        else
            character(chr(key));
    until true = false;

    if (MSXDOSversion.nKernelMajor >= 2) then
        CheatAPPEND(chr(32));

    ClearAllBlinks;
    if msx_version = 4 then
        TRZ80mode;
end.
