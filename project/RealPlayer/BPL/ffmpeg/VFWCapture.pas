(*
 * VFW capture interface
 * Copyright (c) 2006-2008 Ramiro Polla
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
 * Original file: libavdevice/vfwcap.c
 * Ported by CodeCoolie@CNSW 2010/03/10 -> $Date:: 2013-11-18 #$
 *)

unit VFWCapture;

interface

{$I CompilerDefines.inc}

{.$DEFINE DEBUG_VFW}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes;
{$ELSE}
  Windows,
  Messages,
  SysUtils,
  Classes;
{$ENDIF}

procedure register_vfwcap;

var
  GVFWCapOpenCloseInMainThread: Boolean = True;
  GVFWCapTryConnectCount: Integer = 10;

implementation

uses
  libavcodec,
  AVCodecStubs,
  libavformat,
  AVFormatStubs,

  libavutil,
  libavutil_common,
  libavutil_error,
  libavutil_log,
  libavutil_opt,
  libavutil_pixfmt,
  libavutil_rational,
  AVUtilStubs,

  FFUtils,
  MyUtils;

{$I libversion.inc}

const
  WM_CAP_START                    = WM_USER;
  WM_CAP_SET_CALLBACK_VIDEOSTREAM = WM_CAP_START + 6;
  WM_CAP_DRIVER_CONNECT           = WM_CAP_START + 10;
  WM_CAP_DRIVER_DISCONNECT        = WM_CAP_START + 11;
  WM_CAP_GET_VIDEOFORMAT          = WM_CAP_START + 44;
  WM_CAP_SET_VIDEOFORMAT          = WM_CAP_START + 45;
  WM_CAP_SET_PREVIEW              = WM_CAP_START + 50;
  WM_CAP_SET_OVERLAY              = WM_CAP_START + 51;
  WM_CAP_SEQUENCE_NOFILE          = WM_CAP_START + 63;
  WM_CAP_SET_SEQUENCE_SETUP       = WM_CAP_START + 64;
  WM_CAP_GET_SEQUENCE_SETUP       = WM_CAP_START + 65;
//  WM_CAP_STOP                     = WM_CAP_START + 68;
//  WM_CAP_ABORT                    = WM_CAP_START + 69;
{$IFDEF FPC}
  HWND_MESSAGE = HWND(-3);
{$ENDIF}

const
  AVICAPDLL   = 'AVICAP32.DLL';

function capCreateCaptureWindow(
  lpszWindowName      : LPCSTR;
  dwStyle             : DWORD;
  x, y                : Integer;
  nWidth, nHeight     : Integer;
  hwndParent          : HWND;
  nID                 : Integer
  ): HWND; stdcall; external AVICAPDLL name 'capCreateCaptureWindowA';

function capGetDriverDescription(
  wDriverIndex        : UINT;
  lpszName            : LPSTR;
  cbName              : Integer;
  lpszVer             : LPSTR;
  cbVer               : Integer
  ): BOOL; stdcall; external AVICAPDLL name 'capGetDriverDescriptionA';

