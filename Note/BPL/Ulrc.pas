//------------------------------------------------------------------------------
//
//歌词模块
//
//
//------------------------------------------------------------------------------

{$INCLUDE '..\TypeDef.inc'}

unit Ulrc;
interface
{$R 'LrcRES.res' 'LrcRES.rc'}
uses
  Windows, Graphics, ExtCtrls, Classes, Controls, Forms,
  SysUtils, ComCtrls, StdCtrls,
  {$IFDEF DELPHI_7}pngimage7
  {$ELSE}pngimage{$ENDIF};
type
  TlrcEdit=class(TCustomPanel)
  private
    box: TPanel;            //背景
    MidMouseLine: TImage;   //中线
    pbxbox: TPaintBox;      //显示区
    tmr: TTimer;            //同步计时器
    ToolBar1: TToolBar;
    ImageList1: TImageList;
    TBtnOk, TTBtnOpen, TBtnSave,
    TBtnPlay, TBtnPause, TBtnL, TBtnR,
    TBtnAdd, TBtnaddline, TBtnMinus : TToolButton;
    Tbar1,Tbar2: TToolButton;
    BMP:TBitmap;
    ListLrcEdit: TListBox;  //编辑歌词
    ListEdit: TEdit;        //歌词选中行编辑

    m_Drawing:Boolean;      //是否点下
    oldTop: Integer;        //鼠标点到 pbxbox顶端间距
    TmrList:array of Int64;  //时间表
    LrcText: TStrings;      //歌词列表
    currentRow: Integer;    //当前高亮行
    lineSize: Integer;      //字距
    tmrstate:Boolean;       //计时器状态(拖动时记住)
    FImgSectionPos: TPoint;                //分段图标的位置

    FmouseUp: TNotifyEvent;
    FTmr:Boolean;
    procedure MidMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MidMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure MidMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbxBoxPaint(Sender: TObject);
    procedure ImgMidDblClick(Sender: TObject);    //双击进入编辑器
    procedure TmrTimer(Sender: TObject);
    procedure TBtnOkClick(Sender: TObject);
    procedure TBtnAddClick(Sender: TObject);
    procedure TBtnaddlineClick(Sender: TObject);
    procedure ListLrcEditClick(Sender: TObject);
    procedure ListLrcEditDblClick(Sender: TObject);
    procedure ListEditExit(Sender: TObject);
    procedure ListEditKeyPress(Sender: TObject; var Key: Char);
    procedure DoMouseUpMpp;   //鼠标弹起定位播放器
  protected
    procedure SetTmr(tmp:Boolean);
    procedure LoadPRO(tmp: Boolean=true);   //锁定歌词区
  published
    property Align;
    property PMouseUpMpp: TNotifyEvent read FmouseUp write FmouseUp;
  public
    Ctmr,FMpp:Int64;       //外部播放器定位时间传入
    ShowLT: Boolean;
    Flrc:TStrings;

    procedure SetTmrState(tmp:Boolean=True);                  //计时器开关
    procedure LoadLrc(strlist:TStrings);                      //加载歌词和时间
    procedure POSlinelrc(lindex:Integer);                     //定位lindex的歌词
    procedure SetShowEdit(edt:Boolean=True);                  //设置显示编辑器
    procedure LoadEdit;                                       //加载编辑歌词部分(必须在create后)
    property ATmr:Boolean read FTmr write SetTmr;
    property AmouseSetMpp:int64 read FMpp;// write FMpp;      //设置播放器进度用
    property Alrc:TStrings read Flrc write LoadLrc;           //外部加载歌词
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;
  procedure Register;
var
  lrcEdit:TlrcEdit;
implementation

procedure Register;
begin
  RegisterComponents('AHMGbpl', [TlrcEdit]);
end;

Function StrToMM10(tmr:WideString):Int64;stdcall;
var
  hh, mm, ss, ms: Integer;
begin
  Result:=0;
  if Length(tmr)<1 then  Exit;
  try
    mm := StrToInt(Copy(tmr, 1, 2)) * 60000;
    ss := StrToInt(Copy(tmr, 4, 2)) * 1000;
    ms := StrToInt(Copy(tmr, 7, 2)) * 10;
    Result := (mm + ss + ms) div 10;
  except
    Result:=-1;
  end;
