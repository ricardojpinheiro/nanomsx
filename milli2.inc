(*
*  milli2.inc - Pascal library which is used with the milli text editor.
*  So, some routines were taken from the main program to be placed here.
*)

(* Clears the status line. *)

procedure ClearStatusLine;
begin
    ClearBlink(1, maxlength + 1, maxwidth + 2);
    FillChar(temp, maxwidth + 3, #23);
    temp[1]             := #26;
    temp[maxwidth + 2]  := #27;
    WriteVRAM(0, (maxwidth + 2) * maxlength, Addr(temp[1]), maxwidth + 3);
end;

(* Shows a help when milli is executed with /h or /v. *)

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
                FastWriteln('Version 0.8.2 - Copyright (c) 2020-2023 Brazilian MSX Crew.');
                FastWriteln('Some rights reserved (not many!).');
                writeln;
                FastWriteln('This editor resembles the GNU nano editor (http://www.nano-editor.org),');
                FastWriteln('with the same look and feel and many of the same keystrokes.');
                writeln;
                FastWriteln('It''s licensed under the GPLv3+ license. Yep, free software. You are free');
                FastWriteln('to change and redistribute it. But don''t ask me about any warranties...');
                FastWriteln('Use it at your own risk. http://gnu.org/licenses/gpl.html');
                writeln;
                FastWriteln('By the way, the ''milli'' name may come from two places:');
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
    FastWriteln('/e      - Convert typed tabs to spaces.');
}
				FastWriteln('/b      - Save backups of existing files.');
                FastWriteln('/l<l>   - Start at line l.');
                FastWriteln('/c<c>   - Start at column c.');
                FastWriteln('/t<n>   - Make a tab this number (n) of columns wide.');
                FastWriteln('/z<n>   - Tell milli the maximum number of lines that will be used.');
                FastWriteln('/h      - Show this help text and exit.');
                FastWriteln('/v      - Output version information and exit.');
                writeln;
            end;
        end;
    ClearAllBlinks;
    halt;
end;

(* Turn on the cursor - uses blink table. *)

Procedure CursorOn;
Begin
    BlinkChar(column + 1, screenline + 1);
End;

(* Turn off the cursor - uses blink table. *)

Procedure CursorOff;
Begin
    ClearBlinkChar(column + 1, screenline + 1);
End;

procedure GetKey (var key: byte; var iscommand: boolean);
(* Return true if a key waiting, and the key. *)

begin
    iscommand   := false;
    c       	:= readkey;
    key         := ord(c);

    if key in NoPrint then
        iscommand := true;

{
	case key of
		1..31, 127: iscommand := true;
	end;
}
end;

procedure quick_display(x, y: integer; s: TString);
begin
    GotoWindowXY(EditWindowPtr, x, y);
    WriteWindow (EditWindowPtr, s);
    ClrEolWindow(EditWindowPtr);
end;

procedure StatusLine (message: TString);
begin
    ClearStatusLine;

    message         := concat('[ ', message, ' ]');
    lengthmessage   := length(message);
    ranking        	:= (maxwidth - lengthmessage) div 2;

    GotoXY(ranking, maxlength + 1);
    FastWrite(message);
    Blink(ranking, maxlength + 1, lengthmessage);
end;

procedure DisplayKeys (whichkey: KeystrokeLines);
var
    BlinkSequence: 	array [1..6] of byte;
