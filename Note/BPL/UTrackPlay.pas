//------------------------------------------------------------------------------
//
//����Ϊ���ֲ������������ؼ�
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
    BoolOnePlay,isdown: Boolean;        //��갴��״̬
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
    procedure DoNextTrigger;              //��һ���¼�
    procedure DoPTimerTrigger;            //��ʱ���¼�
    function ReadMPPos:int64;
    procedure SetMPPos(value:Int64);
  published
    //�����һ���¼�
    property PNextTrigger: TNotifyEvent read FNextTrigger write FNextTrigger;
    //��� �������¼�
    property PTimerTrigger: TNotifyEvent read FPTimerTrigger write FPTimerTrigger;
  public
    procedure SlowPlay;                   //����
    procedure FastPlay;                   //���
    procedure StopPlay;                   //ֹͣ����
    procedure SStop;                      //����ֹͣ(����б�)
    property APos:Int64 read ReadMPPos write SetMPPos;   //��ǰ����λ�� 10������
    property APlayPause:Boolean  read FPlayPause write SetPlayPause;
    procedure OpenPlay(PathMp3:string);                       //�򿪲���
    function GetTime(PathMp3:string):string;                  //���ż���ȡʱ��(����ǰ)
    function OnGetTime():string;                              //����ʱȡʱ��
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation
{ TTrackBar }

Function TimeToStr3(tmr:int64):WideString;stdcall;
begin
  Result := Format('%.2d:%.2d:%.2d.%.2d',
  [tmr div 1000 div 60 div 60,     //�õ��ж��ٸ�Сʱ
   tmr div 1000 div 60 mod 60,     //�õ��ж��ٸ�����
   tmr div 1000 mod 60,             //�õ����ٸ���
   tmr mod 1000 * 1000 div 10000]);                          //���Լ���
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
  Plab.Font.Name:= '΢���ź�';
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
  //����MPP
  MPP := TMediaPlayer.Create(Self);
  MPP.Parent := Self;
  MPP.VisibleButtons := [btPlay];
  MPP.Visible := False;
  tmpp:= TMediaPlayer.Create(Self);
  tmpp.Parent := Self;
  tmpp.VisibleButtons := [btPlay];
  tmpp.Visible := False;
  //��ʱ��
  Timer1:=TTimer.Create(Self);
  Timer1.Enabled:=False;
  Timer1.Interval:=100;
  Timer1.OnTimer:=TimerPTimer;

  //������
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
  //�̽�����
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
//  ttmp.Close;         //����һ��Ҫ��
//  ttmp.Free;
//  Exit;

  tmpp.Close;
  tmpp.FileName:= PathMp3;
  tmpp.Open;
  Result:= TimeToStr3(tmpp.Length);
  tmpp.Stop;
  tmpp.Close;         //����һ��Ҫ��
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
    loadtime.Caption:=TimeToStr3(round(Imageload.Width * okey));       //��ʾʱ��
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
//    loadtime.Caption:=DurationToStr(MPP.Position);      //��ʾʱ��
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
      //SbtnPlay.Glyph.LoadFromResourceName(HInstance, 'bmpPause');  //��ʾ��ͣ��ť
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
      DoNextTrigger;   //��һ��
    end;
    okey:= MPP.Position / MPP.Length;
    Imageload.Width:= round(Self.Width * okey);        //ͬ��������
    loadtime.Caption:=TimeToStr3(MPP.Position);        //ͬ��ʱ��
    DoPTimerTrigger;   //��ʱ���¼�
  except
    Timer1.Enabled:=False;
    //('�����쳣');
  end;
end;

end.