end;

//设置PNG图片
procedure SetPng(img:TImage;PngName:string);
var
  oStream: TResourceStream;
  {$IFDEF DELPHI_7} opng: TPngObject;{$ENDIF}
  {$IFnDEF DELPHI_7}opng: tpngimage;{$ENDIF}
begin
  try
    oStream := TResourceStream.Create(HInstance, PngName, RT_RCDATA);
    opng:=TPngObject.Create;// TPngImage.Create;
    opng.LoadFromStream(oStream);
    img.Picture.Bitmap.Assign(opng);
  finally
    oStream.Free;
    opng.Free;
  end;
end;

//取小数点2位(将第三位4舍五入)
function RoundEx(const Value: Real): Real;
var
  x: Real;
begin
  x := Value * 100 - Trunc(Value * 100);
  if x >= 0.5 then
    Result := (Trunc(Value) + 1)/100
  else Result := Trunc(Value) /100;
end;

constructor TlrcEdit.Create(AOwner: TComponent);
begin
  inherited;
  self.Height:=200;
  Self.Width:=200;
  Self.BevelOuter:=bvNone;
  currentRow:=-1;                 //默认没有高亮行
  Ctmr:=0;

  BMP:=TBitmap.Create;
//  BMP.LoadFromResourceName(hInstance,'toolbar');
  BMP.LoadFromResourceName(HInstance,'toolbarj');
  ImageList1 := TImageList.Create(Self);
  ImageList1.ShareImages := True;
//  ImageList1.ColorDepth:= 1;
//  ImageList1.DrawingStyle:=dsNormal;

  ImageList1.AddMasked(bmp,0);
  box := TPanel.Create(Self);
  box.Parent := Self;
  box.Align:=alClient;
  box.BevelOuter := bvNone;
  box.Color:=clBlack;

  tmr:=TTimer.Create(Self);
  tmr.Enabled := False;
  tmr.Interval := 100;            //测试400毫秒同步一次
  tmr.OnTimer := TmrTimer;
  FTmr:=False;

  pbxBox := TPaintBox.Create(box);
  pbxBox.Parent := box;
  pbxBox.Left :=0;  // 6;
  pbxBox.Top := 0;
  pbxBox.Width := 4000;
//  pbxBox.Top := box.Height div 2;
//  pbxBox.Width := 222;// box.Width-pbxBox.Left*2;
//  pbxBox.Height := 15;
  pbxBox.Font.Color := clRed;
  pbxBox.Font.Height := -11;
  pbxbox.Font.Size:=8;    //12
  lineSize:=15;           //字距一般不动它  8号字为15  12/20
  pbxBox.Font.Name := '微软雅黑';
  pbxBox.ParentColor := False;
  pbxBox.OnPaint := pbxBoxPaint;

  MidMouseLine := TImage.Create(box);
  with MidMouseLine do
  begin
    Parent := box;
    Align:=alClient;
    Center := True;
    Proportional := True;           //默认隐藏
    Transparent := True;
    OnDblClick := ImgMidDblClick;
    OnMouseDown := midMouseDown;
    OnMouseMove := midMouseMove;
    OnMouseUp := midMouseUp;
//    Enabled:=False;                 //默认锁定
  end;
  SetPng(MidMouseLine,'MidMouseLine');

  LrcText:=TStringList.Create;
  LrcText.Add('字幕仅解析单行时间');
  LrcText.Add('解析时间格式为:');
  LrcText.Add('[00:00:00.00]');
  LrcText.Add('鼠标拖动播放进度可变化');
  LrcText.Add('!');
  Flrc:= TStringList.Create;
end;

destructor TlrcEdit.Destroy;
begin
  LrcText.Free;
  Flrc.free;
  inherited;
end;

procedure TlrcEdit.DoMouseUpMpp;
begin
  if Assigned(FmouseUp) then FmouseUp(Self);
end;

procedure TlrcEdit.ImgMidDblClick(Sender: TObject);
begin
  SetShowEdit;
  //将副本数据填充到
  ListLrcEdit.Items:=Flrc;
end;

procedure TlrcEdit.LoadLrc(strlist: TStrings);
var
  I: Integer;
  tmp:string;
