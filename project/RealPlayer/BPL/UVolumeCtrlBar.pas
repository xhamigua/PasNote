unit UVolumeCtrlBar;
{$IFNDEF VER150}
{$R 'VolRes.res' 'VolRes.rc'}
{$ENDIF}
interface
uses
  Windows, Messages, Classes, Graphics, Controls, SysUtils,
  jpeg,
  ExtCtrls;

Function DurationToStr(ADuration: Int64): string;

const
  WM_MSG_THUMBMOVED = WM_USER + 12001;
  WM_MSG_THUMBMOUSEUP = WM_USER + 12002;
type
  TMediaInfo = record
    FileName: string;
    Length: Int64;
    StartTime: Int64;
    EndTime: Int64;
    ValidLength: Int64;
  end;

  TArrMediaInfo = array of TMediaInfo;

  TLnMoveImage = Class(TImage)
  private
    OldPoint:TPoint;
    bMouseDown: Boolean;
  public
    FParentHandle: HWND;
    FPicture, FPictureNormal, FPictureHot: TPicture;
    procedure ChangeImg;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton;Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState;X, Y: Integer);override;
    Procedure CMMouseEnter(var msg: TMessage); message CM_MOUSEENTER;
    Procedure CMMouseLeave(var msg: TMessage); message CM_MOUSELEAVE;
  End;

  TVolumeCtrlBar = class(TCustomPanel)
  private
    FMin, FMax, FPos: Int64;
    FTransparent: Boolean;
    FTickSize: Single;
    FImgBG: TImage;
    FImgPos: TImage;
    FThumb: TLnMoveImage;
    FOnPlayPosChanged: TNotifyEvent;
    procedure SetParams(AMin, AMax, APos: Int64);
    procedure SetMin(const Value: Int64);
    procedure SetMax(const Value: Int64);
    procedure SetPos(const Value: Int64);
    procedure SetHint(const Value: String);
    procedure SetTransparent(const Value: Boolean);
    procedure SetPictureBg(Value: TPicture);
    procedure SetPicturePos(Value: TPicture);
    procedure SetPictureThumbNormal(Value: TPicture);
    procedure SetPictureThumbHot(Value: TPicture);
    function  GetPictureBg: TPicture;
    function  GetPicturePos: TPicture;
    function  GetPictureThumbNormal: TPicture;
    function  GetPictureThumbHot: TPicture;
    function  GetHint: String;
    procedure CountTickSize;
    procedure AdjustPictures;
  protected
    procedure OnThumbMoved(var msg: TMessage); message WM_MSG_THUMBMOVED;
    //procedure OnThumbMouseUp(var msg: TMessage); message WM_MSG_THUMBMOUSEUP;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property PictureBackGround: TPicture read GetPictureBg write SetPictureBg;
    property PicturePostion: TPicture read GetPicturePos write SetPicturePos;
    property PictureThumbNormal: TPicture read GetPictureThumbNormal write SetPictureThumbNormal;
    property PictureThumbHot: TPicture read GetPictureThumbHot write SetPictureThumbHot;
    property ToolTip: String read GetHint write SetHint;
    property Transparent: Boolean read FTransparent write SetTransparent;
    property Min: Int64 read FMin write SetMin;
    property Max: Int64 read FMax write SetMax;
    property Position: Int64 read FPos write SetPos;
    property OnPlayPosChanged: TNotifyEvent read FOnPlayPosChanged write FOnPlayPosChanged;
    property OnClick;
    property OnCanResize;
    property OnReSize;
    property Anchors;
  end;


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Standard', [TVolumeCtrlBar]);
end;

Function DurationToStr(ADuration: Int64): string;
begin
  Result := Format('%.2d:%.2d:%.2d.%.3d',
    [ADuration div 1000 div 60 div 60,
     ADuration div 1000 div 60 mod 60,
     ADuration div 1000 mod 60,
     ADuration mod 1000 * 1000 div 1000]);
end;


{ TLnMoveImage }

procedure TLnMoveImage.ChangeImg;
begin
  Self.Picture.Assign(FPicture);
end;

procedure TLnMoveImage.CMMouseEnter(var msg: TMessage);
begin
  if Assigned(FPictureHot.Graphic) then
  begin
    FPicture := FPictureHot;
    ChangeImg;
  end;
  inherited;
end;

procedure TLnMoveImage.CMMouseLeave(var msg: TMessage);
begin
  FPicture := FPictureNormal;
  ChangeImg;
  inherited;
end;

