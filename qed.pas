(*
 * quick editor
 *
 * This is a simple and fast editor to use
 * when you want to quickly change a file.  It is not
 * meant to be used as a programming editor
 *
 *)

 program QuickEditor;

 uses crt;

 type
   anystr     =        string [255];
   linestring =        string [128];
   lineptr    =        ^linestring;

 const
   maxlines =          5000;

 var
   currentline,
   column,
   highestline,
   screenline:         integer;
   linebuffer:         array [1.. maxlines] of lineptr;
   emptyline:          lineptr;
   tabset:             array [1..80] of boolean;
   textfile:           text;
   searchstring,
   replacement:        linestring;
   insertmode:         boolean;

(**************************************************************************
  Return true if a key waiting, and the key.
  If function key, add 256 to the value of the key.
 **************************************************************************)
 procedure getkey (var key : integer; var iscommand : boolean);
 var
    inkey : char;
 begin
   iscommand := false;
   inkey := readkey;
   key := ord(inkey);
   if inkey <= #27 then begin
     iscommand := true;
     if (inkey = #0) and keypressed then begin
       inkey := readkey;
       key := ord(inkey) + 256;
     end;
   end;
 end;

 procedure WaitForKey;
 var
   key : integer;
   iscommand : boolean;
 begin
   getkey(key, iscommand);
 end;

 procedure init_msgline;
 begin
    window(1, 25, 80, 25);
    gotoxy(1, 25);
    clreol;
 end;

 procedure edit_win;
 begin
    window(1, 2, 80, 23);
 end;

 procedure full_screen;
 begin
    window(1, 1, 80, 25);
 end;

 procedure quick_display(x,y: integer;  s: linestring);
 begin
    gotoxy(x, y);
    write(s);
    clreol;
 end;

 procedure dispkey (s:                  linestring);
 begin
   highvideo;
   write(s [1]);
   lowvideo;
   write(copy (s, 2, 80));
 end;

 procedure displaykeys;
 begin
   init_msgline;
   dispkey('1Help  ');
   dispkey('2Locate  ');
   dispkey('3Search  ');
   dispkey('4Replace  ');
   dispkey('5SaveQuit  ');
   dispkey('6InsLine  ');
   dispkey('7DelLine  ');
   dispkey('0QuitNosave  ');
   highvideo;
   edit_win;
 end;

 procedure ShowMessage(message : anystr);
 begin
   init_msgline;
   write(message);
   WaitForKey;
   displaykeys;
 end;

procedure drawscreen;
var
   i:  integer;
begin
   for i := 1 to 22 do
      quick_display(1,i,linebuffer [currentline-screenline+i]^);
end;

 function replicate (count, ascii: integer): linestring;
 var
   temp:               linestring;
   i:                  byte;
 begin
   temp := '';

   for i := 1 to count do
      temp := temp + chr (ascii);

   replicate := temp;
 end;

 procedure newbuffer(var buf: lineptr);
 begin
    new(buf);
 end;

 procedure loadfile (name:               linestring);
 var
   i : integer;
 begin
   edit_win;
   clrscr;
   assign(textfile, name);    {$i-}

   reset(textfile);           {$i+}

   if (ioresult <> 0) then begin
      clrscr;
      writeln(chr (7));
      writeln('File does not exist: ', name);
      halt;
   end;

   writeln;
   write('      Reading ',name);

   for i := 1 to maxlines do begin
      if (linebuffer[i] <> emptyline) then
         linebuffer[i]^ := emptyline^;
   end;

   currentline := 1;

   while not eof (textfile) do begin
      if (currentline mod 100) = 0 then
         write(#13,currentline);

      if linebuffer[currentline] = emptyline then
         newbuffer(linebuffer[currentline]);

      readln(textfile, linebuffer [currentline]^);

      currentline := currentline + 1;
      if (currentline > maxlines) then begin
         writeln('File is too long to edit with QED');
         writeln('Only compiled for ',maxlines,' lines');
         halt;
      end;
   end;

   close(textfile);

   highestline := currentline + 1;
   currentline := 1;
   column := 1;
   screenline := 1;
   drawscreen;
 end;

 procedure initialize;
 var
   i : integer;
 begin
   clrscr;
   full_screen;
   gotoxy(1,1);
   write(replicate (80, 205));
   gotoxy(1,24);
   write(replicate (80, 196));
   gotoxy(12,1);
   write(' Quick Editor ');
   gotoxy(29,1);
   write(' ',paramstr (1),' ');
   displaykeys;
   currentline := 1;
   column := 1;
   screenline := 1;
   highestline := 1;
   newbuffer(emptyline);
   emptyline^ := '';
   searchstring := '';
   replacement := '';
   insertmode := false;

   for i := 1 to 80 do
      tabset[i]:=(i mod 8)= 1;

   for i := 1 to maxlines do
      linebuffer[i] := emptyline;

   gotoxy(10, 20);
 end;

procedure help;
begin
   clrscr;
   quick_display(1, 1,'Quick editor commands:');
   quick_display(5, 3,'<BACKSPACE>, <TAB>, <ENTER>, <HOME>, <END>, ');
   quick_display(5, 4,'<PGUP>, <PGDN>, <DELETE>, <arrow keys>');
   quick_display(5, 5,'  - These keys operate as expected');
   quick_display(5, 7,'<ESC>       Erase current line');
   quick_display(5, 8,'<INSERT>    Toggle insert/replace mode');
   quick_display(5, 9,'CTL/LEFT    Previous word');
   quick_display(5,10,'CTL/RIGHT   Next word');
   quick_display(5,11,'CTL/PGUP    Top of file');
   quick_display(5,12,'CTL/PGDN    End of file');
   quick_display(5,13,'F1          Print these instructions');
   quick_display(5,14,'F2          Locate all lines with a string');
   quick_display(5,15,'F3          Search for a string');
   quick_display(5,16,'F4          Global search and replace');
   quick_display(5,17,'F5          Save file and quit');
   quick_display(5,18,'F6          Insert blank line');
   quick_display(5,19,'F7          Delete current line');
   quick_display(5,20,'F10         Abort edit');

   ShowMessage('Press any key to return to editing...');

   drawscreen;
end;

 procedure printrow;
 begin
   full_screen;
   gotoxy(54,1);
   write(' line ', currentline : 4,' ');
   gotoxy(68,1);
   write(' col ', column : 2,' ');
   edit_win;
 end;

 procedure character(inkey : char);
 begin
   if column = 79 then begin
      sound(510);
      delay(30);
      nosound;
   end else begin
      gotoxy(column, screenline);
      write(inkey);

      if linebuffer[currentline] = emptyline then begin
         newbuffer(linebuffer[currentline]);
         linebuffer[currentline]^ := '';
      end;

      while length(linebuffer[currentline]^) < column do
         linebuffer[currentline]^ := linebuffer[currentline]^ + ' ';

      insert(inkey, linebuffer [currentline]^, column);
      column := column + 1;

      if not insertmode then
         delete(linebuffer [currentline]^, column, 1);

(* redraw current line if in insert mode *)
      if insertmode then
         quick_display(1,screenline,linebuffer [currentline]^);

(* ding the bell when close to the end of a line *)

      if column = 70 then begin
         sound(1010);
         delay(10);
         nosound;
      end;
   end;
 end;

 procedure beginfile;
 begin
   currentline := 1;
   column := 1;
   screenline := 1;
   drawscreen;
 end;

 procedure endfile;
 begin
   currentline := highestline + 1;
   screenline := 12;
   column := 1;
   drawscreen;
 end;

 procedure funcend;
 begin
   column := length (linebuffer [currentline]^) + 1;
   if column > 80 then
      column := 80;
 end;

 procedure cursorup;
 begin
   if currentline = 1 then
      exit;

   currentline := currentline - 1;
   if screenline = 1 then begin
      gotoxy(1, 1);
      insline;
      quick_display(1,1,linebuffer [currentline]^);
   end else
      screenline := screenline - 1;
 end;

 procedure cursordown;
 begin
   currentline := currentline + 1;
   if currentline > highestline then
      highestline := currentline;

   screenline := screenline + 1;
   if screenline > 22 then begin
      gotoxy(1, 1);
      delline;
      screenline := 22;
      quick_display(1,screenline,linebuffer [currentline]^);
   end;
 end;

 procedure insertline;
 var
   i : integer;
 begin
   insline;

   for i := highestline + 1 downto currentline do
      linebuffer[i + 1] := linebuffer [i];

    highestline := highestline + 1;
   linebuffer[currentline] := emptyline;
   
 end;

 procedure enter;
 begin
   cursordown;
   column := 1;
   gotoxy(column, screenline);

   if insertmode then
      insertline;
 end;

 procedure deleteline;
 var
   i : integer;
 begin
   delline;

   if highestline > currentline +(23 - screenline) then
      quick_display(1,22,linebuffer [currentline +(23 - screenline)]^);

   if linebuffer[currentline] <> emptyline then
      linebuffer[currentline]^ := emptyline^;

   for i := currentline to highestline + 1 do
      linebuffer[i] := linebuffer [i + 1];

   linebuffer [highestline+2] := emptyline;
   highestline := highestline - 1;

   if currentline > highestline then
      highestline := currentline;
 end;

 procedure cursorleft;
 begin
   column := column - 1;

   if column < 1 then begin
      cursorup;
      funcend;
   end
 end;

 procedure cursorright;
 begin
   column := column + 1;

   if column > 79 then begin
      cursordown;
      column := 1;
   end;
 end;

 procedure ins;
 begin
   if insertmode then
      insertmode := false
   else
      insertmode := true;

   full_screen;
   gotoxy(1,1);

   if insertmode then
      write('Insert ')
   else
      write(replicate (7, 205));

   edit_win;
 end;

 procedure del;
 begin
   if (column > length(linebuffer[currentline]^)) then begin
      if (length(linebuffer[currentline]^) +
          length(linebuffer[currentline+1]^)) < 80 then begin
         linebuffer[currentline]^ := linebuffer[currentline]^ +
                                     linebuffer[currentline+1]^;

         quick_display(1,screenline,linebuffer [currentline]^);
         cursordown;
         deleteline;
         cursorup;
      end;
      exit;
   end;

   if linebuffer[currentline] = emptyline then begin
      newbuffer(linebuffer[currentline]);
      linebuffer[currentline]^ := '';
   end;

   while length(linebuffer[currentline]^) < column do
      linebuffer[currentline]^ := linebuffer[currentline]^ + ' ';

   delete(linebuffer [currentline]^, column, 1);

   gotoxy(1,screenline);
   clreol;
   quick_display(1,screenline,linebuffer [currentline]^)
 end;

 procedure backspace;
 begin
   if column > 1 then
      column := column - 1
   else begin
      cursorup;
      funcend;
      del;
   end;
 end;

 procedure terminate;
 var
   i:integer;
 begin
   full_screen;
   gotoxy(1, 25);
   clreol;
   gotoxy(1, 24);
   clreol;
   write('      Writing...');

   rewrite(textfile);
   for i := 1 to highestline + 1 do begin
      if (i mod 100) = 0 then
         write(#13,i);

      writeln(textfile, linebuffer [i]^);
   end;

   write(#13,i);
   writeln(textfile,^Z);
   close(textfile);
   write(#13);
   clreol;
   halt;
 end;

 procedure quitnosave;
 begin
   full_screen;
   gotoxy(1, 25);
   clreol;
   gotoxy(1, 24);
   clreol;
   halt;
 end;

 procedure funcpgup;
 begin
   currentline := currentline - 20;
   if currentline <= screenline then
      beginfile
   else
      drawscreen;
 end;

 procedure funcpgdn;
 begin
   currentline := currentline + 20;
   if currentline+12 >= highestline then
      endfile
   else
      drawscreen;
 end;

 procedure prevword;
 begin
(* if i am in a word then skip to the space *)
   while (not ((linebuffer[currentline]^[column] = ' ') or
               (column >= length(linebuffer[currentline]^) ))) and
         ((currentline <> 1) or
          (column <> 1)) do
      cursorleft;

(* find end of previous word *)
   while ((linebuffer[currentline]^[column] = ' ') or
          (column >= length(linebuffer[currentline]^) )) and
         ((currentline <> 1) or
          (column <> 1)) do
      cursorleft;

(* find start of previous word *)
   while (not ((linebuffer[currentline]^[column] = ' ') or
               (column >= length(linebuffer[currentline]^) ))) and
         ((currentline <> 1) or
          (column <> 1)) do
      cursorleft;

   cursorright;
 end;

 procedure nextword;
 begin
(* if i am in a word, then move to the whitespace *)
   while (not ((linebuffer[currentline]^[column] = ' ') or
               (column >= length(linebuffer[currentline]^)))) and
         (currentline < highestline) do
      cursorright;

(* skip over the space to the other word *)
   while ((linebuffer[currentline]^[column] = ' ') or
          (column >= length(linebuffer[currentline]^))) and
         (currentline < highestline) do
      cursorright;
 end;

 procedure tab;
 begin
   if column < 79 then begin
      repeat
         column := column + 1;
      until (tabset [column]= true) or (column = 79);
   end;
 end;

 procedure backtab;
 begin
   if column > 1 then begin
      repeat
         column := column - 1;
      until (tabset [column]= true) or (column = 1);
   end;
 end;

 procedure esc;
 begin
   column := 1;
   gotoxy(1, wherey);
   clreol;

   if (linebuffer[currentline] <> emptyline) then
      linebuffer[currentline]^ := emptyline^;

   linebuffer[currentline] := emptyline;
 end;

 procedure locate;
 var
   temp:               linestring;
   i,
   pointer,
   position,
   len:                integer;
 begin
   init_msgline;
   write('Locate:     Enter string: <',searchstring,'> ');
   temp := '';
   readln(temp);
   if temp <> '' then
      searchstring := temp;
   len := length (searchstring);

   if len = 0 then begin
      displaykeys;
      beginfile;
      exit;
   end;

   clrscr;
   write('Searching...  Press <ESC> to exit, <HOLD> to pause');
   edit_win;
   clrscr;

   for i := 1 to highestline do begin
   (* look for matches on this line *)
      pointer := pos (searchstring, linebuffer [i]^);

    (* if there was a match then get ready to print it *)
      if (pointer > 0) then begin
         temp := linebuffer [i]^;
         position := pointer;
         gotoxy(1, wherey);
         lowvideo;
         write(copy(temp,1,79));
         highvideo;

         (* print all of the matches on this line *)
         while pointer > 0 do begin
            gotoxy(position, wherey);
            write(copy (temp, pointer, len));
            temp := copy (temp, pointer + len + 1, 128);
            pointer := pos (searchstring, temp);
            position := position + pointer + len;
         end;

         (* go to next line and keep searching *)
         writeln;
      end;
   end;

   ShowMessage('End of locate.  Press any key to exit...');

   beginfile;
 end;

 procedure search;
 var
   temp:               linestring;
   i,
   pointer,
   len:                integer;
 begin
   init_msgline;
   write('Search:     Enter string: <',searchstring,'> ');
   temp := '';
   readln(temp);
   if temp <> '' then
      searchstring := temp;
   len := length (searchstring);

   if len = 0 then begin
      displaykeys;
      beginfile;
      exit;
   end;

   clrscr;
   write('Searching...');
   edit_win;

   for i := currentline+1 to highestline do begin
   (* look for matches on this line *)
      pointer := pos (searchstring, linebuffer [i]^);

    (* if there was a match then get ready to print it *)
      if (pointer > 0) then begin
         currentline := i;
         if currentline >= 12 then
            screenline := 12
         else
            screenline := currentline;

         drawscreen;
         column := pointer;
         displaykeys;
         exit;
      end;
   end;

   ShowMessage('Search string not found.  Press any key to exit...');
 end;

 procedure replace;
 var
   temp:               linestring;
   position,
   line,
   len:                integer;
   choice:             char;
 begin
   init_msgline;
   write('Replace:     Enter search string: <',searchstring,'> ');
   temp := '';
   readln(temp);
   if temp <> '' then
      searchstring := temp;

   len := length (searchstring);
   if len = 0 then begin
      displaykeys;
      exit;
   end;

   clrscr;          { clear the message line }
   write('Replace:     Enter replacement string: <',replacement,'> ');
   temp := '';
   readln(temp);
   if temp <> '' then
      replacement := temp;
   len := length (replacement);

   clrscr;          { clear the message line }
   write('Searching...');
   edit_win;
   clrscr;

   for line := 1 to highestline do begin
      position := pos (searchstring, linebuffer [line]^);

      while (position > 0) do begin
         currentline := line;
         if currentline >= 12 then
            screenline := 12
         else
            screenline := currentline;

         drawscreen;
         column := position;
         lowvideo;
         gotoxy(column,screenline);
         write(column,screenline,searchstring);
         highvideo;

         init_msgline;
         write('Replace (Y/N/ESC)? ');
         choice := readkey;

         if ord (choice)= 27 then begin
            displaykeys;
            beginfile;
            exit;
         end;

         clrscr;
         write('Searching...');
         edit_win;
         gotoxy(1,line);

         if choice in ['y','Y'] then begin
            linebuffer[line]^ := copy (linebuffer [line]^, 1, position - 1) +
                                   replacement +
                                   copy (linebuffer [line]^, position +
                                           length (searchstring), 128);

            position := pos (searchstring, copy (linebuffer[line]^,
                                position + len + 1,128)) +
                            position + len;
         end else
            position := pos (searchstring, copy (linebuffer[line]^,
                               position + length(searchstring) + 1,128)) +
                          position + length(searchstring);

         gotoxy(1,screenline);
         clreol;
         write(copy(linebuffer[currentline]^,1,79));
      end;
   end;

   ShowMessage('End of replace.  Press any key to exit...');
 end;

 procedure handlefunc(keynum:integer);
 begin
   case keynum of
      8:  backspace;
      9:  tab;
     13:  enter;
     27:  esc;
    271:  backtab;
    315:  help;
    316:  locate;
    317:  search;
    318:  replace;
    319:  terminate;
    320:  insertline;
    321:  deleteline;
    324:  quitnosave;
    327:  column := 1;
    328:  cursorup;
    329:  funcpgup;
    331:  cursorleft;
    333:  cursorright;
    335:  funcend;
    336:  cursordown;
    338:  ins;
    339:  del;
    337:  funcpgdn;
    371:  prevword;
    372:  nextword;
    374:  endfile;
    388:  beginfile;

    else  begin
             sound(200);
             delay(300);
             nosound;
          end;
   end;
 end;

(* main *)

var
  key : integer;
  iscommand : boolean;
 begin
   if (paramcount <> 1) then
   begin
      writeln('Usage:  qed FILENAME');
      halt;
   end;

   initialize;
   loadfile(paramstr (1));
   printrow;

(* main loop - get a key and process it *)

   repeat
      gotoxy(column, screenline);

      getkey (key, iscommand);
      if iscommand then
            handlefunc(key)
      else
            character(chr(key));

      printrow;

   until true = false;
 end.
