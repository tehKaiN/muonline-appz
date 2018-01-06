{$APPTYPE GUI}
{$r menu.res}
{$r bmpheads.res}
program MuMapEdit;

uses
  Windows,
  Messages,
  Strings;

type
  TPos = packed record
             x: longint;
             y: longint;
           end;
  TTex = record
           handle: hBitmap;
           szer: word;
           wys: word;
           hThumb: hBitmap;
           substc: longint;
         end;
var
  /////////////////////////////////////////////////zmienne do okna glownego
  Wnd: WndClass; //klasa okna glownego
  wymiaryokna: RECT; //wymiary okna glownego bez belki gornej itd.
  WspRect: RECT; //pole odswiezane przy odmalowaniu wspolrzednych
  hOkna: HWND; // uchwyt do okna
  hdcOkna: HDC; // uchwyt do rysowania po oknie
  TextProp: TEXTMETRIC;

  ///////////////////////////////////////////////////////zmienne do planszy
  plansza: WndClass;  // klasa okna planszy
  hPlanszy: HWND; // uchwyt do okna planszy
  hdcPlanszy: HDC; // uchwyt do rysowania po planszy
  szerPlanszy,wysPlanszy: word; //mierzona w ilosci pol
  kp,wp,kk,wk: byte; {numery pol poczatkowych i koncowych aktualnie
                      wyswietlanych na planszy}
  skala: byte = 64; //dlugosc boku pola w pikselach i wartosc domyslna
  pozycja: TPos; //aktualne x i y na mapie
  xscroll,yscroll : longint; //wymiary x i y suwaka
  war: byte; //obecnie wyswietlana warstwa na planszy
  RefPole: RECT; //pole wymagane do odswiezania przy rysowaniu

  //////////////////////////////////////////////////////operacje na plikach
  hPlik: HWND; //uchwyt do okna
  przeczyt:LongWord;  //ilosc przeczytanych/zapisanych bajtow podczas operacji
  otworz,zapisz: OPENFILENAME; //dane do dialogow otworz/zapisz plik
  folder: BROWSEINFO; //dane do dialogu wybierania katalogu
  FilePath: array [0..MAX_PATH] of char; {sciezka do czytanego/zapisywanego
                                          pliku}
  WorldPath: array [0..MAX_PATH] of char; //sciezka do folderu z worldem
  przesuw: integer; //offset do czytania niektorych plikow
  tempdir: pchar; //sciezka do folderu tymczasowego
  znaleziony: win32_find_data; //dane znalezionych po wyszukiwaniu plikow

  ////////////////////////////////////////////////////////////////dane mapy
  MAP: array [0..7,0..255,0..255] of byte; {wartosci warstw, uporzadkowanie:
                                            warstwa,x,y}
  tekstury: array [0..$0E] of TTex; {tablica z uchwytami do tekstur,
                                     ostatnia dla nieprawidlowych wartosci}

  //////////////////////////////////////////////////////////kontrolka RYSUJ
  rysuj: boolean; //rysujemy albo nie
  hPrzycisk: HWND; //uchwyt do przycisku rysuj

  //////////////////////////////////////////////////////////kontrolka SKALA
  hSkala: HWND; // uchwyt do comboboxa skali

  ////////////////////////////////////////////////////////kontrolka WARSTWA
  hWar: HWND; //uchwyt do comboboxa warstw

  /////////////////////////////////////////////////kontrolka WYBOR TEKSTURY
  hSelTex: HWND; //uchwyt do okna wyboru
  SelTex: WndClass; //klasa okna wyboru
  hdcSelTex: HDC; //uchwyt do rysowania po oknie wyboru
  valSelTex: byte; //wybrana przez uzytkownika tekstura

  /////////////////////////////////////////////kontrolka WARTOSC POJEDYNCZA
  hSel1: HWND;  //uchwyt do okna wpisywania wartosci
  sSel1: string; //lancuch przechowujacy tymczasowo wartosc z pola hSel1
  dSel1: word;  {wartosc liczbowa otrzymana z konwersji sSel1. Typ word
                 dla sprawdzania przekroczenia dozwolonych wartosci}

  ////////////////////////////////////////////////////////////////////ROZNE
  Msg: TMsg;
  w,k: byte;
  ps: PAINTSTRUCT;
  bufor: PCHAR = '';
  defPen,polePen: HPEN;
  defBrush,poleBrush: HBRUSH;
  hbmOld: HBITMAP; // poprzednia, domyslna wartosc bitmapy dla hdcNowy
  hdcNowy: HDC; // uchwyt dla bitmapy przy BitBlt
  BelkaMenu: HMENU; //uchwyt do belki gornego menu
  i,tex:byte;

  nazwy: array [$00..$12] of pchar = ('\TileGrass01.bmp',
                                      '\TileGrass02.bmp',
                                      '\TileGround01.bmp',
                                      '\TileGround02.bmp',
                                      '\TileGround03.bmp',
                                      '\TileWater01.bmp',
                                      '\TileWood01.bmp',
                                      '\TileRock01.bmp',
                                      '\TileRock02.bmp',
                                      '\TileRock03.bmp',
                                      '\TileRock04.bmp',
                                      '\TileRock05.bmp',
                                      '\TileRock06.bmp',
                                      '\TileRock07.bmp',
                                      '\borken.bmp',
                                      '\Terrain.map',
                                      '\Terrain.att',
                                      '\TerrainHeight.ozb',
                                      '\TerrainLight.bmp');

procedure loadtex(nr: byte; src: pchar);
var
  sciezka: pchar;
  info: bitmap;
