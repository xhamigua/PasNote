(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is TFFBaseComponent unit.
 * Created by CodeCoolie@CNSW 2010/02/09 -> $Date:: 2013-11-18 #$
 *)

unit FFBaseComponent;

interface

{$I CompilerDefines.inc}

{$I _LicenseDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  System.SysUtils,
  System.Classes,
{$ELSE}
  Windows, SysUtils, Classes,
{$ENDIF}
{$IFDEF USES_LICKEY}
  LicenseKey,
{$ENDIF}
  libavformat;

const
  AV_NOPTS_VALUE: Int64    = Int64($8000000000000000);
  AV_TIME_BASE_I           = 1000000;
  AV_TIME_BASE: Int64      = AV_TIME_BASE_I;

type
  TSeekFlag = (
    sfBackward, // seek backward
    sfByte,     // seeking based on position in bytes
    sfAny,      // seek to any frame, even non key-frames
    sfFrame);   // seeking based on frame number
  TSeekFlags = set of TSeekFlag;

  PAVFormatContext = libavformat.PAVFormatContext;
  TBeforeFindStreamInfoEvent = procedure(Sender: TObject; AFormatContext: PAVFormatContext) of object;

  TFFBaseComponent = class(TComponent)
  private
    FAbout: string;
{$IF Defined(NEED_IDE) Or Defined(NEED_ABOUT)}
    FShowAbout: Integer;
{$IFEND}
  protected
{$IFDEF ACTIVEX}
    FName: string;
    FResID: Integer;
{$ENDIF}
    FVersion: string;
    FReadTimeout: Integer;
    FWriteTimeout: Integer;
{$IFDEF NEED_KEY}
    FKey: Boolean;
    FLicKey: AnsiString;
    FLic: PLicKey;
{$ENDIF}
{$IF Defined(NEED_IDE) Or Defined(NEED_ABOUT)}
    procedure CheckShowAbout;
{$IFEND}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ShowAbout;
{$IFDEF ACTIVEX}
    procedure SetInfo(AName, AVer: string; AResID: Integer);
{$ENDIF}
    property ReadTimeout: Integer read FReadTimeout write FReadTimeout;
    property WriteTimeout: Integer read FWriteTimeout write FWriteTimeout;
  published
    property About: string read FAbout write FAbout;
    property Version: string read FVersion;
  end;

function MakeSeekFlags(ASeekFlags: TSeekFlags): Integer;
function IntToSeekFlags(ASeekFlags: Integer): TSeekFlags;

implementation

uses
  FFAbout,
  MyUtils;

{$IFDEF ACTIVEX}
  {$I VersionX.inc}
{$ELSE}
  {$I Version.inc}
{$ENDIF}

(*
var
  GDebuggerPresent: Integer = -1;

function DebuggerPresent: Integer;
{$IFDEF MSWINDOWS}
type
  TIsDebuggerPresentProc = function: Integer; stdcall;
var
  HKernel32: THandle;
  IsDebuggerPresent: TIsDebuggerPresentProc;
begin
  if Win32Platform = VER_PLATFORM_WIN32_NT then
    try
      HKernel32 := GetModuleHandle(kernel32);
      if HKernel32 = 0 then
        HKernel32 := LoadLibrary(kernel32);
      if HKernel32 <> 0 then
      begin
        @IsDebuggerPresent := GetProcAddress(HKernel32, 'IsDebuggerPresent');
        if Assigned(IsDebuggerPresent) then
        begin
          Result := Abs(IsDebuggerPresent);
          Exit;
        end;
      end;
    except
    end;
  Result := 0;
end;
{$ENDIF}
{$IFDEF POSIX}
begin
  Result := 0;
end;
{$ENDIF}
*)

function MakeSeekFlags(ASeekFlags: TSeekFlags): Integer;
begin
{
  // libavformat.pas
  AVSEEK_FLAG_BACKWARD = 1; ///< seek backward
  AVSEEK_FLAG_BYTE     = 2; ///< seeking based on position in bytes
  AVSEEK_FLAG_ANY      = 4; ///< seek to any frame, even non key-frames
  AVSEEK_FLAG_FRAME    = 8; ///< seeking based on frame number
}
  Result := 0;
  if sfBackward in ASeekFlags then
    Result := Result or 1{AVSEEK_FLAG_BACKWARD};
  if sfByte in ASeekFlags then
    Result := Result or 2{AVSEEK_FLAG_BYTE};
  if sfAny in ASeekFlags then
    Result := Result or 4{AVSEEK_FLAG_ANY};
  if sfFrame in ASeekFlags then
    Result := Result or 8{AVSEEK_FLAG_FRAME};
end;

function IntToSeekFlags(ASeekFlags: Integer): TSeekFlags;
begin
  Result := [];
  if ASeekFlags and 1 <> 0 then
    Include(Result, sfBackward)
  else if ASeekFlags and 2 <> 0 then
    Include(Result, sfByte)
  else if ASeekFlags and 4 <> 0 then
    Include(Result, sfAny)
  else if ASeekFlags and 8 <> 0 then
    Include(Result, sfFrame);
end;

{ TFFBaseComponent }

constructor TFFBaseComponent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAbout := '';
  FVersion := SVersion;
{
  if GDebuggerPresent < 0 then
    GDebuggerPresent := DebuggerPresent;
  if GDebuggerPresent > 0 then
    FReadTimeout := 0
  else
}
    FReadTimeout := 30 * 1000;
  FWriteTimeout := FReadTimeout;
{$IF Defined(NEED_IDE) Or Defined(NEED_ABOUT)}
  FShowAbout := 0;
{$IFEND}
{$IFDEF NEED_KEY}
  FKey := False;
  FLicKey := '';
  GetMem(FLic, SizeOf(TLicKey));
  FillChar(FLic^, SizeOf(TLicKey), 0);
{$ENDIF}
end;

destructor TFFBaseComponent.Destroy;
begin
{$IFDEF NEED_KEY}
  FreeMem(FLic);
{$ENDIF}
  inherited Destroy;
end;

{$IFDEF ACTIVEX}
procedure TFFBaseComponent.SetInfo(AName, AVer: string; AResID: Integer);
begin
  FName := AName;
  FResID := AResID;
  FVersion := AVer;
end;
{$ENDIF}

procedure TFFBaseComponent.ShowAbout;
begin
{$IFDEF ACTIVEX}
  ShowAboutBox(FName, FVersion, FResID);
{$ELSE}
  ShowAboutBox(Copy(ClassName, 2, MaxInt), FVersion);
{$ENDIF}
end;

{$IF Defined(NEED_IDE) Or Defined(NEED_ABOUT)}
procedure TFFBaseComponent.CheckShowAbout;
begin
  if (FShowAbout mod 3) = 0 then
    ShowAbout;
  Inc(FShowAbout);
end;
{$IFEND}

end.