begin
  //清理工作
  SetLength(TmrList,0);
  SetLength(TmrList,strlist.Count);     //设置时间数组
  LrcText.Clear;

  SetShowEdit(False);                   //编辑状态调整
  //分离歌词和时间
  if Length(strlist.Text)<1 then        //歌词加载失败
  begin
    LoadPRO;
    Exit;
  end;

  for I := 0 to strlist.Count - 1 do
  begin
    if Length(strlist[i])<8 then
    begin
      TmrList[i]:=0;
      LrcText.Add(strlist[i]);
    end else begin
      tmp:= Copy(strlist[i],2,8);       //Copy(strlist[i],1,10);
      TmrList[i]:= StrToMM10(tmp);      //转换时间为10毫秒制
      if ShowLT then LrcText.Add('['+tmp+'] '+ Copy(strlist[i],11,length(strlist[i])-10))
      else LrcText.Add(Copy(strlist[i],11,length(strlist[i])-10));
    end;
  end;
  pbxBox.Top := box.Height div 2;
  pbxBox.Height:= lineSize* strlist.Count +3;
  Flrc.Clear;                           //清空
  Flrc.Text:=strlist.Text;              //留下副本
  LoadPRO(False);                       //歌词区解锁
//  pbxBox.Width := box.Width-pbxBox.Left * 2;
end;

procedure TlrcEdit.LoadPRO(tmp: Boolean);
begin
  MidMouseLine.Enabled:= not tmp;
end;

procedure TlrcEdit.MidMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  oldTop:=y-pbxBox.Top;              //求间距
  m_Drawing:=True;
  MidMouseLine.Proportional:=False;  //中线打开

  //记下tmr状态并无条件关闭
  tmrstate:= tmr.Enabled;
  tmr.Enabled:=False;
  GetCursorPos(FImgSectionPos);
end;

procedure TlrcEdit.MidMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  oPnt: TPoint;
  midpot:Int64;
begin
  if not m_Drawing then Exit;
  //-------------------------------------------------------------------------
//  GetCursorPos(oPnt);
//  midpot:=pbxBox.Height div 2;     //标记图片的中点
//  pbxBox.Top := Math.Max(pbxBox.Top  + (oPnt.y - FImgSectionPos.y),0);
//  pbxBox.Top := Math.Min(pbxBox.Top , box.Height);
//  if pbxBox.Top>=(box.Height div 2) then
//    pbxBox.Top := box.Height div 2;
//  GetCursorPos(FImgSectionPos);
  //-------------------------------------------------------------------------
  if pbxBox.Top>=(box.Height div 2) then
    if Y>(box.Height div 2) then Exit;
  if ((box.Height div 2)+abs(pbxBox.Top))>=pbxBox.Height then
    if Y<(box.Height div 2) then Exit;
  pbxBox.Top:= y-oldTop;

  //高亮定位
  if pbxBox.Top<0 then
  currentRow:= ((box.Height div 2)+abs(pbxBox.Top)) div lineSize
  else currentRow:= ((box.Height div 2)-pbxBox.Top) div lineSize;
end;

procedure TlrcEdit.MidMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  oPnt: TPoint;
begin
  m_Drawing:=False;
  MidMouseLine.Proportional:=True;
  oldTop:=0;
  //-------------------------------------------------------------------------
//  GetCursorPos(oPnt);
//  pbxBox.Top := Math.Max(pbxBox.Top  + (oPnt.y - FImgSectionPos.y),0);
//  pbxBox.Top := Math.Min(pbxBox.Top , box.Height);
  //-------------------------------------------------------------------------
  tmr.Enabled:=tmrstate;              //恢复
  //根据行数currentRow 定位播放位置
  if Length(TmrList)<1 then Exit;
  FMpp:=10*TmrList[currentRow+1];
  DoMouseUpMpp;                       //外部调用调整播放位置
end;

procedure TlrcEdit.ListEditExit(Sender: TObject);
begin
  ListLrcEdit.Items[ListLrcEdit.ItemIndex]:=ListEdit.Text;
end;

procedure TlrcEdit.ListEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    ListLrcEdit.Items[ListLrcEdit.ItemIndex]:=ListEdit.Text;
    ListEdit.Visible := False;
    Key := #0;
  end;
end;

procedure TlrcEdit.ListLrcEditClick(Sender: TObject);
begin
  if ListEdit.Visible then
  begin
    ListEdit.Visible := false;
  end;
