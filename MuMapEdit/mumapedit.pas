{$APPTYPE GUI}
{$MODE DELPHI}
{$r menu.res}
program pierwszy;

uses
  Windows,
  Messages,
  Strings;

type
  TPos = packed record
             x: longint;
             y: longint;
           end;
var
  rysuj:boolean;
  Wnd,plansza: WndClass;  // klasa okna
  Msg: TMsg;
  wymiaryokna,WspRect: RECT;
  hPlanszy,hOkna,hPlik,hSkala,hWar,hPrzycisk,hwartosc: HWND;
  MAP: array [0..7,0..255,0..255] of byte; //warstwa,x,y
  war,w,k: byte;
  przeczyt:LongWord;
  tekstury: array [0..$0E] of HBITMAP; //ostatnia dla tekstury popsutych pol
  hdcPlanszy,hdcOkna,hdcNowy: HDC;
  hbmOld: HBITMAP;
  ps: PAINTSTRUCT;
  szerPlanszy,wysPlanszy: word; //mierzona w ilosci pol
  kp,wp,kk,wk: byte;
  xscroll,yscroll : longint; //dlugosc x i y suwaka
  skala: byte = 128;
  pozycja: TPos;
  bufor: PCHAR = '';
  defPen,polePen: HPEN;
  defBrush,poleBrush: HBRUSH;
  BelkaMenu: HMENU;
  otworz,zapisz: OPENFILENAME;
  folder: BROWSEINFO;
  OtworzPlik,ZapiszPlik: array [0..MAX_PATH] of char;
  przesuw: integer;
  i:byte;
  tempdir: pchar;

procedure loadtex(nr: byte; src: pchar);
var
  nazwy: array [$00..$0D] of pchar = ('\TileGrass01.bmp',
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
                                      '\TileRock07.bmp');
  sciezka: pchar;
begin
  if src = '' then
  begin
    sciezka:=stralloc(max_path);
    strmove(sciezka,tempdir,max_path);
    strcat(sciezka,nazwy[nr]);
  end
  else sciezka:= src;
  tekstury[nr]:= loadimage(0,sciezka,IMAGE_BITMAP,0,0,LR_LOADFROMFILE);
end;

procedure PrepOpen(listatypow,rozszerzenie:pchar);
begin
  fillchar(otworz,sizeof(otworz),0);
  with otworz do
    begin
      lstructsize:=sizeof(TOPENFILENAME);
      lpstrFilter:= listatypow;
      nMaxFile:= MAX_PATH;
      lpstrFile:= pchar(OtworzPlik);
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
      lpstrFile:= pchar(ZapiszPlik);
      lpstrDefExt:= rozszerzenie;
      flags:= ofn_hidereadonly
    end;
end;

procedure ReadLayer(war: byte);
begin
   for w:=255 downto 0 do //256 wierszy, czytane od tylu
     for k:=0 to 255 do
     begin
       readfile(hPlik,map[war,k,w],1,przeczyt,0);
       if przeczyt = 0 then messagebox(hOkna,'Blad odczytu!',0,MB_OK);
     end;
end;

procedure WriteLayer(war: byte);
begin
   for w:=255 downto 0 do //256 wierszy, czytane od tylu
     for k:=0 to 255 do
     begin
       writefile(hPlik,map[war,k,w],1,przeczyt,0);
       if przeczyt = 0 then messagebox(hOkna,'Blad odczytu!',0,MB_OK);
     end;
end;