begin
    for i := 2 to 3 do
        ClearBlink(1, maxlength + i, maxwidth);

    FillChar(BlinkSequence, sizeof(BlinkSequence), 0);

	BlinkLength := 2;
    case whichkey of
        main:       begin
                        BlinkSequence[1] := 1;	BlinkSequence[2] := 9;
                        BlinkSequence[3] := 22; BlinkSequence[4] := 34;
                        BlinkSequence[5] := 43; BlinkSequence[6] := 55;
                        Line1 := concat('^G Help ^O Write Out ^W Where Is ', 
										'~B MarkB ^C Location ~C Line count');
                        Line2 := concat('^Z Exit ^P Read File ^N Replace  ',
										'~E MarkE ^J Align    ^T Go To Line');
                    end;
        search:     begin
                        BlinkSequence[1] := 1;  BlinkSequence[2] := 11;
                        BlinkSequence[3] := 28; BlinkSequence[4] := 41;
                        Line1 := concat('^G Help   ~W Next forward  ',
										'^Q Backwards ^T Go To Line');
                        Line2 := concat('^C Cancel ~Q Next backward ',
										'^N Replace   ^X Exit');
                    end;
        replace:    begin
                        BlinkSequence[1] := 1;  BlinkSequence[2] := 15;
                        Line1 := ' Y Yes         A All';
                        Line2 := ' N No         ^C Cancel';
                    end;
        align:      begin
						BlinkLength := 1;
                        BlinkSequence[1] := 1;  BlinkSequence[2] := 15;
                        Line1 := 'L Left        C Center';
                        Line2 := 'R Right       J Justify';
                    end;
    end;
    FillVRAM(0,  (maxwidth + 2)*(maxlength + 1), 32, ScreenStatus.nWidth);
    FillVRAM(0,  (maxwidth + 2)*(maxlength + 2), 32, ScreenStatus.nWidth);
    WriteVRAM(0, (maxwidth + 2)*(maxlength + 1), Addr(Line1[1]), length(Line1));
    WriteVRAM(0, (maxwidth + 2)*(maxlength + 2), Addr(Line2[1]), length(Line2));

    for i := 1 to sizeof(BlinkSequence) do
    begin
        Blink(BlinkSequence[i], maxlength + 2, BlinkLength);
        Blink(BlinkSequence[i], maxlength + 3, BlinkLength);
    end;
end;

procedure DrawScreen (currentline, screenline: integer; j: byte);
begin
    if highestline <= (maxlength - j) then
		aux := highestline
    else
        aux := maxlength - j;

    ClrWindow(EditWindowPtr);

    for i := 1 to aux do
    begin
        FillChar(temp, sizeof(temp), chr(32));
        FromVRAMToRAM(temp, currentline - screenline + i);
        quick_display(1, i, temp);
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

procedure InitStructures;
begin
	BlockMarked	:= false;
    counter		:= startvram;

(*  Initialize structure. *)
    StatusLine('Initializing structures...');
    for i := 1 to maxlinesforreal do
    begin
        InitVRAM(i, counter); 
        counter := counter + maxcols;
    end;

(*  Erase VRAM banks, from startvram till the end. *)
    StatusLine('Wiping memory, please be patient...');
    fillvram(0, startvram, 0, (startvram + $50 * maxlinesforreal) - startvram);
    if maxlinesforreal > 750 then
		fillvram(1, 0 , 0, ($50 * ((maxlinesforreal + 1) - 750)));
    
    ClrWindow(EditWindowPtr);
    ClearStatusLine;
end;

procedure InitTextEditor;
begin
    GetScreenStatus(ScreenStatus);
    
    if ScreenStatus.bFnKeyOn then
		begin
			FnKeys := ScreenStatus.bFnKeyOn;
			SetFnKeyStatus (false);
        end;
    
    ScreenWidth(80);
    ClearAllBlinks;
    SetBlinkColors(ScreenStatus.nBkColor, ScreenStatus.nFgColor);
    SetBlinkRate(5, 0);

(*  Some variables. *)   
    currentline := 1; 		screenline := 1;        highestline := 1;
    column      := 1; 		insertmode  := false;   savedfile   := false;   
    FillChar(temp,          sizeof(temp),           chr(32));
    FillChar(filename,      sizeof(filename),       chr(32));
    FillChar(searchstring,  sizeof(searchstring),   chr(32));
    FillChar(replacestring, sizeof(replacestring),  chr(32));