type
  PVIDEOHDR             = ^TVIDEOHDR;
  TVIDEOHDR             = record
    lpData              : PBYTE;                // pointer to locked data buffer
    dwBufferLength      : DWORD;                // Length of data buffer
    dwBytesUsed         : DWORD;                // Bytes actually used
    dwTimeCaptured      : DWORD;                // Milliseconds from start of stream
    dwUser              : DWORD;                // for client's use
    dwFlags             : DWORD;                // assorted flags (see defines)
    dwReserved          : array[0..3] of DWORD; // reserved for driver
  end;

  PCAPTUREPARMS                 = ^TCAPTUREPARMS;
  TCAPTUREPARMS                 = record
    dwRequestMicroSecPerFrame   : DWORD ;   // Requested capture rate
    fMakeUserHitOKToCapture     : BOOL  ;   // Show "Hit OK to cap" dlg?
    wPercentDropForError        : UINT  ;   // Give error msg if > (10%)
    fYield                      : BOOL  ;   // Capture via background task?
    dwIndexSize                 : DWORD ;   // Max index size in frames (32K)
    wChunkGranularity           : UINT  ;   // Junk chunk granularity (2K)
    fUsingDOSMemory             : BOOL  ;   // Use DOS buffers?
    wNumVideoRequested          : UINT  ;   // # video buffers, If 0, autocalc
    fCaptureAudio               : BOOL  ;   // Capture audio?
    wNumAudioRequested          : UINT  ;   // # audio buffers, If 0, autocalc
    vKeyAbort                   : UINT  ;   // Virtual key causing abort
    fAbortLeftMouse             : BOOL  ;   // Abort on left mouse?
    fAbortRightMouse            : BOOL  ;   // Abort on right mouse?
    fLimitEnabled               : BOOL  ;   // Use wTimeLimit?
    wTimeLimit                  : UINT  ;   // Seconds to capture
    fMCIControl                 : BOOL  ;   // Use MCI video source?
    fStepMCIDevice              : BOOL  ;   // Step MCI device?
    dwMCIStartTime              : DWORD ;   // Time to start in MS
    dwMCIStopTime               : DWORD ;   // Time to stop in MS
    fStepCaptureAt2x            : BOOL  ;   // Perform spatial averaging 2x
    wStepCaptureAverageFrames   : UINT  ;   // Temporal average n Frames
    dwAudioBufferSize           : DWORD ;   // Size of audio bufs (0 = default)
    fDisableWriteCache          : BOOL  ;   // Attempt to disable write cache
    AVStreamMaster              : UINT  ;   // Which stream controls length?
  end;

type
  TVFWCapture = class;

  Pvfw_ctx = ^Tvfw_ctx;
  Tvfw_ctx = record
    class_: PAVClass;
    hwnd: HWND;
    mutex: THANDLE;
    event: THANDLE;
    pktl: PAVPacketList;
    curbufsize: Cardinal;
    frame_num: Cardinal;
    video_size: PAnsiChar;       (**< A string describing video size, set by a private option. *)
    framerate: PAnsiChar;        (**< Set by a private option. *)
    VFWCapture: TVFWCapture;
  end;

  TVFWCapture = class
  private
    Fvfw_ctx: Pvfw_ctx;
  protected
    procedure CallOpen;
    procedure CallClose;
    procedure Open;
    procedure Close;
  public
    constructor Create(Avfw_ctx: Pvfw_ctx);
    destructor Destroy; override;
  end;

function count_vfw_drivers: Integer;
var
  wIndex: Integer;
  szDeviceName: array[0..80] of AnsiChar;
  szDeviceVersion: array[0..80] of AnsiChar;
  P1, P2: PAnsiChar;
begin
  Result := 0;
  P1 := @szDeviceName[0];
  P2 := @szDeviceVersion[0];
  for wIndex := 0 to 10 - 1 do
    if capGetDriverDescription(
            wIndex,
            P1, // szDeviceName,
            SizeOf(szDeviceName),
            P2, // szDeviceVersion,
            SizeOf(szDeviceVersion)) then
    Inc(Result);
end;

procedure list_vfw_drivers(log_level: Integer);
var
  wIndex: Integer;
  szDeviceName: array[0..80] of AnsiChar;
  szDeviceVersion: array[0..80] of AnsiChar;
  P1, P2: PAnsiChar;
begin
  P1 := @szDeviceName[0];
  P2 := @szDeviceVersion[0];
  for wIndex := 0 to 10 - 1 do
    if capGetDriverDescription(
            wIndex,
            P1, // szDeviceName,
            SizeOf(szDeviceName),
            P2, // szDeviceVersion,
            SizeOf(szDeviceVersion)) then
      av_log(nil, log_level, 'VFW Driver device #%d %s %s'#10,
            wIndex, P1{szDeviceName}, P2{szDeviceVersion});
end;