constructor TLnMoveImage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Self.ShowHint := True;
  FParentHandle := 0;
  bMouseDown := False;
  FPictureNormal := TPicture.Create;
  FPictureHot := TPicture.Create;
  FPicture := FPictureNormal;
end;

destructor TLnMoveImage.Destroy;
begin
  FPictureNormal.Free; FPictureNormal := nil;
  FPictureHot.Free; FPictureHot := nil;
  inherited Destroy;
end;

procedure TLnMoveImage.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if GetCursorPos(OldPoint) then bMouseDown := True;
end;

procedure TLnMoveImage.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  newPoint: TPoint;
begin
  inherited MouseMove(Shift, X, Y);
  if not bMouseDown then Exit;
  if not GetCursorPos(newPoint) then Exit;
  if newPoint.X <> oldPoint.X then
  begin
    if FParentHandle <> 0 then
      SendMessage(FParentHandle, WM_MSG_THUMBMOVED, newPoint.X - oldPoint.X, newPoint.Y - oldPoint.Y);
    oldPoint.X := newPoint.X;
    oldPoint.Y := newPoint.Y;
  end;
end;

procedure TLnMoveImage.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  bMouseDown := False;
  if FParentHandle <> 0 then
    SendMessage(FParentHandle, WM_MSG_THUMBMOUSEUP, 0, 0);
end;

{ TVolumeCtrlBar }

procedure TVolumeCtrlBar.AdjustPictures;  //调整Bevel大小及图片位置
begin
  Self.Width := FImgBg.Width;// + FThumb.Width; //此处限制哦
  Self.Height := FThumb.Height;
  FImgBg.Top := Trunc((FThumb.Height - FImgBg.Height ) / 2);
  FImgPos.Top := FImgBg.Top;
end;

procedure TVolumeCtrlBar.CountTickSize;
begin
  FTickSize := (FImgBg.Width-FThumb.Width)  / (FMax - FMin);
end;

constructor TVolumeCtrlBar.Create(AOwner: TComponent);
var
  jpg:TJPEGImage;
//  Pic1:TResourceStream;
begin
  inherited Create(AOwner);    //Thumb默认大小为16*10
  //初始化
  FMin := 0;
  FMax := 100;
  FPos := 0;
  FTickSize := 1.0; // (Width - TickLength) / 2
  FTransparent := False;
  //设置自身属性
  Self.Width := 75;
  Self.Height := 17;
  Self.BevelOuter := bvNone;
  //Self.ShowCaption := False; {Delphi 7及以前版本不支持该属性。}
  Self.FullRepaint := False;
  //创建加载进度图片
  FImgBg := TImage.Create(Self);
  FImgBg.Parent := Self;
//  FImgBG.Align :=alClient;  //拉伸
  FImgBg.AutoSize := True;
  FImgBg.Stretch := False;
  FImgBg.Transparent := FTransparent;
  FImgBg.Left := 0; FImgBg.Width := 80;
  FImgBg.Top := 0; FImgBg.Height := Self.Height;
  jpg := TJPEGImage.Create;
  jpg.LoadFromStream(TResourceStream.Create(HInstance, 'jpgbj', 'jpgtype'));
  FImgBG.Picture.Assign(jpg);
  //创建播放进度图片
  FImgPos := TImage.Create(Self);
  FImgPos.Parent := Self;
  jpg.LoadFromStream(TResourceStream.Create(HInstance, 'jpgload', 'jpgtype'));
  FImgPos.Picture.Assign(jpg);
//  FImgPos.Picture.Bitmap.Handle:=LoadBitmap(HInstance,'jpgload');
  FImgPos.AutoSize := True;
  FImgPos.Stretch := False;
  FImgPos.Transparent := FTransparent;
  FImgPos.Left := 0; FImgPos.Width := 80;
  FImgPos.Top := 0; FImgPos.Height := Self.Height;
  //创建拖动滑块
  FThumb := TLnMoveImage.Create(Self);
  FThumb.Parent := Self;
  FThumb.Stretch := False;
  FThumb.AutoSize := True;
  FThumb.Transparent := True;//FTransparent;
  FThumb.Left := 0;  FThumb.Top := 0; //5
  FThumb.Width := 12; FThumb.Height := Self.Height;
  jpg.LoadFromStream(TResourceStream.Create(HInstance, 'jpgpos', 'jpgtype'));
  FThumb.Picture.Assign(jpg);
  FThumb.FPictureNormal.Assign(jpg);
  FThumb.FPictureHot.Assign(jpg);
//  Self.PictureThumbNormal.Bitmap.Handle:= LoadBitmap(HInstance,'jpgpos');
//  Self.PictureThumbHot.Bitmap.Handle:= LoadBitmap(HInstance,'jpgpos');
  jpg.Free;