(*  Set new function keys. *)
    SetFnKey(1, chr(7));  SetFnKey(2, chr(26)); SetFnKey(3, chr(15));
    SetFnKey(4, chr(10)); SetFnKey(5, chr(3));  SetFnKey(6, chr(23));
    SetFnKey(7, chr(20)); SetFnKey(8, chr(17));
end;

procedure InitMainScreen;
begin
    EditWindowPtr := MakeWindow(0, 1, maxwidth + 2, maxlength + 1, chr(32));

	ClrWindow (EditWindowPtr);

    GotoXY(3, 1);
    FastWrite('milli 0.8.2');

    Blink(2, 1, maxwidth);
    DrawScreen(currentline, screenline, 1);

    DisplayFileNameOnTop;

    DisplayKeys (main);
    ClearStatusLine;
end;

procedure character(inkey: char);
begin
    CursorOff;

    FillChar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, currentline);

    if column > maxwidth then
        delay(10)
    else
		begin
			GotoWindowXY(EditWindowPtr, column, screenline);
			WriteWindow(EditWindowPtr, inkey);

			if length(line) = 0 then
			begin
				InsertLinesIntoText (currentline - 1, highestline, 1);
				FillChar(line, sizeof(line), chr(32));
			end;

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

			if column >= maxwidth then
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
    DrawScreen(currentline, screenline, 1);
end;

procedure EndFile;
begin
    currentline := highestline - (maxlength - 2);
    screenline  := 1;
    column      := 1;
    DrawScreen(currentline, screenline, 1);
    screenline  := maxlength - 1;
    GotoWindowXY(EditWindowPtr, column, screenline);
end;

procedure BeginLine;
begin
    currentline := WhereYWindow(EditWindowPtr);
    screenline  := currentline;
    column      := 1;
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
end;

procedure CursorDown;
begin
    if currentline > highestline then
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
end;

procedure deleteline;
begin
    aux := currentline + (maxlength - screenline);
    FillChar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, aux);

    GotoWindowXY(EditWindowPtr, column, screenline);
    DelLineWindow(EditWindowPtr);
    DeleteLinesFromText(currentline, highestline, 1);

    if highestline > aux then
        quick_display(1, maxlength - 1, line);
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
        temp 		:= 'Insert mode off';
        insertmode 	:= false;
    end
    else
    begin
        temp 		:= 'Insert mode on';
        insertmode 	:= true;
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

    if length(line) = 0 then
        FillChar(line, sizeof(line), chr(32));

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
    begin
        column  := column - 1;
        del;
    end
    else
        if currentline > 1 then
        begin
            FillChar(temp, sizeof(temp), chr(32));
            FromVRAMToRAM(temp, currentline); 

            deleteline;
            CursorUp;
            EndLine;

            FillChar(line, sizeof(line), chr(32));
            FromVRAMToRAM(line, currentline);
            line := concat(line, temp);
            
            quick_display(1, screenline, line);

            FromRAMToVRAM(line, currentline);
            
            FillChar(line, sizeof(line), chr(32));
            FromVRAMToRAM(line, currentline + ((maxlength - 1) - screenline));
            if highestline > (currentline + ((maxlength - 1) - screenline)) then
                quick_display(1, maxlength - 1, line);    
        end;
end;

procedure PageUp;
begin
    currentline     := currentline - (maxlength - 1);
    if currentline <= screenline then
        BeginFile
    else
        DrawScreen(currentline, screenline, 1);
end;

procedure PageDown;
begin
    currentline     := currentline + (maxlength - 1);
    if currentline >= highestline then
        EndFile
    else
        if (highestline - currentline) < maxlength then
            DrawScreen(currentline, screenline, 2)
        else
            DrawScreen(currentline, screenline, 1);
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
		lengthmessage := column;
		newcolumn := 0;
		FillChar(Line1, sizeof(Line1), chr(32));
		repeat
			column 		:= column 		+ 1;
			newcolumn 	:= newcolumn	+ 1;
		until (tabset [column]= true) or (column = maxwidth + 1);

		if insertmode then
		begin
			FillChar(line, sizeof(line), chr(32));
			FromVRAMToRAM(line, currentline);
			line := copy (line	, 1, lengthmessage - 1) + 
					copy (Line1	, 1, newcolumn - 1) + 
					copy (line	, lengthmessage, maxwidth);
			quick_display(1, currentline, line);
			FromRAMToVRAM(line, currentline);
		end;
   end;
   column := column - 1;
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
    
    if (length(line) <> 0) then
        FillChar(line, sizeof(line), chr(32));

    FillChar(line, sizeof(line), chr(32));
    FromRAMToVRAM(line, currentline);
    CursorOn;