function vfw_pixfmt(biCompression: DWORD; biBitCount: WORD): TAVPixelFormat;
const
  TAG_UYVY = Ord('U') or (Ord('Y') shl 8) or (Ord('V') shl 16) or (Ord('Y') shl 24);
begin
  case biCompression of
    TAG_UYVY: Result := AV_PIX_FMT_UYVY422;
    TAG_YUY2: Result := AV_PIX_FMT_YUYV422;
    TAG_I420: Result := AV_PIX_FMT_YUV420P;
    BI_RGB:
      begin
        case biBitCount of (* 1-8 are untested *)
          1:  Result := AV_PIX_FMT_MONOWHITE;
          4:  Result := AV_PIX_FMT_RGB4;
          8:  Result := AV_PIX_FMT_RGB8;
          16: Result := AV_PIX_FMT_RGB555;
          24: Result := AV_PIX_FMT_BGR24;
          32: Result := AV_PIX_FMT_RGB32;
        else
          Result := AV_PIX_FMT_NONE;
        end;
      end;
  else
    Result := AV_PIX_FMT_NONE;
  end;
end;

function vfw_codecid(biCompression: DWORD): TAVCodecID;
const
  TAG_MJPG = Ord('M') or (Ord('J') shl 8) or (Ord('P') shl 16) or (Ord('G') shl 24);
  TAG_MJPG_S = Ord('m') or (Ord('j') shl 8) or (Ord('p') shl 16) or (Ord('g') shl 24);
begin
  case biCompression of
    TAG_dvsd: Result := AV_CODEC_ID_DVVIDEO;
    TAG_MJPG,
    TAG_MJPG_S: Result := AV_CODEC_ID_MJPEG;
  else
    Result := AV_CODEC_ID_NONE;
  end;
end;