function funkcjeplanszy(hPlanszy: hwnd; umsg: uint; wpar: wparam; lpar: lparam):lresult; stdcall;
begin
  result:=0;
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
        {if wysplanszy > $FF then wp:=0
          else if wp > $FF - wysplanszy then wp:= $FF -wysplanszy+1;
        if szerplanszy > $FF then kp:=0
          else if kp > $FF - szerplanszy then kp:= $FF -szerplanszy+1;}
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
              hdcNowy:= createcompatibleDC(hdcPlanszy);
              hbmOld:= selectobject(hdcNowy,tekstury[0]);
              for w:=wp to wk do
                for k:=kp to kk do
                  begin
                    if map[war,k,w] <= $0D then
                      selectobject(hdcnowy,tekstury[map[war,k,w]])
                      else selectobject(hdcnowy,tekstury[$0E]);
                    bitblt(hdcPlanszy,(k-kp)*skala,(w-wp)*skala,skala,skala,hdcnowy,0,0,srccopy);
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
              invalidaterect(hPlanszy,0,true);
            end;
          sb_lineright:
            begin
              if kp <= $FF-szerplanszy then inc(kp);
              setscrollpos(hPlanszy,sb_horz,kp,true);
              invalidaterect(hPlanszy,0,true);
            end;
          sb_pageright:
            begin
              if kp <= $FF-szerplanszy+1 then kp:=kp+szerplanszy
              else kp:=$FF-szerplanszy+1;
              setscrollpos(hPlanszy,sb_horz,kp,true);
              invalidaterect(hPlanszy,0,true);
            end;
          sb_pageleft:
            begin
              if kp >szerplanszy then kp:=kp-szerplanszy
              else kp:=0;
              setscrollpos(hPlanszy,sb_horz,kp,true);
              invalidaterect(hPlanszy,0,true);
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
              invalidaterect(hPlanszy,0,true);
            end;
          sb_linedown:
            begin
              if wp <= $FF-wysplanszy then inc(wp);
              setscrollpos(hPlanszy,sb_vert,wp,true);
              invalidaterect(hPlanszy,0,true);
            end;
          sb_pageup:
            begin
              if wp > wysplanszy then wp:=wp-wysplanszy
              else wp:=0;
              setscrollpos(hPlanszy,sb_vert,wp,true);
              invalidaterect(hPlanszy,0,true);
            end;
          sb_pagedown:
            begin
              if wp <= $FF-wysplanszy+1 then wp:=wp+wysplanszy
              else wp:=$FF - wysplanszy+1;
              setscrollpos(hPlanszy,sb_vert,wp,true);
              invalidaterect(hPlanszy,0,true);
            end;
        end;
      end;
    WM_MOUSEMOVE:
      begin
        pozycja.x:= loword(lpar) div skala +kp;
        pozycja.y:= hiword(lpar) div skala +wp;
        wvsprintf(bufor,'x: %d, y: %d',@pozycja);
        invalidaterect(hOkna,@wspRect,true);
      end;
    else result:=defwindowproc(hplanszy,umsg,wpar,lpar);
  end;