end;

procedure WhereIs (direction: Directions; nextoccurrence: boolean);
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
        searchstring := readstring(40);
    end;

    if length (searchstring) = 0 then
        if length(tempsearchstring) = 0 then
        begin
            BeginFile;
            exit;
        end
        else
            searchstring := tempsearchstring;
    
    i := currentline;
        
    if direction = forwardsearch then
        stopsearch := highestline + 1
    else
        stopsearch := 0;
    
    while i <> stopsearch do
    begin
        FillChar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, i);        
    
(* look for matches on this line *)
        point := pos (searchstring, line);

(* if there was a match then get ready to print it *)
        if (point > 0) then
        begin
            currentline := i;
            if currentline >= maxlength then
                screenline := maxlength - 1
            else
                screenline := currentline;
            column := point;
            DrawScreen(currentline, screenline, 1);
            
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

    FillChar(searchstring, sizeof(searchstring), chr(32));
    
    searchstring := readstring(40);
    
    delete(searchstring, 1, 1);
    aux := Pos(chr(32), searchstring);
    tempnumber0 := copy(searchstring, 1, aux - 1);
    tempnumber1 := copy(searchstring, aux + 1, length(searchstring));

    val (tempnumber0, destline,     aux);
    val (tempnumber1, destcolumn,   aux);

    if destline >= highestline then
        destline := highestline;

    FillChar(line, sizeof(line), chr(32));
    FromVRAMToRAM(line, destline);    
    i := length(line);
    
    if destcolumn > i then
        destcolumn := i;

(*  Here, if destline is in the last page... *)
    if destline >= (highestline - maxlength) then
        i := 2
    else
        i := 1;

    currentline     := destline;
    screenline      := 1;
    column          := destcolumn;

    DrawScreen(currentline, screenline, i);
  
(* Redraw the StatusLine, bottom of the window and display keys *)
    ClearStatusLine;
end;

procedure Help;
begin
    ClrWindow(EditWindowPtr);
    WritelnWindow(EditWindowPtr, 'Commands:');
    WritelnWindow(EditWindowPtr, 'Ctrl+S - Save current file         | Ctrl+O - Save as file (F3)');
    WritelnWindow(EditWindowPtr, 'Ctrl+P - Read new file             | Ctrl+Z - Close and exit from nano (F2)');
    WritelnWindow(EditWindowPtr, 'Ctrl+G - Display help text (F1)    | Ctrl+C - Report cursor position (F5)');
    WritelnWindow(EditWindowPtr, 'Ctrl+A - To start of line          | Ctrl+Y - One page up');
    WritelnWindow(EditWindowPtr, 'Ctrl+E - To end of line            | Ctrl+V - One page down');
    WritelnWindow(EditWindowPtr, 'Ctrl+F - One word forward          | Ctrl+B - One word backward');
    WritelnWindow(EditWindowPtr, 'TAB - Indent marked region         | SELECT+TAB - Unindent marked region');
    WritelnWindow(EditWindowPtr, 'Cursor right - Character forward   | Cursor up   - One line up');
    WritelnWindow(EditWindowPtr, 'Cursor left  - Character backward  | Cursor down - One line down');
    WritelnWindow(EditWindowPtr, 'HOME - Jump to beginning of file   | CLS - Jump to end of file');
    WritelnWindow(EditWindowPtr, 'Ctrl+J - Align line (F4)           | Ctrl+W - Start forward search (F6)');
    WritelnWindow(EditWindowPtr, 'Ctrl+N - Start a replacing session | Ctrl+Q - Start backward search (F8)');
    WritelnWindow(EditWindowPtr, 'BS - Delete character before cursor| SELECT+W - Next occurrence forward');
    WritelnWindow(EditWindowPtr, 'DEL - Delete character under cursor| SELECT+Q - Next occurrence backward');
    WritelnWindow(EditWindowPtr, 'SELECT+DEL - Delete current line   | SELECT+Y - Remove current line');
    WritelnWindow(EditWindowPtr, 'Ctrl+T - Go to specified line (F7) | SELECT+D - Report line/word/char count');
    WritelnWindow(EditWindowPtr, 'SELECT+B - Mark beginning of block | SELECT+E - Mark end of the block');
    WritelnWindow(EditWindowPtr, 'SELECT+C - Copy block to line      | SELECT+V - Move block to line');
    WritelnWindow(EditWindowPtr, 'SELECT+F - Delete block            | SELECT+H - Unhide block');    
    c := readkey;
    DrawScreen(currentline, screenline, 1);
