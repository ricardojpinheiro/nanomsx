(* milli
 * This wannabe GNU nano-like text editor is based on Qed-Pascal
 * (http://bit.ly/qedpascal). Our main approach is to have all GNU nano
 * funcionalities. MSX version by Ricardo Jurczyk Pinheiro - 2020/2021.
 *)

program milli;

{$i d:conio.inc}
{$i d:dos.inc}
{$i d:dos2err.inc}
{$i d:readvram.inc}
{$i d:fillvram.inc}
{$i d:fastwrit.inc}
{$i d:txtwin.inc}
{$i d:blink.inc}
{$i d:milli.inc}

var
    currentline, highestline:       integer; 
    key, screenline, column:        byte;
    line, emptyline:                linestring;
{
    linebuffer:                     array [1.. maxlines] of lineptr;
}
    tabset:                         array [1..maxwidth] of boolean;
    textfile:                       text;
    searchstring, replacestring:    str80;
    filename:                       linestring;
    savedfile, insertmode,
    iscommand:                      boolean;
    tempnumber0:                    string[6];
    i, j, tabnumber, newline,
    newcolumn, returncode:          integer;
    c:                              char;

    Registers:                      TRegs;
    ScreenStatus:                   TScreenStatus;
   
    EditWindowPtr:                  Pointer;
    MSXDOSversion:                  TMSXDOSVersion;

Procedure CursorOn;
Begin
    BlinkChar(column + 1, screenline + 1);
End;

Procedure CursorOff;
Begin
    ClearBlinkChar(column + 1, screenline + 1);
End;

procedure GetKey (var key: byte; var iscommand: boolean);
var
    inkey: char;
(* Return true if a key waiting, and the key. *)
    
begin
    iscommand   := false;
    inkey       := readkey;
    key         := ord(inkey);
    case key of
        1..31, 127: iscommand := true;
    end;
end;

procedure quick_display(x, y: integer; s: linestring);
begin
    GotoWindowXY(EditWindowPtr, x, y);
    WriteWindow (EditWindowPtr, s);
    ClrEolWindow(EditWindowPtr);
end;

procedure StatusLine (message: str80);
var
    lengthmessage, position: byte;
begin
    ClearStatusLine;

    message         := concat('[ ', message, ' ]');
    lengthmessage   := length(message);
    position        := (maxwidth - lengthmessage) div 2;

    GotoXY(position, maxlength + 1);
    FastWrite(message);
    Blink(position, maxlength + 1, lengthmessage);
end;

procedure DisplayKeys (whichkey: KeystrokeLines);
var
    BlinkSequence: array [1..6] of byte;
    Line1, Line2: str80;
    BlinkLength: byte;
    
begin
    for i := 2 to 3 do
        ClearBlink(1, maxlength + i, maxwidth);

    FillChar(BlinkSequence, sizeof(BlinkSequence), 0);

    case whichkey of
        main:       begin
                        BlinkLength := 2;
                        BlinkSequence[1] := 1;  BlinkSequence[2] := 9;
                        BlinkSequence[3] := 22; BlinkSequence[4] := 34;
                        BlinkSequence[5] := 43; BlinkSequence[6] := 55;
                        Line1 := '^G Help ^O Write Out ^W Where Is ^K CUT   ^C Location ~D Line count';
                        Line2 := '^Z Exit ^P Read File ^N Replace  ^U PASTE ^J Align    ^T Go To Line';
                    end;
        search:     begin
                        BlinkLength := 2;
                        BlinkSequence[1] := 1;  BlinkSequence[2] := 11;
                        BlinkSequence[3] := 28; BlinkSequence[4] := 41;
                        Line1 := '^G Help   ~W Next forward  ^Q Backwards ^T Go To Line              ';
                        Line2 := '^C Cancel ~Q Bext backward ^N Replace   ^X Exit                    ';
                    end;
        replace:    begin
                        BlinkLength := 2;
                        BlinkSequence[1] := 1;  BlinkSequence[2] := 15;
                        Line1 := ' Y Yes         A All                                               ';
                        Line2 := ' N No         ^C Cancel                                            ';
                    end;
        align:      begin
                        BlinkLength := 2;
                        BlinkSequence[1] := 1;  BlinkSequence[2] := 15;
                        Line1 := ' L Left        C Center                                            ';
                        Line2 := ' R Right       J Justify                                           ';
                    end;
    end;
    WriteVRAM(0, (maxwidth + 2) * (maxlength + 1), Addr(Line1[1]), length(Line1));
    WriteVRAM(0, (maxwidth + 2) * (maxlength + 2), Addr(Line2[1]), length(Line2));

    for i := 1 to sizeof(BlinkSequence) do
    begin
        Blink(BlinkSequence[i], maxlength + 2, BlinkLength);
        Blink(BlinkSequence[i], maxlength + 3, BlinkLength);
    end;
end;

procedure DrawScreen (j: byte);
var
    line:   linestring;
begin
    ClrWindow(EditWindowPtr);

    for i := 1 to (maxlength - j) do
    begin
        FillChar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, currentline - screenline + i);
        quick_display(1, i, line);
    end;