end;

destructor TVolumeCtrlBar.Destroy;
begin
  FThumb.Free; FThumb := nil;
  FImgBG.Free; FImgBg := nil;
  FImgPos.Free; FImgPos := nil;
  inherited Destroy;
end;

function TVolumeCtrlBar.GetHint: String;
begin
  Result := FThumb.Hint;
end;

function TVolumeCtrlBar.GetPictureBg: TPicture;
begin
  Result := FImgBg.Picture;
end;

function TVolumeCtrlBar.GetPicturePos: TPicture;
begin
  Result := FImgPos.Picture;
end;

function TVolumeCtrlBar.GetPictureThumbHot: TPicture;
begin
  Result := FThumb.FPictureHot;
end;

function TVolumeCtrlBar.GetPictureThumbNormal: TPicture;
begin
  Result := FThumb.FPictureNormal;
end;

procedure TVolumeCtrlBar.OnThumbMoved(var msg: TMessage);
var
  iNewLeft: Integer;
begin
  iNewLeft := FThumb.Left + msg.WParam;
  if iNewLeft < 0 then Exit;
  if iNewLeft > Round(FTickSize * FMax) then Exit;
  FThumb.Left := iNewLeft;
  FImgPos.Width := iNewLeft;
  FPos := Round(FImgPos.Width / FTickSize);
  if Assigned(FOnPlayPosChanged) then FOnPlayPosChanged(Self);
end;

procedure TVolumeCtrlBar.Resize;
begin
  inherited ReSize;
  if FThumb.FParentHandle = 0 then
    FThumb.FParentHandle := Self.Handle;
  FThumb.ChangeImg; //加载图片
  AdjustPictures;
  CountTickSize;
  FImgPos.AutoSize := False;
  FImgPos.Width := Trunc(FPos * FTickSize);
  FThumb.Left := FImgPos.Width;
  Self.Caption := ''; //Delphi2010 可设置 ShowCaption=False，而取消该语句。
end;

procedure TVolumeCtrlBar.SetHint(const Value: String);
begin
  FThumb.Hint := Value;
end;

procedure TVolumeCtrlBar.SetMax(const Value: Int64);
begin
  SetParams(FMin, Value, FPos);
end;

procedure TVolumeCtrlBar.SetMin(const Value: Int64);
begin
  SetParams(Value, FMax, FPos);
end;

procedure TVolumeCtrlBar.SetParams(AMin, AMax, APos: Int64);
begin
  if aMin < 0 then aMin := 0;
  if aMax <= aMin then aMax := aMin + 1;
  if aPos < aMin then aPos := aMin;
  if aPos > aMax then aPos := aMax;
  if FMin <> aMin then
  begin
    FMin := aMin;
    CountTickSize;
    FImgPos.Width := Trunc(FPos * FTickSize);
    FThumb.Left := FImgPos.Width;
  end;
  if FMax <> aMax then
  begin
    FMax := aMax;
    CountTickSize;
    FImgPos.Width := Trunc(FPos * FTickSize);
    FThumb.Left := FImgPos.Width;
  end;
  if FPos <> aPos then
  begin
    FPos := aPos;
    FImgPos.Width := Trunc(FPos * FTickSize);
    FThumb.Left := FImgPos.Width;
    if Assigned(FOnPlayPosChanged) then FOnPlayPosChanged(Self);
  end;
end;

procedure TVolumeCtrlBar.SetPictureBg(Value: TPicture);
begin
  FImgBg.Picture.Assign(Value);
  AdjustPictures;
end;

procedure TVolumeCtrlBar.SetPicturePos(Value: TPicture);
begin
  FImgPos.Picture.Assign(Value);
  AdjustPictures;
end;

procedure TVolumeCtrlBar.SetPictureThumbHot(Value: TPicture);
begin
  FThumb.FPictureHot.Assign(Value);
end;

procedure TVolumeCtrlBar.SetPictureThumbNormal(Value: TPicture);
begin
  FThumb.FPictureNormal.Assign(Value);
  FThumb.Picture.Assign(Value);
  AdjustPictures;
end;

procedure TVolumeCtrlBar.SetPos(const Value: Int64);
begin
  SetParams(FMin, FMax, Value);
end;

procedure TVolumeCtrlBar.SetTransparent(const Value: Boolean);
begin
  if FTransparent <> Value then
  begin
    FTransparent := Value;
    FImgBg.Transparent := Value;
    FImgPos.Transparent := Value;
    FThumb.Transparent := Value;
  end;
end;


end.
