unit FFAbout;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls;
{$ELSE}
  Windows, SysUtils, Classes, Graphics,
  Controls, Forms, Dialogs, ExtCtrls, StdCtrls;
{$ENDIF}

type
  TfrmAbout = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    btnOK: TButton;
    procedure Label4Click(Sender: TObject);
    procedure Label4MouseEnter(Sender: TObject);
    procedure Label4MouseLeave(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

procedure ShowAboutBox(const AName, AVersion: string; AResID: Integer = 0);
{$IFDEF ActiveX}
procedure DrawIcon(ACanvas: TCanvas; const AName: string; AResID: Integer);
const
  CControlSize = 48;
{$ENDIF}

//var
//  frmAbout: TfrmAbout;

implementation

{$R FFAbout.dfm}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.Win.Registry, Winapi.ShellAPI;
{$ELSE}
  Registry, ShellAPI;
{$ENDIF}

{$IFDEF ACTIVEX}
  {$I VersionX.inc}
{$ELSE}
  {$I Version.inc}
{$ENDIF}

{$IFDEF ActiveX}
procedure DrawIcon(ACanvas: TCanvas; const AName: string; AResID: Integer);
var
  ICO: TIcon;
begin
  with ACanvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := clWhite;
    FillRect(Rect(0, 0, CControlSize, CControlSize));
    Brush.Color := RGB($F1, $EF, $E2);
    FrameRect(Rect(0, 0, CControlSize, CControlSize));
    FrameRect(Rect(0, 0, CControlSize - 1, CControlSize - 1));
    Brush.Color := RGB($71, $6F, $64);
    FrameRect(Rect(1, 1, CControlSize, CControlSize));
  end;
  if AResID <> 0 then
  begin
    ICO := TIcon.Create;
    try
{$IF Defined(VER140) or Defined(VER150)}
      ICO.Handle := LoadIcon(HInstance, MakeIntResource(AResID));
{$ELSE}
      ICO.LoadFromResourceID(HInstance, AResID);
{$IFEND}
      ACanvas.Draw((CControlSize - ICO.Width) div 2, (CControlSize - ICO.Height) div 2, ICO);
    finally
      ICO.Free;
    end;
  end
  else
  begin
    // TODO: draw text
    ACanvas.TextOut(0, 0, AName);
  end;
end;
{$ENDIF}

procedure ShowAboutBox(const AName, AVersion: string; AResID: Integer);
begin
  with TfrmAbout.Create(nil) do
    try
      Caption := 'About ' + AName;
      if AVersion <> '' then
        Label1.Caption := AName{$IFDEF ACTIVEX} + ' ActiveX Control'{$ENDIF} + ' - Version ' + AVersion + ' '
      else
        Label1.Caption := AName{$IFDEF ACTIVEX} + ' ActiveX Control'{$ENDIF} + ' ';
      Label2.Caption := SComponents + ' ';
      if SysLocale.PriLangID = LANG_CHINESE then
      begin
        Label3.Caption := SCopyRightC + ' ';
        Label4.Caption := SWebSiteC + ' ';
      end
      else
      begin
        Label3.Caption := SCopyRightE + ' ';
        Label4.Caption := SWebSiteE + ' ';
      end;
{$IFDEF ACTIVEX}
      Image1.Picture.Graphic := nil;
      Image1.Left := Image1.Left - (CControlSize - Image1.Width) div 2 + 5;
      Label1.Left := Label1.Left + 8;
      Label2.Left := Label2.Left + 8;
      Label3.Left := Label3.Left + 8;
      Label4.Left := Label4.Left + 8;
      Image1.Width := CControlSize;
      Image1.Height := CControlSize;
      DrawIcon(Image1.Canvas, AName, AResID);
{$ENDIF}
      if Label1.Width + Label1.Left + 10 > ClientWidth then
        ClientWidth := Label1.Width + Label1.Left + 10;
      if Label2.Width + Label2.Left + 10 > ClientWidth then
        ClientWidth := Label2.Width + Label2.Left + 10;
      if Label3.Width + Label3.Left + 10 > ClientWidth then
        ClientWidth := Label3.Width + Label3.Left + 10;
      ShowModal;
    finally
      Free;
    end;
end;

function BrowseURL(const URL: string; const ANewInstance: Boolean): Boolean;
  function OpenURL: Boolean;
  begin
    ShellExecute({$IFDEF FPC}HWND(nil){$ELSE}Application.Handle{$ENDIF}, 'open', PChar(URL), nil, nil, SW_SHOW); // do not localize
    Result := True;
  end;
var
  LBrowser: string;
begin
  if not ANewInstance then
  begin
    Result := OpenURL;
    Exit;
  end;

  LBrowser := '';
  with TRegistry.Create do
  try
    RootKey := HKEY_CLASSES_ROOT;
    Access := KEY_QUERY_VALUE;
    if OpenKey('htmlfile\shell\open\command', False) then // do not localize
      try
        LBrowser := Trim(ReadString(''));
      except
      end;
    CloseKey;
  finally
    Free;
  end;

  if LBrowser = '' then
  begin
    Result := OpenURL;
    Exit;
  end;

  if Pos('"', LBrowser) = 1 then
  begin
    LBrowser := Copy(LBrowser, 2, Length(LBrowser));
    LBrowser := Copy(LBrowser, 1, Pos('"', LBrowser) - 1);
  end;
  ShellExecute({$IFDEF FPC}HWND(nil){$ELSE}Application.Handle{$ENDIF}, 'open', // do not localize
    PChar(LBrowser), PChar(URL), nil, SW_SHOW);

  Result := True;
end;

procedure TfrmAbout.FormCreate(Sender: TObject);
begin
  Label4.Font.Color := clBlue;
end;

procedure TfrmAbout.Label4Click(Sender: TObject);
  function FromAbout: string;
  var
    S: string;
  begin
    S := Caption;
{$IFDEF NEED_TRIAL}
    S := 'trial ' + S;
{$ENDIF}
{$IFDEF ACTIVEX}
    S := 'ocx ' + S;
{$ELSE}
    S := 'vcl ' + S;
{$ENDIF}
    S := StringReplace(S, ' ', '_', [rfReplaceAll]);
    Result := '/?from=' + S;
  end;
begin
  if SysLocale.PriLangID = LANG_CHINESE then
    BrowseURL(LowerCase(SWebSiteC + FromAbout), True)
  else
    BrowseURL(LowerCase(SWebSiteE + FromAbout), True);
end;

procedure TfrmAbout.Label4MouseEnter(Sender: TObject);
begin
  Label4.Font.Color := clRed;
end;

procedure TfrmAbout.Label4MouseLeave(Sender: TObject);
begin
  Label4.Font.Color := clBlue;
end;

end.
