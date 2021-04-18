(* milli
 * This wannabe GNU nano-like text editor is based on Qed-Pascal
 * (http://texteditors.org/cgi-bin/wiki.pl?action=browse&diff=1&id=Qed-Pascal).
 * Our main approach is to have all GNU nano funcionalities. 
 * MSX version by Ricardo Jurczyk Pinheiro - 2020/2021.
 *)

program milli;

{$i d:conio.inc}
{$i d:dos.inc}
{$i d:dos2err.inc}
{$i d:fillvram.inc}
{$i d:readvram.inc}
{$i d:fastwrit.inc}
{$i d:milli.inc}
{$i d:txtwin.inc}
{$i d:blink.inc}

var
    currentline, key, highestline, 
    screenline, column:             byte;
    line, emptyline:                linestring;
    linebuffer:                     array [1.. maxlines] of lineptr;
    tabset:                         array [1..maxwidth] of boolean;
    textfile:                       text;
    searchstring, replacestring:    str80;
    filename:                       linestring;
    savedfile, insertmode,iscommand:boolean;
    tempnumber0:                    string[6];
    temp:                           linestring;
    i, j, tabnumber, newline,
    newcolumn, returncode:          integer;
    c:                              char;

    Registers:                      TRegs;
    ScreenStatus:                   TScreenStatus;
   
    EditWindowPtr,StatusWindowPtr:  Pointer;
    MSXDOSversion:                  TMSXDOSVersion;

Procedure CursorOn;
Begin
    BlinkChar(column + 1, screenline + 1);
End;

Procedure CursorOff;
Begin
    ClearBlinkChar(column + 1, screenline + 1);
End;

(* Return true if a key waiting, and the key. *)
procedure GetKey (var key: byte; var iscommand: boolean);
var
    inkey: char;
    
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

procedure ClearStatusLine;
begin
    ClearBlink(1, maxlength + 1, maxwidth + 2);
    FillChar(temp, maxwidth + 3, #23);
    temp[1]             := #26;
    temp[maxwidth + 2]  := #27;
    WriteVRAM(0, (maxwidth + 2) * maxlength, Addr(temp[1]), maxwidth + 3);
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

    fillchar(BlinkSequence, sizeof(BlinkSequence), 0);

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
                        Line1 := '^G Help   ~W Next forward  ^Q Backwards ^T Go To Line             ';
                        Line2 := '^C Cancel ~Q Bext backward ^N Replace   ^X Exit                   ';
                    end;
        replace:    begin
                        BlinkLength := 2;
                        BlinkSequence[1] := 1;  BlinkSequence[2] := 15;
                        Line1 := ' Y Yes         A All                                              ';
                        Line2 := ' N No         ^C Cancel                                           ';
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
begin
    ClrWindow(EditWindowPtr);

    for i := 1 to (maxlength - j) do
    begin
        fillchar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, currentline - screenline + i);
        quick_display(1, i, line);
    end;
end;

procedure ReadFile (AskForName: boolean);
var
    EndOfRead,
    maxlinesnotreached: boolean;
    VRAMAddress:        integer;
    counter:            real;

begin
    EndOfRead           := false;
    maxlinesnotreached  := false;
    counter             := startvram;

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

        while not EndOfRead do
        begin
            EndOfRead := eof(textfile);
            fillchar(line, sizeof(line), chr(32));
            readln(textfile, line);
            counter := counter + length(line) + 1;
            FromFileToVRAM(line, currentline, counter, EndOfRead);
            currentline := currentline + 1;
        end;
        
(*  Problema: Se o arquivo for grande demais pro editor, ler 
*   somente a parte que dá pra ler e parar.*)
        
        str(currentline - 1, tempnumber0);

        if maxlinesnotreached then
            temp := concat('File is too long. Read ', tempnumber0, ' lines. ')
        else
            temp := concat('Read ', tempnumber0, ' lines.');

        StatusLine (temp);
    end;

    close(textfile);

    highestline := currentline - 1;
    currentline := 1;
    column      := 1;
    screenline  := 1;
    insertmode  := true;
end;

procedure InitTextEditor;
begin
    GetScreenStatus(ScreenStatus);
    
    if ScreenStatus.bFnKeyOn then
        SetFnKeyStatus (false);
    
    Width(80);
    ClearAllBlinks;
    SetBlinkColors(ScreenStatus.nBkColor, ScreenStatus.nFgColor);
    SetBlinkRate(5, 0);

(*  Some variables. *)   
    currentline     := 1;   column  := 1;           screenline  := 1;
    highestline     := 1;   searchstring    := '';  replacestring := '';
    insertmode  := false;   savedfile       := false;
    fillchar(temp,      sizeof(temp),       chr(32));
    fillchar(emptyline, sizeof(emptyline),  chr(32));
    
(*  Erasing VRAM. *)
    fillvram(0, startvram   , 0, $DFFF);
    fillvram(1, 0           , 0, $FFFF);

(*  Erasing structure. *)    
    fillchar(structure, sizeof(structure) , 0);

(*  Set new function keys. *)
    SetFnKey(1, chr(7));    SetFnKey(2, chr(26));   SetFnKey(3, chr(15));
    SetFnKey(4, chr(10));   SetFnKey(5, chr(3));    SetFnKey(6, chr(23));
    SetFnKey(7, chr(20));   SetFnKey(8, chr(17));

end;

procedure InitMainScreen;
var
    i: byte;
    
begin
    EditWindowPtr := MakeWindow(0, 1, maxwidth + 2, maxlength + 1, chr(32));

    GotoXY(3, 1);
    FastWrite('milli 0.2');

    Blink(2, 1, maxwidth);
    DrawScreen(1);
    
    i := (maxwidth - length(filename)) div 2;
    fillchar(temp, sizeof(temp), chr(32));
    GotoXY(i - 3, 1);
    FastWriteln(temp);

    GotoXY(i, 1);
    FastWriteln(filename);

    DisplayKeys (main);
end;

procedure Help;
begin
    ClearStatusLine;
    ClearBlink(1, maxlength + 1, maxwidth + 2);
    StatusWindowPtr := MakeWindow(0, 1, maxwidth + 2, maxlength + 1, 'Main milli help text');
    WritelnWindow(StatusWindowPtr, 'Commands:');
    WritelnWindow(StatusWindowPtr, 'Ctrl-S - Save current file         | Ctrl-O - Save as file (F3)');
    WritelnWindow(StatusWindowPtr, 'Ctrl-P - Read new file             | Ctrl+Z - Close and exit from nano (F2)');
    WritelnWindow(StatusWindowPtr, 'Ctrl+G - Display help text (F1)    | Ctrl+C - Report cursor position (F5)');
    WritelnWindow(StatusWindowPtr, 'Ctrl+A - To start of line          | Ctrl+Y - One page up');
    WritelnWindow(StatusWindowPtr, 'Ctrl+E - To end of line            | Ctrl+V - One page down');
    WritelnWindow(StatusWindowPtr, 'Ctrl+F - One word backward         | Ctrl+D - One word forward');
    WritelnWindow(StatusWindowPtr, 'TAB - Indent marked region         | SELECT+TAB - Unindent marked region');
    WritelnWindow(StatusWindowPtr, 'Cursor right - Character forward   | Cursor up   - One line up');
    WritelnWindow(StatusWindowPtr, 'Cursor left  - Character backward  | Cursor down - One line down');
    WritelnWindow(StatusWindowPtr, 'HOME - To start of file            | CLS - To end of file');
    WritelnWindow(StatusWindowPtr, 'Ctrl+J - Align line (F4)           | Ctrl+W - Start forward search (F6)');
    WritelnWindow(StatusWindowPtr, 'Ctrl+N - Start a replacing session | Ctrl+Q - Start backward search (F8)');
    WritelnWindow(StatusWindowPtr, 'BS - Delete character before cursor| SELECT+W - Next occurrence forward');
    WritelnWindow(StatusWindowPtr, 'DEL - Delete character under cursor| SELECT+Q - Next occurrence backward');
    WritelnWindow(StatusWindowPtr, 'SELECT-DEL - Delete current line   | Ctrl+T - Go to specified line (F7)');
    WritelnWindow(StatusWindowPtr, 'SELECT-D - Report line/word/char count');
    c := readkey;
    EraseWindow(StatusWindowPtr);
end;

procedure character(inkey: char);
begin
    CursorOff;
    if column > maxwidth then
        delay(10)
    else
    begin
        GotoWindowXY(EditWindowPtr, column, screenline);
        WriteWindow(EditWindowPtr, inkey);
        
        fillchar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, currentline);

        if line = emptyline then
            FromRAMToVRAM(line, currentline);

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
    currentline := highestline + 1;
    screenline  := 12;
    column      := 1;
    DrawScreen(2);
