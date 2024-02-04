Program teste;

type
	TString = string[80];

var 
	frase: TString;
	i: byte;
	Found: boolean;

Function DifferentPos(Character: char; Phrase: TString): byte;

(* Used only into AlignText procedure. *)

begin
    i := 0;
    Found := false;

    repeat
		i := i + 1;
        if Phrase[i] <> Character then
        begin
            DifferentPos := i;
            Found := true;
        end;
    until (Found) or (i >= length(Phrase));

    if Not Found then DifferentPos := 0;
end;

(*  Finds the last occurence of a char which is different into a string. *)

Function RDifferentPos(Character: char; Phrase: TString): integer;

(* Used only into AlignText procedure. *)
    
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

begin
	frase := '     1  Alessandro Bezerra';
	writeln(frase);
	writeln(length(frase));
	writeln(' DifferentPos - espaco: ',  DifferentPos (#32, frase));
	writeln('RDifferentPos - espaco: ', RDifferentPos (#32, frase));
end.
