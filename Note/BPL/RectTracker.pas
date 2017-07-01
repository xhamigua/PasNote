//------------------------------------------------------------------------------
//
//��Ƥ��ؼ�
//
//
//------------------------------------------------------------------------------

{$INCLUDE '..\TypeDef.inc'}
unit RectTracker;
interface
uses
  Windows,Messages,SysUtils, Classes, Graphics, Controls,ExtCtrls;

type
  TTrackerEvent=procedure(Sender:TObject;TrackRect:TRect) of object;
  TMousePos=(mpLeft,mpRight,mpTop,mpBottom,mpLeftTop,mpRightTop,mpLeftBottom,mpRightBottom,mpInBox,mpOutBox);
  TCustomRectTracker = class(TGraphicControl)
  private
    FBrush:TBrush;
    FPen:TPen;
    FRect:TRect;
    Fx,Fy: Integer;
    FInited: Boolean;
    FTrackerType: TMousePos;
    FOnChange:TTrackerEvent;
    tmpRect: TRect;
    FControl: TControl;
    FAss: Boolean;
    procedure OnSizeChanged(sender: TObject);
    procedure WMMouseMove(var Message: TWMMouseMove);message WM_MOUSEMOVE;
    procedure WMLButtonDown(var Message: TWMLButtonDown);message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var Message: TWMLButtonUp);message WM_LBUTTONUP;
    function GetRect: TRect;
    procedure SetRect(Value: TRect);
    function GetMousePos(X, Y: Integer): TMousePos;
    procedure DoChange;
    procedure SetControl(Value: TControl);
    { Private declarations }
  protected
    procedure Paint; override;
    property OnChange:TTrackerEvent read FOnChange write FOnChange;
    property CRect:TRect read GetRect write SetRect;
    property AcControl: TControl read FControl write SetControl;
    { Protected declarations }
  public
    procedure SetMoveXY(x,y:Integer);       //�ⲿ�ؼ�ͬ���ڲ��ؼ�
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { Public declarations }
  published
    { Published declarations }
  end;
  TRectTracker = class(TCustomRectTracker)
  published
    property CRect;
    property OnChange;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property Visible;
    property AcControl;
  end;
procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AHMGbpl', [TRectTracker]);
end;

constructor TCustomRectTracker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FInited:=False;
  Fx:=-1;
  Fy:=-1;
  Width := 65;
  Height := 65;
  Constraints.MinHeight:=10;
  Constraints.MinWidth:=10;
  FBrush:=TBrush.Create;
  FBrush.Style:=bsClear;
  FPen:=TPen.Create;
  FPen.Style:= psSolid;//ֱ�� //psDot;����
  //psSolid, psDash, psDot, psDashDot, psDashDotDot, psClear,
//    psInsideFrame, psUserStyle, psAlternate);
  FTrackerType:=mpOutBox;
  OnResize:=OnSizeChanged;
end;

destructor TCustomRectTracker.Destroy;
begin
  FPen.Free;
  FBrush.Free;
  inherited Destroy;
end;

procedure TCustomRectTracker.OnSizeChanged(sender: TObject);
begin
  FRect.Left:=2;
  FRect.Right:=Width-2;
  FRect.Top:=2;
  FRect.Bottom:=Height-2;
  if Assigned(FControl) then
  begin
    if Not FAss then
    begin
      FControl.Left:=Left+5;
      FControl.Top:=Top+5;
      FControl.Width:=Width-10;
      FControl.Height:=Height-10;
    end;
  end;
end;

procedure TCustomRectTracker.Paint;
var
  X,Y:Integer;
  w6,w1,h6,h1:Integer;
begin
  Canvas.Brush:=FBrush;
  Canvas.Pen:=FPen;

  if Not FInited then
    FRect:=Rect(2,2,Width-2,Height-2);
  X:=(width div 2)-3+(width mod 2);
  Y:=(height div 2)-3+(height mod 2);
  w6:= Width-5;
  w1:=Width;
  h6:=Height-5;
  h1:=Height;
  Canvas.Rectangle(2,2,Width-2,Height-2);
  Canvas.Brush.Style:=bsSolid;
  Canvas.Brush.Color:=clBlack;
  Canvas.Pen.Style:=psSolid;
  Canvas.Rectangle(0,0,5,5);
  Canvas.Rectangle(0,Y,5,Y+5);
  Canvas.Rectangle(0,h6,5,h1);
  Canvas.Rectangle(X,0,X+5,5);
  Canvas.Rectangle(X,h6,X+5,h1);
  Canvas.Rectangle(w6,0,w1,5);
  Canvas.Rectangle(w6,Y,w1,Y+5);
  Canvas.Rectangle(w6,h6,w1,h1);
end;

procedure TCustomRectTracker.WMMouseMove(var Message: TWMMouseMove);
var
  dx,dy:Integer;