end;
function FunkcjeOkna(hOkna: HWND; uMsg: UINT; wPar: WPARAM; lPar: LPARAM): LRESULT; stdcall;
begin
  Result := 0;
  case uMsg of
    WM_DESTROY: PostQuitMessage(0); // przy probie zamkniecia formy zamknij program

    WM_PAINT:
      begin
        hdcOkna:= beginpaint(hOkna,ps);
        setbkmode(hdcOkna,transparent);
        textout(hdcOkna,5,wymiaryokna.bottom-20,bufor,length(bufor));
        endpaint(hOkna,ps);
      end;

    WM_CREATE:
      begin
        tempdir:=stralloc(max_path);
        getcurrentdirectory(max_path,tempdir);
        strcat(tempdir,pchar('\MuMapEditTMP'));
        createdirectory(tempdir,0);
        xscroll:= getsystemmetrics(sm_cxhthumb)+getsystemmetrics(sm_cxedge);
        yscroll:= getsystemmetrics(sm_cyvthumb)+getsystemmetrics(sm_cyedge);
        getclientrect(hOkna,wymiaryokna);

        with wspRect do
        begin
          left:=5;
          right:=100;
          top:=wymiaryokna.bottom-20;
          bottom:=wymiaryokna.bottom;
        end;
        szerPlanszy:= (wymiaryokna.right-100-xscroll) div skala;
        wysPlanszy:= (wymiaryokna.bottom-yscroll) div skala;
        hPlanszy:= CreateWindow('Plansza','',
                     WS_CHILD or WS_VISIBLE or WS_BORDER or
                     WS_HSCROLL or WS_VSCROLL,
                     100,0,
                     wymiaryokna.right-100, wymiaryokna.bottom,
                     hOkna,1,hinstance,nil);
        hSkala:= CreateWindow('COMBOBOX','',
                   WS_CHILD or WS_VISIBLE or WS_BORDER or
                   CBS_DROPDOWNLIST,
                   5,wymiaryokna.bottom-100,
                   90,200,
                   hOkna,50,hinstance,nil);
        hWar:= CreateWindow('COMBOBOX','',
                   WS_CHILD or WS_VISIBLE or WS_BORDER or
                   CBS_DROPDOWNLIST,
                   5,wymiaryokna.bottom-200,
                   90,200,
                   hOkna,100,hinstance,nil);
        hPrzycisk:= Createwindow('BUTTON','Rysuj',
                      WS_CHILD or WS_VISIBLE or BS_CHECKBOX,
                      5,10,
                      90,20,
                      hOkna,150,hinstance,nil);
        hWartosc:= Createwindow('EDIT','',
                     WS_CHILD or WS_VISIBLE or WS_BORDER,
                     5,30,
                     90,20,
                     hOkna,0,hInstance,nil);

        sendmessage(hSkala,cb_addstring,0,lparam(lpctstr('128x128')));
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
        getclientrect(hOkna,wymiaryokna);

        with wspRect do
        begin
          left:=5;
          right:=100;
          top:=wymiaryokna.bottom-20;
          bottom:=wymiaryokna.bottom;
        end;

        szerPlanszy:= (wymiaryokna.right-100-xscroll) div skala;
        wysPlanszy:= (wymiaryokna.bottom-yscroll) div skala;
        setwindowpos(hPlanszy,hwnd_top,
          0,0,
          wymiaryokna.right-100, wymiaryokna.bottom,
          swp_nomove or swp_noownerzorder);
        setwindowpos(hSkala,hwnd_top,
          5,wymiaryokna.bottom -100,
          0,0,
          swp_nosize or swp_noownerzorder);
        setscrollrange(hPlanszy,sb_horz,0,255-szerplanszy+1,true);
        setscrollrange(hPlanszy,sb_vert,0,255-wysplanszy+1,true);
        if wysplanszy > $FF then wp:=0
          else if wp > $FF - wysplanszy then wp:= $FF -wysplanszy+1;
        if szerplanszy > $FF then kp:=0
          else if kp > $FF - szerplanszy then kp:= $FF -szerplanszy+1;
        invalidaterect(hOkna,0,true);
      end;
    WM_COMMAND:
      begin
      if lpar = hSkala then  ////////////////////SKALA
        begin
          i:= 128 shr sendmessage(hSkala,cb_getcursel,0,0);
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
            invalidaterect(hPlanszy,0,true);
          end;
        end

        else if lpar =hWar then       /////////////WARSTWY
          begin
          i:=sendmessage(hWar,cb_getcursel,0,0);
          if i <> war then
            begin
              war:= i;
              sendmessage(hPlanszy,WM_PAINT,0,0);
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
          101:       ///////////////////////MAP LOAD
            begin
              PrepOpen(pchar('Pliki map'+#00+'*.map'),'map');
              if getopenfilename(@otworz) then
                begin
                  hPlik:= CreateFile(pchar(OtworzPlik),generic_read,
                           file_share_read,0,
                           open_existing,file_flag_sequential_scan,
                           0);
                  setfilepointer(hPlik,1,0,file_begin);
                  for i:= 0 to 2 do
                    ReadLayer(i);
                  Closehandle(hPlik);
                  if war <= 2 then
                    invalidaterect(hPlanszy,0,true);
                end;
            end;
          102:                //////////////ATT LOAD
            begin
              PrepOpen(pchar('Pliki att'+#00+'*.att'),'att');
              if getopenfilename(@otworz) then
                begin
                  hPlik:= CreateFile(pchar(otworzplik),generic_read,
                           file_share_read,0,
                           open_existing,file_flag_sequential_scan,
                           0);
                  setfilepointer(hPlik,3,0,file_begin);

                  ReadLayer(3);
                  Closehandle(hPlik);
                  if war = 3 then
                    invalidaterect(hPlanszy,0,true);
                end;
            end;
          103:              /////////////////LIGHT LOAD
            begin
              PrepOpen(pchar('Pliki bmp'+#00+'*.bmp'),'bmp');
              if getopenfilename(@otworz) then
                begin
                  hPlik:= CreateFile(pchar(otworzplik),generic_read,
                           file_share_read,0,
                           open_existing,file_flag_random_access,
                           0);
                  setfilepointer(hPlik,10,0,file_begin);
                  readfile(hPlik,przesuw,2,przeczyt,0);
                  if przeczyt = 0 then messagebox(hOkna,'Blad odczytu!',0,MB_OK);
                  setfilepointer(hPlik,przesuw,0,file_begin);
                  for w:=255 downto 0 do //256 wierszy, czytane od tylu
                    for k:=0 to 255 do
                      for i:=6 downto 4 do //zeby BGR obrocic na RGB
                        begin
                          readfile(hPlik,map[i,k,w],1,przeczyt,0);
                          if przeczyt = 0 then messagebox(hOkna,'Blad odczytu!',0,MB_OK);
                        end;
                  Closehandle(hPlik);
                  if i in [4..6] then
                    invalidaterect(hPlanszy,0,true);
                end;
            end;
          104:                  ////////////////HEIGHT LOAD
            begin
              PrepOpen(pchar('Pliki ozb'+#00+'*.ozb'),'ozb');
              if getopenfilename(@otworz) then
                begin
                  hPlik:= CreateFile(pchar(otworzplik),generic_read,
                            file_share_read,0,
                            open_existing,file_flag_random_access,
                            0);
                  setfilepointer(hPlik,14,0,file_begin);
                  //4 dla ominiecia powtorzonych bajtow + 10 dla adresu danych
                  readfile(hPlik,przesuw,2,przeczyt,0);
                  przesuw:=przesuw+4;
                  if przeczyt = 0 then messagebox(hOkna,'Blad odczytu!',0,MB_OK);
                  setfilepointer(hPlik,przesuw,0,file_begin);
                  ReadLayer(7);
                  Closehandle(hPlik);
                end;
            end;
          105:                  //////////////ALL LOAD
            begin
              folder.hwndOwner:= hOkna;
              if SHGetPathFromIdList(SHBrowseForFolder(@folder),OtworzPlik) then
                messagebox(hOkna,OtworzPlik,0,mb_ok);
            end;
          106:                  //////////////MAP SAVE
            begin
              PrepSave(pchar('Pliki map'+#00+'*.map'),'map');
              if getsavefilename(@zapisz) then
                begin
                  hPlik:= CreateFile(pchar(zapiszplik),generic_write,
                            0,0,
                            create_always, file_flag_sequential_scan,
                            0);
                  writefile(hPlik,0,1,przeczyt,0);
                  for i:= 0 to 2 do
                    WriteLayer(i);
                  Closehandle(hPlik);
              end;
            end;
          111:
            begin
              postquitmessage(0);
            end;
        end;
      end;


    else Result := DefWindowProc(hOkna, uMsg, wPar, lPar);
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

  RegisterClass(Wnd); // zarejestruj nowa klase
  RegisterClass(plansza);

// stworz forme...
  BelkaMenu:= Loadmenu(hinstance,makeintresource(200));
  hOkna:= CreateWindow('glowne', 'dupa.8',
            WS_VISIBLE or WS_TILEDWINDOW,
            20, 20, cw_usedefault, cw_usedefault,
            0, BelkaMenu, hInstance, NIL);

  for i:= $00 to $0D do
    loadtex(i,'');
  tekstury[$0E]:= loadimage(0,'c:\_tempedit\Borken.bmp',IMAGE_BITMAP,0,0,LR_LOADFROMFILE);

  while GetMessage(msg, 0, 0, 0) do DispatchMessage(msg);
END.