end;

procedure Location (Types: LocationOptions);
begin
    FillChar(temp, sizeof(temp), chr(32));
(*  Line count - Percentage. *)    
    str(currentline, tempnumber0);
    str(highestline, tempnumber1);
    str((round(int((currentline*100)/highestline))), tempnumber2);
    
    if Types = Position then
        temp := concat( 'line ', tempnumber0,'/', tempnumber1,
                        ' (', tempnumber2,'%),')
    else
        temp := concat( ' Lines: ', tempnumber1);

    if Types = Position then
    begin
(*  Column count. *)  
        FillChar(line, sizeof(line), chr(32));
        FromVRAMToRAM(line, currentline);

        j := length(line);
        if j = 0 then
            j := 1;
(*  Column count - Percentage. *)        
        str(column, tempnumber0);
        str(j, tempnumber1);
        str((round(int((column*100)/j))) , tempnumber2);
    
        temp := concat( temp, ' col ',tempnumber0,'/',tempnumber1,
                        ' (', tempnumber2,'%)');
    end;

(*  Char count. *)
    abovechar := 0;
    
    for i := 1 to currentline - 1 do
        abovechar := abovechar + length(line);

    totalchar := abovechar;
    abovechar := abovechar + column;
    
    for i := currentline to highestline do
        totalchar := totalchar + length(line);

    if totalchar = 0 then
        totalchar := 1;
    
(*  Char count - percentage. *)
    str(abovechar:6:0                   ,   tempnumber0);
    str(totalchar:6:0                   ,   tempnumber1);

    str((round(int((abovechar*100)/totalchar))),   tempnumber2);
    
    delete(tempnumber0  , 1, RPos(' ', tempnumber0) - 1);
    delete(tempnumber1  , 1, RPos(' ', tempnumber1) - 1);

    if Types = Position then
        temp := concat( temp, ' char ', tempnumber0,'/', tempnumber1,
                        ' (', tempnumber2,'%)')
    else
        temp := concat( temp, ' Chars: ', tempnumber1);

(*  Word count *)
    if Types = HowMany then
    begin
        totalwords  := 0;
        FillChar(Line2, sizeof(Line2), chr(32));

        for i := 1 to highestline do
        begin
            FillChar(Line2, sizeof(Line2), chr(32));
            FromVRAMToRAM(Line2, i);
            for j   := 1 to length(Line2) do
                if (Line2[j] = chr(32)) and (ord(Line2[j + 1]) in Print)
                    and (j > 1) then
                    TotalWords := TotalWords + 1;
        end;
        
        TotalWords := TotalWords + 1;
        str(TotalWords      , tempnumber0);
        insert(tempnumber0  , temp  , 1);
        insert('Words: '    , temp  , 1);
    end;
    StatusLine(temp);
end;
