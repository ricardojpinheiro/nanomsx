(*  Finds the n-th occurence of a char which is into a string. *)
(*
Function NPos(SearchPhrase, Phrase: TString; Ntuple: byte): byte;
var
    HowManyPos, ResultPos, counter, LengthPhrase, 
    LengthSearchPhrase: byte;
    temp: TString;

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

