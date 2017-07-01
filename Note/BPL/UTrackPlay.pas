//------------------------------------------------------------------------------
//
//以下为音乐播放器进度条控件
//
//
//------------------------------------------------------------------------------

{$INCLUDE '..\TypeDef.inc'}
unit UTrackPlay;
{$R 'TrackRES.res' 'TrackRES.rc'}
interface
uses
  Windows, Classes, ExtCtrls, StdCtrls, Controls,
  SysUtils, Graphics, MPlayer;

type
  TTrackPlay=class(TCustomPanel)
  private
    tmpp, MPP: TMediaPlayer;
    Timer1: TTimer;
    PanPro: TPanel;
    Imageload: TImage;
    loadtime: TLabel;
    Alltime: TLabel;
    ImgSet: TImage;
    BoolOnePlay,isdown: Boolean;        //鼠标按下状态
    FPlayPause: Boolean;

    FNextTrigger: TNotifyEvent;
    FPTimerTrigger: TNotifyEvent;

    procedure ImgSetMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImgSetMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ImgSetMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SetPlayPause(const Value: Boolean);
    procedure TimerPTimer(Sender: TObject);
    procedure DoNextTrigger;              //下一曲事件
    procedure DoPTimerTrigger;            //计时器事件
    function ReadMPPos:int64;
    procedure SetMPPos(value:Int64);
  published
    //输出下一曲事件
    property PNextTrigger: TNotifyEvent read FNextTrigger write FNextTrigger;
    //输出 进度条事件
    property PTimerTrigger: TNotifyEvent read FPTimerTrigger write FPTimerTrigger;
  public
    procedure SlowPlay;                   //快退
    procedure FastPlay;                   //快进
    procedure StopPlay;                   //停止播放
    procedure SStop;                      //彻底停止(清空列表)
    property APos:Int64 read ReadMPPos write SetMPPos;   //当前播放位置 10倍毫秒
    property APlayPause:Boolean  read FPlayPause write SetPlayPause;
    procedure OpenPlay(PathMp3:string);                       //打开播放
    function GetTime(PathMp3:string):string;                  //播放加载取时长(播放前)
    function OnGetTime():string;                              //播放时取时长
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation
{ TTrackBar }

Function TimeToStr3(tmr:int64):WideString;stdcall;
begin
  Result := Format('%.2d:%.2d:%.2d.%.2d',
  [tmr div 1000 div 60 div 60,     //得到有多少个小时
   tmr div 1000 div 60 mod 60,     //得到有多少个分钟
   tmr div 1000 mod 60,             //得到多少个秒
   tmr mod 1000 * 1000 div 10000]);                          //初略计算
end;

procedure CreateLab(var Plab:TLabel;Aparent:TWinControl;AAlign:TAlign);
begin
  Plab:=TLabel.Create(Aparent);
  Plab.Parent := Aparent;
  Plab.Align:=AAlign;
  Plab.Caption := '00:00:00.00';
  Plab.ParentFont:=False;
  Plab.Transparent := True;
  Plab.Font.Color:= clBlack;
  Plab.Font.Size:= 11;
  Plab.Font.Name:= '微软雅黑';
  Plab.Font.Style:= [fsBold];
  Plab.ParentFont:=False;
  Plab.Transparent := True;
end;

{ TTrack }

constructor TTrackPlay.Create(AOwner: TComponent);
begin
  inherited;
  Self.BevelOuter:= bvNone;// bvRaised;
  Self.Caption:='';
  Self.ParentColor:=True;
  Self.ParentBackground:=True;
  Self.Height:=20;
  Self.Width:=30;
  //创建MPP
  MPP := TMediaPlayer.Create(Self);
  MPP.Parent := Self;
  MPP.VisibleButtons := [btPlay];
  MPP.Visible := False;
  tmpp:= TMediaPlayer.Create(Self);
  tmpp.Parent := Self;
  tmpp.VisibleButtons := [btPlay];
  tmpp.Visible := False;
  //计时器
  Timer1:=TTimer.Create(Self);
  Timer1.Enabled:=False;
  Timer1.Interval:=100;
  Timer1.OnTimer:=TimerPTimer;

  //进度条
  PanPro:=TPanel.Create(Self);
  PanPro.Parent:=Self;
  PanPro.Caption:='';
  PanPro.Align:=alBottom;
  PanPro.BevelOuter:=bvNone;
  PanPro.Height:=20;
  PanPro.ParentBackground:=True;
  PanPro.ParentColor:=True;
  PanPro.ParentBackground:=False;
  PanPro.ParentColor:=False;
  PanPro.Color:=rgb(125,125,125);
  //绿进度条
  Imageload:=TImage.Create(PanPro);
  Imageload.Parent := PanPro;
  Imageload.Left := 0;
  Imageload.Top := 0;
  Imageload.Width := 0;
  Imageload.Height := PanPro.Height+4;
  Imageload.Stretch := True;
  //Imageload.Picture.Bitmap.Canvas.Brush.Color:=clLime;
  Imageload.Picture.Bitmap.Handle:=LoadBitmap(HInstance,'bmpload');  //bmpload BITMAP res\9.bmp

  CreateLab(loadtime,PanPro,alLeft);
  CreateLab(Alltime,PanPro,alRight);

  ImgSet:=TImage.Create(PanPro);
  ImgSet.Parent := PanPro;
  ImgSet.Left := 0;
  ImgSet.Top := -2;
  ImgSet.Width := 9000;
  ImgSet.Height := PanPro.Height+4;
  ImgSet.Stretch := True;

  ImgSet.OnMouseDown:=ImgSetMouseDown;
  ImgSet.OnMouseMove:=ImgSetMouseMove;
  ImgSet.OnMouseUp:=ImgSetMouseUp;