end;

procedure BeginLine;
begin
    currentline := WhereYWindow(EditWindowPtr);
    screenline  := currentline;
    column      := 1;
    DrawScreen(1);
end;

procedure EndLine;
begin
    fillchar(line, sizeof(line), chr(32));
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
        fillchar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, currentline);
        quick_display(1, 1, line);
    end
    else
        screenline := screenline - 1;
end;

procedure CursorDown;
begin
    if currentline >= (highestline - 1) then
        exit;
    
    currentline :=  currentline + 1;
    screenline  :=  screenline  + 1;

    if screenline > (maxlength - 1) then
    begin
        GotoWindowXY(EditWindowPtr, 1, 2);
        ScrollWindowUp(EditWindowPtr);
        screenline := maxlength - 1;
        fillchar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, currentline);
        quick_display(1, screenline, line);
    end;
end;

procedure InsertLine;
begin

(* Problema: Aqui vamos ter que mexer depois. Será necessário criar 
*  uma rotina para mover os dados na VRAM, para inserir a linha.
*  Também será necessário uma rotina para remover linhas, fazendo a 
*  desfragmentação da VRAM. *)
    
    fillchar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, currentline);

    GotoWindowXY(EditWindowPtr, column, screenline + 1);
    InsLineWindow(EditWindowPtr);
{
    for i := highestline + 1 downto currentline do
        linebuffer[i + 1] := linebuffer[i];
}
    line        := emptyline;
    highestline := highestline + 1;
    FromRAMToVRAM(line, currentline);
