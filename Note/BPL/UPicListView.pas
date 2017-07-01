//------------------------------------------------------------------------------
//
//图片显示
//
//
//------------------------------------------------------------------------------

{$INCLUDE '..\TypeDef.inc'}
unit UPicListView;
interface
uses
  Classes, ExtCtrls, Controls, Forms,
  jpeg;

type
  TPicSView= class(TCustomPanel)
  private
    Img:array of TImage;
    ScrBox: TScrollBox;      //背景

    jpg : TJPEGImage;
    pNum, pW, pH: Integer;   //图片个数 宽高
    Loaded: Boolean;         //是否加载过
  protected
    procedure Resize; override;
  public
    procedure SetImg(var sImg:TImage);
    procedure LoadImgList(XW, YH,nNum:Integer;LineNum:Integer=0; P2P:Integer=0;CreatBool:Boolean=True);
    procedure ClearImgList(nNum:Integer);
    property Align;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

VAR
  PicSView:TPicSView;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Standard', [TPicSView]);
end;

{ TPicSView }

procedure TPicSView.ClearImgList(nNum: Integer);
var
  I: Integer;
begin
  if not Loaded then Exit;  
  for I := 0 to nNum - 1 do
  begin
    Img[i].Free;
  end;
  SetLength(Img,0);
end;

constructor TPicSView.Create(AOwner: TComponent);
begin
  inherited;
  Self.BevelOuter:= bvNone;// bvRaised;
  Self.Caption:='';
  Self.Color:=0;
//  Self.ParentColor:=True;
//  Self.ParentBackground:=True;
  Self.Height:=200;
  Self.Width:=300;

  ScrBox:= TScrollBox.Create(Self);
  with ScrBox DO
  begin
    Parent := Self;
    Align := alClient;
    BevelInner := bvNone;
    BevelOuter := bvNone;
    HorzScrollBar.Visible := False;
//    AutoSize := True;
    AutoScroll := True;
  end;

  pNum:=0;
  PW:=0;
  PH:=0;
end;

destructor TPicSView.Destroy;
begin

  inherited;
end;

procedure TPicSView.LoadImgList(XW, YH,nNum:Integer;LineNum:Integer=0;
  P2P:Integer=0;CreatBool:Boolean=TRUE);
var
  I,p,q: Integer;
//  P2P:Integer;      //图像间距
//  XW, YH:Integer;   //图像尺寸
//  nNum:Integer;     //图片总个数
//  LineNum:Integer;  //一行个数
begin
//  P2P:=6;
//  XW:=80;
//  YH:=60;
//  nNum:=50;
  pNum:= nNum;
  pW:=XW;
  pH:=YH;

  if LineNum=0 then
  BEGIN
    LineNum:= (ScrBox.Width-20) div XW;
    P2P:= (ScrBox.Width -20 - LineNum*XW) div (LineNum+1);
  END;
  if CreatBool then
  begin
    ClearImgList(pNum);
    SetLength(Img,nNum);
    jpg := TJPEGImage.Create;
  end;
  P:=0;
  q:=-1;
  for I := 0 to nNum-1 do
  begin
    if CreatBool then
    begin
      Img[i] := TImage.Create(Self);
      Img[i].Parent := ScrBox;
      SetImg(Img[i]);
    end;
    with Img[i] do
    begin
      Width := XW;
      Height := YH;
      Stretch := True;
      Inc(p);
      if (I mod LineNum)=0 then   //一行几个
      begin
        Inc(q);       //行
        p:=0;         //重置一次
      end;
      top :=(YH+P2P)*q+P2P; //加一次行距
      Left := (XW+P2P)*p+P2P;
    end;
  end;
  Loaded:=True;
end;

procedure TPicSView.Resize;
begin
  inherited;
  if pNum>0 then
  PicSView.LoadImgList(pW,pH,pNum,0,0,False);
end;

procedure TPicSView.SetImg(var sImg: TImage);
begin
  jpg.LoadFromStream(TResourceStream.Create(HInstance, 'test', 'jpgtype'));
  sImg.Picture.Assign(jpg);
end;

end.
