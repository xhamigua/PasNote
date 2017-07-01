unit UPlayer;
{$INCLUDE '..\IVersion.INC'}
interface
//{$R 'PlayRES.res' '..\res\PlayRES.rc'}
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  RealBar, FFDecode, MyUtils,
  Dialogs, ExtCtrls, StdCtrls, FFPlay, jpeg, ComCtrls,
  {$IFNDEF BPL}
  UCommon,  ShellApi, ExtDlgs, Magnetic, FFBaseComponent, Menus,
  {$ENDIF}
  UVolumeCtrlBar;
{$IFNDEF BPL}
function loadRealPanel(app:THandle;const H:Integer=0;const W:Integer=0):Boolean;stdcall;
function loadFullPanel(app:THandle;const H:Integer=0;const W:Integer=0):Boolean;stdcall;
procedure unloadReal;stdcall;                         //卸载上面创建的
function FPlayCutPic:HBITMAP;stdcall;                 //截图
procedure FPlayShowD7;stdcall;                        //D7单独显示
procedure FPlayShowModal(pvideo:string='');stdcall;   //单独显示并播放一个文件
procedure LoadPlayOneFile(tmp:WideString);stdcall;    //外部打开一个文件
function GetVLength(pvideo:string):Int64;stdcall;     //取视频时长
procedure SeekPos(pos:Int64);stdcall;                 //外定位内播放
function SetProcess:Int64;stdcall;                    //内定位外进度
procedure SetWHLength(const H:Integer=0;const W:Integer=0);stdcall;    //设置窗口的尺寸
procedure GetVideoPic(videoname,OutPath:PAnsiChar;fps:int64);cdecl;     //取出视频某一帧上的图片
{$ENDIF}
const
{$IFDEF PResdll}
  CLibAVPath = 'C:\windows\LibAV\';
{$ELSE}
  CLibAVPath = 'LibAV';
{$ENDIF}
  LICENSE_KEY = 'FSXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX';

{$IFDEF DELPHI_7} // Delphi 7
const WM_NID = WM_User + 1000;
{$ENDIF}
{$IFDEF BPL}
const
  WM_MSG_THUMBMOVED = WM_USER + 12001;
  WM_MSG_THUMBMOUSEUP = WM_USER + 12002;
type
TNotifyEvent = procedure(Sender: TObject) of object;
{$ENDIF}

