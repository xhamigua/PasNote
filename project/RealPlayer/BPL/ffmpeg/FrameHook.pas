(*
 * Video processing hooks
 * Copyright (c) 2000, 2001 Fabrice Bellard.
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *)

(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * Original file: libavformat/framehook.c
 * Ported by CodeCoolie@CNSW 2008/07/06 -> $Date:: 2011-10-28 #$
 *)

unit FrameHook;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
{$ELSE}
  Windows,
  SysUtils,
  Classes,
{$ENDIF}

{$IFDEF FPC}
  MyUtils,
{$ENDIF}
  libavcodec,
  libavutil_error,
  libavutil_log,
  libavutil_pixfmt,
  AVUtilStubs;

{ // libavformat/framehook.h
/* Function must be called 'Configure' */
typedef int (FrameHookConfigure)(void **ctxp, int argc, char *argv[]);
typedef FrameHookConfigure *FrameHookConfigureFn;
extern FrameHookConfigure Configure;

/* Function must be called 'Process' */
typedef void (FrameHookProcess)(void *ctx, struct AVPicture *pict, enum PixelFormat pix_fmt, int width, int height, int64_t pts);
typedef FrameHookProcess *FrameHookProcessFn;
extern FrameHookProcess Process;

/* Function must be called 'Release' */
typedef void (FrameHookRelease)(void *ctx);
typedef FrameHookRelease *FrameHookReleaseFn;
extern FrameHookRelease Release;

extern int frame_hook_add(int argc, char *argv[]);
extern void frame_hook_process(struct AVPicture *pict, enum PixelFormat pix_fmt, int width, int height, int64_t pts);
extern void frame_hook_release(void);
}

type
  TFrameHookConfigureFn = function(ctxp: PPointer; argc: Integer; argv: array of PAnsiChar): Integer; cdecl;
  TFrameHookProcessFn = procedure(ctx: Pointer; pict: PAVPicture; pix_fmt: TAVPixelFormat; width, height: Integer; pts: Int64); cdecl;
  TFrameHookReleaseFn = procedure(ctx: Pointer); cdecl;

  PPFrameHookEntry = ^PFrameHookEntry;
  PFrameHookEntry = ^TFrameHookEntry;
  TFrameHookEntry = record
    next: PFrameHookEntry;
    Configure: TFrameHookConfigureFn;
    Process: TFrameHookProcessFn;
    Release: TFrameHookReleaseFn;
    ctx: Pointer;
  end;

function frame_hook_add(var first_hook: PFrameHookEntry; argc: Integer; argv: array of PAnsiChar): Integer;
procedure frame_hook_process(first_hook: PFrameHookEntry; pict: PAVPicture; pix_fmt: TAVPixelFormat; width, height: Integer; pts: Int64);
procedure frame_hook_release(var first_hook: PFrameHookEntry);

implementation

var
  GHookDLLs: TStringList = nil;

(* Returns 0 on OK *)
function frame_hook_add(var first_hook: PFrameHookEntry; argc: Integer; argv: array of PAnsiChar): Integer;
var
  I: Integer;
  HHook: THandle;
  fhe: PFrameHookEntry;
  fhep: PPFrameHookEntry;
  LHookPath: string;
  LCurrPath: string;
  LCurrDir: string;
