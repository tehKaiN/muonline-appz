#include <windows.h>
#define quit 801
#define save 802
#define windowMode 803
#define music 804
#define sound 805
#define resolution 806
#define ikona 888

HWND hMain,hQuit,hSave,hWindowMode,hMusic,hSound,hRes,hId,hIdD;
DWORD vWndMode = 0, vMusic = 0, vSound = 0, vRes = 0;
LPSTR vId;
HKEY hk;

void chgState(WPARAM *btn,DWORD *state)
  {
  CheckDlgButton(hMain,*btn,(*state == 0?BST_CHECKED:BST_UNCHECKED));
	*state = ! *state;
  }
void initCb(LPSTR opt,DWORD *v,int btn)
  {
  DWORD sBuf1 = sizeof(DWORD);
  DWORD tBuf1 = REG_DWORD;
	RegQueryValueEx(hk,opt,NULL,&tBuf1,(LPBYTE)v,&sBuf1);
	if(btn != 0)
	  CheckDlgButton(hMain,btn,(*v == 0?BST_UNCHECKED:BST_CHECKED));
  }

LRESULT CALLBACK wpMain(HWND hWnd,UINT msg, WPARAM wPar, LPARAM lPar)
  {
	switch(msg)
	  {
		case WM_CREATE:
		  break;
		case WM_DESTROY:
		  PostQuitMessage(0);
			break;
		case WM_CLOSE:
			DestroyWindow(hWnd);
			break;
		case WM_COMMAND:
      switch(LOWORD(wPar))
				{
				case quit:
				  DestroyWindow(hWnd);
				  break;
		    case save:
			    vRes = SendMessage(hRes,LB_GETCURSEL,0,0);
					RegSetValueEx(hk,"Resolution",0,REG_DWORD,(LPBYTE)&vRes,sizeof(DWORD));
					RegSetValueEx(hk,"WindowMode",0,REG_DWORD,(LPBYTE)&vWndMode,sizeof(DWORD));
					RegSetValueEx(hk,"MusicOnOff",0,REG_DWORD,(LPBYTE)&vMusic,sizeof(DWORD));
					RegSetValueEx(hk,"SoundOnOff",0,REG_DWORD,(LPBYTE)&vSound,sizeof(DWORD));
					GetWindowText(hId,vId,10);
					RegSetValueEx(hk,"ID",0,REG_SZ,vId,10);
			    break;
		    case windowMode:
			    chgState(&wPar,&vWndMode);
					break;
				case music:
			    chgState(&wPar,&vMusic);
			    break;
        case sound:
			    chgState(&wPar,&vSound);
			    break;
		    }
	    break;
		default:
		  return DefWindowProc(hWnd,msg,wPar,lPar);
	  }
  }

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpPar, int cmdShow)
  {
	WNDCLASSEX wcMain;
	wcMain.cbSize = sizeof(WNDCLASSEX);
	wcMain.style = 0;
	wcMain.lpfnWndProc = wpMain;
	wcMain.cbClsExtra = 0;
	wcMain.cbWndExtra = 0;
	wcMain.hInstance = hInstance;
	wcMain.hIcon = LoadIcon(hInstance,MAKEINTRESOURCE(ikona));
	wcMain.hCursor = LoadCursor(NULL,IDC_ARROW);
	wcMain.hbrBackground = (HBRUSH)COLOR_WINDOW;
	wcMain.lpszMenuName = NULL;
	wcMain.lpszClassName = "muKonfig";
	wcMain.hIconSm = LoadIcon(hInstance,MAKEINTRESOURCE(ikona));

	RegisterClassEx(&wcMain);

	hMain = CreateWindowEx(WS_EX_WINDOWEDGE,"muKonfig",
	  "muConfig 0.1 for DarkMuBat",WS_OVERLAPPEDWINDOW ^ WS_MAXIMIZEBOX ^ WS_THICKFRAME ^ WS_MINIMIZEBOX,
		CW_USEDEFAULT,CW_USEDEFAULT,
		300,120,
		0,NULL,
		hInstance,NULL);
  hQuit = CreateWindowEx(0,"BUTTON",
	  "quit",WS_CHILD | WS_VISIBLE,
	  200,60,
		65,25,
		hMain,(HMENU)quit,
		hInstance,NULL);
	hSave = CreateWindowEx(0,"BUTTON",
	  "save",WS_CHILD | WS_VISIBLE,
		120,60,
		65,25,
		hMain,(HMENU)save,
		hInstance,NULL);
	hWindowMode = CreateWindowEx(0,"BUTTON",
	  "windowed",WS_CHILD|WS_VISIBLE|BS_CHECKBOX,
	  5,5,
		85,16,
		hMain,(HMENU)windowMode,
		hInstance,NULL);
	hMusic = CreateWindowEx(0,"BUTTON",
	  "music",WS_CHILD|WS_VISIBLE|BS_CHECKBOX,
	  100,5,
		60,16,
		hMain,(HMENU)music,
		hInstance,NULL);
	hSound = CreateWindowEx(0,"BUTTON",
	  "sound",WS_CHILD|WS_VISIBLE|BS_CHECKBOX,
	  165,5,
		60,16,
		hMain,(HMENU)sound,
		hInstance,NULL);
	hRes = CreateWindowEx(WS_EX_CLIENTEDGE,"LISTBOX",
	  "resolution",WS_CHILD|WS_VISIBLE|LBS_NOTIFY,
		5,25,
		100,80,
		hMain,(HMENU)resolution,
		hInstance,NULL);
	hId = CreateWindowEx(WS_EX_CLIENTEDGE,"EDIT",
	  NULL,WS_CHILD|WS_VISIBLE,
		190,25,
		100,24,
		hMain,(HMENU)0,
		hInstance,NULL);
	hIdD = CreateWindowEx(0,"STATIC",
	"Auto Login:",WS_CHILD|WS_VISIBLE,
	110,30,
	80,24,
	hMain,0,
	hInstance,NULL);
	LPSTR tRes[4] = {"640x480","800x600","1024x768","1280x1024"};
	BYTE i;
	for(i = 0; i != 4; ++i)
	  SendMessage(hRes,LB_ADDSTRING,0,(LPARAM)tRes[i]);

  RegCreateKeyEx(HKEY_CURRENT_USER,"Software\\Webzen\\Mu\\Config",
	  0,NULL,
		REG_OPTION_NON_VOLATILE,KEY_ALL_ACCESS,
		NULL,&hk,NULL);

	initCb("WindowMode",&vWndMode,windowMode);
	initCb("MusicOnOff",&vMusic,music);
	initCb("SoundOnOff",&vSound,sound);
	initCb("Resolution",&vRes,0);
  DWORD sBuf1 = 10;
  DWORD tBuf1 = REG_SZ;
  vId = malloc(11);
	if(RegQueryValueEx(hk,"ID",NULL,&tBuf1,(LPBYTE)vId,&sBuf1) == ERROR_SUCCESS)
    SetWindowText(hId,vId);

  SendMessage(hRes,LB_SETCURSEL,vRes,0);

	ShowWindow(hMain,SW_SHOW);
	UpdateWindow(hMain);
	MSG msg;
	while(GetMessage(&msg,NULL,0,0))
	  {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	  }
  return msg.wParam;
	}
