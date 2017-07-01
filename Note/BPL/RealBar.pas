//------------------------------------------------------------------------------
//
//TRealBar  类似real的进度条控件
//
//
//------------------------------------------------------------------------------

{$INCLUDE '..\TypeDef.inc'}
unit RealBar;
interface
uses
  Windows, Classes, Graphics, Controls, ExtCtrls, Math;

type
  TProChangeEvent = procedure(const AValue: Int64) of object;
  TRealBar = class;
  TMoveImage = class(TImage)
  private
    FPoint: TPoint;
    FParent: TRealBar;
    FMoving: Boolean;
  protected
    property Enabled;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  //类似real的进度条控件
  TRealBar = class(TGraphicControl)
  private
    { Private declarations }
    FBorderColor: TColor;
    FBackgroundColor: TColor;
    FFillColor: TColor;
    FBaseInnerHighColor: TColor;
    FBaseInnerLowColor: TColor;
    FInnerHighColor: TColor;
    FInnerLowColor: TColor;
    FMin, FMax, FStep: Int64;
    FPosition: Int64;
    FPosCtrl: TMoveImage;
    FProChangeEvent: TProChangeEvent;

    procedure SetBorderColor(Value: TColor);
    procedure SetBackgroundColor(Value: TColor);
    procedure SetFillColor(Value: TColor);
    procedure SetBaseInnerHighColor(Value: TColor);
    procedure SetBaseInnerLowCOlor(Value: TColor);
    procedure SetInnerHighColor(Value: TColor);
    procedure SetInnerLowCOlor(Value: TColor);

    procedure SetMin(Value: int64);
    procedure SetMax(Value: int64);
    procedure SetPosition(Value: int64);
    procedure SetStep(Value: int64);

    function GetPercent: Byte;
  protected
    { Protected declarations }
    procedure Paint; override;
    procedure Click; override;
//    procedure OnMouseMove; override;
    procedure ZPaint;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function PositionToValue(const APos: Integer): Integer;
  published
    { Published declarations }
    property ProChangeEvent: TProChangeEvent read FProChangeEvent write FProChangeEvent;
    property OnMouseMove;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $00636563;
    property BackgroundColor: TColor read FBackgroundColor write SetBackgroundColor default $00E7E7E7;
    property FillColor: TColor read FFillColor write SetFillColor default $00BD8A52;
    property BaseInnerHighColor: TColor read FBaseInnerHighColor write SetBaseInnerHighColor default $00BDBEBD;
    property BaseInnerLowColor: TColor read FBaseInnerLowColor write SetBaseInnerLowColor default clWhite;
    property InnerHighColor: TColor read FInnerHighColor write SetInnerHighColor default $00CEA684;
    property InnerLowCOlor: TColor read FInnerLowColor write SetInnerLowColor default $007B4910;
    property AMin: Int64 read FMin write SetMin default 0;
    property AMax: Int64 read FMax write SetMax default 100;
    property Position: Int64 read FPosition write SetPosition;
    property Step: Int64 read FStep write SetStep;
  end;


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AHMGbpl', [TRealBar]);
end;

{ TRealOneProgressBar }
procedure TRealBar.Click;
var
  oPnt: TPoint;
begin
  inherited;
  GetCursorPos(oPnt);
  oPnt := ScreenToClient(oPnt);
  if (oPnt.Y > 0)  and (oPnt.Y < Height - 0) then
  begin
    oPnt.X := Min(oPnt.X, Width - 0);
    oPnt.X := Max(oPnt.X, 0);
    FPosCtrl.Left := oPnt.X - FPosCtrl.Width div 2;
    FPosition := PositionToValue(oPnt.X);
    if Assigned(FProChangeEvent) then FProChangeEvent(FPosition);
//    DrawVideoPositonLine;  .
    Paint;
  end;
end;

constructor TRealBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  FBorderColor := $00636563;
  FBackgroundColor := $00E7E7E7;
  FFillColor := $00BD8A52;
  FBaseInnerHighColor := $00BDBEBD;
  FBaseInnerLowColor := clWhite;
  FInnerHighColor := $00CEA684;
  FInnerLowColor := $007B4910;
  FMin := 0;
  FMax := 100;
  FPosition := 50;
  FStep := 10;
  Width := 200;
  Height := 20;

  FPosCtrl := TMoveImage.Create(Self);
  FPosCtrl.Width := 25;   //24
  FPosCtrl.Height := 15;  //15
  FPosCtrl.Stretch := True;
//  FPosCtrl.Parent := Self;
  FPosCtrl.Top := -1;
  FPosCtrl.Left := 0 - FPosCtrl.Width div 2;
  FPosCtrl.Transparent := True;
  FPosCtrl.FParent := Self;
  //FPosCtrl.Enabled:=False;
  FPosCtrl.Picture.Bitmap.Handle:= LoadBitmap(HInstance,'posplay');
end;

destructor TRealBar.Destroy;
begin
  inherited Destroy;
end;

procedure TRealBar.SetBorderColor(Value: TColor);
begin
  if FBorderColor <> Value then
  begin
    FBorderCOlor := Value;
    ZPaint;
  end;
end;

procedure TRealBar.SetBackgroundColor(Value: TColor);
begin
  if FBackgroundColor <> Value then
  begin
    FBackgroundCOlor := Value;
    ZPaint;
  end;
end;

procedure TRealBar.SetFillColor(Value: TColor);
begin
  if FFillColor <> Value then
  begin
    FFillCOlor := Value;
    ZPaint;
  end;
end;

procedure TRealBar.SetBaseInnerHighColor(Value: TColor);
begin
  if FBaseInnerHighCOlor <> Value then
  begin
    FBaseInnerHighColor := Value;
    ZPaint;
  end;
