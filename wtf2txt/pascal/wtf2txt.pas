program wtf2txt;

uses crt;

var
  wtf,txt: file of byte; {pliki deklarujemy jako skladajace sie z bajtow
                         i o tyle czytamy}
  bufor: byte; //bufor do ktorego czytamy zawartosc pliku
  i,j,len,lenstr,numer: integer; {i,j to do forow, len to ilosc linii,
                                 lenstr to dlugosc linii, numer to jej numer}
  numerstr: string; {uzyte do konwersji numeru linii na lancuch ascii
                     zeby to sobie zapisac w outpucie}

BEGIN

  assign(wtf,'c:\plik.wtf'); //przypisujemy pliki do sciezek i je otwieramy
  reset(wtf);
  assign(txt,'c:\plik.txt');
  rewrite(txt);

  seek(wtf,$18);  //idziemy do offsetu w .wtf liczonego od 0, 0x18
  read(wtf,bufor); {czytamy sobie podwojna liczbe, liczba calkowita
                   linii = len}
  len:= bufor;
  read(wtf,bufor);
  len:=len+bufor shl 8; {shl to przesuniecie wartosci w lewo o dana ilosc
                        bitow, x shl 8 = x *FF, to jest po to by bylo
                        parami od tylu czytane}

  seek(wtf,$1C);  //idziemy do offsetu wlasciwego, 0x1c

  for j:=1 to len do  //czytamy tyle razy ile jest linii
  begin
    read(wtf,bufor); //czytamy pierwsze 2 bajty jako numer linii
    numer:= bufor;
    read(wtf,bufor);
    numer:=numer+bufor shl 8;

    read(wtf,bufor); //czytamy nast. 2 bajty jako dl. linii = lenstr
    lenstr:= bufor;
    read(wtf,bufor);
    lenstr:=lenstr+bufor shl 8;
    str(numer,numerstr); //konwersja numeru z liczby int na string
    for i:=1 to byte(numerstr[0]) do write(txt,byte(numerstr[i]));
    {w stringu na pozycji 0 zawsze jest podany rozmiar, od 1 zaczyna sie
    str wlasciwy, for do pisania kolejnych cyfr numeru}

    write(txt,32); //po numerze spacja zeby oddzielic nr od linii

    for i:=1 to lenstr do  {czytaj i zapisz kolejne bajty przez dlugosc
                           linii = lenstr}
    begin
      read(wtf,bufor);
      write(txt,bufor xor $CA); //oczywiscie z odpowiednim xorem
    end;

    write(txt,13,10); // NL CR

  end;

close(txt);  //zamykamy pliki
close(wtf);
readkey;   //czekamy na nacisniecie klawisza
END.

