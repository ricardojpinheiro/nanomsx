program teste;

{$i defs.inc}
{$i fastwrit.inc}

type 
    linestring = string[255];
    
var
    St: linestring;

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

begin
    FillChar(St, sizeof(St), chr(32));
    St := ' F   U   D   E   B   A   .   X';
    
    FastWrite(St);
end.
