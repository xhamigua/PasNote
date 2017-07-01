(*
 * Copyright (c) 2000-2003 Fabrice Bellard
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

(**
 * @file
 * multimedia converter based on the FFmpeg libraries
 *)

(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * Original file: ffmpeg.c
 * Ported by CodeCoolie@CNSW 2008/03/25 -> $Date:: 2013-12-24 #$
 *)

unit FFmpeg;

interface

{$I CompilerDefines.inc}

{$I _LicenseDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  {$IFDEF POSIX}
    Posix.Unistd, // DeleteFile -> unlink
  {$ENDIF}
  System.SysUtils,
  {$IFDEF VCL_XE4_OR_ABOVE}
    System.AnsiStrings, // StrLen
  {$ENDIF}
  System.Classes,
  {$IFDEF FFFMX}
    {$IFDEF VCL_XE5_OR_ABOVE}
      FMX.Graphics,
    {$ELSE}
      FMX.Types,
    {$ENDIF}
  {$ELSE}
    Vcl.Graphics,
  {$ENDIF}

  System.SyncObjs,
  System.Math,
{$ELSE}
  Windows,
  SysUtils,
  Classes,
  Graphics,

  SyncObjs,
  Math,
{$ENDIF}

{$IFDEF BCB}
  BCBTypes,
{$ENDIF}

{$IFDEF USES_LICKEY}
  LicenseKey,
{$ENDIF}

  libavcodec,
  AVCodecStubs,

  libavformat,
  libavformat_avio,
  AVFormatStubs,

  libavfilter,
  AVFilterStubs,

  libavutil,
  libavutil_common,
  libavutil_dict,
  libavutil_error,
  libavutil_fifo,
  libavutil_frame,
  libavutil_log,
  libavutil_pixdesc,
  libavutil_pixfmt,
  libavutil_rational,
  libavutil_samplefmt,
  AVUtilStubs,

  libswresample,
  SwResampleStubs,

  libswscale,
  SwScaleStubs,

{$IFDEF MSWINDOWS}
  FrameHook,
{$ENDIF}

  MyUtils,
  MyUtilStubs,

  FFmpegOpt,
  Previewer,
  UnicodeProtocol,
  FFBaseComponent,
  FFUtils;

{$I libversion.inc}

const
  CReportInterval           = 500;  // 0.5 second
  CPreviewInterval          = 100;  // 0.1 second

  DEFAULT_PASS_LOGFILENAME_PREFIX  = 'ffencoder2pass';

  CHECK_LOG_MSG = 'Please check error log message(reported by FFLogger) to find out more detail information.';

type
  PPostHookContext = ^TPostHookContext;
  TPostHookContext = record
    Converter: TFormatConverter;
    Previewer: TPreviewer;
    preview_last_time: Int64;
    preview_cur_time: Int64;
  end;

  TPostHook = (phPreview, phBitmap, phHBITMAP);
  TPostHooks = set of TPostHook;

  TAudioHookEvent = procedure(Sender: TObject; const APTS: Int64; ASample: PByte;
    ASize, ASampleRate, AChannels: Integer; ASampleFormat: TAVSampleFormat) of object;
  TPreviewBitmapEvent = procedure(Sender: TObject; ABitmap: TBitmap;
    AFrameNumber: Integer; const APTS: Int64) of object;
  TProgressEvent = procedure(Sender: TObject; AFileIndex, AFrameNumber, AFPS: Integer;
    const AQuality, ABitRate: Single; const ACurrentSize, ACurrentDuration, ATotalDuration: Int64) of object;
  TVideoHookEvent = procedure(Sender: TObject; ABitmap: {$IFDEF ACTIVEX}PBitmap{$ELSE}TBitmap{$ENDIF};
    AFrameNumber: Integer; const APTS: Int64; var AUpdate, AStopHook: Boolean) of object;
  TFrameHookEvent = procedure(Sender: TObject; APicture: PAVPicture; APixFmt: TAVPixelFormat;
    AFrameNumber, AWidth, AHeight: Integer; const APTS: Int64) of object;

  TCustomFFmpeg = class;

{$IFDEF POSIX}
  TThreadPriority = Integer;
{$ENDIF}

  TConvertThread = class(TThread)
  private
    FOwner: TCustomFFmpeg;
  protected
    procedure Execute; override;
  public
    {$WARN SYMBOL_PLATFORM OFF}
    constructor Create(AOwner: TCustomFFmpeg; APriority: TThreadPriority);
    destructor Destroy; override;
  end;

  TDoTerminateThread = class(TThread)
  private
    FOwner: TCustomFFmpeg;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TCustomFFmpeg);
    destructor Destroy; override;
  end;

  TCustomFFmpeg = class(TCustomFFmpegOpt)
  protected
    Fvstats_file: Pointer; // FILE *

    //Frun_as_daemon: Integer;
    Fvideo_size: Int64;
    Faudio_size: Int64;
    Fsubtitle_size: Int64;
    Fextra_size: Int64;
    Fnb_frames_dup: Integer;
    Fnb_frames_drop: Integer;
    Fdecode_error_stat: array[Boolean] of Int64;

    //Fcurrent_time: Int64; // Integer;
    //Fprogress_avio: PAVIOContext; // move to FFmpegOpt.pas

    Fsubtitle_out: PByte;

{   // move to FFmpegOpt.pas
    Finput_streams: PPInputStream;
    Fnb_input_streams: Integer;
    Finput_files: PPInputFile;
    Fnb_input_files: Integer;

    Foutput_streams: PPOutputStream;
    Fnb_output_streams: Integer;
    Foutput_files: PPOutputFile;
    Fnb_output_files: Integer;

    Ffiltergraphs: PPFilterGraph;
    Fnb_filtergraphs: Integer;
}
    Flast_time: Int64;
    Fqp_histogram: array[0..51] of Integer;

    procedure ffmpeg_cleanup();
    procedure write_frame(s: PAVFormatContext; pkt: PAVPacket; ost: POutputStream);
    procedure close_output_stream(ost: POutputStream);
    function check_recording_time(ost: POutputStream): Integer;
    procedure do_audio_out(s: PAVFormatContext; ost: POutputStream; frame: PAVFrame);
    procedure pre_process_video_frame(ist: PInputStream; picture: PAVPicture);
    procedure do_subtitle_out(s: PAVFormatContext; ost: POutputStream;
                              ist: PInputStream; sub: PAVSubtitle);
    procedure DoVideoHook(var AHookEvent: TVideoHookEvent; ARGBConverter: TFormatConverter;
                          picture: PAVPicture; codec: PAVCodecContext; AFrameNumber: Integer;
                          const APTS: Int64; var ABitmapReady: Boolean);
    procedure DoPostHooks(picture: PAVPicture; codec: PAVCodecContext;
                          AFrameNumber: Integer; const APTS: Int64; ABitmapReady: Boolean);
    procedure do_video_out(s: PAVFormatContext; ost: POutputStream; in_picture: PAVFrame);
    procedure do_video_stats(ost: POutputStream; frame_size: Integer);
    function reap_filters: Integer;
    procedure print_report(cur_file_index, is_last_report: Integer; timer_start, cur_time: Int64);
    procedure flush_encoders;
    function check_output_constraints(ist: PInputStream; ost: POutputStream): Integer;
    procedure do_streamcopy(ist: PInputStream; ost: POutputStream; pkt: PAVPacket);
    function decode_audio(ist: PInputStream; pkt: PAVPacket; got_output: PInteger): Integer;
    function decode_video(ist: PInputStream; pkt: PAVPacket; got_output: PInteger): Integer;
    function transcode_subtitles(ist: PInputStream; pkt: PAVPacket; got_output: PInteger): Integer;
    function output_packet(ist: PInputStream; const pkt: PAVPacket): Integer;
    procedure print_sdp();
    function init_input_stream(ist_index: Integer; var error: string): Integer;
    function get_input_stream(ost: POutputStream): PInputStream;
    procedure report_new_stream(input_index: Integer; pkt: PAVPacket);
    function transcode_init(): Integer;
    procedure DumpInformation;
    function need_output: Integer;
    function choose_output: POutputStream;
    function SendFilterCommand(target, cmd, arg: string; flags: Integer): Boolean;
    function QueueFilterCommand(target, cmd, arg: string; flags: Integer; pts: Double): Boolean;
    function get_input_packet(f: PInputFile; pkt: PAVPacket): Integer;
    function got_eagain: Integer;
    procedure reset_eagain;
    procedure CalcOstIdx; // hack
    function process_input(file_index: Integer): Integer;
    function transcode_from_filter(graph: PFilterGraph; best_ist: PPInputStream): Integer;
    function transcode_step: Integer;
    procedure transcode_cleanup();
    function do_transcode_init: Boolean;
    procedure transcode();

{$IFDEF MSWINDOWS}
    function add_frame_hooker(optctx: Pointer; opt, arg: PAnsiChar): Integer; override;
{$ENDIF}
{$IFNDEF FFFMX}
    function opt_VideoHookBitsPixel(optctx: Pointer; opt, arg: PAnsiChar): Integer; override;
{$ENDIF}
  private
    FShowDupOrDrop: Boolean;
    Fusing_vhook: Boolean;
{$IFDEF MSWINDOWS}
    FFirstHook: PFrameHookEntry;
{$ENDIF}

    FEncoderList: Pointer{PCodecItem};
    FDecoderList: Pointer{PCodecItem};
    FThread: TConvertThread;
    FStopEvent: TEvent;
    FTermEvent: TEvent;
    FInputPictureBuf: PByte;
    FInputPictureBufSize: Integer;
    FInputVideoHook: TFormatConverter;
    FOutputPictureBuf: PByte;
    FOutputPictureBufSize: Integer;
    FOutputVideoHook: TPostHookContext;
    FPostHooks: TPostHooks;
    FPostHooksChanged: Boolean;

    FConverting: Boolean;
    FFinished: Boolean;
    FTerminated: Boolean;
    FTranscodeInitialized: Boolean;
    FTranscodeCleanuped: Boolean;
    Fjoin_file_index: Integer;
    Fost_from_idx: Integer;
    Fost_to_idx: Integer;
    FPauseTime: Int64;
    FTotalPauseTime: Int64;

    FFatalException: Boolean;
    FFatalMessage: string;

{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
    Fyuv01: Integer;
    Fyuv23: Integer;
    Fyuv45: Integer;
{$IFEND}

    FOnInputAudioHook: TAudioHookEvent;
    FOnOutputAudioHook: TAudioHookEvent;
    FOnInputVideoHook: TVideoHookEvent;
    FOnOutputVideoHook: TVideoHookEvent;
    FOnInputFrameHook: TFrameHookEvent;
    FOnOutputFrameHook: TFrameHookEvent;
    FOnPreviewBitmap: TPreviewBitmapEvent;
    FOnProgress: TProgressEvent;
    FOnTerminate: TNotifyEvent;

    procedure Finalize;
  protected
    ReportInterval: Int64;
    PreviewInterval: Int64;
    procedure DoConvert;
    procedure DoTerminate;
    procedure StopAndDoTerminate(const AWaitForStop: Boolean);
    procedure _SetPostHooks(const AValue: TPostHooks);
    procedure SetPostHooks(const AValue: TPostHooks);
{$IFNDEF FFFMX}
    function GetVideoHookBitsPixel: Integer;
    procedure SetVideoHookBitsPixel(const AValue: Integer);
{$ENDIF}
{$IFDEF ACTIVEX}
  public
{$ENDIF}
    function Get_input_files(Index: Integer): PAVFormatContext;
    function Get_output_files(Index:Integer): PAVFormatContext;
  protected
    property PostHooks: TPostHooks read FPostHooks write SetPostHooks;
{$IFNDEF FFFMX}
    property VideoHookBitsPixel: Integer read GetVideoHookBitsPixel write SetVideoHookBitsPixel;
{$ENDIF}

    property OnPreviewBitmap: TPreviewBitmapEvent read FOnPreviewBitmap write FOnPreviewBitmap;
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    property OnTerminate: TNotifyEvent read FOnTerminate write FOnTerminate;
    property OnInputAudioHook: TAudioHookEvent read FOnInputAudioHook write FOnInputAudioHook;
    property OnOutputAudioHook: TAudioHookEvent read FOnOutputAudioHook write FOnOutputAudioHook;
    property OnInputVideoHook: TVideoHookEvent read FOnInputVideoHook write FOnInputVideoHook;
    property OnOutputVideoHook: TVideoHookEvent read FOnOutputVideoHook write FOnOutputVideoHook;
    property OnInputFrameHook: TFrameHookEvent read FOnInputFrameHook write FOnInputFrameHook;
    property OnOutputFrameHook: TFrameHookEvent read FOnOutputFrameHook write FOnOutputFrameHook;
  public
    constructor Create; override;
    destructor Destroy; override;

    function StartConvert(const AUseThread: Boolean; const APriority: TThreadPriority): TThread;
    procedure Stop(const AWaitForStop: Boolean);
    procedure Pause;
    procedure Resume;

    property Converting: Boolean read FConverting;
    property Finished: Boolean read FFinished;
    property FatalException: Boolean read FFatalException;
    property FatalMessage: string read FFatalMessage;
    property Terminated: Boolean read FTerminated;
  end;

implementation

uses
  FFLoad,
  FFLog;

var
  GHookLock: TCriticalSection;
  GCodecLock: TCriticalSection;

{$IFDEF NEED_IDE}
  {$I Z_INIDE.inc}
{$ENDIF}

function PtrIdx(P: PPAVFormatContext; I: Integer): PPAVFormatContext; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := P;
  Inc(Result, I);
end;

type
  PCodecItem = ^TCodecItem;
  TCodecItem = record
    st: Pointer;
    Prev: PCodecItem;
    Next: PCodecItem;
  end;

procedure AddCodecList(var ACodecList: Pointer{PCodecItem}; const st: Pointer);
var
  P: PCodecItem;
begin
  GCodecLock.Acquire;
  try
    New(P);
    P.st := st;
    P.Prev := nil;
    P.Next := ACodecList;
    ACodecList := P;
    if P.Next <> nil then
      P.Next.Prev := P;
  finally
    GCodecLock.Release;
  end;
end;

procedure RemoveCodecList(var ACodecList: Pointer{PCodecItem}; const st: Pointer);
var
  P: PCodecItem;
begin
  GCodecLock.Acquire;
  try
    P := ACodecList;
    while (P <> nil) and (P.st <> st) do
      P := P.Next;
    if P <> nil then
    begin
      if P.Prev <> nil then
        P.Prev.Next := P.Next;
      if P.Next <> nil then
        P.Next.Prev := P.Prev;
      if P = ACodecList then
        ACodecList := P.Next;
      Dispose(P);
    end;
  finally
    GCodecLock.Release;
  end;
end;

procedure EnsureCloseEncoders(var AEncoderList: Pointer{PCodecItem});
var
  P: PCodecItem;
  H: PCodecItem;
  ost: POutputStream;
begin
  GCodecLock.Acquire;
  try
    P := AEncoderList;
    while P <> nil do
    begin
      ost := P.st;
      if ost.encoding_needed <> 0 then
      begin
        av_freep(@ost.st.codec.stats_in);
        avcodec_close(ost.st.codec);
        ost.is_avcodec_closed := 1;
      end;
      H := P;
      P := P.Next;
      Dispose(H);
    end;
    AEncoderList := nil;
  finally
    GCodecLock.Release;
  end;
end;

procedure EnsureCloseDecoders(var ADecoderList: Pointer{PCodecItem});
var
  P: PCodecItem;
  H: PCodecItem;
  ist: PInputStream;
begin
  GCodecLock.Acquire;
  try
    P := ADecoderList;
    while P <> nil do
    begin
      ist := P.st;
      if ist.decoding_needed <> 0 then
        avcodec_close(ist.st.codec);
      H := P;
      P := P.Next;
      Dispose(H);
    end;
    ADecoderList := nil;
  finally
    GCodecLock.Release;
  end;
end;

procedure ResetPostHostContext(P: PPostHookContext);
begin
  with P^ do
  begin
    if Assigned(Previewer) then
      FreeAndNil(Previewer);
    preview_last_time := 0;
    preview_cur_time := 0;
  end;
end;

{ TConvertThread }

constructor TConvertThread.Create(AOwner: TCustomFFmpeg; APriority: TThreadPriority);
begin
  inherited Create(True);
  FreeOnTerminate := True;
{$IFDEF MSWINDOWS}
  Priority := APriority;
{$ENDIF}
  FOwner := AOwner;
end;

destructor TConvertThread.Destroy;
begin
  inherited Destroy;
end;

procedure TConvertThread.Execute;
begin
  if Assigned(FOwner) then
  begin
    FOwner.FStopEvent.ResetEvent;
    try
      FOwner.DoConvert;
    finally
      FOwner.FStopEvent.SetEvent;
    end;
  end;
end;

{ TDoTerminateThread }

constructor TDoTerminateThread.Create(AOwner: TCustomFFmpeg);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FOwner := AOwner;
end;

destructor TDoTerminateThread.Destroy;
begin
  inherited Destroy;
end;

procedure TDoTerminateThread.Execute;
begin
  if Assigned(FOwner) then
  begin
    FOwner.FTermEvent.ResetEvent;
    try
      FOwner.DoTerminate;
    finally
      FOwner.FTermEvent.SetEvent;
    end;
  end;
end;

{ TCustomFFmpeg }

constructor TCustomFFmpeg.Create;
begin
  inherited Create;

  Assert(FFLoader.Loaded(CEncoderLibraries));

  Fvstats_file := nil; // FILE *

  //Frun_as_daemon := 0;
  Fvideo_size := 0;
  Faudio_size := 0;
  Fsubtitle_size := 0;
  Fextra_size := 0;
  Fnb_frames_dup := 0;
  Fnb_frames_drop := 0;
  Fdecode_error_stat[False] := 0;
  Fdecode_error_stat[True] := 0;

  Fprogress_avio := nil;

  Fsubtitle_out := nil;

  Finput_streams := nil;
  Fnb_input_streams := 0;
  Finput_files := nil;
  Fnb_input_files := 0;

  Foutput_streams := nil;
  Fnb_output_streams := 0;
  Foutput_files := nil;
  Fnb_output_files := 0;

  Flast_time := -1;
  FillChar(Fqp_histogram[0], SizeOf(Fqp_histogram), 1);

  Fusing_vhook := False;
  FShowDupOrDrop := False;

  FEncoderList := nil;
  FDecoderList := nil;
  FThread := nil;

{$IFDEF MSWINDOWS}
  FFirstHook := nil;
{$ENDIF}
  FInputPictureBuf := nil;
  FInputPictureBufSize := 0;

  FOutputPictureBuf := nil;
  FOutputPictureBufSize := 0;
  ResetPostHostContext(@FOutputVideoHook);
  FPostHooks := [];
  FPostHooksChanged := False;

  FConverting := False;
  FBroken := False;
  FFinished := False;
  FTerminated := False;
  FTranscodeInitialized := False;
  FTranscodeCleanuped := False;

  FFatalException := False;
  FFatalMessage := '';
  FInputDuration := -1;
  FOutputDuration := -1;
  FLastErrMsg := '';

  FLastRead := High(Int64);
  FLastWrite := High(Int64);

  FStopEvent := TEvent.Create(nil, True, True, '');
  FTermEvent := TEvent.Create(nil, True, True, '');

  FInputVideoHook := TFormatConverter.Create;
  FOutputVideoHook.Converter := TFormatConverter.Create;

  ReportInterval := CReportInterval * 1000;
  PreviewInterval := CPreviewInterval * 1000;

{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
  Fyuv45 := 1;
{$IFEND}
end;

destructor TCustomFFmpeg.Destroy;
begin
  Stop(True);
  Finalize;

  FInputVideoHook.Free;
  FOutputVideoHook.Converter.Free;

  FStopEvent.Free;
  FTermEvent.Free;

  inherited Destroy;
end;

procedure TCustomFFmpeg.Stop(const AWaitForStop: Boolean);
begin
  FBroken := True;
  if Assigned(FThread) then
  begin
    if FThread.Suspended then
{$WARN SYMBOL_DEPRECATED OFF}
      FThread.Resume;
{$WARN SYMBOL_DEPRECATED ON}
    if AWaitForStop then
      while FStopEvent.WaitFor(20) = wrTimeout do
      begin
{$IFDEF MSWINDOWS}
        if GetCurrentThreadID = MainThreadID then
{$ENDIF}
{$IFDEF POSIX}
        if TThread.CurrentThread.ThreadID = MainThreadID then
{$ENDIF}
        begin
          CheckSynchronize;
          MyProcessMessages;
        end;
      end;
  end;
end;

procedure TCustomFFmpeg.StopAndDoTerminate(const AWaitForStop: Boolean);
begin
  if FConverting then
    Stop(AWaitForStop)
  else if not FTerminated then
  begin
    TDoTerminateThread.Create(Self);
    if AWaitForStop then
      FTermEvent.WaitFor(INFINITE); // FTermEvent.Acquire;
  end;
end;

procedure TCustomFFmpeg.Pause;
begin
  if Assigned(FThread) and not FThread.Suspended then
  begin
    FPauseTime := av_gettime();
{$WARN SYMBOL_DEPRECATED OFF}
    FThread.Suspend;
{$WARN SYMBOL_DEPRECATED ON}
  end;
end;

procedure TCustomFFmpeg.Resume;
begin
  if Assigned(FThread) and FThread.Suspended then
  begin
    Inc(FTotalPauseTime, av_gettime() - FPauseTime);
{$WARN SYMBOL_DEPRECATED OFF}
    FThread.Resume
{$WARN SYMBOL_DEPRECATED ON}
  end;
end;

procedure TCustomFFmpeg.DoConvert;
begin
  try
    FFinished := False;
    try
      if do_transcode_init then
        transcode()
      else
        raise Exception.Create(FLastErrMsg);
    except on E: Exception do
      begin
        FFLogger.Log(Self, llQuiet, E.Message);
        // becuase exception cannot be caught in thread, so we should handle exception manually
        FFatalException := True;
        FFatalMessage := E.Message;
      end;
    end;
  finally
    try
      EnsureCloseEncoders(FEncoderList);
    except on E: Exception do
      begin
        FFLogger.Log(Self, llQuiet, E.Message);
        // becuase exception cannot be caught in thread, so we should handle exception manually
        FFatalException := True;
        FFatalMessage := E.Message;
      end;
    end;
    try
      EnsureCloseDecoders(FDecoderList);
    except on E: Exception do
      begin
        FFLogger.Log(Self, llQuiet, E.Message);
        // becuase exception cannot be caught in thread, so we should handle exception manually
        FFatalException := True;
        FFatalMessage := E.Message;
      end;
    end;
    try
      Finalize;
    except on E: Exception do
      begin
        FFLogger.Log(Self, llQuiet, E.Message);
        // becuase exception cannot be caught in thread, so we should handle exception manually
        FFatalException := True;
        FFatalMessage := E.Message;
      end;
    end;
    try
      DoTerminate;
    except on E: Exception do
      begin
        FFLogger.Log(Self, llQuiet, E.Message);
        // becuase exception cannot be caught in thread, so we should handle exception manually
        FFatalException := True;
        FFatalMessage := E.Message;
      end;
    end;
    av_log(nil, AV_LOG_QUIET, '%s', '');
  end;
end;

procedure TCustomFFmpeg.DoTerminate;
begin
  FConverting := False;
  FTerminated := True;

  FThread := nil;
  if Assigned(FOnTerminate) then
    FOnTerminate(Self);
end;

function TCustomFFmpeg.StartConvert(const AUseThread: Boolean;
  const APriority: TThreadPriority): TThread;
begin
  Result := nil;

  if FConverting or FTerminated then
    Exit;

  try
    if Fnb_output_files <= 0 then
    begin
      Finalize; // Cleanup
      raise FFmpegException.Create('At least one output file must be specified');
    end;

    if Fnb_input_files = 0 then
    begin
      Finalize; // Cleanup
      raise FFmpegException.Create('At least one input file must be specified');
    end;

{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
    Fyuv01 := 1;
{$IFEND}

{$IFDEF NEED_IDE}
    if not ISDP{INIDE} then
    begin
  {$IFDEF NEED_YUV}
      Fyuv01 := 0;
  {$ELSE}
      Finalize; // Cleanup
      raise FFmpegException.Create(CDemoOnly);
  {$ENDIF}
    end;
    if not PNGF{INIDE1} then
    begin
  {$IFDEF NEED_YUV}
      Fyuv01 := 0;
  {$ELSE}
      Finalize; // Cleanup
      DoTerminate;
      Exit;
  {$ENDIF}
    end;
{$ENDIF}
  except on E: Exception do
    begin
      FFLogger.Log(Self, llQuiet, E.Message);
      // becuase exception cannot be caught in thread, so we should handle exception manually
      FFatalException := True;
      FFatalMessage := E.Message;
      DoTerminate;
      Exit;
    end;
  end;

{$IFDEF NEED_KEY}
  _CK3(FLic);
{$ENDIF}

  FConverting := True;
  FBroken := False;
  FFinished := False;
  FTerminated := False;

  if AUseThread then
  begin
    FPauseTime := 0;
    FTotalPauseTime := 0;
    FThread := TConvertThread.Create(Self, APriority);
    Result := FThread;
  end
  else
  begin
    DoConvert;
    Result := nil;
  end;
end;

procedure TCustomFFmpeg._SetPostHooks(const AValue: TPostHooks);
begin
  if FPostHooks <> AValue then
  begin
    if (phPreview in FPostHooks) and not (phPreview in AValue) then
    begin
      with FOutputVideoHook do
        if Assigned(Previewer) then
        begin
          Previewer.Free;
          Previewer := nil;
        end;
    end;
    // TODO: other post hooks
    FPostHooks := AValue;
  end;
end;

procedure TCustomFFmpeg.SetPostHooks(const AValue: TPostHooks);
begin
  GHookLock.Acquire;
  try
    _SetPostHooks(AValue);
    FPostHooksChanged := True;
  finally
    GHookLock.Release;
  end;
end;

{$IFNDEF FFFMX}
function TCustomFFmpeg.GetVideoHookBitsPixel: Integer;
begin
  Assert(FInputVideoHook.BitsPixel = FOutputVideoHook.Converter.BitsPixel);
  Result := FInputVideoHook.BitsPixel;
end;

procedure TCustomFFmpeg.SetVideoHookBitsPixel(const AValue: Integer);
begin
  FInputVideoHook.BitsPixel := AValue;
  FOutputVideoHook.Converter.BitsPixel := AValue;
end;
{$ENDIF}

function TCustomFFmpeg.Get_input_files(Index: Integer): PAVFormatContext;
begin
  Result := PPtrIdx(Finput_files, Index).ctx;
end;

function TCustomFFmpeg.Get_output_files(Index: Integer): PAVFormatContext;
begin
  Result := PPtrIdx(Foutput_files, Index).ctx;
end;

procedure TCustomFFmpeg.Finalize;
begin
  Assert(FFLoader.Loaded(CEncoderLibraries));

  if FTranscodeInitialized and not FTranscodeCleanuped then
    transcode_cleanup;

  ffmpeg_cleanup();

{$IFDEF MSWINDOWS}
  if Assigned(FFirstHook) then
  begin
    frame_hook_release(FFirstHook);
    FFirstHook := nil;
  end;
{$ENDIF}

  av_freep(@FInputPictureBuf);
  av_freep(@FOutputPictureBuf);

  ResetPostHostContext(@FOutputVideoHook);
end;

(* sub2video hack:
   Convert subtitles to video with alpha to insert them in filter graphs.
   This is a temporary solution until libavfilter gets real subtitles support.
 *)

function sub2video_get_blank_frame(ist: PInputStream): Integer;
var
  ret: Integer;
  frame: PAVFrame;
begin
  frame := ist.sub2video.frame;

  av_frame_unref(frame);
  ist.sub2video.frame.width  := ist.sub2video.w;
  ist.sub2video.frame.height := ist.sub2video.h;
  ist.sub2video.frame.format := Ord(AV_PIX_FMT_RGB32);
  ret := av_frame_get_buffer(frame, 32);
  if ret < 0 then
    Result := ret
  else
  begin
    FillChar(frame.data[0]^, frame.height * frame.linesize[0], 0);
    Result := 0;
  end;
end;

procedure sub2video_copy_rect(dst: PByte; dst_linesize, w, h: Integer; r: PAVSubtitleRect);
var
  pal, dst2: PCardinal;
  src, src2: PByte;
  x, y: Integer;
begin
  if r.ttype <> SUBTITLE_BITMAP then
  begin
    FFLogger.Log(nil, llWarning, 'sub2video: non-bitmap subtitle');
    Exit;
  end;
  if (r.x < 0) or (r.x + r.w > w) or (r.y < 0) or (r.y + r.h > h) then
  begin
    FFLogger.Log(nil, llWarning, 'sub2video: rectangle overflowing');
    Exit;
  end;

  Inc(dst, r.y * dst_linesize + r.x * 4);
  src := r.pict.data[0];
  pal := PCardinal(r.pict.data[1]);
  for y := 0 to r.h - 1 do
  begin
    dst2 := PCardinal(dst);
    src2 := src;
    for x := 0 to r.w - 1 do
    begin
      //*(dst2++) = pal[*(src2++)];
      dst2^ := PPtrIdx(pal, src2^);
      Inc(dst2, 2);
      Inc(src2, 2);
    end;
    Inc(dst, dst_linesize);
    Inc(src, r.pict.linesize[0]);
  end;
end;

procedure sub2video_push_ref(ist: PInputStream; pts: Int64);
var
  frame: PAVFrame;
  i: Integer;
begin
  frame := ist.sub2video.frame;

  Assert(Assigned(frame.data[0]));
  ist.sub2video.last_pts := pts;
  frame.pts := pts;
  for i := 0 to ist.nb_filters - 1 do
    av_buffersrc_add_frame_flags(PPtrIdx(ist.filters, i).filter, frame,
                                 AV_BUFFERSRC_FLAG_KEEP_REF or
                                 AV_BUFFERSRC_FLAG_PUSH);
end;

procedure sub2video_update(ist: PInputStream; sub: PAVSubtitle);
var
  w, h: Integer;
  frame: PAVFrame;
  dst: PByte;
  dst_linesize: Integer;
  num_rects, i: Integer;
  pts, end_pts: Int64;
begin
  w := ist.sub2video.w;
  h := ist.sub2video.h;
  frame := ist.sub2video.frame;

  if not Assigned(frame) then
    Exit;

  if Assigned(sub) then
  begin
    pts       := av_rescale_q(sub.pts + sub.start_display_time * 1000,
                              AV_TIME_BASE_Q, ist.st.time_base);
    end_pts   := av_rescale_q(sub.pts + sub.end_display_time   * 1000,
                              AV_TIME_BASE_Q, ist.st.time_base);
    num_rects := sub.num_rects;
  end
  else
  begin
    pts       := ist.sub2video.end_pts;
    end_pts   := High(Int64);
    num_rects := 0;
  end;

  if sub2video_get_blank_frame(ist) < 0 then
  begin
    av_log(ist.st.codec, AV_LOG_ERROR, 'Impossible to get a blank canvas.'#10);
    Exit;
  end;
  dst          := frame.data[0];
  dst_linesize := frame.linesize[0];
  for i := 0 to num_rects - 1 do
    sub2video_copy_rect(dst, dst_linesize, w, h, PPtrIdx(sub.rects, i));
  sub2video_push_ref(ist, pts);
  ist.sub2video.end_pts := end_pts;
end;

procedure sub2video_heartbeat(input_files: PPInputFile; input_streams: PPInputStream;
  ist: PInputStream; pts: Int64);
var
  infile: PInputFile;
  i, j, nb_reqs: Integer;
  pts2: Int64;
  ist2: PInputStream;
begin
  infile := PPtrIdx(input_files, ist.file_index);

  (* When a frame is read from a file, examine all sub2video streams in
     the same file and send the sub2video frame again. Otherwise, decoded
     video frames could be accumulating in the filter graph while a filter
     (possibly overlay) is desperately waiting for a subtitle frame. *)
  for i := 0 to infile.nb_streams - 1 do
  begin
    ist2 := PPtrIdx(input_streams, infile.ist_index + i);
    if not Assigned(ist2.sub2video.frame) then
      Continue;
    (* subtitles seem to be usually muxed ahead of other streams;
       if not, substracting a larger time here is necessary *)
    pts2 := av_rescale_q(pts, ist.st.time_base, ist2.st.time_base) - 1;
    (* do not send the heartbeat frame if the subtitle is already ahead *)
    if pts2 <= ist2.sub2video.last_pts then
      Continue;
    if (pts2 >= ist2.sub2video.end_pts) or not Assigned(ist2.sub2video.frame.data[0]) then
      sub2video_update(ist2, nil);
    nb_reqs := 0;
    for j := 0 to ist2.nb_filters - 1 do
      Inc(nb_reqs, av_buffersrc_get_nb_failed_requests(PPtrIdx(ist2.filters, j).filter));
    if nb_reqs <> 0 then
      sub2video_push_ref(ist2, pts2);
  end;
end;

procedure sub2video_flush(ist: PInputStream);
var
  i: Integer;
begin
  for i := 0 to ist.nb_filters - 1 do
    av_buffersrc_add_ref(PPtrIdx(ist.filters, i).filter, nil, 0);
end;

(* end of sub2video hack *)

procedure TCustomFFmpeg.ffmpeg_cleanup();
var
  i, j: Integer;
  s: PAVFormatContext;
  ist: PInputStream;
  ost: POutputStream;
begin
(*
  if (do_benchmark) {
      int maxrss = getmaxrss() / 1024;
      printf("bench: maxrss=%ikB\n", maxrss);
  }
*)
  for i := 0 to Fnb_filtergraphs - 1 do
  begin
    avfilter_graph_free(@PAVFilterGraph(PPtrIdx(Ffiltergraphs, i).graph));
    for j := 0 to PPtrIdx(Ffiltergraphs, i).nb_inputs - 1 do
    begin
      av_freep(@PByte(PPtrIdx(PPtrIdx(Ffiltergraphs, i).inputs, j).name));
      av_freep(@PInputFilter(PtrIdx(PPtrIdx(Ffiltergraphs, i).inputs, j)^));
    end;
    av_freep(@PPInputFilter(PPtrIdx(Ffiltergraphs, i).inputs));
    for j := 0 to PPtrIdx(Ffiltergraphs, i).nb_outputs - 1 do
    begin
      av_freep(@PByte(PPtrIdx(PPtrIdx(Ffiltergraphs, i).outputs, j).name));
      av_freep(@POutputFilter(PtrIdx(PPtrIdx(Ffiltergraphs, i).outputs, j)^));
    end;
    av_freep(@POutputFilter(PPtrIdx(Ffiltergraphs, i).outputs));
    av_freep(@PPtrIdx(Ffiltergraphs, i).graph_desc);
    av_freep(@PFilterGraph(PtrIdx(Ffiltergraphs, i)^));
  end;
  av_freep(@Ffiltergraphs);
  Fnb_filtergraphs := 0; // hack: reset

  av_freep(@Fsubtitle_out);

  // hack: fix memory leak
  for i := 0 to Fnb_output_streams - 1 do
  begin
    if FJoinMode and (i >= Fnb_output_streams_join) then
      Break;
    ost := PPtrIdx(Foutput_streams, i);
    // after filter_codec_opts() without avcodec_open2()
    if (ost.is_filter_codec_opts <> 0) and (ost.is_avcodec_opened = 0) then
      av_dict_free(@ost.opts);
    // after avcodec_get_context_defaults3() without avcodec_open2()
    if (ost.is_avcodec_get_context_defaults <> 0) and (ost.is_avcodec_opened = 0) then
      if Assigned(ost.st.codec.priv_data) and Assigned(ost.enc) and Assigned(ost.enc.priv_class) then
        av_opt_free(ost.st.codec.priv_data);
    // after avcodec_get_context_defaults3() without avcodec_close()
    if (ost.is_avcodec_get_context_defaults <> 0) and (ost.is_avcodec_closed = 0) then
      avcodec_close(ost.st.codec);
  end;
  // hack end

  (* close files *)
  for i := 0 to Fnb_output_files - 1 do
  begin
    s := PPtrIdx(Foutput_files, i).ctx;
    if Assigned(s) then
    begin
      if Assigned(s.oformat) and ((s.oformat.flags and AVFMT_NOFILE) = 0) and Assigned(s.pb) then
        avio_close(s.pb);
      // hack: remove zero file
      if ((s.oformat.flags and AVFMT_NOFILE) = 0) and
        (MyUtils.GetFileSize(delphi_filename(s.filename)) = 0) then
{$IFDEF VCL_XE2_OR_ABOVE}
        System.SysUtils.DeleteFile(delphi_filename(s.filename));
{$ELSE}
        SysUtils.DeleteFile(delphi_filename(s.filename));
{$ENDIF}
      // hack end
    end;
    avformat_free_context(s);
    av_dict_free(@PAVDictionary(PPtrIdx(Foutput_files, i).opts));
    av_freep(@POutputFile(PtrIdx(Foutput_files, i)^));
    if FJoinMode then
    begin
      for j := 1 to Fnb_output_files - 1 do
        av_freep(@POutputFile(PtrIdx(Foutput_files, j)^));
      Break;
    end;
  end;
  Fnb_output_files := 0; // hack: reset
  FreeOutputStreams(); // hack: move to FreeOutputStreams()
  for i := 0 to Fnb_input_files - 1 do
  begin
    avformat_close_input(@PAVFormatContext(PPtrIdx(Finput_files, i).ctx));
    av_freep(@PInputFile(PtrIdx(Finput_files, i)^));
  end ;
  Fnb_input_files := 0; // hack: reset
  for i := 0 to Fnb_input_streams - 1 do
  begin
    ist := PPtrIdx(Finput_streams, i);
    // hack: for join mode
    if ist.stream_freed = 1 then
    begin
      av_freep(@PInputStream(PtrIdx(Finput_streams, i)^));
      Continue;
    end;
    ist.stream_freed := 1;
    // hack end
    av_frame_free(@ist.decoded_frame);
    av_frame_free(@ist.filter_frame);
    av_dict_free(@PAVDictionary(ist.opts));
    avsubtitle_free(@ist.prev_sub.subtitle);
    av_frame_free(@ist.sub2video.frame);
    av_freep(@PPInputFilter(ist.filters));
    av_freep(@PInputStream(PtrIdx(Finput_streams, i)^));
  end;
  Fnb_input_streams := 0; // hack: reset

  if Assigned(Fvstats_file) then
    my_fclose(Fvstats_file);
  Fvstats_file := nil; // hack: reset
  av_free(Fvstats_filename);

  av_freep(@Finput_streams);
  av_freep(@Finput_files);
  av_freep(@Foutput_streams);
  av_freep(@Foutput_files);

(*
  avformat_network_deinit();

  if (received_sigterm) {
      av_log(NULL, AV_LOG_INFO, "Received signal %d: terminating.\n",
             (int) received_sigterm);
  }
  term_exit();
*)
end;

(*
procedure update_benchmark(const ALogMsg: string); overload;
begin
  if (do_benchmark_all) then
  begin
      int64_t t = getutime();
      va_list va;
      char buf[1024];

      if (fmt) then
      begin
          va_start(va, fmt);
          vsnprintf(buf, sizeof(buf), fmt, va);
          va_end(va);
          // #define PRIu64 "llu"
          printf("bench: %8"PRIu64" %s \n", t - current_time, buf);
      end;
      current_time = t;
  end;
end;

procedure update_benchmark(); overload;
begin
  update_benchmark('');
end;

procedure update_benchmark(const AFormat: string; const Args: array of const); overload;
begin
  update_benchmark(Format(AFormat, Args));
end;
*)

procedure TCustomFFmpeg.write_frame(s: PAVFormatContext; pkt: PAVPacket; ost: POutputStream);
var
  bsfc: PAVBitStreamFilterContext;
  avctx: PAVCodecContext;
  ret: Integer;
  max: Int64;
  loglevel: Integer;
  new_pkt: TAVPacket;
  a: Integer;
  t: PByte;
  name: string;
  error: string;
{$IF Defined(VCL_60) Or Defined(VCL_70)}
  I64: Int64;
  LoLastDTS, HiLastDTS: Integer;
  LoDTS, HiDTS: Integer;
{$IFEND}
begin
  bsfc := ost.bitstream_filters;
  avctx := ost.st.codec;

  if ((avctx.codec_type = AVMEDIA_TYPE_VIDEO) and (Fvideo_sync_method = VSYNC_DROP)) or
     ((avctx.codec_type = AVMEDIA_TYPE_AUDIO) and (Faudio_sync_method < 0)) then
  begin
    pkt.pts := AV_NOPTS_VALUE;
    pkt.dts := AV_NOPTS_VALUE;
  end;

  (*
   * Audio encoders may split the packets --  #frames in != #packets out.
   * But there is no reordering, so we can limit the number of output packets
   * by simply dropping them here.
   * Counting encoded video frames needs to be done separately because of
   * reordering, see do_video_out()
   *)
  //if not ((avctx.codec_type = AVMEDIA_TYPE_VIDEO) and Assigned(avctx.codec)) then
  if (avctx.codec_type <> AVMEDIA_TYPE_VIDEO) or not Assigned(avctx.codec) then
  begin
    if ost.frame_number >= ost.max_frames then
    begin
      av_free_packet(pkt);
      Exit;
    end;
    Inc(ost.frame_number);
  end;

  while Assigned(bsfc) do
  begin
    new_pkt := pkt^;
    a := av_bitstream_filter_filter(bsfc, avctx, nil,
                                    @new_pkt.data, @new_pkt.size,
                                    pkt.data, pkt.size,
                                    pkt.flags and AV_PKT_FLAG_KEY);
    if (a = 0) and (new_pkt.data <> pkt.data) and Assigned(new_pkt.destruct) then
    begin
      t := av_malloc(new_pkt.size + FF_INPUT_BUFFER_PADDING_SIZE); //the new should be a subset of the old so cannot overflow
      if Assigned(t) then
      begin
        Move(new_pkt.data^, t^, new_pkt.size);
        FillChar(PByte(PAnsiChar(t) + new_pkt.size)^, FF_INPUT_BUFFER_PADDING_SIZE, 0);
        new_pkt.data := t;
        new_pkt.buf := nil;
        a := 1;
      end
      else
        a := AVERROR_ENOMEM;
    end;
    if a > 0 then
    begin
      av_free_packet(pkt);
      new_pkt.buf := av_buffer_create(new_pkt.data, new_pkt.size,
                                      av_buffer_default_free, nil, 0);
      if not Assigned(new_pkt.buf) then
      begin
        RaiseException('av_buffer_create() failed');
        //exit_program(1);
      end;
    end
    else if a < 0 then
    begin
      if Assigned(avctx.codec) then
        name := string(avctx.codec.name)
      else
        name := 'copy';
      error := Format('Failed to open bitstream filter %s for stream %d with codec %s',
                      [bsfc.filter.name, pkt.stream_index, name]);
      error := print_error(error, a);
      if Fexit_on_error <> 0 then
        RaiseException(error) //exit_program(1)
      else
        FFLogger.Log(Self, llError, error);
    end;
    pkt^ := new_pkt;

    bsfc := bsfc.next;
  end;

  if ((s.oformat.flags and AVFMT_NOTIMESTAMPS) = 0) and
    ((avctx.codec_type = AVMEDIA_TYPE_AUDIO) or (avctx.codec_type = AVMEDIA_TYPE_VIDEO)) and
    (pkt.dts <> AV_NOPTS_VALUE) and
    (ost.last_mux_dts <> AV_NOPTS_VALUE) then
  begin
    max := ost.last_mux_dts + Ord((s.oformat.flags and AVFMT_TS_NONSTRICT) = 0);
    if pkt.dts < max then
    begin
      if (max - pkt.dts > 2) or (avctx.codec_type = AVMEDIA_TYPE_VIDEO) then
        loglevel := AV_LOG_WARNING
      else
        loglevel := AV_LOG_DEBUG;
{$IF Defined(VCL_60) Or Defined(VCL_70)}
      // Int64Rec on non-local variables will cause Internal error(URW699) in Delphi 6
      I64 := ost.last_mux_dts;
      LoLastDTS := Int64Rec(I64).Lo;
      HiLastDTS := Int64Rec(I64).Hi;
      I64 := pkt.dts;
      LoDTS := Int64Rec(I64).Lo;
      HiDTS := Int64Rec(I64).Hi;
{$IFEND}
      // #define PRId64 "lld"
      av_log(s, loglevel, 'Non-monotonous DTS in output stream ' +
{$IFDEF MSWINDOWS}
              // '%lld/%llx' works on Vista or above, '%I64d/%I64x' works always
              '%d:%d; previous: %I64d, current: %I64d; ',
{$ELSE}
              '%d:%d; previous: %lld, current: %lld; ',
{$ENDIF}
              ost.file_index, ost.st.index,
{$IF Defined(VCL_60) Or Defined(VCL_70)}
              // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
              // Int64 and Single are incorrectly passed to cdecl/varargs functions
              LoLastDTS, HiLastDTS, LoDTS, HiDTS);
{$ELSE}
              ost.last_mux_dts, pkt.dts);
{$IFEND}
      if Fexit_on_error <> 0 then
      begin
        av_log(nil, AV_LOG_FATAL, 'aborting.'#10);
        RaiseException('Non-monotonous DTS in output stream %d:%d; previous: %d, current: %d',
          [ost.file_index, ost.st.index, ost.last_mux_dts, pkt.dts]);
        //exit_program(1);
      end;
      // #define PRId64 "lld"
      av_log(s, loglevel,
{$IFDEF MSWINDOWS}
              // '%lld/%llx' works on Vista or above, '%I64d/%I64x' works always
              'changing to %I64d. This may result ' +
{$ELSE}
              'changing to %lld. This may result ' +
{$ENDIF}
              'in incorrect timestamps in the output file.'#10,
{$IF Defined(VCL_60) Or Defined(VCL_70)}
              // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
              // Int64 and Single are incorrectly passed to cdecl/varargs functions
              Int64Rec(max).Lo, Int64Rec(max).Hi);
{$ELSE}
              max);
{$IFEND}
      if pkt.pts >= pkt.dts then
        if pkt.pts < max then
          pkt.pts := max;
      pkt.dts := max;
    end;
  end;
  ost.last_mux_dts := pkt.dts;

  pkt.stream_index := ost.index;

  if Fdebug_ts <> 0 then
    FFLogger.Log(Self, llInfo, 'muxer <- type:%s ' +
                 'pkt_pts:%s pkt_pts_time:%s pkt_dts:%s pkt_dts_time:%s size:%d',
                [av_get_media_type_string(ost.st.codec.codec_type),
                 av_ts2str(pkt.pts), av_ts2timestr(pkt.pts, @ost.st.time_base),
                 av_ts2str(pkt.dts), av_ts2timestr(pkt.dts, @ost.st.time_base),
                 pkt.size]);

  // hack: write timeout
  FLastWrite := av_gettime();
  // hack end
  ret := av_interleaved_write_frame(s, pkt);
  if (ret < 0) and (ret <> AVERROR_EXIT) then
  begin
    RaiseException(print_error('av_interleaved_write_frame()', ret) + '. ' + CHECK_LOG_MSG);
    //exit_program(1);
  end;
end;

procedure TCustomFFmpeg.close_output_stream(ost: POutputStream);
var
  fo: POutputFile;
  end_pts: Int64;
begin
  fo := PPtrIdx(Foutput_files, ost.file_index);

  ost.finished := 1;
  if fo.shortest <> 0 then
  begin
    end_pts := av_rescale_q(ost.sync_opts - ost.first_pts, ost.st.codec.time_base, AV_TIME_BASE_Q);
    if fo.recording_time > end_pts then
      fo.recording_time := end_pts;
  end;
end;

function TCustomFFmpeg.check_recording_time(ost: POutputStream): Integer;
var
  fo: POutputFile;
begin
  fo := PPtrIdx(Foutput_files, ost.file_index);

  if (fo.recording_time <> High(Int64)) and
     (av_compare_ts(ost.sync_opts - ost.first_pts, ost.st.codec.time_base, fo.recording_time,
                    AV_TIME_BASE_Q) >= 0) then
  begin
    close_output_stream(ost);
    Result := 0;
    Exit;
  end;
  Result := 1;
end;

procedure TCustomFFmpeg.do_audio_out(s: PAVFormatContext; ost: POutputStream; frame: PAVFrame);
var
  enc: PAVCodecContext;
  pkt: TAVPacket;
  got_packet: Integer;
  LFramePTS: Int64;
begin
  enc := ost.st.codec;
  got_packet := 0;

  av_init_packet(@pkt);
  pkt.data := nil;
  pkt.size := 0;

  if check_recording_time(ost) <> 1 then
    Exit;

  if (frame.pts = AV_NOPTS_VALUE) or (Faudio_sync_method < 0) then
    frame.pts := ost.sync_opts;
  ost.sync_opts := frame.pts + frame.nb_samples;

  Assert((pkt.size <> 0) or (pkt.data = nil));
  // hack: audio hook
  // TODO: PTS may be not correct
  LFramePTS := av_rescale_q(frame.pts, enc.time_base, AV_TIME_BASE_Q);
  if Assigned(FOnOutputAudioHook) then
    FOnOutputAudioHook(Self, LFramePTS, frame.data[0],
      frame.nb_samples * enc.channels * av_get_bytes_per_sample(enc.sample_fmt),
      enc.sample_rate, enc.channels, enc.sample_fmt);
  // hack end
  //update_benchmark();
  if avcodec_encode_audio2(enc, @pkt, frame, @got_packet) < 0 then
  begin
    RaiseException('Audio encoding failed (avcodec_encode_audio2)');
    //exit_program(1);
  end;
  //update_benchmark('encode_audio %d.%d', [ost.file_index, ost.index]);

  if got_packet <> 0 then
  begin
    if pkt.pts <> AV_NOPTS_VALUE then
    begin
      pkt.pts := av_rescale_q(pkt.pts, enc.time_base, ost.st.time_base);
      // hack: for join mode
      if FJoinMode then
      begin
        if ost.last_pts >= pkt.pts then
          pkt.pts := ost.last_pts + 1;
        ost.last_pts := pkt.pts;
      end;
      // hack end
    end;
    if pkt.dts <> AV_NOPTS_VALUE then
    begin
      pkt.dts := av_rescale_q(pkt.dts, enc.time_base, ost.st.time_base);
      // hack: for join mode
      if FJoinMode then
      begin
        if ost.last_dts >= pkt.dts then
          pkt.dts := ost.last_dts + 1;
        ost.last_dts := pkt.dts;
      end;
      // hack end
    end;
    if pkt.duration > 0 then
      pkt.duration := av_rescale_q(pkt.duration, enc.time_base, ost.st.time_base);

    if Fdebug_ts <> 0 then
      FFLogger.Log(Self, llInfo, 'encoder . type:audio ' +
                   'pkt_pts:%s pkt_pts_time:%s pkt_dts:%s pkt_dts_time:%s',
                  [av_ts2str(pkt.pts), av_ts2timestr(pkt.pts, @ost.st.time_base),
                   av_ts2str(pkt.dts), av_ts2timestr(pkt.dts, @ost.st.time_base)]);

    Inc(Faudio_size, pkt.size);
    write_frame(s, @pkt, ost);

    av_free_packet(@pkt);
  end;
end;

// TODO: always check this function which had been removed in ffmpeg 2.0
procedure TCustomFFmpeg.pre_process_video_frame(ist: PInputStream; picture: PAVPicture);
var
  avdec: PAVCodecContext;
  picture2: PAVPicture;
  picture_tmp: TAVPicture;
  size: Integer;
  pts: Int64;
  LDummy: Boolean;
            procedure TMASM;
            asm
              emms; // maybe a bug missing call emms in function avpicture_deinterlace()
            end;
begin
  Inc(ist.frame_number);  // hack: input frame number
  pts := ist.pts;         // hack: used for frame hook and video hook
  avdec := ist.st.codec;

  (* deinterlace : must be done before any resize *)
  if (Fdo_deinterlace <> 0) or Assigned(FOnInputFrameHook) or Assigned(FOnInputVideoHook) or Fusing_vhook then
  begin
    (* create temporary picture *)
    size := avpicture_get_size(avdec.pix_fmt, avdec.width, avdec.height);
    if size < 0 then
    begin
      FFLogger.Log(Self, llError, 'avpicture_get_size() returns error.');
      Exit;
    end;
    // hack: global buffer
    if not Assigned(FInputPictureBuf) then
    begin
      FInputPictureBuf := av_malloc(size);
      FInputPictureBufSize := size;
    end
    else if size > FInputPictureBufSize then
    begin
      av_free(FInputPictureBuf);
      FInputPictureBuf := av_malloc(size);
      FInputPictureBufSize := size;
    end;
    if not Assigned(FInputPictureBuf) then
    begin
      FFLogger.Log(Self, llError, 'memory malloc error in pre_process_video_frame().');
      Exit;
    end;
    // hack end

    picture2 := @picture_tmp;
    avpicture_fill(picture2, FInputPictureBuf, avdec.pix_fmt, avdec.width, avdec.height);

    if Fdo_deinterlace <> 0 then
    begin
      if avpicture_deinterlace(picture2, picture, avdec.pix_fmt,
                               avdec.width, avdec.height) < 0 then
      begin
        TMASM;
        (* if error, do not deinterlace *)
        FFLogger.Log(Self, llWarning, 'Deinterlacing failed.');
        picture2 := picture;
      end
      else
        TMASM;
    end
    else
      // hack: for video hook
      av_picture_copy(picture2, picture, avdec.pix_fmt, avdec.width, avdec.height);
  end
  else
    picture2 := picture;

  // hack: for video hook
  // TODO: convert to YUV420P?
  if Assigned(FOnInputFrameHook) then
    FOnInputFrameHook(Self, picture2, avdec.pix_fmt, ist.frame_number, avdec.width, avdec.height, pts);

  if Assigned(FOnInputVideoHook) then
    // Do Input Video Hook
    DoVideoHook(FOnInputVideoHook, FInputVideoHook, picture2, avdec, ist.frame_number, pts, LDummy)
{$IFDEF MSWINDOWS}
  else if Fusing_vhook then
    // Do External Video Hook
    frame_hook_process(FFirstHook, picture2, avdec.pix_fmt, avdec.width, avdec.height, pts);
{$ELSE}
    ;
{$ENDIF}
  // hack end

  if picture <> picture2 then
    picture^ := picture2^;
end;

procedure TCustomFFmpeg.do_subtitle_out(s: PAVFormatContext;
  ost: POutputStream; ist: PInputStream; sub: PAVSubtitle);
const
  subtitle_out_max_size = 1024 * 1024;
var
  subtitle_out_size, nb, i: Integer;
  enc: PAVCodecContext;
  pkt: TAVPacket;
  pts: Int64;
begin
  if sub.pts = AV_NOPTS_VALUE then
  begin
    if Fexit_on_error <> 0 then
      RaiseException('Subtitle packets must have a pts') //exit_program(1)
    else
      FFLogger.Log(Self, llError, 'Subtitle packets must have a pts');
    Exit;
  end;

  enc := ost.st.codec;

  if not Assigned(Fsubtitle_out) then
    Fsubtitle_out := av_malloc(subtitle_out_max_size);

  (* Note: DVB subtitle need one packet to draw them and one other packet to clear them *)
  (* XXX: signal it in the codec context ? *)
  if enc.codec_id = AV_CODEC_ID_DVB_SUBTITLE then
    nb := 2
  else
    nb := 1;

  (* shift timestamp to honor -ss and make check_recording_time() work with -t *)
  pts := sub.pts;
  if PPtrIdx(Foutput_files, ost.file_index).start_time <> AV_NOPTS_VALUE then
    Dec(pts, PPtrIdx(Foutput_files, ost.file_index).start_time);
  for i := 0 to nb - 1 do
  begin
    ost.sync_opts := av_rescale_q(pts, AV_TIME_BASE_Q, enc.time_base);
    if check_recording_time(ost) <> 1 then
      Exit;

    sub.pts := pts;
    // start_display_time is required to be 0
    Inc(sub.pts, av_rescale_q(sub.start_display_time, AV_TIME_BASE_SUB, AV_TIME_BASE_Q));
    Dec(sub.end_display_time, sub.start_display_time);
    sub.start_display_time := 0;
    if i = 1 then
      sub.num_rects := 0;
    subtitle_out_size := avcodec_encode_subtitle(enc, Fsubtitle_out,
                                                 subtitle_out_max_size, sub);
    if subtitle_out_size < 0 then
    begin
      RaiseException('Subtitle encoding failed');
      //exit_program(1);
    end;

    av_init_packet(@pkt);
    pkt.data := Fsubtitle_out;
    pkt.size := subtitle_out_size;
    pkt.pts := av_rescale_q(sub.pts, AV_TIME_BASE_Q, ost.st.time_base);
    pkt.duration := av_rescale_q(sub.end_display_time, AV_TIME_BASE_SUB{1, 1000}, ost.st.time_base);
    if enc.codec_id = AV_CODEC_ID_DVB_SUBTITLE then
    begin
      (* XXX: the pts correction is handled here. Maybe handling it in the codec would be better *)
      if i = 0 then
        Inc(pkt.pts, 90 * sub.start_display_time)
      else
        Inc(pkt.pts, 90 * sub.end_display_time);
    end;
    Inc(Fsubtitle_size, pkt.size);
    write_frame(s, @pkt, ost);
  end;
end;

// TODO: refactoring video hook
procedure TCustomFFmpeg.DoVideoHook(var AHookEvent: TVideoHookEvent; ARGBConverter: TFormatConverter;
  picture: PAVPicture; codec: PAVCodecContext; AFrameNumber: Integer;
  const APTS: Int64; var ABitmapReady: Boolean);
var
  LUpdate: Boolean;
  LStopHook: Boolean;
begin
  ABitmapReady := ARGBConverter.PictureToRGB(picture, codec.pix_fmt, codec.width, codec.height{$IFDEF ACTIVEX}, FPostHooks <> []{$ENDIF});
  LStopHook := not ABitmapReady;
  if LStopHook then
  begin
    FFLogger.Log(Self, llError, ARGBConverter.LastErrMsg);
  end
  else
  begin
    // do video hook
    LUpdate := True;
    try
      AHookEvent(Self, {$IFDEF ACTIVEX}ARGBConverter.DIB{$ELSE}ARGBConverter.Bitmap{$ENDIF}, AFrameNumber, APTS, LUpdate, LStopHook);
    except on E: Exception do
      begin
        FFLogger.Log(Self, llError, 'Error occurs VideoHook event: ' + E.Message);
        LUpdate := False;
      end;
    end;

    if LUpdate then
    begin
{$IFDEF ACTIVEX}
      // copy RGB picture to bitmap
      if FPostHooks <> [] then
        ARGBConverter.RGBToBitmap;
{$ELSE}
      // copy bitmap back to RGB picture
      ARGBConverter.BitmapToRGB;
{$ENDIF}

      // transfer RGB picture back to source format
      if ARGBConverter.RGBPictureRef = ARGBConverter.RGBPicture then
      begin
        if not ARGBConverter.RGBToPicture(picture, codec.pix_fmt, codec.width, codec.height) then
        begin
          FFLogger.Log(Self, llError, ARGBConverter.LastErrMsg);
          LStopHook := True;
        end;
      end;
    end
    else if FPostHooks <> [] then
      ABitmapReady := False;
  end;

  if LStopHook then
    AHookEvent := nil;
end;

// TODO: refactoring video hook
procedure TCustomFFmpeg.DoPostHooks(picture: PAVPicture; codec: PAVCodecContext;
  AFrameNumber: Integer; const APTS: Int64; ABitmapReady: Boolean);
var
  LContinue: Boolean;
  LPostHooks: TPostHooks;
begin
  GHookLock.Acquire;
  try
    LPostHooks := FPostHooks;
    if (phBitmap in LPostHooks) and Assigned(FOnPreviewBitmap) then
    begin
      // preview bitmap
      FOutputVideoHook.preview_cur_time := av_gettime;
      if (FOutputVideoHook.preview_cur_time - FOutputVideoHook.preview_last_time) > PreviewInterval then
      begin
        if ABitmapReady and not FPostHooksChanged then
          LContinue := True
        else
          LContinue := FOutputVideoHook.Converter.PictureToRGB(picture, codec.pix_fmt, codec.width, codec.height);
        if LContinue then
          // do preview bitmap event
          FOnPreviewBitmap(Self, FOutputVideoHook.Converter.Bitmap, AFrameNumber, APTS)
        else
          FFLogger.Log(Self, llError, FOutputVideoHook.Converter.LastErrMsg);
        FOutputVideoHook.preview_last_time := FOutputVideoHook.preview_cur_time;
        if not LContinue then
          Exclude(LPostHooks, phBitmap);
      end;
    end
    else if phPreview in LPostHooks then
    begin
      // preview
      FOutputVideoHook.preview_cur_time := av_gettime;
      if (FOutputVideoHook.preview_cur_time - FOutputVideoHook.preview_last_time) > PreviewInterval then
      begin
        if ABitmapReady and not FPostHooksChanged then
          LContinue := True
        else
          LContinue := FOutputVideoHook.Converter.PictureToRGB(picture, codec.pix_fmt, codec.width, codec.height);
        if LContinue then
        begin
          // create previewer
          if not Assigned(FOutputVideoHook.Previewer) then
            FOutputVideoHook.Previewer := TPreviewer.Create;
          // paint preview frame
          LContinue := FOutputVideoHook.Previewer.PaintFrame(FOutputVideoHook.Converter.Bitmap, AFrameNumber, APTS);
        end
        else
          FFLogger.Log(Self, llError, FOutputVideoHook.Converter.LastErrMsg);
        FOutputVideoHook.preview_last_time := FOutputVideoHook.preview_cur_time;
        if not LContinue then
          Exclude(LPostHooks, phPreview);
      end;
    end;
    // TODO: other post hooks
    _SetPostHooks(LPostHooks);
    FPostHooksChanged := False;
  finally
    GHookLock.Release;
  end;
end;

procedure TCustomFFmpeg.do_video_out(s: PAVFormatContext; ost: POutputStream; in_picture: PAVFrame);
var
  LFrameNumber: Integer;
  LFramePTS: Int64;
  LBitmapReady: Boolean;
  procedure _DoVideoHook(picture: PAVPicture; enc: PAVCodecContext);
  var
    avdec: PAVCodecContext;
    picture2: PAVPicture;
    picture_tmp: TAVPicture;
    size: Integer;
  begin
    (* create temporary picture *)
    avdec := ost.st.codec;
    size := avpicture_get_size(avdec.pix_fmt, avdec.width, avdec.height);
    if size < 0 then
    begin
      FFLogger.Log(Self, llError, 'avpicture_get_size() returns error.');
      Exit;
    end;
    if not Assigned(FOutputPictureBuf) then
    begin
      FOutputPictureBuf := av_malloc(size);
      FOutputPictureBufSize := size;
    end
    else if size > FOutputPictureBufSize then
    begin
      av_free(FOutputPictureBuf);
      FOutputPictureBuf := av_malloc(size);
      FOutputPictureBufSize := size;
    end;
    if not Assigned(FOutputPictureBuf) then
    begin
      FFLogger.Log(Self, llError, 'hook buf malloc error.');
      Exit;
    end;

    picture2 := @picture_tmp;
    avpicture_fill(picture2, FOutputPictureBuf, avdec.pix_fmt, avdec.width, avdec.height);

    av_picture_copy(picture2, picture, avdec.pix_fmt, avdec.width, avdec.height);

    if Assigned(FOnOutputVideoHook) then
      DoVideoHook(FOnOutputVideoHook, FOutputVideoHook.Converter,
        picture2, enc, LFrameNumber, LFramePTS, LBitmapReady)
    else
      LBitmapReady := False;

    // TODO: convert to YUV420P?
    if Assigned(FOnOutputFrameHook) then
      FOnOutputFrameHook(Self, picture2, enc.pix_fmt, LFrameNumber, enc.width, enc.height, LFramePTS);

    picture^ := picture2^;
  end;
var
  ret, format_video_sync: Integer;
  pkt: TAVPacket;
  enc: PAVCodecContext;
  nb_frames, i: Integer;
  sync_ipts, delta: Double;
  duration: Double;
  frame_size: Integer;
  ist: PInputStream;
  got_packet: Integer;
  forced_keyframe: Integer;
  pts_time: Double;
  res: Double;
begin
  enc := ost.st.codec;
  duration := 0;
  frame_size := 0;
  ist := nil;
  forced_keyframe := 0;

  if ost.source_index >= 0 then
    ist := PPtrIdx(Finput_streams, ost.source_index);

  if Assigned(ist) and (ist.st.start_time <> AV_NOPTS_VALUE) and (ist.st.first_dts <> AV_NOPTS_VALUE) and (ost.frame_rate.num <> 0) then
    duration := 1 / (av_q2d(ost.frame_rate) * av_q2d(enc.time_base));

  format_video_sync := Fvideo_sync_method;
  if format_video_sync = VSYNC_AUTO then
  begin
    if (s.oformat.flags and AVFMT_VARIABLE_FPS) <> 0 then
    begin
      if (s.oformat.flags and AVFMT_NOTIMESTAMPS) <> 0 then
        format_video_sync := VSYNC_PASSTHROUGH
      else
        format_video_sync := VSYNC_VFR;
    end
    else
      format_video_sync := VSYNC_CFR;
    if Assigned(ist) and
      (format_video_sync = VSYNC_CFR) and
      (PPtrIdx(Finput_files, ist.file_index).ctx.nb_streams = 1) and
      (PPtrIdx(Finput_files, ist.file_index).input_ts_offset = 0) then
      format_video_sync := VSYNC_VSCFR;
  end;

  // hack: VSYNC_PASSTHROUGH bug in official ffmpeg?
  if format_video_sync = VSYNC_PASSTHROUGH then
    in_picture.pts := Round((ost.sync_ist.pts - PtrIdx(Foutput_files, ost.file_index)^^.start_time) / AV_TIME_BASE / av_q2d(enc.time_base));
  // hack end

  sync_ipts := in_picture.pts;
  delta := sync_ipts - ost.sync_opts + duration;

  (* by default, we output a single frame *)
  nb_frames := 1;

  // NOTICE: some wrong mpeg-ts maybe cause delta very large!!!
  //    Fvideo_sync_method should be set as VSYNC_VFR/2 to correct the problem!!!
  case format_video_sync of
    VSYNC_VSCFR, VSYNC_CFR:
      begin
        if format_video_sync = VSYNC_VSCFR then
        begin
          if (ost.frame_number = 0) and (delta - duration >= 0.5) then
          begin
            FFLogger.Log(Self, llDebug, 'Not duplicating %d initial frames', [Round{lrintf}(delta - duration)]);
            delta := duration;
            ost.sync_opts := Round{lrint}(sync_ipts);
          end;
        end;
        // FIXME set to 0.5 after we fix some dts/pts bugs like in avidec.c
        if delta < -1.1 then
          nb_frames := 0
        else if delta > 1.1 then
          nb_frames := Round{lrintf}(delta);
      end;
    VSYNC_VFR:
      begin
        if delta <= -0.6 then
          nb_frames := 0
        else if delta > 0.6 then
          ost.sync_opts := Round{lrint}(sync_ipts);
      end;
    VSYNC_DROP, VSYNC_PASSTHROUGH:
        ost.sync_opts := Round{lrint}(sync_ipts);
  else
    raise FFmpegException.Create('Never occur');
  end;

  if nb_frames > ost.max_frames - ost.frame_number then
    nb_frames := ost.max_frames - ost.frame_number;
  if nb_frames = 0 then
  begin
    Inc(Fnb_frames_drop);
    FShowDupOrDrop := True;
    FFLogger.Log(Self, llVerbose, '*** drop!');
    Exit;
  end
  else if nb_frames > 1 then
  begin
    if nb_frames > Fdts_error_threshold * 30 then
    begin
      FFLogger.Log(Self, llError, '%d frame duplication too large, skipping', [nb_frames - 1]);
      Inc(Fnb_frames_drop);
      Exit;
    end;
    Inc(Fnb_frames_dup, nb_frames - 1);
    FShowDupOrDrop := True; // hack
    FFLogger.Log(Self, llVerbose, Format('*** %d dup!', [nb_frames - 1]));
  end;

  (* duplicates frame if needed *)
  for i := 0 to nb_frames - 1 do
  begin
    // hack: some wrong mpeg-ts maybe cause nb_frames very large,
    //       add this code for break encoding.
    if FBroken then
    begin
      if i > 10 then
      begin
        FFLogger.Log(Self, llInfo, 'break in do_video_out()');
        Break;
      end;
    end;
    // hack end
    av_init_packet(@pkt);
    pkt.data := nil;
    pkt.size := 0;

    in_picture.pts := ost.sync_opts;

    if check_recording_time(ost) <> 1 then
    //if ost.frame_number >= ost.max_frames then
      Exit;

    LFrameNumber := ost.frame_number + 1; // hack: output frame number

    if ((s.oformat.flags and AVFMT_RAWPICTURE) <> 0) and
      (enc.codec.id = AV_CODEC_ID_RAWVIDEO) then
    begin
      (* raw pictures are written as AVPicture structure to
         avoid any copies. We support temporarily the older method. *)
      enc.coded_frame.interlaced_frame := in_picture.interlaced_frame;
      enc.coded_frame.top_field_first  := in_picture.top_field_first;
      if enc.coded_frame.interlaced_frame <> 0 then
      begin
        if enc.coded_frame.top_field_first <> 0 then
          enc.field_order := AV_FIELD_TB
        else
          enc.field_order := AV_FIELD_BT;
      end
      else
        enc.field_order := AV_FIELD_PROGRESSIVE;
      pkt.data := PByte(in_picture);
      pkt.size := SizeOf(TAVPicture);
      pkt.pts := av_rescale_q(in_picture.pts, enc.time_base, ost.st.time_base);
      pkt.flags := pkt.flags or AV_PKT_FLAG_KEY;

      // hack: for video hook
      // TODO: PTS may be not correct
      LFramePTS := av_rescale_q(pkt.pts, enc.time_base, AV_TIME_BASE_Q);
      if Assigned(FOnOutputVideoHook) or Assigned(FOnOutputFrameHook) then
        _DoVideoHook(PAVPicture(in_picture), enc)
      else
        LBitmapReady := False;
      if FPostHooks <> [] then
        DoPostHooks(PAVPicture(in_picture), enc, LFrameNumber, LFramePTS, LBitmapReady);
      // hack end

      Inc(Fvideo_size, pkt.size);
      write_frame(s, @pkt, ost);
    end
    else
    begin
      if ((ost.st.codec.flags and (CODEC_FLAG_INTERLACED_DCT or CODEC_FLAG_INTERLACED_ME)) <> 0) and
        (ost.top_field_first >= 0) then
        in_picture.top_field_first := Ord(ost.top_field_first <> 0);{!!ost.top_field_first}

      if in_picture.interlaced_frame <> 0 then
      begin
        if enc.codec.id = AV_CODEC_ID_MJPEG then
        begin
          if in_picture.top_field_first <> 0 then
            enc.field_order := AV_FIELD_TT
          else
            enc.field_order := AV_FIELD_BB;
        end
        else
        begin
          if in_picture.top_field_first <> 0 then
            enc.field_order := AV_FIELD_TB
          else
            enc.field_order := AV_FIELD_BT;
        end;
      end
      else
        enc.field_order := AV_FIELD_PROGRESSIVE;

      in_picture.quality := ost.st.codec.global_quality;
      if enc.me_threshold = 0 then
        in_picture.pict_type := AV_PICTURE_TYPE_NONE;

      if in_picture.pts <> AV_NOPTS_VALUE then
        pts_time := in_picture.pts * av_q2d(enc.time_base)
      else
        pts_time := NaN;
      if (ost.forced_kf_index < ost.forced_kf_count) and
        (in_picture.pts >= PPtrIdx(ost.forced_kf_pts, ost.forced_kf_index)) then
      begin
        Inc(ost.forced_kf_index);
        forced_keyframe := 1;
      end
      else if Assigned(ost.forced_keyframes_pexpr) then
      begin
        ost.forced_keyframes_expr_const_values[FKF_T] := pts_time;
        res := av_expr_eval(ost.forced_keyframes_pexpr,
                           @ost.forced_keyframes_expr_const_values[FKF_N], nil);
        FFLogger.Log(Self, llDebug, 'force_key_frame: n:%f n_forced:%f prev_forced_n:%f t:%f prev_forced_t:%f -> res:%f',
                 [ost.forced_keyframes_expr_const_values[FKF_N],
                  ost.forced_keyframes_expr_const_values[FKF_N_FORCED],
                  ost.forced_keyframes_expr_const_values[FKF_PREV_FORCED_N],
                  ost.forced_keyframes_expr_const_values[FKF_T],
                  ost.forced_keyframes_expr_const_values[FKF_PREV_FORCED_T],
                  res]);
        if res <> 0 then
        begin
          forced_keyframe := 1;
          ost.forced_keyframes_expr_const_values[FKF_PREV_FORCED_N] :=
              ost.forced_keyframes_expr_const_values[FKF_N];
          ost.forced_keyframes_expr_const_values[FKF_PREV_FORCED_T] :=
              ost.forced_keyframes_expr_const_values[FKF_T];
          ost.forced_keyframes_expr_const_values[FKF_N_FORCED] :=
              ost.forced_keyframes_expr_const_values[FKF_N_FORCED] + 1;
        end;

        ost.forced_keyframes_expr_const_values[FKF_N] :=
            ost.forced_keyframes_expr_const_values[FKF_N] + 1;
      end;
      if forced_keyframe <> 0 then
      begin
        in_picture.pict_type := AV_PICTURE_TYPE_I;
        FFLogger.Log(Self, llDebug, 'Forced keyframe at time %f', [pts_time]);
      end;

      //update_benchmark();
      // hack: for video hook
      // TODO: PTS may be not correct
      LFramePTS := av_rescale_q(in_picture.pts, enc.time_base, AV_TIME_BASE_Q);
      if Assigned(FOnOutputVideoHook) or Assigned(FOnOutputFrameHook) then
        _DoVideoHook(PAVPicture(in_picture), enc)
      else
        LBitmapReady := False;
      if FPostHooks <> [] then
        DoPostHooks(PAVPicture(in_picture), enc, LFrameNumber, LFramePTS, LBitmapReady);
      // hack end
      ret := avcodec_encode_video2(enc, @pkt, in_picture, @got_packet);
      //update_benchmark('encode_video %d.%d', [ost.file_index, ost.index]);
      if ret < 0 then
      begin
        RaiseException('Video encoding failed');
        //exit_program(1);
      end;

      if got_packet <> 0 then
      begin
        if (pkt.pts = AV_NOPTS_VALUE) and ((enc.codec.capabilities and CODEC_CAP_DELAY) = 0) then
          pkt.pts := ost.sync_opts;

        if pkt.pts <> AV_NOPTS_VALUE then
        begin
          pkt.pts := av_rescale_q(pkt.pts, enc.time_base, ost.st.time_base);
          // hack: for join mode
          if FJoinMode then
          begin
            if ost.last_pts >= pkt.pts then
              pkt.pts := ost.last_pts + 1;
            ost.last_pts := pkt.pts;
          end;
          // hack end
        end;
        if pkt.dts <> AV_NOPTS_VALUE then
        begin
          pkt.dts := av_rescale_q(pkt.dts, enc.time_base, ost.st.time_base);
          // hack: for join mode
          if FJoinMode then
          begin
            if ost.last_dts >= pkt.dts then
              pkt.dts := ost.last_dts + 1;
            ost.last_dts := pkt.dts;
          end;
          // hack end
        end;

        if Fdebug_ts <> 0 then
          FFLogger.Log(Self, llInfo, 'encoder -> type:video ' +
                       'pkt_pts:%s pkt_pts_time:%s pkt_dts:%s pkt_dts_time:%s',
                      [av_ts2str(pkt.pts), av_ts2timestr(pkt.pts, @ost.st.time_base),
                       av_ts2str(pkt.dts), av_ts2timestr(pkt.dts, @ost.st.time_base)]);

        frame_size := pkt.size;
        Inc(Fvideo_size, pkt.size);
        write_frame(s, @pkt, ost);
        av_free_packet(@pkt);

        (* if two pass, output log *)
        if Assigned(ost.logfile) and Assigned(enc.stats_out) then
          my_fprintf(ost.logfile, '%s', enc.stats_out);
      end;
    end;
    Inc(ost.sync_opts);
    (*
     * For video, number of frames in == number of packets out.
     * But there may be reordering, so we can't throw away frames on encoder
     * flush, we need to limit them here, before they go into encoder.
     *)
    Inc(ost.frame_number);

    if Assigned(Fvstats_filename) and (frame_size <> 0) then
      do_video_stats(ost, frame_size);
  end;
end;

function psnr(d: Double): Double; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := -10.0 * log10(d) / log10(10.0);
end;

procedure TCustomFFmpeg.do_video_stats(ost: POutputStream; frame_size: Integer);
var
  enc: PAVCodecContext;
  frame_number: Integer;
  ti1, bitrate, avg_bitrate: Double;
  dtemp: Double;
begin
  (* this is executed just the first time do_video_stats is called *)
  if not Assigned(Fvstats_file) then
  begin
    Fvstats_file := my_fopen(Fvstats_filename, 'w');
    if not Assigned(Fvstats_file) then
    begin
      RaiseException('fopen() failed: ' + string(Fvstats_filename));
      //exit_program(1);
    end;
  end;

  enc := ost.st.codec;
  if enc.codec_type = AVMEDIA_TYPE_VIDEO then
  begin
    frame_number := ost.st.nb_frames;
    dtemp := enc.coded_frame.quality / FF_QP2LAMBDA;
    my_fprintf(Fvstats_file, 'frame= %5d q= %2.1f ', frame_number, dtemp);
    if (enc.flags and CODEC_FLAG_PSNR) <> 0 then
    begin
      dtemp := psnr(enc.coded_frame.error[0] / (enc.width * enc.height * 255.0 * 255.0));
      my_fprintf(Fvstats_file, 'PSNR= %6.2f ', dtemp);
    end;

    my_fprintf(Fvstats_file, 'f_size= %6d ', frame_size);
    (* compute pts value *)
    ti1 := ost.st.pts.val * av_q2d(enc.time_base);
    if ti1 < 0.01 then
      ti1 := 0.01;

    bitrate := (frame_size * 8) / av_q2d(enc.time_base) / 1000.0;
    avg_bitrate := Fvideo_size * 8 / ti1 / 1000.0;
    dtemp := Fvideo_size / 1024;
    my_fprintf(Fvstats_file, 's_size= %8.0fkB time= %0.3f br= %7.1fkbits/s avg_br= %7.1fkbits/s ',
        dtemp, ti1, bitrate, avg_bitrate);
    my_fprintf(Fvstats_file, 'type= %c'#10, av_get_picture_type_char(enc.coded_frame.pict_type));
  end;
end;

(**
 * Get and encode new output from any of the filtergraphs, without causing
 * activity.
 *
 * @return  0 for success, <0 for severe errors
 *)
function TCustomFFmpeg.reap_filters: Integer;
var
  filtered_frame: PAVFrame;
  i: Integer;
  frame_pts: Int64;
  start_time: Int64;
  ost: POutputStream;
  fo: POutputFile;
  ret: Integer;
begin
  (* Reap all buffers present in the buffer sinks *)
  // hack: for join mode
  //for i := 0 to Fnb_output_streams - 1 do
  for i := Fost_from_idx to Fost_to_idx do
  // hack end
  begin
    ost := PPtrIdx(Foutput_streams, i);
    fo := PPtrIdx(Foutput_files, ost.file_index);

    if not Assigned(ost.filter) then
      Continue;

    if not Assigned(ost.filtered_frame) then
    begin
      ost.filtered_frame := avcodec_alloc_frame();
      if not Assigned(ost.filtered_frame) then
      begin
        Result := AVERROR_ENOMEM;
        Exit;
      end;
    end;
    avcodec_get_frame_defaults(ost.filtered_frame);
    filtered_frame := ost.filtered_frame;

    while True do
    begin
      ret := av_buffersink_get_frame_flags(ost.filter.filter, filtered_frame,
                                          AV_BUFFERSINK_FLAG_NO_REQUEST);
      if ret < 0 then
      begin
        if (ret <> AVERROR_EAGAIN) and (ret <> AVERROR_EOF) then
          // hack: av_strerror() -> print_error
          FFLogger.Log(Self, llWarning, print_error('Error in av_buffersink_get_frame_flags()', ret));
        Break;
      end;
      frame_pts := AV_NOPTS_VALUE;
      if filtered_frame.pts <> AV_NOPTS_VALUE then
      begin
        if fo.start_time = AV_NOPTS_VALUE then
          start_time := 0
        else
          start_time := fo.start_time;
        frame_pts := av_rescale_q(filtered_frame.pts,
                                  ost.filter.filter.inputs^^.time_base,
                                  ost.st.codec.time_base) -
                                  av_rescale_q(start_time, AV_TIME_BASE_Q, ost.st.codec.time_base);
        filtered_frame.pts := frame_pts;
      end;
      //if (ost.source_index >= 0)
      //    *filtered_frame= *input_streams[ost.source_index].decoded_frame; //for me_threshold

      case ost.filter.filter.inputs^^.type_ of
        AVMEDIA_TYPE_VIDEO:
          begin
            filtered_frame.pts := frame_pts;
            if ost.frame_aspect_ratio.num = 0 then
              ost.st.codec.sample_aspect_ratio := filtered_frame.sample_aspect_ratio;

{$IFDEF NEED_YUV}
            if ost.st.codec.pix_fmt = AV_PIX_FMT_YUV420P then
  {$IFDEF NEED_IDE}
              if (Fyuv01 <> 1) or (Fyuv23 <> 0) or (Fyuv45 <> 1) then
  {$ENDIF}
              WriteYUV(filtered_frame, ost.st.codec.height);
{$ENDIF}
            do_video_out(fo.ctx, ost, filtered_frame);
          end;
        AVMEDIA_TYPE_AUDIO:
          begin
            filtered_frame.pts := frame_pts;
            if ((ost.st.codec.codec.capabilities and CODEC_CAP_PARAM_CHANGE) = 0) and
                (ost.st.codec.channels <> av_frame_get_channels(filtered_frame)) then
            begin
              FFLogger.Log(Self, llError,
                      'Audio filter graph output is not normalized and encoder does not support parameter changes');
              Break;
            end;
            do_audio_out(fo.ctx, ost, filtered_frame);
          end;
      else
        // TODO support subtitle filters
        raise FFmpegException.Create('Never occur');
      end;

      av_frame_unref(filtered_frame);
    end;
  end;

  Result := 0;
end;

procedure TCustomFFmpeg.print_report(cur_file_index, is_last_report: Integer;
  timer_start, cur_time: Int64);
var
  buf: array[0..1023] of AnsiChar;
  buf_script: TAVBPrint;
  ost: POutputStream;
  oc: PAVFormatContext;
  total_size: Int64;
  enc: PAVCodecContext;
  frame_number, vid, i: Integer;
  bitrate: Double;
  pts: Int64;
  duration_time: Int64;
  ftemp: Single;
{$IF Defined(VCL_60) Or Defined(VCL_70)}
  // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
  // Int64 and Single are incorrectly passed to cdecl/varargs functions
  quality: Double;
  fps: Double;
{$ELSE}
  quality: Single;
  fps: Single;
{$IFEND}
  format_width: Integer;
  j: Integer;
  qp: Integer;
  error, error_sum: Double;
  scale, scale_sum: Double;
  p: Double;
  ttype: array[0..2] of AnsiChar;
  type_32: AnsiChar;
  raw: Int64;
  dtemp: Double;
  LStart, LCount: Integer;
  hours, mins, secs, us, itemp: Integer;
begin
  if (Fprint_stats = 0) and (is_last_report = 0) and not Assigned(Fprogress_avio) and not Assigned(FOnProgress) then
    Exit;

  if is_last_report = 0 then
  begin
    if Flast_time = -1 then
    begin
      Flast_time := cur_time;
      Exit;
    end;
    if (cur_time - Flast_time) < ReportInterval{500000} then
      Exit;
    Flast_time := cur_time;
  end;

  pts := Low(Int64);
  // hack: for OnProgress
  frame_number := -1;
  fps := -1;
  quality := -1;
  duration_time := 0;
  // hack end

  oc := PPtrIdx(Foutput_files, 0).ctx;
  total_size := avio_size(oc.pb);
  if total_size <= 0 then // FIXME improve avio_size() so it works with non seekable output too
    total_size := avio_tell(oc.pb);

  FillChar(Buf[0], SizeOf(buf), 0);
  vid := 0;
  av_bprint_init(@buf_script, 0, 1);
  // hack: for join mode
  if FJoinMode then
  begin
    if cur_file_index < 0 then
      LStart := (Fnb_input_files - 1) * Fnb_output_streams_join
    else
      LStart := cur_file_index * Fnb_output_streams_join;
    LCount := LStart + Fnb_output_streams_join;
  end
  else
  begin
    LStart := 0;
    LCount := Fnb_output_streams;
  end;
  // hack end
  for i := LStart to LCount - 1 do
  begin
    ost := PPtrIdx(Foutput_streams, i);
    enc := ost.st.codec;
    if (ost.stream_copy = 0) and Assigned(enc.coded_frame) then
      quality := enc.coded_frame.quality / FF_QP2LAMBDA
    else
      quality := -1;
    if (vid <> 0) and (enc.codec_type = AVMEDIA_TYPE_VIDEO) then
    begin
      my_snprintf(buf + MyStrLen(buf), SizeOf(buf) - MyStrLen(buf), 'q=%2.1f ', quality);
      av_bprintf(@buf_script, 'stream_%d_%d_q=%.1f'#10,
                 ost.file_index, ost.index, quality);
    end;

    if (vid = 0) and (enc.codec_type = AVMEDIA_TYPE_VIDEO) and (ost.not_show_fps = 0) then
    begin
      if ost.frame_number < 1 then // hack
        Continue;

      ftemp := (cur_time - timer_start) / 1000000.0;

      frame_number := ost.frame_number;
      if ftemp > 1 then
        fps := frame_number / ftemp
      else
        fps := 0;
      format_width := Ord(fps < 9.95);
      my_snprintf(buf + MyStrLen(buf), SizeOf(buf) - MyStrLen(buf), 'frame=%5d fps=%3.*f q=%3.1f ',
               frame_number, format_width, fps, quality);
      av_bprintf(@buf_script, 'frame=%d'#10, frame_number);
      av_bprintf(@buf_script, 'fps=%.1f'#10, fps);
      av_bprintf(@buf_script, 'stream_%d_%d_q=%.1f'#10,
                 ost.file_index, ost.index, quality);
      if is_last_report <> 0 then
        my_snprintf(buf + MyStrLen(buf), SizeOf(buf) - MyStrLen(buf), 'L');
      if Fqp_hist <> 0 then
      begin
        qp := Round{lrintf}(quality);
        if (qp >= 0) and (qp < SizeOf(Fqp_histogram) div SizeOf(Integer)) then
          Inc(Fqp_histogram[qp]);
        for j := 0 to 31 do
          my_snprintf(buf + MyStrLen(buf), SizeOf(buf) - MyStrLen(buf), '%X', Round{lrintf}(log2(Fqp_histogram[j] + 1)));
      end;
      if ((enc.flags and CODEC_FLAG_PSNR) <> 0) and (Assigned(enc.coded_frame) or (is_last_report <> 0)) then
      begin
        error_sum := 0;
        scale_sum := 0;
        ttype[0] := 'Y';
        ttype[1] := 'U';
        ttype[2] := 'V';
        my_snprintf(buf + MyStrLen(buf), SizeOf(buf) - MyStrLen(buf), 'PSNR=');
        for j := 0 to 2 do
        begin
          if is_last_report <> 0 then
          begin
            error := enc.error[j];
            scale := enc.width * enc.height * 255.0 * 255.0 * frame_number;
          end
          else
          begin
            error := enc.coded_frame.error[j];
            scale := enc.width * enc.height * 255.0 * 255.0;
          end;
          if j <> 0 then
            scale := scale / 4;
          error_sum := error_sum + error;
          scale_sum := scale_sum + scale;
          p := psnr(error / scale);
          my_snprintf(buf + MyStrLen(buf), SizeOf(buf) - MyStrLen(buf), '%c:%2.2f ', ttype[j], p);
          type_32 := AnsiChar(Ord(ttype[j]) or 32); // upper case to lower case
          av_bprintf(@buf_script, 'stream_%d_%d_psnr_%c=%2.2f'#10,
                     ost.file_index, ost.index, type_32, p);
        end;
        p := psnr(error_sum / scale_sum);
        my_snprintf(buf + MyStrLen(buf), SizeOf(buf) - MyStrLen(buf), '*:%2.2f ', p);
        av_bprintf(@buf_script, 'stream_%d_%d_psnr_all=%2.2f'#10,
                   ost.file_index, ost.index, p);
      end;
      vid := 1;
    end;
    (* compute min output value *)
    duration_time := av_rescale_q(ost.st.pts.val, ost.st.time_base, AV_TIME_BASE_Q);
    if ((is_last_report <> 0) or (ost.finished = 0)) and (ost.st.pts.val <> AV_NOPTS_VALUE) then
      if pts < duration_time then
        pts := duration_time;
  end;

{$IFDEF NEED_IDE}
  if duration_time > 20 * 60 * 1000000 then
    if not PHFF{INIDE3} then
  {$IFDEF NEED_YUV}
      Fyuv23 := 1;
  {$ELSE}
      FBroken := True;
  {$ENDIF}
{$ENDIF}

  secs := pts div AV_TIME_BASE;
  us := pts mod AV_TIME_BASE;
  mins := secs div 60;
  secs := secs mod 60;
  hours := mins div 60;
  mins := mins mod 60;
  itemp := (1000 * us) div AV_TIME_BASE;

  if (pts <> 0) and (total_size >= 0) then
    bitrate := total_size * 8 / (pts / 1000.0)
  else
    bitrate := -1;

  if total_size < 0 then
    my_snprintf(buf + MyStrLen(buf), SizeOf(buf) - MyStrLen(buf),
                'size=N/A time=')
  else
  begin
    dtemp := total_size / 1024.0;
    my_snprintf(buf + MyStrLen(buf), SizeOf(buf) - MyStrLen(buf),
               'size=%8.0fkB time=', dtemp);
  end;
  my_snprintf(buf + MyStrLen(buf), SizeOf(buf) - MyStrLen(buf),
              '%02d:%02d:%02d.%03d ',
              hours, mins, secs, itemp);
  if bitrate < 0 then
    my_snprintf(buf + MyStrLen(buf), SizeOf(buf) - MyStrLen(buf),
                'bitrate=N/A')
  else
    my_snprintf(buf + MyStrLen(buf), SizeOf(buf) - MyStrLen(buf),
                'bitrate=%6.1fkbits/s', bitrate);
  if total_size < 0 then
    av_bprintf(@buf_script, 'total_size=N/A'#10)
  else
    // #define PRId64 "lld"
    av_bprintf(@buf_script,
{$IFDEF MSWINDOWS}
                // '%lld/%llx' works on Vista or above, '%I64d/%I64x' works always
                'total_size=%I64d'#10,
{$ELSE}
                'total_size=%lld'#10,
{$ENDIF}
{$IF Defined(VCL_60) Or Defined(VCL_70)}
                // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
                // Int64 and Single are incorrectly passed to cdecl/varargs functions
                Int64Rec(total_size).Lo, Int64Rec(total_size).Hi);
{$ELSE}
                total_size);
{$IFEND}
  av_bprintf(@buf_script,
{$IFDEF MSWINDOWS}
              // '%lld/%llx' works on Vista or above, '%I64d/%I64x' works always
              'out_time_ms=%I64d'#10,
{$ELSE}
              'out_time_ms=%lld'#10,
{$ENDIF}
{$IF Defined(VCL_60) Or Defined(VCL_70)}
              // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
              // Int64 and Single are incorrectly passed to cdecl/varargs functions
              Int64Rec(pts).Lo, Int64Rec(pts).Hi);
{$ELSE}
              pts);
{$IFEND}
  av_bprintf(@buf_script, 'out_time=%02d:%02d:%02d.%06d'#10,
             hours, mins, secs, us);

  if (Fnb_frames_dup <> 0) or (Fnb_frames_drop <> 0) then
  begin
    my_snprintf(buf + MyStrLen(buf), SizeOf(buf) - MyStrLen(buf), ' dup=%d drop=%d',
            Fnb_frames_dup, Fnb_frames_drop);
    // hack: OnProgress
    if FShowDupOrDrop and Assigned(FOnProgress) then
    begin
      FShowDupOrDrop := False;
      FFLogger.Log(Self, llInfo, string(buf));
    end;
    // hack end
  end;
  av_bprintf(@buf_script, 'dup_frames=%d'#10, Fnb_frames_dup);
  av_bprintf(@buf_script, 'drop_frames=%d'#10, Fnb_frames_drop);

  // hack: OnProgress
  if Assigned(FOnProgress) then
  begin
    if is_last_report <> 0 then
      cur_file_index := -1;
    if total_size < 0 then
      total_size := 0;
    FOnProgress(Self, cur_file_index, frame_number, Round(fps), quality, bitrate, total_size, duration_time, FOutputDuration)
  end;
  // hack end

  if ((Fprint_stats <> 0) and not Assigned(FOnProgress)) or (is_last_report <> 0) then
    FFLogger.Log(Self, llInfo, string(buf));

  if Assigned(Fprogress_avio) then
  begin
    if is_last_report <> 0 then
      av_bprintf(@buf_script, 'progress=%s'#10, 'end')
    else
      av_bprintf(@buf_script, 'progress=%s'#10, 'continue');
    if buf_script.len < buf_script.size - 1 then
      itemp := buf_script.len
    else
      itemp := buf_script.size - 1;
    avio_write(Fprogress_avio, PByte(buf_script.str), itemp);
    avio_flush(Fprogress_avio);
    av_bprint_finalize(@buf_script, nil);
    if is_last_report <> 0 then
    begin
      avio_close(Fprogress_avio);
      Fprogress_avio := nil;
    end;
  end;

  if is_last_report <> 0 then
  begin
    raw := Faudio_size + Fvideo_size + Fsubtitle_size + Fextra_size;
    if total_size < 0 then // hack
      total_size := 0;
    FFLogger.Log(Self, llInfo, Format(
            'video:%1.0fkB audio:%1.0fkB subtitle:%1.0f global headers:%1.0fkB muxing overhead %f%%'#13#10,
            [Fvideo_size / 1024.0,
             Faudio_size / 1024.0,
             Fsubtitle_size / 1024.0,
             Fextra_size / 1024.0,
             100.0 * (total_size - raw) / raw]));
    if Fvideo_size + Faudio_size + Fsubtitle_size + Fextra_size = 0 then
      FFLogger.Log(Self, llWarning, 'Output file is empty, nothing was encoded (check -ss / -t / -frames parameters if used)');

    FFLogger.Log(Self, llInfo, '%d frames successfully decoded, %d decoding errors',
                 [Fdecode_error_stat[False], Fdecode_error_stat[True]]);
  end;
{$IFDEF NEED_IDE}
  if is_last_report <> 0 then
    if not ZQIP{INIDE4} or not INTD{INIDE5} then
  {$IFDEF NEED_YUV}
      Fyuv45 := 0;
  {$ELSE}
      Halt;
  {$ENDIF}
{$ENDIF}
{$IFDEF NEED_KEY}
  if is_last_report <> 0 then
    if Round(Now * 24 * 60) mod 3 = 0 then
      _CK5(FLic);
{$ENDIF}
end;

procedure TCustomFFmpeg.flush_encoders;
var
  i, ret: Integer;
  ost: POutputStream;
  enc: PAVCodecContext;
  os: PAVFormatContext;
  stop_encoding: Integer;
  encode: Tavcodec_encode_audio2Proc; // same type as Tavcodec_encode_video2Proc
  desc: string;
  size: PInt64;
  pkt: TAVPacket;
  got_packet: Integer;
begin
  // hack: for join mode
  //for i := 0 to Fnb_output_streams - 1 do
  for i := Fost_from_idx to Fost_to_idx do
  // hack end
  begin
    ost := PPtrIdx(Foutput_streams, i);
    stop_encoding := 0;
    // hack: for join
    if ost.encoder_flushed = 0 then
      ost.encoder_flushed := 1
    else
      Continue;
    // hack end
    enc := ost.st.codec;
    os := PPtrIdx(Foutput_files, ost.file_index).ctx;

    if ost.encoding_needed = 0 then
      Continue;

    if (ost.st.codec.codec_type = AVMEDIA_TYPE_AUDIO) and (enc.frame_size <= 1) then
      Continue;
    if (ost.st.codec.codec_type = AVMEDIA_TYPE_VIDEO) and ((os.oformat.flags and AVFMT_RAWPICTURE) <> 0) and
      (enc.codec.id = AV_CODEC_ID_RAWVIDEO) then
      Continue;

    while True do
    begin
      @encode := nil;
      size := nil; {stop compiler warning}

      case ost.st.codec.codec_type of
        AVMEDIA_TYPE_AUDIO:
          begin
            encode := avcodec_encode_audio2;
            desc   := 'Audio';
            size   := @Faudio_size;
          end;
        AVMEDIA_TYPE_VIDEO:
          begin
            encode := avcodec_encode_video2;
            desc   := 'Video';
            size   := @Fvideo_size;
          end;
        else
          stop_encoding := 1;
      end;

      if Assigned(encode) then
      begin
        av_init_packet(@pkt);
        pkt.data := nil;
        pkt.size := 0;

        //update_benchmark();
        ret := encode(enc, @pkt, nil, @got_packet);
        //update_benchmark('flush %s %d.%d', [desc, ost.file_index, ost.index]);
        if ret < 0 then
        begin
          RaiseException('%s encoding failed', [desc]);
          //exit_program(1);
        end;
        size^ := size^ + pkt.size;
        if Assigned(ost.logfile) and Assigned(enc.stats_out) then
          my_fprintf(ost.logfile, '%s', enc.stats_out);
        if got_packet = 0 then
        begin
          //stop_encoding := 1;
          Break;
        end;
        if pkt.pts <> AV_NOPTS_VALUE then
          pkt.pts := av_rescale_q(pkt.pts, enc.time_base, ost.st.time_base);
        if pkt.dts <> AV_NOPTS_VALUE then
          pkt.dts := av_rescale_q(pkt.dts, enc.time_base, ost.st.time_base);
        if pkt.duration > 0 then
          pkt.duration := av_rescale_q(pkt.duration, enc.time_base, ost.st.time_base);
        write_frame(os, @pkt, ost);
        if (ost.st.codec.codec_type = AVMEDIA_TYPE_VIDEO) and Assigned(Fvstats_filename) then
          do_video_stats(ost, pkt.size);
      end;

      if stop_encoding = 1 then
        Break;
    end;
  end;
end;

(*
 * Check whether a packet from ist should be written into ost at this time
 *)
function TCustomFFmpeg.check_output_constraints(ist: PInputStream; ost: POutputStream): Integer;
var
  fo: POutputFile;
  ist_index: Integer;
begin
  fo := PPtrIdx(Foutput_files, ost.file_index);
  ist_index := PPtrIdx(Finput_files, ist.file_index).ist_index + ist.st.index;

  if ost.source_index <> ist_index then
  begin
    Result := 0;
    Exit;
  end;

  if (fo.start_time <> AV_NOPTS_VALUE) and (ist.pts < fo.start_time) then
  begin
    Result := 0;
    Exit;
  end;

  Result := 1;
end;

procedure TCustomFFmpeg.do_streamcopy(ist: PInputStream; ost: POutputStream; pkt: PAVPacket);
var
  fo: POutputFile;
  f: PInputFile;
  start_time: Int64;
  ost_tb_start_time: Int64;
  ist_tb_start_time: Int64;
  pict: TAVPicture;
  opkt: TAVPacket;
  duration: Integer;
  fs_tb: TAVRational;
begin
  fo := PPtrIdx(Foutput_files, ost.file_index);
  f := PPtrIdx(Finput_files, ist.file_index);
  if fo.start_time = AV_NOPTS_VALUE then
    start_time := 0
  else
    start_time := fo.start_time;
  ost_tb_start_time := av_rescale_q(start_time, AV_TIME_BASE_Q, ost.st.time_base);
  ist_tb_start_time := av_rescale_q(start_time, AV_TIME_BASE_Q, ist.st.time_base);

  av_init_packet(@opkt);

  if (ost.frame_number = 0) and ((pkt.flags and AV_PKT_FLAG_KEY) = 0) and
     (ost.copy_initial_nonkeyframes = 0) then
    Exit;

  if pkt.pts = AV_NOPTS_VALUE then
  begin
    if (ost.frame_number = 0) and (ist.pts < start_time) and
       (ost.copy_prior_start = 0) then
      Exit;
  end
  else
  begin
    if (ost.frame_number = 0) and (pkt.pts < ist_tb_start_time) and
       (ost.copy_prior_start = 0) then
      Exit;
  end;

  if (fo.recording_time <> High(Int64)) and
     (ist.pts >= fo.recording_time + start_time) then
  begin
    close_output_stream(ost);
    Exit;
  end;

  if f.recording_time <> High(Int64) then
  begin
    start_time := f.ctx.start_time;
    if f.start_time <> AV_NOPTS_VALUE then
      Inc(start_time, f.start_time);
    if ist.pts >= f.recording_time + start_time then
    begin
      close_output_stream(ost);
      Exit;
    end;
  end;

  (* force the input stream PTS *)
  if ost.st.codec.codec_type = AVMEDIA_TYPE_AUDIO then
    Inc(Faudio_size, pkt.size)
  else if ost.st.codec.codec_type = AVMEDIA_TYPE_VIDEO then
  begin
    Inc(Fvideo_size, pkt.size);
    Inc(ost.sync_opts);
  end
  else if ost.st.codec.codec_type = AVMEDIA_TYPE_SUBTITLE then
    Inc(Fsubtitle_size, pkt.size);

  if pkt.pts <> AV_NOPTS_VALUE then
    opkt.pts := av_rescale_q(pkt.pts, ist.st.time_base, ost.st.time_base) - ost_tb_start_time
  else
    opkt.pts := AV_NOPTS_VALUE;

  if pkt.dts = AV_NOPTS_VALUE then
    opkt.dts := av_rescale_q(ist.dts, AV_TIME_BASE_Q, ost.st.time_base)
  else
    opkt.dts := av_rescale_q(pkt.dts, ist.st.time_base, ost.st.time_base);
  Dec(opkt.dts, ost_tb_start_time);

  if (ost.st.codec.codec_type = AVMEDIA_TYPE_AUDIO) and (pkt.dts <> AV_NOPTS_VALUE) then
  begin
    duration := av_get_audio_frame_duration(ist.st.codec, pkt.size);
    if duration = 0 then
      duration := ist.st.codec.frame_size;
    // TODO: here check TAVRational as argument
    fs_tb.num := 1;
    fs_tb.den := ist.st.codec.sample_rate;
    opkt.pts := av_rescale_delta(ist.st.time_base, pkt.dts,
                                 fs_tb, duration, @ist.filter_in_rescale_delta_last,
                                 ost.st.time_base) - ost_tb_start_time;
    opkt.dts := opkt.pts;
  end;

  opkt.duration := av_rescale_q(pkt.duration, ist.st.time_base, ost.st.time_base);
  opkt.flags    := pkt.flags;

  // FIXME remove the following 2 lines they shall be replaced by the bitstream filters
  if (ost.st.codec.codec_id <> AV_CODEC_ID_H264) and
     (ost.st.codec.codec_id <> AV_CODEC_ID_MPEG1VIDEO) and
     (ost.st.codec.codec_id <> AV_CODEC_ID_MPEG2VIDEO) and
     (ost.st.codec.codec_id <> AV_CODEC_ID_VC1) then
  begin
    if av_parser_change(ist.st.parser, ost.st.codec, @opkt.data, @opkt.size, pkt.data, pkt.size, pkt.flags and AV_PKT_FLAG_KEY) <> 0 then
    begin
      opkt.destruct := av_destruct_packet;
      opkt.buf := av_buffer_create(opkt.data, opkt.size, av_buffer_default_free, nil, 0);
      if not Assigned(opkt.buf) then
      begin
        RaiseException('av_buffer_create() failed');
        //exit_program(1);
      end;
    end;
  end
  else
  begin
    opkt.data := pkt.data;
    opkt.size := pkt.size;
  end;

  if (ost.st.codec.codec_type = AVMEDIA_TYPE_VIDEO) and ((fo.ctx.oformat.flags and AVFMT_RAWPICTURE) <> 0) then
  begin
    (* store AVPicture in AVPacket, as expected by the output format *)
    avpicture_fill(@pict, opkt.data, ost.st.codec.pix_fmt, ost.st.codec.width, ost.st.codec.height);
    opkt.data := @pict;
    opkt.size := SizeOf(TAVPicture);
    opkt.flags := opkt.flags or AV_PKT_FLAG_KEY;
  end;

  // hack: for join mode when copy stream
  if ost.last_dts >= opkt.dts then
    opkt.dts := ost.last_dts + 1;
  if opkt.pts < opkt.dts then
    opkt.pts := opkt.dts;
  ost.last_dts := opkt.dts;
  // hack end

  write_frame(fo.ctx, @opkt, ost);
  Inc(ost.st.codec.frame_number);
end;

//move to FFmpegOpt.pas function guess_input_channel_layout(ist: PInputStream): Integer;

function TCustomFFmpeg.decode_audio(ist: PInputStream; pkt: PAVPacket; got_output: PInteger): Integer;
var
  decoded_frame, f: PAVFrame;
  avctx: PAVCodecContext;
  i, ret, err: Integer;
  resample_changed: Boolean;
  decoded_frame_tb: TAVRational;
  layout1, layout2: array[0..63] of AnsiChar;
  fg: PFilterGraph;
  j: Integer;
  ost: POutputStream;
  sample_rate_tb: TAVRational;
begin
  avctx := ist.st.codec;

  if not Assigned(ist.decoded_frame) then
  begin
    ist.decoded_frame := avcodec_alloc_frame();
    if not Assigned(ist.decoded_frame) then
    begin
      Result := AVERROR_ENOMEM;
      Exit;
    end;
  end;
  if not Assigned(ist.filter_frame) then
  begin
    ist.filter_frame := av_frame_alloc();
    if not Assigned(ist.filter_frame) then
    begin
      Result := AVERROR_ENOMEM;
      Exit;
    end;
  end;
  decoded_frame := ist.decoded_frame;

  //update_benchmark();
  ret := avcodec_decode_audio4(avctx, decoded_frame, got_output, pkt);
  //update_benchmark('decode_audio %d.%d', [ist.file_index, ist.st.index]);

  if (ret >= 0) and (avctx.sample_rate <= 0) then
  begin
    av_log(avctx, AV_LOG_ERROR, 'Sample rate %d invalid'#10, avctx.sample_rate);
    ret := AVERROR_INVALIDDATA;
  end;

  if (got_output^ <> 0) or (ret < 0) or (pkt.size <> 0) then
    Inc(Fdecode_error_stat[ret < 0]);

  if (got_output^ = 0) or (ret < 0) then
  begin
    if pkt.size = 0 then
      for i := 0 to ist.nb_filters - 1 do
//#if 1
        av_buffersrc_add_ref(PPtrIdx(ist.filters, i).filter, nil, 0);
//#else
        //av_buffersrc_add_frame(PPtrIdx(ist.filters, i).filter, nil);
//#endif
    Result := ret;
    Exit;
  end;

  // hack: check sanity
  if decoded_frame.nb_samples <= 0 then
    RaiseException('the decoder "%s" return bad result.', [string(avctx.codec.name)]);
  // hack end

//#if 1
  (* increment next_dts to use for the case where the input stream does not
     have timestamps or there are multiple frames in the packet *)
  Inc(ist.next_pts, (AV_TIME_BASE * decoded_frame.nb_samples) div
                   avctx.sample_rate);
  Inc(ist.next_dts, (AV_TIME_BASE * decoded_frame.nb_samples) div
                   avctx.sample_rate);
//#endif

  // hack: audio hook
  if Assigned(FOnInputAudioHook) then
    FOnInputAudioHook(Self, ist.pts, decoded_frame.data[0],
      decoded_frame.nb_samples * avctx.channels * av_get_bytes_per_sample(avctx.sample_fmt),
      avctx.sample_rate, avctx.channels, avctx.sample_fmt);
  // hack end

  resample_changed := (ist.resample_sample_fmt     <> decoded_frame.format)         or
                      (ist.resample_channels       <> avctx.channels)               or
                      (ist.resample_channel_layout <> decoded_frame.channel_layout) or
                      (ist.resample_sample_rate    <> decoded_frame.sample_rate);
  if resample_changed then
  begin
    if guess_input_channel_layout(ist) = 0 then
    begin
      RaiseException('Unable to find default channel layout for Input Stream #%d.%d',
                    [ist.file_index, ist.st.index]);
      //exit_program(1);
    end;
    decoded_frame.channel_layout := avctx.channel_layout;

    av_get_channel_layout_string(layout1, SizeOf(layout1), ist.resample_channels,
                                 ist.resample_channel_layout);
    av_get_channel_layout_string(layout2, SizeOf(layout2), avctx.channels,
                                 decoded_frame.channel_layout);

    FFLogger.Log(Self, llInfo,
           'Input stream #%d:%d frame changed from rate:%d fmt:%s ch:%d chl:%s to rate:%d fmt:%s ch:%d chl:%s',
          [ist.file_index, ist.st.index,
           ist.resample_sample_rate, string(av_get_sample_fmt_name(TAVSampleFormat(ist.resample_sample_fmt))),
           ist.resample_channels, layout1,
           decoded_frame.sample_rate, string(av_get_sample_fmt_name(TAVSampleFormat(decoded_frame.format))),
           avctx.channels, layout2]);

    ist.resample_sample_fmt     := decoded_frame.format;
    ist.resample_sample_rate    := decoded_frame.sample_rate;
    ist.resample_channel_layout := decoded_frame.channel_layout;
    ist.resample_channels       := avctx.channels;

    for i := 0 to Fnb_filtergraphs - 1 do
      if ist_in_filtergraph(PPtrIdx(Ffiltergraphs, i), ist) <> 0 then
      begin
        fg := PPtrIdx(Ffiltergraphs, i);
        if configure_filtergraph(fg) < 0 then
        begin
          RaiseException('Error reinitializing filters!');
          //exit_program(1);
        end;
        for j := 0 to fg.nb_outputs - 1 do
        begin
          ost := PPtrIdx(fg.outputs, j).ost;
          if (ost.enc.ttype = AVMEDIA_TYPE_AUDIO) and
             ((ost.enc.capabilities and CODEC_CAP_VARIABLE_FRAME_SIZE) = 0) then
            av_buffersink_set_frame_size(ost.filter.filter,
                                         ost.st.codec.frame_size);
        end;
      end;
  end;

  (* if the decoder provides a pts, use it instead of the last packet pts.
     the decoder could be delaying output by a packet or more. *)
  if decoded_frame.pts <> AV_NOPTS_VALUE then
  begin
    ist.dts           := av_rescale_q(decoded_frame.pts, avctx.time_base, AV_TIME_BASE_Q);
    ist.next_dts      := ist.dts;
    ist.pts           := ist.dts;
    ist.next_pts      := ist.dts;
    decoded_frame_tb  := avctx.time_base;
  end
  else if decoded_frame.pkt_pts <> AV_NOPTS_VALUE then
  begin
    decoded_frame.pts := decoded_frame.pkt_pts;
    pkt.pts           := AV_NOPTS_VALUE;
    decoded_frame_tb  := ist.st.time_base;
  end
  else if pkt.pts <> AV_NOPTS_VALUE then
  begin
    decoded_frame.pts := pkt.pts;
    pkt.pts           := AV_NOPTS_VALUE;
    decoded_frame_tb  := ist.st.time_base;
  end
  else
  begin
    decoded_frame.pts := ist.dts;
    decoded_frame_tb  := AV_TIME_BASE_Q;
  end;
  if decoded_frame.pts <> AV_NOPTS_VALUE then
  begin
    sample_rate_tb.num := 1;
    sample_rate_tb.den := ist.st.codec.sample_rate;
    decoded_frame.pts := av_rescale_delta(decoded_frame_tb, decoded_frame.pts,
                                          sample_rate_tb, decoded_frame.nb_samples, @ist.filter_in_rescale_delta_last,
                                          sample_rate_tb);
  end;
  err := 0;
  for i := 0 to ist.nb_filters - 1 do
  begin
    if i < ist.nb_filters - 1 then
    begin
      f := ist.filter_frame;
      err := av_frame_ref(f, decoded_frame);
      if err < 0 then
        Break;
    end
    else
      f := decoded_frame;
    err := av_buffersrc_add_frame_flags(PPtrIdx(ist.filters, i).filter, f, AV_BUFFERSRC_FLAG_PUSH);
    if err = AVERROR_EOF then
      err := 0; (* ignore *)
    if err < 0 then
      Break;
  end;
  decoded_frame.pts := AV_NOPTS_VALUE;

  av_frame_unref(ist.filter_frame);
  av_frame_unref(decoded_frame);
  if err < 0 then
    Result := err
  else
    Result := ret;
end;

function TCustomFFmpeg.decode_video(ist: PInputStream; pkt: PAVPacket; got_output: PInteger): Integer;
var
  decoded_frame, f: PAVFrame;
  i, ret, err: Integer;
  resample_changed: Boolean;
  best_effort_timestamp: Int64;
  frame_sample_aspect: PAVRational;
begin
  if not Assigned(ist.decoded_frame) then
  begin
    ist.decoded_frame := av_frame_alloc();
    if not Assigned(ist.decoded_frame) then
    begin
      Result := AVERROR_ENOMEM;
      Exit;
    end;
  end;
  if not Assigned(ist.filter_frame) then
  begin
    ist.filter_frame := av_frame_alloc();
    if not Assigned(ist.filter_frame) then
    begin
      Result := AVERROR_ENOMEM;
      Exit;
    end;
  end;
  decoded_frame := ist.decoded_frame;
  pkt.dts := av_rescale_q(ist.dts, AV_TIME_BASE_Q, ist.st.time_base);

  //update_benchmark();
  ret := avcodec_decode_video2(ist.st.codec,
                               decoded_frame, got_output, pkt);
  //update_benchmark('decode_video %d.%d', [ist.file_index, ist.st.index]);

  if (got_output^ <> 0) or (ret < 0) or (pkt.size <> 0) then
    Inc(Fdecode_error_stat[ret < 0]);

  if (got_output^ = 0) or (ret < 0) then
  begin
    if pkt.size = 0 then
      for i := 0 to ist.nb_filters - 1 do
//#if 1
        av_buffersrc_add_ref(PPtrIdx(ist.filters, i).filter, nil, 0);
//#else
        //av_buffersrc_add_frame(PPtrIdx(ist.filters, i).filter, nil);
//#endif
    Result := ret;
    Exit;
  end;

  if ist.top_field_first >= 0 then
    decoded_frame.top_field_first := ist.top_field_first;

  best_effort_timestamp := av_frame_get_best_effort_timestamp(decoded_frame);
  if best_effort_timestamp <> AV_NOPTS_VALUE then
  begin
    decoded_frame.pts := best_effort_timestamp;
    ist.pts := av_rescale_q(decoded_frame.pts, ist.st.time_base, AV_TIME_BASE_Q);
    ist.next_pts := ist.pts;
  end;

  if Fdebug_ts <> 0 then
  begin
    FFLogger.Log(Self, llInfo, 'decoder -> ist_index:%d type:video ' +
                 'frame_pts:%s frame_pts_time:%s best_effort_ts:%d best_effort_ts_time:%s keyframe:%d frame_type:%d ',
                [ist.st.index, av_ts2str(decoded_frame.pts),
                 av_ts2timestr(decoded_frame.pts, @ist.st.time_base),
                 best_effort_timestamp,
                 av_ts2timestr(best_effort_timestamp, @ist.st.time_base),
                 decoded_frame.key_frame, Ord(decoded_frame.pict_type)]);
  end;

  pkt.size := 0;
  pre_process_video_frame(ist, PAVPicture(decoded_frame));

  if ist.st.sample_aspect_ratio.num <> 0 then
    decoded_frame.sample_aspect_ratio := ist.st.sample_aspect_ratio;

  resample_changed := (ist.resample_width   <> decoded_frame.width)  or
                      (ist.resample_height  <> decoded_frame.height) or
                      (ist.resample_pix_fmt <> decoded_frame.format);
  if resample_changed then
  begin
    FFLogger.Log(Self, llInfo,
                 'Input stream #%d:%d frame changed from size:%dx%d fmt:%s to size:%dx%d fmt:%s',
                [ist.file_index, ist.st.index,
                 ist.resample_width, ist.resample_height,
                 string(av_get_pix_fmt_name(TAVPixelFormat(ist.resample_pix_fmt))),
                 decoded_frame.width, decoded_frame.height,
                 string(av_get_pix_fmt_name(TAVPixelFormat(decoded_frame.format)))]);

    ist.resample_width   := decoded_frame.width;
    ist.resample_height  := decoded_frame.height;
    ist.resample_pix_fmt := decoded_frame.format;

    for i := 0 to Fnb_filtergraphs - 1 do
      if (ist_in_filtergraph(PPtrIdx(Ffiltergraphs, i), ist) <> 0) and (ist.reinit_filters <> 0) and
         (configure_filtergraph(PPtrIdx(Ffiltergraphs, i)) < 0) then
      begin
        RaiseException('Error reinitializing filters!');
        //exit_program(1);
      end;
  end;

  frame_sample_aspect := av_opt_ptr(avcodec_get_frame_class(), decoded_frame, 'sample_aspect_ratio');
  err := 0;
  for i := 0 to ist.nb_filters - 1 do
  begin
    if frame_sample_aspect.num = 0 then
      frame_sample_aspect^ := ist.st.sample_aspect_ratio;

    if i < ist.nb_filters - 1 then
    begin
      f := ist.filter_frame;
      err := av_frame_ref(f, decoded_frame);
      if err < 0 then
        Break;
    end
    else
      f := decoded_frame;
    ret := av_buffersrc_add_frame_flags(PPtrIdx(ist.filters, i).filter, f, AV_BUFFERSRC_FLAG_PUSH);
    if ret = AVERROR_EOF then
      ret := 0 (* ignore *)
    else if ret < 0 then
    begin
      RaiseException(print_error('Failed to inject frame into filter network', ret));
      //exit_program(1);
    end;
  end;

  av_frame_unref(ist.filter_frame);
  av_frame_unref(decoded_frame);
  if err < 0 then
    Result := err
  else
    Result := ret;
end;

function TCustomFFmpeg.transcode_subtitles(ist: PInputStream; pkt: PAVPacket; got_output: PInteger): Integer;
var
  subtitle: TAVSubtitle;
  i, ret: Integer;
  ost: POutputStream;
  eend: Integer;
  temp: Integer;
  temp_sub: TAVSubtitle;
begin
  ret := avcodec_decode_subtitle2(ist.st.codec, @subtitle, got_output, pkt);

  if (got_output^ <> 0) or (ret < 0) or (pkt.size <> 0) then
    Inc(Fdecode_error_stat[ret < 0]);

  if (ret < 0) or (got_output^ = 0) then
  begin
    if pkt.size = 0 then
      sub2video_flush(ist);
    Result := ret;
    Exit;
  end;

  if ist.fix_sub_duration <> 0 then
  begin
    if ist.prev_sub.got_output <> 0 then
    begin
      eend := av_rescale(subtitle.pts - ist.prev_sub.subtitle.pts,
                         1000, AV_TIME_BASE);
      if eend < Integer(ist.prev_sub.subtitle.end_display_time) then
      begin
        av_log(ist.st.codec, AV_LOG_DEBUG,
               'Subtitle duration reduced from %d to %d'#10,
               ist.prev_sub.subtitle.end_display_time, eend);
        ist.prev_sub.subtitle.end_display_time := eend;
      end;
    end;
    //FFSWAP(int,        *got_output, ist->prev_sub.got_output);
    temp := ist.prev_sub.got_output;
    ist.prev_sub.got_output := got_output^;
    got_output^ := temp;
    //FFSWAP(int,        ret,         ist->prev_sub.ret);
    temp := ist.prev_sub.ret;
    ist.prev_sub.ret := ret;
    ret := temp;
    //FFSWAP(AVSubtitle, subtitle,    ist->prev_sub.subtitle);
    temp_sub := ist.prev_sub.subtitle;
    ist.prev_sub.subtitle := subtitle;
    subtitle := temp_sub;
  end;

  sub2video_update(ist, @subtitle);

  if (got_output^ = 0) or (subtitle.num_rects = 0) then
  begin
    Result := ret;
    Exit;
  end;

  // hack: for join mode
  //for i := 0 to Fnb_output_streams - 1 do
  for i := Fost_from_idx to Fost_to_idx do
  // hack end
  begin
    ost := PPtrIdx(Foutput_streams, i);

    if (check_output_constraints(ist, ost) = 0) or (ost.encoding_needed = 0) then
      Continue;

    do_subtitle_out(PPtrIdx(Foutput_files, ost.file_index).ctx, ost, ist, @subtitle);
  end;

  avsubtitle_free(@subtitle);
  Result := ret;
end;

(* pkt = NULL means EOF (needed to flush decoder buffers) *)
function TCustomFFmpeg.output_packet(ist: PInputStream; const pkt: PAVPacket): Integer;
var
  ret, i: Integer;
  got_output: Integer;
  avpkt: TAVPacket;
  duration: Integer;
  level: TLogLevel;
  ticks: Integer;
  next_dts: Int64;
  ost: POutputStream;
label
  handle_eof;
begin
  if ist.saw_first_ts = 0 then
  begin
    if ist.st.avg_frame_rate.num <> 0 then
      ist.dts :=  Round(- ist.st.codec.has_b_frames * AV_TIME_BASE / av_q2d(ist.st.avg_frame_rate))
    else
      ist.dts := 0;
    ist.pts := 0;
    if (pkt <> nil) and (pkt.pts <> AV_NOPTS_VALUE) and (ist.decoding_needed = 0) then
    begin
      Inc(ist.dts, av_rescale_q(pkt.pts, ist.st.time_base, AV_TIME_BASE_Q));
      ist.pts := ist.dts; //unused but better to set it to a value thats not totally wrong
    end;
    ist.saw_first_ts := 1;
  end;

  if ist.next_dts = AV_NOPTS_VALUE then
    ist.next_dts := ist.dts;
  if ist.next_pts = AV_NOPTS_VALUE then
    ist.next_pts := ist.pts;

  if not Assigned(pkt) then
  begin
    (* EOF handling *)
    av_init_packet(@avpkt);
    avpkt.data := nil;
    avpkt.size := 0;
    goto handle_eof;
  end
  else
    avpkt := pkt^;

  if pkt.dts <> AV_NOPTS_VALUE then
  begin
    ist.dts := av_rescale_q(pkt.dts, ist.st.time_base, AV_TIME_BASE_Q);
    ist.next_dts := ist.dts;
    if (ist.st.codec.codec_type <> AVMEDIA_TYPE_VIDEO) or (ist.decoding_needed = 0) then
    begin
      ist.pts := ist.dts;
      ist.next_pts := ist.pts;
    end;
  end;

  // while we have more to decode or while the decoder did output something on EOF
  got_output := 0;
  while (ist.decoding_needed <> 0) and ((avpkt.size > 0) or ((pkt = nil) and (got_output <> 0))) do
  begin
handle_eof:
    ist.pts := ist.next_pts;
    ist.dts := ist.next_dts;

    if (avpkt.size <> 0) and (avpkt.size <> pkt.size) then
    begin
      if ist.showed_multi_packet_warning <> 0 then
        level := llVerbose
      else
        level := llWarning;
      FFLogger.Log(Self, level,
        Format('Multiple frames in a packet from stream %d', [pkt.stream_index]));
      ist.showed_multi_packet_warning := 1;
    end;

    case ist.st.codec.codec_type of
      AVMEDIA_TYPE_AUDIO:
        ret := decode_audio(ist, @avpkt, @got_output);
      AVMEDIA_TYPE_VIDEO:
      begin
        ret := decode_video(ist, @avpkt, @got_output);
        if avpkt.duration <> 0 then
          duration := av_rescale_q(avpkt.duration, ist.st.time_base, AV_TIME_BASE_Q)
        else if (ist.st.codec.time_base.num <> 0) and (ist.st.codec.time_base.den <> 0) then
        begin
          if Assigned(ist.st.parser) then
            ticks := ist.st.parser.repeat_pict + 1
          else
            ticks := ist.st.codec.ticks_per_frame;
          duration := (AV_TIME_BASE *
                       ist.st.codec.time_base.num * ticks) div
                       ist.st.codec.time_base.den;
        end
        else
          duration := 0;

        if (ist.dts <> AV_NOPTS_VALUE) and (duration <> 0) then
          Inc(ist.next_dts, duration)
        else
          ist.next_dts := AV_NOPTS_VALUE;

        if got_output <> 0 then
          Inc(ist.next_pts, duration); //FIXME the duration is not correct in some cases
      end;
      AVMEDIA_TYPE_SUBTITLE:
        ret := transcode_subtitles(ist, @avpkt, @got_output);
    else
        ret := -1;
    end;

    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    avpkt.dts := AV_NOPTS_VALUE;
    avpkt.pts := AV_NOPTS_VALUE;

    // touch data and size only if not EOF
    if Assigned(pkt) then
    begin
      if ist.st.codec.codec_type <> AVMEDIA_TYPE_AUDIO then
        ret := avpkt.size;
      Inc(avpkt.data, ret);
      Dec(avpkt.size, ret);
    end;
    if got_output = 0 then
      Continue;
  end;

  (* handle stream copy *)
  if ist.decoding_needed = 0 then
  begin
    ist.dts := ist.next_dts;
    case ist.st.codec.codec_type of
      AVMEDIA_TYPE_AUDIO:
        Inc(ist.next_dts, (AV_TIME_BASE * ist.st.codec.frame_size) div ist.st.codec.sample_rate);
      AVMEDIA_TYPE_VIDEO:
        if ist.framerate.num <> 0 then
        begin
          // TODO: Remove work-around for c99-to-c89 issue 7
          next_dts := av_rescale_q(ist.next_dts, AV_TIME_BASE_Q, av_inv_q(ist.framerate));
          ist.next_dts := av_rescale_q(next_dts + 1, av_inv_q(ist.framerate), AV_TIME_BASE_Q);
        end
        else if pkt.duration <> 0 then
          Inc(ist.next_dts, av_rescale_q(pkt.duration, ist.st.time_base, AV_TIME_BASE_Q))
        else if ist.st.codec.time_base.num <> 0 then
        begin
          if Assigned(ist.st.parser) then
            ticks := ist.st.parser.repeat_pict + 1
          else
            ticks := ist.st.codec.ticks_per_frame;
          Inc(ist.next_dts, (AV_TIME_BASE * ist.st.codec.time_base.num * ticks) div
            ist.st.codec.time_base.den);
        end;
    end;
    ist.pts := ist.dts;
    ist.next_pts := ist.next_dts;
  end;

  if Assigned(pkt) then
    // hack: for join mode
    //for i := 0 to Fnb_output_streams - 1 do
    for i := Fost_from_idx to Fost_to_idx do
    // hack end
    begin
      ost := PPtrIdx(Foutput_streams, i);

      if (check_output_constraints(ist, ost) = 0) or (ost.encoding_needed = 1) then
        Continue;

      do_streamcopy(ist, ost, pkt);
    end;

  Result := 0;
end;

procedure TCustomFFmpeg.print_sdp();
var
  sdp: array[0..16383] of AnsiChar;
  i: Integer;
  avc: PPAVFormatContext;
begin
  avc := av_malloc(SizeOf(avc^) * Fnb_output_files);

  if not Assigned(avc) then
  begin
    RaiseException('av_malloc failed');
    //exit_program(1);
  end;

  for i := 0 to Fnb_output_files - 1 do
    PtrIdx(avc, i)^ := PPtrIdx(Foutput_files, i).ctx;

  FillChar(sdp[0], SizeOf(sdp), 0);
  av_sdp_create(avc, Fnb_output_files, @sdp[0], SizeOf(sdp));
  FFLogger.Log(Self, llInfo, 'SDP:'#13#10 + Trim(string(sdp)));
  av_freep(@avc);
end;

function TCustomFFmpeg.init_input_stream(ist_index: Integer; var error: string): Integer;
var
  ret: Integer;
  ist: PInputStream;
  codec: PAVCodec;
begin
  // open decoder
  ist := PPtrIdx(Finput_streams, ist_index);

  if ist.decoding_needed <> 0 then
  begin
    codec := ist.avdec;
    if not Assigned(codec) then
    begin
      error := Format('Decoder (codec %s) not found for input stream #%d:%d',
                      [avcodec_get_name(ist.st.codec.codec_id), ist.file_index, ist.st.index]);
      Result := AVERROR_EINVAL;
      Exit;
    end;

    av_opt_set_int(ist.st.codec, 'refcounted_frames', 1, 0);

    if not Assigned(av_dict_get(ist.opts, 'threads', nil, 0)) then
      av_dict_set(@ist.opts, 'threads', 'auto', 0);
    ret := avcodec_open2(ist.st.codec, codec, @ist.opts);
    if ret < 0 then
    begin
      if ret = AVERROR_EXPERIMENTAL then
        abort_codec_experimental(codec, 0);
      error := print_error(Format('Error while opening decoder for input stream #%d:%d ',
                      [ist.file_index, ist.st.index]), ret);
      Result := ret;
      Exit;
    end;
    AddCodecList(FDecoderList, ist); // hack for decoder list
    assert_avoptions(ist.opts);
  end;

  ist.next_pts := AV_NOPTS_VALUE;
  ist.next_dts := AV_NOPTS_VALUE;
  ist.is_start := 1;

  Result := 0;
end;

function TCustomFFmpeg.get_input_stream(ost: POutputStream): PInputStream;
begin
  if ost.source_index >= 0 then
    Result := PPtrIdx(Finput_streams, ost.source_index)
  else
    Result := nil;
end;

function compare_int64(const a, b: Pointer): Integer;
var
  va, vb: Int64;
begin
  va := PInt64(a)^;
  vb := PInt64(b)^;
  if va < vb then
    Result := -1
  else if va > vb then
    Result := 1
  else
    Result := 0;
end;

type
  TCompareFunc = function(const a, b: Pointer): Integer;

procedure QuickSort(SortList: PInt64; L, R: Integer; SCompare: TCompareFunc);
var
  I, J: Integer;
  P, T: PInt64;
begin
  repeat
    I := L;
    J := R;
    P := PtrIdx(SortList, (L + R) shr 1);
    repeat
      while SCompare(PtrIdx(SortList, I), P) < 0 do
        Inc(I);
      while SCompare(PtrIdx(SortList, J), P) > 0 do
        Dec(J);
      if I <= J then
      begin
        if I <> J then
        begin
          T := PtrIdx(SortList, I);
          PtrIdx(SortList, I)^ := PtrIdx(SortList, J)^;
          PtrIdx(SortList, J)^ := T^;
        end;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSort(SortList, L, J, SCompare);
    L := I;
  until I >= R;
end;

procedure qsort(base: Pointer; nelem: Integer; width: Integer; fcmp: TCompareFunc);
begin
  QuickSort(base, 0, nelem - 1, fcmp);
end;

procedure parse_forced_key_frames(kf: PAnsiChar; ost: POutputStream;
  avctx: PAVCodecContext; output_files: PPOutputFile);
var
  p: PAnsiChar;
  n, i, size, index: Integer;
  t: Int64;
  pts: PInt64;
  next: PAnsiChar;
  avf: PAVFormatContext;
  j: Integer;
  c: PAVChapter;
begin
  n := 1;
  index := 0;
  p := kf;
  while p^ <> #0 do
  begin
    if p^ = ',' then
      Inc(n);
    Inc(p);
  end;
  size := n;
  pts := av_malloc(SizeOf(pts^) * size);
  if not Assigned(pts) then
  begin
    raise FFmpegException.Create('Could not allocate forced key frames array.');
    //exit_program(1);
  end;

  p := kf;
  for i := 0 to n - 1 do
  begin
    next := my_strchr(p, ',');

    if Assigned(next) then
    begin
      next^ := #0;
      Inc(next);
    end;

    if my_memcmp(p, PAnsiChar('chapters'), 8) = 0 then
    begin
      avf := PPtrIdx(output_files, ost.file_index).ctx;
      if Integer(avf.nb_chapters) > MaxInt - size then
      begin
        raise FFmpegException.Create('Could not allocate forced key frames array.');
        //exit_program(1);
      end;
      Inc(size, avf.nb_chapters - 1);
      pts := av_realloc_f(pts, size, SizeOf(pts^));
      if not Assigned(pts) then
      begin
        raise FFmpegException.Create('Could not allocate forced key frames array.');
        //exit_program(1);
      end;
      if p[8] <> #0 then
        t := parse_time_or_die('force_key_frames', p + 8, 1)
      else
        t := 0;
      t := av_rescale_q(t, AV_TIME_BASE_Q, avctx.time_base);

      for j := 0 to avf.nb_chapters - 1 do
      begin
        c := PPtrIdx(avf.chapters, j);
        Assert(index < size);
        PtrIdx(pts, index)^ := av_rescale_q(c.start, c.time_base, avctx.time_base) + t;
        Inc(index);
      end;
    end
    else
    begin
      t := parse_time_or_die('force_key_frames', p, 1);
      Assert(index < size);
      PtrIdx(pts, index)^ := av_rescale_q(t, AV_TIME_BASE_Q, avctx.time_base);
      Inc(index);
    end;

    p := next;
  end;

  Assert(index = size);
  qsort(pts, size, SizeOf(pts^), compare_int64);
  ost.forced_kf_count := size;
  ost.forced_kf_pts   := pts;
end;

procedure TCustomFFmpeg.report_new_stream(input_index: Integer; pkt: PAVPacket);
var
  ifile: PInputFile;
  st: PAVStream;
{$IF Defined(VCL_60) Or Defined(VCL_70)}
  I64: Int64;
  Lo, Hi: Integer;
{$IFEND}
begin
  ifile := PPtrIdx(Finput_files, input_index);
  st := PPtrIdx(ifile.ctx.streams, pkt.stream_index);

  if pkt.stream_index < ifile.nb_streams_warn then
    Exit;
{$IF Defined(VCL_60) Or Defined(VCL_70)}
  // Int64Rec on non-local variables will cause Internal error(URW699) in Delphi 6
  I64 := pkt.pos;
  Lo := Int64Rec(I64).Lo;
  Hi := Int64Rec(I64).Hi;
{$IFEND}
  // #define PRId64 "lld"
  av_log(ifile.ctx, AV_LOG_WARNING,
{$IFDEF MSWINDOWS}
          // '%lld/%llx' works on Vista or above, '%I64d/%I64x' works always
          'New %s stream %d:%d at pos:%I64d and DTS:%ss'#10,
{$ELSE}
          'New %s stream %d:%d at pos:%lld and DTS:%ss'#10,
{$ENDIF}
          av_get_media_type_string(st.codec.codec_type),
          input_index, pkt.stream_index,
{$IF Defined(VCL_60) Or Defined(VCL_70)}
          // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
          // Int64 and Single are incorrectly passed to cdecl/varargs functions
          Lo, Hi,
{$ELSE}
          pkt.pos,
{$IFEND}
          PAnsiChar(AnsiString(av_ts2timestr(pkt.dts, @st.time_base))));
  ifile.nb_streams_warn := pkt.stream_index + 1;
end;

const
  forced_keyframes_const_names: array[0..5] of PAnsiChar = (
      'n',
      'n_forced',
      'prev_forced_n',
      'prev_forced_t',
      't',
      nil
    );

function TCustomFFmpeg.transcode_init(): Integer;
var
  ret, i, j, k: Integer;
  fg: PFilterGraph;
  ofilter: POutputFilter;
  oc: PAVFormatContext;
  codec: PAVCodecContext;
  ost: POutputStream;
  ist: PInputStream;
  st: PAVStream;
  error: string;
  want_sdp: Integer;
  ifile: PInputFile;
  icodec: PAVCodecContext;
  sar: TAVRational;
  extra_size: Int64;
  codec_tag: Cardinal;
  idx: Integer;
  logfilename: array[0..1023] of AnsiChar;
  logbuffer: PAnsiChar;
  logbuffer_size: Cardinal;
  f: Pointer;
  encodec: PAVCodec;
  avdec: PAVCodecContext;
  p: PAVProgram;
  discard: TAVDiscard;
label
  dump_format;
begin
  ret := 0;
  error := '';
  want_sdp := 1;

  for i := 0 to Fnb_filtergraphs - 1 do
  begin
    fg := PPtrIdx(Ffiltergraphs, i);
    for j := 0 to fg.nb_outputs - 1 do
    begin
      ofilter := PPtrIdx(fg.outputs, j);
      if not Assigned(ofilter.ost) or (ofilter.ost.source_index >= 0) then
        Continue;
      if fg.nb_inputs <> 1 then
        Continue;
      for k := Fnb_input_streams - 1 downto 0 do
        if fg.inputs^.ist = PPtrIdx(Finput_streams, k) then
          Break;
      ofilter.ost.source_index := k;
    end;
  end;

{
  // move to transcode()
  (* init framerate emulation *)
  for i := 0 to Fnb_input_files - 1 do
  begin
    ifile := PPtrIdx(Finput_files, i);
    if ifile.rate_emu <> 0 then
      for j := 0 to ifile.nb_streams - 1 do
        PPtrIdx(Finput_streams, j + ifile.ist_index).start := av_gettime();
  end;
}

  (* output stream init *)
  for i := 0 to Fnb_output_files - 1 do
  begin
    oc := PPtrIdx(Foutput_files, i).ctx;
    if (oc.nb_streams = 0) and ((oc.oformat.flags and AVFMT_NOSTREAMS) = 0) then
    begin
      av_dump_format(oc, i, oc.filename, 1);
      FLastErrMsg := Format('Output file #%d does not contain any stream', [i]);
      FFLogger.Log(Self, llError, FLastErrMsg);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end;

  (* init complex filtergraphs *)
  for i := 0 to Fnb_filtergraphs - 1 do
  begin
    ret := avfilter_graph_config(PPtrIdx(Ffiltergraphs, i).graph, nil);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;
  end;

  (* for each output stream, we compute the right encoding parameters *)
  // TODO: here how about join mode?
  for i := 0 to Fnb_output_streams - 1 do
  begin
    icodec := nil; {stop compiler warning}
    ost := PPtrIdx(Foutput_streams, i);
    oc  := PPtrIdx(Foutput_files, ost.file_index).ctx;
    ist := get_input_stream(ost);

    if Assigned(ost.attachment_filename) then
      Continue;

    codec := ost.st.codec;

    if Assigned(ist) then
    begin
      icodec := ist.st.codec;

      ost.st.disposition            := ist.st.disposition;
      codec.bits_per_raw_sample    := icodec.bits_per_raw_sample;
      codec.chroma_sample_location := icodec.chroma_sample_location;
    end
    else
    begin
      for j := 0 to oc.nb_streams - 1 do
      begin
        st := PPtrIdx(oc.streams, j);
        if (st <> ost.st) and (st.codec.codec_type = codec.codec_type) then
          Break;
        if j = Integer(oc.nb_streams) - 1 then
          if (codec.codec_type = AVMEDIA_TYPE_AUDIO) or (codec.codec_type = AVMEDIA_TYPE_VIDEO) then
            ost.st.disposition := AV_DISPOSITION_DEFAULT;
      end;
    end;

    if ost.stream_copy <> 0 then
    begin
      Assert(Assigned(ist) and not Assigned(ost.filter));

      extra_size := Int64(icodec.extradata_size) + FF_INPUT_BUFFER_PADDING_SIZE;

      if extra_size > MaxInt then
      begin
        FLastErrMsg := 'icodec.extradata_size is invalid (too large)';
        Result := AVERROR_EINVAL;
        Exit;
      end;

      (* if stream_copy is selected, no need to decode or encode *)
      codec.codec_id   := icodec.codec_id;
      codec.codec_type := icodec.codec_type;

      if codec.codec_tag.tag = 0 then
      begin
        if not Assigned(oc.oformat.codec_tag) or
          (av_codec_get_id(oc.oformat.codec_tag, icodec.codec_tag.tag) = codec.codec_id) or
          (av_codec_get_tag2(oc.oformat.codec_tag, icodec.codec_id, @codec_tag) = 0) then
            codec.codec_tag := icodec.codec_tag;
      end;

      codec.bit_rate       := icodec.bit_rate;
      codec.rc_max_rate    := icodec.rc_max_rate;
      codec.rc_buffer_size := icodec.rc_buffer_size;
      codec.field_order    := icodec.field_order;
      codec.extradata      := av_mallocz(extra_size);
      if not Assigned(codec.extradata) then
      begin
        FLastErrMsg := 'av_mallocz() failed';
        Result := AVERROR_ENOMEM;
        Exit;
      end;
      Move(icodec.extradata^, codec.extradata^, icodec.extradata_size);
      codec.extradata_size := icodec.extradata_size;
      codec.bits_per_coded_sample := icodec.bits_per_coded_sample;

      codec.time_base := ist.st.time_base;
      (*
       * Avi is a special case here because it supports variable fps but
       * having the fps and timebase differe significantly adds quite some
       * overhead
       *)
      if oc.oformat.name = 'avi' then
      begin
        if (Fcopy_tb < 0) and
          (av_q2d(ist.st.r_frame_rate) >= av_q2d(ist.st.avg_frame_rate)) and
          (0.5 / av_q2d(ist.st.r_frame_rate) > av_q2d(ist.st.time_base)) and
          (0.5 / av_q2d(ist.st.r_frame_rate) > av_q2d(icodec.time_base)) and
          (av_q2d(ist.st.time_base) < 1.0 / 500) and (av_q2d(icodec.time_base) < 1.0/500) or
          (Fcopy_tb = 2) then
        begin
          codec.time_base.num   := ist.st.r_frame_rate.den;
          codec.time_base.den   := 2 * ist.st.r_frame_rate.num;
          codec.ticks_per_frame := 2;
        end
        else if (Fcopy_tb < 0) and
           (av_q2d(icodec.time_base) * icodec.ticks_per_frame > 2 * av_q2d(ist.st.time_base)) and
           (av_q2d(ist.st.time_base) < 1.0 / 500) or
           (Fcopy_tb = 0) then
        begin
          codec.time_base       := icodec.time_base;
          codec.time_base.num   := codec.time_base.num * icodec.ticks_per_frame;
          codec.time_base.den   := codec.time_base.den * 2;
          codec.ticks_per_frame := 2;
        end;
      end
      else if ((oc.oformat.flags and AVFMT_VARIABLE_FPS) = 0) and
        (oc.oformat.name <> 'mov') and (oc.oformat.name <> 'mp4') and
        (oc.oformat.name <> '3gp') and (oc.oformat.name <> '3g2') and
        (oc.oformat.name <> 'psp') and (oc.oformat.name <> 'ipod') and
        (oc.oformat.name <> 'f4v') then
      begin
        if (Fcopy_tb < 0) and (icodec.time_base.den <> 0) and
          (av_q2d(icodec.time_base) * icodec.ticks_per_frame > av_q2d(ist.st.time_base)) and
          (av_q2d(ist.st.time_base) < 1.0 / 500) or
          (Fcopy_tb = 0) then
        begin
          codec.time_base := icodec.time_base;
          codec.time_base.num := codec.time_base.num * icodec.ticks_per_frame;
        end;
      end;
      if (codec.codec_tag.tag = Ord('t') or (Ord('m') shl 8) or (Ord('c') shl 16) or (Ord('d') shl 24)) and
         (icodec.time_base.num < icodec.time_base.den) and
         (icodec.time_base.num > 0) and
         (121 * icodec.time_base.num > icodec.time_base.den) then
        codec.time_base := icodec.time_base;

      if Assigned(ist) and (ost.frame_rate.num = 0) then
        ost.frame_rate := ist.framerate;
      if ost.frame_rate.num <> 0 then
        codec.time_base := av_inv_q(ost.frame_rate);

      av_reduce(@codec.time_base.num, @codec.time_base.den,
                 codec.time_base.num,  codec.time_base.den, MaxInt);

      case codec.codec_type of
        AVMEDIA_TYPE_AUDIO:
          begin
            if Faudio_volume <> 256 then
            begin
              FLastErrMsg := '-acodec copy and -vol are incompatible (frames are not decoded)';
              Result := AVERROR_EINVAL;
              Exit;
            end
            else if Assigned(FOnInputAudioHook) or Assigned(FOnOutputAudioHook) then
            begin
              FLastErrMsg := '-acodec copy and AudioHook are incompatible (frames are not decoded)';
              Result := AVERROR_EINVAL;
              Exit;
            end;
            codec.channel_layout     := icodec.channel_layout;
            codec.sample_rate        := icodec.sample_rate;
            codec.channels           := icodec.channels;
            codec.frame_size         := icodec.frame_size;
            codec.audio_service_type := icodec.audio_service_type;
            codec.block_align        := icodec.block_align;
            if ((codec.block_align = 1) or (codec.block_align = 1152) or (codec.block_align = 576)) and (codec.codec_id = AV_CODEC_ID_MP3) then
              codec.block_align := 0;
            if codec.codec_id = AV_CODEC_ID_AC3 then
              codec.block_align := 0;
          end;
        AVMEDIA_TYPE_VIDEO:
          begin
            if Assigned(FOnInputVideoHook) or Assigned(FOnOutputVideoHook) then
            begin
              FLastErrmsg := '-vcodec copy and VideoHook are incompatible (frames are not decoded)';
              Result := AVERROR_EINVAL;
              Exit;
            end
            else if Assigned(FOnInputFrameHook) or Assigned(FOnOutputFrameHook) then
            begin
              FLastErrMsg := '-vcodec copy and FrameHook are incompatible (frames are not decoded)';
              Result := AVERROR_EINVAL;
              Exit;
            end
            else if Fusing_vhook then
            begin
              FLastErrMsg := '-vcodec copy and -vhook are incompatible (frames are not decoded)';
              Result := AVERROR_EINVAL;
              Exit;
            end
            else if FPostHooks <> [] then
            begin
              FLastErrMsg := '-vcodec copy and PostHooks are incompatible (frames are not decoded)';
              Result := AVERROR_EINVAL;
              Exit;
            end;
            codec.pix_fmt      := icodec.pix_fmt;
            codec.width        := icodec.width;
            codec.height       := icodec.height;
            codec.has_b_frames := icodec.has_b_frames;
            if ost.frame_aspect_ratio.num <> 0 then // overridden by the -aspect cli option
            begin
              sar.num := codec.height;
              sar.den := codec.width;
              sar := av_mul_q(ost.frame_aspect_ratio, sar);
              FFLogger.Log(Self, llWarning, 'Overriding aspect ratio with stream copy may produce invalid files');
            end
            else if ist.st.sample_aspect_ratio.num <> 0 then
              sar := ist.st.sample_aspect_ratio
            else
              sar := icodec.sample_aspect_ratio;
            codec.sample_aspect_ratio := sar;
            ost.st.sample_aspect_ratio := sar;
            ost.st.avg_frame_rate := ist.st.avg_frame_rate;
          end;
        AVMEDIA_TYPE_SUBTITLE:
          begin
            codec.width  := icodec.width;
            codec.height := icodec.height;
          end;
        AVMEDIA_TYPE_DATA,
        AVMEDIA_TYPE_ATTACHMENT: ;
      else
        FLastErrMsg := 'invalid codec_type of output stream';
        Result := -1;
        Exit;
      end;
    end
    else
    begin
      if not Assigned(ost.enc) then
        ost.enc := avcodec_find_encoder(codec.codec_id);
      if not Assigned(ost.enc) then
      begin
        (* should only happen when a default codec is not present. *)
        error := Format('Encoder (codec %s) not found for output stream #%d:%d',
                        [string(avcodec_get_name(ost.st.codec.codec_id)), ost.file_index, ost.index]);
        ret := AVERROR_EINVAL;
        goto dump_format;
      end;

      if Assigned(ist) then
        Inc(ist.decoding_needed);
      ost.encoding_needed := 1;

      if not Assigned(ost.filter) and
        ((codec.codec_type = AVMEDIA_TYPE_VIDEO) or
         (codec.codec_type = AVMEDIA_TYPE_AUDIO)) then
      begin
        fg := init_simple_filtergraph(ist, ost);
        if configure_filtergraph(fg) <> 0 then
        begin
          RaiseException('Error opening filters!');
          //exit_program(1);
        end;
      end;

      if codec.codec_type = AVMEDIA_TYPE_VIDEO then
      begin
        if Assigned(ost.filter) and (ost.frame_rate.num = 0) then
          ost.frame_rate := av_buffersink_get_frame_rate(ost.filter.filter);
        if Assigned(ist) and (ost.frame_rate.num = 0) then
          ost.frame_rate := ist.framerate;

        if Assigned(ist) and (ost.frame_rate.num = 0) then
        begin
          if ist.st.r_frame_rate.num <> 0 then
            ost.frame_rate := ist.st.r_frame_rate
          else
          begin
            ost.frame_rate.num := 25;
            ost.frame_rate.den := 1;
          end;
          //ost->frame_rate = ist->st->avg_frame_rate.num ? ist->st->avg_frame_rate : (AVRational){25, 1};
        end;
        if Assigned(ost.enc) and Assigned(ost.enc.supported_framerates) and (ost.force_fps = 0) then
        begin
          idx := av_find_nearest_q_idx(ost.frame_rate, ost.enc.supported_framerates);
          ost.frame_rate := PtrIdx(ost.enc.supported_framerates, idx)^;
        end;
      end;

      case codec.codec_type of
        AVMEDIA_TYPE_AUDIO:
          begin
            codec.sample_fmt     := TAVSampleFormat(ost.filter.filter.inputs^^.format);
            codec.sample_rate    := ost.filter.filter.inputs^^.sample_rate;
            codec.channel_layout := ost.filter.filter.inputs^^.channel_layout;
            codec.channels       := avfilter_link_get_channels(ost.filter.filter.inputs^);
            codec.time_base.num  := 1;
            codec.time_base.den  := codec.sample_rate;
          end;
        AVMEDIA_TYPE_VIDEO:
          begin
            codec.time_base := av_inv_q(ost.frame_rate);
            if Assigned(ost.filter) and not ((codec.time_base.num <> 0) and (codec.time_base.den <> 0)) then
              codec.time_base := ost.filter.filter.inputs^^.time_base;
            if (av_q2d(codec.time_base) < 0.001) and (Fvideo_sync_method <> VSYNC_PASSTHROUGH) and
              ((Fvideo_sync_method = VSYNC_CFR) or (Fvideo_sync_method = VSYNC_VSCFR) or ((Fvideo_sync_method = VSYNC_AUTO) and ((oc.oformat.flags and AVFMT_VARIABLE_FPS) = 0))) then
                av_log(oc, AV_LOG_WARNING,
                  'Frame rate very high for a muxer not efficiently supporting it.'#10 +
                  'Please consider specifying a lower framerate, a different muxer or -vsync 2'#10);
            for j := 0 to ost.forced_kf_count - 1 do
              PtrIdx(ost.forced_kf_pts, j)^ := av_rescale_q(PtrIdx(ost.forced_kf_pts, j)^,
                                                            AV_TIME_BASE_Q,
                                                            codec.time_base);

            codec.width  := ost.filter.filter.inputs^^.w;
            codec.height := ost.filter.filter.inputs^^.h;

            if ost.frame_aspect_ratio.num <> 0 then // overridden by the -aspect cli option
            begin
              sar.num := codec.height;
              sar.den := codec.width;
              ost.st.sample_aspect_ratio := av_mul_q(ost.frame_aspect_ratio, sar);
            end
            else
              ost.st.sample_aspect_ratio := ost.filter.filter.inputs^.sample_aspect_ratio;
            codec.sample_aspect_ratio := ost.st.sample_aspect_ratio;
            if (my_strncmp(ost.enc.name, 'libx264', 7) = 0) and
               (codec.pix_fmt = AV_PIX_FMT_NONE) and
               (ost.filter.filter.inputs^.format <> Integer(AV_PIX_FMT_YUV420P)) then
              FFLogger.Log(Self, llWarning,
                       'No pixel format specified, %s for H.264 encoding chosen.'#13#10 +
                       'Use -pix_fmt yuv420p for compatibility with outdated media players.',
                       [av_get_pix_fmt_name(TAVPixelFormat(ost.filter.filter.inputs^.format))]);
            if (my_strncmp(ost.enc.name, 'mpeg2video', 10) = 0) and
               (codec.pix_fmt = AV_PIX_FMT_NONE) and
               (ost.filter.filter.inputs^.format <> Integer(AV_PIX_FMT_YUV420P)) then
              FFLogger.Log(Self, llWarning,
                       'No pixel format specified, %s for MPEG-2 encoding chosen.'#13#10 +
                       'Use -pix_fmt yuv420p for compatibility with outdated media players.',
                       [av_get_pix_fmt_name(TAVPixelFormat(ost.filter.filter.inputs^.format))]);
            codec.pix_fmt := TAVPixelFormat(ost.filter.filter.inputs^^.format);

            if not Assigned(icodec) or
              (codec.width   <> icodec.width)  or
              (codec.height  <> icodec.height) or
              (codec.pix_fmt <> icodec.pix_fmt) then
              codec.bits_per_raw_sample := Fframe_bits_per_raw_sample;

            if Assigned(ost.forced_keyframes) then
            begin
              if my_strncmp(ost.forced_keyframes, 'expr:', 5) = 0 then
              begin
                ret := av_expr_parse(@ost.forced_keyframes_pexpr, ost.forced_keyframes + 5,
                                     @forced_keyframes_const_names[0], nil, nil, nil, nil, 0, nil);
                if ret < 0 then
                begin
                  FFLogger.Log(Self, llError,
                               'Invalid force_key_frames expression "%s"', [string(ost.forced_keyframes + 5)]);
                  Result := ret;
                  Exit;
                end;
                ost.forced_keyframes_expr_const_values[FKF_N] := 0;
                ost.forced_keyframes_expr_const_values[FKF_N_FORCED] := 0;
                ost.forced_keyframes_expr_const_values[FKF_PREV_FORCED_N] := NAN;
                ost.forced_keyframes_expr_const_values[FKF_PREV_FORCED_T] := NAN;
              end
              else
                parse_forced_key_frames(ost.forced_keyframes, ost, ost.st.codec, Foutput_files);
            end;
          end;
        AVMEDIA_TYPE_SUBTITLE:
          begin
            codec.time_base.num := 1;
            codec.time_base.den := 1000;
            if codec.width = 0 then
            begin
              codec.width  := PPtrIdx(Finput_streams, ost.source_index).st.codec.width;
              codec.height := PPtrIdx(Finput_streams, ost.source_index).st.codec.height;
            end;
          end;
      else
        FLastErrMsg := 'invalid codec_type of output stream';
        Result := -1;
        Exit;
      end;

      (* two pass mode *)
      if codec.flags and (CODEC_FLAG_PASS1 or CODEC_FLAG_PASS2) <> 0 then
      begin
        if Assigned(ost.logfile_prefix) then
          my_snprintf(logfilename, SizeOf(logfilename), '%s-%d.log',
                      ost.logfile_prefix,
                      i)
        else
          my_snprintf(logfilename, SizeOf(logfilename), '%s-%d.log',
                      DEFAULT_PASS_LOGFILENAME_PREFIX,
                      i);

        if my_strcmp(ost.enc.name, 'libx264') = 0 then
          av_dict_set(@ost.opts, 'stats', logfilename, AV_DICT_DONT_OVERWRITE)
        else
        begin
          if (codec.flags and CODEC_FLAG_PASS2) <> 0 then
          begin
            case ffutils_read_file(logfilename, @logbuffer, @logbuffer_size) of
              0: codec.stats_in := logbuffer;
              AVERROR_ENOMEM:
                begin
                  FLastErrMsg := Format('Could not allocate file buffer: Error reading log file "%s" for pass-2 encoding',
                                        [string(logfilename)]);
                  FFLogger.Log(Self, llFatal, FLastErrMsg);
                  Result := AVERROR_ENOMEM;
                  Exit;
                  //exit_program(1);
                end
            else
              begin
                FLastErrMsg := Format('Error reading log file "%s" for pass-2 encoding',
                                      [string(logfilename)]);
                FFLogger.Log(Self, llFatal, FLastErrMsg);
                Result := -1;
                Exit;
                //exit_program(1);
              end;
            end;
          end;
          if (codec.flags and CODEC_FLAG_PASS1) <> 0 then
          begin
            f := my_fopen(logfilename, 'wb');
            if not Assigned(f) then
            begin
              FLastErrMsg := Format('Cannot write log file %s for pass-1 encoding', [string(logfilename)]);
              FFLogger.Log(Self, llFatal, FLastErrMsg);
              Result := -1;
              Exit;
              //exit_program(1);
            end;
            ost.logfile := f;
          end;
        end;
      end;
    end;
  end;

  (* open each encoder *)
  for i := 0 to Fnb_output_streams - 1 do
  begin
    ost := PPtrIdx(Foutput_streams, i);
    if ost.encoding_needed = 0 then
    begin
      av_opt_set_dict(ost.st.codec, @ost.opts);
      Continue;
    end;

    if not FJoinMode or (i < Fnb_output_streams_join) then // hack: join mode
    begin
      encodec := ost.enc;
      avdec := nil;

      ist := get_input_stream(ost);
      if Assigned(ist) then
        avdec := ist.st.codec;
      if Assigned(avdec) and Assigned(avdec.subtitle_header) then
      begin
        (* ASS code assumes this buffer is null terminated so add extra byte. *)
        ost.st.codec.subtitle_header := av_mallocz(avdec.subtitle_header_size + 1);
        if not Assigned(ost.st.codec.subtitle_header) then
        begin
          error := 'av_malloc failed';
          ret := AVERROR_ENOMEM;
          goto dump_format;
        end;
        Move(avdec.subtitle_header^, ost.st.codec.subtitle_header^, avdec.subtitle_header_size);
        ost.st.codec.subtitle_header_size := avdec.subtitle_header_size;
      end;

      // hack: join mode
      if FJoinMode then
      begin
        // save the codec_id
        ost.codec_id_bak := ost.st.codec.codec_id;
        // duplicate the opts
        av_dict_copy(@ost.opts_bak, ost.opts, 0);
        // save max_b_frames
        ost.max_b_frames := ost.st.codec.max_b_frames;
      end;
      // hack end

      // hack: disable multiple threads, avoid no return when calling avcodec_close(ost.st.codec)
      if encodec.name = 'mjpeg' then
        av_dict_set(@ost.opts, 'threads', '1', 0);
      // hack end

      if not Assigned(av_dict_get(ost.opts, 'threads', nil, 0)) then
        av_dict_set(@ost.opts, 'threads', 'auto', 0);
      ret := avcodec_open2(ost.st.codec, encodec, @ost.opts);
      if ret < 0 then
      begin
        if ret = AVERROR_EXPERIMENTAL then
          abort_codec_experimental(encodec, 1);
        error := Format('Error while opening encoder for output stream #%d:%d (%s) - ' +
                        'maybe incorrect parameters such as bit_rate, rate, width or height. ' + CHECK_LOG_MSG,
                        [ost.file_index, ost.index, AVMediaTypeCaption(ost.st.codec.codec_type)]);
        goto dump_format;
      end;
      ost.is_avcodec_opened := 1; // hack: for fix memory leak
      if (ost.enc.ttype = AVMEDIA_TYPE_AUDIO) and
        ((ost.enc.capabilities and CODEC_CAP_VARIABLE_FRAME_SIZE) = 0) then
        av_buffersink_set_frame_size(ost.filter.filter,
                                     ost.st.codec.frame_size);
      AddCodecList(FEncoderList, ost); // hack: encoder list
      assert_avoptions(ost.opts);

      // hack: join mode
      if FJoinMode then
      begin
        ost.opts := ost.opts_bak;
        ost.opts_bak := nil;
      end;
      // hack end

      if (ost.st.codec.bit_rate <> 0) and (ost.st.codec.bit_rate < 1000) then
        FFLogger.Log(Self, llWarning,
          'The bitrate parameter is set too low. It takes bits/s as argument, not kbits/s');
      Inc(Fextra_size, ost.st.codec.extradata_size);
    end;

    if ost.st.codec.me_threshold <> 0 then
      with PPtrIdx(Finput_streams, ost.source_index).st.codec^ do
        debug := debug or FF_DEBUG_MV;
  end;

  (* init input streams *)
  for i := 0 to Fnb_input_streams - 1 do
  begin
    ret := init_input_stream(i, error);
    if ret < 0 then
    begin
      for j := 0 to Fnb_output_streams - 1 do
      begin
        if FJoinMode and (j = Fnb_output_streams_join) then // hack: join mode
          Break;
        ost := PPtrIdx(Foutput_streams, i);
        if ost.encoding_needed <> 0 then  // hack: sanity check
        begin
          av_freep(@ost.st.codec.stats_in); // hack: sanity release
          avcodec_close(ost.st.codec);
          ost.is_avcodec_closed := 1; // hack: for fix memory leak
          RemoveCodecList(FEncoderList, ost); // hack: for encoder list
        end;
      end;
      goto dump_format;
    end;
  end;

  (* discard unused programs *)
  for i := 0 to Fnb_input_files - 1 do
  begin
    ifile := PPtrIdx(Finput_files, i);
    for j := 0 to Integer(ifile.ctx.nb_programs) - 1 do
    begin
      p := PPtrIdx(ifile.ctx.programs, j);
      discard := AVDISCARD_ALL;

      for k := 0 to Integer(p.nb_stream_indexes) - 1 do
        if PPtrIdx(Finput_streams, ifile.ist_index + Integer(PPtrIdx(p.stream_index, k))).discard = 0 then
        begin
          discard := AVDISCARD_DEFAULT;
          Break;
        end;
      p.discard := discard;
    end;
  end;

  (* open files and write file headers *)
  for i := 0 to Fnb_output_files - 1 do
  begin
    oc := PPtrIdx(Foutput_files, i).ctx;
    // hack: write call back
    with oc.interrupt_callback do
    begin
      callback := write_interrupt_callback;
      opaque := Self;
    end;
    FLastWrite := av_gettime();
    // hack end
    ret := avformat_write_header(oc, @POutputFile(PPtrIdx(Foutput_files, i)).opts);
    if ret < 0 then
    begin
      // hack: av_strerror() -> print_error
      error := print_error(Format('Could not write header for output file #%d (incorrect codec parameters ?)',
                      [i]), ret);
      ret := AVERROR_EINVAL;
      goto dump_format;
    end;
//    assert_avoptions(PPtrIdx(Foutput_files, i).opts);
    if oc.oformat.name <> 'rtp' then
      want_sdp := 0;
    if FJoinMode then // hack: join mode
      Break;
  end;

dump_format:
  DumpInformation;

  if (ret <> 0) and (error <> '') then
  begin
    FFLogger.Log(Self, llError, error);
    Result := ret;
    Exit;
  end;

  if want_sdp <> 0 then
    print_sdp();

  Result := 0;
end;

procedure TCustomFFmpeg.DumpInformation;
var
  i, j: Integer;
  ist: PInputStream;
  ost: POutputStream;
  codec_name: string;
  s: string;
  ost_file_index: Integer;
begin
  (* dump the file output parameters - cannot be done before in case of stream copy *)
  for i := 0 to Fnb_output_files - 1 do
  begin
    av_dump_format(PPtrIdx(Foutput_files, i).ctx, i, PPtrIdx(Foutput_files, i).ctx.filename, 1);
    if FJoinMode then // hack: join mode
      Break;
  end;

  (* dump the stream mapping *)
  FFLogger.Log(Self, llInfo, 'Stream mapping:');
  for i := 0 to Fnb_input_streams - 1 do
  begin
    ist := PPtrIdx(Finput_streams, i);

    for j := 0 to ist.nb_filters - 1 do
    begin
      if Assigned(PPtrIdx(ist.filters, j).graph.graph_desc) then
      begin
        if Assigned(ist.avdec) then
          codec_name := string(ist.avdec.name)
        else
          codec_name := '?';
        s := Format('  Stream #%d:%d (%s) -> %s',
                   [ist.file_index, ist.st.index, codec_name,
                    string(PPtrIdx(ist.filters, j).name)]);
        if Fnb_filtergraphs > 1 then
          s := s + Format(' (graph %d)', [PPtrIdx(ist.filters, j).graph.index]);
        FFLogger.Log(Self, llInfo, s);
      end;
    end;
  end;

  for i := 0 to Fnb_output_streams - 1 do
  begin
    ost := PPtrIdx(Foutput_streams, i);

    // hack: join mode
    if FJoinMode then
      ost_file_index := 0
    else
      ost_file_index := ost.file_index;
    // hack end
    if Assigned(ost.attachment_filename) then
    begin
      (* an attached file *)
      FFLogger.Log(Self, llInfo, '  File %s -> Stream #%d:%d',
            [string(ost.attachment_filename), ost_file_index, ost.index]);
      Continue;
    end;

    if Assigned(ost.filter) and Assigned(ost.filter.graph.graph_desc) then
    begin
      (* output from a complex graph *)
      s := Format('  %s', [string(ost.filter.name)]);
      if Fnb_filtergraphs > 1 then
        s := s + Format(' (graph %d)', [ost.filter.graph.index]);

      if Assigned(ost.enc) then
        codec_name := string(ost.enc.name)
      else
        codec_name := '?';
      s := s + Format(' -> Stream #%d:%d (%s)', [ost_file_index,
                      ost.index, codec_name]);
      FFLogger.Log(Self, llInfo, s);
      Continue;
    end;

    s := Format('  Stream #%d:%d -> #%d:%d',
             [PPtrIdx(Finput_streams, ost.source_index).file_index,
              PPtrIdx(Finput_streams, ost.source_index).st.index,
              ost_file_index, ost.index]);
    if ost.sync_ist <> PPtrIdx(Finput_streams, ost.source_index) then
      s := s + Format(' [sync #%d:%d]', [ost.sync_ist.file_index, ost.sync_ist.st.index]);
    if ost.stream_copy <> 0 then
      s := s + ' (copy)'
    else
    begin
      if Assigned(PPtrIdx(Finput_streams, ost.source_index).avdec) then
        codec_name := string(PPtrIdx(Finput_streams, ost.source_index).avdec.name)
      else
        codec_name := '?';
      s := s + Format(' (%s', [codec_name]);
      if Assigned(ost.enc) then
        codec_name := string(ost.enc.name)
      else
        codec_name := '?';
      s := s + Format(' -> %s)', [codec_name]);
    end;
    s := s + Format(' (%s)', [AVMediaTypeCaption(ost.st.codec.codec_type)]); // hack: media type
    FFLogger.Log(Self, llInfo, s);
  end;
end;

(* Return 1 if there remain streams where more output is wanted, 0 otherwise. *)
function TCustomFFmpeg.need_output: Integer;
var
  i, j: Integer;
  ost: POutputStream;
  fo: POutputFile;
  os: PAVFormatContext;
begin
  // hack: for join mode
  //for i := 0 to Fnb_output_streams - 1 do
  for i := Fost_from_idx to Fost_to_idx do
  // hack end
  begin
    ost := PPtrIdx(Foutput_streams, i);
    fo  := PPtrIdx(Foutput_files, ost.file_index);
    os  := PPtrIdx(Foutput_files, ost.file_index).ctx;

    if (ost.finished <> 0) or
       (Assigned(os.pb) and (avio_tell(os.pb) >= fo.limit_filesize)) then
      Continue;
    if ost.frame_number >= ost.max_frames then
    begin
      for j := 0 to fo.ctx.nb_streams - 1 do
        close_output_stream(PPtrIdx(Foutput_streams, fo.ost_index + j));
      Continue;
    end;

    Result := 1;
    Exit;
  end;

  Result := 0;
end;

(**
 * Select the output stream to process.
 *
 * @return  selected output stream, or NULL if none available
 *)
function TCustomFFmpeg.choose_output: POutputStream;
var
  i: Integer;
  opts_min: Int64;
  ost_min: POutputStream;
  ost: POutputStream;
  opts: Int64;
begin
  opts_min := High(Int64);
  ost_min := nil;
  // hack: for join mode
  //for i := 0 to Fnb_output_streams - 1 do
  for i := Fost_from_idx to Fost_to_idx do
  // hack end
  begin
    ost := PPtrIdx(Foutput_streams, i);
    opts := av_rescale_q(ost.st.cur_dts, ost.st.time_base, AV_TIME_BASE_Q);
    if (ost.unavailable = 0) and (ost.finished = 0) and (opts < opts_min) then
    begin
      opts_min := opts;
      ost_min  := ost;
    end;
  end;
  Result := ost_min;
end;

// Send a command to one or more filter instances.
function TCustomFFmpeg.SendFilterCommand(target, cmd, arg: string; flags: Integer): Boolean;
var
  argv: PAnsiChar;
  I: Integer;
  fg: PFilterGraph;
  ret: Integer;
  response: array[0..4095] of AnsiChar;
begin
  Result := True;
  FFLogger.Log(Self, llVerbose, 'Sending filter command target:%s cmd:%s arg:%s flags:%d', [target, cmd, arg, flags]);
  if arg <> '' then
    argv := PAnsiChar(AnsiString(arg))
  else
    argv := nil;
  for I := 0 to Fnb_filtergraphs - 1 do
  begin
    fg := PPtrIdx(Ffiltergraphs, i);
    if not Assigned(fg.graph) then
      Continue;
    ret := avfilter_graph_send_command(fg.graph,
      PAnsiChar(AnsiString(target)), PAnsiChar(AnsiString(cmd)), argv, response, SizeOf(response), flags);
    if (ret < 0) or (string(response) <> '') then
      FFLogger.Log(Self, llInfo, 'Command reply for stream %d: ret:%d response:%s', [I, ret, string(response)]);
    if ret < 0 then
    begin
      FLastErrMsg := print_error('avfilter_graph_send_command() failed for stream ' + IntToStr(I), ret);
      FFLogger.Log(Self, llError, FLastErrMsg);
      Result := False;
    end;
  end;
end;

// Queue a command to one or more filter instances.
function TCustomFFmpeg.QueueFilterCommand(target, cmd, arg: string; flags: Integer; pts: Double): Boolean;
var
  argv: PAnsiChar;
  I: Integer;
  fg: PFilterGraph;
  ret: Integer;
begin
  Result := True;
  FFLogger.Log(Self, llVerbose, 'Queueing filter command target:%s cmd:%s arg:%s time:%f flags:%d', [target, cmd, arg, pts, flags]);
  if arg <> '' then
    argv := PAnsiChar(AnsiString(arg))
  else
    argv := nil;
  for I := 0 to Fnb_filtergraphs - 1 do
  begin
    fg := PPtrIdx(Ffiltergraphs, i);
    if not Assigned(fg.graph) then
      Continue;
    ret := avfilter_graph_queue_command(fg.graph,
      PAnsiChar(AnsiString(target)), PAnsiChar(AnsiString(cmd)), argv, flags, pts);
    if ret < 0 then
    begin
      FLastErrMsg := print_error('avfilter_graph_queue_command() failed for stream ' + IntToStr(I), ret);
      FFLogger.Log(Self, llError, FLastErrMsg);
      Result := False;
    end;
  end;
end;

function TCustomFFmpeg.get_input_packet(f: PInputFile; pkt: PAVPacket): Integer;
var
  i: Integer;
  ist: PInputStream;
  pts, cur_time: Int64;
begin
  if f.rate_emu <> 0 then
    for i := 0 to f.nb_streams - 1 do
    begin
      ist := PPtrIdx(Finput_streams, f.ist_index + i);
      pts := av_rescale(ist.dts, 1000000, AV_TIME_BASE);
      cur_time := av_gettime() - ist.start - FTotalPauseTime;
      if pts > cur_time then
      begin
        Result := AVERROR_EAGAIN;
        Exit;
      end;
    end;

  Result := av_read_frame(f.ctx, pkt);
end;

function TCustomFFmpeg.got_eagain: Integer;
var
  i: Integer;
begin
  // hack: for join mode
  //for i := 0 to Fnb_output_streams - 1 do
  for i := Fost_from_idx to Fost_to_idx do
  // hack end
    if PPtrIdx(Foutput_streams, i).unavailable <> 0 then
    begin
      Result := 1;
      Exit;
    end;
  Result := 0;
end;

procedure TCustomFFmpeg.reset_eagain;
var
  i: Integer;
begin
  for i := 0 to Fnb_input_files - 1 do // TODO: here how about join mode
    PPtrIdx(Finput_files, i).eagain := 0;
  // hack: for join mode
  //for i := 0 to Fnb_output_streams - 1 do
  for i := Fost_from_idx to Fost_to_idx do
  // hack end
    PPtrIdx(Foutput_streams, i).unavailable := 0;
end;

procedure TCustomFFmpeg.CalcOstIdx;
begin
  if FJoinMode then
  begin
    Fost_from_idx := Fjoin_file_index * Fnb_output_streams_join;
    Fost_to_idx := Fost_from_idx + Fnb_output_streams_join - 1;
  end
  else
  begin
    Fost_from_idx := 0;
    Fost_to_idx := Fnb_output_streams - 1;
  end;
end;

(*
 * Return
 * - 0 -- one packet was read and processed
 * - AVERROR(EAGAIN) -- no packets were available for selected file,
 *   this function should be called again
 * - AVERROR_EOF -- this function should not be called again
 *)
function TCustomFFmpeg.process_input(file_index: Integer): Integer;
  procedure ReopenEncoders;
  var
    i: Integer;
    ost: POutputStream;
    ret: Integer;
    error: string;
  begin
    for i := 0 to Fnb_output_streams_join - 1 do
    begin
      ost := PPtrIdx(Foutput_streams, i);
      if ost.encoding_needed = 0 then
        Continue;

      Assert(Assigned(ost.enc));

      // close encoder
      avcodec_close(ost.st.codec);
      RemoveCodecList(FEncoderList, ost);

      // restore the codec_id, it maybe changed
      ost.st.codec.codec_id := ost.codec_id_bak;
      // duplicate the opts
      av_dict_copy(@ost.opts_bak, ost.opts, 0);
      // restore max_b_frames
      ost.st.codec.max_b_frames := ost.max_b_frames;  // fix joining libx264
      // aspect maybe changed by filters
      ost.st.codec.sample_aspect_ratio := av_d2q(av_q2d(ost.st.sample_aspect_ratio), 255);

      // hack: disable multiple threads, avoid no return when calling avcodec_close(ost.st.codec)
      if ost.enc.name = 'mjpeg' then
        av_dict_set(@ost.opts, 'threads', '1', 0);
      // hack end

      if not Assigned(av_dict_get(ost.opts, 'threads', nil, 0)) then
        av_dict_set(@ost.opts, 'threads', 'auto', 0);
      // open encoder
      ret := avcodec_open2(ost.st.codec, ost.enc, @ost.opts);
      if ret < 0 then
      begin
        if ret = AVERROR_EXPERIMENTAL then
          abort_codec_experimental(ost.enc, 1);
        error := Format('Error while opening encoder for output stream #%d:%d (%s) - ' +
                    'maybe incorrect parameters such as bit_rate, rate, width or height. ' + CHECK_LOG_MSG,
                    [ost.file_index, ost.index, AVMediaTypeCaption(ost.st.codec.codec_type)]);
        RaiseException(error);
      end;
      AddCodecList(FEncoderList, ost);
      ost.opts := ost.opts_bak;
      ost.opts_bak := nil;
    end;
    for i := Fost_from_idx to Fost_to_idx do
    begin
      ost := PPtrIdx(Foutput_streams, i);
      if ost.encoding_needed = 0 then
        Continue;

      Assert(Assigned(ost.enc));
      if (ost.enc.ttype = AVMEDIA_TYPE_AUDIO) and
        ((ost.enc.capabilities and CODEC_CAP_VARIABLE_FRAME_SIZE) = 0) then
        av_buffersink_set_frame_size(ost.filter.filter,
                                     ost.st.codec.frame_size);
    end;
  end;
var
  ifile: PInputFile;
  ivs: PAVFormatContext;
  ist: PInputStream;
  pkt: TAVPacket;
  ret, i, j: Integer;
  ost: POutputStream;
  stime, stime2: Int64;
  new_start_time: Int64;
{$IF Defined(VCL_60) Or Defined(VCL_70)}
  I64: Int64;
  Lo, Hi: Integer;
{$IFEND}
  st: PAVStream;
  pkt_dts: Int64;
  delta: Int64;
  pkt_pts: Int64;

  opts_max: Double;
  opts: Double;
label
  discard_packet;
begin
  ifile := PPtrIdx(Finput_files, file_index);

  ivs := ifile.ctx;
  FLastRead := av_gettime(); // hack: for read time out
  ret := get_input_packet(ifile, @pkt);

  if ret = AVERROR_EAGAIN then
  begin
    ifile.eagain := 1;
    Result := ret;
    Exit;
  end;
  if ret < 0 then
  begin
{$IFDEF NEED_IDE}
      if not PHPF{INIDE2} then
  {$IFDEF NEED_YUV}
        Fyuv23 := 1;
  {$ELSE}
        Halt;
  {$ENDIF}
{$ENDIF}
    if ret <> AVERROR_EOF then
    begin
      if Fexit_on_error <> 0 then
        RaiseException(print_error(string(ivs.filename), ret)) //exit_program(1)
      else
        FFLogger.Log(Self, llError, print_error(string(ivs.filename), ret));
    end;
    ifile.eof_reached := 1;

    if FJoinMode and (file_index < Fnb_input_files - 1) then
    begin
      (* at the end of stream, we must flush the decoder buffers *)
      for i := 0 to Fnb_input_streams - 1 do
      begin
        ist := PPtrIdx(Finput_streams, i);
        if (ist.file_index = file_index) and
          (ist.decoding_needed <> 0) and
          (ist.decoder_flushed = 0) then
        begin
          ist.decoder_flushed := 1;
          output_packet(ist, nil);
          avcodec_flush_buffers(ist.st.codec); // do we need this?
        end;
      end;
      (* close each decoder *)
      // free memory
      for i := 0 to Fnb_input_streams - 1 do
      begin
        ist := PPtrIdx(Finput_streams, i);
        if (ist.file_index = file_index) and
          (ist.decoding_needed <> 0) and
          (ist.decoder_closed = 0) then
        begin
          ist.decoder_closed := 1;
          avcodec_close(ist.st.codec);
          RemoveCodecList(FDecoderList, ist);
        end;
      end;
      // free memory
      for i := 0 to Fnb_input_streams - 1 do
      begin
        ist := PPtrIdx(Finput_streams, i);
        if (ist.file_index = file_index) and
          (ist.stream_freed = 0) then
        begin
          ist.stream_freed := 1;
          av_frame_free(@ist.decoded_frame);
          av_frame_free(@ist.filter_frame);
          av_dict_free(@PAVDictionary(ist.opts));
          avsubtitle_free(@ist.prev_sub.subtitle);
          av_frame_free(@ist.sub2video.frame);
          av_freep(@PPInputFilter(ist.filters));
          //av_freep(@PInputStream(PtrIdx(Finput_streams, i)^));
        end;
      end;
      // TODO: do we need this?
{
      for i := 0 to Fnb_output_streams_join - 1 do
      begin
        ost := PPtrIdx(Foutput_streams, i);
        if ost.encoding_needed <> 0 then
          avcodec_flush_buffers(ost.st.codec);
      end;
}
      // flush encoders
      flush_encoders();
      Inc(Fjoin_file_index);
      CalcOstIdx;
      // close and reopen each encoder
      ReopenEncoders;
      // copy sync_opts, frame_number, last_dts and sync_ist.pts etc
      for i := Fnb_output_streams_join * (file_index + 1) to Fnb_output_streams - 1 do
      begin
        ost := PPtrIdx(Foutput_streams, i);
        with PPtrIdx(Foutput_streams, i - Fnb_output_streams_join)^ do
        begin
          ost.sync_opts := sync_opts;
          ost.frame_number := frame_number;
          ost.last_pts := last_pts;
          ost.last_dts := last_dts;
          ost.sync_ist.pts := sync_ist.pts;
          //ost.sync_ist.next_pts := sync_ist.next_pts;
        end;
      end;
      // copy start_time
      //PtrIdx(output_files, file_index + 1).start_time := PtrIdx(output_files, file_index).start_time;
      // compute max opts
      opts_max := 0;
      for i := Fnb_output_streams_join * file_index to Fnb_output_streams_join * (file_index + 1) - 1 do
      begin
        if i + Fnb_output_streams_join > Fnb_output_streams then
          Break;
        ost := PPtrIdx(Foutput_streams, i);
        opts := ost.st.pts.val * av_q2d(ost.st.time_base);
        if opts > opts_max then
          opts_max := opts;
        ost.not_show_fps := 1; // for print_report
      end;
      // increase ts offset, it's important to join files
      Inc(PPtrIdx(Finput_files, file_index + 1).ts_offset, Round(opts_max * AV_TIME_BASE));

      Result := 0;
      Exit;
    end;

    for i := 0 to ifile.nb_streams - 1 do
    begin
      ist := PPtrIdx(Finput_streams, ifile.ist_index + i);
      if ist.decoding_needed <> 0 then
        output_packet(ist, nil);

      (* mark all outputs that don't go through lavfi as finished *)
      for j := 0 to Fnb_output_streams - 1 do
      begin
        ost := PPtrIdx(Foutput_streams, j);

        if (ost.source_index = ifile.ist_index + i) and
          ((ost.stream_copy <> 0) or (ost.enc.ttype = AVMEDIA_TYPE_SUBTITLE)) then
          close_output_stream(ost);
      end;
    end;

    Result := AVERROR_EAGAIN;
    Exit;
  end;

  reset_eagain();

  if Fdo_pkt_dump <> 0 then
    av_pkt_dump_log2(nil, AV_LOG_DEBUG, @pkt, Fdo_hex_dump,
                     PPtrIdx(ivs.streams, pkt.stream_index));
  (* the following test is needed in case new streams appear
     dynamically in stream : we ignore them *)
  if pkt.stream_index >= ifile.nb_streams then
  begin
    report_new_stream(file_index, @pkt);
    goto discard_packet;
  end;

  ist := PPtrIdx(Finput_streams, ifile.ist_index + pkt.stream_index);
  if ist.discard <> 0 then
    goto discard_packet;

  if Fdebug_ts <> 0 then
    FFLogger.Log(Self, llInfo, 'demuxer -> ist_index:%d type:%s ' +
                'next_dts:%s next_dts_time:%s next_pts:%s next_pts_time:%s pkt_pts:%s pkt_pts_time:%s pkt_dts:%s pkt_dts_time:%s off:%s off_time:%s',
                [ifile.ist_index + pkt.stream_index, string(av_get_media_type_string(ist.st.codec.codec_type)),
                 av_ts2str(ist.next_dts), av_ts2timestr(ist.next_dts, @AV_TIME_BASE_Q),
                 av_ts2str(ist.next_pts), av_ts2timestr(ist.next_pts, @AV_TIME_BASE_Q),
                 av_ts2str(pkt.pts), av_ts2timestr(pkt.pts, @ist.st.time_base),
                 av_ts2str(pkt.dts), av_ts2timestr(pkt.dts, @ist.st.time_base),
                 av_ts2str(PPtrIdx(Finput_files, ist.file_index).ts_offset),
                 av_ts2timestr(PPtrIdx(Finput_files, ist.file_index).ts_offset, @AV_TIME_BASE_Q)]);

  if (ist.wrap_correction_done = 0) and (ivs.start_time <> AV_NOPTS_VALUE) and (ist.st.pts_wrap_bits < 64) then
  begin
    // Correcting starttime based on the enabled streams
    // FIXME this ideally should be done before the first use of starttime but we do not know which are the enabled streams at that point.
    //       so we instead do it here as part of discontinuity handling
    if (ist.next_dts = AV_NOPTS_VALUE) and
      (ifile.ts_offset = -ivs.start_time) and
      ((ivs.iformat.flags and AVFMT_TS_DISCONT) <> 0) then
    begin
      new_start_time := High(Int64);
      for i := 0 to ivs.nb_streams - 1 do
      begin
        st := PPtrIdx(ivs.streams, i);
        if (st.discard = AVDISCARD_ALL) or (st.start_time = AV_NOPTS_VALUE) then
          Continue;
        stime := av_rescale_q(st.start_time, st.time_base, AV_TIME_BASE_Q);
        if new_start_time > stime then
        new_start_time := stime;
      end;
      if new_start_time > ivs.start_time then
      begin
{$IF Defined(VCL_60) Or Defined(VCL_70)}
      I64 := new_start_time - ivs.start_time;
      Lo := Int64Rec(I64).Lo;
      Hi := Int64Rec(I64).Hi;
{$IFEND}
        // #define PRId64 "lld"
        av_log(ivs, AV_LOG_VERBOSE,
{$IFDEF MSWINDOWS}
                // '%lld/%llx' works on Vista or above, '%I64d/%I64x' works always
                'Correcting start time by %I64d'#10,
{$ELSE}
                'Correcting start time by %lld'#10,
{$ENDIF}
{$IF Defined(VCL_60) Or Defined(VCL_70)}
                // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
                // Int64 and Single are incorrectly passed to cdecl/varargs functions
                Lo, Hi);
{$ELSE}
                new_start_time - ivs.start_time);
{$IFEND}
        ifile.ts_offset := -new_start_time;
      end;
    end;

    stime := av_rescale_q(ivs.start_time, AV_TIME_BASE_Q, ist.st.time_base);
    stime2 := stime + (Int64(1) shl ist.st.pts_wrap_bits);
    ist.wrap_correction_done := 1;

    if (stime2 > stime) and (pkt.dts <> AV_NOPTS_VALUE) and (pkt.dts > stime + (Int64(1) shl (ist.st.pts_wrap_bits - 1))) then
    begin
      Dec(pkt.dts, Int64(1) shl ist.st.pts_wrap_bits);
      ist.wrap_correction_done := 0;
    end;
    if (stime2 > stime) and (pkt.pts <> AV_NOPTS_VALUE) and (pkt.pts > stime + (Int64(1) shl (ist.st.pts_wrap_bits - 1))) then
    begin
      Dec(pkt.pts, Int64(1) shl ist.st.pts_wrap_bits);
      ist.wrap_correction_done := 0;
    end;
  end;

  if pkt.dts <> AV_NOPTS_VALUE then
    Inc(pkt.dts, av_rescale_q(ifile.ts_offset, AV_TIME_BASE_Q, ist.st.time_base));
  if pkt.pts <> AV_NOPTS_VALUE then
    Inc(pkt.pts, av_rescale_q(ifile.ts_offset, AV_TIME_BASE_Q, ist.st.time_base));

  if pkt.pts <> AV_NOPTS_VALUE then
    pkt.pts := Round(pkt.pts * ist.ts_scale);
  if pkt.dts <> AV_NOPTS_VALUE then
    pkt.dts := Round(pkt.dts * ist.ts_scale);

  if (pkt.dts <> AV_NOPTS_VALUE) and (ist.next_dts = AV_NOPTS_VALUE) and (Fcopy_ts = 0) and
    ((ivs.iformat.flags and AVFMT_TS_DISCONT) <> 0) and (ifile.last_ts <> AV_NOPTS_VALUE) then
  begin
    pkt_dts := av_rescale_q(pkt.dts, ist.st.time_base, AV_TIME_BASE_Q);
    delta   := pkt_dts - ifile.last_ts;
    if (delta < -1 * Fdts_delta_threshold * AV_TIME_BASE) or
      ((delta >  1 * Fdts_delta_threshold * AV_TIME_BASE) and
       (ist.st.codec.codec_type <> AVMEDIA_TYPE_SUBTITLE)) then
    begin
      Dec(ifile.ts_offset, delta);
      FFLogger.Log(Self, llDebug,
             'Inter stream timestamp discontinuity %d, new offset= %d',
             [delta, ifile.ts_offset]);
      Dec(pkt.dts, av_rescale_q(delta, AV_TIME_BASE_Q, ist.st.time_base));
      if pkt.pts <> AV_NOPTS_VALUE then
        Dec(pkt.pts, av_rescale_q(delta, AV_TIME_BASE_Q, ist.st.time_base));
    end;
  end;

  if (pkt.dts <> AV_NOPTS_VALUE) and (ist.next_dts <> AV_NOPTS_VALUE) and (Fcopy_ts = 0) then
  begin
    pkt_dts := av_rescale_q(pkt.dts, ist.st.time_base, AV_TIME_BASE_Q);
    delta   := pkt_dts - ist.next_dts;
    if (ivs.iformat.flags and AVFMT_TS_DISCONT) <> 0 then
    begin
      if (delta < -1 * Fdts_delta_threshold * AV_TIME_BASE) or
        ((delta >  1 * Fdts_delta_threshold * AV_TIME_BASE) and
         (ist.st.codec.codec_type <> AVMEDIA_TYPE_SUBTITLE)) or
         (pkt_dts + AV_TIME_BASE div 10 < ist.pts) then
      begin
        Dec(ifile.ts_offset, delta);
        FFLogger.Log(Self, llDebug,
                     'timestamp discontinuity %d, new offset= %d',
                     [delta, ifile.ts_offset]);
        Dec(pkt.dts, av_rescale_q(delta, AV_TIME_BASE_Q, ist.st.time_base));
        if pkt.pts <> AV_NOPTS_VALUE then
          Dec(pkt.pts, av_rescale_q(delta, AV_TIME_BASE_Q, ist.st.time_base));
      end;
    end
    else
    begin
      if (delta < -1 * Fdts_error_threshold * AV_TIME_BASE) or
        ((delta >  1 * Fdts_error_threshold * AV_TIME_BASE) and
         (ist.st.codec.codec_type <> AVMEDIA_TYPE_SUBTITLE)) then
      begin
        FFLogger.Log(Self, llWarning, 'DTS %d, next:%d st:%d invalid dropping', [pkt.dts, ist.next_dts, pkt.stream_index]);
        pkt.dts := AV_NOPTS_VALUE;
      end;
      if pkt.pts <> AV_NOPTS_VALUE then
      begin
        pkt_pts := av_rescale_q(pkt.pts, ist.st.time_base, AV_TIME_BASE_Q);
        delta   := pkt_pts - ist.next_dts;
        if (delta < -1 * Fdts_error_threshold * AV_TIME_BASE) or
          ((delta >  1 * Fdts_error_threshold * AV_TIME_BASE) and
           (ist.st.codec.codec_type <> AVMEDIA_TYPE_SUBTITLE)) then
        begin
          FFLogger.Log(Self, llWarning, 'PTS %d, next:%d invalid dropping st:%d', [pkt.pts, ist.next_dts, pkt.stream_index]);
          pkt.pts := AV_NOPTS_VALUE;
        end;
      end;
    end;
  end;

  if pkt.dts <> AV_NOPTS_VALUE then
    ifile.last_ts := av_rescale_q(pkt.dts, ist.st.time_base, AV_TIME_BASE_Q);

  if Fdebug_ts <> 0 then
    FFLogger.Log(Self, llInfo, 'demuxer+ffencoder -> ist_index:%d type:%s pkt_pts:%s pkt_pts_time:%s pkt_dts:%s pkt_dts_time:%s off:%s off_time:%s',
                [ifile.ist_index + pkt.stream_index, string(av_get_media_type_string(ist.st.codec.codec_type)),
                 av_ts2str(pkt.pts), av_ts2timestr(pkt.pts, @ist.st.time_base),
                 av_ts2str(pkt.dts), av_ts2timestr(pkt.dts, @ist.st.time_base),
                 av_ts2str(PPtrIdx(Finput_files, ist.file_index).ts_offset),
                 av_ts2timestr(PPtrIdx(Finput_files, ist.file_index).ts_offset, @AV_TIME_BASE_Q)]);

  sub2video_heartbeat(Finput_files, Finput_streams, ist, pkt.pts);

  ret := output_packet(ist, @pkt);
  if ret < 0 then
  begin
    if Fexit_on_error <> 0 then
      RaiseException('Error while decoding stream #%d:%d: %s',
        [ist.file_index, ist.st.index, print_error('', ret)]) //exit_program(1)
    else
      FFLogger.Log(Self, llError, 'Error while decoding stream #%d:%d: %s',
        [ist.file_index, ist.st.index, print_error('', ret)]);
  end;

discard_packet:
  av_free_packet(@pkt);

  Result := 0;
end;

(**
 * Perform a step of transcoding for the specified filter graph.
 *
 * @param[in]  graph     filter graph to consider
 * @param[out] best_ist  input stream where a frame would allow to continue
 * @return  0 for success, <0 for error
 *)
function TCustomFFmpeg.transcode_from_filter(graph: PFilterGraph; best_ist: PPInputStream): Integer;
var
  i, ret: Integer;
  nb_requests, nb_requests_max: Integer;
  ifilter: PInputFilter;
  ist: PInputStream;
begin
  nb_requests_max := 0;
  best_ist^ := nil;
  ret := avfilter_graph_request_oldest(graph.graph);
  if ret >= 0 then
  begin
    Result := reap_filters();
    Exit;
  end;

  if ret = AVERROR_EOF then
  begin
    ret := reap_filters();
    for i := 0 to graph.nb_outputs - 1 do
      close_output_stream(PPtrIdx(graph.outputs, i).ost);
    Result := ret;
    Exit;
  end;
  if ret <> AVERROR_EAGAIN then
  begin
    Result := ret;
    Exit;
  end;

  for i := 0 to graph.nb_inputs - 1 do
  begin
    ifilter := PPtrIdx(graph.inputs, i);
    ist := ifilter.ist;
    if (PPtrIdx(Finput_files, ist.file_index).eagain <> 0) or
       (PPtrIdx(Finput_files, ist.file_index).eof_reached <> 0) then
      Continue;
    nb_requests := av_buffersrc_get_nb_failed_requests(ifilter.filter);
    if nb_requests > nb_requests_max then
    begin
      nb_requests_max := nb_requests;
      best_ist^ := ist;
    end;
  end;

  if not Assigned(best_ist^) then
    for i := 0 to graph.nb_outputs - 1 do
      PPtrIdx(graph.outputs, i).ost.unavailable := 1;

  Result := 0;
end;

(**
 * Run a single step of transcoding.
 *
 * @return  0 for success, <0 for error
 *)
function TCustomFFmpeg.transcode_step: Integer;
var
  ost: POutputStream;
  ist: PInputStream;
  ret: Integer;
begin
  ost := choose_output();
  if not Assigned(ost) then
  begin
    if got_eagain() <> 0 then
    begin
      reset_eagain();
      av_usleep(10000);
      Result := 0;
      Exit;
    end;
    FFLogger.Log(Self, llVerbose, 'No more inputs to read from, finishing.');
    Result := AVERROR_EOF;
    Exit;
  end;

  if Assigned(ost.filter) then
  begin
    ret := transcode_from_filter(ost.filter.graph, @ist);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;
    if not Assigned(ist) then
    begin
      Result := 0;
      Exit;
    end;
  end
  else
  begin
    Assert(ost.source_index >= 0);
    ist := PPtrIdx(Finput_streams, ost.source_index);
  end;

  ret := process_input(ist.file_index);
  if ret = AVERROR_EAGAIN then
  begin
    if PPtrIdx(Finput_files, ist.file_index).eagain <> 0 then
      ost.unavailable := 1;
    Result := 0;
    Exit;
  end;
  if ret < 0 then
  begin
    if ret = AVERROR_EOF then
      Result := 0
    else
      Result := ret;
    Exit;
  end;

  Result := reap_filters();
end;

procedure TCustomFFmpeg.transcode_cleanup();
var
  i: Integer;
  ost: POutputStream;
begin
  EnsureCloseDecoders(FDecoderList);
  EnsureCloseEncoders(FEncoderList);

  for i := 0 to Fnb_output_streams - 1 do
  begin
    ost := PPtrIdx(Foutput_streams, i);
    if not Assigned(ost) then
      Continue;
    if not FJoinMode or (i < Fnb_output_streams_join) then // hack: join mode
    begin
      if ost.stream_copy <> 0 then
        av_freep(@ost.st.codec.extradata);
      // close two pass logfile
      if Assigned(ost.logfile) then
      begin
        my_fclose(ost.logfile);
        ost.logfile := nil;
      end;
      av_freep(@ost.st.codec.subtitle_header);
      av_freep(@ost.forced_kf_pts);
      av_freep(@ost.apad);
      av_dict_free(@ost.opts);
      av_dict_free(@ost.swr_opts);
      av_dict_free(@ost.resample_opts);
    end;
  end;
  FTranscodeCleanuped := True;
end;

function TCustomFFmpeg.do_transcode_init: Boolean;
var
  ret: Integer;
begin
  if FTranscodeInitialized then
  begin
    Result := True;
    Exit;
  end;

  if FOutputDuration < 0 then
    FOutputDuration := FInputDuration;

  FLastErrMsg := '';
  try
    ret := transcode_init();
    if ret < 0 then
    begin
      if FLastErrMsg = '' then
        FLastErrMsg := print_error('transcode_init() error', ret) + '. ' + CHECK_LOG_MSG;
      Result := False;
      transcode_cleanup;
    end
    else
    begin
      FTranscodeInitialized := True;
      Result := True;
    end;
  except on E: Exception do
    begin
      FLastErrMsg := E.Message;
      Result := False;
      transcode_cleanup;
    end;
  end;
end;

(* The following code is the main loop of the file converter *)
procedure TCustomFFmpeg.transcode();
var
  ret, i: Integer;
  ost: POutputStream;
  ist: PInputStream;
  timer_start: Int64;
  cur_time: Int64;
  ifile: PInputFile;
  j: Integer;
begin
{$IF Defined(NEED_HASH) or Defined(NEED_KEY)}
  Randomize;
  if (FOutputDuration < 0) or (FOutputDuration > 1000000 * (60 * 5 + Random(60))) then
  begin
    {$IFDEF NEED_HASH}StartHash;{$ENDIF}
    {$IFDEF NEED_KEY}_CK1(FLic);{$ENDIF}
  end;
{$IFEND}

  timer_start := av_gettime();

  (* init framerate emulation *)
  for i := 0 to Fnb_input_files - 1 do
  begin
    ifile := PPtrIdx(Finput_files, i);
    if ifile.rate_emu <> 0 then
      for j := 0 to ifile.nb_streams - 1 do
        PPtrIdx(Finput_streams, j + ifile.ist_index).start := av_gettime();
  end;

  // hack: for join mode
  Fjoin_file_index := 0;
  CalcOstIdx;
  // hack end

  // main loop
  while not FBroken do
  begin
    cur_time := av_gettime;
    (* check if there's any stream where output is still needed *)
    if need_output() = 0 then
    begin
      FFLogger.Log(Self, llVerbose, 'No more output streams to write to, finishing.');
      Break;
    end;

    ret := transcode_step();

    if ret < 0 then
    begin
      if (ret = AVERROR_EOF) or (ret = AVERROR_EAGAIN) then
        Continue;
      FFLogger.Log(Self, llError, print_error('Error while filtering', ret));
      Break;
    end;

    (* dump report by using the output first video and audio streams *)
    print_report(Fjoin_file_index, 0, timer_start, cur_time);
  end;

  (* at the end of stream, we must flush the decoder buffers *)
  for i := 0 to Fnb_input_streams - 1 do
  begin
    ist := PPtrIdx(Finput_streams, i);
    if (PPtrIdx(Finput_files, ist.file_index).eof_reached = 0) and (ist.decoding_needed <> 0) and
      (ist.decoder_flushed <> 1) then // hack: for join mode
      output_packet(ist, nil);
  end;
  flush_encoders();

  (* write the trailer if needed and close file *)
  for i := 0 to Fnb_output_files - 1 do
  begin
    ret := av_write_trailer(PPtrIdx(Foutput_files, i).ctx);
    if ret < 0 then
      FFLogger.Log(Self, llError, print_error('av_write_trailer()', ret));
    if FJoinMode then
      Break;
  end;

  (* dump report by using the first video and audio streams *)
  print_report(-1, 1, timer_start, av_gettime());

  (* close each encoder *)
  for i := 0 to Fnb_output_streams - 1 do
  begin
    if FJoinMode and (i = Fnb_output_streams_join) then // hack: join mode
      Break;
    ost := PPtrIdx(Foutput_streams, i);
    if ost.encoding_needed <> 0 then
    begin
      av_freep(@ost.st.codec.stats_in);
      avcodec_close(ost.st.codec);
      ost.is_avcodec_closed := 1; // hack: for fix memory leak
      RemoveCodecList(FEncoderList, ost); // hack: for encoder list
    end;
  end;

  (* close each decoder *)
  for i := 0 to Fnb_input_streams - 1 do
  begin
    ist := PPtrIdx(Finput_streams, i);
    if ist.decoding_needed <> 0 then
    begin
      // hack: for join mode
      if ist.decoder_closed = 1 then
        Continue;
      ist.decoder_closed := 1;
      // hack end
      avcodec_close(ist.st.codec);
      RemoveCodecList(FDecoderList, ist); // hack: for decoder list
    end;
  end;

  (* finished ! *)
  FFinished := not FBroken;

  transcode_cleanup;
end;

// hack
{$IFDEF MSWINDOWS}
function TCustomFFmpeg.add_frame_hooker(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  argc: Integer;
  argv: array[0..63] of PAnsiChar;
  args: PAnsiChar;
  delim: PAnsiChar;
begin
  argc := 0;
  args := av_strdup(arg);

  // NOTICE: if vhook parameters(HookDLL or FileName) have SPACE characters,
  //         the delimiter between vhook parameters must be set to '|'.
  //         this feature is an increment to original FFmpeg's vhook.
  if Pos('|', string(args)) > 0 then
    delim := '|'
//  else if Pos(#9, args) > 0 then
//    delim := #9
  else
    delim := ' ';

  argv[0] := my_strtok(args, delim);
  while argc < SizeOf(argv) - 2 do
  begin
    Inc(argc);
    argv[argc] := my_strtok(nil, delim);
    if argv[argc] = nil then
      Break;
  end;

  if frame_hook_add(FFirstHook, argc, argv) <> 0 then
    RaiseException('Failed to add video hook function: ' + arg);

  Fusing_vhook := True;
  Result := 0;
end;
{$ENDIF}

// hack
{$IFNDEF FFFMX}
function TCustomFFmpeg.opt_VideoHookBitsPixel(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  try
    Self.VideoHookBitsPixel := StrToInt(string(arg));
    Result := 0;
  except on E: Exception do
    begin
      GOptionError := E.Message;
      FFLogger.Log(Self, llError, GOptionError);
      Result := AVERROR_EINVAL;
    end;
  end;
end;
{$ENDIF}

initialization
  GHookLock := TCriticalSection.Create;
  GCodecLock := TCriticalSection.Create;

finalization
  GCodecLock.Free;
  GHookLock.Free;

end.