begin
  sciezka:=stralloc(max_path);
  strmove(sciezka,tempdir,max_path);
  strcat(sciezka,nazwy[nr]);

  if src <> '' then
    begin
      deletefile(sciezka);
      copyfile(src,sciezka,false);
    end;
  with tekstury[nr] do
    begin
      handle:= loadimage(0,sciezka,IMAGE_BITMAP,0,0,LR_LOADFROMFILE);
      if handle <> 0 then
        begin
          hThumb:= loadimage(0,sciezka,IMAGE_BITMAP,48,48,LR_LOADFROMFILE);
          GetObject(handle,sizeof(info),@info);
          szer:= info.bmWidth;
          wys:= info.bmHeight;
          if skala <> 64 then
            begin
              handle:= loadimage(0,sciezka,IMAGE_BITMAP,szer div 64 * skala, wys div 64 * skala,LR_LOADFROMFILE);
              GetObject(handle,sizeof(info),@info);
              szer:= info.bmWidth;
              wys:= info.bmHeight;
            end;
        end
      else hThumb:=0;
    end;
end;

procedure PrepOpen(listatypow,rozszerzenie:pchar);
begin
  fillchar(otworz,sizeof(otworz),0);
  with otworz do
    begin
      lstructsize:=sizeof(TOPENFILENAME);
      lpstrFilter:= listatypow;
      nMaxFile:= MAX_PATH;
      lpstrFile:= pchar(FilePath);
      lpstrDefExt:= rozszerzenie;
      flags:= ofn_filemustexist or ofn_hidereadonly
    end;
end;

procedure PrepSave(listatypow,rozszerzenie:pchar);
begin
  fillchar(zapisz,sizeof(zapisz),0);
  with zapisz do
    begin
      lstructsize:=sizeof(TOPENFILENAME);
      lpstrFilter:= listatypow;
      nMaxFile:= MAX_PATH;
      lpstrFile:= pchar(FilePath);
      lpstrDefExt:= rozszerzenie;
      flags:= ofn_hidereadonly
    end;
end;

procedure WriteLayer(war: byte);
begin
   for w:=255 downto 0 do //256 wierszy, czytane od tylu
     for k:=0 to 255 do
     begin
       writefile(hPlik,map[war,k,w],1,przeczyt,poverlapped(0));
       if przeczyt = 0 then messagebox(hOkna,'Blad zapisu!','',MB_OK);
     end;
end;

procedure frOpen(src: pchar; defname: byte);
var
  fpath: pchar;
begin
  fpath:=stralloc(max_path);
  strmove(fpath,tempdir,max_path);
  strcat(fpath,nazwy[defname]);

  if src <> '' then
    copyfile(src,fpath,false);

  hPlik:= CreateFile(fpath,generic_read,
           file_share_read,lpsecurity_attributes(0),
           open_always,file_flag_sequential_scan,
           0);
end;


procedure AttMapRead(wmin,wmax,offs: byte);
begin
  if hPlik <> INVALID_HANDLE_VALUE then
  begin
    setfilepointer(hPlik,offs,plong(0),file_begin);
    for i:= wmin to wmax do
     for w:=255 downto 0 do //256 wierszy, czytane od tylu
       for k:=0 to 255 do
       begin
         readfile(hPlik,map[i,k,w],1,przeczyt,poverlapped(0));
         if przeczyt = 0 then
           begin
             messagebox(hOkna,'Blad odczytu!','',MB_OK);
             Closehandle(hPlik);
             exit;
           end;
       end;
    if (war >= wmin) and (war <= wmax) then
      invalidaterect(hPlanszy,lprect(0),true);
  end;
  Closehandle(hPlik);
end;

procedure HeightRead(lwar: byte);
begin
  if hPlik <> INVALID_HANDLE_VALUE then
  begin
    setfilepointer(hPlik,14,plong(0),file_begin);
    //4 dla ominiecia powtorzonych bajtow + 10 dla adresu danych
    readfile(hPlik,przesuw,2,przeczyt,poverlapped(0));
    inc(przesuw,4);
    if przeczyt = 0 then
      begin
        messagebox(hOkna,'Blad odczytu!','',MB_OK);
        Closehandle(hPlik);
        exit;
      end;
    setfilepointer(hPlik,przesuw,plong(0),file_begin);
    for w:=255 downto 0 do //256 wierszy, czytane od tylu
      for k:=0 to 255 do
      begin
        readfile(hPlik,map[lwar,k,w],1,przeczyt,poverlapped(0));
        if przeczyt = 0 then
          begin
            messagebox(hOkna,'Blad odczytu!','',MB_OK);
            Closehandle(hPlik);
            exit;
          end;
      end;
    if war = lwar then
      invalidaterect(hPlanszy,lprect(0),true);
  end;
  Closehandle(hPlik);
end;

procedure LightRead(wmin,wmax: byte);
begin
  if hPlik <> INVALID_HANDLE_VALUE then
  begin
      setfilepointer(hPlik,10,plong(0),file_begin);
      readfile(hPlik,przesuw,2,przeczyt,poverlapped(0));
      if przeczyt = 0 then
      begin
        messagebox(hOkna,'Blad odczytu!','',MB_OK);
        Closehandle(hPlik);
        exit;
      end;
      setfilepointer(hPlik,przesuw,plong(0),file_begin);
      for w:=255 downto 0 do //256 wierszy, czytane od tylu
        for k:=0 to 255 do
          for i:=wmax downto wmin do //zeby BGR obrocic na RGB
          begin
            readfile(hPlik,map[i,k,w],1,przeczyt,poverlapped(0));
            if przeczyt = 0 then
            begin
              messagebox(hOkna,'Blad odczytu!','',MB_OK);
              Closehandle(hPlik);
              exit;
            end;
          end;
      if (war >= wmin) and (war <=wmax) then
        invalidaterect(hPlanszy,lprect(0),true);
  end;
  Closehandle(hPlik);
end;

procedure fwTempOpen(defname: byte);
var
  fpath: pchar;
begin
  fpath:=stralloc(max_path);
  strmove(fpath,tempdir,max_path);
  strcat(fpath,nazwy[defname]);
  hPlik:= CreateFile(fpath,generic_write,
            0,lpsecurity_attributes(0),
            open_existing, file_flag_random_access,
            0);