end;

procedure TRealBar.SetBaseInnerLowCOlor(Value: TColor);
begin
  if FBaseInnerLowCOlor <> Value then
  begin
    FBaseInnerLowCOlor := Value;
    ZPaint;
  end;
end;

procedure TRealBar.SetInnerHighColor(Value: TColor);
begin
  if FInnerHighCOlor <> Value then
  begin
    FInnerHighColor := Value;
    ZPaint;
  end;
end;

procedure TRealBar.SetInnerLowCOlor(Value: TColor);
begin
  if FInnerLowColor <> Value then
  begin
    FInnerLowColor := Value;
    ZPaint;
  end;
end;

procedure TRealBar.SetMin(Value: int64);
begin
  if FMin <> Value then
  begin
    FMin := Value;
    if FPosition < Value then FPosition := Value;
    ZPaint;
  end;
end;

procedure TRealBar.SetMax(Value: int64);
begin
  if FMax <> Value then
  begin
    FMax := Value;
    if FPosition > Value then FPosition := Value;
    ZPaint;
  end;
end;

procedure TRealBar.SetPosition(Value: int64);
begin
  if Value > FMax then Value := FMax;
  if Value < FMin then Value := FMin;
  if FPosition <> Value then
  begin
    FPosition := Value;
    ZPaint;
  end;
end;

procedure TRealBar.SetStep(Value: int64);
begin
  if FStep <> Value then
  begin
    FStep := Value;
    ZPaint;
  end;
end;

procedure TRealBar.Paint;
var
  RealWidth: Integer;
  R: TRect;
  MBitmap: TBitmap;
begin
  MBitmap := TBitmap.Create;
  MBitmap.Width := Width;
  MBitmap.Height := Height;
  MBitmap.Canvas.Brush.Color := clBtnFace;
  MBitmap.Canvas.FillRect(Rect(0,0,Width,Height));
  MBitmap.Canvas.Pen.Color := FBorderColor;
  MBitmap.Canvas.Brush.Style := bsClear;
  //Draw Base Image
  with MBitmap.Canvas do
  begin
    RoundRect(0, 0, Width, Height, 2, 2);
    Pen.Width := 1;
    Pen.Color := FBaseInnerHighColor;
    MoveTo(1, 1);
    LineTo(1, Height - 1);
    MoveTo(1, 1);
    LineTo(Width - 1, 1);
    Pen.Color := FBaseInnerLowColor;
    MoveTo(Width - 2, 2);
    LineTo(Width - 2, Height - 2);
    LineTo(1, Height - 2);
    Brush.Color := FBackgroundColor;
    FillRect(Rect(2,2,Width-2, Height-2));
  end;
    //Draw Bar
  if FPosition > 0 then
  with MBitmap.Canvas do
  begin
    RealWidth := Trunc((Width - 3)*GetPercent/100)+1;
    R := Rect(2,2,RealWidth+1, Height-2);
    Brush.Color := FFillColor;
    FillRect(R);
    Pen.Color := FInnerHighColor;
    MoveTo(1, 1);
    LineTo(1, Height - 1);
    MoveTo(1, 1);
    LineTo(RealWidth +1, 1);
    Pen.Color := FInnerLowCOlor;
    MoveTo(2, Height - 2);
    LineTo(RealWidth + 1, Height -2);
  end;
  Canvas.Draw(0,0,MBitmap);
  MBitmap.Free;
end;

function TRealBar.PositionToValue(const APos: Integer): Integer;
begin
  Result := 0;
  if Width <= 0 then Exit;
  Result := FMin + Round(APos * (FMax - FMin) / Width);
end;

procedure TRealBar.ZPaint;
begin
  if csOpaque in ControlStyle then
    RePaint
  else
  begin
    ControlStyle := ControlStyle + [csOpaque];
    RePaint;
    ControlStyle := ControlStyle - [csOpaque];
  end;
end;

function TRealBar.GetPercent: Byte;
begin
  Result:=0;
  if (FMax - FMin) = 0 then
    Result := 0
  else
    Result := Trunc(((FPosition - FMin)/(FMax - FMin)) * 100);
end;


{ TMoveImage }

constructor TMoveImage.Create(AOwner: TComponent);
begin
  inherited;
  FMoving := False;
end;

procedure TMoveImage.MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
begin
  inherited;
  FMoving := True;
  GetCursorPos(FPoint);
  if Assigned(FParent.OnMouseDown) then
    FParent.OnMouseDown(FParent, Button, Shift, X, Y);
end;

procedure TMoveImage.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  oPnt: TPoint;
begin
  inherited;
  if not FMoving then Exit;
  GetCursorPos(oPnt);
  Left := Left + (oPnt.X - FPoint.X);
  Left := Max(Left, 0 - Width div 2);
  Left := Min(Left, FParent.Width  - Width div 2);
  GetCursorPos(FPoint);
  FParent.FPosition := FParent.PositionToValue(Left + Width div 2);
end;

procedure TMoveImage.MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
var
  oPnt: TPoint;
begin
  inherited;
  GetCursorPos(oPnt);
  Left := Left + (oPnt.X - FPoint.X);
  Left := Max(Left, 0 - Width div 2);
  Left := Min(Left, FParent.Width - Width div 2);
  GetCursorPos(FPoint);
  FMoving := False;
  FParent.FPosition := FParent.PositionToValue(Left + Width div 2);
//  if Assigned(FParent.FVideoChangeEvent) then
//  begin
//    FParent.FVideoChangeEvent(FParent.FPosition);
//    FParent.Invalidate;
//  end;
  if Assigned(FParent.OnMouseUp) then
    FParent.OnMouseUp(FParent, Button, Shift, X, Y);
end;

end.
