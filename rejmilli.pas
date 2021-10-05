
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

(* Here we use MSX-DOS 2 to do the error handling. *)
{
function ErrorCode (ExitsOrNot: boolean): linestring;
var
    ErrorCodeNumber: byte;
    ErrorMessage: TMSXDOSString;
    
begin
    ErrorCodeNumber := GetLastErrorCode;
    GetErrorMessage (ErrorCodeNumber, ErrorMessage);
    ErrorCode := ErrorMessage;
    if ExitsOrNot = true then
        Exit;
end;
}