end;

procedure fwTemp(value: byte;offs: dword);
begin
  setfilepointer(hPlik,offs,plong(0),file_begin);
  WriteFile(hPlik,value,1,przeczyt,poverlapped(0));
  if przeczyt = 0 then
    messagebox(hOkna,'Blad Zapisu!','',mb_ok);
end;

procedure AttMapSave(wmin,wmax: byte; sciezka: pchar; header:shortstring);
begin
  hPlik:= CreateFile(sciezka,generic_write,
            0,lpsecurity_attributes(0),
            create_always, file_flag_sequential_scan,
            0);
  for i:= 1 to byte(header[0]) do
    begin
      writefile(hPlik,header[i],1,przeczyt,poverlapped(0));
      if przeczyt = 0 then
        begin
          messagebox(hOkna,'Blad zapisu!','',MB_OK);
          Closehandle(hPlik);
          exit;
        end;
    end;
  for i:= wmin to wmax do
    for w:=255 downto 0 do //256 wierszy, czytane od tylu
      for k:=0 to 255 do
        begin
          writefile(hPlik,map[i,k,w],1,przeczyt,poverlapped(0));
          if przeczyt = 0 then
            begin
              messagebox(hOkna,'Blad zapisu!','',MB_OK);
              Closehandle(hPlik);
              exit;
            end;
        end;
  Closehandle(hPlik);
end;

procedure BmpWrite(wmin,wmax: byte; sciezka: pchar);
var
  hHeader: LongWord;
begin
  if wmin<> wmax then
    hHeader:= FindResource(hInstance,'RGBHead',RT_RCDATA)
  else
    hHeader:= FindResource(hInstance,'MonoHead',RT_RCDATA);

  hPlik:= CreateFile(sciezka,generic_write,
            0,lpsecurity_attributes(0),
            create_always, file_flag_sequential_scan,
            0);
  writefile(hPlik,LockResource(LoadResource(hInstance,hHeader))^,SizeOfResource(hInstance,hHeader),przeczyt,poverlapped(0));
  if przeczyt <> SizeOfResource(hInstance,hHeader) then
    begin
      messagebox(hOkna,'Blad zapisu!','',MB_OK);
      Closehandle(hPlik);
      exit;
    end;
  for w:= 255 downto 0 do
    for k:= 0 to 255 do
      for i:=wmax downto wmin do
        begin
          writefile(hPlik,map[i,k,w],1,przeczyt,poverlapped(0));
          if przeczyt = 0 then
            begin
              messagebox(hOkna,'Blad zapisu!','',MB_OK);
              Closehandle(hPlik);
              exit;
            end;
        end;

  CloseHandle(hPlik);
end;

procedure odrysujSelTex(nrTex: byte);
begin
  SelectObject(hdcNowy,tekstury[nrTex].hThumb);
  w:=nrTex div 2;
  k:=nrTex mod 2;

  if nrTex = valSelTex then
    begin
      polePen:= createpen(ps_solid,1,RGB(255,0,0));
      defPen:= selectobject(hdcSelTex,polePen);
      if tekstury[nrTex].hthumb = 0 then
        poleBrush:= createsolidbrush(tekstury[nrTex].substc)
      else
        poleBrush:= createpatternbrush(tekstury[nrTex].hThumb);
      defBrush:= selectobject(hdcSelTex,poleBrush);

      rectangle(hdcSelTex,k*48,w*48,k*48+48,w*48+48);

      selectobject(hdcSelTex,defBrush);
      deleteobject(poleBrush);
      selectobject(hdcSelTex,defpen);
      deleteobject(polePen);
    end
  else
    if tekstury[nrTex].hthumb = 0 then
      begin
        polePen:= createpen(ps_solid,1,tekstury[nrTex].substc);
        defPen:= selectobject(hdcSelTex,polePen);
        poleBrush:= createsolidbrush(tekstury[nrTex].substc);
        defBrush:= selectobject(hdcSelTex,poleBrush);

        rectangle(hdcSelTex,k*48,w*48,k*48+48,w*48+48);

        selectobject(hdcSelTex,defBrush);
        deleteobject(poleBrush);
        selectobject(hdcSelTex,defpen);
        deleteobject(polePen);
      end
    else
      BitBlt(hdcSelTex,k*48,w*48,48,48,hdcNowy,0,0,srccopy);

end;


(*******************FUNKCJE SELTEX*******************************************)

function funkcjeSelTex(hSelTex: hwnd; umsg: uint; wpar: wparam; lpar: lparam):lresult; stdcall;
begin
  funkcjeSelTex:=0;
  case uMsg of
    WM_CREATE:
      begin
      end;
    WM_PAINT:
      begin
        hdcSelTex:= beginpaint(hSelTex,ps);
        hdcSelTex:= getdc(hSelTex);
        hdcNowy:= createcompatibleDC(hdcSelTex);
        hbmOld:= SelectObject(hdcNowy,tekstury[0].hThumb);

        for i:= $00 to $0E do
          odrysujSelTex(i);

        SelectObject(hdcNowy,hbmOld);
        deleteDC(hdcNowy);
        releasedc(hSelTex,hdcSelTex);
        endpaint(hSelTex,ps);
      end;
    WM_LBUTTONUP:
      begin
        valSelTex:= loWord(lPar) div 48 + 2* (hiWord(lPar) div 48);
        if valSelTex > $0E then valSelTex:= $0E;
        sendmessage(hSelTex,wm_paint,0,0);
      end;
    else funkcjeSelTex:=defwindowproc(hSeltex,umsg,wpar,lpar);
  end;
end;

(*******************FUNKCJE PLANSZY******************************************)