begin
  if argc < 1 then
  begin
    Result := AVERROR_ENOENT;
    Exit;
  end;

  if GHookDLLs = nil then
    GHookDLLs := TStringList.Create;

  I := GHookDLLs.IndexOf(string(argv[0]));

  LHookPath := ExtractFilePath(string(argv[0]));
  if LHookPath <> '' then
  begin
    LCurrDir := GetCurrentDir;
    SetCurrentDir(LHookPath);
    LCurrPath := UpperCase(GetEnvironmentVariable('PATH')); {Do not Localize}
    if Pos(UpperCase(LHookPath), LCurrPath) < 1 then
      SetEnvironmentVariable('PATH', PChar(LHookPath + ';' + LCurrPath)); {Do not Localize}
  end;

  try
    if I < 0 then
    begin
{$IFDEF UNICODE}
      HHook := LoadLibraryEx(PChar(string(argv[0])), 0, LOAD_WITH_ALTERED_SEARCH_PATH);
{$ELSE}
      HHook := LoadLibraryEx(argv[0], 0, LOAD_WITH_ALTERED_SEARCH_PATH);
{$ENDIF}
      if HHook <> 0 then
        GHookDLLs.AddObject(string(argv[0]), TObject(HHook))
      else
      begin
{$IFDEF FPC}
        av_log(nil, AV_LOG_ERROR, '%s'#10, PAnsiChar(SysErrorMessage(GetLastError)));
{$ELSE}
        av_log(nil, AV_LOG_ERROR, '%s'#10, SysErrorMessage(GetLastError));
{$ENDIF}
        Result := -1;
        Exit;
      end;
    end
    else
      HHook := THandle(GHookDLLs.Objects[I]);

    fhe := av_mallocz(SizeOf(TFrameHookEntry));
    if not Assigned(fhe) then
    begin
      Result := AVERROR_ENOMEM;
      Exit;
    end;

{$IFDEF UNICODE}
  {$IFDEF VCL_XE2_OR_ABOVE}
    fhe.Configure := Winapi.Windows.GetProcAddress(HHook, AnsiString('Configure')); {Do not Localize}
    fhe.Process := Winapi.Windows.GetProcAddress(HHook, AnsiString('Process')); {Do not Localize}
    fhe.Release := Winapi.Windows.GetProcAddress(HHook, AnsiString('Release')); {Do not Localize} (* Optional *)
  {$ELSE}
    fhe.Configure := Windows.GetProcAddress(HHook, AnsiString('Configure')); {Do not Localize}
    fhe.Process := Windows.GetProcAddress(HHook, AnsiString('Process')); {Do not Localize}
    fhe.Release := Windows.GetProcAddress(HHook, AnsiString('Release')); {Do not Localize} (* Optional *)
  {$ENDIF}
{$ELSE}
    fhe.Configure := Windows.GetProcAddress(HHook, 'Configure'); {Do not Localize}
    fhe.Process := Windows.GetProcAddress(HHook, 'Process'); {Do not Localize}
    fhe.Release := Windows.GetProcAddress(HHook, 'Release'); {Do not Localize} (* Optional *)
{$ENDIF}

    if not Assigned(fhe.Process) then
    begin
      av_log(nil, AV_LOG_ERROR, 'Failed to find Process entrypoint in %s'#10, argv[0]);
      Result := AVERROR_ENOENT;
      Exit;
    end;

    if not Assigned(fhe.Configure) and (argc > 1) then
    begin
      av_log(nil, AV_LOG_ERROR, 'Failed to find Configure entrypoint in %s'#10, argv[0]);
      Result := AVERROR_ENOENT;
      Exit;
    end;

    if (argc > 1) or Assigned(fhe.Configure) then
    begin
      if fhe.Configure(@(fhe.ctx), argc, argv) <> 0 then
      begin
        av_log(nil, AV_LOG_ERROR, 'Failed to Configure %s'#10, argv[0]);
        Result := AVERROR_EINVAL;
        Exit;
      end;
    end;

    fhep := @first_hook;
    while Assigned(fhep^) do
      fhep := @(fhep^.next);

    fhep^ := fhe;

    Result := 0;
  finally
    if LHookPath <> '' then
      SetCurrentDir(LCurrDir);
  end;
end;

procedure frame_hook_process(first_hook: PFrameHookEntry; pict: PAVPicture; pix_fmt: TAVPixelFormat; width, height: Integer; pts: Int64);
var
  fhe: PFrameHookEntry;
begin
  fhe := first_hook;
  while Assigned(fhe) do
  begin
    fhe.Process(fhe.ctx, pict, pix_fmt, width, height, pts);
    fhe := fhe.next;
  end;
end;

procedure frame_hook_release(var first_hook: PFrameHookEntry);
var
  fhe: PFrameHookEntry;
  fhenext: PFrameHookEntry;
begin
  fhe := first_hook;
  while Assigned(fhe) do
  begin
    fhenext := fhe.next;
    if Assigned(fhe.Release) then
      fhe.Release(fhe.ctx);
    av_free(fhe);
    fhe := fhenext;
  end;
  first_hook := nil;
end;

initialization
finalization
  if Assigned(GHookDLLs) then
    FreeAndNil(GHookDLLs);

end.