end;

procedure TlrcEdit.ListLrcEditDblClick(Sender: TObject);
var
  ii : integer;
  lRect: TRect;
begin
  ii := ListLrcEdit.ItemIndex;
  if ii = -1 then exit;
  lRect := ListLrcEdit.ItemRect(ii) ;
  ListEdit.Top := lRect.Top;// + 23;
  ListEdit.Left := lRect.Left + 1;
  ListEdit.Width:=(lRect.Right-lRect.Left)+1;
  ListEdit.Height := (lRect.Bottom - lRect.Top);
  ListEdit.Text := ListLrcEdit.Items.Strings[ii];
  ListLrcEdit.ItemIndex:=ii;
  ListEdit.Visible := True;
  ListEdit.SelectAll;
  ListEdit.SetFocus;
end;

procedure TlrcEdit.LoadEdit;
begin
  //创建工具栏
  ToolBar1 := TToolBar.Create(self);
  ToolBar1.Parent := self;
  ToolBar1.Height := 22;
  {$IFNDEF DELPHI_7}
  ToolBar1.AutoSize := True;
  ToolBar1.DrawingStyle := dsGradient;
  ToolBar1.GradientEndColor := clBtnText;
  ToolBar1.GradientStartColor := clBtnText;
  {$ENDIF}
  ToolBar1.Images := ImageList1;
  ToolBar1.Transparent := True;
  ToolBar1.Visible := False;
  //注意是倒序
  TBtnMinus:=TToolButton.Create(ToolBar1);
  TBtnMinus.Parent := ToolBar1;
  TBtnaddline:=TToolButton.Create(ToolBar1);
  TBtnaddline.Parent := ToolBar1;
  TBtnAdd:=TToolButton.Create(ToolBar1);
  TBtnAdd.Parent := ToolBar1;
  Tbar1:=TToolButton.Create(ToolBar1);  //间隔
  Tbar1.Parent := ToolBar1;
  Tbar1.Style := tbsSeparator;
  TBtnR:=TToolButton.Create(ToolBar1);
  TBtnR.Parent := ToolBar1;
  TBtnL:=TToolButton.Create(ToolBar1);
  TBtnL.Parent := ToolBar1;
  TBtnPause:=TToolButton.Create(ToolBar1);
  TBtnPause.Parent := ToolBar1;
  TBtnPlay:=TToolButton.Create(ToolBar1);
  TBtnPlay.Parent := ToolBar1;
  Tbar2:=TToolButton.Create(ToolBar1);   //间隔
  Tbar2.Parent := ToolBar1;
  Tbar2.Style := tbsSeparator;
  TBtnSave:=TToolButton.Create(ToolBar1);
  TBtnSave.Parent := ToolBar1;
  TTBtnOpen:=TToolButton.Create(ToolBar1);
  TTBtnOpen.Parent := ToolBar1;
  TBtnOk:=TToolButton.Create(ToolBar1);
  TBtnOk.Parent := ToolBar1;
  //=========设置图标===========================================================
  TBtnOk.ImageIndex := 0;
  TTBtnOpen.ImageIndex := 1;
  TBtnSave.ImageIndex := 2;
  TBtnPlay.ImageIndex := 3;
  TBtnPause.ImageIndex := 4;
  TBtnL.ImageIndex := 5;
  TBtnR.ImageIndex := 6;
  TBtnAdd.ImageIndex := 7;
  TBtnaddline.ImageIndex := 8;
  TBtnMinus.ImageIndex := 9;
  //============================================================================
  TBtnOk.OnClick := TBtnOkClick;
  TBtnAdd.OnClick := TBtnAddClick;
  TBtnaddline.OnClick := TBtnaddlineClick;
  //创建歌词编辑区
  ListLrcEdit := TListBox.Create(Self);
  with ListLrcEdit do
  begin
    Parent := Self;
    Align := alClient;
    BevelInner := bvNone;
    BevelOuter := bvNone;
    BorderStyle := bsNone;
    Color := clNone;
    Font.Charset := DEFAULT_CHARSET;
    Font.Color := clAqua;
    Font.Height := -12;
    Font.Name := '微软雅黑';
    ItemHeight := 17;
    Visible := False;
    OnClick:=ListLrcEditClick;
    OnDblClick:=ListLrcEditDblClick;
  end;
  ListEdit := TEdit.Create(ListLrcEdit);
  with ListEdit do
  begin
    Parent := ListLrcEdit;
    Left := 3;
    Top := 85;
    Width := 97;
    Height := 51;
    BevelInner := bvNone;
    BevelOuter := bvNone;
    BorderStyle := bsNone;
    Color := clYellow;// cl3DDkShadow;
    Font.Charset := DEFAULT_CHARSET;
    Font.Color := clBlack;
    Font.Size:=9;
    Font.Name := '微软雅黑';
    Visible := False;
    OnExit := ListEditExit;
    OnKeyPress :=ListEditKeyPress;
  end;
