(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of previewer.
 * Created by CodeCoolie@CNSW 2008/12/16 -> $Date:: 2013-09-17 #$
 *)

unit Previewer;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
    Winapi.Messages,
  {$ENDIF}
  System.SysUtils,
  System.Classes,
  {$IF Defined(MSWINDOWS) And Defined(FFFMX) And Defined(VCL_XE4_OR_ABOVE)}
    Fmx.Platform.Win, // for WindowHandleToPlatform
  {$IFEND}
  {$IFDEF FFFMX}
    System.Types,
    System.UITypes,
    FMX.Objects,
    {$IFDEF VCL_XE5_OR_ABOVE}
      FMX.Graphics,
    {$ELSE}
      FMX.Types,
    {$ENDIF}
    FMX.Forms;
  {$ELSE}
    Vcl.Graphics,
    Vcl.Controls,
    Vcl.Forms;
  {$ENDIF}
{$ELSE}
  Windows,
{$IFNDEF FPC}
  Messages,
{$ENDIF}
  SysUtils,
  Classes,
  Graphics,
  Controls,
  Forms;
{$ENDIF}

type
{$IFDEF MSWINDOWS}
  TPreviewerForm = class(TForm)
  private
    procedure WMLButtonDown(var Message: TWMLButtonDown); message WM_LBUTTONDOWN;
  end;
{$ENDIF}

  TPreviewer = class
  private
    FForm: TForm;
{$IFDEF FFFMX}
    FImage: TImage;
{$ENDIF}
    FClosed: Boolean;
    FBitmap: TBitmap;
    FFrameNumber: Integer;
    FPTS: Int64;

    procedure DoFormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CreateForm;
    procedure FreeForm;
    procedure Paint;
  public
    constructor Create;
    destructor Destroy; override;

    function PaintFrame(ABitmap: TBitmap; const AFrameNumber: Integer; const APTS: Int64): Boolean;
  end;

implementation

uses
  FFUtils,
  MyUtils;

{ TPreviewerForm }

{$IFDEF MSWINDOWS}
procedure TPreviewerForm.WMLButtonDown(var Message: TWMLButtonDown);
var
  Pos: DWORD;
begin
  Pos := GetMessagePos;
{$IF Defined(FFFMX) And Defined(VCL_XE4_OR_ABOVE)}
  SendMessage(WindowHandleToPlatform(Self.Handle).Wnd, WM_NCLButtonDown, HTCaption, Pos);
{$ELSE}
  SendMessage(Self.Handle, WM_NCLButtonDown, HTCaption, Pos);
{$IFEND}
//  inherited;
end;
{$ENDIF}

{ TPreviewForm }

constructor TPreviewer.Create;
begin
  inherited Create;
  FClosed := False;
end;

procedure TPreviewer.CreateForm;
begin
{$IFDEF MSWINDOWS}
  FForm := TPreviewerForm.CreateNew(nil);
{$ENDIF}
{$IFDEF POSIX}
  FForm := TForm.CreateNew(nil);
{$ENDIF}
  with FForm do
  begin
{$IFDEF FFFMX}
    BorderStyle := TFmxFormBorderStyle.bsToolWindow; // bsDialog;
    BorderIcons := [TBorderIcon.biSystemMenu];
    Position := TFormPosition.poScreenCenter;
{$ELSE}
    FormStyle := fsStayOnTop;
    BorderStyle := bsToolWindow; // bsDialog;
    BorderIcons := [biSystemMenu];
    Position := poScreenCenter;
{$ENDIF}
    OnCloseQuery := DoFormCloseQuery;
    ClientWidth := FBitmap.Width;
    ClientHeight := FBitmap.Height;
  end;
{$IFDEF FFFMX}
  FImage := TImage.Create(FForm);
  FImage.Parent := FForm;
  FImage.SetBounds(0, 0, FBitmap.Width, FBitmap.Height);
{$ENDIF}
end;

destructor TPreviewer.Destroy;
begin
  MySynchronize(FreeForm);
  inherited Destroy;
end;

procedure TPreviewer.FreeForm;
begin
  if FForm <> nil then
    FreeAndNil(FForm);
end;

procedure TPreviewer.DoFormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  FClosed := True;
end;

procedure TPreviewer.Paint;
begin
  if not FClosed then
  begin
    if not Assigned(FForm) then
    begin
      CreateForm;
      FForm.Show;
    end;
    FForm.Caption := DurationToStr(FPTS);
{$IFDEF FFFMX}
    FImage.Bitmap.Assign(FBitmap);
  {$IFDEF MACOS}
//    FImage.Bitmap.Assign(FBitmap);
  {$ELSE}
{
    if FForm.Canvas.BeginScene then
      try
        FForm.Canvas.DrawBitmap(FBitmap, RectF(0, 0, FBitmap.Width, FBitmap.Height), FForm.ClientRect, 1, True);
      finally
        FForm.Canvas.EndScene;
      end;
}
  {$ENDIF}
{$ELSE}
    FForm.Canvas.Draw(0, 0, FBitmap);
{$ENDIF}
  end;
end;

function TPreviewer.PaintFrame(ABitmap: TBitmap; const AFrameNumber: Integer; const APTS: Int64): Boolean;
begin
  if not FClosed then
  begin
    FBitmap := ABitmap;
    FFrameNumber := AFrameNumber;
    FPTS := APTS;
    MySynchronize(Paint);
  end;
  Result := not FClosed;
end;

end.