function funkcjeplanszy(hPlanszy: hwnd; umsg: uint; wpar: wparam; lpar: lparam):lresult; stdcall;
begin
  funkcjeplanszy:=0;
  case uMsg of
    WM_CREATE:
      begin
        setscrollrange(hPlanszy,sb_horz,0,255-szerplanszy+1,true);
        setscrollrange(hPlanszy,sb_vert,0,255-wysplanszy+1,true);
      end;
    WM_SIZE:
      begin
        setscrollrange(hPlanszy,sb_horz,0,255-szerplanszy+1,true);
        setscrollrange(hPlanszy,sb_vert,0,255-wysplanszy+1,true);
      end;
    WM_PAINT:
      begin
        hdcPlanszy:= beginpaint(hPlanszy,ps);
        hdcPlanszy:= getdc(hplanszy);

        if wp+wysplanszy > $FF then wk:= $FF else wk:= wp+wysplanszy;
        if kp+szerplanszy > $FF then kk:= $FF else kk:= kp+szerplanszy;
        case war of
          0,1:                            /////////////TEX 1, 2
            begin
              if war=1 then
              i:=i;
              hdcNowy:= createcompatibleDC(hdcPlanszy);
              hbmOld:= selectobject(hdcNowy,tekstury[0].handle);
              for w:=wp to wk do
                for k:=kp to kk do
                  begin
                    if map[war,k,w] <= $0D then
                      tex:=map[war,k,w]
                    else
                      tex:=$0E;
                    selectobject(hdcnowy,tekstury[tex].handle);

                    if tekstury[tex].handle = 0 then
                      begin
                        polePen:= createpen(ps_solid,1,tekstury[tex].substc);
                        defPen:= selectobject(hdcPlanszy,polePen);
                        poleBrush:= createsolidbrush(tekstury[tex].substc);
                        defBrush:= selectobject(hdcPlanszy,poleBrush);

                        rectangle(hdcPlanszy,(k-kp)*skala,(w-wp)*skala,(k-kp)*skala+skala,(w-wp)*skala+skala);

                        selectobject(hdcPlanszy,defPen);
                        deleteobject(polePen);
                        selectobject(hdcPlanszy,defBrush);
                        deleteobject(poleBrush);
                      end
                    else
                      bitblt(hdcPlanszy,(k-kp)*skala,(w-wp)*skala,skala,skala,hdcnowy,(k mod (tekstury[tex].szer div skala))*skala, (w mod (tekstury[tex].wys div skala))*skala,srccopy);
                  end;
              selectobject(hdcNowy,hbmOld);
              deletedc(hdcNowy);
            end;
          2,4,5,6,7:                      ////TEXATR, SWIATLO R, G, B, HEIGHT
            for w:=wp to wk do
              for k:=kp to kk do
                begin
                  polePen:= createpen(ps_solid,1,RGB(map[war,k,w],map[war,k,w],map[war,k,w]));
                  defPen:= selectobject(hdcPlanszy,polePen);
                  poleBrush:= createsolidbrush(RGB(map[war,k,w],map[war,k,w],map[war,k,w]));
                  defBrush:= selectobject(hdcPlanszy,poleBrush);

                  rectangle(hdcPlanszy,(k-kp)*skala,(w-wp)*skala,(k-kp)*skala+skala,(w-wp)*skala+skala);

                  selectobject(hdcPlanszy,defPen);
                  deleteobject(polePen);
                  selectobject(hdcPlanszy,defBrush);
                  deleteobject(poleBrush);
                end;
          3:                              /////////////ATT
            for w:=wp to wk do
              for k:=kp to kk do
                begin
                  polePen:= createpen(ps_solid,1,RGB(map[war,k,w]*20,map[war,k,w]*20,map[war,k,w]*20));
                  defPen:= selectobject(hdcPlanszy,polePen);
                  poleBrush:= createsolidbrush(RGB(map[war,k,w]*20,map[war,k,w]*20,map[war,k,w]*20));
                  defBrush:= selectobject(hdcPlanszy,poleBrush);

                  rectangle(hdcPlanszy,(k-kp)*skala,(w-wp)*skala,(k-kp)*skala+skala,(w-wp)*skala+skala);

                  selectobject(hdcPlanszy,defPen);
                  deleteobject(polePen);
                  selectobject(hdcPlanszy,defBrush);
                  deleteobject(poleBrush);
                end;
          8:                              //////SWIATLO RGB
            for w:=wp to wk do
              for k:=kp to kk do
                begin
                  polePen:= createpen(ps_solid,1,RGB(map[4,k,w],map[5,k,w],map[6,k,w]));
                  defPen:= selectobject(hdcPlanszy,polePen);
                  poleBrush:= createsolidbrush(RGB(map[4,k,w],map[5,k,w],map[6,k,w]));
                  defBrush:= selectobject(hdcPlanszy,poleBrush);

                  rectangle(hdcPlanszy,(k-kp)*skala,(w-wp)*skala,(k-kp)*skala+skala,(w-wp)*skala+skala);

                  selectobject(hdcPlanszy,defPen);
                  deleteobject(polePen);
                  selectobject(hdcPlanszy,defBrush);
                  deleteobject(poleBrush);
                end;
        end;

        releasedc(hplanszy,hdcPlanszy);
        endpaint(hplanszy,ps);
      end;
    WM_HSCROLL:
      begin
        case wpar of
          sb_lineleft:
            begin
              if kp > 0 then dec(kp);
              setscrollpos(hPlanszy,sb_horz,kp,true);
              invalidaterect(hPlanszy,lprect(0),true);
            end;
          sb_lineright:
            begin
              if kp <= $FF-szerplanszy then inc(kp);
              setscrollpos(hPlanszy,sb_horz,kp,true);
              invalidaterect(hPlanszy,lprect(0),true);
            end;
          sb_pageright:
            begin
              if kp <= $FF-szerplanszy+1 then kp:=kp+szerplanszy
              else kp:=$FF-szerplanszy+1;
              setscrollpos(hPlanszy,sb_horz,kp,true);
              invalidaterect(hPlanszy,lprect(0),true);
            end;
          sb_pageleft:
            begin
              if kp >szerplanszy then kp:=kp-szerplanszy
              else kp:=0;
              setscrollpos(hPlanszy,sb_horz,kp,true);
              invalidaterect(hPlanszy,lprect(0),true);
            end;
        end;
      end;
    WM_VSCROLL:
      begin
        case wpar of
          sb_lineup:
            begin
              if wp > 0 then dec(wp);
              setscrollpos(hPlanszy,sb_vert,wp,true);
              invalidaterect(hPlanszy,lprect(0),true);
            end;
          sb_linedown:
            begin
              if wp <= $FF-wysplanszy then inc(wp);
              setscrollpos(hPlanszy,sb_vert,wp,true);
              invalidaterect(hPlanszy,lprect(0),true);
            end;
          sb_pageup:
            begin
              if wp > wysplanszy then wp:=wp-wysplanszy
              else wp:=0;
              setscrollpos(hPlanszy,sb_vert,wp,true);
              invalidaterect(hPlanszy,lprect(0),true);
            end;
          sb_pagedown:
            begin
              if wp <= $FF-wysplanszy+1 then wp:=wp+wysplanszy
              else wp:=$FF - wysplanszy+1;
              setscrollpos(hPlanszy,sb_vert,wp,true);
              invalidaterect(hPlanszy,lprect(0),true);
            end;
        end;
      end;
    WM_MOUSEMOVE:
      begin
        if loword(lpar) div skala +kp <= $FF then
          pozycja.x:= loword(lpar) div skala +kp;
        if (hiword(lpar) div skala +wp) <= $FF then
          pozycja.y:= (hiword(lpar) div skala +wp) xor $FF;
        wvsprintf(bufor,'x: %d, y: %d',@pozycja);
        invalidaterect(hOkna,@wspRect,true);

        if rysuj and (wpar = mk_lbutton) then
          begin
            case war of
              0,1:
                if map[war,pozycja.x,pozycja.y xor $FF] <> valSelTex then
                  begin
                    map[war,pozycja.x,pozycja.y xor $FF]:= valSelTex;
                    with RefPole do
                      begin
                        left:= (LoWord(lpar) div skala) * skala;
                        right:= left+skala;
                        top:= (HiWord(lpar) div skala) * skala;
                        bottom:= top+skala;
                      end;
                    fwTemp(valSelTex,1+(war shl 16) + pozycja.x + (pozycja.y shl 8));
                    invalidaterect(hPlanszy,RefPole,true);
                  end;


              2,4,5,6,7:
                begin
                  fillchar(sSel1,256,0);
                  sSel1[0]:= char(getwindowtext(hSel1,@sSel1[1],getwindowtextlength(hSel1)+1));
                  val(sSel1,dSel1,i);
                  if dSel1 > $FF then
                    begin
                      dSel1:= $FF;
                      str(dSel1,sSel1);
                      SetWindowText(hSel1,@sSel1[1]);
                    end;
                  if map[war,pozycja.x,pozycja.y xor $FF] <> dSel1 then
                    begin
                      map[war,pozycja.x, pozycja.y xor $FF]:= dSel1;
                      case war of
                        2: fwTemp(dSel1,1+(war shl 16) + pozycja.x + (pozycja.y shl 8));
                        4,5,6: fwTemp(dSel1,54+((pozycja.x*3)+2-(war-4))+(pozycja.y*3) shl 8);
                        7: fwTemp(dSel1,1082+pozycja.x+(pozycja.y shl 8));
                      end;
                      with RefPole do
                        begin
                          left:= (LoWord(lpar) div skala) * skala;
                          right:= left+skala;
                          top:= (HiWord(lpar) div skala) * skala;
                          bottom:= top+skala;
                        end;
                      invalidaterect(hPlanszy,RefPole,true);
                    end;
                end;
            end;
          end;
      end;
    WM_LBUTTONDOWN:
      begin
        if rysuj then
          case war of
            0,1:
              begin
                fwTempOpen($0F);
                if map[war,pozycja.x,pozycja.y xor $FF] <> valSelTex then
                  begin
                    map[war,pozycja.x,pozycja.y xor $FF]:= valSelTex;
                    with RefPole do
                      begin
                        left:= (LoWord(lpar) div skala) * skala;
                        right:= left+skala;
                        top:= (HiWord(lpar) div skala) * skala;
                        bottom:= top+skala;
                      end;
                    fwTemp(valSelTex,1+(war shl 16) + pozycja.x + (pozycja.y shl 8));
                    invalidaterect(hPlanszy,RefPole,true);
                  end;
                end;

            2,4,5,6,7:
              begin
                case war of
                  2: fwTempOpen($0F);
                  4,5,6: fwTempOpen($12);
                  7: fwTempOpen($11);
                end;
                fillchar(sSel1,256,0);
                sSel1[0]:= char(getwindowtext(hSel1,@sSel1[1],getwindowtextlength(hSel1)+1));
                val(sSel1,dSel1,i);
                if dSel1 > $FF then
                  begin
                    dSel1:= $FF;
                    str(dSel1,sSel1);
                    SetWindowText(hSel1,@sSel1[1]);
                  end;
                if map[war,pozycja.x,pozycja.y xor $FF] <> dSel1 then
                  begin
                    map[war,pozycja.x, pozycja.y xor $FF]:= dSel1;
                    case war of
                      2: fwTemp(dSel1,1+(war shl 16) + pozycja.x + (pozycja.y shl 8));
                      4,5,6: fwTemp(dSel1,54+((pozycja.x*3)+2-(war-4))+(pozycja.y*3) shl 8);
                      7: fwTemp(dSel1,1082+pozycja.x+(pozycja.y shl 8));
                    end;
                    with RefPole do
                      begin
                        left:= LoWord(lpar);
                        right:= left+skala;
                        top:= HiWord(lpar);
                        bottom:= top+skala;
                      end;
                    invalidaterect(hPlanszy,RefPole,true);
                  end;
              end;
          end;
      end;
    WM_LBUTTONUP:
      closehandle(hPlik);
    else funkcjeplanszy:=defwindowproc(hplanszy,umsg,wpar,lpar);
  end;