type
  {$IFDEF BPL}
  xPanel = TCustomPanel;
  {$ELSE}
  xPanel = TForm;
  {$ENDIF}
  TFPlay = class(xPanel)
    PlayShow: TPanel;                 //播放区域
    Ptool: TPanel;                    //下面面板
    ImgBJ: TImage;                    //面板背景
    Imglogo: TImage;                  //播放logo
    ImgFull: TImage;                  //全屏按钮
    ImgPlayPause: TImage;             //播放暂停
    lblStatus: TLabel;                //时间
    ImgStop: TImage;                  //停止
    ImgWav: TImage;                   //静音按钮
    LabTop: TLabel;                   //置顶
    ImgSet: TImage;                   //设置按钮

    {$IFNDEF BPL}
    MenuPlay: TPopupMenu;
    NOpenPlay: TMenuItem;
    NDeskPlay: TMenuItem;
    N3: TMenuItem;
    NCut: TMenuItem;
    NRule: TMenuItem;
    MFullShow: TMenuItem;
    M4B3: TMenuItem;
    M16B9: TMenuItem;
    Mllong: TMenuItem;
    TrackBar1: TTrackBar;
    NMulte: TMenuItem;
    NFull: TMenuItem;
    MenuTray: TPopupMenu;
    Ntexit: TMenuItem;
    N2: TMenuItem;
    Mdefaut: TMenuItem;
    Mlong: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N9: TMenuItem;
    NGetVLength: TMenuItem;
    NExit: TMenuItem;
    URLUDP1: TMenuItem;
    NStop: TMenuItem;
    N1: TMenuItem;
    N7: TMenuItem;
    {$ENDIF}
    procedure ImgPlayPauseMouseEnter(Sender: TObject);
    procedure ImgPlayPauseMouseLeave(Sender: TObject);
    procedure ImgWavClick(Sender: TObject);
    procedure VolumePlayPosChanged(Sender: TObject);
    procedure FFPlayerPosition(Sender: TObject; const APTS: Int64);
    procedure FFPlayerFileOpen(Sender: TObject; const ADuration: Int64;
    AFrameWidth, AFrameHeight: Integer; var AScreenWidth, AScreenHeight: Integer);
    procedure ProBarChangeEvent(const AValue: Int64);
    procedure ImgPlayPauseClick(Sender: TObject);
    procedure ImgStopClick(Sender: TObject);              //定位(外)进度条
    procedure DoPTimerTrigger;             //(外)进度条定位播放
    procedure DoProgressLoad;              //定位(外)进度条
    {$IFDEF BPL}
    procedure ImglogoDblClick(Sender: TObject);
    {$ELSE}
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ImgBJMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure NCutClick(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;WheelDelta: Integer;
        MousePos: TPoint; var Handled: Boolean);
    procedure PtoolMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PlayShowDblClick(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure MdefautClick(Sender: TObject);
    procedure LabTopClick(Sender: TObject);
    procedure ImgFullClick(Sender: TObject);
    procedure ImgSetClick(Sender: TObject);
    procedure URLUDP1Click(Sender: TObject);
    procedure NExitClick(Sender: TObject);
    {$IF Defined(DELPHI_2010) OR Defined(DELPHI_XE5)}
    procedure ImglogoMouseActivate(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y, HitTest: Integer;var MouseActivate: TMouseActivate);
    {$IFEND}
    {$ENDIF}
  private
    Volume: TVolumeCtrlBar;     //声音进度值
    ProBar:TRealBar;            //进度条
    FFPlayer: TFFPlayer;        //播放器
    AllTime: string;            //视频全长
    Fvol: Integer;              //声音值
    OKPlayed: Boolean;          //是否成功播放文件
    Mutebool: Boolean;          //是否静音
    topbool: Boolean;           //是否置顶
    FPTimerTrigger: TNotifyEvent;         //进度条定位播放
    FPoressChangeLoad: TNotifyEvent;      //定位进度条
    FPosition: int64;           //当前播放位置
    FTrackChanging: Boolean;
    {$IFNDEF BPL}
    isPlay: Boolean;            //是否打开播放
    FCurMenu: TMenuItem;        //菜单比例选项
    FNativeFilters: Boolean;
      {$IF Defined(DELPHI_2010) OR Defined(DELPHI_XE5)}
      Tray: TTrayIcon;            //托盘
      {$IFEND}
    procedure DragFileProc(var Message: TMessage);
    procedure initPro;          //初始化
    procedure FullPlay;         //全屏播放切换
    {$ENDIF}
    procedure AppActive(Sender: TObject);  //非激活
    procedure AppActive1(Sender: TObject); // 激活
    procedure hotykey(var msg:TMessage); message WM_HOTKEY;  //快捷键
    {$IF Defined(DELPHI_2010) OR Defined(DELPHI_XE5)}
  published
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    {$IFEND}
//------------------------------------------------------------------------------
    {$IFDEF DELPHI_7}{$IFNDEF BPL}
  private
    procedure WMNID(var msg: TMessage); message WM_NID;   //托盘菜单操作
  protected
    procedure WndProc(var Message: TMessage);override;    //防止explorer崩溃
    {$ENDIF}{$ENDIF}
//------------------------------------------------------------------------------
  {$IFDEF BPL}
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Resize; override;
  {$ENDIF}
  published
    property PTimerTrigger: TNotifyEvent  read FPTimerTrigger write FPTimerTrigger;
    property PoressChangeLoad:TNotifyEvent  read FPoressChangeLoad write FPoressChangeLoad;

//##############################################################################
  private
    procedure SetMute(tmp:Boolean);
    procedure SetPos(APOS:Int64);
    procedure SetTop(tmp:Boolean);
  public
    FDuration: Int64;           //总毫秒
    property APlayState:Boolean read OKPlayed write OKPlayed;      //播放器播放状态
    property AwavMute:Boolean read Mutebool write SetMute  default False;
    property Atop:Boolean read topbool write SetTop default False;
    property APosition:int64 read FPosition write SetPos;

//    procedure LoadPlayFile(tmp:WideString);                 //命令行下的视频
    procedure PlayPauseState;                               //播放暂停
    procedure PlayStateChange(pos:Boolean);                 //修改播放状态
    procedure StopClosePlay;
    function LoadPlayFile(filename:WideString):Boolean;     //播放路径视频文件 (命令参数也用这个)
    function LoadPlayUrl(filename:string):Boolean;          //播放url视频文件
    function CutPic(const PicName:string=''):HBITMAP;       //截图
    function CutPicPIC():TJPEGImage;                        //JPG截图
    {$IFDEF BPL}
    procedure SetXY;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    {$ELSE}
    procedure WMEnterSizeMove(var Msg: TMessage); message WM_ENTERSIZEMOVE;
    procedure WMSizing(var Msg: TMessage); message WM_SIZING;
    procedure WMMoving(var Msg: TMessage); message WM_MOVING;
    procedure WMExitSizeMove(var Msg: TMessage); message WM_EXITSIZEMOVE;
    procedure WMSysCommand(var Msg: TMessage); message WM_SYSCOMMAND;
    procedure WMCommand(var Msg: TMessage); message WM_COMMAND;
    {$ENDIF}
  end;

var
  Key1,Key2,KeyPlay:Integer;
  {$IFNDEF BPL}
  FPlay: TFPlay;
  dummyHandled : boolean;
  {$ENDIF}
  
  procedure Register;
implementation
{$IFNDEF BPL}
uses UFrmConfig;
var
  OLDWndProc: TWndMethod;
  {$IFDEF DELPHI_7}
  NotifyIcon: TNotifyIconData;
  WM_TASKBARCREATED: cardinal;
  {$ENDIF}
{$R *.dfm}
{$ENDIF}

procedure Register;
begin
  RegisterComponents('AHMGbpl', [TFPlay]);
end;

//前置函数
function IsMouseDown: Boolean;
begin
  if GetSystemMetrics(SM_SWAPBUTTON) <> 0 then
    Result := GetAsyncKeyState(VK_RBUTTON) and $8000 <> 0
  else
    Result := GetAsyncKeyState(VK_LBUTTON) and $8000 <> 0;
end;

function Getvideolength(filename:string):string;
var
  FFDecoder: TFFDecoder;
  LDesirePTS: Int64;
  FCurrentPTS: Int64;
  tmp:string;
begin
  result:='';
  if not FileExists(filename) then
    begin
      result:='';
      exit;
    end;
  FFDecoder:=TFFDecoder.Create(application);
  if not FFDecoder.AVLibLoaded then
    begin
    {$IFDEF PResdll}
      if not FFDecoder.LoadAVLib(CLibAVPath) then
    {$ELSE}
      if not FFDecoder.LoadAVLib(ExePath + CLibAVPath) then
    {$ENDIF}
      begin
        freeandnil(FFDecoder);
        Exit;
      end;
    end;
//  FFDecoder.SetLicenseKey(LICENSE_KEY);

  ffdecoder.LoadFile(filename);   //载入视频
  tmp:=ffdecoder.FileInfoText;

  tmp:=trim(copy(tmp,pos('Duration:',tmp)+9,13));
  result:= tmp;
  ffdecoder.CloseFile;
  freeandnil(FFDecoder);
end;

//转毫秒
Function TimeToInt64_ms(sStr:String):Int64;
var
  hh,mm,ss,ms:integer;
begin
  hh:=StrToInt(Copy(sStr,1,2)) * 60*60*1000;
  mm:=StrToInt(Copy(sStr,4,2)) * 60*1000;
  ss:=StrToInt(Copy(sStr,7,2)) * 1000;
  if Copy(sStr,10,3)<>'' then
    ms:=StrToInt(Copy(sStr,10,3))
  else
    ms:=0;
  Result:=(hh + mm + ss + ms);
end;

function OpenDlg(strdefault:string):string;stdcall;
var
  open:TOpenDialog;
begin
  open:=TOpenDialog.Create(nil);
  if strdefault='' then open.InitialDir:='c:\'
  else
  open.InitialDir:= strdefault; //初始路径
  if open.Execute() then
  begin
    if Length(open.FileName)<1 then Result:=''
    else
    Result:= open.FileName
  end;
  open.Free;
end;

//******************************************************************************
{$IFNDEF BPL}
function loadRealPanel(app:THandle;const H:Integer=0;const W:Integer=0):Boolean;stdcall;
begin
  Application.Handle:=app;
  FPlay:=TFPlay.Create(Application);
  FPlay.ParentWindow:=Application.Handle;
  FPlay.BorderStyle:=bsNone;

  with FPlay do
  begin
    Position:=poDefault;                                 // FPlay.OnResize:=nil;
    Top:=0;                                              //  FPlay.WindowState:=wsMaximized;
    Left:=0;                                             //  FPlay.Align:=alClient;
    Constraints.MinHeight := 335;
    Constraints.MinWidth := 544;
    Width:=w;
    Height:=H;
  end;
  FPlay.Align:=alNone;
  FPlay.Show;
  Result:=True;
end;

function loadFullPanel(app:THandle;const H:Integer=0;const W:Integer=0):Boolean;stdcall;
begin
  Application.Handle:=app;
  FPlay:=TFPlay.Create(Application);
  FPlay.ParentWindow:=Application.Handle;
  FPlay.BorderStyle:=bsNone;
  with FPlay do
  begin
    Position:=poDefault;
    Top:=0;
    Left:=0;
    if Width>0 then
    begin
      Width:=w;
      Height:=H;
    end;
  end;
  FPlay.Align:=alNone;
  FPlay.Show;
  FPlay.Imglogo.OnDblClick:= FPlay.PlayShowDblClick;
  FPlay.Imglogo.OnClick:= FPlay.ImgPlayPauseClick;

  FPlay.Ptool.Height:= FPlay.ProBar.Height;
  FPlay.PlayShow.Align:=alClient;
  FPlay.Nexit.Visible:=False;
  FPlay.NFull.Visible:=False;
  Result:=True;
end;

procedure unloadReal;stdcall;
begin
//  FPlay.FFPlayer.Stop(True);
  FPlay.Free;
end;

function FPlayCutPic:HBITMAP;stdcall;
begin
  Result:=FPlay.CutPic;
end;

procedure FPlayShowD7;stdcall;
begin
  //CreateMag;  //创建类
  // Set Snap width
  //MagneticWnd.SnapWidth := 15;
  FPlay:=TFPlay.Create(nil);
//  FPlay.SetLock:=True;
  if not MagneticWnd.AddWindow(FPlay.Handle, 0, MagneticWndProc) then exit;
  // Subclassing sub form, the original Window Proc is saved in its own 32-bit value space.
  SetWindowLong(FPlay.Handle, GWL_USERDATA, GetWindowLong(FPlay.Handle, GWL_WNDPROC));  // Save Original Window Proc
  SetWindowLong(FPlay.Handle, GWL_WNDPROC, Integer(@SubFormWindowProc));
  FPlay.ShowModal;
  FPlay.Free;

  //DestMag;    //销毁类
end;

procedure FPlayShowModal(pvideo:string);stdcall;
begin
  FPlay:=TFPlay.Create(Application);
  with FPlay do
  begin
    Imglogo.OnMouseDown:= PtoolMouseDown;
    ImgBJ.OnMouseDown:= ImgBJMouseDown;
    lblStatus.OnMouseDown:= ImgBJMouseDown;
    if Length(pvideo)>0 then FPlay.LoadPlayFile(pvideo);
    ShowModal;
    Free;
  end;
end;

procedure LoadPlayOneFile(tmp:WideString);stdcall;
begin
  FPlay.FFPlayer.Stop(True);
  FPlay.PlayShow.Invalidate;
  FPlay.LoadPlayFile(tmp);
end;

function GetVLength(pvideo:string):Int64;stdcall;  //取得指定文件的长度，如果视频不存在返回-1
var
  FFDecoder: TFFDecoder;
  LDesirePTS: Int64;
  FCurrentPTS: Int64;
  tmp:string;

    Function Fn_TimeToInt64_ms(sStr:String):Int64;
    var
      hh,mm,ss,ms:integer;
    begin
      hh:=StrToInt(Copy(sStr,1,2)) * 60*60*1000;
      mm:=StrToInt(Copy(sStr,4,2)) * 60*1000;
      ss:=StrToInt(Copy(sStr,7,2)) * 1000;
      if Copy(sStr,10,3)<>'' then
        ms:=StrToInt(Copy(sStr,10,3))
      else
        ms:=0;
      Result:=(hh + mm + ss + ms);
    end;//转整型
begin
  result:=0;
  if not FileExists(pvideo) then
    begin
      result:=-1;
      exit;
    end;
  FFDecoder:=TFFDecoder.Create(application);
  if not FFDecoder.AVLibLoaded then
    begin
    {$IFDEF PResdll}
      if not FFDecoder.LoadAVLib(CLibAVPath) then
    {$ELSE}
      if not FFDecoder.LoadAVLib(ExePath + CLibAVPath) then
    {$ENDIF}
      begin
        freeandnil(FFDecoder);
        Exit;
      end;
    end;
  FFDecoder.SetLicenseKey(LICENSE_KEY);

  ffdecoder.LoadFile(pvideo);   //载入视频
  tmp:=ffdecoder.FileInfoText;
//  showmessage(tmp);
 // showmessage(inttostr(pos('Duration:',tmp)));
  tmp:=trim(copy(tmp,pos('Duration:',tmp)+9,13));
//  showmessage(tmp);
 // result:=ffdecoder.FileStreamInfo.Duration div 1000;
  result:=  Fn_TimeToInt64_ms(tmp);
  ffdecoder.CloseFile;
  freeandnil(FFDecoder);
end;

procedure SeekPos(pos:Int64);stdcall;
begin
  FPlay.FFPlayer.Seek(FPlay.FDuration * pos);
end;

function SetProcess:Int64;stdcall;
begin
  Result := FPlay.FPosition div FPlay.FDuration;
end;

procedure SetWHLength(const H:Integer=0;const W:Integer=0);stdcall;
begin
  with FPlay do
  begin
    Top:=0;
    Left:=0;
    Width:=w;
    Height:=H;
  end;
end;

//从视频中的某一帧上抓图
procedure GetVideoPic(videoname,OutPath:PAnsiChar;fps:int64);cdecl;
var
  FFDecoder: TFFDecoder;
  FBitmap: tBitmap;
  LDesirePTS: Int64;
  FCurrentPTS: Int64;
begin
//  ShowMessage(IntToStr(fps));
  FFDecoder:=TFFDecoder.Create(application);
  fbitmap:=tbitmap.Create;
  if not FFDecoder.AVLibLoaded then
  begin
  {$IFDEF PResdll}
//    ShowMessage(CLibAVPath);
    if not FFDecoder.LoadAVLib(CLibAVPath) then
  {$ELSE}
    if not FFDecoder.LoadAVLib(ExePath + CLibAVPath) then
  {$ENDIF}
    begin
      freeandnil(FFDecoder);
      Exit;
    end;
  end;
  FFDecoder.SetLicenseKey(LICENSE_KEY);
  FFDecoder.LoadFile(videoname);   //载入视频


  if (FFDecoder.VideoStreamCount <= 0) then
  begin   //如果为空
    freeandnil(FFDecoder);
    freeandnil(FBitmap);
    Exit;
  end;
  try
    LDesirePTS:=fps * 1000;
    { //该变量 大致上 一豪秒是1000
    LDesirePTS:=1000*1000;   //一秒钟
    //LDesirePTS:=LDesirePTS*60*2+30*LDesirePTS+200;  //2分钟30秒200毫秒时
    LDesirePTS:=LDesirePTS*60*1+20*LDesirePTS+300;  //1分钟20秒300毫秒时}
    if FFDecoder.Seek(LDesirePTS) or
      FFDecoder.Seek(LDesirePTS, [sfBackward]) or
      FFDecoder.Seek(LDesirePTS, [sfAny]) then
    begin
      while FFDecoder.Decode do
      begin
        if (FFDecoder.FrameInfo.PTS >= LDesirePTS) or (LDesirePTS <= 0) then
        begin
          if FFDecoder.FrameInfo.PTS <> AV_NOPTS_VALUE then
            FCurrentPTS := FFDecoder.FrameInfo.PTS
          else
            FCurrentPTS := 0;
          if ffdecoder.CopyToBitmap(FBitmap) then
            with TJPEGImage.Create do
            try
              Assign(FBitmap);
              SaveToFile(OutPath);
            finally
              Free;
            end
          else
          begin
            freeandnil(FFDecoder);
            freeandnil(FBitmap);
            exit;
          end;
          break;
        end;
      end;
    end ;
    FFDecoder.closefile;
    ffdecoder.free;

    freeandnil(FBitmap);
  except
    on e:exception do
    begin
      FFDecoder.closefile;
      ffdecoder.UnloadAVLib;
      ffdecoder.free;
      freeandnil(FBitmap);
    end;
  end;
end;
{$ENDIF}
//******************************************************************************

{$IFDEF DELPHI_7} // Delphi 7
procedure GetBorderStyles(AForm: TCustomForm; ABorderStyle: TFormBorderStyle;
  var Style, ExStyle, ClassStyle: Cardinal);
begin
  // Clear existing border styles
  Style := Style and not (WS_POPUP or WS_CAPTION or WS_BORDER or WS_THICKFRAME or WS_DLGFRAME or DS_MODALFRAME);
  ExStyle := ExStyle and not (WS_EX_DLGMODALFRAME or WS_EX_WINDOWEDGE or WS_EX_TOOLWINDOW);
  ClassStyle := ClassStyle and not (CS_SAVEBITS or CS_BYTEALIGNWINDOW);

  // Set new border styles
  case ABorderStyle of
    bsNone:
      if (AForm.Parent = nil) and (AForm.ParentWindow = 0) then
        Style := Style or WS_POPUP;
    bsSingle, bsToolWindow:
      Style := Style or (WS_CAPTION or WS_BORDER);
    bsSizeable, bsSizeToolWin:
      Style := Style or (WS_CAPTION or WS_THICKFRAME);
    bsDialog:
      begin
        Style := Style or WS_POPUP or WS_CAPTION;
        ExStyle := ExStyle or WS_EX_DLGMODALFRAME or WS_EX_WINDOWEDGE;
        if not NewStyleControls then
          Style := Style or WS_DLGFRAME or DS_MODALFRAME;
        ClassStyle := ClassStyle or CS_DBLCLKS or CS_SAVEBITS or CS_BYTEALIGNWINDOW;
      end;
  end;
  if ABorderStyle in [bsToolWindow, bsSizeToolWin] then
    ExStyle := ExStyle or WS_EX_TOOLWINDOW;
end;
procedure GetBorderIconStyles(AForm: TCustomForm; ABorderStyle: TFormBorderStyle;
  var Style, ExStyle: Cardinal);
var
  LIcons: TBorderIcons;
begin
  // Clear existing border icon styles
  Style := Style and not (WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_SYSMENU);
  ExStyle := ExStyle and not WS_EX_CONTEXTHELP;

  // Adjust icons based on border style
  LIcons := TForm(AForm).BorderIcons;
  case ABorderStyle of
    bsNone: LIcons := [];
    bsDialog: LIcons := LIcons * [biSystemMenu, biHelp];
    bsToolWindow,
    bsSizeToolWin: LIcons := LIcons * [biSystemMenu];
  end;

  // Set border icon styles
  if ABorderStyle in [bsSingle, bsSizeable, bsNone] then
  begin
    if biMinimize in LIcons then Style := Style or WS_MINIMIZEBOX;
    if biMaximize in LIcons then Style := Style or WS_MAXIMIZEBOX;
  end;
  if biSystemMenu in LIcons then Style := Style or WS_SYSMENU;
  if biHelp in LIcons then ExStyle := ExStyle or WS_EX_CONTEXTHELP;
end;
procedure SetBorderStyle(AForm: TCustomForm; ABorderStyle: TFormBorderStyle);
var
  LStyle, LExStyle, LClassStyle: Cardinal;
  LIcon: HICON;
begin
  LStyle := GetWindowLong(AForm.Handle, GWL_STYLE);
  LExStyle := GetWindowLong(AForm.Handle, GWL_EXSTYLE);
  LClassStyle := GetClassLong(AForm.Handle, GCL_STYLE);

  GetBorderStyles(AForm, ABorderStyle, LStyle, LExStyle, LClassStyle);
  GetBorderIconStyles(AForm, ABorderStyle, LStyle, LExStyle);

  SetWindowLong(AForm.Handle, GWL_STYLE, LStyle);
  SetWindowLong(AForm.Handle, GWL_EXSTYLE, LExStyle);
  SetClassLong(AForm.Handle, GCL_STYLE, LClassStyle);

  // Update icon on window frame
  if NewStyleControls then
    if ABorderStyle <> bsDialog then
    begin
      LIcon := TForm(AForm).Icon.Handle;
      if LIcon = 0 then LIcon := Application.Icon.Handle;
      if LIcon = 0 then LIcon := LoadIcon(0, IDI_APPLICATION);
      SendMessage(AForm.Handle, WM_SETICON, ICON_BIG, LIcon);
    end
    else
      SendMessage(AForm.Handle, WM_SETICON, ICON_BIG, 0);

  // Reset system menu based on new border style
  GetSystemMenu(AForm.Handle, True);
  AForm.Perform(WM_NCCREATE, 0, 0);

  SetWindowPos(AForm.Handle, 0, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or
    SWP_NOZORDER or SWP_NOSIZE or SWP_NOACTIVATE);
  AForm.Invalidate;
end;
procedure SetStayOnTop(AHandle: HWND; AStayOnTop: Boolean);
const
  HWND_STYLE: array[Boolean] of HWND = (HWND_NOTOPMOST, HWND_TOPMOST);
begin
  SetWindowPos(AHandle, HWND_STYLE[AStayOnTop], 0, 0, 0, 0,
    SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);
end;

{$IFNDEF BPL}
procedure TFPlay.WndProc(var Message: TMessage);
begin
  if Message.Msg= WM_TASKBARCREATED then
  Shell_NotifyIcon(NIM_ADD, @NotifyIcon); // 在托盘区显示图标
  inherited WndProc(Message);
end;

procedure TFPlay.WMNID(var msg: TMessage);
var
  mousepos: TPoint;
begin
  GetCursorPos(mousepos); //获取鼠标位置
  case msg.LParam of
    WM_LBUTTONUP: // 在托盘区点击左键后
      begin
        //FormServer.Visible := not FormServer.Visible; // 显示主窗体与否
        inherited;
        //Shell_NotifyIcon(NIM_DELETE, @NotifyIcon); // 显示主窗体后删除托盘区的图标
        //SetWindowPos(Application.Handle, HWND_TOP, 0, 0, 0, 0, SWP_SHOWWINDOW); // 在任务栏显示程序
      end;
    WM_RBUTTONUP:MenuTray.Popup(mousepos.X, mousepos.Y); // 右键弹出菜单
  end;
end;
{$ENDIF}
{$ENDIF}  

procedure TFPlay.ImgPlayPauseMouseEnter(Sender: TObject);
begin
  TImage(Sender).Top:= TImage(Sender).Top+1;
  TImage(Sender).Left:= TImage(Sender).Left+1;
end;

procedure TFPlay.ImgPlayPauseMouseLeave(Sender: TObject);
begin
  TImage(Sender).Top:= TImage(Sender).Top-1;
  TImage(Sender).Left:= TImage(Sender).Left-1;
end;

procedure TFPlay.ImgWavClick(Sender: TObject);
begin
  AwavMute:= not AwavMute;
end;

procedure TFPlay.VolumePlayPosChanged(Sender: TObject);
begin             //max 128  //trbAudioVolume.Max - trbAudioVolume.Position;
  if Volume.position=0 then
  begin
    AwavMute:=True;
  end else begin
    Fvol:= Volume.position;
    FFPlayer.Mute := False;
    ImgWav.Picture.Graphic.LoadFromStream(TResourceStream.Create(HInstance, 'ImgWav', 'jpgtype'));
    Mutebool:= False;
  end;
  FFPlayer.AudioVolume := Volume.position;
end;

procedure TFPlay.FFPlayerPosition(Sender: TObject; const APTS: Int64);
var
  showtall:string;
begin
  //显示时间     注意APTS就是播放位置
  if Length(AllTime)<1 then showtall:='' else showtall:= '/'+AllTime;
  lblStatus.Caption := DurationToStr(APTS div 1000)+showtall;
  if (APTS >= 0) and (FDuration > 0) then
  begin
//    TrackBar1.SelEnd := TrackBar1.Max * APTS div FDuration;
    if not FTrackChanging and not IsMouseDown then
    begin
      FTrackChanging := True;
      try
        //定位进度
        ProBar.Position := ProBar.AMax * APTS div FDuration;
        FPosition:= APTS div 1000;
        DoProgressLoad;     //定位外部进度条
//        TrackBar1.Position := TrackBar1.Max * APTS div FDuration;
      finally
        FTrackChanging := False;
      end;
    end;
  end;
  if ProBar.Position = ProBar.AMax then
  begin
    FFPlayer.Stop(true);
    PlayShow.Invalidate;
    ProBar.Position :=0;
  end;
end;

procedure TFPlay.FFPlayerFileOpen(Sender: TObject; const ADuration: Int64;
  AFrameWidth, AFrameHeight: Integer; var AScreenWidth, AScreenHeight: Integer);
begin
  FDuration := ADuration;
//  lblDuration.Caption := Format('%f', [ADuration / 1000000]);
//  lblCurrentPTS.Caption := '0.0';

  // setup track bar
//  TrackBar1.Frequency := 5;
//  TrackBar1.TickStyle := tsAuto;
//  TrackBar1.Max :=ADuration;// TrackBar1.Width;
//  TrackBar1.SelStart := 0;  //蓝色区域开始位置
//  TrackBar1.SelEnd := 0;    //蓝色区域结束位置
//  TrackBar1.SliderVisible := ADuration > 0;
  ProBar.AMax:= ADuration;
//  ShowMessage(IntToStr(ADuration));

  FTrackChanging := True;
  try
//    TrackBar1.Position := 0;
  finally
    FTrackChanging := False;
  end;
end;

procedure TFPlay.ProBarChangeEvent(const AValue: Int64);
begin
  if not FTrackChanging and not IsMouseDown then
  FFPlayer.Seek(FDuration * ProBar.Position div ProBar.AMax);
end;

procedure TFPlay.ImgPlayPauseClick(Sender: TObject);
begin
  PlayPauseState;
end;

procedure TFPlay.ImgStopClick(Sender: TObject);
begin
  ImgPlayPause.Picture.Graphic.LoadFromStream(TResourceStream.Create(HInstance, 'ImgPlay', 'jpgtype'));
  FFPlayer.Stop(True);
  PlayShow.Invalidate;
  OKPlayed:=False;
end;

procedure TFPlay.DoPTimerTrigger;
begin
  if Assigned(FPTimerTrigger) then
    FPTimerTrigger(Self);
end;

procedure TFPlay.DoProgressLoad;
begin
  if Assigned(FPoressChangeLoad) then
    FPoressChangeLoad(Self);
end;

procedure TFPlay.AppActive(Sender: TObject);
begin
  //注销快捷键       //非激活
  UnRegisterHotKey(handle,Key1);
  UnRegisterHotKey(handle,Key2);
  UnRegisterHotKey(handle,KeyPlay);
end;

procedure TFPlay.AppActive1(Sender: TObject);
begin
  //启动快捷键
  RegisterHotkey(Handle,Key1,0,70); //F是70
//  RegisterHotKey(handle,Key1,mod_control,49);
  RegisterHotkey(Handle,Key2,0,VK_F1);
  RegisterHotkey(Handle,KeyPlay,0,VK_SPACE);
end;

procedure TFPlay.hotykey(var msg: TMessage);
begin
  {$IFNDEF BPL}
  if FPlay.Active then
  begin
    if (msg.LParamHi=70)  then  //全屏
    FullPlay;
    if (msg.LParamHi=VK_SPACE) then   //播放暂停
    PlayPauseState;
  end ;
  {$ENDIF}
end;

procedure TFPlay.SetMute(tmp: Boolean);
begin
  FFPlayer.Mute := tmp;     //调为静音
  if tmp then
  begin                                               //  HInstance
    ImgWav.Picture.Graphic.LoadFromStream(TResourceStream.Create(HInstance, 'ImgNoWav', 'jpgtype'));
    FFPlayer.AudioVolume := 0;
    Volume.position:=0;
  end else begin
    ImgWav.Picture.Graphic.LoadFromStream(TResourceStream.Create(HInstance, 'ImgWav', 'jpgtype'));
    Volume.position:=Fvol;
    FFPlayer.AudioVolume:=Fvol;
  end;
  Mutebool:= tmp;
end;

procedure TFPlay.SetPos(APOS: Int64);
begin
  FFPlayer.Seek(APOS * 1000);
end;

procedure TFPlay.SetTop(tmp: Boolean);
begin
  {$IFNDEF BPL}
  if tmp then
  begin
    {$IFDEF DELPHI_7}
    SetStayOnTop(Self.Handle, True);
    {$ELSE}
    Self.FormStyle:=fsStayOnTop;
    {$ENDIF}
    Self.LabTop.Font.Color:=RGB(155,155,155);
  end else begin
    {$IFDEF DELPHI_7}
    SetStayOnTop(Self.Handle, False);
    {$ELSE}
    Self.FormStyle:=fsNormal;
    {$ENDIF}
    Self.LabTop.Font.Color:=RGB(255,255,255);
  end;
  topbool:=tmp;
  {$ENDIF}
end;

function TFPlay.LoadPlayFile(filename: WideString):Boolean;
var
  ttmp: string;
  FFDecoder: TFFDecoder;
begin
  Result:=False;
  if not FFPlayer.AVLibLoaded then
  begin
    {$IFDEF PResdll}
    if not FFPlayer.LoadAVLib(CLibAVPath) then Exit;
    {$ELSE}
    if not FFPlayer.LoadAVLib(extractfilepath(ParamStr(0)) + CLibAVPath) then Exit;
    {$ENDIF}
  end;
  if Length(filename)<1 then Exit;

  FFDecoder:=TFFDecoder.Create(application);
  ffdecoder.LoadFile(filename);   //载入视频
  ttmp:=ffdecoder.FileInfoText;
  ttmp:=trim(copy(ttmp,pos('Duration:',ttmp)+9,13));;
  AllTime:=ttmp;
  FDuration:=TimeToInt64_ms(ttmp);
  ffdecoder.CloseFile;
  freeandnil(FFDecoder);

  if not FFPlayer.Open(filename, PlayShow.Handle) then
  begin
    ImgPlayPause.Picture.Graphic.LoadFromStream(TResourceStream.Create(HInstance, 'ImgPlay', 'jpgtype'));
    FFPlayer.Stop(True);
    PlayShow.Invalidate;
    OKPlayed:=False;
    Exit;
  end;
  OKPlayed:=True;
  ImgPlayPause.Picture.Graphic.LoadFromStream(TResourceStream.Create(HInstance, 'ImgPause', 'jpgtype'));
  Result:=True;
end;

procedure TFPlay.PlayPauseState;
begin
  if not OKPlayed then Exit;

  if FFPlayer.Paused then
  begin
    FFPlayer.Resume;
    ImgPlayPause.Picture.Graphic.LoadFromStream(TResourceStream.Create(HInstance, 'ImgPause', 'jpgtype'));
  end else begin
    FFPlayer.TogglePause;   //    FFPlayer.Pause;
    ImgPlayPause.Picture.Graphic.LoadFromStream(TResourceStream.Create(HInstance, 'ImgPlay', 'jpgtype'));
  end;
end;

procedure TFPlay.PlayStateChange(pos: Boolean);
begin
//  FFPlayer.TogglePause;
//  FFPlayer.Pause;
//  exit;
  if pos then FFPlayer.Resume
  else FFPlayer.TogglePause;
end;

procedure TFPlay.StopClosePlay;
begin
  ImgPlayPause.Picture.Graphic.LoadFromStream(TResourceStream.Create(HInstance, 'ImgPlay', 'jpgtype'));
  FFPlayer.Stop(True);
  PlayShow.Invalidate;
  OKPlayed:=False;
end;

function TFPlay.LoadPlayUrl(filename: string):Boolean;
var
  LScreenHandle: HWND;
  LPngFile: string;
  ttmp: string;
  FFDecoder: TFFDecoder;
begin
  Result:=False;
  if not FFPlayer.AVLibLoaded then
  begin
    {$IFDEF PResdll}
    if not FFPlayer.LoadAVLib(CLibAVPath) then Exit;
    {$ELSE}
    if not FFPlayer.LoadAVLib(extractfilepath(ParamStr(0)) + CLibAVPath) then Exit;
    {$ENDIF}
  end;

//  URL:='udp://@225.1.1.1:3000';
  FFPlayer.ReadTimeout := 1000 * 60;
  //if not InputQuery('打开', 'URL(or Filename)', tmp) or (Trim(tmp) = '') then Exit;
  FFDecoder:=TFFDecoder.Create(application);
  ffdecoder.LoadFile(filename);   //载入视频
  ttmp:=ffdecoder.FileInfoText;
  ttmp:=trim(copy(ttmp,pos('Duration:',ttmp)+9,13));;
  AllTime:=ttmp;
  FDuration:=TimeToInt64_ms(ttmp);
  ffdecoder.CloseFile;
  freeandnil(FFDecoder);

  if not FFPlayer.Open(filename, PlayShow.Handle) then Exit;
  OKPlayed:=True;
  ImgPlayPause.Picture.Graphic.LoadFromStream(TResourceStream.Create(HInstance, 'ImgPause', 'jpgtype'));
  Result:=True;
end;

function TFPlay.CutPic(const PicName: string): HBITMAP;
var
  BMP: TBitmap;
begin
  BMP := TBitmap.Create;
  try
    BMP.Assign(FFPlayer.CurrentFrame);
    Result:=BMP.Handle;
    if BMP.Width > 0 then
    begin
      with TJPEGImage.Create do
      try
        Assign(BMP);
        if Length(PicName)>0 then SaveToFile(PicName);
      finally
        Free;
      end;
    end;
  finally
    BMP.Free;
  end;
end;

function TFPlay.CutPicPIC: TJPEGImage;
var
  BMP: TBitmap;
begin
  BMP := TBitmap.Create;
  try
    BMP.Assign(FFPlayer.CurrentFrame);
    if BMP.Width > 0 then
    begin
      //with TJPEGImage.Create do
      Result:= TJPEGImage.Create;
      try
        Result.Assign(BMP);
      finally
//        Free;
      end;
    end;
  finally
    BMP.Free;
  end;
end;

{$IFDEF BPL}

procedure TFPlay.ImglogoDblClick(Sender: TObject);
var
  filename: string;
begin
  if not FFPlayer.AVLibLoaded then
  begin
    {$IFDEF PResdll}
    if not FFPlayer.LoadAVLib(CLibAVPath) then Exit;
    {$ELSE}
    if not FFPlayer.LoadAVLib(extractfilepath(ParamStr(0)) + CLibAVPath) then Exit;
    {$ENDIF}
  end;
  filename:= OpenDlg('D:\');
  if Length(filename)<1 then  Exit;
  LoadPlayFile(filename);
end;

procedure TFPlay.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if Key = VK_SPACE then
  begin
    ShowMessage('VK_SPACE');
//    APlayPause:=NOT APlayPause;
  end;
  if Key = VK_F1 then
  begin
    ShowMessage('VK_F1');
  end;
end;

procedure TFPlay.Resize;
begin
  inherited;
  SetXY;
end;

procedure TFPlay.SetXY;
begin
  //下面是一些控件位置调整
  ImgWav.Left := Self.Width-125; //声音按钮
  ImgFull.Left := Self.Width-46; //全屏按钮
  LabTop.Left := Self.Width-197; //top按钮
  ImgSet.Left := Self.Width-159; //设置按钮
  Volume.Left := Self.Width-101; //声音进度
end;

constructor TFPlay.Create(AOwner: TComponent);
var
  jpg: TJPEGImage;
begin
  inherited;
  Fvol:=128;
  Self.Width:=553;
  Self.Caption:='';
  Self.BevelOuter := bvNone;
  Self.BorderStyle:= bsNone;
  Self.Constraints.MinHeight := 335;
  Self.Constraints.MinWidth := 544;

  //创建播放控件
  FFPlayer := TFFPlayer.Create(Self);
  FFPlayer.OnPosition := FFPlayerPosition;
  FFPlayer.OnFileOpen := FFPlayerFileOpen;
  FFPlayer.AspectRatio := 0;//-1;
  FFPlayer.FrameHook:=True;
  //下面面板
  Ptool := TPanel.Create(Self);
  Ptool.Parent := Self;
  Ptool.Caption:='';
  Ptool.Height := 50;
  Ptool.Align := alBottom;
  Ptool.BevelOuter := bvNone;
  Ptool.Color:= clBlack;
//  Ptool.OnMouseDown := ImgBJMouseDown;
  //背景
  jpg := TJPEGImage.Create;
  ImgBJ := TImage.Create(Ptool);
  ImgBJ.Parent := Ptool;
  ImgBJ.Align := alClient;
  ImgBJ.Stretch := True;
  jpg.LoadFromStream(TResourceStream.Create(HInstance, 'ImgBj', 'jpgtype'));
  ImgBJ.Picture.Assign(jpg);
  //全屏按钮
  ImgFull := TImage.Create(Ptool);
  ImgFull.Parent := Ptool;
  ImgFull.Left := Self.Width-46;
  ImgFull.Top := 20000;//20;
  ImgFull.Width := 33;
  ImgFull.Height := 25;
  ImgFull.AutoSize := True;
  jpg.LoadFromStream(TResourceStream.Create(HInstance, 'ImgFull', 'jpgtype'));
  ImgFull.Picture.Assign(jpg);

//  ImgFull.OnMouseEnter := ImgPlayPauseMouseEnter;
//  ImgFull.OnMouseLeave := ImgPlayPauseMouseLeave;
//  ImgFull.OnClick := ImgFullClick;
  //暂停播放
  ImgPlayPause := TImage.Create(Ptool);
  ImgPlayPause.Parent := Ptool;
  ImgPlayPause.Left := 6;
  ImgPlayPause.Top := 20;
  ImgPlayPause.Width := 41;
  ImgPlayPause.Height := 25;
  ImgPlayPause.Stretch := True;
  jpg.LoadFromStream(TResourceStream.Create(HInstance, 'ImgPlay', 'jpgtype'));
  ImgPlayPause.Picture.Assign(jpg);
//  ImgPlayPause.OnMouseEnter := ImgPlayPauseMouseEnter;
//  ImgPlayPause.OnMouseLeave := ImgPlayPauseMouseLeave;
  ImgPlayPause.OnClick := ImgPlayPauseClick;
  //停止
  ImgStop := TImage.Create(Ptool);
  ImgStop.Parent := Ptool;
  ImgStop.Left := 50;
  ImgStop.Top := 20000;//20;
  ImgStop.Width := 41;
  ImgStop.Height := 25;
  ImgStop.Stretch := True;
  jpg.LoadFromStream(TResourceStream.Create(HInstance, 'ImgStop', 'jpgtype'));
  ImgStop.Picture.Assign(jpg);
//  ImgStop.OnMouseEnter := ImgPlayPauseMouseEnter;
//  ImgStop.OnMouseLeave := ImgPlayPauseMouseLeave;
  ImgStop.OnClick := ImgStopClick;
  //lblStatus
  lblStatus := TLabel.Create(Ptool);
  lblStatus.Parent := Ptool;
  lblStatus.Left := 50;//98;
  lblStatus.Top := 23;
  lblStatus.Width := 193;
  lblStatus.Height := 17;
  lblStatus.Caption := '00:00:00.000/00:00:00.000';
  lblStatus.Font.Color := clWhite;
  lblStatus.Font.Height := -13;
  lblStatus.Font.Name := '微软雅黑';
  lblStatus.Font.Style := [fsBold];
  lblStatus.ParentFont := False;
  lblStatus.Transparent := True;

  //ImgWav
  ImgWav := TImage.Create(Ptool);
  ImgWav.Parent := Ptool;
  ImgWav.Top := 25;
  ImgWav.Width := 14;
  ImgWav.Height := 14;
  ImgWav.AutoSize := True;
  jpg.LoadFromStream(TResourceStream.Create(HInstance, 'ImgWav', 'jpgtype'));
  ImgWav.Picture.Assign(jpg);
  ImgWav.OnClick := ImgWavClick;
  //LabTop
  LabTop := TLabel.Create(Ptool);
  LabTop.Parent := Ptool;
  LabTop.Top :=20000;// 23;
  LabTop.Width := 23;
  LabTop.Height := 16;
  LabTop.Caption := 'Top';
  LabTop.Font.Charset := ANSI_CHARSET;
  LabTop.Font.Color := clWhite;
  LabTop.Font.Height := -12;
  LabTop.Font.Name := '微软雅黑';
  LabTop.ParentFont := False;
  LabTop.Transparent := True;
//  LabTop.OnClick := LabTopClick;
  //ImgSet
  ImgSet := TImage.Create(Ptool);
  ImgSet.Parent := Ptool;
  ImgSet.Top := 20000;//23;
  ImgSet.Width := 18;
  ImgSet.Height := 18;
  jpg.LoadFromStream(TResourceStream.Create(HInstance, 'ImgSet', 'jpgtype'));
  ImgSet.Picture.Assign(jpg);
//  ImgSet.Anchors := [akTop, akRight];
  ImgSet.AutoSize := True;
//  ImgSet.OnClick := ImgSetClick;
  //Volume
  Volume := TVolumeCtrlBar.Create(Self);
  Volume.Parent := Ptool;
  Volume.Top := 24;
  Volume.Width := 92;
  Volume.Height := 17;
  Volume.Transparent := False;
  Volume.Max := 128;
  Volume.Position := 128;
  Volume.OnPlayPosChanged := VolumePlayPosChanged;
  SetXY;    //设置右对齐的控件
  //PlayShow
  PlayShow := TPanel.Create(Self);
  PlayShow.Caption:='';
  PlayShow.Parent := Self;
  PlayShow.Align := alClient;
  PlayShow.BevelOuter := bvNone;
  PlayShow.Color := 0;
  PlayShow.ParentBackground := False;
  PlayShow.TabOrder := 0;
//  PlayShow.OnDblClick := PlayShowDblClick;
  //Imglogo
  Imglogo := TImage.Create(PlayShow);
  Imglogo.Parent := PlayShow;
  Imglogo.Left := 0;
  Imglogo.Top := 0;
  Imglogo.Width := 694;
  Imglogo.Height := 326;
  Imglogo.Align := alClient;
  Imglogo.Center := True;
  jpg.LoadFromStream(TResourceStream.Create(HInstance, 'ImgLogo', 'jpgtype'));
  Imglogo.Picture.Assign(jpg);
//  Imglogo.PopupMenu := MenuPlay;
  Imglogo.Transparent := True;
  Imglogo.OnClick:= ImgPlayPauseClick;
  Imglogo.OnDblClick := ImglogoDblClick;

  //创建进度条控件
  ProBar:=TRealBar.Create(Ptool);
  ProBar.Parent:=Ptool;
  ProBar.Align:=altop;
  ProBar.Height:=15;
  ProBar.ProChangeEvent:=ProBarChangeEvent;

  Application.OnDeactivate := AppActive;
  Application.OnActivate:=AppActive1;

  OKPlayed:=False;
end;

destructor TFPlay.Destroy;
begin
  FFPlayer.Stop(True);
  PlayShow.Invalidate;
  inherited;
end;

{$ELSE}

procedure TFPlay.FormCreate(Sender: TObject);
begin
{$IFDEF Pdll} {$ELSE}
  {$IFDEF DELPHI_7} //D7创建托盘
  WM_TASKBARCREATED:= RegisterWindowMessage('TaskbarCreated');   //防止explorer崩溃注册
  with NotifyIcon do
  begin
    cbSize := SizeOf(TNotifyIconData);
    Wnd := Handle;
    uID := 1;
    uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
    uCallBackMessage := WM_NID;
    hIcon := Application.Icon.Handle; //取图片
//    hIcon:=LoadIcon(HInstance,'AppIcon');  //取资源的图片
  end;
  Shell_NotifyIcon(NIM_ADD, @NotifyIcon); // 在托盘区显示图标
  {$ENDIF}
  {$IF Defined(DELPHI_2010) OR Defined(DELPHI_XE5)}
  //2010创建托盘
  Tray := TTrayIcon.Create(Self);
  Tray.PopupMenu := MenuTray;
  Tray.Visible := True;

  //以下D7不能通过
  ImgPlayPause.OnMouseEnter := ImgPlayPauseMouseEnter;
  ImgPlayPause.OnMouseLeave := ImgPlayPauseMouseLeave;
  ImgStop.OnMouseEnter := ImgPlayPauseMouseEnter;
  ImgStop.OnMouseLeave := ImgPlayPauseMouseLeave;
  ImgFull.OnMouseEnter := ImgPlayPauseMouseEnter;
  ImgFull.OnMouseLeave := ImgPlayPauseMouseLeave;
  Imglogo.OnMouseActivate := ImglogoMouseActivate;
  {$IFEND}
  Imglogo.OnMouseDown:= PtoolMouseDown;
  ImgBJ.OnMouseDown:= ImgBJMouseDown;
  lblStatus.OnMouseDown:= ImgBJMouseDown;
{$ENDIF}
  //创建播放控件
  FFPlayer := TFFPlayer.Create(Self);
  FFPlayer.OnPosition := FFPlayerPosition;
  FFPlayer.OnFileOpen := FFPlayerFileOpen;
  FFPlayer.AspectRatio := 0;//-1;
  FFPlayer.FrameHook:=True;
  PlayShow.Align:= alNone;

  //创建进度条控件
  ProBar:=TRealBar.Create(Self);
  ProBar.Parent:=Ptool;
  ProBar.Align:=altop;
  ProBar.Height:=15;
  ProBar.ProChangeEvent:=ProBarChangeEvent;

  TrackBar1.Height:=0;
//  ProBar.Parent:=Ptool;
//  ProBar.Height:=0;
//  ProBar.Width:=0;

  //创建声音进度条控件
  Volume := TVolumeCtrlBar.Create(Self);
  Volume.Parent := Ptool;
  Volume.Left := ImgWav.Left+23;
  Volume.Top := 24;
  Volume.Width := 92;
  Volume.Height := 17;
  Volume.Transparent := False;
  Volume.Max := 128;
  Volume.Position := 128;
  Volume.OnPlayPosChanged := VolumePlayPosChanged;
  Volume.Anchors := [akTop, akRight];

//  Self.Imglogo.WindowProc
  DragAcceptFiles(Self.PlayShow.Handle, True);
  // 保存原来的 WindowProc
  OLDWndProc := Self.PlayShow.WindowProc;
  // 设置新的 WindowProc
  Self.PlayShow.WindowProc:=Self.DragFileProc;
//  Self.Imglogo.WindowProc:=Self.DragFileProc;

  //变量初始化
  initPro;
  //热键
  Key1:=GlobalAddAtom('hotkey1');
  Key2:=GlobalAddAtom('hotkey2');
  KeyPlay:= GlobalAddAtom('KeyPlay');
  Application.OnDeactivate := AppActive;
  Application.OnActivate:=AppActive1;
  {$IFDEF Pdll}
  //注意以下不能这么写
//  FPlay.Constraints.MinHeight := 335;
//  FPlay.Constraints.MinWidth := 522;
  {$ELSE}
  FPlay.Constraints.MinHeight := 425;
  FPlay.Constraints.MinWidth := 700;
  {$ENDIF}
end;

procedure TFPlay.FormDestroy(Sender: TObject);
begin
{$IFDEF Pdll}
  FFPlayer.Stop(True);
  PlayShow.Invalidate;
{$ELSE}
  {$IFDEF DELPHI_7}Shell_NotifyIcon(NIM_DELETE, @NotifyIcon);{$ENDIF}
  {$IF Defined(DELPHI_2010) OR Defined(DELPHI_XE5)}Tray.Free;{$IFEND}
{$ENDIF}

//  FPlay.FFPlayer.Stop(True);
  FFPlayer.Free;
  ProBar.Free;
  //注销快捷键
  UnRegisterHotKey(handle,Key1);
  UnRegisterHotKey(handle,Key2);
  UnRegisterHotKey(handle,KeyPlay);
  DestMag;     //磁性类销毁
end;

procedure TFPlay.FormShow(Sender: TObject);
begin
  //注册自己为磁性窗口
  if not CreateMag then
  begin
    MagneticWnd.SnapWidth := 20;
    MagneticWnd.AddWindow(Self.Handle, 0, MagneticWndProc);
  end;
end;

procedure TFPlay.FormResize(Sender: TObject);
begin
  PlayShow.Height:=self.ClientHeight-50;//Self.Height - 76;
  PlayShow.Width:= Self.ClientWidth;
end;

procedure TFPlay.ImgBJMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
const SC_DRAGMOVE:Longint=$F012;
begin
  ReleaseCapture;
  SendMessage(Handle,WM_SYSCOMMAND,SC_DRAGMOVE,0);
end;

procedure TFPlay.NCutClick(Sender: TObject);
var
  BMP: TBitmap;
  Savejpg:TSavePictureDialog;
begin
  Savejpg := TSavePictureDialog.Create(Self);
  Savejpg.Options := [ofOverwritePrompt, ofHideReadOnly, ofExtensionDifferent, ofPathMustExist, ofEnableSizing];
  Savejpg.Filter := 'JPEG Image File |*.jpg;*.jpeg | Bitmaps (*.bmp)|*.bmp';
  Savejpg.DefaultExt := 'jpg';
  BMP := TBitmap.Create;
  try
    BMP.Assign(FFPlayer.CurrentFrame);
    if BMP.Width > 0 then
    begin
      if Savejpg.Execute then
      begin
        if SameText(ExtractFileExt(Savejpg.FileName), '.jpg') then
        begin
          with TJPEGImage.Create do
          try
            Assign(BMP);
            SaveToFile(Savejpg.FileName)
          finally
            Free;
          end;
        end else BMP.SaveToFile(Savejpg.FileName);
      end;
    end;
  finally
    BMP.Free;
  end;
  Savejpg.Free;
end;

procedure TFPlay.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  I:Integer;
begin
//  if I>128 then I:=128;
//  if I<0 then I:=0;
//  if I=0 then AwavMute:=true;

//  ShowMessage('2');
//  if WheelDelta>0 then i:=i+1 else i:=i-1;
//wheelDelta参数表示滚动一格的值，向上滚动为正数，向下滚动则为负数
//  ShowMessage(inttostr(i));
//  FFPlayer.AudioVolume :=I;
end;

procedure TFPlay.PtoolMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
const SC_DRAGMOVE:Longint=$F012;
begin
  if Button=mbLeft then
  begin
    if Self.WindowState= wsMaximized then Exit;
    ReleaseCapture;
    SendMessage(Handle,WM_SYSCOMMAND,SC_DRAGMOVE,0);
  end;
//  if Button=mbMiddle then FullPlay;
end;

procedure TFPlay.PlayShowDblClick(Sender: TObject);
var
  filename: string;
begin
  if not FFPlayer.AVLibLoaded then
  begin
    {$IFDEF PResdll}
    if not FFPlayer.LoadAVLib(CLibAVPath) then Exit;
    {$ELSE}
    if not FFPlayer.LoadAVLib(extractfilepath(ParamStr(0)) + CLibAVPath) then Exit;
    {$ENDIF}
  end;
  filename:= OpenDlg('D:\');
  if Length(filename)<1 then  Exit;
  if not FFPlayer.Open(filename, PlayShow.Handle) then
  begin
    ImgStopClick(Sender);
    Exit;
  end;

  AllTime:=Getvideolength(filename);    //时长
  OKPlayed:=True;
  ImgPlayPause.Picture.Graphic.LoadFromStream(TResourceStream.Create(HInstance, 'ImgPause', 'jpgtype'));
end;

procedure TFPlay.TrackBar1Change(Sender: TObject);
begin
  if not FTrackChanging and not IsMouseDown then
    FFPlayer.Seek(FDuration * TrackBar1.Position div TrackBar1.Max);
end;

procedure TFPlay.MdefautClick(Sender: TObject);
begin
  if Assigned(FCurMenu) then
  begin
    //移走就执行
    FCurMenu.Checked := False;
  end;
  TMenuItem(Sender).Checked:=True;
  FCurMenu := TMenuItem(Sender);

  case FCurMenu.Tag of
  0: FFPlayer.AspectRatio:= 0;
  1: FFPlayer.AspectRatio := -1;
  2: FFPlayer.AspectRatio := 4 / 3;
  3: FFPlayer.AspectRatio := 16 / 9;
  4: FFPlayer.AspectRatio := 1.85;
  5: FFPlayer.AspectRatio := 2.35;
  end;
end;

procedure TFPlay.LabTopClick(Sender: TObject);
begin
  Atop:=not Atop;
end;

procedure TFPlay.ImgFullClick(Sender: TObject);
begin
  FullPlay;
end;

procedure TFPlay.ImgSetClick(Sender: TObject);
begin
  Exit;
  if not Assigned(FConfig) then
    FConfig := TFConfig.Create(Self);

    FConfig.trbBrightness.Enabled := FNativeFilters;
    FConfig.trbContrast.Enabled := FNativeFilters;
    FConfig.trbSaturation.Enabled := FNativeFilters;
    FConfig.trbHue.Enabled := FNativeFilters;
    FConfig.btnBrightness.Enabled := FNativeFilters;
    FConfig.btnContrast.Enabled := FNativeFilters;
    FConfig.btnSaturation.Enabled := FNativeFilters;
    FConfig.btnHue.Enabled := FNativeFilters;
    FConfig.Show;
//    frmControlBox.Close;
end;

procedure TFPlay.URLUDP1Click(Sender: TObject);
var
  LScreenHandle: HWND;
  LPngFile: string;
  URL: string;
begin
  if not FFPlayer.AVLibLoaded then
  begin
    {$IFDEF PResdll}
    if not FFPlayer.LoadAVLib(CLibAVPath) then Exit;
    {$ELSE}
    if not FFPlayer.LoadAVLib(extractfilepath(ParamStr(0)) + CLibAVPath) then Exit;
    {$ENDIF}
  end;

  URL:='udp://@225.1.1.1:3000';
  FFPlayer.ReadTimeout := 1000 * 60;
  if not InputQuery('打开', 'URL(or Filename)', URL) or (Trim(URL) = '') then Exit;

  if not FFPlayer.Open(URL, PlayShow.Handle) then Exit;
  OKPlayed:=True;
//    mmoLog.Lines.Add(FFPlayer.LastErrMsg);
end;

procedure TFPlay.NExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFPlay.DragFileProc(var Message: TMessage);
var
  FileNum: Word;
  p: array[0..254] of char;
begin
  if Message.Msg = WM_DropFiles then
  begin
//    Self.RichEdit.Clear;
    FileNum := DragQueryFile(Message.WParam, $FFFFFFFF, nil, 0);
    // 取得拖放文件总数
    for FileNum := 0 to FileNum - 1 do
    begin
      DragQueryFile(Message.WParam, FileNum, p, 255);
      // 取得拖放文件名
//      ShowMessage(StrPas(p));
      if not FFPlayer.AVLibLoaded then
      begin
        {$IFDEF PResdll}
        if not FFPlayer.LoadAVLib(CLibAVPath) then Exit;
        {$ELSE}
        if not FFPlayer.LoadAVLib(extractfilepath(ParamStr(0)) + CLibAVPath) then Exit;
        {$ENDIF}
      end;
      if not FFPlayer.Open(StrPas(p), PlayShow.Handle) then
      begin
        ImgPlayPause.Picture.Graphic.LoadFromStream(TResourceStream.Create(HInstance, 'ImgPlay', 'jpgtype'));
        FFPlayer.Stop(True);
        PlayShow.Invalidate;
        OKPlayed:=False;
        Exit;
      end;
      AllTime:=Getvideolength(StrPas(p));
      OKPlayed:=True;
      ImgPlayPause.Picture.Graphic.LoadFromStream(TResourceStream.Create(HInstance, 'ImgPause', 'jpgtype'));
      Break;
      //Self.MemoDrag.Lines.add(StrPas(p));
      //对文件的处理
//      RichEdit.Lines.LoadFromFile(StrPas(p));
    end;
  end else  OLDWndProc(Message); // 其他消息,调用原来的处理程序
end;

procedure TFPlay.initPro;
begin
  ProBar.Position:=0;
  OKPlayed:=False;
  topbool:= False;
  FCurMenu:=Mdefaut;
  FNativeFilters:=True;
  Fvol:=128;
  //磁性类创建
  CreateMag;
end;

procedure TFPlay.FullPlay;
const
  LAlign: array[Boolean] of TAlign = (alNone, alClient);
  MaxState: array[Boolean] of TWindowState = (wsNormal,wsMaximized);
  BStyle: array[Boolean] OF TFormBorderStyle = (bsSingle,bsNone);
  FStyle: array[Boolean] of TFormStyle = (fsNormal,fsStayOnTop);
{$J+}
  L: Integer = -1;
  T: Integer = -1;
  W: Integer = -1;
  H: Integer = -1;
  WS: TWindowState = wsNormal;
  FBS: TFormBorderStyle = bsSingle;
  FS: TFormStyle = fsNormal;
{$J-}
var
  I: Integer;
  LToFullScreen: Boolean;
begin
//  LToFullScreen:= Self.BorderStyle <> bsNone;
  LToFullScreen:= PlayShow.Align <> alClient;
//  if not LToFullScreen then Exit;
  if LToFullScreen then
  begin
    L := PlayShow.Left;
    T := PlayShow.Top;
    W := PlayShow.Width;
    H := PlayShow.Height;
    WS := Self.WindowState;
    FBS := Self.BorderStyle;
    FS := Self.FormStyle;
  end;
  //隐藏除PlayShow外其他控件
  for I := 0 to ControlCount - 1 do
    if Controls[I].Name <> 'PlayShow' then
      TControl(Controls[I]).Visible := not LToFullScreen;

  //设置窗体风格和PlayShow
  if LToFullScreen then
  begin
    {$IFDEF DELPHI_7}
    SetStayOnTop(Self.Handle, True);
    SetBorderStyle(Self, bsNone);
    {$ENDIF}
    {$IF Defined(DELPHI_2010) OR Defined(DELPHI_XE5)}
    Self.FormStyle := fsStayOnTop;
    Self.BorderStyle := bsNone;
    {$IFEND}
    Self.WindowState:= wsMaximized;
  end else begin
    Self.WindowState:= WS;
    {$IFDEF DELPHI_7}
    SetStayOnTop(Self.Handle, False);
      {$IFDEF Pdll}SetBorderStyle(Self, bsNone);{$ELSE}  //D7编译dll时用
    SetBorderStyle(Self, bsSizeable);{$ENDIF}
    {$ENDIF}
    {$IF Defined(DELPHI_2010) OR Defined(DELPHI_XE5)}
    Self.FormStyle:= FS;
    self.BorderStyle:= FBS;//bsNone
    {$IFEND}
  end;

  PlayShow.Align:= LAlign[LToFullScreen];

  Sleep(10);
  FFPlayer.UpdateScreenPosition;

  // restore normal position and size   恢复
  if not LToFullScreen then
  begin
    PlayShow.SetBounds(L, T, W, H);
    PlayShow.Anchors := [akLeft, akTop, akRight, akBottom];
  end;

//  if LToFullScreen then Imglogo.OnMouseDown:=nil else
//  Imglogo.OnMouseDown:=PtoolMouseDown;
end;

procedure TFPlay.WMEnterSizeMove(var Msg: TMessage);
begin
  inherited;

  if Assigned(MagneticWndProc) then
    MagneticWndProc(Self.Handle, WM_ENTERSIZEMOVE, Msg, dummyHandled);
end;

procedure TFPlay.WMSizing(var Msg: TMessage);
var
  bHandled: Boolean;
begin
  if not Assigned(MagneticWndProc) then
    inherited
  else
    if MagneticWndProc(Self.Handle, WM_SIZING, Msg, bHandled) then
       if not bHandled then
          inherited;
end;

procedure TFPlay.WMMoving(var Msg: TMessage);
var
  bHandled: Boolean;
begin
  if not Assigned(MagneticWndProc) then
    inherited
  else
    if MagneticWndProc(Self.Handle, WM_MOVING, Msg, bHandled) then
       if not bHandled then
          inherited;
end;

procedure TFPlay.WMExitSizeMove(var Msg: TMessage);
begin
  inherited;

  if Assigned(MagneticWndProc) then
    MagneticWndProc(Self.Handle, WM_EXITSIZEMOVE, Msg, dummyHandled);
end;

procedure TFPlay.WMSysCommand(var Msg: TMessage);
begin
  inherited;

  if Assigned(MagneticWndProc) then
    MagneticWndProc(Self.Handle, WM_SYSCOMMAND, Msg, dummyHandled);
end;

procedure TFPlay.WMCommand(var Msg: TMessage);
begin
  inherited;

  if Assigned(MagneticWndProc) then
    MagneticWndProc(Self.Handle, WM_COMMAND, Msg, dummyHandled);
end;

{$IF Defined(DELPHI_2010) OR Defined(DELPHI_XE5)}
procedure TFPlay.ImglogoMouseActivate(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y, HitTest: Integer;
  var MouseActivate: TMouseActivate);
begin
  if Button=mbMiddle then  FullPlay;
end;
{$IFEND}
{$ENDIF}
{$IFNDEF BPL}
exports
loadRealPanel        {$IFDEF CDlE}name 'OxPD0000001'{$ENDIF},
loadFullPanel        {$IFDEF CDlE}name 'OxPD0000002'{$ENDIF},
unloadReal           {$IFDEF CDlE}name 'OxPD0000003'{$ENDIF},
FPlayCutPic          {$IFDEF CDlE}name 'OxPD0000004'{$ENDIF},
FPlayShowD7          {$IFDEF CDlE}name 'OxPD0000005'{$ENDIF},
FPlayShowModal       {$IFDEF CDlE}name 'OxPD0000006'{$ENDIF},
LoadPlayOneFile      {$IFDEF CDlE}name 'OxPD0000007'{$ENDIF},
SetWHLength          {$IFDEF CDlE}name 'OxPD0000008'{$ENDIF},
GetVideoPic          {$IFDEF CDlE}name 'OxPD0000009'{$ENDIF},
GetVLength           {$IFDEF CDlE}name 'OxPD0000010'{$ENDIF},
SeekPos              {$IFDEF CDlE}name 'OxPD0000011'{$ENDIF},
SetProcess           {$IFDEF CDlE}name 'OxPD0000012'{$ENDIF};
{$ENDIF}

end.


