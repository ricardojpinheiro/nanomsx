program teste;
type 
    linestring = string[255];
var
    S: linestring;
    a, b, c, d: integer;

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

begin
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
end.