end;

procedure DisplayFileNameOnTop;
begin
    i := (maxwidth - length(filename)) div 2;
    FillChar(temp, sizeof(temp), chr(32));
    GotoXY(i - 3, 1);
    FastWriteln(temp);

    GotoXY(i, 1);
    FastWriteln(filename);
end;

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
        read(filename);
    end;
    
    assign(textfile, filename);
    {$i-}
    reset(textfile);
    {$i+}

    if (ioresult <> 0) then
        StatusLine('New file')
    else
    begin
        currentline := 1;

        while not eof(textfile) do
        begin
            FillChar(line, sizeof(line), chr(32));
            readln(textfile, line);
            FromRAMToVRAM(line, currentline);
            currentline := currentline + 1;
        end;
        
(*  Problema, gravidade alta: Se o arquivo for grande demais pro
*   editor, ele tem que ler somente a parte que dá pra ler e parar.*)
        
        str(currentline - 1, tempnumber0);

        if maxlinesnotreached then
            temp := concat('File is too long. Read ', tempnumber0, ' lines. ')
        else
            temp := concat('Read ', tempnumber0, ' lines.');

        StatusLine (temp);
    end;

    close(textfile);

    highestline := currentline; currentline := 1; column := 1;
    screenline  := 1;           insertmode  := true;

    DisplayFileNameOnTop;

    if AskForName then
        DrawScreen(1);
end;

procedure InitTextEditor;
var
    counter:    real;

begin
    GetScreenStatus(ScreenStatus);
    
    if ScreenStatus.bFnKeyOn then
        SetFnKeyStatus (false);
    
    Width(80);
    ClearAllBlinks;
    SetBlinkColors(ScreenStatus.nBkColor, ScreenStatus.nFgColor);
    SetBlinkRate(5, 0);

(*  Some variables. *)   
    currentline := 1; screenline := 1;         highestline := 1;
    column      := 1; counter    := startvram; insertmode  := false;
    savedfile   := false;   
    FillChar(filename,      sizeof(filename),       chr(32));
    FillChar(temp,          sizeof(temp),           chr(32));
    FillChar(emptyline,     sizeof(emptyline),      chr(32));
    FillChar(filename,      sizeof(filename),       chr(32));
    FillChar(searchstring,  sizeof(searchstring),   chr(32));
    FillChar(replacestring, sizeof(replacestring),  chr(32));

(*  Initialize structure. *)

    GotoXY(1, 1); FastWriteln('Initializing structures...');
    for i := 1 to maxlines do
    begin
        InitVRAM(i, counter); 
        counter := counter + maxcols;
    end;

(*  Erase VRAM banks, from startvram till the end. *)
    GotoXY(1, 2); FastWriteln('Wiping memory, please be patient...');
    fillvram(0, startvram   , 0, $FFFF - startvram);
    fillvram(1, 0           , 0, $FFFF);

(*  Set new function keys. *)
    SetFnKey(1, chr(7));  SetFnKey(2, chr(26)); SetFnKey(3, chr(15));
    SetFnKey(4, chr(10)); SetFnKey(5, chr(3));  SetFnKey(6, chr(23));
    SetFnKey(7, chr(20)); SetFnKey(8, chr(17));
end;

procedure InitMainScreen;
begin
    EditWindowPtr := MakeWindow(0,  1,  maxwidth  + 2, 
                                        maxlength + 1, chr(32));

    GotoXY(3, 1);
    FastWrite('milli 0.1');

    Blink(2, 1, maxwidth);
    DrawScreen(1);

    DisplayFileNameOnTop;

    DisplayKeys (main);
    ClearStatusLine;