end;

procedure Return;
begin
    CursorDown;
    column := 1;
    GotoWindowXY(EditWindowPtr, column, screenline);

    if insertmode then
        InsertLine;
end;

procedure deleteline;
begin

(* Problema: Aqui vamos ter que mexer depois. Será necessário criar 
*  uma rotina para mover os dados na VRAM, para inserir a linha.
*  Também será necessário uma rotina para remover linhas, fazendo a 
*  desfragmentação da VRAM. *)

    DelLineWindow(EditWindowPtr);

    fillchar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, currentline + ((maxlength + 1) - screenline));

    if highestline > currentline + (maxlength - screenline) then
        quick_display(1, maxlength,line);

    fillchar(line, sizeof(line), chr(32));
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
    fillchar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, currentline);
    fillchar(temp, sizeof(temp), chr(32));
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
    quick_display(1,screenline,line);
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
        if filename <> '' then
            temp := concat('File Name to Write [', filename, ']: ')
        else
            temp := concat('File Name to Write: ');
{    
        tempfilename := filename;
}
        FastWrite(temp);
        read(filename);
    end;
    
    assign(textfile, filename);
    {$i-}
    rewrite(textfile);
    {$i+}
    
    filename := tempfilename;
    
    for i := 1 to highestline + 1 do
    begin
        if (i mod 100) = 0 then
            write(#13, i);
        fillchar(line, sizeof(line), chr(32));
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
    if not savedfile then
        WriteOut(false); 

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
    fillchar(line, sizeof(line), chr(32));
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
    fillchar(line, sizeof(line), chr(32));
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

    fillchar(line, sizeof(line), chr(32));
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

(*  Problema: Não está funcionando continuar a busca de trás pra frente. Verificar. *)
    
    if NOT nextoccurrence OR (searchstring = '') then
    begin
        GotoXY(1, maxlength + 1);
        ClrEol;
        Blink(1, maxlength + 1, maxwidth + 2);
        tempsearchstring := searchstring;
        if searchstring <> '' then
            temp := concat('Search [', tempsearchstring, ']: ')
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
        stopsearch := highestline
    else
        stopsearch := 1;
        
    i := currentline + 1;
    
    while i <> stopsearch do
    begin
        fillchar(line, sizeof(line), chr(32));
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
    position, linesearch                : integer;
    searchlength, replacementlength     : byte;
    choice                              : char;
    tempsearchstring                    : str80;
   
begin
    DisplayKeys (search);
    SetBlinkRate (5, 0);
    GotoXY(1, maxlength + 1);
    ClrEol;
    Blink(1, maxlength + 1, maxwidth + 2);

    tempsearchstring := searchstring;
    if searchstring <> '' then
        temp := concat('Search (to replace) [', tempsearchstring, ']: ')
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

    for linesearch := 1 to highestline do
    begin
        fillchar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, linesearch);        
        
        position := pos (searchstring, line);

        while (position > 0) do
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