end;

(***************FUNKCJE OKNA*************************************************)

function FunkcjeOkna(hOkna: HWND; uMsg: UINT; wPar: WPARAM; lPar: LPARAM): LRESULT; stdcall;
begin
  funkcjeokna := 0;
  case uMsg of
    WM_DESTROY: PostQuitMessage(0);

    WM_PAINT:
      begin
        hdcOkna:= beginpaint(hOkna,ps);
        case war of
          0,1:
            begin
              showwindow(hSelTex,sw_show);
              showwindow(hSel1,sw_hide);
            end;
          2,4,5,6,7:
            begin
              showwindow(hSel1,sw_show);
              showwindow(hSelTex,sw_hide);
            end;
          else
            begin
              showwindow(hSel1,sw_hide);
              showwindow(hSelTex,sw_hide);
            end;
        end;

        setbkmode(hdcOkna,transparent);
        textout(hdcOkna,5,wymiaryokna.bottom-20,bufor,length(bufor));

        endpaint(hOkna,ps);
      end;

    WM_CREATE:
      begin
        hdcOkna:= getdc(hOkna);
        GetTextMetrics(hdcOkna,@TextProp);
        releasedc(hOkna,hdcOkna);

        tempdir:=stralloc(max_path);
        getcurrentdirectory(max_path,tempdir);
        strcat(tempdir,pchar('\MuMapEditTMP'));
        createdirectory(tempdir,lpsecurity_attributes(0));
        xscroll:= getsystemmetrics(sm_cxhthumb)+getsystemmetrics(sm_cxedge);
        yscroll:= getsystemmetrics(sm_cyvthumb)+getsystemmetrics(sm_cyedge);
        getclientrect(hOkna,wymiaryokna);

        with wspRect do
        begin
          left:=5;
          right:=100;
          top:=wymiaryokna.bottom-20;
          bottom:=top + TextProp.tmHeight;
        end;
        szerPlanszy:= (wymiaryokna.right-100-xscroll) div skala;
        wysPlanszy:= (wymiaryokna.bottom-yscroll) div skala;
        hPlanszy:= CreateWindow('Plansza','',
                     WS_CHILD or WS_VISIBLE or WS_BORDER or
                     WS_HSCROLL or WS_VSCROLL,
                     100,0,
                     wymiaryokna.right-100, wymiaryokna.bottom,
                     hOkna,1,hInstance,nil);
        hSkala:= CreateWindow('COMBOBOX','',
                   WS_CHILD or WS_VISIBLE or WS_BORDER or
                   CBS_DROPDOWNLIST,
                   1,wymiaryokna.bottom-50,
                   98,200,
                   hOkna,50,hInstance,nil);
        hWar:= CreateWindow('COMBOBOX','',
                   WS_CHILD or WS_VISIBLE or WS_BORDER or
                   CBS_DROPDOWNLIST,
                   1,wymiaryokna.bottom-80,
                   98,200,
                   hOkna,100,hinstance,nil);
        hPrzycisk:= Createwindow('BUTTON','Rysuj',
                      WS_CHILD or WS_VISIBLE or BS_CHECKBOX,
                      1,0,
                      98,TextProp.tmHeight+6,
                      hOkna,150,hInstance,nil);
        hSelTex:= Createwindow('Seltex','',
                    WS_CHILD or WS_BORDER,
                    1,20,
                    98,386,
                    hOkna,2,hInstance,nil);
        hSel1:= Createwindow('EDIT','',
                    WS_CHILD or WS_BORDER,
                    1,20,
                    TextProp.tmMaxCharWidth*3+6,TextProp.tmHeight+6,
                    hOkna,2,hInstance,nil);

        sendmessage(hSkala,cb_addstring,0,lparam(lpctstr('64x64')));
        sendmessage(hSkala,cb_addstring,0,lparam(lpctstr('32x32')));
        sendmessage(hSkala,cb_addstring,0,lparam(lpctstr('16x16')));
        sendmessage(hSkala,cb_addstring,0,lparam(lpctstr('8x8')));
        sendmessage(hSkala,cb_addstring,0,lparam(lpctstr('4x4')));
        sendmessage(hSkala,cb_addstring,0,lparam(lpctstr('2x2')));
        sendmessage(hSkala,cb_setcursel,0,0);

        sendmessage(hWar,cb_addstring,0,lparam(lpctstr('Tekstury1')));
        sendmessage(hWar,cb_addstring,0,lparam(lpctstr('Tekstury2')));
        sendmessage(hWar,cb_addstring,0,lparam(lpctstr('Atr teks2')));
        sendmessage(hWar,cb_addstring,0,lparam(lpctstr('Att')));
        sendmessage(hWar,cb_addstring,0,lparam(lpctstr('Swiatlo R')));
        sendmessage(hWar,cb_addstring,0,lparam(lpctstr('Swiatlo G')));
        sendmessage(hWar,cb_addstring,0,lparam(lpctstr('Swiatlo B')));
        sendmessage(hWar,cb_addstring,0,lparam(lpctstr('Wysokosci')));
        sendmessage(hWar,cb_addstring,0,lparam(lpctstr('Swiatlo RGB')));
        sendmessage(hWar,cb_setcursel,0,0);
      end;

    WM_SIZE:
      begin
        getwindowrect(hOkna,wymiaryokna);
        if wymiaryokna.bottom-wymiaryokna.top < 535 then
          begin
            setwindowpos(hOkna,hwnd_top,
              0,0,
              wymiaryokna.right,535,
              swp_nomove or swp_drawframe or swp_nozorder);
            sendmessage(hOkna,WM_PAINT,0,0);
          end;
        getclientrect(hOkna,wymiaryokna);
        invalidaterect(hOkna,@wspRect,true);
        with wspRect do
        begin
          left:=5;
          right:=100;
          top:=wymiaryokna.bottom-20;
          bottom:=wymiaryokna.bottom-4;
        end;

        szerPlanszy:= (wymiaryokna.right-100-xscroll) div skala;
        wysPlanszy:= (wymiaryokna.bottom-yscroll) div skala;
        setwindowpos(hPlanszy,hwnd_top,
          0,0,
          wymiaryokna.right-100, wymiaryokna.bottom,
          swp_nomove or swp_noownerzorder);
        setwindowpos(hSkala,hwnd_top,
          1,wymiaryokna.bottom -50,
          0,0,
          swp_nosize or swp_noownerzorder);
        setwindowpos(hWar,hwnd_top,
          1,wymiaryokna.bottom -80,
          0,0,
          swp_nosize or swp_noownerzorder);
        setscrollrange(hPlanszy,sb_horz,0,255-szerplanszy+1,true);
        setscrollrange(hPlanszy,sb_vert,0,255-wysplanszy+1,true);
        if wysplanszy > $FF then wp:=0
          else if wp > $FF - wysplanszy then wp:= $FF -wysplanszy+1;
        if szerplanszy > $FF then kp:=0
          else if kp > $FF - szerplanszy then kp:= $FF -szerplanszy+1;
        sendmessage(hOkna,WM_PAINT,0,0);
      end;
    WM_COMMAND:
      begin
      if lpar = hSkala then  ////////////////////SKALA
        begin
          i:= 64 shr sendmessage(hSkala,cb_getcursel,0,0);
          if skala <> i then
          begin
            skala:= i;
            szerPlanszy:= (wymiaryokna.right-100-xscroll) div skala;
            wysPlanszy:= (wymiaryokna.bottom-yscroll) div skala;
            setscrollrange(hPlanszy,sb_horz,0,255-szerplanszy+1,true);
            setscrollrange(hPlanszy,sb_vert,0,255-wysplanszy+1,true);
            if wysplanszy > $FF then wp:=0
              else if wp > $FF - wysplanszy then wp:= $FF -wysplanszy+1;
            if szerplanszy > $FF then kp:=0
              else if kp > $FF - szerplanszy then kp:= $FF -szerplanszy+1;
            for i:= $00 to $0E do
              loadtex(i,'');

            invalidaterect(hPlanszy,lprect(0),true);
          end;
        end

        else if lpar =hWar then       /////////////WARSTWY
          begin
          i:=sendmessage(hWar,cb_getcursel,0,0);
          if i <> war then
            begin
              war:= i;
              sendmessage(hPlanszy,WM_PAINT,0,0);
              sendmessage(hOkna,WM_PAINT,0,0);
            end;
          end

        else if lpar =hPrzycisk then   ///////////'RYSUJ' BUTTON
          begin
            if IsDlgButtonChecked(hOkna,150) = bst_checked then
              begin
                checkdlgbutton(hOkna,150,bst_unchecked);
                rysuj:=false;
              end
            else
              begin
                checkdlgbutton(hOkna,150,bst_checked);
                rysuj:=true;
              end;
          end

        else
        case loword(wpar) of
          101:       ///////////////////////MAP READ
            begin
              PrepOpen(pchar('Pliki map'#00'*.map'#00),'map');
              if GetOpenFileName(@otworz) then
                frOpen(pchar(FilePath),$0F);
                AttMapRead(0,2,1);
            end;
          102:                //////////////ATT READ
            begin
              PrepOpen(pchar('Pliki att'#00'*.att'#00),'att');
              if getopenfilename(@otworz) then
                frOpen(pchar(FilePath),$10);
                AttMapRead(3,3,3);
            end;
          103:              /////////////////LIGHT READ
            begin
              PrepOpen(pchar('Pliki bmp'#00'*.bmp'#00),'bmp');
              if getopenfilename(@otworz) then
                frOpen(pchar(FilePath),$12);
                LightRead(4,6);
            end;
          104:                  ////////////////HEIGHT READ
            begin
              PrepOpen(pchar('Pliki ozb'#00'*.ozb'#00),'ozb');
              if getopenfilename(@otworz) then
                frOpen(pchar(FilePath),$11);
                HeightRead(7);

            end;
          112..126:             ///////////////SINGLE TEX READ
            begin
              PrepOpen(pchar('Pliki bmp'#00'*.bmp'#00),'bmp');
              if getopenfilename(@otworz) then
                begin
                  LoadTex(loword(wpar)-112,pchar(FilePath));
                  sendmessage(hSelTex,WM_PAINT,0,0);
                  sendmessage(hPlanszy,WM_PAINT,0,0);
                end;
            end;
          127:                  ///////////////ALL TEX READ
            begin
              folder.hwndOwner:= hOkna;
              if SHGetPathFromIdList(SHBrowseForFolder(@folder),WorldPath) then
                begin
                  for i:=$0 to $0D do
                    begin
                      strcopy(FilePath,WorldPath);
                      strcat(FilePath,nazwy[i]);
                      LoadTex(i,FilePath);
                    end;
                  sendmessage(hSelTex,WM_PAINT,0,0);
                  sendmessage(hPlanszy,WM_PAINT,0,0);
                end;

            end;
          105:                  //////////////ALL READ
            begin
              folder.hwndOwner:= hOkna;
              if SHGetPathFromIdList(SHBrowseForFolder(@folder),WorldPath) then
                begin
                  strcopy(FilePath,WorldPath);
                  strcat(FilePath,'\*.map');
                  FindFirstFile(FilePath,znaleziony);     //*.MAP
                  strcopy(FilePath,WorldPath);
                  strcat(FilePath,'\');
                  strcat(FilePath,znaleziony.cfilename);
                  frOpen(FilePath,$0F);
                  AttMapRead(0,2,1);

                  strcopy(FilePath,WorldPath);
                  strcat(FilePath,'\*.att');
                  FindFirstFile(FilePath,znaleziony);     //*.ATT
                  strcopy(FilePath,WorldPath);
                  strcat(FilePath,'\');
                  strcat(FilePath,znaleziony.cfilename);
                  frOpen(FilePath,$10);
                  AttMapRead(3,3,3);

                  strcopy(FilePath,WorldPath);
                  strcat(FilePath,'\Terrainlight.bmp');    //TERRAINLIGHT.BMP
                  frOpen(FilePath,$12);
                  LightRead(4,6);

                  strcopy(FilePath,WorldPath);
                  strcat(FilePath,nazwy[$11]);   //TERRAINHEIGHT.OZB
                  frOpen(FilePath,$11);
                  HeightRead(7);

                  for i:=$0 to $0D do
                    begin
                      strcopy(FilePath,WorldPath);
                      strcat(FilePath,nazwy[i]);   //TEKSTURY
                      LoadTex(i,FilePath);
                    end;
                  sendmessage(hSelTex,WM_PAINT,0,0);
                  sendmessage(hPlanszy,WM_PAINT,0,0);
                end;
            end;
          106:                  //////////////MAP SAVE
            begin
              PrepSave(pchar('Pliki map'#00'*.map'#00),'map');
              if getsavefilename(@zapisz) then
                AttMapSave(0,2,filepath,#00);
            end;
          107:                  //////////////ATT SAVE
            begin
              PrepSave(pchar('Pliki att'#00'*.att'#00),'att');
              if getsavefilename(@zapisz) then
                AttMapSave(3,3,filepath,#00#255#255);
            end;
          108:                  /////////////LIGHT SAVE
            begin
              PrepSave(pchar('Pliki bmp'#00'*.bmp'#00),'bmp');
              if getsavefilename(@zapisz) then
                BmpWrite(4,6,filepath);
            end;
          109:                  /////////////HEIGT SAVE
            begin
              PrepSave(pchar('Pliki ozb'#00'*.ozb'#00),'ozb');
              if getsavefilename(@zapisz) then
                BmpWrite(7,7,filepath);
            end;
          110:                  /////////////ALL SAVE
            begin
              folder.hwndOwner:= hOkna;
              if SHGetPathFromIdList(SHBrowseForFolder(@folder),WorldPath) then
                begin
                  strcopy(FilePath,WorldPath);
                  strcat(FilePath,nazwy[$0F]);    //MAP
                  AttMapSave(0,2,filepath,#00);

                  strcopy(FilePath,WorldPath);
                  strcat(FilePath,nazwy[$10]);    //ATT
                  AttMapSave(0,2,filepath,#00);

                  strcopy(FilePath,WorldPath);
                  strcat(FilePath,nazwy[$12]);    //LIGHT
                  BmpWrite(4,6,filepath);

                  strcopy(FilePath,WorldPath);
                  strcat(FilePath,nazwy[$11]);    //HEIGHT
                  BmpWrite(7,7,filepath);
                end;
            end;
          128:                  ///////////SESSION LOAD
            begin
              for i:= 0 to 14 do
                loadtex(i,'');
              frOpen('',$0F);
              AttMapRead(0,2,1);
              frOpen('',$10);
              AttMapRead(3,3,3);
              frOpen('',$11);
              HeightRead(7);
              frOpen('',$12);
              LightRead(4,6);
              sendmessage(hSelTex,WM_PAINT,0,0);
            end;
          111:                  //////////EXIT
            begin
              postquitmessage(0);
            end;
        end;
      end;
    else funkcjeokna := DefWindowProc(hOkna, uMsg, wPar, lPar);
  end;
end;

BEGIN
  with Wnd do
  begin
    lpfnWndProc := @FunkcjeOkna;
    hInstance := hInstance;
    lpszClassName := 'Glowne';
    hbrBackground := COLOR_WINDOW;
    hcursor:= loadcursor(0,idc_arrow);
  end;

  with plansza do
  begin
    style:= cs_bytealignclient;
    lpfnWndProc:= @FunkcjePlanszy;
    hInstance:= hInstance;
    lpszClassName:= 'Plansza';
    hbrBackground:= color_window;
    hcursor:= loadcursor(0,idc_arrow);
  end;

  with seltex do
  begin
    style:= cs_bytealignclient;
    lpfnWndProc:= @FunkcjeSelTex;
    hInstance:= hInstance;
    lpszClassName:= 'Seltex';
    hbrBackground:= color_window;
    hcursor:= loadcursor(0,idc_arrow);
  end;

  RegisterClass(Wnd); // zarejestruj nowa klase
  RegisterClass(plansza);
  RegisterClass(seltex);

// stworz forme...
  BelkaMenu:= Loadmenu(hinstance,makeintresource(200));
  hOkna:= CreateWindow('glowne', 'MuMapEdit Alpha 8',
            WS_VISIBLE or WS_TILEDWINDOW,
            20, 20, cw_usedefault, cw_usedefault,
            0, BelkaMenu, hInstance, NIL);

  tekstury[$0].substc:= $006400;
  tekstury[$1].substc:= $00AF00;
  tekstury[$2].substc:= $004B96;
  tekstury[$3].substc:= $317DC8;
  tekstury[$4].substc:= $64AFFA;
  tekstury[$5].substc:= $FF0000;
  tekstury[$6].substc:= $00FFFF;
  tekstury[$7].substc:= $5E5E5E;
  tekstury[$8].substc:= $757575;
  tekstury[$9].substc:= $8C8C8C;
  tekstury[$A].substc:= $A3A3A3;
  tekstury[$B].substc:= $BABABA;
  tekstury[$C].substc:= $D1D1D1;
  tekstury[$D].substc:= $E8E8E8;
  tekstury[$E].substc:= $000000;

  while GetMessage(msg, 0, 0, 0) do
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;
END.