end;

procedure character(inkey: char);
begin
    CursorOff;

    gotoxy (2, 1); writeln ('screenl: ', screenline, ' currentl: ', currentline, ' highestl: ', highestline, ' Char');

    FillChar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, currentline);

    if column > maxwidth then
        delay(10)
    else
    begin
        GotoWindowXY(EditWindowPtr, column, screenline);
        WriteWindow(EditWindowPtr, inkey);
{
        if line = emptyline then
        begin
            InsertLinesIntoText (currentline - 1, highestline, 1);
            FillChar(line, sizeof(line), chr(32));
        end;
}
        while length(line) <= column do
            line := line + ' ';

        insert(inkey, line, column);
        column := column + 1;

        if not insertmode then
            delete(line, column, 1);

(* redraw current line if in insert mode *)

        if insertmode then
            quick_display(1, screenline, line);

(* A little delay when you are close to the end of a line *)

        if column >= 78 then
            delay(10);
    end;
    FromRAMToVRAM(line, currentline);    
    CursorOn;
end;

procedure BeginFile;
begin
    currentline := 1;
    screenline  := 1;
    column      := 1;
    DrawScreen(1);
end;

procedure EndFile;
begin
(*  Problema, gravidade baixa: Se eu coloco um valor maior do que 1 em
*   screenline, ele coloca na tela anterior. Bem, a ser resolvido
*   depois. *)
    currentline := highestline - maxlength + 1;
    screenline  := 1;
    column      := 1;
    DrawScreen(1);
end;

procedure BeginLine;
begin
    currentline := WhereYWindow(EditWindowPtr);
    screenline  := currentline;
    column      := 1;
(*
    DrawScreen(1);
*)
end;

procedure EndLine;
begin
    FillChar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, currentline);
    column      := length (line) + 1;
    if column > maxwidth then
        column := maxwidth;
end;

procedure CursorUp;
begin
    if currentline = 1 then
        exit;

    currentline := currentline - 1;
    if screenline = 1 then
    begin
        GotoWindowXY(EditWindowPtr, 1, 1);
        ScrollWindowDown(EditWindowPtr);

        FillChar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, currentline);
        quick_display(1, 1, line);
    end
    else
        screenline := screenline - 1;

    gotoxy (2, 1); writeln ('screenl: ', screenline, ' currentl: ', currentline, ' highestl: ', highestline, ' CursU    ');

end;

procedure CursorDown;
begin
    if currentline >= highestline then
        exit;
    
    currentline :=  currentline + 1;
    screenline  :=  screenline  + 1;

    if screenline > (maxlength - 1) then
    begin
        GotoWindowXY(EditWindowPtr, 1, 2);
        ScrollWindowUp(EditWindowPtr);
        screenline := maxlength - 1;
        FillChar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, currentline);
        quick_display(1, screenline, line);
    end;

    gotoxy (2, 1); writeln ('screenl: ', screenline, ' currentl: ', currentline, ' highestl: ', highestline, ' CursD   ');

end;

procedure InsertLine;
begin
    GotoWindowXY(EditWindowPtr, column, screenline + 1);
    InsLineWindow(EditWindowPtr);
    InsertLinesIntoText (currentline - 1, highestline, 1);
end;

procedure Return;
begin
    CursorDown;
    column := 1;

    if insertmode then
        InsertLine;

    gotoxy (2, 1); writeln ('screenl: ', screenline, ' currentl: ', currentline, ' highestl: ', highestline, ' Return   ');

end;

procedure deleteline;
begin
    DelLineWindow(EditWindowPtr);

    FillChar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, currentline + ((maxlength + 1) - screenline));

    if highestline > currentline + (maxlength - screenline) then
        quick_display(1, maxlength, line);

    DeleteLinesFromText(currentline, highestline, 1);

    FillChar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, currentline);

    if line <> emptyline then
        line := emptyline;
{

    for i := currentline to highestline + 1 do
        linebuffer[i]               := linebuffer [i + 1];

    linebuffer [highestline + 2]    := emptyline;
    highestline                     := highestline - 1;

    if currentline > highestline then
        highestline                 := currentline;
}
end;

procedure CursorLeft;
begin
    column := column - 1;

    if column < 1 then
    begin
        CursorUp;
        EndLine;
    end;
end;