(* Problema: Na execução do replace, *)
            
            case ord (choice) of
            CONTROLC:          begin
                                    ClrEol;
                                    StatusLine('Cancelled');
                                    DisplayKeys (main);
                                    BeginFile;
                                    exit;
                                end;
                                
(* a, A, y, Y *)
                                
(* Problema: A rotina que faz a troca precisa fazer nova busca a partir daquela posição
* nova. Este é um problema que vem desde o código original. Outra alteração seria 
* apenas reescrever aquela linha específica, e não toda a janela. Redesenhar toda a 
* janela, somente se trocar de página. *)
                                
            65, 97, 89, 121:    begin
                                    line := copy (line, 1, position - 1) +
                                    replacestring + copy (line, 
                                    position + length (searchstring), 128);

                                    position := pos (searchstring, copy (line,
                                    position + replacementlength + 1, 128)) + 
                                    position + replacementlength;
                                end;
(* n, N *)                                
            78, 110:            position := pos (searchstring, copy (line,
                                position + length(searchstring) + 1, 128)) +
                                position + length(searchstring);
            end;

            GotoWindowXY(EditWindowPtr, 1, screenline);
            ClrEolWindow(EditWindowPtr);
            temp := copy(line, 1, maxlength + 1);
            WriteWindow(EditWindowPtr, temp);
            FromRAMToVRAM(line, linesearch);
        end;
    end;
end;

procedure AlignText;
var
    lengthline, blankspaces: byte;
    justifyvector: array [1..maxwidth] of byte;
    k, l: byte;

begin
(*  Testar um pouco mais. *)
    fillchar(temp, sizeof(temp), chr(32));
    FromVRAMToRAM(temp, currentline);
        
    lengthline := length(temp);
    
(*  Remove blank spaces in the beginning and in the end of the line. *)
    i := DifferentPos   (chr(32), temp) - 1; 
    j := RDifferentPos  (chr(32), temp) + 1;

    if i > 1 then
        delete(temp, 1, i)
    else
        i := 0;
        
    if j < maxwidth then
        delete(temp, j, lengthline - j)
    else
        j := maxwidth;

    lengthline := length(temp);

    DisplayKeys(align);
    c := readkey;

    case ord(c) of
        76, 108:    begin
