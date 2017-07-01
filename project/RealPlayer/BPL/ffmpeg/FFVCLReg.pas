unit FFVCLReg;

interface

{$I CompilerDefines.inc}

{$I _LicenseDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.SysUtils, System.Classes;
{$ELSE}
  SysUtils, Classes;
{$ENDIF}

procedure Register;

implementation

uses
  FFBaseComponent,
  CircularBuffer,
  FFDXUtils,
  FrameEffects,

{$IF DEFINED(ENABLE_ENCODER) or DEFINED(ENABLE_PLAYER)}
  FFLog, FFDecode, MemoryAccess,
  FrameInput, PacketInput, WaveInput,
  GDICapture, ScreenCapture, VFWCapture, WaveCapture,
{$IFEND}

{$IFDEF ENABLE_ENCODER}
  FFEncode, FrameOutput, WaveOutput,
{$ENDIF}

{$IFDEF ENABLE_PLAYER}
  FFPlay,
{$ENDIF}

{$IFDEF ACTIVEX}
  FFmpegActiveX,
{$ENDIF}

{$IFDEF ENABLE_DECSS}
  DeCSSVCL,
{$ENDIF}

{$IFDEF FPC}
  LResources,
  LazIDEIntf, PropEdits, ComponentEditors,
{$ELSE}
  {$IFDEF VCL_6_OR_ABOVE}
    DesignIntf, DesignEditors,
  {$ELSE}
    DsgnIntf,
  {$ENDIF}
{$ENDIF}
  FFLoad;

{$IFNDEF FPC}
{$R FFVCL.dcr}
{$ENDIF}

type
  TFFAboutProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure Edit; override;
  end;

  TFFComponentEditor = class(TDefaultEditor)
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

{ TFFAboutProperty }

function TFFAboutProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly, paFullWidthName];
end;

function TFFAboutProperty.GetValue: string;
begin
  Result := '(About)';
end;

procedure TFFAboutProperty.Edit;
var
  I: Integer;
  P: TPersistent;
begin
  for I := 0 to PropCount - 1 do
  begin
    P := GetComponent(I);
    if P is TFFBaseComponent then
    begin
      (P as TFFBaseComponent).ShowAbout;
      Break;
    end;
  end;
end;

{ TFFComponentEditor }

procedure TFFComponentEditor.ExecuteVerb(Index: Integer);
begin
  if (Index = 0) and (Component is TFFBaseComponent) then
    (Component as TFFBaseComponent).ShowAbout;
end;

function TFFComponentEditor.GetVerb(Index: Integer): string;
begin
  if (Index = 0) and (Component is TFFBaseComponent) then
    Result := Format('About %s %s...',
                    [System.Copy(Component.ClassName, 2, MaxInt),
                    (Component as TFFBaseComponent).Version])
  else
    Result := 'N/A';
end;

function TFFComponentEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

procedure Register;
const
  SComponentsPage = 'FFmpeg';
{$IFDEF ACTIVEX}
  SComponentsPageX = 'FFmpegX';
{$ENDIF}
begin
  GShowReadOnlyProps := True;

{$IF DEFINED(ENABLE_ENCODER) or DEFINED(ENABLE_PLAYER)}
  RegisterComponents(SComponentsPage, [TFFLogger]);
  RegisterComponents(SComponentsPage, [TFFDecoder]);
{$IFEND}

{$IFDEF ENABLE_ENCODER}
  RegisterComponents(SComponentsPage, [TFFEncoder]);
{$ENDIF}

{$IFDEF ENABLE_PLAYER}
  RegisterComponents(SComponentsPage, [TFFPlayer]);
{$ENDIF}

{$IF DEFINED(ENABLE_ENCODER) or DEFINED(ENABLE_PLAYER)}
  RegisterComponents(SComponentsPage, [TMemoryAccessAdapter]);
  RegisterComponents(SComponentsPage, [TFrameInputAdapter]);
  RegisterComponents(SComponentsPage, [TPacketInputAdapter]);
  RegisterComponents(SComponentsPage, [TWaveInputAdapter]);
{$IFEND}

{$IFDEF ENABLE_ENCODER}
  RegisterComponents(SComponentsPage, [TFrameOutputAdapter]);
  RegisterComponents(SComponentsPage, [TWaveOutputAdapter]);
{$ENDIF}

{$IFDEF ACTIVEX}
  RegisterComponents(SComponentsPageX, [TFFLoggerX]);
  RegisterComponents(SComponentsPageX, [TFFDecoderX]);
  RegisterComponents(SComponentsPageX, [TFFEncoderX]);
  RegisterComponents(SComponentsPageX, [TFFPlayerX]);
  RegisterComponents(SComponentsPageX, [TMemoryAccessAdapterX]);
{$ENDIF}

  RegisterPropertyEditor(TypeInfo(string), TFFBaseComponent, 'About', TFFAboutProperty);
  RegisterComponentEditor(TFFBaseComponent, TFFComponentEditor);

{$IFDEF ENABLE_DECSS}
  RegisterComponents(SComponentsPage, [TDeCSSVCL]);
{$ENDIF}
end;

{$IFDEF FPC}
initialization
{$I FFVCL.lrs}

finalization
{$ENDIF}

end.