end;

procedure TlrcEdit.pbxBoxPaint(Sender: TObject);
var
  I:Integer;
begin
//  红线
//  pbxbox.Canvas.Pen.Color:=clRed;
//  pbxBox.Canvas.MoveTo(0,0);
//  pbxBox.Canvas.LineTo(box.Width,0);
//  Exit;
  pbxBox.Canvas.Brush.Color:=clBlack;
  if LrcText.Count<1 then Exit;     //没有数据就over
  for I := 0 to LrcText.Count-1  do
  begin
    pbxBox.Canvas.Font.Color:=RGB(90,90,90);
    if I=currentRow then  //变色行
    pbxBox.Canvas.Font.Color:= clLime;//RGB(255,0,0);
    pbxBox.Canvas.TextOut(6,lineSize*I+1,LrcText[i]);
  end;
end;

procedure TlrcEdit.POSlinelrc(lindex: Integer);
begin
  //高亮定位
  if pbxBox.Top<0 then
    pbxBox.Top:= 0- (lindex*lineSize - (box.Height div 2))+3
  else pbxBox.Top:=(box.Height div 2)- lindex*lineSize +3;
  currentRow:=lindex-1;
end;

procedure TlrcEdit.SetShowEdit(edt: Boolean);
begin
  ToolBar1.Visible:=edt;
  ListLrcEdit.Visible:=edt;
end;

procedure TlrcEdit.SetTmr(tmp: Boolean);
begin
  if FTmr <> tmp then
  begin
    FTmr := tmp;
    if tmp then
    begin
      tmr.Enabled:=True;
      ATmr:=True;
    end else begin
      tmr.Enabled:=False;
      ATmr:=False;
    end;
  end;
end;

procedure TlrcEdit.SetTmrState(tmp: Boolean);
begin
  tmr.Enabled:=tmp;
end;

procedure TlrcEdit.TBtnAddClick(Sender: TObject);
var
//  Temp:Int64;
  M,S:Double;
  str:String;
begin
  if ListLrcEdit.ItemIndex=-1 then Exit;
//  Temp:=trunc(NowTime*100);
//  temp:= trunc(Ctmr);
  M:=Ctmr div 6000;
  if M>9 then str:='['+floattostr(M)+':'
  else str:='[0'+floattostr(M)+':';
  S:=Ctmr Mod 6000;
  S:=S/100.0;
  s:=strtofloat(FormatFloat('#0.00',S));
  if S>=10.0 then str:=str+floattostr(S)+']'
  else str:=str+'0'+floattostr(S)+']';
  ListLrcEdit.Items[ListLrcEdit.ItemIndex]:=str+ListLrcEdit.Items[ListLrcEdit.ItemIndex];
end;

procedure TlrcEdit.TBtnaddlineClick(Sender: TObject);
begin
  //增加一行
  if ListLrcEdit.ItemIndex=-1 then Exit;
    ListLrcEdit.Items.Insert(ListLrcEdit.ItemIndex+1,'');
end;

procedure TlrcEdit.TBtnOkClick(Sender: TObject);
begin
  LoadLrc(ListLrcEdit.Items);
end;

procedure TlrcEdit.TmrTimer(Sender: TObject);
var
  I: Integer;
begin
  if Length(TmrList)<1 then Exit;  //没有就不用定位了
  for I := 0 to Length(TmrList) - 1  do
  begin
    if Ctmr <= TmrList[I] then
    begin
      POSlinelrc(I);       //定位
      Exit;
    end;
  end;
end;

end.
