(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of swscale library api stubs.
 * Created by CodeCoolie@CNSW 2008/03/20 -> $Date:: 2012-01-16 #$
 *)

unit SwScaleStubs;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.SysUtils,
{$ELSE}
  SysUtils,
{$ENDIF}
  MyUtils,
  libswscale;

var
  sws_freeContext     : Tsws_freeContextProc      = nil;
  sws_get_class       : Tsws_get_classProc        = nil;
  sws_getCachedContext: Tsws_getCachedContextProc = nil;
  sws_getContext      : Tsws_getContextProc       = nil;
  sws_scale           : Tsws_scaleProc            = nil;

procedure SwScaleFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
procedure SwScaleUnfixStubs;

implementation

procedure SwScaleFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
begin
  FixupStub(ALibFile, AHandle, 'sws_freeContext',       @sws_freeContext);
  FixupStub(ALibFile, AHandle, 'sws_get_class',         @sws_get_class);
  FixupStub(ALibFile, AHandle, 'sws_getContext',        @sws_getContext);
  FixupStub(ALibFile, AHandle, 'sws_getCachedContext',  @sws_getCachedContext);
  FixupStub(ALibFile, AHandle, 'sws_scale',             @sws_scale);
end;

procedure SwScaleUnfixStubs;
begin
  @sws_freeContext      := nil;
  @sws_get_class        := nil;
  @sws_getCachedContext := nil;
  @sws_getContext       := nil;
  @sws_scale            := nil;
end;

end.