procedure dump_captureparms(s: PAVFormatContext; cparms: PCAPTUREPARMS);
begin
  av_log(s, AV_LOG_DEBUG, 'CAPTUREPARMS'#10);
  av_log(s, AV_LOG_DEBUG, 'dwRequestMicroSecPerFrame:'#9'%lu'#10, cparms.dwRequestMicroSecPerFrame);
  av_log(s, AV_LOG_DEBUG, 'fMakeUserHitOKToCapture:'#9'%d'#10, cparms.fMakeUserHitOKToCapture);
  av_log(s, AV_LOG_DEBUG, 'wPercentDropForError:'#9'%u'#10, cparms.wPercentDropForError);
  av_log(s, AV_LOG_DEBUG, 'fYield:'#9'%d'#10, cparms.fYield);
  av_log(s, AV_LOG_DEBUG, 'dwIndexSize:'#9'%lu'#10, cparms.dwIndexSize);
  av_log(s, AV_LOG_DEBUG, 'wChunkGranularity:'#9'%u'#10, cparms.wChunkGranularity);
  av_log(s, AV_LOG_DEBUG, 'fUsingDOSMemory:'#9'%d'#10, cparms.fUsingDOSMemory);
  av_log(s, AV_LOG_DEBUG, 'wNumVideoRequested:'#9'%u'#10, cparms.wNumVideoRequested);
  av_log(s, AV_LOG_DEBUG, 'fCaptureAudio:'#9'%d'#10, cparms.fCaptureAudio);
  av_log(s, AV_LOG_DEBUG, 'wNumAudioRequested:'#9'%u'#10, cparms.wNumAudioRequested);
  av_log(s, AV_LOG_DEBUG, 'vKeyAbort:'#9'%u'#10, cparms.vKeyAbort);
  av_log(s, AV_LOG_DEBUG, 'fAbortLeftMouse:'#9'%d'#10, cparms.fAbortLeftMouse);
  av_log(s, AV_LOG_DEBUG, 'fAbortRightMouse:'#9'%d'#10, cparms.fAbortRightMouse);
  av_log(s, AV_LOG_DEBUG, 'fLimitEnabled:'#9'%d'#10, cparms.fLimitEnabled);
  av_log(s, AV_LOG_DEBUG, 'wTimeLimit:'#9'%u'#10, cparms.wTimeLimit);
  av_log(s, AV_LOG_DEBUG, 'fMCIControl:'#9'%d'#10, cparms.fMCIControl);
  av_log(s, AV_LOG_DEBUG, 'fStepMCIDevice:'#9'%d'#10, cparms.fStepMCIDevice);
  av_log(s, AV_LOG_DEBUG, 'dwMCIStartTime:'#9'%lu'#10, cparms.dwMCIStartTime);
  av_log(s, AV_LOG_DEBUG, 'dwMCIStopTime:'#9'%lu'#10, cparms.dwMCIStopTime);
  av_log(s, AV_LOG_DEBUG, 'fStepCaptureAt2x:'#9'%d'#10, cparms.fStepCaptureAt2x);
  av_log(s, AV_LOG_DEBUG, 'wStepCaptureAverageFrames:'#9'%u'#10, cparms.wStepCaptureAverageFrames);
  av_log(s, AV_LOG_DEBUG, 'dwAudioBufferSize:'#9'%lu'#10, cparms.dwAudioBufferSize);
  av_log(s, AV_LOG_DEBUG, 'fDisableWriteCache:'#9'%d'#10, cparms.fDisableWriteCache);
  av_log(s, AV_LOG_DEBUG, 'AVStreamMaster:'#9'%u'#10, cparms.AVStreamMaster);
end;

procedure dump_videohdr(s: PAVFormatContext; vhdr: PVIDEOHDR);
begin
  av_log(s, AV_LOG_DEBUG, 'VIDEOHDR'#10);
  av_log(s, AV_LOG_DEBUG, 'lpData:'#9'%p'#10, vhdr.lpData);
  av_log(s, AV_LOG_DEBUG, 'dwBufferLength:'#9'%lu'#10, vhdr.dwBufferLength);
  av_log(s, AV_LOG_DEBUG, 'dwBytesUsed:'#9'%lu'#10, vhdr.dwBytesUsed);
  av_log(s, AV_LOG_DEBUG, 'dwTimeCaptured:'#9'%lu'#10, vhdr.dwTimeCaptured);
  av_log(s, AV_LOG_DEBUG, 'dwUser:'#9'%lu'#10, vhdr.dwUser);
  av_log(s, AV_LOG_DEBUG, 'dwFlags:'#9'%lu'#10, vhdr.dwFlags);
  av_log(s, AV_LOG_DEBUG, 'dwReserved[0]:'#9'%lu'#10, vhdr.dwReserved[0]);
  av_log(s, AV_LOG_DEBUG, 'dwReserved[1]:'#9'%lu'#10, vhdr.dwReserved[1]);
  av_log(s, AV_LOG_DEBUG, 'dwReserved[2]:'#9'%lu'#10, vhdr.dwReserved[2]);
  av_log(s, AV_LOG_DEBUG, 'dwReserved[3]:'#9'%lu'#10, vhdr.dwReserved[3]);
end;

procedure dump_bih(s: PAVFormatContext; bih: PBITMAPINFOHEADER);
var
  P: PAnsiChar;
begin
  av_log(s, AV_LOG_DEBUG, 'BITMAPINFOHEADER'#10);
  av_log(s, AV_LOG_DEBUG, 'biSize:'#9'%lu'#10, bih.biSize);
  av_log(s, AV_LOG_DEBUG, 'biWidth:'#9'%ld'#10, bih.biWidth);
  av_log(s, AV_LOG_DEBUG, 'biHeight:'#9'%ld'#10, bih.biHeight);
  av_log(s, AV_LOG_DEBUG, 'biPlanes:'#9'%d'#10, bih.biPlanes);
  av_log(s, AV_LOG_DEBUG, 'biBitCount:'#9'%d'#10, bih.biBitCount);
  av_log(s, AV_LOG_DEBUG, 'biCompression:'#9'%lu'#10, bih.biCompression);
  P := @bih.biCompression;
  av_log(s, AV_LOG_DEBUG, 'biCompression:'#9'"%.4s"'#10, P); //(char*) &bih.biCompression);
  av_log(s, AV_LOG_DEBUG, 'biSizeImage:'#9'%lu'#10, bih.biSizeImage);
  av_log(s, AV_LOG_DEBUG, 'biXPelsPerMeter:'#9'%lu'#10, bih.biXPelsPerMeter);
  av_log(s, AV_LOG_DEBUG, 'biYPelsPerMeter:'#9'%lu'#10, bih.biYPelsPerMeter);
  av_log(s, AV_LOG_DEBUG, 'biClrUsed:'#9'%lu'#10, bih.biClrUsed);
  av_log(s, AV_LOG_DEBUG, 'biClrImportant:'#9'%lu'#10, bih.biClrImportant);
end;

function shall_we_drop(s: PAVFormatContext): Integer;
const
  dropscore: array[0..3] of Byte = (62, 75, 87, 100);
  ndropscores: Cardinal = 4;
var
  ctx: Pvfw_ctx;
  buffer_fullness: Cardinal;
begin
  ctx := s.priv_data;
  buffer_fullness := (ctx.curbufsize * 100) div s.max_picture_buffer;

  Inc(ctx.frame_num);
  if dropscore[ctx.frame_num mod ndropscores] <= buffer_fullness then
  begin
    av_log(s, AV_LOG_ERROR,
        'real-time buffer %d%% full! frame dropped!'#10, buffer_fullness);
    Result := 1;
  end
  else
    Result := 0;
end;

type
  PPAVPacketList = ^PAVPacketList;

function videostream_cb(hwnd: HWND; vdhdr: PVIDEOHDR): LRESULT; stdcall;
var
  s: PAVFormatContext;
  ctx: Pvfw_ctx;
  ppktl: PPAVPacketList;
  pktl_next: PAVPacketList;
begin
  s := PAVFormatContext(GetWindowLong{Ptr}(hwnd, {GWLP}GWL_USERDATA));
  ctx := s.priv_data;
  if ctx.hwnd = 0 then
  begin
    Result := 0;
    Exit;
  end;

{$IFDEF DEBUG_VFW}
  dump_videohdr(s, vdhdr);
{$ENDIF}

  if shall_we_drop(s) <> 0 then
  begin
    Result := 0;
    Exit;
  end;

  WaitForSingleObject(ctx.mutex, INFINITE);
  try
    pktl_next := av_mallocz(SizeOf(TAVPacketList));
    if not Assigned(pktl_next) then
    begin
      Result := 0;
      Exit;
    end;

    if av_new_packet(@pktl_next.pkt, vdhdr.dwBytesUsed) < 0 then
    begin
      av_free(pktl_next);
      Result := 0;
      Exit;
    end;

    pktl_next.pkt.pts := vdhdr.dwTimeCaptured;
    Move(vdhdr.lpData^, pktl_next.pkt.data^, vdhdr.dwBytesUsed);

    ppktl := @ctx.pktl;
    while Assigned(ppktl^) do
      ppktl := @ppktl^.next;
    ppktl^ := pktl_next;

    Inc(ctx.curbufsize, vdhdr.dwBytesUsed);

    SetEvent(ctx.event);

    Result := 1;
  finally
    ReleaseMutex(ctx.mutex);
  end;
end;

function vfw_read_close(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pvfw_ctx;
  pktl: PAVPacketList;
  next: PAVPacketList;
begin
  ctx := s.priv_data;

  if Assigned(ctx.VFWCapture) then
  begin
    ctx.VFWCapture.Close;
    FreeAndNil(ctx.VFWCapture);
  end;

  if ctx.mutex <> 0 then
  begin
    CloseHandle(ctx.mutex);
    ctx.mutex := 0;
  end;
  if ctx.event <> 0 then
  begin
    CloseHandle(ctx.event);
    ctx.event := 0;
  end;

  pktl := ctx.pktl;
  while Assigned(pktl) do
  begin
    next := pktl.next;
    av_destruct_packet(@pktl.pkt);
    av_free(pktl);
    pktl := next;
  end;

  Result := 0;
end;

function vfw_read_header(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pvfw_ctx;
  codec: PAVCodecContext;
  st: PAVStream;
  devnum: Integer;
  bisize: Integer;
  bi: PBITMAPINFO;
  cparms: TCAPTUREPARMS;
  biCompression: DWORD;
  biBitCount: WORD;
  Ret: LRESULT;
  framerate_q: TAVRational;
  loop: Integer;
label
  fail;
begin
  if count_vfw_drivers = 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'No VFW device found'#10);
    Result := AVERROR_ENODEV;
    Exit;
  end;

  ctx := s.priv_data;
  bi := nil;

  ctx.VFWCapture := TVFWCapture.Create(ctx); // used for open/close capture window

  //ctx.hwnd := capCreateCaptureWindow(nil, 0, 0, 0, 0, 0, HWND_MESSAGE, 0);
  ctx.VFWCapture.Open;

  if ctx.hwnd = 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Could not create capture window.'#10);
    goto fail;
  end;

  (* If atoi fails, devnum==0 and the default device is used *)
  devnum := StrToIntDef(string(s.filename), 0);

  // it needs WM_CAP_DRIVER_CONNECT for more times under Win7
  if GVFWCapTryConnectCount < 1 then
    loop := MaxInt
  else
    loop := GVFWCapTryConnectCount;
  repeat
    Ret := SendMessage(ctx.hwnd, WM_CAP_DRIVER_CONNECT, devnum, 0);
    Dec(loop);
  until (Ret <> 0) or (loop = 0);
  if Ret = 0 then
  begin
    list_vfw_drivers(AV_LOG_INFO);
    av_log(s, AV_LOG_ERROR, 'Could not connect to device #%s.'#10, s.filename);
    vfw_read_close(s);
    Result := AVERROR_ENODEV;
    Exit;
  end;

  SendMessage(ctx.hwnd, WM_CAP_SET_OVERLAY, 0, 0);
  SendMessage(ctx.hwnd, WM_CAP_SET_PREVIEW, 0, 0);

  Ret := SendMessage(ctx.hwnd, WM_CAP_SET_CALLBACK_VIDEOSTREAM, 0, LPARAM(@videostream_cb));
  if Ret = 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Could not set video stream callback.'#10);
    goto fail;
  end;

  SetWindowLong{Ptr}(ctx.hwnd, {GWLP}GWL_USERDATA, {LONG_PTR}Integer(s));

  st := avformat_new_stream(s, nil);
  if not Assigned(st) then
  begin
    vfw_read_close(s);
    Result := AVERROR_ENOMEM;
    Exit;
  end;

  (* Set video format *)
  bisize := SendMessage(ctx.hwnd, WM_CAP_GET_VIDEOFORMAT, 0, 0);
  if bisize = 0 then
    goto fail;
  bi := av_malloc(bisize);
  if not Assigned(bi) then
  begin
    vfw_read_close(s);
    Result := AVERROR_ENOMEM;
    Exit;
  end;
  Ret := SendMessage(ctx.hwnd, WM_CAP_GET_VIDEOFORMAT, bisize, LPARAM(bi));
  if Ret = 0 then
    goto fail;

  dump_bih(s, @bi.bmiHeader);

  ret := av_parse_video_rate(@framerate_q, ctx.framerate);
  if ret < 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Could not parse framerate "%s".'#10, ctx.framerate);
    goto fail;
  end;

  if Assigned(ctx.video_size) and (ctx.video_size <> '') then
  begin
    ret := av_parse_video_size(@bi.bmiHeader.biWidth, @bi.bmiHeader.biHeight, ctx.video_size);
    if ret < 0 then
    begin
      av_log(s, AV_LOG_ERROR, 'Couldn''t parse video size.'#10);
      goto fail;
    end;
  end;

{
  (* For testing yet unsupported compressions
   * Copy these values from user-supplied verbose information *)
  bi.bmiHeader.biWidth       := 320;
  bi.bmiHeader.biHeight      := 240;
  bi.bmiHeader.biPlanes      := 1;
  bi.bmiHeader.biBitCount    := 12;
  bi.bmiHeader.biCompression := TAG_I420;
  bi.bmiHeader.biSizeImage   := 115200;
  dump_bih(s, @bi.bmiHeader);
}

  Ret := SendMessage(ctx.hwnd, WM_CAP_SET_VIDEOFORMAT, bisize, LPARAM(bi));
  if Ret = 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Could not set Video Format.'#10);
    goto fail;
  end;

  biCompression := bi.bmiHeader.biCompression;
  biBitCount := bi.bmiHeader.biBitCount;

  (* Set sequence setup *)
  Ret := SendMessage(ctx.hwnd, WM_CAP_GET_SEQUENCE_SETUP, sizeof(cparms), LPARAM(@cparms));
  if Ret = 0 then
    goto fail;

  dump_captureparms(s, @cparms);

  cparms.fYield := True; // Spawn a background thread
  cparms.dwRequestMicroSecPerFrame := (framerate_q.den * 1000000) div framerate_q.num;
  cparms.fAbortLeftMouse := False;
  cparms.fAbortRightMouse := False;
  cparms.fCaptureAudio := False;
  cparms.vKeyAbort := 0;

  Ret := SendMessage(ctx.hwnd, WM_CAP_SET_SEQUENCE_SETUP, sizeof(cparms), LPARAM(@cparms));
  if Ret = 0 then
    goto fail;

  codec := st.codec;
  codec.time_base.num := framerate_q.den;
  codec.time_base.den := framerate_q.num;
  codec.codec_type := AVMEDIA_TYPE_VIDEO;
  codec.width := bi.bmiHeader.biWidth;
  codec.height := bi.bmiHeader.biHeight;
  codec.pix_fmt := vfw_pixfmt(biCompression, biBitCount);
  codec.thread_count := 1; // avoid multithreading issue of log callback
  if codec.pix_fmt = AV_PIX_FMT_NONE then
  begin
    codec.codec_id := vfw_codecid(biCompression);
    if codec.codec_id = AV_CODEC_ID_NONE then
    begin
      av_log(s, AV_LOG_ERROR, 'Unknown compression type. ' +
               'Please report verbose (-v 9) debug information.'#10);
      vfw_read_close(s);
      Result := AVERROR_PATCHWELCOME;
      Exit;
    end;
    codec.bits_per_coded_sample := biBitCount;
  end
  else
  begin
    codec.codec_id := AV_CODEC_ID_RAWVIDEO;
    if biCompression = BI_RGB then
      codec.bits_per_coded_sample := biBitCount;
  end;

  av_freep(@bi);

  av_set_pts_info(st, 32, 1, 1000);

  // !!! to avoid av_find_stream_info() to read packets
  // condition 1
  st.r_frame_rate := framerate_q;
  st.avg_frame_rate := framerate_q;
  // condition 2
  s.flags := s.flags or AVFMT_FLAG_NOPARSE;
  // condition 3
  st.first_dts := 0;
  // condition ALL
  s.probesize := 0;

  ctx.mutex := CreateMutex(nil, False, nil);
  if ctx.mutex = 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Could not create Mutex.'#10);
    goto fail;
  end;
  ctx.event := CreateEvent(nil, True, False, nil);
  if ctx.event = 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Could not create Event.'#10);
    goto fail;
  end;

  Ret := SendMessage(ctx.hwnd, WM_CAP_SEQUENCE_NOFILE, 0, 0);
  if Ret = 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Could not start capture sequence.'#10);
    goto fail;
  end;

  Result := 0;
  Exit;

fail:
  av_freep(@bi);
  vfw_read_close(s);
  Result := AVERROR_EIO;
end;

function vfw_read_packet(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;
var
  ctx: Pvfw_ctx;
  pktl: PAVPacketList;
begin
  ctx := s.priv_data;
  pktl := nil;

  while not Assigned(pktl) do
  begin
    WaitForSingleObject(ctx.mutex, INFINITE);
    pktl := ctx.pktl;
    if Assigned(ctx.pktl) then
    begin
      pkt^ := ctx.pktl.pkt;
      ctx.pktl := ctx.pktl.next;
      av_free(pktl);
    end;
    ResetEvent(ctx.event);
    ReleaseMutex(ctx.mutex);
    if not Assigned(pktl) then
    begin
      if (s.flags and AVFMT_FLAG_NONBLOCK) <> 0 then
      begin
        Result := AVERROR_EAGAIN;
        Exit;
      end
      else
      begin
        //WaitForSingleObject(ctx.event, INFINITE);
        if WaitForSingleObject(ctx.event, 1000) <> WAIT_OBJECT_0 then
        begin
          Result := AVERROR_EAGAIN;
          Exit;
        end;
      end;
    end;
  end;

  Dec(ctx.curbufsize, pkt.size);

  Result := pkt.size;
end;

var
  options: array[0..2] of TAVOption = (
    (name       : 'video_size';
     help       : 'A string describing frame size, such as 640x480 or hd720.';
     offset     : -1;
     ttype      : AV_OPT_TYPE_STRING;
     default_val: (str: nil);
     min        : 0;
     max        : 0;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'framerate';
     help       : '';
     offset     : -1;
     ttype      : AV_OPT_TYPE_STRING;
     default_val: (str: 'ntsc');
     min        : 0;
     max        : 0;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : nil;)
  );

  vfw_class: TAVClass = (
    class_name: 'VFW indev';
    //item_name : av_default_item_name;
    option    : @options[0];
    version   : LIBAVUTIL_VERSION_INT;
  );

  vfwcap_demuxer: TAVInputFormat = (
    name: 'vfwcapture';
    long_name: 'VfW video capture';
    flags: AVFMT_NOFILE;
    priv_class: @vfw_class;
    priv_data_size: SizeOf(Tvfw_ctx);
    read_header: vfw_read_header;
    read_packet: vfw_read_packet;
    read_close: vfw_read_close;
  );

procedure register_vfwcap;
var
  ctx: Tvfw_ctx;
begin
  Assert(Assigned(av_default_item_name));
  vfw_class.item_name := av_default_item_name;
  options[0].offset := Integer(@ctx.video_size) - Integer(@ctx);
  options[1].offset := Integer(@ctx.framerate) - Integer(@ctx);
  RegisterInputFormat(@vfwcap_demuxer);
  list_vfw_drivers(AV_LOG_DEBUG);
end;

{ TVFWCapture }

constructor TVFWCapture.Create(Avfw_ctx: Pvfw_ctx);
begin
  Fvfw_ctx := Avfw_ctx;
end;

destructor TVFWCapture.Destroy;
begin
  Close;
  inherited;
end;

procedure TVFWCapture.CallOpen;
begin
  Fvfw_ctx.hwnd := capCreateCaptureWindow(nil, 0, 0, 0, 0, 0, HWND(HWND_MESSAGE), 0);
end;

procedure TVFWCapture.Open;
begin
  if GVFWCapOpenCloseInMainThread then
    MySynchronize(CallOpen)
  else
    CallOpen;
end;

procedure TVFWCapture.CallClose;
var
  h: HWND;
begin
  if Assigned(Fvfw_ctx) then
  begin
    if Fvfw_ctx.hwnd <> 0 then
    begin
      h := Fvfw_ctx.hwnd;
      Fvfw_ctx.hwnd := 0;
      SendMessage(h, WM_CAP_SET_CALLBACK_VIDEOSTREAM, 0, 0);
      SendMessage(h, WM_CAP_DRIVER_DISCONNECT, 0, 0);
      DestroyWindow(h);
    end;
    Fvfw_ctx := nil;
  end;
end;

procedure TVFWCapture.Close;
begin
  if Assigned(Fvfw_ctx) then
  begin
    if GVFWCapOpenCloseInMainThread then
      MySynchronize(CallClose)
    else
      CallClose;
    Fvfw_ctx := nil;
  end;
end;

end.