procedure CursorRight;
begin
    column := column + 1;

    if column > maxwidth + 1 then
    begin
        CursorDown;
        column := 1;
    end;
end;

procedure ins;
begin
    if insertmode then
    begin
        temp := 'Insert mode off';
        insertmode := false;
    end
    else
    begin
        temp := 'Insert mode on';
        insertmode := true;
    end;
    StatusLine(temp);
end;

procedure del;
begin
    FillChar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, currentline);
    FillChar(temp, sizeof(temp), chr(32));
    FromVRAMToRAM(temp, currentline + 1);
    
    if (column > length(line)) then
    begin
        if (length(line) + length(temp)) < maxwidth then
        begin
            line    := line + temp;
            quick_display(1, screenline, line);
            CursorDown;
            deleteline;
            CursorUp;
        end;
        exit;
    end;

    if line = emptyline then
        line := '';

    while length(line) < column do
        line := line + ' ';

    delete(line, column, 1);

    GotoWindowXY(EditWindowPtr, 1, screenline);
    ClrEolWindow(EditWindowPtr);
    quick_display(1, screenline, line);
    FromRAMToVRAM(line, currentline);
end;

procedure backspace;
begin
    if column > 1 then
        column  := column - 1
    else
    begin
        CursorUp;
        EndLine;
    end;
    del;
end;

procedure WriteOut (AskForName: boolean);
var
    tempfilename: TFileName;
    
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
        read(filename);
    end;
    
    assign(textfile, filename);
    {$i-}
    rewrite(textfile);
    {$i+}
    
    filename := tempfilename;
    
    for i := 1 to highestline do
    begin
        FillChar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, i);
        writeln(textfile, line);
    end;

    close(textfile);
    savedfile := true;
    
    ClearBlink(1, maxlength + 1, maxwidth + 2);
    str(highestline + 1, tempnumber0);
    temp := concat('Wrote ', tempnumber0, ' lines ');
    StatusLine(temp);
end;

procedure ExitToDOS;
begin
    GotoXY(1, maxlength + 1);
    ClrEol;
    Blink(1, maxlength + 1, maxwidth + 2);
    temp := 'Save file? (Y/N)';
    FastWrite(temp);
    c := readkey;
    
    ClearStatusLine;
    
    if upcase(c) = 'Y' then
        WriteOut(true);

    EraseWindow(EditWindowPtr);

(*  Restore function keys. *)
    ClearAllBlinks;
    ClrScr;
    
    InitFnKeys;
   
    SetFnKeyStatus (true);
    Halt;
end;

procedure PageUp;
begin
    currentline     := currentline - (maxlength - 1);
    if currentline <= screenline then
        BeginFile
    else
        DrawScreen(1);
end;

procedure PageDown;
begin
    currentline     := currentline + (maxlength - 1);
    if currentline >= highestline then
        EndFile
    else
        if (highestline - currentline) < maxlength then
            DrawScreen(2)
        else
            DrawScreen(1);
end;

procedure PreviousWord;
begin
    FillChar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, currentline);

(* if i am in a word then skip to the space *)

    while (not ((line[column] = ' ') or
               (column >= length(line) ))) and
         ((currentline <> 1) or
          (column <> 1)) do
      CursorLeft;

(* find end of previous word *)

   while ((line[column] = ' ') or
          (column >= length(line) )) and
         ((currentline <> 1) or
          (column <> 1)) do
      CursorLeft;

(* find start of previous word *)

   while (not ((line[column] = ' ') or
               (column >= length(line) ))) and
         ((currentline <> 1) or
          (column <> 1)) do
      CursorLeft;

   CursorRight;
end;

procedure NextWord;
begin
    FillChar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, currentline);

(* if i am in a word, then move to the whitespace *)

   while (not ((line[column] = ' ') or
               (column >= length(line)))) and
         (currentline < highestline) do
      CursorRight;

(* skip over the space to the other word *)

   while ((line[column] = ' ') or
          (column >= length(line))) and
         (currentline < highestline) do
      CursorRight;
end;

procedure tabulate;
begin
   CursorOff;
   if column < maxwidth + 1 then
   begin
       repeat
           column := column + 1;
       until (tabset [column]= true) or (column = maxwidth + 1);
   end;
   CursorOn;
end;

procedure backtab;
begin
    if column > 1 then
    begin
        repeat
            column := column - 1;
        until (tabset [column]= true) or (column = 1);
    end;
end;