begin
  dx:=Message.XPos-Fx;
  dy:=Message.YPos-Fy;
  case FTrackerType of
    mpLeft:   //��ߵ�
      begin
        if Not((Width<=10) and (dx>0)) then
          SetBounds(Left+dx,Top,Width-dx,Height);
      end;
    mpRight:  //�ұߵ�
      begin
        Width:=Width+dx;
        Fx:=Message.XPos;
      end;
    mpTop:    //������
      begin
        if Not((Height<=10) and (dy>0)) then
          SetBounds(Left,Top+dy,Width,Height-dy);
      end;
    mpBottom: //������
      begin
        Height:=Height+dy;
        Fy:=Message.YPos;
      end;
    mpLeftTop:   //����
      begin
        if Not((Width<=10) and (dx>0)) then
        begin
          if Not((Height<=10) and (dy>0)) then
            SetBounds(Left+dx,Top+dy,Width-dx,Height-dy)
          else
            SetBounds(Left+dx,Top,Width-dx,Height);
        end
        else begin
          if Not((Height<=10) and (dy>0)) then
            SetBounds(Left,Top+dy,Width,Height-dy);
        end;
      end;
    mpRightBottom:  //����
      begin
        SetBounds(Left,Top,Width+dx,Height+dy);
        Fx:=Message.XPos;
        Fy:=Message.YPos;
      end;
    mpLeftBottom:   //����
      begin
        if Not((Width<=10) and (dx>0)) then
        begin
          SetBounds(Left+dx,Top,Width-dx,Height+dy);
        end
        else begin
          SetBounds(Left,Top,Width,Height+dy)
        end;
        Fy:=message.YPos;
      end;
    mpRightTop:     //����
      begin
        if Not((Height<=10) and (dy>0)) then
        begin
          SetBounds(Left,Top+dy,Width+dx,Height-dy);
        end
        else begin
          SetBounds(Left,Top,Width+dx,Height)
        end;
        Fx:=message.XPos;
      end;
    mpInBox:      //�ƶ��ؼ�
      begin
        Left:=Left+dx;
        Top:=Top+dy;
      end;
  end;
  case GetMousePos(Message.XPos,Message.YPos) of
    mpLeftTop,mpRightBottom:Cursor:=crSizeNWSE;
    mpLeftBottom,mpRightTop:Cursor:=crSizeNESW;
    mpLeft,mpRight:Cursor:=crSizeWE;
    mpTop,mpBottom:Cursor:=crSizeNS;
    mpInBox:Cursor:=crSizeAll;
    mpOutBox:Cursor:=crDefault;
  end;
  Inherited;
end;

procedure TCustomRectTracker.WMLButtonDown(var Message: TWMLButtonDown);
begin
  if Message.Keys and MK_LBUTTON <> 0 then
  begin
    tmpRect:=Rect(Left,Top,Width,Height);
    Fx:=Message.XPos;
    Fy:=Message.YPos;
    FTrackerType:=GetMousePos(Fx,Fy);
  end;
  inherited;
end;

procedure TCustomRectTracker.WMLButtonUp(var Message: TWMLButtonUp);
begin
  Fx:=-1;
  Fy:=-1;
  FTrackerType:=mpOutBox;
  inherited;
  if (tmpRect.Left =Left) and
     (tmpRect.Top =Top) and
     (tmpRect.Right =Width) and
     (tmpRect.Bottom =Height) then exit;
  DoChange;
end;

function TCustomRectTracker.GetRect: TRect;
begin
  Result:=Rect(Left+2,Top+2,Left+Width-2,Top+Height-2);
end;

procedure TCustomRectTracker.SetRect(Value: TRect);
begin
  Left:=Value.Left-2;
  Top:= Value.Top-2;
  Width:= Value.Right-Value.Left+4;
  Height:=Value.Bottom-Value.Top+4;
  DoChange;
end;

function TCustomRectTracker.GetMousePos(X, Y: Integer): TMousePos;
var
  CX,CY:Integer;
  w6,w1,h6,h1:Integer;
  p:TPoint;
begin
  Result:=mpOutBox;
  CX:=(width div 2)-3+(width mod 2);
  CY:=(height div 2)-3+(height mod 2);
  w6:= Width-5;
  w1:=Width;
  h6:=Height-5;
  h1:=Height;
  p.X:=X;
  p.Y:=Y;
  if ptInRect(Rect(0,0,5,5),p) then//����
    Result:=mpLeftTop
  else if ptInRect(Rect(w6,h6,w1,h1),p) then//����
    Result:=mpRightBottom
  else if ptInRect(Rect(0,h6,5,h1),p) then//����
    Result:=mpLeftBottom
  else if ptInRect(Rect(w6,0,w1,5),p) then//����
    Result:=mpRightTop
  else if ptInRect(Rect(0,CY,5,CY+5),p) then//��
    Result:=mpLeft
  else if ptInRect(Rect(w6,CY,w1,CY+5),p) then//��
    Result:=mpRight
  else if ptInRect(Rect(CX,0,CX+5,5),p) then //��
    Result:=mpTop
  else if ptInRect(Rect(CX,h6,CX+5,h1),p) then//��
    Result:=mpBottom
  else if ptInRect(FRect,p) then//�ڲ�
    Result:=mpInBox;
end;

procedure TCustomRectTracker.DoChange;
begin
  if Assigned(FOnChange) then
  begin
    FOnChange(self,GetRect);
  end;
end;

procedure TCustomRectTracker.SetControl(Value: TControl);
begin

  if Value=self then
    FControl:=nil
  else
    FControl:=Value;
  if FControl=nil  then exit;
  FAss:=True;
  Left:=Value.Left-5;
  Top:=Value.Top-5;
  Width:=Value.Width+10;
  Height:=Value.Height+10;
  FAss:=False;
end;

procedure TCustomRectTracker.SetMoveXY(x, y: Integer);
var
  dx,dy:Integer;
begin
  dx:=X-Fx;
  dy:=Y-Fy;

  Left:=Left+dx;
  Top:=Top+dy;
end;

end.

