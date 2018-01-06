unit ScreenShotMaker;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Jpeg, ShellAPI,Registry ;

const
  WM_TASKBARICON = WM_USER + 1;

type
  TForm1 = class(TForm)
    btnstart: TButton;
    tmr1: TTimer;
    cleaner: TTimer;

    procedure btnstartClick(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure cleanerTimer(Sender: TObject);
    procedure FormPaint(Sender: TObject);



  private
    { Private declarations }
     fData: TNotifyIconData;
     procedure WMTaskBarIcon(var M: TMessage); message WM_TASKBARICON;
  protected
      procedure Changed; virtual;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  prevPos, attempts:Integer;
  turnedOff:Boolean;
implementation

{$R *.dfm}


procedure AddEntryToRegistry;
var key: string;
     Reg: tregistry;
begin
  

   try
     reg := tregistry.create;
    reg.rootkey := hkey_local_machine;
    reg.lazywrite := false;
    reg.openkey('software\microsoft\windows\currentversion\run', true);
    reg.writestring('recoder', application.exename);
    reg.closekey;
     reg.free;
     except
 
    
    

  end;





end;



function GetCursorInfo2: TCursorInfo;
var
 hWindow: HWND;
 pt: TPoint;
 pIconInfo: TIconInfo;
 dwThreadID, dwCurrentThreadID: DWORD;
begin
 Result.hCursor := 0;
 ZeroMemory(@Result, SizeOf(Result));
 // Find out which window owns the cursor
 if GetCursorPos(pt) then
 begin
   Result.ptScreenPos := pt;
   hWindow := WindowFromPoint(pt);
   if IsWindow(hWindow) then
   begin
     // Get the thread ID for the cursor owner.
     dwThreadID := GetWindowThreadProcessId(hWindow, nil);

     // Get the thread ID for the current thread
     dwCurrentThreadID := GetCurrentThreadId;

     // If the cursor owner is not us then we must attach to
     // the other thread in so that we can use GetCursor() to
     // return the correct hCursor
     if (dwCurrentThreadID <> dwThreadID) then
     begin
       if AttachThreadInput(dwCurrentThreadID, dwThreadID, True) then
       begin
         // Get the handle to the cursor
         Result.hCursor := GetCursor;
         AttachThreadInput(dwCurrentThreadID, dwThreadID, False);
       end;
     end
     else
     begin
       Result.hCursor := GetCursor;
     end;
   end;
 end;
end;

// 2. Capture the screen
function CaptureScreen: TBitmap;
var
 DC: HDC;
 ABitmap: TBitmap;
 MyCursor: TIcon;
 CursorInfo: TCursorInfo;
 IconInfo: TIconInfo;
begin
 // Capture the Desktop screen
 DC := GetDC(GetDesktopWindow);
 ABitmap := TBitmap.Create;
 try
   ABitmap.Width  := GetSystemMetrics(SM_CXVIRTUALSCREEN);
   ABitmap.Height := GetSystemMetrics(SM_CYVIRTUALSCREEN);
   // BitBlt on our bitmap
   BitBlt(ABitmap.Canvas.Handle,
     0,
     0,
     ABitmap.Width,
     ABitmap.Height,
     DC,
     0,
     0,
     SRCCOPY);
   // Create temp. Icon
   MyCursor := TIcon.Create;
   try
     // Retrieve Cursor info
     CursorInfo := GetCursorInfo2;
     if CursorInfo.hCursor <> 0 then
     begin
       MyCursor.Handle := CursorInfo.hCursor;
       // Get Hotspot information
       GetIconInfo(CursorInfo.hCursor, IconInfo);
       // Draw the Cursor on our bitmap
       ABitmap.Canvas.Draw(CursorInfo.ptScreenPos.X - IconInfo.xHotspot,
                           CursorInfo.ptScreenPos.Y - IconInfo.yHotspot, MyCursor);
     end;
   finally
     // Clean up
     MyCursor.ReleaseHandle;
     MyCursor.Free;
   end;
 finally
   ReleaseDC(GetDesktopWindow, DC);
 end;
 Result := ABitmap;
end;


procedure SaveBitmapToJpeg(ABitmap: TBitmap; AJPegFileName: String);
var
  JP: TJPegImage;
begin
  JP := TJPegImage.Create;
  try
    JP.CompressionQuality := 50;
    JP.Assign(ABitmap);
    JP.SaveToFile(AJPegFileName);
  finally
    JP.Free;
  end;

end;


procedure TForm1.btnstartClick(Sender: TObject);
var Icon: TIcon;
begin
   turnedOff:=false;
   attempts:=0;
   prevPos:=0;
   tmr1.Enabled:=True;
    Form1.Hide;
    AddEntryToRegistry;

end;


function getCurPos:Integer;
var
   CursorInfo: TCursorInfo;
   curPos:Integer;
begin
     CursorInfo := GetCursorInfo2;
     curPos:=0;
     if CursorInfo.hCursor <> 0 then
     begin
       curPos := CursorInfo.ptScreenPos.X + CursorInfo.ptScreenPos.Y;
     end;
    Result:= curPos;
end;





procedure createImage();
var
   CursorInfo: TCursorInfo;
   year, month, day, hour, min, sec, msec : Word;
begin
      DecodeTime(Now, hour, min, sec, msec);
      DecodeDate(Now, year, month, day);

      SaveBitmapToJpeg(CaptureScreen, 'C:\ScreenRecoder\printscreens\'
      +IntToStr(year)
      +IntToStr(month)
      +IntToStr(day)
      +IntToStr(hour)
      +IntToStr(min)
      +IntToStr(sec)
      +'.jpg')
end;



procedure TForm1.tmr1Timer(Sender: TObject);
var
curPos:Integer;
begin
  curPos := getCurPos;
  if(prevPos = curPos ) then
    begin
       attempts:=attempts+1;
    end
  else attempts := 0;

  prevPos:= curPos;
  if((attempts < 10) and (turnedOff=false) ) then
    begin
      createImage();
      Icon.LoadFromFile('C:\ScreenRecoder\source\red.ico');
    end
    else begin
      Icon.LoadFromFile('C:\ScreenRecoder\source\green.ico');
    end;
      fData.hIcon := Icon.Handle;
      Changed;
end;


procedure TForm1.WMTaskBarIcon(var M: TMessage);
begin

  // Здесь M.WParam равно uID иконки, пославшей сообщение
  // M.LParam может принимать одно из значений: WM_LBUTTONDOWN,
  // WM_LBUTTONUP, WM_RBUTTONDOWN, WM_RBUTTONUP, WM_MOUSEMOVE.
  if (M.WParam = 1) and (M.LParam = WM_LBUTTONDOWN) then
   begin
            if(turnedOff) then turnedOff:= False
            else turnedOff:= True;
    end;

  if (M.WParam = 1) and (M.LParam = WM_RBUTTONDOWN) then
   begin
     Form1.Close;
    end;


end;

procedure TForm1.Changed;
begin
    Shell_NotifyIcon(NIM_MODIFY, @fData);
end;


procedure TForm1.FormCreate(Sender: TObject);

begin
  fData.cbSize := SizeOf(fData);
  fData.Wnd := Handle;
  fData.uID := 1;
  fData.uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
  fData.uCallbackMessage := WM_TASKBARICON;
  fData.szTip := 'Screen Recorder';
  Icon.LoadFromFile('C:\ScreenRecoder\source\green.ico');
  fData.hIcon := Icon.Handle;
  Shell_NotifyIcon(NIM_ADD, @fData);


end;


procedure TForm1.FormDestroy(Sender: TObject);
begin
  Shell_NotifyIcon(NIM_DELETE, @fData);
end;



procedure TForm1.FormShow(Sender: TObject);
begin

 ShowWindow(Application.Handle, SW_HIDE);
 
end;

procedure TForm1.FormActivate(Sender: TObject);
begin

ShowWindow(Application.Handle, SW_HIDE);

end;




procedure TForm1.cleanerTimer(Sender: TObject);
var dir:string;
result : integer;
SR : tSearchRec;
begin
    dir := 'C:\ScreenRecoder\printscreens\';
    result := FindFirst (dir + '*.jpg', faAnyFile, SR);
    while result = 0 do
    begin
      if Now - FileDateToDateTime (sr.time) > 5 then
      DeleteFile (Dir + Sr.Name);
      result := FindNext (SR);
    end;
end;



procedure TForm1.FormPaint(Sender: TObject);
begin
       btnstart.Click;
end;

end.