procedure RemoveLine;
begin
    CursorOff;
    column := 1;
    GotoWindowXY(EditWindowPtr, column, WhereYWindow(EditWindowPtr));
    ClrEolWindow(EditWindowPtr);

    FillChar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, currentline);
    
    if (line <> emptyline) then
        line := emptyline;

    line := emptyline;
    FromRAMToVRAM(line, currentline);
    CursorOn;
end;

procedure WhereIs (direction: Directions; nextoccurrence: boolean);
var
    pointer, len        : integer;
    tempsearchstring    : str80;
    stopsearch          : integer;
 
begin
    DisplayKeys (search);

    if NOT nextoccurrence OR (searchstring = '') then
    begin
        GotoXY(1, maxlength + 1);
        ClrEol;
        Blink(1, maxlength + 1, maxwidth + 2);
        if searchstring[1] <> ' ' then
        begin
            tempsearchstring := searchstring;
            temp := concat('Search [', tempsearchstring, ']: ');
        end
        else
            temp := 'Search: ';
        
        FastWrite (temp);
        read(searchstring);
    end;

    if length (searchstring) = 0 then
        if length(tempsearchstring) = 0 then
        begin
            BeginFile;
            exit;
        end
        else
            searchstring := tempsearchstring;
        
    if direction = forwardsearch then
    begin
        stopsearch := highestline;
        i := currentline + 1;
    end
    else
    begin
        stopsearch := 1;
        i := currentline - 1;
    end;
    
    while i <> stopsearch do
    begin
        FillChar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, i);        
    
    (* look for matches on this line *)
        pointer := pos (searchstring, line);

    (* if there was a match then get ready to print it *)
        if (pointer > 0) then
        begin
            currentline := i;
            if currentline >= maxlength then
            begin
                screenline := maxlength - 1;
                DrawScreen(1);
            end
            else
                screenline := currentline;
            column := pointer;

    (* Redraw the StatusLine, bottom of the window and display keys *)
            ClearStatusLine;
            DisplayKeys (main);
            exit;
        end;
        
        if direction = forwardsearch then
            i := i + 1
        else
            i := i - 1;
        
    end;

    ClearBlink(1, maxlength + 1, maxwidth + 2);
    temp := concat(searchstring, ' not found');
    StatusLine(temp);
    DisplayKeys (main);
end;

procedure SearchAndReplace;
var
    position, linesearch:               integer;
    searchlength, replacementlength,
    searchperline:                      byte;
    choice:                             char;
    tempsearchstring:                   str80;
   
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
    read(searchstring);
    
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
    read(replacestring);    
    
    replacementlength := length (replacestring);

    choice := ' ';    
    searchperline := 1;

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

            DrawScreen(1);
            column := position;
            Blink(column + 1, screenline + 1, searchlength);

            GotoXY(1, maxlength + 1);

            if not (choice in ['a', 'A']) then
            begin
                FastWrite('Replace this instance?');
                choice := readkey;
            end;

            ClearBlink(column + 1, screenline + 1, searchlength);

            case ord (choice) of
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
            temp := copy(line, 1, maxlength + 1);
            WriteWindow(EditWindowPtr, temp);
        end;
    end;
    DisplayKeys(main);
    ClearStatusLine;
end;

procedure AlignText;
var
    lengthline, k, 
    blankspaces, l: byte;
    justifyvector:  array [1..maxwidth] of byte;

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
    c := readkey;

    case ord(c) of
        76, 108:    begin
