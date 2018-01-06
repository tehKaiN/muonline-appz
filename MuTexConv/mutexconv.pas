program multikonwerter;

{$RESOURCE kain.res}
                                       {bmp4, jpg24, tga4}

var
  sciezka1, sciezka2: string;
  plik1, plik2: file of byte;
  i, j, bufor: byte;

procedure encrypt(ilosc: byte;ext: string); {dodaje okreslona ilosc
                                            bajtow z przodu pliku}
begin
  for j:=0 to 2 do sciezka2[i-j]:=ext[3-j]; {zmieniamy rozszerzenie
                                            w sciezce 2}
  assign(plik2,sciezka2);
  rewrite(plik2);

  for i:=1 to ilosc do
  begin
    read(plik1,bufor);
    write(plik2,bufor); {przepisujemy okreslona w parametrze ilosc bajtow
                        z poczatku pliku}
  end;

  reset(plik1); {i czytamy plik od nowa zeby napisac je jeszcze raz}

  repeat
    read(plik1,bufor); {i teraz dalej czytamy}
    write(plik2,bufor); {i zapisujemy}
  until eof(plik1); {az do konca pliku}
end;

procedure decrypt(ilosc: byte;ext: string); {omija okreslona ilosc
                                                     bajtow z przodu pliku}
begin
  for j:=0 to 2 do sciezka2[i-j]:=ext[3-j]; {zmieniamy rozszerzenie
                                            w sciezce 2}
  assign(plik2,sciezka2);
  rewrite(plik2);
  seek(plik1,ilosc); {omija pierwsze bajty ktore sa powtorzone}
  repeat
    read(plik1,bufor); {reszte czytamy}
    write(plik2,bufor); {i zapisujemy}
  until eof(plik1); {poki nie dojdziemy do konca pliku}
end;

BEGIN

  if paramstr(1) = '' then
  begin
    writeln('Sciezka pliku do konwersji (ozb, ozj, ozt, bmp, jpg, tga): ');
    readln(sciezka1);
  end
  else sciezka1:=paramstr(1);

  assign(plik1,sciezka1);
  {$I-}reset(plik1);{$I+}
  if (IOResult <> 0) or (sciezka1 = '') then
  begin
    writeln('Nieprawidlowa sciezka');
    halt;
  end;

  sciezka2:=sciezka1; {sciezka drugiego pliku jest taka sama}
  i:= length(sciezka2); {liczymy dlugosc sciezki do sprawdzenia rozszerzenia}

  case upcase(sciezka1[i]) of
    'P': encrypt(4,'ozb'); {jak rozszerzenie to bmP to robimy bmp->ozb}
    'B': decrypt(4,'bmp'); {jaka ozB to ozb->bmp}
    'J': decrypt(24,'jpg'); {jak ozJ to ozj->jpg}
    'G': encrypt(24,'ozj'); {jak jpG to jpg->ozj}
    'T': decrypt(4,'tga'); {jak ozT to ozt->tga}
    'A': encrypt(4,'ozt'); {jak tgA to tga->ozt}
  end;

  writeln('Zrobione');
  close(plik1); {zamykamy odczyt plikow}
  close(plik2);
END.