(* left - L *)
                        blankspaces := (maxwidth - lengthline) + 1;
                        for i := 1 to blankspaces do
                            insert(#32, temp, lengthline + 1);
                    end;
        82, 114:    begin
(* right - R *)        
                        blankspaces := (maxwidth - lengthline);
                        for i := 1 to blankspaces do
                            insert(#32, temp, 1);
                    end;
        67, 99:     begin
(* center - C *)
                        blankspaces := (maxwidth - lengthline) div 2;
                        for i := 1 to blankspaces do
                            insert(#32, temp, 1);                        
                    end;
        74, 106:    begin
(* justify - J *)
                        j := 1;
                        
(*  Find all blank spaces in the phrase and save their positions. *)
                        for i := 1 to (RDifferentPos(chr(32), temp)) do
                            if ord(temp[i]) = 32 then
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
                                insert(#32, temp, justifyvector[i]);
                            justifyvector[i] := justifyvector[i] + k;
                        end;

                        k := (maxwidth - lengthline) mod j;
                        
                        for l := 1 to k do
                            insert(#32, temp, justifyvector[1]);
                        justifyvector[1] := justifyvector[1] + k;

                    end;
    end;
    
    FromVRAMToRAM(temp, currentline);
    
    DisplayKeys(main);

(*  Fica mais rápido redesenhar somente a linha alterada. *)

    if screenline < (maxlength - 1) then
    begin
        fillchar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, currentline);
        quick_display(1, screenline, line);
        
        fillchar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, currentline + 1);
        quick_display(1, screenline + 1, line);
    end
    else
        DrawScreen(1);
    
    case ord(c) of
        76, 108: temp := 'Text aligned to the left.';   (* L *)
        82, 114: temp := 'Text aligned to the right.';  (* R *)
        67, 99:  temp := 'Text aligned to the center.'; (* C *)
        74, 106: temp := 'Text justified.';             (* K *)
    end;
    
    StatusLine(temp);
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
    fillchar(temp, sizeof(temp), chr(32));

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
        fillchar(line, sizeof(line), chr(32));
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

        fillchar(temp2, sizeof(temp2), chr(32));

        for i := 1 to highestline do
        begin
            fillchar(temp2, sizeof(temp2), chr(32));
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
    
    fillchar(line, sizeof(line), chr(32));
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
    FastWriteln('using the same look-and-feel and a lot of keystrokes from GNU nano editor.');
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

procedure handlefunc(keynum: byte);
var
    key         : byte;
    iscommand   : boolean;
    
begin
    case keynum of
        BS          :   backspace;
        TAB         :   tabulate;
        ENTER       :   Return;
        UpArrow     :   CursorUp;
        LeftArrow   :   CursorLeft;
        RightArrow  :   CursorRight;
        DownArrow   :   CursorDown;
        INSERT      :   ins;
        DELETE      :   del;
        HOME        :   BeginFile;
        CLS         :   EndFile;
        CONTROLA    :   BeginLine;
        CONTROLB    :   PreviousWord;
        CONTROLC    :   Location(Position); 
        CONTROLD    :   del;
        CONTROLE    :   EndLine;    
        CONTROLF    :   NextWord;
        CONTROLG    :   Help;
        CONTROLJ    :   AlignText;
        CONTROLN    :   SearchAndReplace;
        CONTROLO    :   WriteOut(true);
        CONTROLS    :   WriteOut(false);
        CONTROLP    :   ReadFile(true);
        CONTROLQ    :   WhereIs (backwardsearch, false);
        CONTROLT    :   GoToLine;
(*        CONTROLU    : Colar conteúdo do buffer. Vai demorar... *)
        CONTROLV    :   PageDown;
        CONTROLW    :   WhereIs (forwardsearch,  false);
        CONTROLY    :   PageUp;
        CONTROLZ    :   ExitToDOS;
        SELECT      :   begin
                            key := ord(readkey);
                            case key of
                                DELETE  : RemoveLine;
                                TAB     : backtab;
                                68, 100 : Location  (HowMany);              (* D *)
                                81, 113 : WhereIs   (backwardsearch, true); (* Q *)
                                87, 119 : WhereIs   (forwardsearch , true); (* W *)
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
        end;
    end;

    for i := 1 to maxwidth do
        tabset[i] := (i mod tabnumber) = 1;

    InitMainScreen;

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
