(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of swresample library api stubs.
 * Created by CodeCoolie@CNSW 2011/11/29 -> $Date:: 2012-12-01 #$
 *)

unit SwResampleStubs;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.SysUtils,
{$ELSE}
  SysUtils,
{$ENDIF}
  MyUtils,
  libswresample;

var
  swr_alloc               : Tswr_allocProc                = nil;
  swr_alloc_set_opts      : Tswr_alloc_set_optsProc       = nil;
  swr_convert             : Tswr_convertProc              = nil;
  swr_free                : Tswr_freeProc                 = nil;
  swr_get_class           : Tswr_get_classProc            = nil;
  swr_init                : Tswr_initProc                 = nil;
  swr_set_channel_mapping : Tswr_set_channel_mappingProc  = nil;
  swr_set_compensation    : Tswr_set_compensationProc     = nil;

procedure SwResampleFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
procedure SwResampleUnfixStubs;

implementation

procedure SwResampleFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
begin
  FixupStub(ALibFile, AHandle, 'swr_alloc',               @swr_alloc);
  FixupStub(ALibFile, AHandle, 'swr_alloc_set_opts',      @swr_alloc_set_opts);
  FixupStub(ALibFile, AHandle, 'swr_convert',             @swr_convert);
  FixupStub(ALibFile, AHandle, 'swr_free',                @swr_free);
  FixupStub(ALibFile, AHandle, 'swr_get_class',           @swr_get_class);
  FixupStub(ALibFile, AHandle, 'swr_init',                @swr_init);
  FixupStub(ALibFile, AHandle, 'swr_set_channel_mapping', @swr_set_channel_mapping);
  FixupStub(ALibFile, AHandle, 'swr_set_compensation',    @swr_set_compensation);
end;

procedure SwResampleUnfixStubs;
begin
  @swr_alloc                := nil;
  @swr_alloc_set_opts       := nil;
  @swr_convert              := nil;
  @swr_free                 := nil;
  @swr_get_class            := nil;
  @swr_init                 := nil;
  @swr_set_channel_mapping  := nil;
  @swr_set_compensation     := nil;
end;

end.