(* left - L *)
                        blankspaces := (maxwidth - lengthline) + 1;
                        for i := 1 to blankspaces do
                            insert(#32, line, lengthline + 1);
                        temp := 'Text aligned to the left.';
                    end;
        82, 114:    begin
(* right - R *)        
                        blankspaces := (maxwidth - lengthline);
                        for i := 1 to blankspaces do
                            insert(#32, line, 1);
                        temp := 'Text aligned to the right.';
                    end;
        67, 99:     begin
(* center - C *)
                        blankspaces := (maxwidth - lengthline) div 2;
                        for i := 1 to blankspaces do
                            insert(#32, line, 1);
                        temp := 'Text centered.';
                    end;
        74, 106:    begin
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
    StatusLine(temp);

    FromRAMToVRAM(line, currentline);
    DrawScreen(1);

(*  Problema, gravidade baixa: O ideal é que ele só redesenhe a linha,
*   e não a página toda. Mas no momento, não está funcionando.
*   A ser resolvido depois. *)
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

procedure Location (Types: LocationOptions);
type
    ASCII = set of 0..255;
var
    tempnumber1, tempnumber2: string[6];
    totalwords              : integer;
    abovechar, totalchar, 
    percentchar             : real;
    temp2                   : linestring;
    NoPrint, Print, AllChars: ASCII;

begin
    FillChar(temp, sizeof(temp), chr(32));

(*  Line count - Calculating percentage. *)    

    str(currentline, tempnumber0);
    str(highestline, tempnumber1);
    j := ((currentline * 100) div highestline);
    str(j, tempnumber2);
    
    if Types = Position then
        temp := concat('line ', tempnumber0,'/', tempnumber1, ' (', tempnumber2,'%),')
    else
        temp := concat(' Lines: ', tempnumber1);

    if Types = Position then
    begin
(*  Column count. *)  
        FillChar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, currentline);

        j := length(line) + 1;

(*  Calculating percentage. *)        

        str(column, tempnumber0);
        str(j, tempnumber1);
   
        i := ((column * 100) div j);
        str(i , tempnumber2);
    
        temp := concat(temp, ' col ',tempnumber0,'/',tempnumber1, ' (', tempnumber2,'%)');
    end;

(*  Char count. *)

    abovechar := 0;
    
    for i := 1 to currentline - 1 do
        abovechar := abovechar + length(line);

    totalchar := abovechar;
    abovechar := abovechar + column;
    
    for i := currentline to highestline do
        totalchar := totalchar + length(line);
    
(*  Calculating percentage. *)

    percentchar := round(int(((abovechar * 100) / totalchar)));

    str(abovechar:6:0   ,   tempnumber0);
    str(totalchar:6:0   ,   tempnumber1);
    str(percentchar:6:0 ,   tempnumber2);
    
    delete(tempnumber0  , 1, RPos(' ', tempnumber0) - 1);
    delete(tempnumber1  , 1, RPos(' ', tempnumber1) - 1);
    delete(tempnumber2  , 1, RPos(' ', tempnumber2) - 1);
    
    if Types = Position then
        temp := concat(temp, ' char ', tempnumber0,'/', tempnumber1, ' (', tempnumber2,'%)')
    else
        temp := concat(temp, ' Chars: ', tempnumber1);

(*  Word count *)

    if Types = HowMany then
    begin
        totalwords  := 0;
        AllChars    := [0..255];
        NoPrint     := [0..31, 127, 255];
        Print       := AllChars - NoPrint;

        FillChar(temp2, sizeof(temp2), chr(32));

        for i := 1 to highestline do
        begin
            FillChar(temp2, sizeof(temp2), chr(32));
            FromVRAMToRAM(temp2, i);
            for j   := 1 to length(temp2) do
                if (temp2[j] = chr(32)) and (ord(temp2[j + 1]) in Print) and (j > 1) then
                    TotalWords := TotalWords + 1;
        end;
        
        TotalWords := TotalWords + 1;
        
        str(TotalWords      , tempnumber0);
        insert(tempnumber0  , temp  , 1);
        insert('Words: '    , temp  , 1);
    end;

    StatusLine(temp);
end;

procedure GoToLine;
var
    destline, destcolumn: integer;

begin
    destline    := 1;
    destcolumn  := 1;

    GotoXY(1, maxlength + 1);
    ClrEol;
    
    Blink(1, maxlength + 1, maxwidth + 2);
    
    temp := 'Enter line and column number: ';
    FastWrite(temp);
    
    GotoXY(length(temp) + 1, maxlength + 1);
    readln(destline, destcolumn);
 
    if destline = 1 then
        destline := destline + 1;
 
    if destline >= highestline then
        destline := highestline;
    
    FillChar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, destline);    
    i := length(line);
    
    if destcolumn > i then
        destcolumn := i;
 
    currentline     := destline - 1;
    screenline      := 1;
    column          := destcolumn;
    
    DrawScreen(1);
  
(* Redraw the StatusLine, bottom of the window and display keys *)

    ClearStatusLine;
end;

procedure Help;
begin
    ClrWindow(EditWindowPtr);
    WritelnWindow(EditWindowPtr, 'Commands:');
    WritelnWindow(EditWindowPtr, 'Ctrl-S - Save current file         | Ctrl-O - Save as file (F3)');
    WritelnWindow(EditWindowPtr, 'Ctrl-P - Read new file             | Ctrl+Z - Close and exit from nano (F2)');
    WritelnWindow(EditWindowPtr, 'Ctrl+G - Display help text (F1)    | Ctrl+C - Report cursor position (F5)');
    WritelnWindow(EditWindowPtr, 'Ctrl+A - To start of line          | Ctrl+Y - One page up');
    WritelnWindow(EditWindowPtr, 'Ctrl+E - To end of line            | Ctrl+V - One page down');
    WritelnWindow(EditWindowPtr, 'Ctrl+F - One word forward          | Ctrl+B - One word backward');
    WritelnWindow(EditWindowPtr, 'TAB - Indent marked region         | SELECT+TAB - Unindent marked region');
    WritelnWindow(EditWindowPtr, 'Cursor right - Character forward   | Cursor up   - One line up');
    WritelnWindow(EditWindowPtr, 'Cursor left  - Character backward  | Cursor down - One line down');
    WritelnWindow(EditWindowPtr, 'HOME - To start of file            | CLS - To end of file');
    WritelnWindow(EditWindowPtr, 'Ctrl+J - Align line (F4)           | Ctrl+W - Start forward search (F6)');
    WritelnWindow(EditWindowPtr, 'Ctrl+N - Start a replacing session | Ctrl+Q - Start backward search (F8)');
    WritelnWindow(EditWindowPtr, 'BS - Delete character before cursor| SELECT+W - Next occurrence forward');
    WritelnWindow(EditWindowPtr, 'DEL - Delete character under cursor| SELECT+Q - Next occurrence backward');
    WritelnWindow(EditWindowPtr, 'SELECT-DEL - Delete current line   | Ctrl+T - Go to specified line (F7)');
    WritelnWindow(EditWindowPtr, 'SELECT-D - Report line/word/char count');
    repeat until keypressed;
    DrawScreen(1);
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
(*        CONTROLU    : Colar conteúdo do buffer. Vai demorar... *)
        CONTROLV:   PageDown;
        CONTROLW:   WhereIs (forwardsearch,  false);
        CONTROLY:   PageUp;
        CONTROLZ:   ExitToDOS;
        SELECT:     begin
                        key := ord(readkey);
                        case key of
                            DELETE:     RemoveLine;
                            TAB:        backtab;
                            68, 100:    Location  (HowMany);              (* D *)
                            81, 113:    WhereIs   (backwardsearch, true); (* Q *)
                            87, 119:    WhereIs   (forwardsearch , true); (* W *)
                            else    delay(10);
                        end;
                    end;
        else    delay(10);
    end;
end;

(* main *)
begin

(*  If the program are being executed on a MSX 1, exits. *)
    newline     := 1;   newcolumn   := 1;   tabnumber   := 8;

    if msx_version <= 1 then
    begin
        writeln('This program needs MSX 2 and above.');
        halt;
    end;

(*  If the program are being executed on a MSX with MSX-DOS 1, exits. *)
    GetMSXDOSVersion (MSXDOSversion);

    if (MSXDOSversion.nKernelMajor < 2) then
    begin
        writeln('This program needs MSX-DOS 2 and above.');
        halt;
    end
    else
    begin

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
                        'H': CommandLineHelp;
                        'V': CommandLineVersion;
                        'L': val(copy(temp, 1, length(temp)), newline,      returncode);
                        'C': val(copy(temp, 1, length(temp)), newcolumn,    returncode);
                        'T': val(copy(temp, 1, length(temp)), tabnumber,    returncode);
                    end;
                end;
            end;

(* The first parameter should be the file. *)
            filename    := paramstr(1);
        
(* Cheats the APPEND environment variable. *)    
            CheatAPPEND(filename);
        
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
                    DrawScreen(1);
                end
                else
                    screenline := newline;
            end;
        end
    end;
    
    InitMainScreen;

    for i := 1 to maxwidth do
        tabset[i] := (i mod tabnumber) = 1;

(* main loop - get a key and process it *)
    repeat
        GotoWindowXY(EditWindowPtr, column, screenline);
        CursorOn;
        GetKey (key, iscommand);
        CursorOff;
        if iscommand then
            handlefunc(key)
        else
            character(chr(key));
    until true = false;
    
    CheatAPPEND(chr(32));
    ClearAllBlinks;
end.