end;

destructor TTrackPlay.Destroy;
begin

  inherited;
end;

procedure TTrackPlay.DoNextTrigger;
begin
  if Assigned(FNextTrigger) then FNextTrigger(Self);
end;

procedure TTrackPlay.DoPTimerTrigger;
begin
  if Assigned(FPTimerTrigger) then FPTimerTrigger(Self);
end;

function TTrackPlay.GetTime(PathMp3: string): string;
//var
//  ttmp:TMediaPlayer;
begin
//  ttmp:= TMediaPlayer.Create(Self);
//  ttmp.Parent:=Self;
//  ttmp.Visible := False;        //  ttmp.VisibleButtons := [btPlay];
//  ttmp.Close;
//  ttmp.FileName:= PathMp3;
//  ttmp.Open;
//  Result:= TimeToStr3(ttmp.Length);
//  ttmp.Close;         //用完一定要关
//  ttmp.Free;
//  Exit;

  tmpp.Close;
  tmpp.FileName:= PathMp3;
  tmpp.Open;
  Result:= TimeToStr3(tmpp.Length);
  tmpp.Stop;
  tmpp.Close;         //用完一定要关
end;

procedure TTrackPlay.ImgSetMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  okey:Double;
begin
  isdown:=True;
  APlayPause:=False;
  Imageload.Width:=X;
  okey:= X / Self.Width;
  if MPP.DeviceID=0 then Exit;
  MPP.Position:= round(MPP.Length * okey);
  loadtime.Caption:=TimeToStr3(MPP.Position);
end;

procedure TTrackPlay.ImgSetMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  okey:Double;
begin
  if isdown then
  begin
    if x<0 then Imageload.Width:=0
    else if x>PanPro.Width then Imageload.Width:=PanPro.Width
    else Imageload.Width:=X;
    if MPP.DeviceID=0 then Exit;
    okey:= MPP.Length / Self.Width;
    loadtime.Caption:=TimeToStr3(round(Imageload.Width * okey));       //显示时间
    //application.processmessages;
  end;
end;

procedure TTrackPlay.ImgSetMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  okey:Double;
begin
  isdown:=False;
  begin
    if MPP.DeviceID=0 then Exit;
    okey:= MPP.Length / Self.Width;
    MPP.Position :=round(Imageload.Width * okey);
    APlayPause:=true;
//    loadtime.Caption:=DurationToStr(MPP.Position);      //显示时间
    //DoProgressLoad;
  end;
end;

function TTrackPlay.OnGetTime: string;
begin
//  Result:= TimeToStr3(MPP.Length);
  Result:= Alltime.Caption;
end;

procedure TTrackPlay.OpenPlay(PathMp3: string);
begin
  APlayPause:=False;
  MPP.Close;
  MPP.FileName:= PathMp3;
  MPP.Open;
  MPP.Position:=0;
  Imageload.Width := 0;
  Alltime.Caption:= TimeToStr3(MPP.Length);
  APlayPause:=true;
end;

function TTrackPlay.ReadMPPos: int64;
begin
  Result:=MPP.Position div 10;
end;

procedure TTrackPlay.SetMPPos(value: Int64);
begin
  MPP.Position:=value;
end;

procedure TTrackPlay.SetPlayPause(const Value: Boolean);
begin
  if FPlayPause <> Value then
  begin
    if MPP.DeviceID=0 then Exit;    
    FPlayPause := Value;
    if FPlayPause then
    begin
      //SbtnPlay.Glyph.LoadFromResourceName(HInstance, 'bmpPause');  //显示暂停按钮
      MPP.Play;
      Timer1.Enabled:=True;
      APlayPause:=True;
    end else begin
      //SbtnPlay.Glyph.LoadFromResourceName(HInstance, 'bmpPlay');
      MPP.Pause;
      Timer1.Enabled:=False;
      APlayPause:=False;
    end;
  end;
end;

procedure TTrackPlay.FastPlay;
begin
  if MPP.DeviceID=0 then Exit;
  APlayPause:=not APlayPause;
  MPP.Position:=MPP.Position + 3000;
  APlayPause:=not APlayPause;
end;

procedure TTrackPlay.SlowPlay;
begin
  if MPP.DeviceID=0 then Exit;
  APlayPause:=not APlayPause;
  MPP.Position:=MPP.Position - 3000;
  APlayPause:=not APlayPause;
end;

procedure TTrackPlay.SStop;
begin
  if MPP.DeviceID=0 then Exit;
  APlayPause:=False;
  MPP.Position:=0;
  Imageload.Width:=0;
  MPP.Stop;
  MPP.Close;
end;

procedure TTrackPlay.StopPlay;
begin
  if MPP.DeviceID=0 then Exit;
  APlayPause:=False;
  MPP.Stop;
  MPP.Position:=0;
  Imageload.Width:=0;
end;

procedure TTrackPlay.TimerPTimer(Sender: TObject);
var
  okey:Double;
begin
//  if not APlayPause then Exit;
  try
    if MPP.Position>=MPP.Length then
    begin
      APlayPause:=False;
      MPP.Stop;
      DoNextTrigger;   //下一曲
    end;
    okey:= MPP.Position / MPP.Length;
    Imageload.Width:= round(Self.Width * okey);        //同步进度条
    loadtime.Caption:=TimeToStr3(MPP.Position);        //同步时间
    DoPTimerTrigger;   //计时器事件
  except
    Timer1.Enabled:=False;
    //('程序异常');
  end;
end;

end.
