(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of avdevice library api stubs.
 * Created by CodeCoolie@CNSW 2008/03/19 -> $Date:: 2011-10-28 #$
 *)

unit AVDeviceStubs;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.SysUtils,
{$ELSE}
  SysUtils,
{$ENDIF}
  MyUtils,
  libavdevice;

var
  avdevice_register_all: Tavdevice_register_allProc = nil;

procedure AVDeviceFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
procedure AVDeviceUnfixStubs;

implementation

procedure AVDeviceFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
begin
  FixupStub(ALibFile, AHandle, 'avdevice_register_all', @avdevice_register_all);

  avdevice_register_all;
end;

procedure AVDeviceUnfixStubs;
begin
  @avdevice_register_all := nil;
end;

end.
