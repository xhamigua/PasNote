(*
 * Copyright (c) 2003 Fabrice Bellard
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
 * simple media player based on the FFmpeg libraries
 *)

(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * Original file: ffplay.c
 * Ported by CodeCoolie@CNSW 2008/12/15 -> $Date:: 2013-12-25 #$
 *)

unit FFPlay;

interface

{$I CompilerDefines.inc}

{$I _LicenseDefines.inc}

{ $DEFINE DEBUG_SYNC}

{$DEFINE CONFIG_AVFILTER}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  {$IFDEF VCL_XE4_OR_ABOVE}
    System.AnsiStrings, // AnsiStrComp
  {$ENDIF}
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,

  System.SyncObjs,
  System.Math,
{$ELSE}
  Windows,
  Messages,
  SysUtils,
  Classes,
  Graphics,
  Controls,

  SyncObjs,
  Math,
{$ENDIF}

{$IFDEF BCB}
  BCBTypes,
{$ENDIF}

{$IFDEF USES_LICKEY}
  LicenseKey,
{$ENDIF}

  libsdl,

  libavcodec,
  libavcodec_avfft,
  AVCodecStubs,
{$IFDEF CONFIG_AVFILTER}
  libavfilter,
  AVFilterStubs,
{$ENDIF}
  libavformat,
  AVFormatStubs,
  libavutil,
  libavutil_channel_layout,
  libavutil_common,
  libavutil_dict,
  libavutil_error,
  libavutil_frame,
  libavutil_log,
  libavutil_opt,
  libavutil_pixdesc,
  libavutil_pixfmt,
  libavutil_rational,
  libavutil_samplefmt,
  AVUtilStubs,
  libswresample,
  SwResampleStubs,
  libswscale,
{$IFNDEF CONFIG_AVFILTER}
  SwScaleStubs,
{$ENDIF}
  MyUtilStubs,
  SoundTouchStubs,

//  NGSDebuger,

  UnicodeProtocol,

  FFBaseComponent,
  FFDecode,
  FFUtils,
  MyUtils;

{$I libversion.inc}

const
  // packet queue max size
  MAX_QUEUE_SIZE  = 15 * 1024 * 1024;
  MIN_FRAMES      = 5;

  (* SDL audio buffer size, in samples. Should be small to have precise
     A/V sync as SDL does not have hardware buffer fullness info. *)
  SDL_AUDIO_BUFFER_SIZE = 1024;

  (* no AV sync correction is done if below the minimum AV sync threshold *)
  AV_SYNC_THRESHOLD_MIN = 0.01;
  (* AV sync correction is done if above the maximum AV sync threshold *)
  AV_SYNC_THRESHOLD_MAX = 0.1;
  (* If a frame duration is longer than this, it will not be duplicated to compensate AV sync *)
  AV_SYNC_FRAMEDUP_THRESHOLD = 0.1;
  (* no AV correction is done if too big error *)
  AV_NOSYNC_THRESHOLD = 10.0;

  (* maximum audio speed change to get correct sync *)
  SAMPLE_CORRECTION_PERCENT_MAX = 10;

  (* external clock speed adjustment constants for realtime sources based on buffer fullness *)
  EXTERNAL_CLOCK_SPEED_MIN  = 0.900;
  EXTERNAL_CLOCK_SPEED_MAX  = 1.010;
  EXTERNAL_CLOCK_SPEED_STEP = 0.001;

  (* we use about AUDIO_DIFF_AVG_NB A-V differences to make the average *)
  AUDIO_DIFF_AVG_NB = 20;

  (* polls for possible required screen refresh at least this often, should be less than 1/fps *)
  REFRESH_RATE = 0.01;

  (* NOTE: the size must be big enough to compensate the hardware audio buffersize size *)
  (* TODO: We assume that a decoded and resampled frame fits into this buffer *)
  SAMPLE_ARRAY_SIZE = 8 * 65536;

  // picture queue size
  VIDEO_PICTURE_QUEUE_SIZE = 3;
  SUBPICTURE_QUEUE_SIZE = 4;

  // user custom event constants
  FF_ALLOC_EVENT   = (SDL_USEREVENT);
  FF_QUIT_EVENT    = (SDL_USEREVENT + 2);
  FF_ASPECT_EVENT  = (SDL_USEREVENT + 3); // hack

type
  // packet list
  PMyAVPacketList = ^TMyAVPacketList;
  TMyAVPacketList = record
    pkt: TAVPacket;
    next: PMyAVPacketList;
    serial: Integer;
  end;

  // packet queue
  PPacketQueue = ^TPacketQueue;
  TPacketQueue = record
    first_pkt, last_pkt: PMyAVPacketList;
    nb_packets: Integer;
    size: Integer;
    abort_request: Integer;
    serial: Integer;
    mutex: PSDL_mutex;
    cond: PSDL_cond;
  end;

  // video picture
  PVideoPicture = ^TVideoPicture;
  TVideoPicture = record
    pts: Double;          // presentation time stamp for this picture
    pos: Int64;           // byte position in file
    bmp: PSDL_Overlay;
    width, height: Integer; (* source height & width *)
    allocated: Integer;
    //reallocate: Integer;
    serial: Integer;

    sar: TAVRational;
    abort_allocate: Integer;
  end;

  // subtitle picture
  PSubPicture = ^TSubPicture;
  TSubPicture = record
    pts: Double; (* presentation time stamp for this picture *)
    sub: TAVSubtitle;
    serial: Integer;
  end;

  PAudioParams = ^TAudioParams;
  TAudioParams = record
    freq: Integer;
    channels: Integer;
    channel_layout: Int64;
    fmt: TAVSampleFormat;
  end;

  PClock = ^TClock;
  TClock = record
    pts: Double;            (* clock base *)
    pts_drift: Double;      (* clock base minus time at which we updated the clock *)
    last_updated: Double;
    speed: Double;
    serial: Integer;        (* clock is based on a packet with this serial *)
    paused: Integer;
    queue_serial: PInteger; (* pointer to the current packet queue serial, used for obsolete clock detection *)

    // hack
    check_serial: Boolean;
  end;

  // sync type
  _Tav_sync_type = (
    AV_SYNC_AUDIO_MASTER,   (* default choice *)
    AV_SYNC_VIDEO_MASTER,
    AV_SYNC_EXTERNAL_CLOCK  (* synchronize to an external clock *)
  );

{$IFDEF FPC}
  TThreadFunction = function(p: Pointer): Integer; cdecl;

  TSDL_Thread = class(TThread)
  private
    FThreadFunction: TThreadFunction;
    FData: Pointer;
  protected
    procedure Execute; override;
  public
    constructor Create(fn: TThreadFunction; data: Pointer);
  end;

  PSDL_Thread = TSDL_Thread;
{$ENDIF}

  TCustomPlayer = class;

  // main data record for current video state
  _TShowMode = (
    SHOW_MODE_NONE,
    SHOW_MODE_VIDEO,
    SHOW_MODE_WAVES,
    SHOW_MODE_RDFT,
    SHOW_MODE_NB
  );
  PVideoState = ^TVideoState;
  TVideoState = record
    read_tid: PSDL_Thread;    // read_thread
    video_tid: PSDL_Thread;   // video_thread
    iformat: PAVInputFormat;
    no_background: Integer;
    abort_request: Integer;
    force_refresh: Integer;
    paused: Integer;
    last_paused: Integer;
    queue_attachments_req: Integer;
    seek_req: Integer;
    seek_flags: Integer;
    seek_pos: Int64;
    seek_rel: Int64;
    read_pause_return: Integer;
    ic: PAVFormatContext;
    realtime: Integer;
    audio_finished: Integer;
    video_finished: Integer;

    audclk: TClock;
    vidclk: TClock;
    extclk: TClock;

    audio_stream: Integer;

    av_sync_type: _Tav_sync_type;

    audio_clock: Double;
    audio_clock_serial: Integer;
    audio_diff_cum: Double; (* used for AV difference average computation *)
    audio_diff_avg_coef: Double;
    audio_diff_threshold: Double;
    audio_diff_avg_count: Integer;
    audio_st: PAVStream;
    audioq: TPacketQueue; // SizeOf(TPacketQueue) = 28
    audio_hw_buf_size: Integer;
    silence_buf: array[0..SDL_AUDIO_BUFFER_SIZE-1] of Byte;
    audio_buf: PByte;
    audio_buf1: PByte;
    audio_buf_size: Cardinal; (* in bytes *)
    audio_buf1_size: Cardinal;
    audio_buf_index: Integer; (* in bytes *)
    audio_write_buf_size: Integer;
    audio_buf_frames_pending: Integer;
    audio_pkt_temp: TAVPacket;
    audio_pkt: TAVPacket;
    audio_pkt_temp_serial: Integer;
    audio_last_serial: Integer;
    audio_src: TAudioParams;
{$IFDEF CONFIG_AVFILTER}
    audio_filter_src: TAudioParams;
{$ENDIF}
    audio_tgt: TAudioParams;
    swr_ctx: PSwrContext;
    frame_drops_early: Integer;
    frame_drops_late: Integer;
    frame: PAVFrame;
    audio_frame_next_pts: Int64;

    show_mode: _TShowMode;
    sample_array: array[0..SAMPLE_ARRAY_SIZE - 1] of SmallInt;
    sample_array_index: Integer;
    last_i_start: Integer;
    rdft: PRDFTContext;
    rdft_bits: Integer;
    rdft_data: PFFTSample;
    xpos: Integer;
    last_vis_time: Double;

    subtitle_tid: PSDL_Thread; // subtitle_thread
    subtitle_stream: Integer;
    subtitle_st: PAVStream;
    subtitleq: TPacketQueue;
    subpq: array[0..SUBPICTURE_QUEUE_SIZE - 1] of TSubPicture;
    subpq_size, subpq_rindex, subpq_windex: Integer;
    subpq_mutex: PSDL_mutex;
    subpq_cond: PSDL_cond;

    frame_timer: Double;
    frame_last_pts: Double;
    frame_last_duration: Double;
    frame_last_dropped_pts: Double;
    frame_last_returned_time: Double;
    frame_last_filter_delay: Double;
    frame_last_dropped_pos: Int64;
    frame_last_dropped_serial: Integer;
    video_stream: Integer;
    video_st: PAVStream;
    videoq: TPacketQueue;
    video_current_pos: Int64;           // current displayed file pos
    max_frame_duration: Double;         // maximum duration of a frame - above this, we consider the jump a timestamp discontinuity
    pictq: array[0..VIDEO_PICTURE_QUEUE_SIZE - 1] of TVideoPicture;
    pictq_size, pictq_rindex, pictq_windex: Integer;
    pictq_mutex: PSDL_mutex;
    pictq_cond: PSDL_cond;
{$IFNDEF CONFIG_AVFILTER}
    img_convert_ctx: PSwsContext;
{$ENDIF}
    last_display_rect: TSDL_Rect;

    filename: array[0..1024 - 1] of {$IFDEF FPC}Char{$ELSE}WideChar{$ENDIF};
    width, height, xleft, ytop: Integer;
    step: Integer;

{$IFDEF CONFIG_AVFILTER}
    in_video_filter: PAVFilterContext;  // the first filter in the video chain
    out_video_filter: PAVFilterContext; // the last filter in the video chain
    in_audio_filter: PAVFilterContext;  // the first filter in the audio chain
    out_audio_filter: PAVFilterContext; // the last filter in the audio chain
    agraph: PAVFilterGraph;             // audio filter graph
    FilterGraph: PAVFilterGraph;        // hack for sending video filter commands
{$ENDIF}

    last_video_stream, last_audio_stream, last_subtitle_stream: Integer;

    continue_read_thread: PSDL_cond;

    // hack below
    Owner: TCustomPlayer;
    FileOpened: Integer;
    StartTime: Int64;
    FileDuration: Int64;
    AudioDuration: Int64;
    IsImage2: Integer;
    IsDevice: Integer;
    IOEOFLog: Integer;
    IOERRLog: Integer;
    EndEventDone: Integer;
    ReachEOF: Integer;
    Reading: Integer;
    open_paused: Integer;
    seek_paused: Integer;
    seek_done: Integer;
    seek_flushed: Integer;
    flush_req: Integer;
    pictq_cindex: Integer;

    frame_delay: Double;
    pictq_total_size: Integer;

    master_sync_type: _Tav_sync_type;
    av_sync_type_ok: Integer;
    soundtouch: Pointer;
    st_channels: Integer;
    st_sample_rate: Integer;
    st_tempo: Double; // Single;

    wait_for_stream_opened: Integer;
    open_in_caller_thread: Integer;

{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
    yuv01: Integer;
    yuv23: Integer;
    yuv45: Integer;
{$IFEND}
  end;

  // play thread, internal used only
  TPlayThread = class(TThread)
  private
    FOwner: TCustomPlayer;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TCustomPlayer);
  end;

  // event thread, internal used only
  TEventThread = class(TThread)
  private
    FOwner: TCustomPlayer;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TCustomPlayer);
  end;

  // enum types
  TAudioDriver = (adDefault, adDirectSound, adWaveOut);
  TAudioVolume = 0..SDL_MIX_MAXVOLUME;
  TPlayState = (psPlay, psPause, psResume, psStep, psStop, psEnd);
  TRepeatType = (rtNone, rtStop, rtLoop, rtPause, rtRewind);
  TShowMode = (smNone, smVideo, smWaves, smRDFT);
  TVideoDriver = (vdDefault, vdDirectDraw, vdGDI);
  Tav_sync_type = (stAudio, stVideo, stExternal);

  // events
  TAudioHookEvent = procedure(Sender: TObject; const APTS: Int64; ASample: PByte;
    ASize, ASampleRate, AChannels: Integer) of object;
  TFileOpenEvent = procedure(Sender: TObject; const ADuration: Int64;
    AFrameWidth, AFrameHeight: Integer; var AScreenWidth, AScreenHeight: Integer) of object;
  TPlayStateEvent = procedure(Sender: TObject; APlayState: TPlayState) of object;
  TPositionEvent = procedure(Sender: TObject; const APTS: Int64) of object;
  TVideoHookEvent = procedure(Sender: TObject; ABitmap: {$IFDEF ACTIVEX}PBitmap{$ELSE}TBitmap{$ENDIF};
    const APTS: Int64; var AUpdate: Boolean) of object;
  PAVPicture = libavcodec.PAVPicture;
  TAVPixelFormat = libavutil_pixfmt.TAVPixelFormat;
  TFrameHookEvent = procedure(Sender: TObject; APicture: PAVPicture; APixFmt: TAVPixelFormat;
    AWidth, AHeight: Integer; const APTS: Int64) of object;

  // event type, internal used only
  TEventType = (etNone, etPosition, etState, etStop);
  // event item, internal used only
  PEventItem = ^TEventItem;
  TEventItem = record
    EventType: TEventType;
    case Integer of
      0: (Position: Int64);
      1: (State: TPlayState);
  end;
  // play event queue, internal used only
  TPlayEvent = record
    Lock: TMutex;
    Event: TEvent;
    Header: Integer;
    Tailer: Integer;
    Events: array[0..9] of TEventItem;
  end;

  // custom player
  TCustomPlayer = class(TFFBaseComponent)
  protected
    Fsws_flags: Int64;              // = SWS_BICUBIC;
    FOptions: TFFOptions;           // used for deault options

    (* options specified by the user *)
    Ffile_iformat: PAVInputFormat;
    Finput_filename: TPathFileName;
//    Fwindow_title: PAnsiChar;
    Ffs_screen_width: Integer;
    Ffs_screen_height: Integer;
    Fdefault_width: Integer;        // = 640;
    Fdefault_height: Integer;       // = 480;
    Fscreen_width: Integer;         // = 0;
    Fscreen_height: Integer;        // = 0;
    Faudio_disable: Boolean;        // Integer;
    Fvideo_disable: Boolean;        // Integer;
    Fsubtitle_disable: Boolean;     // Integer;
{$IF Defined(BCB) and Defined(VER140)} // C++Builder 6
    Fwanted_stream: array[AVMEDIA_TYPE_UNKNOWN..AVMEDIA_TYPE_NB] of Integer;
{$ELSE}
    Fwanted_stream: array[TAVMediaType] of Integer;
{$IFEND}
    Fseek_by_bytes: Integer;        // = -1;
    Fdisplay_disable: Boolean;      // Integer;
//    Fshow_status: Integer;        // = 1;
    Fav_sync_type: Tav_sync_type;   // Integer; // = AV_SYNC_AUDIO_MASTER;
    Fstart_time: Int64;             // = AV_NOPTS_VALUE;
//    Fduration: Int64;             // = AV_NOPTS_VALUE;
    Fworkaround_bugs: Integer;      // = 1;
    Ffast: Boolean;                 // Integer;   // = 0;
    Fgenpts: Boolean;               // Integer;   // = 0;
    Flowres: Integer;               // = 0;
    Ferror_concealment: Integer;    // = 3;
    Fdecoder_reorder_pts: Integer;  // = -1;
//    Fautoexit: Integer;
//    Fexit_on_keydown: Integer;
//    Fexit_on_mousedown: Integer;
//    Floop: Integer;               // = 1;
    Fframedrop: Integer;            // = -1;
    Finfinite_buffer: Integer;      // = -1;
//    Fshow_mode: TShowMode;        // = SHOW_MODE_NONE;
    Faudio_codec_name: string;
    Fvideo_codec_name: string;
    Fsubtitle_codec_name: string;
    Frdftspeed: Double;             // = 0.02;
    Fvfilters: string;
    Fafilters: string;

    (* current context *)
    Fis_full_screen: Boolean;       // Integer;
    Faudio_callback_time: Int64;

    Fflush_pkt: TAVPacket;

    Fscreen: PSDL_Surface;

    function packet_queue_put_private(q: PPacketQueue; pkt: PAVPacket): Integer;
    function packet_queue_put(q: PPacketQueue; pkt: PAVPacket): Integer;
    function packet_queue_put_nullpacket(q: PPacketQueue; stream_index: Integer): Integer;
    procedure packet_queue_init(q: PPacketQueue);
    procedure packet_queue_flush(q: PPacketQueue);
    procedure packet_queue_destroy(q: PPacketQueue);
    procedure packet_queue_abort(q: PPacketQueue);
    procedure packet_queue_start(q: PPacketQueue);
    function packet_queue_get(q: PPacketQueue; pkt: PAVPacket; block: Integer; serial: PInteger): Integer;

    procedure fill_rectangle(AScreen: PSDL_Surface; x, y, w, h, AColor, update: Integer);
    procedure fill_border(xleft, ytop, width, height, x, y, w, h, AColor, update: Integer);
    procedure free_picture(vp: PVideoPicture);
    procedure video_image_display(ivs: PVideoState);
    procedure video_audio_display(ivs: PVideoState);
    procedure stream_close(ivs: PVideoState);
    procedure do_exit;
    function video_open(ivs: PVideoState; force_set_video_mode: Boolean; vp: PVideoPicture): Integer;
    procedure video_display(ivs: PVideoState);
    procedure stream_seek(ivs: PVideoState; pos: Int64; rel: Int64; seek_flags: TSeekFlags; AWaitForSeekEnd: Boolean);
    procedure stream_toggle_pause(ivs: PVideoState);
    procedure pictq_next_picture(ivs: PVideoState);
    function pictq_prev_picture(ivs: PVideoState): Integer;
    procedure video_refresh(opaque: Pointer; remaining_time: PDouble);
    procedure alloc_picture(ivs: PVideoState);
    function queue_picture(ivs: PVideoState; src_frame: PAVFrame; pts: Double; pos: Int64; serial: Integer): Integer;
    function get_video_frame(ivs: PVideoState; frame: PAVFrame; pkt: PAVPacket; serial: PInteger): Integer;
    function audio_decode_frame(ivs: PVideoState; pts_ptr: PDouble): Integer;
    function audio_open(opaque: Pointer; wanted_channel_layout: Int64;
      wanted_nb_channels, wanted_sample_rate: Integer; audio_hw_params: PAudioParams): Integer;
    function stream_component_open(ivs: PVideoState; stream_index: Integer): Integer;
    procedure stream_component_close(ivs: PVideoState; stream_index: Integer);
    function stream_open(const filename: TPathFileName; iformat: PAVInputFormat; APaused, AWait: Boolean): Boolean;
    procedure stream_cycle_channel(ivs: PVideoState; codec_type: TAVMediaType);
    function stream_change_channel(ivs: PVideoState; codec_type: TAVMediaType; stream_index: Integer): Boolean;
    procedure refresh_loop_wait_event(ivs: PVideoState; event: PSDL_Event);
    procedure event_loop;
    procedure PushAspectEvent(arg: Pointer);
    procedure PushQuitEvent(arg: Pointer);
{$IFDEF CONFIG_AVFILTER}
    function configure_video_filters(graph: PAVFilterGraph;
      ivs: PVideoState; vfilters: string; frame: PAVFrame): Integer;
    function configure_audio_filters(ivs: PVideoState;
      afilters: string; force_output_format: Integer): Integer;
{$ENDIF}
    procedure do_video_thread(arg: Pointer);
    procedure do_subtitle_thread(arg: Pointer);
    function do_open_stream(arg: Pointer): Integer;
    procedure do_read_thread(arg: Pointer);
  private
    // local SDL API stubs
    SDL_Init: TSDL_Init;
    SDL_Quit: TSDL_Quit;
    SDL_getenv: TSDL_getenv;
    SDL_putenv: TSDL_putenv;
    SDL_GetError: TSDL_GetError;
    SDL_OpenAudio: TSDL_OpenAudio;
    SDL_PauseAudio: TSDL_PauseAudio;
    SDL_CloseAudio: TSDL_CloseAudio;
    SDL_MixAudio: TSDL_MixAudio;
    SDL_PumpEvents: TSDL_PumpEvents;
    SDL_PeepEvents: TSDL_PeepEvents;
    SDL_PushEvent: TSDL_PushEvent;
    SDL_EventState: TSDL_EventState;

    SDL_GetVideoInfo: TSDL_GetVideoInfo;
    SDL_SetVideoMode: TSDL_SetVideoMode;
    SDL_UpdateRect: TSDL_UpdateRect;
    SDL_WM_SetCaption: TSDL_WM_SetCaption;
    SDL_MapRGB: TSDL_MapRGB;
    SDL_FillRect: TSDL_FillRect;
    SDL_CreateYUVOverlay: TSDL_CreateYUVOverlay;
    SDL_LockYUVOverlay: TSDL_LockYUVOverlay;
    SDL_UnlockYUVOverlay: TSDL_UnlockYUVOverlay;
    SDL_DisplayYUVOverlay: TSDL_DisplayYUVOverlay;
    SDL_FreeYUVOverlay: TSDL_FreeYUVOverlay;
    SDL_CreateMutex: TSDL_CreateMutex;
    SDL_LockMutex: TSDL_mutexP;
    SDL_UnlockMutex: TSDL_mutexV;
    SDL_DestroyMutex: TSDL_DestroyMutex;
    SDL_CreateCond: TSDL_CreateCond;
    SDL_DestroyCond: TSDL_DestroyCond;
    SDL_CondSignal: TSDL_CondSignal;
    SDL_CondWaitTimeout: TSDL_CondWaitTimeout;
    SDL_CondWait: TSDL_CondWait;
{$IFNDEF FPC}
    SDL_CreateThread: TSDL_CreateThread;
    SDL_WaitThread: TSDL_WaitThread;
{$ENDIF}
    SDL_AudioDriverName: TSDL_AudioDriverName;
    SDL_VideoDriverName: TSDL_VideoDriverName;

    // SDL Loader
    FSDLLoader: TSDLLoader;
    FAutoLoadSDL: Boolean;

    // used for hijack wndproc
    FObjectInstance: Pointer;
    FHijackWndProc: Boolean;
    FHijackCursor: Boolean;
    FScreenWndProc: TFNWndProc;
    FSDLWndProc: TFNWndProc;
    FScreenHandle: {$IFDEF BCB}Pointer{$ELSE}HWND{$ENDIF};
    FScreenPos: TWindowPos; // particularly used for DirectDraw

    FVideoState: PVideoState;
    FVideoStateCB: PVideoState;
    FLastRead: Int64;

    FFrameWidth: Integer;
    FFrameHeight: Integer;
    FLastErrMsg: string;
    FLastPTS: Int64;
    FCurrentPTS: Int64;
    FLoading: Boolean;
    FTryOpen: Boolean;
    FDecoder: TFFDecoder;
    FUseAudioPosition: Boolean;
{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
    Fyuv01: Integer;
    Fyuv45: Integer;
{$IFEND}

    // sync control
    FDataLock: TMutex;
    FSeekEvent: TEvent;
    FPictEvent: TEvent;
    FStopEvent: TEvent;
    FPlayEvent: TPlayEvent;
    FEventState: TPlayState;
    FEventPTS: Int64;
    FSeeking: Boolean;
    FUpdateRectLock: TCriticalSection;

    FAspectRatio: Single;
    FAudioVolume: TAudioVolume;
    FShowMode: TShowMode;
    FOpenInCallerThread: Boolean;
    FPlaybackSpeed: Double;
    FEnableAudioSpeed: Boolean;
    FBackColorR: Byte;
    FBackColorG: Byte;
    FBackColorB: Byte;
    FWaveColorR: Byte;
    FWaveColorG: Byte;
    FWaveColorB: Byte;
    FCheckIOEOF: Boolean;
    FCheckIOERR: Boolean;
    FNegativeOneAsEOF: Boolean;
    FDeinterlace: Boolean;
    FMute: Boolean;
    FPlayTime: Int64;
    FRepeatType: TRepeatType;
    FVerticalFlip: Boolean;
    FAudioDriver: TAudioDriver;
    FVideoDriver: TVideoDriver;
    FAudioHook: Boolean;
    FRGBConverter: TFormatConverter;
    FHookConverter: TFormatConverter;
    FVideoHook: Boolean;
    FFrameHook: Boolean;
    FTriggerEventInMainThread: Boolean;
    FAVFormatContext: PAVFormatContext;
    FState: TPlayState;
    FEventThread: TEventThread;
    FLooping: Boolean;
    FDisplayRectLock: TCriticalSection;
    FDisplayRect: TRect;
{$IFDEF ACTIVEX}
    FAudioHookPTS: Int64;
    FAudioHookData: PByte;
    FAudioHookSize: Integer;
    FVideoHookPTS: Int64;
    FVideoHookUpdate: Boolean;
    FFrameHookPict: PAVPicture;
    FFrameHookWidth: Integer;
    FFrameHookHeight: Integer;
    FFrameHookPTS: Int64;
{$ENDIF}

    FOnAudioHook: TAudioHookEvent;
    FOnVideoHook: TVideoHookEvent;
    FOnFrameHook: TFrameHookEvent;
    FOnFileOpen: TFileOpenEvent;
    FOnOpenFailed: TNotifyEvent;
    FOnPosition: TPositionEvent;
    FOnPlayState: TPlayStateEvent;
    FOnBeforeFindStreamInfo: TBeforeFindStreamInfoEvent;

    procedure SDLFixupStubs;
    procedure SDLUnfixStubs;

    function DoSDLInit(AScreenHandle: HWND): Boolean;
    procedure WndProc(var Message: TMessage);
    function LockData(AWaitTime: DWORD = INFINITE): TWaitResult;
    procedure UnlockData;
    procedure PopupEvent(AEvent: PEventItem);
    procedure PushEvent(AEvent: PEventItem);
    procedure ClearEvents;
    procedure ResetFlags;
    procedure CallDoState;
    procedure DoState(APlayState: TPlayState);
    procedure DoPosition;
    procedure CallDoPosition;
    procedure DoAudioHook(APTS: Double; AData: PByte; ASize: Integer);
    procedure DoFileOpen;
    procedure DoOpenFailed;
    procedure CallBeforeFindStreamInfo;
{$IFDEF ACTIVEX}
    procedure CallAudioHook;
    procedure CallVideoHook;
    procedure CallFrameHook;
{$ENDIF}
    function DoVideoHook(src_picture, dest_picture: PAVPicture;
      src_pix_fmt, dest_pix_fmt: TAVPixelFormat;
      width, height: Integer; pts: Double): Boolean;
    procedure DoFrameHook(pict: PAVPicture; pix_fmt: TAVPixelFormat;
      width, height: Integer; pts: Double);
    procedure UpdateDisplayRect(R: PSDL_Rect);
    function GetAudioStream: Integer;
    function GetSubtitleStream: Integer;
    function GetVideoStream: Integer;
    procedure SetAudioStream(const Value: Integer);
    procedure SetSubtitleStream(const Value: Integer);
    procedure SetVideoStream(const Value: Integer);
    function GetForceFormat: string;
    procedure SetForceFormat(const Value: string);
    procedure SetAspectRatio(const Value: Single);
    function GetPaused: Boolean;
{$IFDEF FPC}
    function Get_wanted_stream_audio: Integer;
    procedure Set_wanted_stream_audio(const Value: Integer);
    function Get_wanted_stream_video: Integer;
    procedure Set_wanted_stream_video(const Value: Integer);
    function Get_wanted_stream_subtitle: Integer;
    procedure Set_wanted_stream_subtitle(const Value: Integer);
{$ENDIF}
    function Get_wanted_stream(const Index: Integer): Integer;
    procedure Set_wanted_stream(const Index, Value: Integer);
    procedure SetShowMode(const Value: TShowMode);
    function GetVideoHookBitsPixel: Integer;
    procedure SetVideoHookBitsPixel(const Value: Integer);
    procedure SetStartTime(const Value: Int64);
    function GetQueueSize: Integer;
    function GetBackColor: Cardinal;
    procedure SetBackColor(const Value: Cardinal);
    function GetWaveColor: Cardinal;
    procedure SetWaveColor(const Value: Cardinal);
    procedure Setav_sync_type(const Value: Tav_sync_type);
    procedure SetPlaybackSpeed(const Value: Double);
    function SendFilterCommand(fg: PAVFilterGraph; target, cmd, arg: string; flags: Integer): Boolean;
    function QueueFilterCommand(fg: PAVFilterGraph; target, cmd, arg: string; flags: Integer; pts: Double): Boolean;
    function _TryOpen(const AFileName: TPathFileName;
      AScreenHandle: {$IFDEF BCB}Pointer{$ELSE}HWND{$ENDIF};
      APaused, AWait: Boolean): Boolean;
    procedure DoStreamOpened;
    procedure DoReleaseResourceOnFailed(ivs: PVideoState);
  protected
    procedure DoErrLog(const AErrMsg: string; ASetErrMsg: Boolean = False);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetLicenseKey(const AKey: AnsiString);

    function AVLibLoaded: Boolean;
    function LoadAVLib(const APath: TPathFileName; AAutoLoadSDL: Boolean = True): Boolean;
    procedure UnloadAVLib;

    function SDLLibLoaded: Boolean;
    function LoadSDLLib(const APath: TPathFileName; const AFile: TPathFileName = SDLLibName): Boolean;
    procedure UnloadSDLLib;

    // open the media file to play, render on the custom window specified by handle
    function Open(const AFileName: TPathFileName;
      AScreenHandle: {$IFDEF BCB}Pointer{$ELSE}HWND{$ENDIF};
      APaused: Boolean = False): Boolean;
    procedure TryOpen(const AFileName: TPathFileName;
      AScreenHandle: {$IFDEF BCB}Pointer{$ELSE}HWND{$ENDIF};
      APaused: Boolean = False);
    procedure Stop(AWaitForStop: Boolean = False);
    procedure Pause;
    procedure Resume;
    procedure TogglePause;
    procedure ToggleAudioDisplay;
    procedure StepToNextFrame;
    // do seek by timestamp in microseconds
    procedure Seek(const APTS: Int64; ASeekFlags: TSeekFlags = []; AWaitForSeekEnd: Boolean = False); overload;
    // do seek by relative value (backward/forward) in seconds
    procedure Seek(const ADelta: Double; ASeekFlags: TSeekFlags = []; AWaitForSeekEnd: Boolean = False); overload;
    procedure FlushQueue;
    // Send a command to one or more filter instances.
    function SendVideoFilterCommand(target, cmd, arg: string; flags: Integer): Boolean;
    function SendAudioFilterCommand(target, cmd, arg: string; flags: Integer): Boolean;
    // Queue a command to one or more filter instances.
    function QueueVideoFilterCommand(target, cmd, arg: string; flags: Integer; pts: Double): Boolean;
    function QueueAudioFilterCommand(target, cmd, arg: string; flags: Integer; pts: Double): Boolean;
    function opt_default(const opt, arg: string): Boolean;
    function DefaultOptions(AOptions: AnsiString): Boolean;
    function CurrentFrame: {$IFDEF ACTIVEX}PBitmap{$ELSE}TBitmap{$ENDIF}; overload;
    function CurrentFrame(var APTS: Int64): {$IFDEF ACTIVEX}PBitmap{$ELSE}TBitmap{$ENDIF}; overload;
    // particularly used for DirectDraw to update screen position
    procedure UpdateScreenPosition;
    function DisplayToActualRect(ADisplayRect: TRect): TRect;

    // disable audio
    property DisableAudio: Boolean read Faudio_disable write Faudio_disable;
    // disable video
    property DisableVideo: Boolean read Fvideo_disable write Fvideo_disable;
    // disable subtitle
    property DisableSubtitle: Boolean read Fsubtitle_disable write Fsubtitle_disable;
    // disable graphical display
    property DisableDisplay: Boolean read Fdisplay_disable write Fdisplay_disable;
    // force format
    property ForceFormat: string read GetForceFormat write SetForceFormat;
    // frame width
    property FrameWidth: Integer read FFrameWidth;
    // frame height
    property FrameHeight: Integer read FFrameHeight;
    // initial displayed width
    property ScreenWidth: Integer read Fscreen_width write Fscreen_width;
    // initial displayed height
    property ScreenHeight: Integer read Fscreen_height write Fscreen_height;

    property AVFormatContext: PAVFormatContext read FAVFormatContext;
    property FileName: TPathFileName read Finput_filename;
    property LastErrMsg: string read FLastErrMsg {$IFDEF ACTIVEX} write FLastErrMsg{$ENDIF};
    property ScreenHandle: {$IFDEF BCB}Pointer{$ELSE}HWND{$ENDIF} read FScreenHandle;
    property HijackWndProc: Boolean read FHijackWndProc write FHijackWndProc;
    property HijackCursor: Boolean read FHijackCursor write FHijackCursor;

    property AudioStreamIndex: Integer read GetAudioStream write SetAudioStream;
    property VideoStreamIndex: Integer read GetVideoStream write SetVideoStream;
    property SubtitleStreamIndex: Integer read GetSubtitleStream write SetSubtitleStream;

    property Decoder: TFFDecoder read FDecoder;

    // AspectRatio: = 0 means keeping original, < 0 means scaling to fit, > 0 means customization
    property AspectRatio: Single read FAspectRatio write SetAspectRatio;
    property AudioDriver: TAudioDriver read FAudioDriver write FAudioDriver;
    property AudioHook: Boolean read FAudioHook write FAudioHook;
    // AudioVolume: 0-128, 128 means keeping original
    property AudioVolume: TAudioVolume read FAudioVolume write FAudioVolume;
    // background color, value of RGB(r, g, b)
    property BackColor: Cardinal read GetBackColor write SetBackColor;
    // audio wave color, value of RGB(r, g, b)
    property WaveColor: Cardinal read GetWaveColor write SetWaveColor;
    property Mute: Boolean read FMute write FMute;
    property CurrentPTS: Int64 read FCurrentPTS;
    property CheckIOEOF: Boolean read FCheckIOEOF write FCheckIOEOF;
    property CheckIOERR: Boolean read FCheckIOERR write FCheckIOERR;
    property NegativeOneAsEOF: Boolean read FNegativeOneAsEOF write FNegativeOneAsEOF;
    property Deinterlace: Boolean read FDeinterlace write FDeinterlace;
    property FrameHook: Boolean read FFrameHook write FFrameHook;
    property VideoHook: Boolean read FVideoHook write FVideoHook;
    property OpenInCallerThread: Boolean read FOpenInCallerThread write FOpenInCallerThread;
    property Paused: Boolean read GetPaused;
    property PlayState: TPlayState read FState;
    property PlayTime: Int64 read FPlayTime write FPlayTime;
    property QueueSize: Integer read GetQueueSize;
    // playback speed, requires SyncType to be stExternal
    property PlaybackSpeed: Double read FPlaybackSpeed write SetPlaybackSpeed;
    // set audio-video sync. type (type=audio/video/ext)
    property SyncType: Tav_sync_type read Fav_sync_type write Setav_sync_type;
    // enable changing audio speed, only available for mono and stereo, requires SoundTouch library
    property EnableAudioSpeed: Boolean read FEnableAudioSpeed write FEnableAudioSpeed;
    // repeat type on reach of PlayTime
    property RepeatType: TRepeatType read FRepeatType write FRepeatType;
    property Seeking: Boolean read FSeeking;
    property ShowMode: TShowMode read FShowMode write SetShowMode;
    // seek to a given position in microseconds
    property StartTime: Int64 read Fstart_time write SetStartTime;
    property TriggerEventInMainThread: Boolean read FTriggerEventInMainThread
      write FTriggerEventInMainThread;
    property UseAudioPosition: Boolean read FUseAudioPosition write FUseAudioPosition;
    property VerticalFlip: Boolean read FVerticalFlip write FVerticalFlip;
    property VideoDriver: TVideoDriver read FVideoDriver write FVideoDriver;
    // video filters
    property VideoFilters: string read Fvfilters write Fvfilters;
    // audio filters
    property AudioFilters: string read Fafilters write Fafilters;
    // specifies the number of adjacent color bits on each plane needed to define a pixel.
    // one of (8, 15[555, BI_RGB], 16[565, BI_BITFIELDS], 24, 32), default to 32
    property VideoHookBitsPixel: Integer read GetVideoHookBitsPixel write SetVideoHookBitsPixel;

    // force full screen
    property is_full_screen: Boolean read Fis_full_screen write Fis_full_screen;
{$IFDEF FPC}
    // select desired audio stream
    property wanted_audio_stream: Integer read Get_wanted_stream_audio write Set_wanted_stream_audio;
    // select desired video stream
    property wanted_video_stream: Integer read Get_wanted_stream_video write Set_wanted_stream_video;
    // select desired subtitle stream
    property wanted_subtitle_stream: Integer read Get_wanted_stream_subtitle write Set_wanted_stream_subtitle;
{$ELSE}
    // select desired audio stream
    property wanted_audio_stream: Integer index AVMEDIA_TYPE_AUDIO read Get_wanted_stream write Set_wanted_stream;
    // select desired video stream
    property wanted_video_stream: Integer index AVMEDIA_TYPE_VIDEO read Get_wanted_stream write Set_wanted_stream;
    // select desired subtitle stream
    property wanted_subtitle_stream: Integer index AVMEDIA_TYPE_SUBTITLE read Get_wanted_stream write Set_wanted_stream;
{$ENDIF}
    // seek by bytes 0=off 1=on -1=auto
    property seek_by_bytes: Integer read Fseek_by_bytes write Fseek_by_bytes;
    // seek to a given position in microseconds (before open)
    property start_time: Int64 read Fstart_time write Fstart_time;
    property workaround_bugs: Integer read Fworkaround_bugs write Fworkaround_bugs;
    // non spec compliant optimizations
    property fast: Boolean read Ffast write Ffast;
    // generate pts
    property genpts: Boolean read Fgenpts write Fgenpts;
    // let decoder reorder pts 0=off 1=on -1=auto
    property decoder_reorder_pts: Integer read Fdecoder_reorder_pts write Fdecoder_reorder_pts;
    // drop frames when cpu is too slow
    property framedrop: Integer read Fframedrop write Fframedrop;
    // don't limit the input buffer size (useful with realtime streams)
    property infinite_buffer: Integer read Finfinite_buffer write Finfinite_buffer;
    // force decoder
    property audio_codec_name: string read Faudio_codec_name write Faudio_codec_name;
    property video_codec_name: string read Fvideo_codec_name write Fvideo_codec_name;
    property subtitle_codec_name: string read Fsubtitle_codec_name write Fsubtitle_codec_name;
    // rdft speed in second
    property rdftspeed: Double read Frdftspeed write Frdftspeed;
    property lowres: Integer read Flowres write Flowres;
    // set error concealment options (bit_mask)
    property error_concealment: Integer read Ferror_concealment write Ferror_concealment;
    // set audio-video sync. type (type=audio/video/ext)
    property av_sync_type: Tav_sync_type read Fav_sync_type write Setav_sync_type;
  published
    property OnAudioHook: TAudioHookEvent read FOnAudioHook write FOnAudioHook;
    property OnBeforeFindStreamInfo: TBeforeFindStreamInfoEvent read FOnBeforeFindStreamInfo write FOnBeforeFindStreamInfo;
    property OnFileOpen: TFileOpenEvent read FOnFileOpen write FOnFileOpen;
    property OnFrameHook: TFrameHookEvent read FOnFrameHook write FOnFrameHook;
    property OnOpenFailed: TNotifyEvent read FOnOpenFailed write FOnOpenFailed;
    property OnPosition: TPositionEvent read FOnPosition write FOnPosition;
    property OnState: TPlayStateEvent read FOnPlayState write FOnPlayState;
    property OnVideoHook: TVideoHookEvent read FOnVideoHook write FOnVideoHook;
  end;

  TFFPlayer = class(TCustomPlayer)
  published
    property AspectRatio;
    property AudioDriver default adDefault;
    property AudioHook default False;
    property AudioVolume default SDL_MIX_MAXVOLUME;
    property DisableAudio default False;
    property DisableVideo default False;
    property DisableDisplay default False;
    property Mute default False;
    property FrameHook default False;
    property ScreenWidth default 0;
    property ScreenHeight default 0;
    property TriggerEventInMainThread default True;
    property VideoDriver default vdDefault;
    property VideoHook default False;
  end;

// return desktop handle
function GetDesktopHandle: {$IFDEF BCB}Pointer{$ELSE}HWND{$ENDIF};

implementation

uses
  FFLoad,
  FFLog;

{$IFDEF NEED_IDE}
  {$I Z_INIDE.inc}
{$ENDIF}

const
  SCALEBITS = 10;
  ONE_HALF  = (1 shl (SCALEBITS - 1));
  BPP = 1;

{$IFDEF FPC}
function SDL_CreateThread(fn: TThreadFunction; data: Pointer): PSDL_Thread;
begin
  Result := PSDL_Thread.Create(fn, data);
end;

procedure SDL_WaitThread(thread: PSDL_Thread; var status: Integer);
begin
  status := thread.WaitFor;
  thread.Free;
end;

{ TSDL_Thread }

constructor TSDL_Thread.Create(fn: TThreadFunction; data: Pointer);
begin
  inherited Create(False);
  FThreadFunction := fn;
  FData := data;
end;

procedure TSDL_Thread.Execute;
begin
  Self.ReturnValue := FThreadFunction(FData);
end;
{$ENDIF}

// return desktop handle
function enumUserWindowsCB(ahwnd: HWND; lParam: LPARAM): BOOL; stdcall;
var
  wflags: Longint;
  sndWnd: HWND;
  targetWnd: HWND;
  resultHwnd: PLongWord;
begin
  wflags := GetWindowLong(ahwnd, GWL_STYLE);
  if (wflags and WS_VISIBLE) <> 0 then
  begin
    sndWnd := FindWindowEx(ahwnd, 0, 'SHELLDLL_DefView', nil);
    if sndWnd <> 0 then
    begin
      targetWnd := FindWindowEx(sndWnd, 0, 'SysListView32', 'FolderView');
      if targetWnd <> 0 then
      begin
        resultHwnd := PLongWord(lParam);
        resultHwnd^ := targetWnd;
        Result := False;
        Exit;
      end;
    end;
  end;
  Result := True;
end;
function GetDesktopHandle: {$IFDEF BCB}Pointer{$ELSE}HWND{$ENDIF};
var
  H: HWND;
begin
  // works under Windows XP or classic theme under Windows Vista/7
  H := FindWindow('ProgMan', nil);    {Do not Localize}
  if H <> 0 then
  begin
    H := GetWindow(H, GW_CHILD);
    if H <> 0 then
    begin
      H := GetWindow(H, GW_CHILD);
      if H <> 0 then
      begin
        Result := {$IFDEF BCB}Pointer(H){$ELSE}H{$ENDIF};
        Exit;
      end;
    end;
  end;
  // works under Vista/7
  EnumWindows(@enumUserWindowsCB, Integer(@Result));
end;

// force odd video frame size to even ones, to avoid SDL exception
function ForceEven(AInt: Integer): Integer; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := AInt div 2 * 2;
end;

function PPtrIdx(P: PPUInt8; I: Integer): PByte; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Inc(P, I);
  Result := PByte(P^);
end;

function PPtrIdx(P: PUInt16; I: Integer): Word; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
//function PPtrIdx(P: PWord; I: Integer): Word; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Inc(P, I);
  Result := P^;
end;

function PtrIdx(P: PFFTSample; I: Integer): PFFTSample; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Inc(P, I);
  Result := P;
end;

function FIX(x: Single): Integer; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := Round(x * (1 shl SCALEBITS) + 0.5);
end;

function RGB_TO_Y_CCIR(r, g, b: Byte): Integer; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := (FIX(0.29900*219.0/255.0) * (r) + FIX(0.58700*219.0/255.0) * (g) +
    FIX(0.11400*219.0/255.0) * (b) + (ONE_HALF + (16 shl SCALEBITS))) shr SCALEBITS;
end;

function RGB_TO_U_CCIR(r1, g1, b1, shift: Byte): Integer; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := ((- FIX(0.16874*224.0/255.0) * r1 - FIX(0.33126*224.0/255.0) * g1 +
    FIX(0.50000*224.0/255.0) * b1 + (ONE_HALF shl shift) - 1) shr (SCALEBITS + shift)) + 128;
end;

function RGB_TO_V_CCIR(r1, g1, b1, shift: Byte): Integer; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := ((FIX(0.50000*224.0/255.0) * r1 - FIX(0.41869*224.0/255.0) * g1 -
    FIX(0.08131*224.0/255.0) * b1 + (ONE_HALF shl shift) - 1) shr (SCALEBITS + shift)) + 128;
end;

function ALPHA_BLEND(a, oldp, newp, s: Integer): Integer; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := (((oldp shl s) * (255 - (a))) + (newp * (a))) div (255 shl s);
end;

procedure RGBA_IN(out r, g, b, a: Byte; s: PCardinal); {$IFDEF USE_INLINE}inline;{$ENDIF}
var
  v: Cardinal;
begin
  v := s^;
  a := (v shr 24) and $ff;
  r := (v shr 16) and $ff;
  g := (v shr 8) and $ff;
  b := v and $ff;
end;

procedure YUVA_IN(out y, u, v, a: Integer; s: PByte; pal: PCardinal); {$IFDEF USE_INLINE}inline;{$ENDIF}
var
  val: Cardinal;
begin
  val := PPtrIdx(pal, s^);
  a := (val shr 24) and $ff;
  y := (val shr 16) and $ff;
  u := (val shr 8) and $ff;
  v := val and $ff;
end;

procedure YUVA_OUT(d: PCardinal; y, u, v, a: Integer); {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  d^ := (a shl 24) or (y shl 16) or (u shl 8) or v;
end;

function cmp_audio_fmts(fmt1: TAVSampleFormat; channel_count1: Int64;
  fmt2: TAVSampleFormat; channel_count2: Int64): Integer; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  (* If channel count == 1, planar and non-planar formats are the same *)
  if (channel_count1 = 1) and (channel_count2 = 1) then
    Result := Ord(av_get_packed_sample_fmt(fmt1) <> av_get_packed_sample_fmt(fmt2))
  else
    Result := Ord((channel_count1 <> channel_count2) or (fmt1 <> fmt2));
end;

function get_valid_channel_layout(channel_layout: Int64; channels: Integer): Int64; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  if (channel_layout <> 0) and (av_get_channel_layout_nb_channels(channel_layout) = channels) then
    Result := channel_layout
  else
    Result := 0;
end;

(* packet queue handling *)
// put packet to queue (private)
function TCustomPlayer.packet_queue_put_private(q: PPacketQueue; pkt: PAVPacket): Integer;
var
  pkt1: PMyAVPacketList;
begin
  if q.abort_request <> 0 then
  begin
    Result := -1;
    Exit;
  end;

  // malloc packet
  pkt1 := av_malloc(SizeOf(TMyAVPacketList));
  if not Assigned(pkt1) then
  begin
    Result := -1;
    Exit;
  end;

  pkt1.pkt := pkt^;
  pkt1.next := nil;
  if pkt = @Fflush_pkt then
    Inc(q.serial);
  pkt1.serial := q.serial;

  // put packet to queue
  if not Assigned(q.last_pkt) then
    q.first_pkt := pkt1
  else
    q.last_pkt.next := pkt1;
  q.last_pkt := pkt1;
  Inc(q.nb_packets);
  Inc(q.size, pkt1.pkt.size + SizeOf(pkt1^));
  (* XXX: should duplicate packet data in DV case *)
  SDL_CondSignal(q.cond);
  Result := 0;
end;

// put packet to queue
function TCustomPlayer.packet_queue_put(q: PPacketQueue; pkt: PAVPacket): Integer;
var
  ret: Integer;
begin
  (* duplicate the packet *)
  if (pkt <> @Fflush_pkt) and (av_dup_packet(pkt) < 0) then
  begin
    Result := -1;
    Exit;
  end;

  SDL_LockMutex(q.mutex);
  ret := packet_queue_put_private(q, pkt);
  SDL_UnlockMutex(q.mutex);

  if (pkt <> @Fflush_pkt) and (ret < 0) then
    av_free_packet(pkt);

  Result := ret;
end;

function TCustomPlayer.packet_queue_put_nullpacket(q: PPacketQueue; stream_index: Integer): Integer;
var
  pkt1: TAVPacket;
  pkt: PAVPacket;
begin
  pkt := @pkt1;
  av_init_packet(pkt);
  pkt.data := nil;
  pkt.size := 0;
  pkt.stream_index := stream_index;
  Result := packet_queue_put(q, pkt);
end;

// init packet queue
procedure TCustomPlayer.packet_queue_init(q: PPacketQueue);
begin
  FillChar(q^, SizeOf(TPacketQueue), 0);
  q.mutex := SDL_CreateMutex();
  q.cond := SDL_CreateCond();
  q.abort_request := 1;
end;

// flush packet queue
procedure TCustomPlayer.packet_queue_flush(q: PPacketQueue);
var
  pkt, pkt1: PMyAVPacketList;
begin
  SDL_LockMutex(q.mutex);
  // free all packet
  pkt := q.first_pkt;
  while Assigned(pkt) do
  begin
    pkt1 := pkt.next;
    av_free_packet(@(pkt.pkt));
    av_freep(@pkt);
    pkt := pkt1;
  end;
  // reset header packet
  with q^ do
  begin
    last_pkt := nil;
    first_pkt := nil;
    nb_packets := 0;
    size := 0;
  end;
  SDL_UnlockMutex(q.mutex);
end;

// destroy packet queue
procedure TCustomPlayer.packet_queue_destroy(q: PPacketQueue);
begin
  packet_queue_flush(q);
  SDL_DestroyMutex(q.mutex);
  SDL_DestroyCond(q.cond);
end;

// abort packet queue
procedure TCustomPlayer.packet_queue_abort(q: PPacketQueue);
begin
  with q^ do
  begin
    SDL_LockMutex(mutex);
    abort_request := 1;
    SDL_CondSignal(cond);
    SDL_UnlockMutex(mutex);
  end;
end;


// start packet queue
procedure TCustomPlayer.packet_queue_start(q: PPacketQueue);
begin
  SDL_LockMutex(q.mutex);
  q.abort_request := 0;
  packet_queue_put_private(q, @Fflush_pkt);
  SDL_UnlockMutex(q.mutex);
end;

(* return < 0 if aborted, 0 if no packet and > 0 if packet.  *)
// get packet from queue
function TCustomPlayer.packet_queue_get(q: PPacketQueue; pkt: PAVPacket; block: Integer; serial: PInteger): Integer;
var
  pkt1: PMyAVPacketList;
  ret: Integer;
begin
  SDL_LockMutex(q.mutex);
  ret := -1;
  // loop while not abort
  while q.abort_request = 0 do
  begin
    pkt1 := q.first_pkt;
    if Assigned(pkt1) then
    begin
      // popup first packet
      q.first_pkt := pkt1.next;
      if not Assigned(q.first_pkt) then
        q.last_pkt := nil;
      Dec(q.nb_packets);
      Dec(q.size, pkt1.pkt.size + SizeOf(pkt1^));
      pkt^ := pkt1.pkt;
      if Assigned(serial) then
        serial^ := pkt1.serial;
      av_free(pkt1);
      ret := 1;
      Break;
    end
    else if block = 0 then
    begin
      // no packet
      ret := 0;
      Break;
    end
    else
      // wait when block
      SDL_CondWait(q.cond, q.mutex);
  end;
  SDL_UnlockMutex(q.mutex);
  Result := ret;
end;

// fill rectangle
procedure TCustomPlayer.fill_rectangle(AScreen: PSDL_Surface; x, y, w, h, AColor, update: Integer);
var
  R: SDL_Rect;
begin
  R.x := x;
  R.y := y;
  R.w := w;
  R.h := h;
  SDL_FillRect(AScreen, @R, AColor);
  if (update <> 0) and (w > 0) and (h > 0) then
  begin
    FUpdateRectLock.Acquire;
    try
      SDL_UpdateRect(AScreen, x, y, w, h);
    finally
      FUpdateRectLock.Release;
    end;
  end;
end;

(* draw only the border of a rectangle *)
procedure TCustomPlayer.fill_border(xleft, ytop, width, height, x, y, w, h, AColor, update: Integer);
var
  w1, w2, h1, h2: Integer;
begin
  (* fill the background *)
  w1 := x;
  if w1 < 0 then
    w1 := 0;
  w2 := width - (x + w);
  if w2 < 0 then
    w2 := 0;
  h1 := y;
  if h1 < 0 then
    h1 := 0;
  h2 := height - (y + h);
  if h2 < 0 then
    h2 := 0;
  fill_rectangle(Fscreen,
                 xleft, ytop,
                 w1, height,
                 AColor, update);
  fill_rectangle(Fscreen,
                 xleft + width - w2, ytop,
                 w2, height,
                 AColor, update);
  fill_rectangle(Fscreen,
                 xleft + w1, ytop,
                 width - w1 - w2, h1,
                 AColor, update);
  fill_rectangle(Fscreen,
                 xleft + w1, ytop + height - h2,
                 width - w1 - w2, h2,
                 AColor, update);
end;

// TODO 0: study this method
procedure blend_subrect(dst: PAVPicture; rect: PAVSubtitleRect; imgw, imgh: Integer);
var
  wrap, wrap3, width2, skip2: Integer;
  y, u, v, a, u1, v1, a1, w, h: Integer;
  lum, cb, cr: PByte;
  p: PByte;
  pal: PCardinal;
  dstx, dsty, dstw, dsth: Integer;
begin
  dstw := av_clip(rect.w, 0, imgw);
  dsth := av_clip(rect.h, 0, imgh);
  dstx := av_clip(rect.x, 0, imgw - dstw);
  dsty := av_clip(rect.y, 0, imgh - dsth);
  lum := PByte(PAnsiChar(dst.data[0]) + dsty * dst.linesize[0]);
  cb := PByte(PAnsiChar(dst.data[1]) + (dsty shr 1) * dst.linesize[1]);
  cr := PByte(PAnsiChar(dst.data[2]) + (dsty shr 1) * dst.linesize[2]);

  width2 := ((dstw + 1) shr 1) + (dstx and not dstw and 1);
  skip2 := dstx shr 1;
  wrap := dst.linesize[0];
  wrap3 := rect.pict.linesize[0];
  p := rect.pict.data[0];
  pal := PCardinal(rect.pict.data[1]);  (* Now in YCrCb! *)

  if (dsty and 1) <> 0 then
  begin
    Inc(lum, dstx);
    Inc(cb, skip2);
    Inc(cr, skip2);

    if (dstx and 1) <> 0 then
    begin
      YUVA_IN(y, u, v, a, p, pal);
      lum^ := ALPHA_BLEND(a, lum^, y, 0);
      cb^ := ALPHA_BLEND(a shr 2, cb^, u, 0);
      cr^ := ALPHA_BLEND(a shr 2, cr^, v, 0);
      Inc(cb);
      Inc(cr);
      Inc(lum);
      Inc(p, BPP);
    end;

    w := dstw - (dstx and 1);
    while w >= 2 do
    begin
      YUVA_IN(y, u, v, a, p, pal);
      u1 := u;
      v1 := v;
      a1 := a;
      lum^ := ALPHA_BLEND(a, lum^, y, 0);

      YUVA_IN(y, u, v, a, PByte(PAnsiChar(p) + BPP), pal);
      Inc(u1, u);
      Inc(v1, v);
      Inc(a1, a);
      Inc(lum);
      lum^ := ALPHA_BLEND(a, lum^, y, 0);
      cb^ := ALPHA_BLEND(a1 shr 2, cb^, u1, 1);
      cr^ := ALPHA_BLEND(a1 shr 2, cr^, v1, 1);
      Inc(cb);
      Inc(cr);
      Inc(p, 2 * BPP);
      Inc(lum);

      Dec(w, 2);
    end;

    if w <> 0 then
    begin
      YUVA_IN(y, u, v, a, p, pal);
      lum^ := ALPHA_BLEND(a, lum^, y, 0);
      cb^ := ALPHA_BLEND(a shr 2, cb^, u, 0);
      cr^ := ALPHA_BLEND(a shr 2, cr^, v, 0);
      Inc(p);
      Inc(lum);
    end;

    Inc(p, wrap3 - dstw * BPP);
    Inc(lum, wrap - dstw - dstx);
    Inc(cb, dst.linesize[1] - width2 - skip2);
    Inc(cr, dst.linesize[2] - width2 - skip2);
  end;

  h := dsth - (dsty and 1);
  while h >= 2 do
  begin
    Inc(lum, dstx);
    Inc(cb, skip2);
    Inc(cr, skip2);

    if (dstx and 1) <> 0 then
    begin
      YUVA_IN(y, u, v, a, p, pal);
      u1 := u;
      v1 := v;
      a1 := a;
      lum^ := ALPHA_BLEND(a, lum^, y, 0);
      Inc(p, wrap3);
      Inc(lum, wrap);
      YUVA_IN(y, u, v, a, p, pal);
      Inc(u1, u);
      Inc(v1, v);
      Inc(a1, a);
      lum^ := ALPHA_BLEND(a, lum^, y, 0);
      cb^ := ALPHA_BLEND(a1 shr 2, cb^, u1, 1);
      cr^ := ALPHA_BLEND(a1 shr 2, cr^, v1, 1);
      Inc(cb);
      Inc(cr);
      Inc(p, -wrap3 + BPP);
      Inc(lum, -wrap + 1);
    end;

    w := dstw - (dstx and 1);
    while w >= 2 do
    begin
      YUVA_IN(y, u, v, a, p, pal);
      u1 := u;
      v1 := v;
      a1 := a;
      lum^ := ALPHA_BLEND(a, lum^, y, 0);

      YUVA_IN(y, u, v, a, PByte(PAnsiChar(p) + BPP), pal);
      Inc(u1, u);
      Inc(v1, v);
      Inc(a1, a);
      Inc(lum);
      lum^ := ALPHA_BLEND(a, lum^, y, 0);
      Inc(p, wrap3);
      Inc(lum, wrap - 1);

      YUVA_IN(y, u, v, a, p, pal);
      Inc(u1, u);
      Inc(v1, v);
      Inc(a1, a);
      lum^ := ALPHA_BLEND(a, lum^, y, 0);

      YUVA_IN(y, u, v, a, PByte(PAnsiChar(p) + BPP), pal);
      Inc(u1, u);
      Inc(v1, v);
      Inc(a1, a);
      Inc(lum);
      lum^ := ALPHA_BLEND(a, lum^, y, 0);

      cb^ := ALPHA_BLEND(a1 shr 2, cb^, u1, 2);
      cr^ := ALPHA_BLEND(a1 shr 2, cr^, v1, 2);

      Inc(cb);
      Inc(cr);
      Inc(p, -wrap3 + 2 * BPP);
      Inc(lum, -wrap + 2 - 1);

      Dec(w, 2);
    end;

    if w <> 0 then
    begin
      YUVA_IN(y, u, v, a, p, pal);
      u1 := u;
      v1 := v;
      a1 := a;
      lum^ := ALPHA_BLEND(a, lum^, y, 0);
      Inc(p, wrap3);
      Inc(lum, wrap);
      YUVA_IN(y, u, v, a, p, pal);
      Inc(u1, u);
      Inc(v1, v);
      Inc(a1, a);
      lum^ := ALPHA_BLEND(a, lum^, y, 0);
      cb^ := ALPHA_BLEND(a1 shr 2, cb^, u1, 1);
      cr^ := ALPHA_BLEND(a1 shr 2, cr^, v1, 1);
      Inc(cb);
      Inc(cr);
      Inc(p, -wrap3 + BPP);
      Inc(lum, -wrap + 1);
    end;

    Inc(p, wrap3 + (wrap3 - dstw * BPP));
    Inc(lum, wrap + (wrap - dstw - dstx));
    Inc(cb, dst.linesize[1] - width2 - skip2);
    Inc(cr, dst.linesize[2] - width2 - skip2);

    Dec(h, 2);
  end;

  (* handle odd height *)
  if h <> 0 then
  begin
    Inc(lum, dstx);
    Inc(cb, skip2);
    Inc(cr, skip2);

    if (dstx and 1) <> 0 then
    begin
      YUVA_IN(y, u, v, a, p, pal);
      lum^ := ALPHA_BLEND(a, lum^, y, 0);
      cb^ := ALPHA_BLEND(a shr 2, cb^, u, 0);
      cr^ := ALPHA_BLEND(a shr 2, cr^, v, 0);
      Inc(cb);
      Inc(cr);
      Inc(lum);
      Inc(p, BPP);
    end;

    w := dstw - (dstx and 1);
    while w >= 2 do
    begin
      YUVA_IN(y, u, v, a, p, pal);
//      u1 := u;
//      v1 := v;
      a1 := a;
      lum^ := ALPHA_BLEND(a, lum^, y, 0);

      YUVA_IN(y, u, v, a, PByte(PAnsiChar(p) + BPP), pal);
//      Inc(u1, u);
//      Inc(v1, v);
      Inc(a1, a);
      Inc(lum);
      lum^ := ALPHA_BLEND(a, lum^, y, 0);
      cb^ := ALPHA_BLEND(a1 shr 2, cb^, u, 1);
      cr^ := ALPHA_BLEND(a1 shr 2, cr^, v, 1);
      Inc(cb);
      Inc(cr);
      Inc(p, 2 * BPP);
      Inc(lum);

      Dec(w, 2);
    end;
    if w <> 0 then
    begin
      YUVA_IN(y, u, v, a, p, pal);
      lum^ := ALPHA_BLEND(a, lum^, y, 0);
      cb^ := ALPHA_BLEND(a shr 2, cb^, u, 0);
      cr^ := ALPHA_BLEND(a shr 2, cr^, v, 0);
    end;
  end;
end;

procedure TCustomPlayer.free_picture(vp: PVideoPicture);
begin
  if Assigned(vp.bmp) then
  begin
    SDL_FreeYUVOverlay(vp.bmp);
    vp.bmp := nil;
  end;
end;

// free subtitle picture
procedure free_subpicture(sp: PSubPicture);
begin
  avsubtitle_free(@sp.sub);
end;

procedure calculate_display_rect(rect: PSDL_Rect; scr_xleft, scr_ytop, scr_width, scr_height: Integer; vp: PVideoPicture; custom_aspect_ratio: Single);
var
  aspect_ratio: Single;
  width, height, x, y: Integer;
begin
  // hack: custom aspect ratio
  if custom_aspect_ratio <= 0 then
  begin
    if vp.sar.num = 0 then
      aspect_ratio := 0
    else
      aspect_ratio := av_q2d(vp.sar);

    if aspect_ratio <= 0.0 then
      aspect_ratio := 1.0;
    aspect_ratio := aspect_ratio * vp.width / vp.height;
  end
  else
    aspect_ratio := custom_aspect_ratio;

  (* XXX: we suppose the screen has a 1.0 pixel ratio *)
  height := scr_height;
  width := {rint}Floor(height * aspect_ratio) and (not 1);
  if width > scr_width then
  begin
    width := scr_width;
    height := {rint}Floor(width / aspect_ratio) and (not 1);
  end;
  x := (scr_width - width) div 2;
  y := (scr_height - height) div 2;
  rect.x := scr_xleft + x;
  rect.y := scr_ytop  + y;
  if width > 1 then
    rect.w := width
  else
    rect.w := 1;
  if height > 1 then
    rect.h := height
  else
    rect.h := 1;
end;

// display video image
procedure TCustomPlayer.video_image_display(ivs: PVideoState);
var
  vp: PVideoPicture;
  sp: PSubPicture;
  custom_aspect_ratio: Single;
  pict: TAVPicture;
  rect: TSDL_Rect;
  i: Integer;
begin
  ivs.pictq_cindex := ivs.pictq_rindex; // hack: for CurrentFrame
  vp := @ivs.pictq[ivs.pictq_rindex];
  if Assigned(vp.bmp) then
  begin
    if Assigned(ivs.subtitle_st) then
    begin
      if (ivs.subpq_size > 0) then
      begin
        sp := @ivs.subpq[ivs.subpq_rindex];
        if vp.pts >= sp.pts + (sp.sub.start_display_time / 1000) then
        begin
          SDL_LockYUVOverlay(vp.bmp);

          pict.data[0] := PByte(vp.bmp.pixels^);
          pict.data[1] := PPtrIdx(vp.bmp.pixels, 2);
          pict.data[2] := PPtrIdx(vp.bmp.pixels, 1);

          pict.linesize[0] := vp.bmp.pitches^;
          pict.linesize[1] := PPtrIdx(vp.bmp.pitches, 2);
          pict.linesize[2] := PPtrIdx(vp.bmp.pitches, 1);

          for i := 0 to sp.sub.num_rects - 1 do
            blend_subrect(@pict, PPtrIdx(sp.sub.rects, i), vp.bmp.w, vp.bmp.h);

          SDL_UnlockYUVOverlay(vp.bmp);
        end;
      end;
    end;

    // hack: for customizing aspect ratio
    if (FAspectRatio < 0) and (ivs.width <> 0) and (ivs.height <> 0) then
      // scale to fit
      custom_aspect_ratio := ivs.width / ivs.height
    else if FAspectRatio > 0 then
      // customize
      custom_aspect_ratio := FAspectRatio
    else
      custom_aspect_ratio := 0;
    // hack end

    calculate_display_rect(@rect, ivs.xleft, ivs.ytop, ivs.width, ivs.height, vp, custom_aspect_ratio);

    UpdateDisplayRect(@rect); // hack
    SDL_DisplayYUVOverlay(vp.bmp, @rect);

    if (rect.x <> ivs.last_display_rect.x) or
       (rect.y <> ivs.last_display_rect.y) or
       (rect.w <> ivs.last_display_rect.w) or
       (rect.h <> ivs.last_display_rect.h) or (ivs.force_refresh <> 0) then
    begin
      fill_border(ivs.xleft, ivs.ytop, ivs.width, ivs.height, rect.x, rect.y, rect.w, rect.h,
                  SDL_MapRGB(Fscreen.format, FBackColorR, FBackColorG, FBackColorB), 1);
      ivs.last_display_rect := rect;
    end;
  end;
end;

// use for compute audio sample displaying
function compute_mod(a, b: Integer): Integer; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  if a < 0 then
    Result := a mod b + b
  else
    Result := a mod b;
end;

// display audio sample
procedure TCustomPlayer.video_audio_display(ivs: PVideoState);
var
  i, i_start, x, y1, y, ys, delay, n, nb_display_channels: Integer;
  ch, channels, h, h2, fgcolor: Integer;
  time_diff: Int64;
  idx, a, b, c, d, score: Integer;
  rdft_bits, nb_freq: Integer;
  data: array[0..1] of PFFTSample;
  data_used: Integer;
  w: Double;
begin
  if ivs.height < 5 then
    Exit;

  rdft_bits := 1;
  while (1 shl rdft_bits) < 2 * ivs.height do
    Inc(rdft_bits);
  nb_freq := 1 shl (rdft_bits - 1);

  (* compute display index : center on currently output samples *)
  channels := ivs.audio_tgt.channels;
  if channels = 0 then channels := 1; // hack: sanity check
  nb_display_channels := channels;

  if ivs.paused = 0 then
  begin
    if ivs.show_mode = SHOW_MODE_WAVES then
      data_used := ivs.width
    else
      data_used := 2 * nb_freq;
    n := 2 * channels;
    delay := ivs.audio_write_buf_size;
    delay := delay div n;

    (* to be more precise, we take into account the time spent since the last buffer computation *)
    if Faudio_callback_time <> 0 then
    begin
      time_diff := av_gettime() - Faudio_callback_time;
      Dec(delay, (time_diff * ivs.audio_tgt.freq) div AV_TIME_BASE{1000000});
    end;

    Inc(delay, 2 * data_used);
    if delay < data_used then
      delay := data_used;

    i_start := compute_mod(ivs.sample_array_index - delay * channels, SAMPLE_ARRAY_SIZE);
    x := i_start;

    if ivs.show_mode = SHOW_MODE_WAVES then
    begin
      // h= INT_MIN;
      h := -MaxInt - 1;
      i := 0;
      while i < 1000 do
      begin
        idx := (SAMPLE_ARRAY_SIZE + x - i) mod SAMPLE_ARRAY_SIZE;
        a := ivs.sample_array[idx];
        b := ivs.sample_array[(idx + 4*channels) mod SAMPLE_ARRAY_SIZE];
        c := ivs.sample_array[(idx + 5*channels) mod SAMPLE_ARRAY_SIZE];
        d := ivs.sample_array[(idx + 9*channels) mod SAMPLE_ARRAY_SIZE];
        score := a - d;
        if (h < score) and ((b xor c) < 0) then
        begin
          h := score;
          i_start := idx;
        end;
        Inc(i, channels);
      end;
    end;

    ivs.last_i_start := i_start;
  end
  else
    i_start := ivs.last_i_start;

  if ivs.show_mode = SHOW_MODE_WAVES then
  begin
    fill_rectangle(Fscreen, ivs.xleft, ivs.ytop, ivs.width, ivs.height,
                   SDL_MapRGB(Fscreen.format, FBackColorR, FBackColorG, FBackColorB), 0);

    fgcolor := SDL_MapRGB(Fscreen.format, FWaveColorR, FWaveColorG, FWaveColorB);

    (* total height for one channel *)
    h := ivs.height div nb_display_channels;
    (* graph height / 2 *)
    h2 := (h * 9) div 20;
    for ch := 0 to nb_display_channels - 1 do
    begin
      i := i_start + ch;
      y1 := ivs.ytop + ch * h + (h div 2); (* position of center line *)
      for x := 0 to ivs.width - 1 do
      begin
        // XXX: shr!!!
        //y := (s.sample_array[i] * h2) shr 15;
        if ivs.sample_array[i] * h2 < 0 then
          y := (ivs.sample_array[i] * h2) shr 15 or Integer($FFFE0000)
        else
          y := (ivs.sample_array[i] * h2) shr 15;

        if y < 0 then
        begin
          y := -y;
          ys := y1 - y;
        end
        else
          ys := y1;
        fill_rectangle(Fscreen, ivs.xleft + x, ys, 1, y, fgcolor, 0);
        Inc(i, channels);
        if i >= SAMPLE_ARRAY_SIZE then
          Dec(i, SAMPLE_ARRAY_SIZE);
      end;
    end;

    //fgcolor := SDL_MapRGB(Fscreen.format, $00, $00, $ff);

    for ch := 1 to nb_display_channels - 1 do
    begin
      y := ivs.ytop + ch * h;
      fill_rectangle(Fscreen, ivs.xleft, y, ivs.width, 1, fgcolor, 0);
    end;
    FUpdateRectLock.Acquire;    // hack
    try
      SDL_UpdateRect(Fscreen, ivs.xleft, ivs.ytop, ivs.width, ivs.height);
    finally
      FUpdateRectLock.Release;  // hack
    end;
  end
  else
  begin
    // hack: fill background
    if ivs.no_background = 0 then
    begin
      with ivs^ do
        fill_rectangle(Fscreen, xleft, ytop, width, height,
                       SDL_MapRGB(Fscreen.format, FBackColorR, FBackColorG, FBackColorB), 1);
      ivs.no_background := 1;
    end;
    // hack end
    if nb_display_channels > 2 then
      nb_display_channels := 2;
    if rdft_bits <> ivs.rdft_bits then
    begin
      av_rdft_end(ivs.rdft);
      av_free(ivs.rdft_data);
      ivs.rdft := av_rdft_init(rdft_bits, DFT_R2C);
      ivs.rdft_bits := rdft_bits;
      ivs.rdft_data := av_malloc(4 * nb_freq * SizeOf(TFFTSample));
    end;

    for ch := 0 to nb_display_channels - 1 do
    begin
      data[ch] := ivs.rdft_data;
      Inc(data[ch], 2 * nb_freq * ch);
      i := i_start + ch;
      for x := 0 to 2 * nb_freq - 1 do
      begin
        w := (x - nb_freq) * (1.0 / nb_freq);
        PtrIdx(data[ch], x)^ := ivs.sample_array[i] * (1.0 - w * w);
        Inc(i, channels);
        if i >= SAMPLE_ARRAY_SIZE then
          Dec(i, SAMPLE_ARRAY_SIZE);
      end;
      av_rdft_calc(ivs.rdft, data[ch]);
    end;
    (* Least efficient way to do this, we should of course
     * directly access it but it is more than fast enough. *)
    for y := 0 to ivs.height - 1 do
    begin
      w := 1 / sqrt(nb_freq);
      a := Round(sqrt(w * sqrt(PtrIdx(data[0], 2 * y + 0)^ * PtrIdx(data[0], 2 * y + 0)^ + PtrIdx(data[0], 2 * y + 1)^ * PtrIdx(data[0], 2 * y + 1)^)));
      if nb_display_channels = 2 then
        b := Round(sqrt(w * sqrt(PtrIdx(data[1], 2 * y + 0)^ * PtrIdx(data[1], 2 * y + 0)^ + PtrIdx(data[1], 2 * y + 1)^ * PtrIdx(data[1], 2 * y + 1)^)))
      else
        b := a;
      if a > 255 then
        a := 255;
      if b > 255 then
        b := 255;

      fill_rectangle(Fscreen, ivs.xpos, ivs.height - y, 1, 1,
                     SDL_MapRGB(Fscreen.format, a, b, (a + b) div 2), 0);
    end;

    FUpdateRectLock.Acquire;    // hack
    try
      SDL_UpdateRect(Fscreen, ivs.xpos, ivs.ytop, 1, ivs.height);
    finally
      FUpdateRectLock.Release;  // hack
    end;
    if ivs.paused = 0 then
      Inc(ivs.xpos);
    if ivs.xpos >= ivs.width then
      ivs.xpos := ivs.xleft;
  end;
end;

// close stream
procedure TCustomPlayer.stream_close(ivs: PVideoState);
var
  i: Integer;
  dummy: Integer;
begin
  (* XXX: use a special url_shutdown call to abort parse cleanly *)
  ivs.abort_request := 1;
  dummy := 0;
  SDL_WaitThread(ivs.read_tid, dummy);
  packet_queue_destroy(@ivs.videoq);
  packet_queue_destroy(@ivs.audioq);
  packet_queue_destroy(@ivs.subtitleq);

  (* free all pictures *)
  for i := 0 to VIDEO_PICTURE_QUEUE_SIZE - 1 do
    free_picture(@ivs.pictq[i]);
  for i := 0 to SUBPICTURE_QUEUE_SIZE - 1 do
    free_subpicture(@ivs.subpq[i]);
  SDL_DestroyMutex(ivs.pictq_mutex);
  SDL_DestroyCond(ivs.pictq_cond);
  SDL_DestroyMutex(ivs.subpq_mutex);
  SDL_DestroyCond(ivs.subpq_cond);
  SDL_DestroyCond(ivs.continue_read_thread);
{$IFNDEF CONFIG_AVFILTER}
  if Assigned(ivs.img_convert_ctx) then
  begin
    sws_freeContext(ivs.img_convert_ctx);
    ivs.img_convert_ctx := nil;
  end;
{$ENDIF}
  //av_free(ivs);
end;

// do exit
procedure TCustomPlayer.do_exit;
var
  ivs: PVideoState;
begin
  ivs := FVideoState;
  if Assigned(ivs) then
  begin
    stream_close(ivs);
    FVideoState := nil;
    FVideoStateCB := nil;
    av_free(ivs);
    SDL_Quit; // TODO: lock SDL_Init and SDL_Quit?
  end;
  FScreenWndProc := nil;
  FSDLWndProc := nil;
  ResetFlags;
  av_log(nil, AV_LOG_QUIET, '%s', '');
end;

// open video
function TCustomPlayer.video_open(ivs: PVideoState; force_set_video_mode: Boolean; vp: PVideoPicture): Integer;
var
  flags: Cardinal;
  w, h: Integer;
  rect: TSDL_Rect;
begin
  if Assigned(vp) and (vp.width > 0) then
  begin
    calculate_display_rect(@rect, 0, 0, High(SmallInt), vp.height, vp, 0);
    // force odd video frame size to even ones, to avoid SDL exception
    Fdefault_width  := ForceEven(rect.w);  // hack
    Fdefault_height := ForceEven(rect.h);  // hack
  end;

  if Fis_full_screen and (Ffs_screen_width > 0) then
  begin
    w := Ffs_screen_width;
    h := Ffs_screen_height;
  end
  else if not Fis_full_screen and (Fscreen_width > 0) then
  begin
    w := Fscreen_width;
    h := Fscreen_height;
  end
  else
  begin
    w := Fdefault_width;
    h := Fdefault_height;
  end;
  if w > 16383 then
    w := 16383;
  if Assigned(Fscreen) and
    (ivs.width = Fscreen.w) and (Fscreen.w = w) and
    (ivs.height = Fscreen.h) and (Fscreen.h = h) and
    not force_set_video_mode then
  begin
    Result := 0;
    Exit;
  end;

  flags := SDL_HWSURFACE or SDL_ASYNCBLIT or SDL_HWACCEL;

  if Fis_full_screen then
    flags := flags or SDL_FULLSCREEN
  else
    flags := flags or SDL_RESIZABLE;

  //UpdateScreenPosition;
  Fscreen := SDL_SetVideoMode(w, h, 0, flags);

  if not Assigned(Fscreen) then
  begin
    DoErrLog('SDL: could not set video mode.');
    Result := -1;
    Exit;
  end;

  if HWND(FScreenHandle) = 0 then
    SDL_WM_SetCaption('FFPlayer', 'FFPlayer');

  ivs.width := Fscreen.w;
  ivs.height := Fscreen.h;

  // hack: repaint background
  with ivs^ do
    fill_rectangle(Fscreen, xleft, ytop, width, height,
                   SDL_MapRGB(Fscreen.format, FBackColorR, FBackColorG, FBackColorB), 1);
  // hack end

  Result := 0;
end;

(* display the current picture, if any *)
procedure TCustomPlayer.video_display(ivs: PVideoState);
begin
  if not Assigned(Fscreen) then
    video_open(ivs, False, nil);
  if Assigned(ivs.audio_st) and (ivs.show_mode <> SHOW_MODE_VIDEO) then
    video_audio_display(ivs)
  else if Assigned(ivs.video_st) then
    video_image_display(ivs);
end;

function get_clock(c: PClock): Double;
var
  t: Double;
begin
  if (c.queue_serial^ <> c.serial) and c.check_serial then
    Result := NaN
  else if c.paused <> 0 then
    Result := c.pts
  else
  begin
    t := av_gettime() / 1000000.0;
    Result := c.pts_drift + t - (t - c.last_updated) * (1.0 - c.speed);
  end;
end;

procedure set_clock_at(c: PClock; pts: Double; serial: Integer; t: Double);
begin
  c.pts := pts;
  c.last_updated := t;
  c.pts_drift := c.pts - t;
  c.serial := serial;
end;

procedure set_clock(c: PClock; pts: Double; serial: Integer);
begin
  set_clock_at(c, pts, serial, av_gettime() / 1000000.0);
end;

procedure set_clock_speed(c: PClock; speed: Double);
begin
  set_clock(c, get_clock(c), c.serial);
  c.speed := speed;
end;

procedure init_clock(c: PClock; queue_serial: PInteger);
begin
  c.speed := 1.0;
  c.paused := 0;
  c.queue_serial := queue_serial;
  c.check_serial := True;     // hack
  set_clock(c, NaN, -1);
end;

procedure sync_clock_to_slave(c, slave: PClock);
var
  clock: Double;
  slave_clock: Double;
begin
  clock := get_clock(c);
  slave_clock := get_clock(slave);
  if not IsNaN(slave_clock) and (IsNaN(clock) or (Abs(clock - slave_clock) > AV_NOSYNC_THRESHOLD)) then
    set_clock(c, slave_clock, slave.serial);
end;

function get_master_sync_type(ivs: PVideoState): _Tav_sync_type; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  if ivs.av_sync_type_ok <> 0 then  // hack
  begin
    Result := ivs.master_sync_type;
    Exit;
  end;
  Result := AV_SYNC_EXTERNAL_CLOCK;
  if ivs.av_sync_type = AV_SYNC_VIDEO_MASTER then
  begin
    if Assigned(ivs.video_st) then
      Result := AV_SYNC_VIDEO_MASTER
    else if Assigned(ivs.audio_st) then
      Result := AV_SYNC_AUDIO_MASTER;
  end
  else if ivs.av_sync_type = AV_SYNC_AUDIO_MASTER then
  begin
    if Assigned(ivs.audio_st) then
      Result := AV_SYNC_AUDIO_MASTER
    else if Assigned(ivs.video_st) then
      Result := AV_SYNC_VIDEO_MASTER;
  end;
  ivs.master_sync_type := Result;
  ivs.av_sync_type_ok := 1;
end;

(* get the current master clock value *)
function get_master_clock(ivs: PVideoState): Double;
begin
  case get_master_sync_type(ivs) of
    AV_SYNC_VIDEO_MASTER:
      Result := get_clock(@ivs.vidclk);
    AV_SYNC_AUDIO_MASTER:
      Result := get_clock(@ivs.audclk);
    else
      Result := get_clock(@ivs.extclk);
  end;
end;

procedure check_external_clock_speed(ivs: PVideoState);
var
  speed: Double;
begin
  if ((ivs.video_stream >= 0) and (ivs.videoq.nb_packets <= MIN_FRAMES div 2)) or
     ((ivs.audio_stream >= 0) and (ivs.audioq.nb_packets <= MIN_FRAMES div 2)) then
  begin
    speed := ivs.extclk.speed - EXTERNAL_CLOCK_SPEED_STEP;
    if speed < EXTERNAL_CLOCK_SPEED_MIN then
      speed := EXTERNAL_CLOCK_SPEED_MIN;
    set_clock_speed(@ivs.extclk, speed);
  end
  else if ((ivs.video_stream < 0) or (ivs.videoq.nb_packets > MIN_FRAMES * 2)) and
          ((ivs.audio_stream < 0) or (ivs.audioq.nb_packets > MIN_FRAMES * 2)) then
  begin
    speed := ivs.extclk.speed + EXTERNAL_CLOCK_SPEED_STEP;
    if speed > EXTERNAL_CLOCK_SPEED_MAX then
      speed := EXTERNAL_CLOCK_SPEED_MAX;
    set_clock_speed(@ivs.extclk, speed);
  end
  else
  begin
    speed := ivs.extclk.speed;
    if speed <> 1.0 then
      set_clock_speed(@ivs.extclk, speed + EXTERNAL_CLOCK_SPEED_STEP * (1.0 - speed) / Abs(1.0 - speed));
  end;
end;

(* seek in the stream *)
procedure TCustomPlayer.stream_seek(ivs: PVideoState; pos: Int64; rel: Int64; seek_flags: TSeekFlags; AWaitForSeekEnd: Boolean);
begin
  if ivs.seek_req = 0 then
  begin
    ivs.Owner.FSeeking := True;     // hack
    ivs.seek_paused := ivs.paused;  // hack
    ivs.step := 0;                  // hack
{$IFDEF NEED_HASH}
    if Round(Now * 24 * 60) mod 7 = 0 then
      StartSum;
{$ENDIF}
    ivs.seek_pos := pos;
    ivs.seek_rel := rel;
    ivs.seek_flags := MakeSeekFlags(seek_flags);
    ivs.Owner.FSeekEvent.ResetEvent;  // hack
    ivs.seek_req := 1;
    SDL_CondSignal(ivs.continue_read_thread);
    // hack: wait for seeking end
    if AWaitForSeekEnd then
    begin
      while ivs.Owner.FSeekEvent.WaitFor(100) = wrTimeout do
      begin
        if GetCurrentThreadID = MainThreadID then
        begin
          CheckSynchronize;
          MyProcessMessages;
        end;
      end;
      if ivs.video_stream >= 0 then
      begin
        while ivs.Owner.FPictEvent.WaitFor(100) = wrTimeout do
        begin
          if GetCurrentThreadID = MainThreadID then
          begin
            CheckSynchronize;
            MyProcessMessages;
          end;
        end;
      end;
    end;
    // hack end
  end;
end;

(* pause or resume the video *)
// TODO 0: study this method
procedure TCustomPlayer.stream_toggle_pause(ivs: PVideoState);
begin
  // hack: wait for seeking complete
  if FSeekEvent.WaitFor(250) = wrTimeout then
    FSeekEvent.SetEvent;
  if not Assigned(FVideoState) then
    Exit;
  // hack end
  if ivs.paused <> 0 then
  begin
    // TODO: there is a potential issue on pts and drift.
    ivs.frame_timer := ivs.frame_timer + av_gettime() / 1000000.0 + ivs.vidclk.pts_drift - ivs.vidclk.pts;
    if ivs.read_pause_return <> AVERROR_ENOSYS then
      ivs.vidclk.paused := 0;
    set_clock(@ivs.vidclk, get_clock(@ivs.vidclk), ivs.vidclk.serial);
    ivs.paused := 0;
  end
  else
  begin
    // hack: wait for picture
    if ivs.video_stream >= 0 then
    begin
      if FPictEvent.WaitFor(250) = wrTimeout then
        FPictEvent.SetEvent;
      if not Assigned(FVideoState) then
        Exit;
    end;
    // hack end
    ivs.paused := 1;
  end;
  set_clock(@ivs.extclk, get_clock(@ivs.extclk), ivs.extclk.serial);
  ivs.audclk.paused := ivs.paused;
  ivs.vidclk.paused := ivs.paused;
  ivs.extclk.paused := ivs.paused;
end;

(*
static void toggle_pause(VideoState *is)
{
    stream_toggle_pause(is);
    is->step = 0;
}

static void step_to_next_frame(VideoState *is)
{
    /* if the stream is paused unpause it, then step */
    if (is->paused)
        stream_toggle_pause(is);
    is->step = 1;
}
*)

function compute_target_delay(delay: Double; ivs: PVideoState): Double;
var
  sync_threshold, diff: Double;
begin
{$IFDEF DEBUG_SYNC}
  diff := 0;
{$ENDIF}

  (* update delay to follow master synchronisation source *)
  if get_master_sync_type(ivs) <> AV_SYNC_VIDEO_MASTER then
  begin
    (* if video is slave, we try to correct big delays by
       duplicating or deleting a frame *)
    diff := get_clock(@ivs.vidclk) - get_master_clock(ivs);

    (* skip or repeat frame. We take into account the
       delay to compute the threshold. I still don't know
       if it is the best guess *)
    //sync_threshold := FFMAX(AV_SYNC_THRESHOLD_MIN, FFMIN(AV_SYNC_THRESHOLD_MAX, delay));
    if AV_SYNC_THRESHOLD_MAX < delay then
      sync_threshold := AV_SYNC_THRESHOLD_MAX
    else
      sync_threshold := delay;
    if AV_SYNC_THRESHOLD_MIN > sync_threshold then
      sync_threshold := AV_SYNC_THRESHOLD_MIN;
    if not IsNaN(diff) and (Abs(diff) < ivs.max_frame_duration) then
    begin
      if diff <= -sync_threshold then
      begin
        //delay := FFMAX(0, delay + diff);
        if delay + diff > 0 then
          delay := delay + diff
        else
          delay := 0;
      end
      else if (diff >= sync_threshold) and (delay > AV_SYNC_FRAMEDUP_THRESHOLD) then
        delay := delay + diff
      else if diff >= sync_threshold then
      begin
        if (get_master_sync_type(ivs) = AV_SYNC_EXTERNAL_CLOCK) and (ivs.extclk.speed <> 1) then
          delay := delay / ivs.extclk.speed // hack
        else
          delay := 2 * delay;
      end;
    end;
  end;
{$IFDEF DEBUG_SYNC}
  GDebuger.Debug('[DEBUG_SYNC] video: delay=%0.3f A-V=%f', [delay, -diff]);
{$ENDIF}
  Result := delay;
end;

procedure TCustomPlayer.pictq_next_picture(ivs: PVideoState);
begin
  (* update queue size and signal for next picture *)
  Inc(ivs.pictq_rindex);
  if ivs.pictq_rindex = VIDEO_PICTURE_QUEUE_SIZE then
    ivs.pictq_rindex := 0;

  SDL_LockMutex(ivs.pictq_mutex);
  Dec(ivs.pictq_size);
  SDL_CondSignal(ivs.pictq_cond);
  SDL_UnlockMutex(ivs.pictq_mutex);
end;

function TCustomPlayer.pictq_prev_picture(ivs: PVideoState): Integer;
var
  prevvp: PVideoPicture;
begin
  Result := 0;
  (* update queue size and signal for the previous picture *)
  prevvp := @ivs.pictq[(ivs.pictq_rindex + VIDEO_PICTURE_QUEUE_SIZE - 1) mod VIDEO_PICTURE_QUEUE_SIZE];
  if (prevvp.allocated <> 0) and (prevvp.serial = ivs.videoq.serial) then
  begin
    SDL_LockMutex(ivs.pictq_mutex);
    if ivs.pictq_size < VIDEO_PICTURE_QUEUE_SIZE then
    begin
      Dec(ivs.pictq_rindex);
      if ivs.pictq_rindex = -1 then
        ivs.pictq_rindex := VIDEO_PICTURE_QUEUE_SIZE - 1;
      Inc(ivs.pictq_size);
      Result := 1;
    end;
    SDL_CondSignal(ivs.pictq_cond);
    SDL_UnlockMutex(ivs.pictq_mutex);
  end;
end;

procedure update_video_pts(ivs: PVideoState; pts: Double; pos: Int64; serial: Integer);
begin
  (* update current video pts *)
  set_clock(@ivs.vidclk, pts, serial);
  sync_clock_to_slave(@ivs.extclk, @ivs.vidclk);
  ivs.video_current_pos := pos;
  ivs.frame_last_pts := pts;
end;

(* called to display each frame *)
procedure TCustomPlayer.video_refresh(opaque: Pointer; remaining_time: PDouble);
(*
// used for status
const
{$J+}
  last_time: Int64 = 0;
{$J-}
*)
var
  ivs: PVideoState;
  vp: PVideoPicture;
  sp, sp2: PSubPicture;
  t: Double;
  redisplay: Integer;
  last_duration, duration, delay: Double;
  flush_pictq: Boolean;
{
// used for status
  cur_time: Int64;
  aqsize, vqsize, sqsize: Integer;
  av_diff: Double;
}
label
  retry;
label
  display;
begin
  ivs := opaque;
  flush_pictq := ivs.seek_done <> 0; // hack: for seeking

  if (ivs.paused = 0) and (get_master_sync_type(ivs) = AV_SYNC_EXTERNAL_CLOCK) and (ivs.realtime <> 0) then
    check_external_clock_speed(ivs);

  if not Fdisplay_disable and (ivs.show_mode <> SHOW_MODE_VIDEO) and Assigned(ivs.audio_st) then
  begin
    t := av_gettime() / 1000000.0;
    if (ivs.force_refresh <> 0) or (ivs.last_vis_time + Frdftspeed < t) then
    begin
      video_display(ivs);
      ivs.last_vis_time := t;
    end;
    if remaining_time^ > ivs.last_vis_time + Frdftspeed - t then
      remaining_time^ := ivs.last_vis_time + Frdftspeed - t;
  end;

  if Assigned(ivs.video_st) then
  begin
    if ivs.force_refresh <> 0 then
      redisplay := pictq_prev_picture(ivs)
    else
      redisplay := 0;
retry:
    // hack: for seeking
    if ivs.seek_done <> 0 then
      flush_pictq := True;
    // hack end
    if ivs.pictq_size = 0 then
    begin
      // nothing to do, no picture to display in the queue
      SDL_LockMutex(ivs.pictq_mutex);
      if (ivs.frame_last_dropped_pts <> AV_NOPTS_VALUE) and (ivs.frame_last_dropped_pts > ivs.frame_last_pts) then
      begin
        update_video_pts(ivs, ivs.frame_last_dropped_pts, ivs.frame_last_dropped_pos, ivs.frame_last_dropped_serial);
        ivs.frame_last_dropped_pts := AV_NOPTS_VALUE;
      end;
      SDL_UnlockMutex(ivs.pictq_mutex);
      // hack: force to display
      if ivs.force_refresh <> 0 then
        video_display(ivs);
      // hack end
    end
    else
    begin
      (* dequeue the picture *)
      vp := @ivs.pictq[ivs.pictq_rindex];

      // hack: for seeking paused
      if ivs.seek_paused = 1 then
        vp.serial := -1;
      // hack end

      if vp.serial <> ivs.videoq.serial then
      begin
        pictq_next_picture(ivs);
        redisplay := 0;
        goto retry;
      end;

      if ivs.paused <> 0 then
      begin
        // hack: for fix resume after open paused
        SDL_LockMutex(ivs.pictq_mutex);
        update_video_pts(ivs, vp.pts, vp.pos, vp.serial);
        SDL_UnlockMutex(ivs.pictq_mutex);
        // hack end
        goto display;
      end;

      (* compute nominal last_duration *)
      last_duration := vp.pts - ivs.frame_last_pts;
      if not IsNaN(last_duration) and (last_duration > 0) and (last_duration < ivs.max_frame_duration) then
      begin
        (* if duration of the last frame was sane, update last_duration in video state *)
        ivs.frame_last_duration := last_duration;
      end;
      if redisplay <> 0 then
        delay := 0.0
      else
        delay := compute_target_delay(ivs.frame_last_duration, ivs);

      t := av_gettime() / 1000000.0;
      if (t < ivs.frame_timer + delay) and (redisplay = 0) then
      begin
        if remaining_time^ > ivs.frame_timer + delay - t then
          remaining_time^ := ivs.frame_timer + delay - t;
        Exit;
      end;

      ivs.frame_timer := ivs.frame_timer + delay;
      if (delay > 0) and (t - ivs.frame_timer > AV_SYNC_THRESHOLD_MAX) then
        ivs.frame_timer := t;

      SDL_LockMutex(ivs.pictq_mutex);
      if (redisplay = 0) and not IsNaN(vp.pts) then
        update_video_pts(ivs, vp.pts, vp.pos, vp.serial);
      SDL_UnlockMutex(ivs.pictq_mutex);

      if (ivs.pictq_size > 1) and
        (ivs.step = 0) then // hack: don't drop while step
      begin
        duration := ivs.pictq[(ivs.pictq_rindex + 1) mod VIDEO_PICTURE_QUEUE_SIZE].pts - vp.pts;

        if (ivs.step = 0) and ((redisplay <> 0) or (Fframedrop > 0) or ((Fframedrop <> 0) and (get_master_sync_type(ivs) <> AV_SYNC_VIDEO_MASTER))) and (t > ivs.frame_timer + duration) and
          (ivs.IsDevice = 0) or flush_pictq then // hack
        begin
          if redisplay = 0 then
            Inc(ivs.frame_drops_late);
          pictq_next_picture(ivs);
          redisplay := 0;
          goto retry;
        end;
      end;

      if Assigned(ivs.subtitle_st) then
      begin
        while ivs.subpq_size > 0 do
        begin
          sp := @ivs.subpq[ivs.subpq_rindex];

          if ivs.subpq_size > 1 then
            sp2 := @ivs.subpq[(ivs.subpq_rindex + 1) mod SUBPICTURE_QUEUE_SIZE]
          else
            sp2 := nil;

          if (sp.serial <> ivs.subtitleq.serial) or
             (ivs.vidclk.pts > sp.pts + sp.sub.end_display_time / 1000) or
             (Assigned(sp2) and (ivs.vidclk.pts > sp2.pts + sp2.sub.start_display_time / 1000)) then
          begin
            free_subpicture(sp);

            (* update queue size and signal for next picture *)
            Inc(ivs.subpq_rindex);
            if ivs.subpq_rindex = SUBPICTURE_QUEUE_SIZE then
              ivs.subpq_rindex := 0;

            SDL_LockMutex(ivs.subpq_mutex);
            Dec(ivs.subpq_size);
            SDL_CondSignal(ivs.subpq_cond);
            SDL_UnlockMutex(ivs.subpq_mutex);
          end
          else
            Break;
        end;
      end;

display:
      ivs.seek_paused := 0; // hack: stop refresh for seek paused
      ivs.open_paused := 0; // hack: stop refresh for open paused

      (* display picture *)
      if not Fdisplay_disable and (ivs.show_mode = SHOW_MODE_VIDEO) then
        video_display(ivs);

      pictq_next_picture(ivs);

      if (ivs.step <> 0) and (ivs.paused = 0) and
        (ivs.force_refresh = 0) then // hack
        stream_toggle_pause(ivs);
    end;
  end;

  DoPosition; // hack

  ivs.force_refresh := 0;

(*
  if (show_status) {
      static int64_t last_time;
      int64_t cur_time;
      int aqsize, vqsize, sqsize;
      double av_diff;

      cur_time = av_gettime();
      if (!last_time || (cur_time - last_time) >= 30000) {
          aqsize = 0;
          vqsize = 0;
          sqsize = 0;
          if (is->audio_st)
              aqsize = is->audioq.size;
          if (is->video_st)
              vqsize = is->videoq.size;
          if (is->subtitle_st)
              sqsize = is->subtitleq.size;
          av_diff = 0;
          if (is->audio_st && is->video_st)
              av_diff = get_clock(&is->audclk) - get_clock(&is->vidclk);
          else if (is->video_st)
              av_diff = get_master_clock(is) - get_clock(&is->vidclk);
          else if (is->audio_st)
              av_diff = get_master_clock(is) - get_clock(&is->audclk);
          av_log(NULL, AV_LOG_INFO,
                 "%7.2f %s:%7.3f fd=%4d aq=%5dKB vq=%5dKB sq=%5dB f=%"PRId64"/%"PRId64"   \r",
                 get_master_clock(is),
                 (is->audio_st && is->video_st) ? "A-V" : (is->video_st ? "M-V" : (is->audio_st ? "M-A" : "   ")),
                 av_diff,
                 is->frame_drops_early + is->frame_drops_late,
                 aqsize / 1024,
                 vqsize / 1024,
                 sqsize,
                 is->video_st ? is->video_st->codec->pts_correction_num_faulty_dts : 0,
                 is->video_st ? is->video_st->codec->pts_correction_num_faulty_pts : 0);
          fflush(stdout);
          last_time = cur_time;
      }
  }
*)
end;

(* allocate a picture (needs to do that in main thread to avoid potential locking problems *)
procedure TCustomPlayer.alloc_picture(ivs: PVideoState);
var
  vp: PVideoPicture;
  bufferdiff: Int64;
begin
  vp := @ivs.pictq[ivs.pictq_windex];

  free_picture(vp);

  video_open(ivs, False, vp);

  FFrameWidth := vp.width;    // hack: for property
  FFrameHeight := vp.height;  // hack: for property

  vp.bmp := SDL_CreateYUVOverlay(vp.width, vp.height, SDL_YV12_OVERLAY, Fscreen);

  //bufferdiff = FFMAX(vp->bmp->pixels[0], vp->bmp->pixels[1]) - FFMIN(vp->bmp->pixels[0], vp->bmp->pixels[1]);
  if Assigned(vp.bmp) then
  begin
    // hack: with directx driver, the pitches and the pixels were not initialized in SDL_CreateYUVOverlay(),
    //       they will be initialized in SDL_LockYUVOverlay()
    SDL_LockYUVOverlay(vp.bmp);
    SDL_UnlockYUVOverlay(vp.bmp);
    // hack end
    bufferdiff := Abs(Integer(vp.bmp.pixels^) - Integer(PPtrIdx(vp.bmp.pixels, 1)));
  end
  else
    bufferdiff := 0;
  if not Assigned(vp.bmp) or (vp.bmp.pitches^ < vp.width) or (bufferdiff < Int64(vp.height) * vp.bmp.pitches^) then
  begin
    (* SDL allocates a buffer smaller than requested if the video
     * overlay hardware is unable to support the requested size. *)
    if Assigned(vp.bmp) then
      FFLogger.Log(Self, llFatal,
                   'Error: the video system does not support an image ' +
                   'size of %dx%d pixels. Try using -lowres or -vf "scale=w:h" ' +
                   'to reduce the image size.',
                   [vp.width, vp.height])
    else
      FFLogger.Log(Self, llFatal, 'SDL_CreateYUVOverlay() error: %s', [string(SDL_GetError())]);
    vp.abort_allocate := 1;
    do_exit;
    SDL_Quit;
    Exit;
  end;

  SDL_LockMutex(ivs.pictq_mutex);
  vp.allocated := 1;
  SDL_CondSignal(ivs.pictq_cond);
  SDL_UnlockMutex(ivs.pictq_mutex);
end;

function FFMAX(f1, f2: Single): Single; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  if f1 > f2 then
    Result := f1
  else
    Result := f2;
end;

procedure duplicate_right_border_pixels(bmp: PSDL_Overlay);
var
  i, width, height: Integer;
  p, maxp: PByte;
begin
  for i := 0 to 2 do
  begin
    width  := bmp.w;
    height := bmp.h;
    if i > 0 then
    begin
      width  := width shr 1;
      height := height shr 1;
    end;
    if PPtrIdx(bmp.pitches, i) > width then
    begin
      maxp := PByte(Integer(PPtrIdx(bmp.pixels, i)) + PPtrIdx(bmp.pitches, i) * height - 1);
      p := PByte(Integer(PPtrIdx(bmp.pixels, i)) + width - 1);
      while Integer(p) < Integer(maxp) do
      begin
        PByte(Integer(p) + 1)^ := p^;
        Inc(p, PPtrIdx(bmp.pitches, i));
      end;
    end;
  end;
end;

function TCustomPlayer.queue_picture(ivs: PVideoState; src_frame: PAVFrame; pts: Double; pos: Int64; serial: Integer): Integer;
var
  vp: PVideoPicture;
  pict: TAVPicture;
  event: TSDL_Event;
  I: Integer;
  save_data: array[0..3] of PByte;
  save_linesize: array[0..3] of Integer;
begin
{$IFDEF DEBUG_SYNC}
//  printf("frame_type=%c pts=%0.3f\n",
//         av_get_picture_type_char(src_frame->pict_type), pts);
{$ENDIF}

  (* wait until we have space to put a new picture *)
  SDL_LockMutex(ivs.pictq_mutex);

  (* keep the last already displayed picture in the queue *)
  while (ivs.pictq_size >= VIDEO_PICTURE_QUEUE_SIZE - 1) and (ivs.videoq.abort_request = 0) do
    SDL_CondWait(ivs.pictq_cond, ivs.pictq_mutex);
  SDL_UnlockMutex(ivs.pictq_mutex);

  if ivs.videoq.abort_request <> 0 then
  begin
    Result := -1;
    Exit;
  end;

  vp := @ivs.pictq[ivs.pictq_windex];

  vp.sar := src_frame.sample_aspect_ratio;

  (* alloc or resize hardware picture buffer *)
  // force odd video frame size to even ones, to avoid SDL exception
  if not Assigned(vp.bmp) or {(vp.reallocate <> 0) or} (vp.allocated = 0) or
     (vp.width  <> ForceEven(src_frame.width)) or
     (vp.height <> ForceEven(src_frame.height)) then
  begin
    vp.allocated  := 0;
    //vp.reallocate := 0;
    // force odd video frame size to even ones, to avoid SDL exception
    vp.width := ForceEven(src_frame.width);
    vp.height := ForceEven(src_frame.height);

    (* the allocation must be done in the main thread to avoid
       locking problems. *)
    event.type_ := FF_ALLOC_EVENT;
    event.user.data1 := ivs;
    SDL_PushEvent(@event);

    (* wait until the picture is allocated *)
    SDL_LockMutex(ivs.pictq_mutex);
    while (vp.allocated = 0) and (ivs.videoq.abort_request = 0) do
      SDL_CondWait(ivs.pictq_cond, ivs.pictq_mutex);
    (* if the queue is aborted, we have to pop the pending ALLOC event or wait for the allocation to complete *)
    if (ivs.videoq.abort_request <> 0) and (SDL_PeepEvents(@event, 1, SDL_GETEVENT, 1 shl FF_ALLOC_EVENT) <> 1) then
    begin
      while (vp.allocated = 0) and (vp.abort_allocate = 0) do
        SDL_CondWait(ivs.pictq_cond, ivs.pictq_mutex);
    end;
    SDL_UnlockMutex(ivs.pictq_mutex);

    if ivs.videoq.abort_request <> 0 then
    begin
      Result := -1;
      Exit;
    end;
  end;

  (* if the frame is not skipped, then display it *)
  if Assigned(vp.bmp) then
  begin
    (* get a pointer on the bitmap *)
    SDL_LockYUVOverlay(vp.bmp);

    FillChar(pict, SizeOf(TAVPicture), 0);
    pict.data[0] := PByte(vp.bmp.pixels^);
    pict.data[1] := PPtrIdx(vp.bmp.pixels, 2);
    pict.data[2] := PPtrIdx(vp.bmp.pixels, 1);

    pict.linesize[0] := vp.bmp.pitches^;
    pict.linesize[1] := PPtrIdx(vp.bmp.pitches, 2);
    pict.linesize[2] := PPtrIdx(vp.bmp.pitches, 1);

    // hack: vertical flip
    if FVerticalFlip {and (src_frame.format = Ord(PIX_FMT_YUV420P))} then
    begin
      for I := 0 to 3 do
      begin
        save_data[I] := src_frame.data[0];
        save_linesize[I] := src_frame.linesize[0];
      end;
      Inc(src_frame.data[0], src_frame.linesize[0] * (vp.height - 1));
      src_frame.linesize[0] := src_frame.linesize[0] * -1;
      Inc(src_frame.data[1], src_frame.linesize[1] * (vp.height div 2 - 1));
      src_frame.linesize[1] := src_frame.linesize[1] * -1;
      Inc(src_frame.data[2], src_frame.linesize[2] * (vp.height div 2 - 1));
      src_frame.linesize[2] := src_frame.linesize[2] * -1;
    end;
    // hack end

{$IFDEF CONFIG_AVFILTER}
    //FIXME use direct rendering
    av_picture_copy(@pict, PAVPicture(src_frame), TAVPixelFormat(src_frame.format), vp.width, vp.height);
    DoVideoHook(PAVPicture(src_frame), @pict,
          TAVPixelFormat(src_frame.format), AV_PIX_FMT_YUV420P, vp.width, vp.height, pts);
{$ELSE}
    if not DoVideoHook(PAVPicture(src_frame), @pict,
          TAVPixelFormat(src_frame.format), AV_PIX_FMT_YUV420P, vp.width, vp.height, pts) then
    begin
      //av_opt_get_int(FOptions.sws_opts, 'sws_flags', 0, @Fsws_flags);
      ivs.img_convert_ctx := sws_getCachedContext(ivs.img_convert_ctx,
          vp.width, vp.height,
          src_frame.format,
          vp.width, vp.height,
          Ord(AV_PIX_FMT_YUV420P), Fsws_flags, nil, nil, nil);
      if not Assigned(ivs.img_convert_ctx) then
      begin
        SDL_UnlockYUVOverlay(vp.bmp);
        DoErrLog('Cannot initialize the conversion context.');
        Result := -1;
        Exit;
      end;
      sws_scale(ivs.img_convert_ctx, @src_frame.data[0], @src_frame.linesize[0],
                0, vp.height, @pict.data[0], @pict.linesize[0]);
    end;
{$ENDIF}
    DoFrameHook(@pict, AV_PIX_FMT_YUV420P, vp.width, vp.height, pts);
{$IFDEF NEED_YUV}
  {$IFDEF NEED_IDE}
    if (ivs.yuv01 <> 1) or (ivs.yuv23 <> 0) or (ivs.yuv45 <> 1) then
  {$ENDIF}
      WriteYUV(@pict, vp.height);
{$ENDIF}
    (* workaround SDL PITCH_WORKAROUND *)
    duplicate_right_border_pixels(vp.bmp);
    (* update the bitmap content *)
    SDL_UnlockYUVOverlay(vp.bmp);

    // hack: vertical flip
    if FVerticalFlip {and (src_frame.format = Ord(PIX_FMT_YUV420P))} then
    begin
      for I := 0 to 3 do
      begin
        src_frame.data[0] := save_data[I];
        src_frame.linesize[0] := save_linesize[I];
      end;
    end;
    // hack end

    vp.pts := pts;
    vp.pos := pos;
    vp.serial := serial;

    (* now we can update the picture count *)
    Inc(ivs.pictq_windex);
    if ivs.pictq_windex = VIDEO_PICTURE_QUEUE_SIZE then
      ivs.pictq_windex := 0;
    SDL_LockMutex(ivs.pictq_mutex);
    Inc(ivs.pictq_size);
    SDL_UnlockMutex(ivs.pictq_mutex);
    Inc(ivs.pictq_total_size); // hack for DoPosition
  end;
  Result := 0;
end;

function TCustomPlayer.get_video_frame(ivs: PVideoState; frame: PAVFrame; pkt: PAVPacket; serial: PInteger): Integer;
var
  got_picture: Integer;
  ret: Integer;
  dpts: Double;
  clockdiff, ptsdiff: Double;
begin
  if packet_queue_get(@ivs.videoq, pkt, 1, serial) < 0 then
  begin
    Result := -1;
    Exit;
  end;

  if pkt.data = Fflush_pkt.data then
  begin
    avcodec_flush_buffers(ivs.video_st.codec);

    SDL_LockMutex(ivs.pictq_mutex);
    // Make sure there are no long delay timers (ideally we should just flush the queue but thats harder)
    while (ivs.pictq_size <> 0) and (ivs.videoq.abort_request = 0) do
      SDL_CondWait(ivs.pictq_cond, ivs.pictq_mutex);
    ivs.video_current_pos := -1;
    ivs.frame_last_pts := AV_NOPTS_VALUE;
    ivs.frame_last_duration := 0;
    ivs.frame_timer := av_gettime() / 1000000.0;
    ivs.frame_last_dropped_pts := AV_NOPTS_VALUE;
    ivs.seek_flushed := 1; // hack
    SDL_UnlockMutex(ivs.pictq_mutex);

    Result := 0;
    Exit;
  end;

  if avcodec_decode_video2(ivs.video_st.codec, frame, @got_picture, pkt) < 0 then
  begin
    Result := 0;
    Exit;
  end;

  if (got_picture = 0) and not Assigned(pkt.data) then
    ivs.video_finished := serial^;

  if got_picture <> 0 then
  begin
    ret := 1;
    dpts := NaN;

    if Fdecoder_reorder_pts = -1 then
      frame.pts := av_frame_get_best_effort_timestamp(frame)
    else if Fdecoder_reorder_pts <> 0 then
      frame.pts := frame.pkt_pts
    else
      frame.pts := frame.pkt_dts;

    if frame.pts <> AV_NOPTS_VALUE then
      dpts := av_q2d(ivs.video_st.time_base) * frame.pts;

    frame.sample_aspect_ratio := av_guess_sample_aspect_ratio(ivs.ic, ivs.video_st, frame);

    if (Fframedrop > 0) or ((Fframedrop <> 0) and (get_master_sync_type(ivs) <> AV_SYNC_VIDEO_MASTER)) and
      (ivs.step = 0) then // hack: don't drop while step
    begin
      SDL_LockMutex(ivs.pictq_mutex);
      if (ivs.frame_last_pts <> AV_NOPTS_VALUE) and (frame.pts <> AV_NOPTS_VALUE) then
      begin
        clockdiff := get_clock(@ivs.vidclk) - get_master_clock(ivs);
        ptsdiff := dpts - ivs.frame_last_pts;
        if not IsNaN(clockdiff) and (Abs(clockdiff) < AV_NOSYNC_THRESHOLD) and
          not IsNaN(ptsdiff) and (ptsdiff > 0) and (ptsdiff < AV_NOSYNC_THRESHOLD) and
          (clockdiff + ptsdiff - ivs.frame_last_filter_delay < 0) and
          (ivs.videoq.nb_packets <> 0) then
        begin
          ivs.frame_last_dropped_pos := av_frame_get_pkt_pos(frame);
          ivs.frame_last_dropped_pts := dpts;
          ivs.frame_last_dropped_serial := serial^;
          Inc(ivs.frame_drops_early);
          av_frame_unref(frame);
          ret := 0;
        end;
      end;
      SDL_UnlockMutex(ivs.pictq_mutex);
    end;
  end
  else
    ret := 0;
  // hack: position
  if not Assigned(pkt.data) and (pkt.size = 0) and (ivs.EndEventDone = 0) then
    DoPosition;
  // hack end
  Result := ret;
end;

{$IFDEF CONFIG_AVFILTER}
function configure_filtergraph(graph: PAVFilterGraph; const filtergraph: PAnsiChar;
  source_ctx, sink_ctx: PAVFilterContext): Integer;
var
  ret: Integer;
  outputs, inputs: PAVFilterInOut;
label
  fail;
begin
  outputs := nil;
  inputs := nil;

  if Assigned(filtergraph) then
  begin
    outputs := avfilter_inout_alloc();
    inputs  := avfilter_inout_alloc();
    if not Assigned(outputs) or not Assigned(inputs) then
    begin
      ret := AVERROR_ENOMEM;
      goto fail;
    end;

    outputs.name       := av_strdup('in');
    outputs.filter_ctx := source_ctx;
    outputs.pad_idx    := 0;
    outputs.next       := nil;

    inputs.name        := av_strdup('out');
    inputs.filter_ctx  := sink_ctx;
    inputs.pad_idx     := 0;
    inputs.next        := nil;

    ret := avfilter_graph_parse_ptr(graph, filtergraph, @inputs, @outputs, nil);
    if ret < 0 then
      goto fail;
  end
  else
  begin
    ret := avfilter_link(source_ctx, 0, sink_ctx, 0);
    if ret < 0 then
      goto fail;
  end;

  ret := avfilter_graph_config(graph, nil);
fail:
  avfilter_inout_free(@outputs);
  avfilter_inout_free(@inputs);
  Result := ret;
end;

function TCustomPlayer.configure_video_filters(graph: PAVFilterGraph; ivs: PVideoState;
  vfilters: string; frame: PAVFrame): Integer;
const
  pix_fmts: array[0..1] of TAVPixelFormat = (AV_PIX_FMT_YUV420P, AV_PIX_FMT_NONE);
var
  sws_flags_str: array[0..127] of AnsiChar;
  buffersrc_args: array[0..255] of AnsiChar;
  ret: Integer;
  filt_src, filt_out, filt_crop: PAVFilterContext;
  codec: PAVCodecContext;
  fr: TAVRational;
label
  fail;
begin
  filt_src := nil;
  filt_out := nil;
  codec := ivs.video_st.codec;
  fr := av_guess_frame_rate(ivs.ic, ivs.video_st, nil);

  //av_opt_get_int(FOptions.sws_opts, 'sws_flags', 0, @Fsws_flags);
  // #define PRId64 "lld"
  my_snprintf(sws_flags_str, SizeOf(sws_flags_str),
{$IFDEF MSWINDOWS}
              // '%lld/%llx' works on Vista or above, '%I64d/%I64x' works always
              'flags=%I64d',
{$ELSE}
              'flags=%lld',
{$ENDIF}
{$IF Defined(VCL_60) Or Defined(VCL_70)}
              // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
              // Int64 and Single are incorrectly passed to cdecl/varargs functions
              Int64Rec(Fsws_flags).Lo, Int64Rec(Fsws_flags).Hi);
{$ELSE}
              Fsws_flags);
{$IFEND}
  graph.scale_sws_opts := av_strdup(sws_flags_str);

  my_snprintf(buffersrc_args, SizeOf(buffersrc_args),
              'video_size=%dx%d:pix_fmt=%d:time_base=%d/%d:pixel_aspect=%d/%d',
              frame.width, frame.height, frame.format,
              ivs.video_st.time_base.num, ivs.video_st.time_base.den,
              codec.sample_aspect_ratio.num, Max(codec.sample_aspect_ratio.den, 1));
  if (fr.num <> 0) and (fr.den <> 0) then
    av_strlcatf(buffersrc_args, SizeOf(buffersrc_args), ':frame_rate=%d/%d', fr.num, fr.den);

  ret := avfilter_graph_create_filter(@filt_src,
                                      avfilter_get_by_name('buffer'),
                                      'ffplay_buffer', buffersrc_args, nil,
                                      graph);
  if ret < 0 then
    goto fail;

  ret := avfilter_graph_create_filter(@filt_out,
                                      avfilter_get_by_name('buffersink'),
                                      'ffplay_buffersink', nil, nil, graph);
  if ret < 0 then
    goto fail;

  ret := av_opt_set_int_list(filt_out, 'pix_fmts', @pix_fmts[0], SizeOf(TAVPixelFormat), Int64(AV_PIX_FMT_NONE), AV_OPT_SEARCH_CHILDREN);
  if ret < 0 then
    goto fail;

  (* SDL YUV code is not handling odd width/height for some driver
   * combinations, therefore we crop the picture to an even width/height. *)
  // TODO: do we need ForceEven() any more?
  ret := avfilter_graph_create_filter(@filt_crop,
                                      avfilter_get_by_name('crop'),
                                      'ffplay_crop', 'floor(in_w/2)*2:floor(in_h/2)*2', nil, graph);
  if ret < 0 then
    goto fail;
  ret := avfilter_link(filt_crop, 0, filt_out, 0);
  if ret < 0 then
    goto fail;

  if vfilters <> '' then
  begin
    FFLogger.Log(Self, llInfo, 'Parse filters: %s', [vfilters]);
    ret := configure_filtergraph(graph, PAnsiChar(AnsiString(vfilters)), filt_src, filt_crop);
  end
  else
    ret := configure_filtergraph(graph, nil, filt_src, filt_crop);
  if ret < 0 then
    goto fail;

  ivs.in_video_filter  := filt_src;
  ivs.out_video_filter := filt_out;

fail:
  Result := ret;
end;

function TCustomPlayer.configure_audio_filters(ivs: PVideoState; afilters: string;
  force_output_format: Integer): Integer;
const
  sample_fmts: array[0..1] of TAVSampleFormat = (AV_SAMPLE_FMT_S16, AV_SAMPLE_FMT_NONE);
var
  sample_rates: array[0..1] of Integer;
  channel_layouts: array[0..1] of Int64;
  channels: array[0..1] of Integer;
  filt_asrc, filt_asink: PAVFilterContext;
  aresample_swr_opts: array[0..511] of AnsiChar;
  e: PAVDictionaryEntry;
  asrc_args: array[0..255] of AnsiChar;
  ret: Integer;
{$IF Defined(VCL_60) Or Defined(VCL_70)}
  I64: Int64;
  Lo, Hi: Integer;
{$IFEND}
label
  fail;
begin
  sample_rates[0] := 0;
  sample_rates[1] := -1;
  channel_layouts[0] := 0;
  channel_layouts[1] := -1;
  channels[0] := 0;
  channels[1] := -1;
  filt_asrc := nil;
  filt_asink := nil;
  FillChar(aresample_swr_opts[0], SizeOf(aresample_swr_opts), 0);

  avfilter_graph_free(@ivs.agraph);
  ivs.agraph := avfilter_graph_alloc();
  if not Assigned(ivs.agraph) then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;

  e := av_dict_get(FOptions.swr_opts, '', nil, AV_DICT_IGNORE_SUFFIX);
  while Assigned(e) do
  begin
    av_strlcatf(aresample_swr_opts, SizeOf(aresample_swr_opts), '%s=%s:', e.key, e.value);
    e := av_dict_get(FOptions.swr_opts, '', e, AV_DICT_IGNORE_SUFFIX);
  end;
  if MyStrLen(aresample_swr_opts) <> 0 then
    aresample_swr_opts[MyStrLen(aresample_swr_opts) - 1] := #0;
  av_opt_set(ivs.agraph, 'aresample_swr_opts', aresample_swr_opts, 0);

  ret := my_snprintf(asrc_args, SizeOf(asrc_args),
                 'sample_rate=%d:sample_fmt=%s:channels=%d:time_base=%d/%d',
                 ivs.audio_filter_src.freq, av_get_sample_fmt_name(ivs.audio_filter_src.fmt),
                 ivs.audio_filter_src.channels,
                 1, ivs.audio_filter_src.freq);
  if ivs.audio_filter_src.channel_layout <> 0 then
  begin
{$IF Defined(VCL_60) Or Defined(VCL_70)}
    // Int64Rec on non-local variables will cause Internal error(URW699) in Delphi 6
    I64 := ivs.audio_filter_src.channel_layout;
    Lo := Int64Rec(I64).Lo;
    Hi := Int64Rec(I64).Hi;
{$IFEND}
    // #define PRIx64 "llx"
    my_snprintf(asrc_args + ret, SizeOf(asrc_args) - ret,
{$IFDEF MSWINDOWS}
                // '%lld/%llx' works on Vista or above, '%I64d/%I64x' works always
                ':channel_layout=0x%I64x',
{$ELSE}
                ':channel_layout=0x%llx',
{$ENDIF}
{$IF Defined(VCL_60) Or Defined(VCL_70)}
                // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
                // Int64 and Single are incorrectly passed to cdecl/varargs functions
                Lo, Hi);
{$ELSE}
                ivs.audio_filter_src.channel_layout);
{$IFEND}
  end;

  ret := avfilter_graph_create_filter(@filt_asrc,
                                     avfilter_get_by_name('abuffer'), 'ffplay_abuffer',
                                     asrc_args, nil, ivs.agraph);
  if ret < 0 then
    goto fail;


  ret := avfilter_graph_create_filter(@filt_asink,
                                     avfilter_get_by_name('abuffersink'), 'ffplay_abuffersink',
                                     nil, nil, ivs.agraph);
  if ret < 0 then
    goto fail;

  ret := av_opt_set_int_list(filt_asink, 'sample_fmts', @sample_fmts[0], SizeOf(TAVSampleFormat), Int64(AV_SAMPLE_FMT_NONE), AV_OPT_SEARCH_CHILDREN);
  if ret < 0 then
    goto fail;
  ret := av_opt_set_int(filt_asink, 'all_channel_counts', 1, AV_OPT_SEARCH_CHILDREN);
  if ret < 0 then
    goto fail;

  if force_output_format <> 0 then
  begin
    channel_layouts[0] := ivs.audio_tgt.channel_layout;
    channels       [0] := ivs.audio_tgt.channels;
    sample_rates   [0] := ivs.audio_tgt.freq;
    ret := av_opt_set_int(filt_asink, 'all_channel_counts', 0, AV_OPT_SEARCH_CHILDREN);
    if ret < 0 then
      goto fail;
    ret := av_opt_set_int_list(filt_asink, 'channel_layouts', @channel_layouts[0], SizeOf(Int64),   -1, AV_OPT_SEARCH_CHILDREN);
    if ret < 0 then
      goto fail;
    ret := av_opt_set_int_list(filt_asink, 'channel_counts' , @channels[0]       , SizeOf(Integer), -1, AV_OPT_SEARCH_CHILDREN);
    if ret < 0 then
      goto fail;
    ret := av_opt_set_int_list(filt_asink, 'sample_rates'   , @sample_rates[0]   , SizeOf(Integer), -1, AV_OPT_SEARCH_CHILDREN);
    if ret < 0 then
      goto fail;
  end;

  if afilters <> '' then
  begin
    FFLogger.Log(Self, llInfo, 'Parse afilters: %s', [afilters]);
    ret := configure_filtergraph(ivs.agraph, PAnsiChar(AnsiString(afilters)), filt_asrc, filt_asink);
  end
  else
    ret := configure_filtergraph(ivs.agraph, nil, filt_asrc, filt_asink);
  if ret < 0 then
    goto fail;

  ivs.in_audio_filter  := filt_asrc;
  ivs.out_audio_filter := filt_asink;

fail:
  if ret < 0 then
    avfilter_graph_free(@ivs.agraph);
  Result := ret;
end;
{$ENDIF}

function video_thread(arg: Pointer): Integer; cdecl;
begin
  PVideoState(arg).Owner.do_video_thread(arg);
  Result := 0;
end;

procedure TCustomPlayer.do_video_thread(arg: Pointer);
// hack: deinterlacing support
var
  deint_frame: TAVFrame;
  deint_size: Integer;
  deint_buf: PByte;
  deint_pix_fmt: TAVPixelFormat;
  deint_width: Integer;
  deint_height: Integer;

  function do_deinterlace(frame: PAVFrame): PAVFrame;
  var
    final_frame: PAVFrame;
    size: Integer;
    procedure ASM1;
    asm
      emms; // maybe a bug missing call emms in function avpicture_deinterlace()
    end;
  begin
    if not FDeinterlace then
      Result := frame
    else
    begin
      // malloc buffer
      size := avpicture_get_size(deint_pix_fmt, deint_width, deint_height);
      if not Assigned(deint_buf) then
      begin
        deint_buf := av_malloc(size);
        deint_size := size;
      end
      else if deint_size < size then
      begin
        av_free(deint_buf);
        deint_buf := av_malloc(size);
        deint_size := size;
      end;

      if not Assigned(deint_buf) then
      begin
        FFLogger.Log(Self, llError, 'deinterlace buffer malloc error.');
        FDeinterlace := False;
        final_frame := frame;
      end
      else
      begin
        // deinterlacing
        final_frame := @deint_frame;
        Move(frame^, final_frame^, SizeOf(TAVFrame));
        avpicture_fill(PAVPicture(final_frame), deint_buf, deint_pix_fmt, deint_width, deint_height);
        if avpicture_deinterlace(PAVPicture(final_frame), PAVPicture(frame), deint_pix_fmt, deint_width, deint_height) < 0 then
        begin
          ASM1;
          (* if error, do not deinterlace *)
          FFLogger.Log(Self, llError, 'deinterlacing failed.');
          FDeinterlace := False;
          final_frame := frame;
        end
        else
          ASM1;
      end;
      Result := final_frame;
    end;
  end;
// hack end

var
  pkt: TAVPacket;
  ivs: PVideoState;
  frame: PAVFrame;
  pts: Double;
  ret: Integer;
  serial: Integer;
{$IFDEF CONFIG_AVFILTER}
  graph: PAVFilterGraph;
  filt_out, filt_in: PAVFilterContext;
  last_w: Integer;
  last_h: Integer;
  last_format: Integer;
  last_serial: Integer;
  last_vfilters: string;
{$ENDIF}
label
  the_end;
begin
  FillChar(pkt, SizeOf(TAVPacket), 0);
  ivs := arg;
  frame := av_frame_alloc();
  avcodec_get_frame_defaults(frame);
  serial := 0;

  // hack: deinterlacing support
  deint_size := 0;
  deint_buf := nil;
  // hack end

{$IFDEF CONFIG_AVFILTER}
  graph := avfilter_graph_alloc;
  filt_out := nil;
  filt_in := nil;
  last_w := 0;
  last_h := 0;
  last_format := -2;
  last_serial := -1;
  last_vfilters := '';
{$ELSE}
  // hack: deinterlacing support
  deint_width   := ForceEven(ivs.video_st.codec.width);
  deint_height  := ForceEven(ivs.video_st.codec.height);
  deint_pix_fmt := ivs.video_st.codec.pix_fmt;
  // hack end
{$ENDIF}

  while True do
  begin
    while (ivs.paused <> 0) and (ivs.videoq.abort_request = 0) and
      (ivs.seek_paused = 0) and (ivs.open_paused = 0) do // hack
      Sleep(10);

    avcodec_get_frame_defaults(frame);
    av_free_packet(@pkt);

    ret := get_video_frame(ivs, frame, @pkt, @serial);
    if ret < 0 then
    begin
      FFLogger.Log(Self, llError, 'Error: get_video_frame() return %d', [ret]);
      goto the_end;
    end;
    if ret = 0 then
      Continue;

{$IFDEF CONFIG_AVFILTER}
    if (last_w <> frame.width) or
       (last_h <> frame.height) or
       (last_format <> frame.format) or
       (last_serial <> serial) or
       (last_vfilters <> Fvfilters) then
    begin
      if (last_format <> -2) or (last_serial <> -1) then // hack
        FFLogger.Log(Self, llInfo,
                     'Video frame changed from size:%dx%d format:%s serial:%d to size:%dx%d format:%s serial:%d',
                    [last_w, last_h,
                     av_x_if_null(av_get_pix_fmt_name(TAVPixelFormat(last_format)), 'none'), last_serial,
                     frame.width, frame.height,
                     av_x_if_null(av_get_pix_fmt_name(TAVPixelFormat(frame.format)), 'none'), serial]);
      avfilter_graph_free(@graph);
      graph := avfilter_graph_alloc;
      ret := configure_video_filters(graph, ivs, Fvfilters, frame);
      if ret < 0 then
      begin
        PushQuitEvent(ivs);
        av_free_packet(@pkt);
        FFLogger.Log(Self, llError, print_error('configure_video_filters() failed', ret));
        goto the_end;
      end;
      ivs.FilterGraph := graph; // hack for sending video filter commands
      filt_in  := ivs.in_video_filter;
      filt_out := ivs.out_video_filter;
      last_w := frame.width;
      last_h := frame.height;
      last_format := frame.format;
      last_serial := serial;
      last_vfilters := Fvfilters;
      // hack: deinterlacing support
      deint_width   := ForceEven(ivs.out_video_filter.inputs^.w);
      deint_height  := ForceEven(ivs.out_video_filter.inputs^.h);
      deint_pix_fmt := TAVPixelFormat(ivs.out_video_filter.inputs^.format);
      // hack end
    end;

    ret := av_buffersrc_add_frame(filt_in, frame);
    if ret < 0 then
      goto the_end;
    av_frame_unref(frame);
    avcodec_get_frame_defaults(frame);
    av_free_packet(@pkt);

    while ret >= 0 do
    begin
      ivs.frame_last_returned_time := av_gettime() / 1000000.0;

      ret := av_buffersink_get_frame_flags(filt_out, frame, 0);
      if ret < 0 then
      begin
        if ret = AVERROR_EOF then
          ivs.video_finished := serial;
        ret := 0;
        Break;
      end;

      ivs.frame_last_filter_delay := av_gettime() / 1000000.0 - ivs.frame_last_returned_time;
      if Abs(ivs.frame_last_filter_delay) > AV_NOSYNC_THRESHOLD / 10.0 then
        ivs.frame_last_filter_delay := 0;

      if frame.pts = AV_NOPTS_VALUE then
        pts := NaN
      else
        pts := frame.pts * av_q2d(filt_out.inputs^.time_base);
      ret := queue_picture(ivs, do_deinterlace(frame), pts, av_frame_get_pkt_pos(frame), serial); // hack: deinterlacing support
      av_frame_unref(frame);
    end;
{$ELSE}
    if frame.pts = AV_NOPTS_VALUE then
      pts := NaN
    else
      pts := frame.pts * av_q2d(ivs.video_st.time_base);
    ret := queue_picture(ivs, do_deinterlace(frame), pts, av_frame_get_pkt_pos(frame), serial); // hack: deinterlacing support
    av_frame_unref(frame);
{$ENDIF}

    if ret < 0 then
      goto the_end;

    // hack: for seeking paused
    if (ivs.seek_done <> 0) and (ivs.seek_flushed <> 0) then
    begin
      ivs.seek_done := 0;
      ivs.seek_paused := 2;
    end;
    // hack end

    // hack: reset status
    FPictEvent.SetEvent;
    ivs.EndEventDone := 0;
    if FSeeking and (ivs.seek_req = 0) then
      FSeeking := False;
    // hack end

    // hack: for open paused
    if ivs.open_paused <> 0 then
    begin
      if ivs.open_paused = 1 then
        DoState(psPause);
      Inc(ivs.open_paused);
    end;
    // hack end
  end;

the_end:
  avcodec_flush_buffers(ivs.video_st.codec);
{$IFDEF CONFIG_AVFILTER}
  avfilter_graph_free(@graph);
{$ENDIF}
  av_free_packet(@pkt);
  av_frame_free(@frame);
  // hack: deinterlacing support
  if Assigned(deint_buf) then
    av_free(deint_buf);
  // hack end
end;

function subtitle_thread(arg: Pointer): Integer; cdecl;
begin
  PVideoState(arg).Owner.do_subtitle_thread(arg);
  Result := 0;
end;

procedure TCustomPlayer.do_subtitle_thread(arg: Pointer);
var
  ivs: PVideoState;
  sp: PSubPicture;
  pkt1: TAVPacket;
  pkt: PAVPacket;
  got_subtitle: Integer;
  serial: Integer;
  pts: Double;
  i, j: Integer;
  r, g, b, a: Byte;
  y, u, v: Integer;
  p: PAVSubtitleRect;
begin
  ivs := arg;
  pkt := @pkt1;

  while True do
  begin
    while (ivs.paused <> 0) and (ivs.subtitleq.abort_request = 0) and
      (ivs.seek_paused = 0) and (ivs.open_paused = 0) do // hack
      Sleep(10);
    if packet_queue_get(@ivs.subtitleq, pkt, 1, @serial) < 0 then
      Break;

    if pkt.data = Fflush_pkt.data then
    begin
      avcodec_flush_buffers(ivs.subtitle_st.codec);
      Continue;
    end;
    SDL_LockMutex(ivs.subpq_mutex);
    while (ivs.subpq_size >= SUBPICTURE_QUEUE_SIZE) and
      (ivs.subtitleq.abort_request = 0) do
      SDL_CondWait(ivs.subpq_cond, ivs.subpq_mutex);
    SDL_UnlockMutex(ivs.subpq_mutex);

    if ivs.subtitleq.abort_request <> 0 then
      Exit;

    sp := @ivs.subpq[ivs.subpq_windex];

    (* NOTE: ipts is the PTS of the _first_ picture beginning in this packet, if any *)
    pts := 0;
    if pkt.pts <> AV_NOPTS_VALUE then
      pts := av_q2d(ivs.subtitle_st.time_base) * pkt.pts;

    avcodec_decode_subtitle2(ivs.subtitle_st.codec, @sp.sub, @got_subtitle, pkt);
    if (got_subtitle <> 0) and (sp.sub.format = 0) then
    begin
      if sp.sub.pts <> AV_NOPTS_VALUE then
        pts := sp.sub.pts / AV_TIME_BASE;
      sp.pts := pts;
      sp.serial := serial;

      for i := 0 to sp.sub.num_rects - 1 do
      begin
        p := PPtrIdx(sp.sub.rects, i);
        for j := 0 to p.nb_colors - 1 do
        begin
          //RGBA_IN(r, g, b, a, (uint32_t*)sp.sub.rects[i].pict.data[1] + j);
          RGBA_IN(r, g, b, a, PCardinal(PAnsiChar(p.pict.data[1]) + j * SizeOf(Cardinal)));
          y := RGB_TO_Y_CCIR(r, g, b);
          u := RGB_TO_U_CCIR(r, g, b, 0);
          v := RGB_TO_V_CCIR(r, g, b, 0);
          //YUVA_OUT((uint32_t*)sp.sub.rects[i].pict.data[1] + j, y, u, v, a);
          YUVA_OUT(PCardinal(PAnsiChar(p.pict.data[1]) + j * SizeOf(Cardinal)), y, u, v, a);
        end;
      end;

      (* now we can update the picture count *)
      Inc(ivs.subpq_windex);
      if ivs.subpq_windex = SUBPICTURE_QUEUE_SIZE then
        ivs.subpq_windex := 0;
      SDL_LockMutex(ivs.subpq_mutex);
      Inc(ivs.subpq_size);
      SDL_UnlockMutex(ivs.subpq_mutex);
    end
    else if got_subtitle <> 0 then
      avsubtitle_free(@sp.sub); // TODO: text subtitles
    av_free_packet(pkt);
  end;
end;

(* copy samples for viewing in editor window *)
procedure update_sample_display(ivs: PVideoState; samples: PSmallInt; samples_size: Integer);
var
  size, len: Integer;
begin
  size := samples_size div SizeOf(SmallInt);
  while size > 0 do
  begin
    len := SAMPLE_ARRAY_SIZE - ivs.sample_array_index;
    if len > size then
      len := size;
    Move(samples^, ivs.sample_array[ivs.sample_array_index], len * SizeOf(SmallInt));
    Inc(samples, len);
    Inc(ivs.sample_array_index, len);
    if ivs.sample_array_index >= SAMPLE_ARRAY_SIZE then
      ivs.sample_array_index := 0;
    Dec(size, len);
  end;
end;

(* return the wanted number of samples to get better sync if sync_type is video
 * or external master clock *)
function synchronize_audio(ivs: PVideoState; nb_samples: Integer): Integer;
var
  wanted_nb_samples: Integer;
  diff, avg_diff: Double;
  min_nb_samples, max_nb_samples: Integer;
begin
  wanted_nb_samples := nb_samples;

  (* if not master, then we try to remove or add samples to correct the clock *)
  if get_master_sync_type(ivs) <> AV_SYNC_AUDIO_MASTER then
  begin
    diff := get_clock(@ivs.audclk) - get_master_clock(ivs);

    if (get_master_sync_type(ivs) = AV_SYNC_EXTERNAL_CLOCK) and (ivs.extclk.speed <> 1.0) then
      wanted_nb_samples := Round(wanted_nb_samples / ivs.extclk.speed)
    else if not IsNaN(diff) and (Abs(diff) < AV_NOSYNC_THRESHOLD) then
    begin
      ivs.audio_diff_cum := diff + ivs.audio_diff_avg_coef * ivs.audio_diff_cum;
      if ivs.audio_diff_avg_count < AUDIO_DIFF_AVG_NB then
        (* not enough measures to have a correct estimate *)
        Inc(ivs.audio_diff_avg_count)
      else
      begin
        (* estimate the A-V difference *)
        avg_diff := ivs.audio_diff_cum * (1.0 - ivs.audio_diff_avg_coef);

        if Abs(avg_diff) >= ivs.audio_diff_threshold then
        begin
          wanted_nb_samples := nb_samples + Trunc(diff * ivs.audio_src.freq);
          min_nb_samples := ((nb_samples * (100 - SAMPLE_CORRECTION_PERCENT_MAX) div 100));
          max_nb_samples := ((nb_samples * (100 + SAMPLE_CORRECTION_PERCENT_MAX) div 100));
          //wanted_nb_samples = FFMIN(FFMAX(wanted_nb_samples, min_nb_samples), max_nb_samples);
          if wanted_nb_samples < min_nb_samples then
            wanted_nb_samples := min_nb_samples;
          if wanted_nb_samples > max_nb_samples then
            wanted_nb_samples := max_nb_samples;
        end;
{
        av_dlog(NULL, "diff=%f adiff=%f sample_diff=%d apts=%0.3f %f\n",
                diff, avg_diff, wanted_nb_samples - nb_samples,
                is->audio_clock, is->audio_diff_threshold);
}
      end;
    end
    else
    begin
      (* too big difference : may be initial PTS errors, so
         reset A-V filter *)
      ivs.audio_diff_avg_count := 0;
      ivs.audio_diff_cum := 0;
    end;
  end;
  Result := wanted_nb_samples;
end;

(**
 * Decode one audio frame and return its uncompressed size.
 *
 * The processed audio frame is decoded, converted if required, and
 * stored in is->audio_buf, with size in bytes given by the return
 * value.
 *)
function TCustomPlayer.audio_decode_frame(ivs: PVideoState; pts_ptr: PDouble): Integer;
const
  bytes_per_sample = 2; // AV_SAMPLE_FMT_S16
{$IFDEF DEBUG_SYNC}
{$J+}
  last_clock: Double = 0;
{$J-}
{$ENDIF}
var
  pkt_temp: PAVPacket;
  pkt: PAVPacket;
  avdec: PAVCodecContext;
  len1, data_size, resampled_data_size: Integer;
  dec_channel_layout: Int64;
  got_frame: Integer;
  wanted_nb_samples: Integer;
  tb, tb_src: TAVRational;
  ret: Integer;
  reconfigure: Boolean;
  buf1, buf2: array[0..1023] of AnsiChar;
  in_buf: PPByte;
  out_buf: PPByte;
  out_count: Integer;
  out_size: Integer;
  len2: Integer;
  dec_channels: Integer;
begin
  // hack: ensure pause immediately for APE which has large ivs.audio_pkt_temp.size
  if (ivs.paused <> 0) or (ivs.audioq.abort_request <> 0) then
  begin
    Result := -1;
    Exit;
  end;
  // hack end

  pkt_temp := @ivs.audio_pkt_temp;
  pkt := @ivs.audio_pkt;
  avdec := ivs.audio_st.codec;

  while True do
  begin
    (* NOTE: the audio packet can contain several frames *)
    while (pkt_temp.stream_index <> -1) or (ivs.audio_buf_frames_pending <> 0) do
    begin
      if not Assigned(ivs.frame) then
      begin
        ivs.frame := avcodec_alloc_frame();
        if not Assigned(ivs.frame) then
        begin
          Result := AVERROR_ENOMEM;
          Exit;
        end;
      end
      else
      begin
        av_frame_unref(ivs.frame);
        avcodec_get_frame_defaults(ivs.frame);
      end;

      if ivs.audioq.serial <> ivs.audio_pkt_temp_serial then
        Break;

      if ivs.paused <> 0 then
      begin
        Result := -1;
        Exit;
      end;

      if ivs.audio_buf_frames_pending = 0 then
      begin
        len1 := avcodec_decode_audio4(avdec, ivs.frame, @got_frame, pkt_temp);
        if len1 < 0 then
        begin
          (* if error, we skip the frame *)
          FFLogger.Log(Self, llInfo, 'avcodec_decode_audio4() failed');
          pkt_temp.size := 0;
          Break;
        end;

        pkt_temp.dts := AV_NOPTS_VALUE;
        pkt_temp.pts := AV_NOPTS_VALUE;
        Inc(pkt_temp.data, len1);
        Dec(pkt_temp.size, len1);
        if (Assigned(pkt_temp.data) and (pkt_temp.size <= 0)) or (not Assigned(pkt_temp.data) and (got_frame = 0)) then
          pkt_temp.stream_index := -1;
        if not Assigned(pkt_temp.data) and (got_frame = 0) then
          ivs.audio_finished := ivs.audio_pkt_temp_serial;

        if got_frame = 0 then
          Continue;

        tb.num := 1;
        tb.den := ivs.frame.sample_rate;
        if ivs.frame.pts <> AV_NOPTS_VALUE then
          ivs.frame.pts := av_rescale_q(ivs.frame.pts, avdec.time_base, tb)
        else if ivs.frame.pkt_pts <> AV_NOPTS_VALUE then
          ivs.frame.pts := av_rescale_q(ivs.frame.pkt_pts, ivs.audio_st.time_base, tb)
        else if ivs.audio_frame_next_pts <> AV_NOPTS_VALUE then
        begin
          tb_src.num := 1;
{$IFDEF CONFIG_AVFILTER}
          tb_src.den := ivs.audio_filter_src.freq;
{$ELSE}
          tb_src.den := ivs.audio_src.freq;
{$ENDIF}
          ivs.frame.pts := av_rescale_q(ivs.audio_frame_next_pts, tb_src, tb);
        end;

        if ivs.frame.pts <> AV_NOPTS_VALUE then
          ivs.audio_frame_next_pts := ivs.frame.pts + ivs.frame.nb_samples;

{$IFDEF CONFIG_AVFILTER}
        dec_channel_layout := get_valid_channel_layout(ivs.frame.channel_layout, av_frame_get_channels(ivs.frame));

        reconfigure :=
            (cmp_audio_fmts(ivs.audio_filter_src.fmt, ivs.audio_filter_src.channels,
                           TAVSampleFormat(ivs.frame.format), av_frame_get_channels(ivs.frame)) <> 0) or
            (ivs.audio_filter_src.channel_layout <> dec_channel_layout) or
            (ivs.audio_filter_src.freq           <> ivs.frame.sample_rate) or
            (ivs.audio_pkt_temp_serial           <> ivs.audio_last_serial);

        if reconfigure then
        begin
          av_get_channel_layout_string(buf1, SizeOf(buf1), -1, ivs.audio_filter_src.channel_layout);
          av_get_channel_layout_string(buf2, SizeOf(buf2), -1, dec_channel_layout);
          FFLogger.Log(Self, llDebug,
                 'Audio frame changed from rate:%d ch:%d fmt:%s layout:%s serial:%d to rate:%d ch:%d fmt:%s layout:%s serial:%d',
                [ivs.audio_filter_src.freq, ivs.audio_filter_src.channels, av_get_sample_fmt_name(ivs.audio_filter_src.fmt), buf1, ivs.audio_last_serial,
                 ivs.frame.sample_rate, av_frame_get_channels(ivs.frame), av_get_sample_fmt_name(TAVSampleFormat(ivs.frame.format)), buf2, ivs.audio_pkt_temp_serial]);

          ivs.audio_filter_src.fmt            := TAVSampleFormat(ivs.frame.format);
          ivs.audio_filter_src.channels       := av_frame_get_channels(ivs.frame);
          ivs.audio_filter_src.channel_layout := dec_channel_layout;
          ivs.audio_filter_src.freq           := ivs.frame.sample_rate;
          ivs.audio_last_serial               := ivs.audio_pkt_temp_serial;

          ret := configure_audio_filters(ivs, Fafilters, 1);
          if ret < 0 then
          begin
            Result := ret;
            Exit;
          end;
        end;

        ret := av_buffersrc_add_frame(ivs.in_audio_filter, ivs.frame);
        if ret < 0 then
        begin
          Result := ret;
          Exit;
        end;
        av_frame_unref(ivs.frame);
{$ENDIF}
      end;
{$IFDEF CONFIG_AVFILTER}
      ret := av_buffersink_get_frame_flags(ivs.out_audio_filter, ivs.frame, 0);
      if ret < 0 then
      begin
        if ret = AVERROR_EAGAIN then
        begin
          ivs.audio_buf_frames_pending := 0;
          Continue;
        end;
        if ret = AVERROR_EOF then
          ivs.audio_finished := ivs.audio_pkt_temp_serial;
        Result := ret;
        Exit;
      end;
      ivs.audio_buf_frames_pending := 1;
      tb := ivs.out_audio_filter.inputs^.time_base;
{$ENDIF}

      data_size := av_samples_get_buffer_size(nil, av_frame_get_channels(ivs.frame),
                                              ivs.frame.nb_samples,
                                              TAVSampleFormat(ivs.frame.format), 1);

      if (ivs.frame.channel_layout <> 0) and (av_frame_get_channels(ivs.frame) = av_get_channel_layout_nb_channels(ivs.frame.channel_layout)) then
        dec_channel_layout := ivs.frame.channel_layout
      else
        dec_channel_layout := av_get_default_channel_layout(av_frame_get_channels(ivs.frame));
      wanted_nb_samples := synchronize_audio(ivs, ivs.frame.nb_samples);

      if (get_master_sync_type(ivs) = AV_SYNC_EXTERNAL_CLOCK) and (ivs.extclk.speed <> 1.0) then
      begin
        // hack: change tempo for playback speed
        Assert(TAVSampleFormat(ivs.frame.format) = AV_SAMPLE_FMT_S16);
        dec_channels := av_frame_get_channels(ivs.frame);

        // TODO: soundtouch_flush(), soundtouch_clear()

        // calculate resampled data size
        resampled_data_size := Trunc(data_size / ivs.extclk.speed) div (bytes_per_sample * dec_channels) * (bytes_per_sample * dec_channels);

        // malloc buffer
        av_fast_malloc(@ivs.audio_buf1, @ivs.audio_buf1_size, resampled_data_size);
        if not Assigned(ivs.audio_buf1) then
        begin
          DoErrLog('av_fast_malloc() failed');
          Result := AVERROR_ENOMEM;
          Exit;
        end;

        if FEnableAudioSpeed and (FFLoader.Loaded(libSoundTouch)) and (dec_channels in [1, 2]) then
        begin
          if not Assigned(ivs.soundtouch) then
          begin
            // create soundtouch instance
            ivs.soundtouch := soundtouch_createInstance();
            if not Assigned(ivs.soundtouch) then
            begin
              DoErrLog('soundtouch_createInstance() failed');
              Result := AVERROR_ENOMEM;
              Exit;
            end;
            // channels
            ivs.st_channels := dec_channels;
            soundtouch_setChannels(ivs.soundtouch, ivs.st_channels);
            // sample rate
            ivs.st_sample_rate := ivs.audio_tgt.freq;
            soundtouch_setSampleRate(ivs.soundtouch, ivs.st_sample_rate);
            // tempo
            ivs.st_tempo := ivs.extclk.speed;
            soundtouch_setTempo(ivs.soundtouch, ivs.st_tempo);
          end
          else
          begin
            // channels
            if ivs.st_channels <> dec_channels then
            begin
              ivs.st_channels := dec_channels;
              soundtouch_setChannels(ivs.soundtouch, ivs.st_channels);
            end;
            // sample rate
            if ivs.st_sample_rate <> ivs.audio_tgt.freq then
            begin
              ivs.st_sample_rate := ivs.audio_tgt.freq;
              soundtouch_setSampleRate(ivs.soundtouch, ivs.st_sample_rate);
            end;
            // tempo
            if ivs.st_tempo <> ivs.extclk.speed then
            begin
              ivs.st_tempo := ivs.extclk.speed;
              soundtouch_setTempo(ivs.soundtouch, ivs.st_tempo);
            end;
          end;

          // put samples
          soundtouch_putSamples(ivs.soundtouch,
            PSingle(ivs.frame.data[0]), {ivs.frame.nb_samples}data_size div (bytes_per_sample * ivs.st_channels));
          // receive samples
          wanted_nb_samples := soundtouch_receiveSamples(ivs.soundtouch,
            PSingle(ivs.audio_buf1), {wanted_nb_samples}resampled_data_size div (bytes_per_sample * ivs.st_channels));

          if wanted_nb_samples <= 0 then
            Break
          else
            resampled_data_size := wanted_nb_samples * bytes_per_sample * ivs.st_channels;
        end
        else
          // just silence
          FillChar(ivs.audio_buf1^, resampled_data_size, 0);
        ivs.audio_buf := ivs.audio_buf1;
        // hack end
      end
      else
      begin
        resampled_data_size := data_size;
        if (TAVSampleFormat(ivs.frame.format) <> ivs.audio_src.fmt) or
          (dec_channel_layout <> ivs.audio_src.channel_layout) or
          (ivs.frame.sample_rate <> ivs.audio_src.freq) or
          ((wanted_nb_samples <> ivs.frame.nb_samples) and not Assigned(ivs.swr_ctx)) then
        begin
          swr_free(@ivs.swr_ctx);
          ivs.swr_ctx := swr_alloc_set_opts(nil,
                           ivs.audio_tgt.channel_layout, ivs.audio_tgt.fmt, ivs.audio_tgt.freq,
                           dec_channel_layout, TAVSampleFormat(ivs.frame.format), ivs.frame.sample_rate,
                           0, nil);
          if not Assigned(ivs.swr_ctx) or (swr_init(ivs.swr_ctx) < 0) then
          begin
            DoErrLog(Format('Cannot create sample rate converter for conversion of %d Hz %s %d channels to %d Hz %s %d channels!',
               [ivs.frame.sample_rate, av_get_sample_fmt_name(TAVSampleFormat(ivs.frame.format)), av_frame_get_channels(ivs.frame),
                ivs.audio_tgt.freq, av_get_sample_fmt_name(ivs.audio_tgt.fmt), ivs.audio_tgt.channels]));
            Break;
          end;
          ivs.audio_src.channel_layout := dec_channel_layout;
          ivs.audio_src.channels := av_frame_get_channels(ivs.frame);
          ivs.audio_src.freq := ivs.frame.sample_rate;
          ivs.audio_src.fmt := TAVSampleFormat(ivs.frame.format);
        end;

        //resampled_data_size := data_size;
        if Assigned(ivs.swr_ctx) then
        begin
          //const uint8_t **in = (const uint8_t **)is->frame->extended_data;
          in_buf := ivs.frame.extended_data;
          out_buf := @ivs.audio_buf1;
          out_count := Int64(wanted_nb_samples) * ivs.audio_tgt.freq div ivs.frame.sample_rate + 256;
          out_size := av_samples_get_buffer_size(nil, ivs.audio_tgt.channels, out_count, ivs.audio_tgt.fmt, 0);
          if out_size < 0 then
          begin
            FFLogger.Log(Self, llError, 'av_samples_get_buffer_size() failed');
            Break;
          end;
          if wanted_nb_samples <> ivs.frame.nb_samples then
          begin
            if swr_set_compensation(ivs.swr_ctx, (wanted_nb_samples - ivs.frame.nb_samples) * ivs.audio_tgt.freq div ivs.frame.sample_rate,
                                    wanted_nb_samples * ivs.audio_tgt.freq div ivs.frame.sample_rate) < 0 then
            begin
              DoErrLog('swr_set_compensation() failed');
              Break;
            end;
          end;
          av_fast_malloc(@ivs.audio_buf1, @ivs.audio_buf1_size, out_size);
          if not Assigned(ivs.audio_buf1) then
          begin
            DoErrLog('av_fast_malloc() failed');
            Result := AVERROR_ENOMEM;
            Exit;
          end;
          len2 := swr_convert(ivs.swr_ctx,
                    out_buf, out_count, in_buf, ivs.frame.nb_samples);
          if len2 < 0 then
          begin
            DoErrLog('swr_convert() failed');
            Break;
          end;
          if len2 = out_count then
          begin
            FFLogger.Log(Self, llWarning, 'audio buffer is probably too small');
            swr_init(ivs.swr_ctx);
          end;
          ivs.audio_buf := ivs.audio_buf1;
          resampled_data_size := len2 * ivs.audio_tgt.channels * av_get_bytes_per_sample(ivs.audio_tgt.fmt);
        end
        else
          ivs.audio_buf := ivs.frame.data[0];
      end;

      pts_ptr^ := ivs.audio_clock;
      (* update the audio clock with the pts *)
      if ivs.frame.pts <> AV_NOPTS_VALUE then
        ivs.audio_clock := ivs.frame.pts * av_q2d(tb) + ivs.frame.nb_samples / ivs.frame.sample_rate
      else
        ivs.audio_clock := NaN;
      ivs.audio_clock_serial := ivs.audio_pkt_temp_serial;
{$IFDEF DEBUG_SYNC}
      GDebuger.Debug('[DEBUG_SYNC] audio: delay=%0.3f clock=%0.3f clock0=%0.3f',
             [ivs.audio_clock - last_clock, ivs.audio_clock, pts_ptr^]);
      last_clock := ivs.audio_clock;
{$ENDIF}
      Result := resampled_data_size;
      Exit;
    end;

    (* free the current packet *)
    if Assigned(pkt.data) then
      av_free_packet(pkt);
    FillChar(pkt_temp^, SizeOf(pkt_temp^), 0);
    pkt_temp.stream_index := -1;

    if (ivs.paused <> 0) or (ivs.audioq.abort_request <> 0) then
    begin
      Result := -1;
      Exit;
    end;

    if ivs.audioq.nb_packets = 0 then
      SDL_CondSignal(ivs.continue_read_thread);

    (* read next packet *)
    ret := packet_queue_get(@ivs.audioq, pkt, 0, @ivs.audio_pkt_temp_serial);
    if ret = 0 then
      Sleep(1) // hack: give time slice to other threads to avoid thread competition issue under Windows XP
    else if ret < 0 then
    begin
      // abort
      Result := -1;
      Exit;
    end;

    if pkt.data = Fflush_pkt.data then
    begin
      avcodec_flush_buffers(avdec);
      ivs.audio_buf_frames_pending := 0;
      ivs.audio_frame_next_pts := AV_NOPTS_VALUE;
      if ((ivs.ic.iformat.flags and (AVFMT_NOBINSEARCH or AVFMT_NOGENSEARCH or AVFMT_NO_BYTE_SEEK)) <> 0) and not Assigned(ivs.ic.iformat.read_seek) then
        ivs.audio_frame_next_pts := ivs.audio_st.start_time;
    end;

    pkt_temp^ := pkt^;
  end;
end;

(* prepare a new audio buffer *)
procedure sdl_audio_callback(opaque: Pointer; stream: PByte{PUint8}; len: Integer); cdecl;
var
  ivs: PVideoState;
  audio_size, len1: Integer;
  bytes_per_sec: Integer;
  frame_size: Integer;
  pts: Double;
begin
  ivs := opaque;
  frame_size := av_samples_get_buffer_size(nil, ivs.audio_tgt.channels, 1, ivs.audio_tgt.fmt, 1);
  ivs.Owner.Faudio_callback_time := av_gettime();

  while len > 0 do
  begin
    if ivs.audio_buf_index >= Integer(ivs.audio_buf_size) then
    begin
      audio_size := ivs.Owner.audio_decode_frame(ivs, @pts);
      // hack: break immediately
      if ivs.audioq.abort_request <> 0 then
        Break;
      // hack end
      if audio_size < 0 then
      begin
        (* if error, just output silence *)
        ivs.audio_buf      := @ivs.silence_buf[0];
        ivs.audio_buf_size := SizeOf(ivs.silence_buf) div frame_size * frame_size;
      end
      else
      begin
        ivs.Owner.DoAudioHook(pts, ivs.audio_buf, audio_size); // hack: audio hook
        if ivs.show_mode <> SHOW_MODE_VIDEO then
          update_sample_display(ivs, PSmallInt(ivs.audio_buf), audio_size);
        ivs.audio_buf_size := audio_size;
      end;
      ivs.audio_buf_index := 0;
    end;
    len1 := Integer(ivs.audio_buf_size) - ivs.audio_buf_index;
    if len1 > len then
      len1 := len;
    // hack: audio volume
    if ivs.Owner.FMute or (ivs.Owner.FAudioVolume = 0) then
      FillChar(stream^, len1, 0)
    else if ivs.Owner.FAudioVolume = SDL_MIX_MAXVOLUME then
      Move(PByte(Integer(ivs.audio_buf) + ivs.audio_buf_index)^, stream^, len1)
    else
      ivs.Owner.SDL_MixAudio(PUint8(stream), PUint8(PAnsiChar(ivs.audio_buf) + ivs.audio_buf_index), len1,
        ivs.Owner.FAudioVolume); // SDL_MIX_MAXVOLUME);
    // hack end
    Dec(len, len1);
    Inc(stream, len1);
    Inc(ivs.audio_buf_index, len1);
  end;
  bytes_per_sec := ivs.audio_tgt.freq * ivs.audio_tgt.channels * av_get_bytes_per_sample(ivs.audio_tgt.fmt);
  ivs.audio_write_buf_size := Integer(ivs.audio_buf_size) - ivs.audio_buf_index;
  (* Let's assume the audio driver that is used by SDL has two periods. *)
  if not IsNaN(ivs.audio_clock) then
  begin
    set_clock_at(@ivs.audclk, ivs.audio_clock - (2 * ivs.audio_hw_buf_size + ivs.audio_write_buf_size) / bytes_per_sec, ivs.audio_clock_serial, ivs.Owner.Faudio_callback_time / 1000000.0);
    sync_clock_to_slave(@ivs.extclk, @ivs.audclk);
  end;
end;

function TCustomPlayer.audio_open(opaque: Pointer; wanted_channel_layout: Int64;
  wanted_nb_channels, wanted_sample_rate: Integer; audio_hw_params: PAudioParams): Integer;
const
  next_nb_channels: array[0..7] of Integer = (0, 0, 1, 6, 2, 6, 4, 6);
var
  wanted_spec, spec: TSDL_AudioSpec;
  env: PAnsiChar;
begin
  env := SDL_getenv('SDL_AUDIO_CHANNELS');
  if Assigned(env) then
  begin
    wanted_nb_channels := my_atoi(env);
    wanted_channel_layout := av_get_default_channel_layout(my_atoi(env));
  end;
  if (wanted_channel_layout = 0) or (wanted_nb_channels <> av_get_channel_layout_nb_channels(wanted_channel_layout)) then
  begin
    wanted_channel_layout := av_get_default_channel_layout(wanted_nb_channels);
    wanted_channel_layout := wanted_channel_layout and not AV_CH_LAYOUT_STEREO_DOWNMIX;
  end;
  wanted_spec.channels := av_get_channel_layout_nb_channels(wanted_channel_layout);
  wanted_spec.freq := wanted_sample_rate;
  if (wanted_spec.freq <= 0) or (wanted_spec.channels <= 0) then
  begin
    DoErrLog('Invalid sample rate or channel count!');
    Result := -1;
    Exit;
  end;

  wanted_spec.format := AUDIO_S16SYS;
  wanted_spec.silence := 0;
  wanted_spec.samples := SDL_AUDIO_BUFFER_SIZE;
  wanted_spec.callback := sdl_audio_callback;
  wanted_spec.userdata := opaque;
  while SDL_OpenAudio(@wanted_spec, @spec) < 0 do
  begin
    FFLogger.Log(Self, llWarning, 'SDL_OpenAudio (%d channels): %s', [wanted_spec.channels, string(SDL_GetError())]);
    if 7 < wanted_spec.channels then
      wanted_spec.channels := next_nb_channels[7]
    else
      wanted_spec.channels := next_nb_channels[wanted_spec.channels];
    if wanted_spec.channels = 0 then
    begin
      DoErrLog('No more channel combinations to try, audio open failed');
      Result := -1;
      Exit;
    end;
    wanted_channel_layout := av_get_default_channel_layout(wanted_spec.channels);
  end;
  if spec.format <> AUDIO_S16SYS then
  begin
    DoErrLog(Format('SDL advised audio format %d is not supported!', [spec.format]));
    Result := -1;
    Exit;
  end;
  if spec.channels <> wanted_spec.channels then
  begin
    wanted_channel_layout := av_get_default_channel_layout(spec.channels);
    if wanted_channel_layout = 0 then
    begin
      DoErrLog(Format('SDL advised channel count %d is not supported!', [spec.channels]));
      Result := -1;
      Exit;
    end;
  end;

  audio_hw_params.fmt := AV_SAMPLE_FMT_S16;
  audio_hw_params.freq := spec.freq;
  audio_hw_params.channel_layout := wanted_channel_layout;
  audio_hw_params.channels := spec.channels;
  Result := spec.size;
end;

(* open a given stream. Return 0 if OK *)
function TCustomPlayer.stream_component_open(ivs: PVideoState; stream_index: Integer): Integer;
var
  ic: PAVFormatContext;
  avctx: PAVCodecContext;
  codec: PAVCodec;
  forced_codec_name: string;
  opts: PAVDictionary;
  t: PAVDictionaryEntry;
  sample_rate, nb_channels: Integer;
  channel_layout: Int64;
  ret: Integer;
  stream_lowres: Integer;
  link: PAVFilterLink;
begin
  Result := -1;
  ic := ivs.ic;

  if (stream_index < 0) or (stream_index >= Integer(ic.nb_streams)) then
    Exit;

  avctx := PPtrIdx(ic.streams, stream_index)^.codec;

  codec := avcodec_find_decoder(avctx.codec_id);

  case avctx.codec_type of
    AVMEDIA_TYPE_AUDIO:
      begin
        ivs.last_audio_stream := stream_index;
        forced_codec_name := Faudio_codec_name;
      end;
    AVMEDIA_TYPE_SUBTITLE:
      begin
        ivs.last_subtitle_stream := stream_index;
        forced_codec_name := Fsubtitle_codec_name;
      end;
    AVMEDIA_TYPE_VIDEO:
      begin
        ivs.last_video_stream := stream_index;
        forced_codec_name := Fvideo_codec_name;
      end;
  else
    forced_codec_name := '';
  end;
  if forced_codec_name <> '' then
    codec := avcodec_find_decoder_by_name(PAnsiChar(AnsiString(forced_codec_name)));
  if not Assigned(codec) then
  begin
    if forced_codec_name <> '' then
      DoErrLog(Format('No codec could be found with name "%s"', [forced_codec_name]))
    else
      DoErrLog(Format('No codec could be found with id %d', [Ord(avctx.codec_id)]));
    Exit;
  end;

  avctx.codec_id := codec.id;
  avctx.workaround_bugs := Fworkaround_bugs;
  stream_lowres := Flowres;
  if stream_lowres > av_codec_get_max_lowres(codec) then
  begin
    FFLogger.Log(Self, llWarning, 'The maximum value for lowres supported by the decoder is %d',
                [av_codec_get_max_lowres(codec)]);
    stream_lowres := av_codec_get_max_lowres(codec);
  end;
  av_codec_set_lowres(avctx, stream_lowres);
  avctx.error_concealment := Ferror_concealment;

  if stream_lowres <> 0 then
    avctx.flags := avctx.flags or CODEC_FLAG_EMU_EDGE;
  if Ffast then
    avctx.flags2 := avctx.flags2 or CODEC_FLAG2_FAST;
  if codec.capabilities and CODEC_CAP_DR1 <> 0 then
    avctx.flags := avctx.flags or CODEC_FLAG_EMU_EDGE;

  opts := filter_codec_opts(FOptions.codec_opts, avctx.codec_id, ic, PPtrIdx(ic.streams, stream_index), codec);
  if not Assigned(av_dict_get(opts, 'threads', nil, 0)) then
    av_dict_set(@opts, 'threads', 'auto', 0);
  if stream_lowres <> 0 then
    av_dict_set(@opts, 'lowres', av_asprintf('%d', stream_lowres), AV_DICT_DONT_STRDUP_VAL);
  if (avctx.codec_type = AVMEDIA_TYPE_VIDEO) or (avctx.codec_type = AVMEDIA_TYPE_AUDIO) then
    av_dict_set(@opts, 'refcounted_frames', '1', 0);
  if avcodec_open2(avctx, codec, @opts) < 0 then
  begin
    DoErrLog('avcodec_open2() failed.');
    Exit;
  end;
  t := av_dict_get(opts, '', nil, AV_DICT_IGNORE_SUFFIX);
  if Assigned(t) then
  begin
    DoErrLog(Format('Option %s not found.', [string(t.key)]));
    av_dict_free(@opts); // hack: memory leak
    Result := AVERROR_OPTION_NOT_FOUND;
    Exit;
  end;

  PPtrIdx(ic.streams, stream_index)^.discard := AVDISCARD_DEFAULT;
  case avctx.codec_type of
    AVMEDIA_TYPE_AUDIO:
      begin
{$IFDEF CONFIG_AVFILTER}
        ivs.audio_filter_src.freq           := avctx.sample_rate;
        ivs.audio_filter_src.channels       := avctx.channels;
        ivs.audio_filter_src.channel_layout := get_valid_channel_layout(avctx.channel_layout, avctx.channels);
        ivs.audio_filter_src.fmt            := avctx.sample_fmt;
        ret := configure_audio_filters(ivs, Fafilters, 0);
        if ret < 0 then
        begin
          Result := ret;
          Exit;
        end;
        link := ivs.out_audio_filter.inputs^;
        sample_rate    := link.sample_rate;
        nb_channels    := link.channels;
        channel_layout := link.channel_layout;
{$ELSE}
        sample_rate    := avctx.sample_rate;
        nb_channels    := avctx.channels;
        channel_layout := avctx.channel_layout;
{$ENDIF}

        (* prepare audio output *)
        ret := audio_open(ivs, channel_layout, nb_channels, sample_rate, @ivs.audio_tgt);
        if ret < 0 then
        begin
          Result := ret;
          Exit;
        end;
        ivs.audio_hw_buf_size := ret;
        ivs.audio_src := ivs.audio_tgt;
        ivs.audio_buf_size := 0;
        ivs.audio_buf_index := 0;

        (* init averaging filter *)
        ivs.audio_diff_avg_coef := exp(log10(0.01) / AUDIO_DIFF_AVG_NB);
        ivs.audio_diff_avg_count := 0;
        (* since we do not have a precise anough audio fifo fullness,
           we correct audio sync only if larger than this threshold *)
        ivs.audio_diff_threshold := 2.0 * ivs.audio_hw_buf_size / av_samples_get_buffer_size(nil, ivs.audio_tgt.channels, ivs.audio_tgt.freq, ivs.audio_tgt.fmt, 1);

        FillChar(ivs.audio_pkt, SizeOf(ivs.audio_pkt), 0);
        FillChar(ivs.audio_pkt_temp, SizeOf(ivs.audio_pkt_temp), 0);
        ivs.audio_pkt_temp.stream_index := -1;

        ivs.audio_stream := stream_index;
        ivs.audio_st := PPtrIdx(ic.streams, stream_index);
        // hack: audio duration
        if Assigned(ivs.audio_st) and (ivs.audio_st.duration <> AV_NOPTS_VALUE) then
          ivs.AudioDuration := av_rescale_q(ivs.audio_st.duration, ivs.audio_st.time_base, AV_TIME_BASE_Q)
        else
          ivs.AudioDuration := -1;
        // hack end

        packet_queue_start(@ivs.audioq);
        SDL_PauseAudio(0);
      end;
    AVMEDIA_TYPE_VIDEO:
      begin
        ivs.video_stream := stream_index;
        ivs.video_st := PPtrIdx(ic.streams, stream_index);

        // hack: frame delay
        with ivs.video_st^ do
          if (codec.time_base.num <> r_frame_rate.den) or
            (codec.time_base.den <> r_frame_rate.num * codec.ticks_per_frame) then
          begin
            FFLogger.Log(Self, llInfo,
              Format('Seems stream %d codec frame rate differs from container frame rate: %2.2f (%d/%d) -> %2.2f (%d/%d)',
                      [stream_index, codec.time_base.den / codec.time_base.num, codec.time_base.den, codec.time_base.num,
                       r_frame_rate.num / r_frame_rate.den, r_frame_rate.num, r_frame_rate.den]));
            ivs.frame_delay := r_frame_rate.den / r_frame_rate.num;
          end
          else
            ivs.frame_delay := av_q2d(codec.time_base);
        // hack end

        packet_queue_start(@ivs.videoq);
        ivs.video_tid := SDL_CreateThread({$IFDEF FPC}@{$ENDIF}video_thread, ivs);
        ivs.queue_attachments_req := 1;
      end;
    AVMEDIA_TYPE_SUBTITLE:
      begin
        ivs.subtitle_stream := stream_index;
        ivs.subtitle_st := PPtrIdx(ic.streams, stream_index);

        packet_queue_start(@ivs.subtitleq);
        ivs.subtitle_tid := SDL_CreateThread({$IFDEF FPC}@{$ENDIF}subtitle_thread, ivs);
      end;
  end;
  Result := 0;
end;

// close a given stream
procedure TCustomPlayer.stream_component_close(ivs: PVideoState; stream_index: Integer);
var
  ic: PAVFormatContext;
  avctx: PAVCodecContext;
  ret: Integer;
begin
  ic := ivs.ic;

  if (stream_index < 0) or (stream_index >= Integer(ic.nb_streams)) then
    Exit;
  avctx := PPtrIdx(ic.streams, stream_index)^.codec;

  case avctx.codec_type of
    AVMEDIA_TYPE_AUDIO:
      begin
        packet_queue_abort(@ivs.audioq);

        SDL_CloseAudio();

        packet_queue_flush(@ivs.audioq);
        av_free_packet(@ivs.audio_pkt);
        swr_free(@ivs.swr_ctx);
        av_freep(@ivs.audio_buf1);
        ivs.audio_buf1_size := 0;
        ivs.audio_buf := nil;
        av_frame_free(@ivs.frame);

        // hack: soundtouch
        if Assigned(ivs.soundtouch) then
        begin
          if Assigned(soundtouch_destroyInstance) then
            soundtouch_destroyInstance(ivs.soundtouch);
          ivs.soundtouch := nil;
        end;
        // hack end

        if Assigned(ivs.rdft) then
        begin
          av_rdft_end(ivs.rdft);
          av_freep(@ivs.rdft_data);
          ivs.rdft := nil;
          ivs.rdft_bits := 0;
        end;
{$IFDEF CONFIG_AVFILTER}
        avfilter_graph_free(@ivs.agraph);
{$ENDIF}
      end;
    AVMEDIA_TYPE_VIDEO:
      begin
        packet_queue_abort(@ivs.videoq);

        (* note: we also signal this mutex to make sure we deblock the video thread in all cases *)
        SDL_LockMutex(ivs.pictq_mutex);
        SDL_CondSignal(ivs.pictq_cond);
        SDL_UnlockMutex(ivs.pictq_mutex);

        ret := 0;
        SDL_WaitThread(ivs.video_tid, ret);

        packet_queue_flush(@ivs.videoq);
      end;
    AVMEDIA_TYPE_SUBTITLE:
      begin
        packet_queue_abort(@ivs.subtitleq);

        (* note: we also signal this mutex to make sure we deblock the video thread in all cases *)
        SDL_LockMutex(ivs.subpq_mutex);
        SDL_CondSignal(ivs.subpq_cond);
        SDL_UnlockMutex(ivs.subpq_mutex);

        ret := 0;
        SDL_WaitThread(ivs.subtitle_tid, ret);

        packet_queue_flush(@ivs.subtitleq);
      end;
  end;

  PPtrIdx(ic.streams, stream_index)^.discard := AVDISCARD_ALL;
  avcodec_close(avctx);
  case avctx.codec_type of
    AVMEDIA_TYPE_AUDIO:
      begin
        ivs.audio_st := nil;
        ivs.audio_stream := -1;
        ivs.AudioDuration := -1;  // hack
      end;
    AVMEDIA_TYPE_VIDEO:
      begin
        ivs.video_st := nil;
        ivs.video_stream := -1;
      end;
    AVMEDIA_TYPE_SUBTITLE:
      begin
        ivs.subtitle_st := nil;
        ivs.subtitle_stream := -1;
      end;
  end;
end;

// hack: for read timeout
function read_interrupt_callback(opaque: Pointer): Integer; cdecl;
begin
  //if TObject(opaque) is TCustomPlayer then
    with TObject(opaque) as TCustomPlayer do
    begin
      if Assigned(FVideoStateCB) and (FVideoStateCB.abort_request <> 0) then
      begin
        FFLogger.Log(TObject(opaque), llInfo, 'connecting/reading broken');
        Result := 1;
        Exit;
      end;
      if (FLastRead < High(Int64)) and (FReadTimeout > 0) and (av_gettime() - FLastRead > FReadTimeout * 1000) then
      begin
        if FLastRead <> 0 then
          FFLogger.Log(TObject(opaque), llInfo, 'connecting/reading timeout')
        else
          FFLogger.Log(TObject(opaque), llInfo, 'connecting/reading canceled');
        Result := 1;
        Exit;
      end;
    end;
  Result := 0;
end;

// hack: for convenience
procedure TCustomPlayer.PushAspectEvent(arg: Pointer);
var
  event: TSDL_Event;
begin
  event.type_ := FF_ASPECT_EVENT;
  event.user.data1 := arg;
  SDL_PushEvent(@event);
end;

// hack: for convenience
procedure TCustomPlayer.PushQuitEvent(arg: Pointer);
var
  event: TSDL_Event;
begin
  event.type_ := FF_QUIT_EVENT;
  event.user.data1 := arg;
  SDL_PushEvent(@event);
end;

function is_realtime(s: PAVFormatContext): Integer;
begin
  if (my_strcmp(s.iformat.name, 'rtp')  = 0) or
     (my_strcmp(s.iformat.name, 'rtsp') = 0) or
     (my_strcmp(s.iformat.name, 'sdp')  = 0) then
    Result := 1
  else if Assigned(s.pb) and
    ((my_strncmp(s.filename, 'rtp:', 4) = 0) or
     (my_strncmp(s.filename, 'udp:', 4) = 0)) then
    Result := 1
  else
    Result := 0;
end;

(* this thread gets the stream from the disk or the network *)
function read_thread(arg: Pointer): Integer; cdecl;
begin
  PVideoState(arg).Owner.do_read_thread(arg);
  Result := 0;
end;

function TCustomPlayer.do_open_stream(arg: Pointer): Integer;
var
  ivs: PVideoState;
  ic: PAVFormatContext;
  err, i, ret: Integer;
{$IF Defined(BCB) and Defined(VER140)} // C++Builder 6
  st_index: array[AVMEDIA_TYPE_UNKNOWN..AVMEDIA_TYPE_NB] of Integer;
{$ELSE}
  st_index: array[TAVMediaType] of Integer;
{$IFEND}
  timestamp: Int64;
  t: PAVDictionaryEntry;
  opts: PPAVDictionary;
  orig_nb_streams: Integer;
  label fail;
begin
  ivs := arg;

  FillChar(st_index[AVMEDIA_TYPE_UNKNOWN], SizeOf(st_index), $FF);
  ivs.last_video_stream := -1;
  ivs.video_stream := -1;
  ivs.last_audio_stream := -1;
  ivs.audio_stream := -1;
  ivs.last_subtitle_stream := -1;
  ivs.subtitle_stream := -1;

  ic := avformat_alloc_context();
  with ic.interrupt_callback do
  begin
    callback := read_interrupt_callback; // hack: read timeout
    opaque := Self;
  end;

{
  opt_default('video_size',    '640x480');  // video_size
  opt_default('pixel_format',  'yuv420p');  // pixel_format
  opt_default('framerate',    '25/1');      // frame_rate
  opt_default('sample_rate',  '44100');     // sample_rate
  opt_default('channels',     '2');         // channels
  opt_default('channel',      '1');         // Used to select DV channel
  opt_default('mpeg2ts_compute_pcr', '1');
  opt_default('initial_pause', '1');        // Do not begin to play the stream immediately (RTSP only)
}
  FLastRead := av_gettime(); // hack: for read timeout
  err := avformat_open_input(@ic, ffmpeg_filename(ivs.filename), ivs.iformat, @FOptions.format_opts);
  if err < 0 then
  begin
    // fail to open input file
    FLastErrMsg := print_error(ivs.filename, err);
    ret := -1;
    goto fail;
  end;
  t := av_dict_get(FOptions.format_opts, '', nil, AV_DICT_IGNORE_SUFFIX);
  while Assigned(t) do
  begin
    FFLogger.Log(Self, llError, 'Option %s not found, ignored.', [string(t.key)]);
    t := av_dict_get(FOptions.format_opts, '', t, AV_DICT_IGNORE_SUFFIX);
    //ret := AVERROR_OPTION_NOT_FOUND;
    //goto fail;
  end;
  ivs.ic := ic;
  FAVFormatContext := ic;

  // generate pts
  if Fgenpts then
    ic.flags := ic.flags or AVFMT_FLAG_GENPTS;

  // hack: before find stream info event
  if Assigned(FOnBeforeFindStreamInfo) then
  begin
    if FTriggerEventInMainThread then
      MySynchronize(CallBeforeFindStreamInfo)
    else
      CallBeforeFindStreamInfo;
  end;
  // hack end

//  av_dict_set(@FOptions.codec_opts, 'request_channels', '2', 0); // TODO: do we need this?

  opts := setup_find_stream_info_opts(ic, FOptions.codec_opts);
  orig_nb_streams := ic.nb_streams;

  // try to find stream info of input file
  FLastRead := av_gettime(); // hack: for read timeout
  err := avformat_find_stream_info(ic, opts);
  if err < 0 then
  begin
    DoErrLog(Format('%s: could not find codec parameters', [ivs.filename]), True);
    ret := -1;
    goto fail;
  end;
  for i := 0 to orig_nb_streams - 1 do
    av_dict_free(PtrIdx(opts, i));
  av_freep(@opts);

  if Assigned(ic.pb) then
  begin
    ic.pb.eof_reached := 0; //FIXME hack, ffplay maybe should not use url_feof() to test for the end
    ic.pb.error := 0; // hack
  end;

  if Fseek_by_bytes < 0 then
  begin
    //seek_by_bytes = !!(ic->iformat->flags & AVFMT_TS_DISCONT) && strcmp("ogg", ic->iformat->name);
    if ((ic.iformat.flags and AVFMT_TS_DISCONT) <> 0) and (my_strcmp('ogg', ic.iformat.name) <> 0) then
      Fseek_by_bytes := 1
    else
      Fseek_by_bytes := 0;
  end;

  if (ic.iformat.flags and AVFMT_TS_DISCONT) <> 0 then
    ivs.max_frame_duration :=  10.0
  else
    ivs.max_frame_duration :=  3600.0;

  // hack: for some status
  ivs.IsImage2 := Ord(ic.iformat.name = 'image2');
  ivs.IsDevice := Ord((ic.iformat.name = 'vfwcap') or (ic.iformat.name = 'vfwcapture') or (ic.iformat.name = 'dshow'));
  if ic.start_time <> AV_NOPTS_VALUE then
    ivs.StartTime := ic.start_time;

  if ic.duration <> AV_NOPTS_VALUE then
    ivs.FileDuration := ic.duration
  else
    ivs.FileDuration := -1;
  // hack end

  (* if seeking requested, we execute it *)
  if Fstart_time <> AV_NOPTS_VALUE then
  begin
    timestamp := Fstart_time;
    (* add the stream start time *)
    if ic.start_time <> AV_NOPTS_VALUE then
      Inc(timestamp, ic.start_time);
    FLastRead := av_gettime();  // hack: for read timeout
    ret := avformat_seek_file(ic, -1, Low(Int64), timestamp, High(Int64), 0);
    if ret < 0 then
      FFLogger.Log(Self, llWarning, '%s: could not seek to position %0.3f', [ivs.filename, timestamp / AV_TIME_BASE]);
  end;

  ivs.realtime := is_realtime(ic);

  // find which audio and/or video stream to play
  for i := 0 to Integer(ic.nb_streams) - 1 do
    PPtrIdx(ic.streams, i)^.discard := AVDISCARD_ALL;
  if not Fvideo_disable then
    st_index[AVMEDIA_TYPE_VIDEO] :=
      av_find_best_stream(ic, AVMEDIA_TYPE_VIDEO,
                          Fwanted_stream[AVMEDIA_TYPE_VIDEO], -1, nil, 0);
  if not Faudio_disable then
    st_index[AVMEDIA_TYPE_AUDIO] :=
      av_find_best_stream(ic, AVMEDIA_TYPE_AUDIO,
                          Fwanted_stream[AVMEDIA_TYPE_AUDIO],
                          st_index[AVMEDIA_TYPE_VIDEO],
                          nil, 0);
  if not Fvideo_disable and not Fsubtitle_disable then
    if st_index[AVMEDIA_TYPE_AUDIO] >= 0 then
      st_index[AVMEDIA_TYPE_SUBTITLE] :=
        av_find_best_stream(ic, AVMEDIA_TYPE_SUBTITLE,
                            Fwanted_stream[AVMEDIA_TYPE_SUBTITLE],
                            st_index[AVMEDIA_TYPE_AUDIO],
                            nil, 0)
    else
      st_index[AVMEDIA_TYPE_SUBTITLE] :=
        av_find_best_stream(ic, AVMEDIA_TYPE_SUBTITLE,
                            Fwanted_stream[AVMEDIA_TYPE_SUBTITLE],
                            st_index[AVMEDIA_TYPE_VIDEO],
                            nil, 0);

  // dump format information of input file
//  if Fshow_status <> 0 then
//    av_dump_format(ic, 0, ffmpeg_filename(ivs.filename), 0);

  ivs.show_mode := _TShowMode(FShowMode);

  (* open the streams *)
  if st_index[AVMEDIA_TYPE_AUDIO] >= 0 then
    // TODO 0: if return < 0, what shall we do?
    stream_component_open(ivs, st_index[AVMEDIA_TYPE_AUDIO]);

  ret := -1;
  if st_index[AVMEDIA_TYPE_VIDEO] >= 0 then
    // TODO 0: if return < 0, what shall we do?
    ret := stream_component_open(ivs, st_index[AVMEDIA_TYPE_VIDEO]);

  // hack: create refresh thread only when OPEN OK
  // is.refresh_tid = SDL_CreateThread(refresh_thread, is);
  // hack end

  if ivs.show_mode = SHOW_MODE_NONE then
  begin
    if ret >= 0 then
      ivs.show_mode := SHOW_MODE_VIDEO
    else
      ivs.show_mode := SHOW_MODE_WAVES; // SHOW_MODE_RDFT;
  end;

  if st_index[AVMEDIA_TYPE_SUBTITLE] >= 0 then
    // TODO 0: if return < 0, what shall we do?
    stream_component_open(ivs, st_index[AVMEDIA_TYPE_SUBTITLE]);

  // no stream to play
  if (ivs.video_stream < 0) and (ivs.audio_stream < 0) then
  begin
    FLastErrMsg := Format('Failed to open file "%s" or configure filtergraph', [ivs.filename]);
    FFLogger.Log(Self, llFatal, FLastErrMsg);
    ret := -1;
    goto fail;
  end;

  if (Finfinite_buffer < 0) and (ivs.realtime = 1) then
    Finfinite_buffer := 1;

  FPictEvent.SetEvent; // hack: sanity set event

  // hack: indicate open file OK
  ivs.FileOpened := 1;
  FVideoStateCB := ivs;
  if ivs.wait_for_stream_opened = 0 then
  begin
    FVideoState := ivs;
    DoStreamOpened;
  end;
  // hack end

  // ready to read loop
  Result := 0;
  Exit;

fail:
  Result := ret;
  if ivs.open_in_caller_thread = 0 then
    Exit;

  // hack: open status, failed
  if ivs.FileOpened <> 1 then
    ivs.FileOpened := -1;
  // hack end

  // hack: disable interrupting
  FLastRead := High(Int64);
  if Assigned(ic) then
    ic.interrupt_callback.callback := nil;
  FVideoStateCB := nil;
  // hack end

  (* close each stream *)
  if ivs.audio_stream >= 0 then
    stream_component_close(ivs, ivs.audio_stream);
  if ivs.video_stream >= 0 then
    stream_component_close(ivs, ivs.video_stream);
  if ivs.subtitle_stream >= 0 then
    stream_component_close(ivs, ivs.subtitle_stream);

  // close file handle
  FDecoder.FileHandle := nil; // hack: decoder
  FAVFormatContext := nil;
  if Assigned(ivs.ic) then
    avformat_close_input(@ivs.ic);

  if ret <> 0 then
  begin
    PushQuitEvent(ivs);
    Sleep(10);  // hack
  end;
//  SDL_DestroyMutex(wait_mutex);

  // hack: open status
  if ivs.FileOpened = -1 then
  begin
    ivs.FileOpened := -2;
    if ivs.wait_for_stream_opened = 0 then
      DoReleaseResourceOnFailed(ivs);
    if FTriggerEventInMainThread then
      MySynchronize(DoOpenFailed)
    else
      DoOpenFailed;
  end;
  // hack end
end;

procedure TCustomPlayer.do_read_thread(arg: Pointer);
var
  ivs: PVideoState;
  ic: PAVFormatContext;
  ret: Integer;
  pkt1: TAVPacket;
  pkt: PAVPacket;
  seek_target: Int64;
  seek_min: Int64;
  seek_max: Int64;
  eof: Boolean;
  wait_mutex: PSDL_mutex;
  copy_pkt: TAVPacket;
  label fail;
begin
  ivs := arg;
  pkt := @pkt1;
  eof := False;
  wait_mutex := SDL_CreateMutex();

  if ivs.open_in_caller_thread = 0 then
  begin
    ret := do_open_stream(arg);
    ic := ivs.ic;
    if ret < 0 then
      goto fail;
  end
  else
    ic := ivs.ic;

  // loop to read frame
  while True do
  begin
    // abort request
    if ivs.abort_request <> 0 then
      Break;

    // pause process
    if ivs.paused <> ivs.last_paused then
    begin
      ivs.last_paused := ivs.paused;
      if ivs.paused <> 0 then
        ivs.read_pause_return := av_read_pause(ic)
      else
        av_read_play(ic);
    end;

    // pause process for rtsp and mmsh
    if (ivs.paused <> 0) and
{$IFDEF VCL_XE4_OR_ABOVE}
      ((System.AnsiStrings.AnsiStrComp(ic.iformat.name, 'rtsp') = 0) or
{$ELSE}
      ((AnsiStrComp(ic.iformat.name, 'rtsp') = 0) or
{$ENDIF}
      (Assigned(ic.pb) and (Pos('mmsh:', Finput_filename) = 1))) then
    begin
      (* wait 10 ms to avoid trying to get another packet *)
      (* XXX: horrible *)
      Sleep(10);
      Continue;
    end;

    // seek
    if ivs.seek_req <> 0 then
    begin
      seek_target := ivs.seek_pos;
      if ivs.seek_rel > 0 then
        seek_min := seek_target - ivs.seek_rel + 2
      else
        seek_min := Low(Int64);
      if ivs.seek_rel < 0 then
        seek_max := seek_target - ivs.seek_rel - 2
      else
        seek_max := High(Int64);
// FIXME the +-2 is due to rounding being not done in the correct direction in generation
//      of the seek_pos/seek_rel variables

      FLastRead := av_gettime(); // hack: for read timeout
      ret := avformat_seek_file(ivs.ic, -1, seek_min, seek_target, seek_max, ivs.seek_flags);
      // hack: try seek again with or without AVSEEK_FLAG_BACKWARD
      if ret < 0 then
      begin
        if (ivs.seek_flags and AVSEEK_FLAG_BACKWARD) = 0 then
          ret := avformat_seek_file(ivs.ic, -1, seek_min, seek_target, seek_max, ivs.seek_flags or AVSEEK_FLAG_BACKWARD)
        else
          ret := avformat_seek_file(ivs.ic, -1, seek_min, seek_target, seek_max, ivs.seek_flags and not AVSEEK_FLAG_BACKWARD);
      end;
      // hack end
      if ret < 0 then
      begin
        DoErrLog(Format('%s: error while seeking', [ivs.filename]));
        ivs.seek_paused := 0; // hack: stop refresh for seek paused
        // hack: for picture
        if ivs.video_stream >= 0 then
          FPictEvent.SetEvent;
        // hack end
      end
      else
      begin
        if ivs.audio_stream >= 0 then
        begin
          packet_queue_flush(@ivs.audioq);
          packet_queue_start(@ivs.audioq);
          ivs.audio_pkt_temp.size := 0; // hack: skip ivs.audio_pkt_temp when seek or flush
        end;
        if ivs.subtitle_stream >= 0 then
        begin
          packet_queue_flush(@ivs.subtitleq);
          packet_queue_start(@ivs.subtitleq);
        end;
        if ivs.video_stream >= 0 then
        begin
          ivs.seek_flushed := 0; // hack
          packet_queue_flush(@ivs.videoq);
          packet_queue_start(@ivs.videoq);
          FPictEvent.ResetEvent; // hack
        end;
        if (ivs.seek_flags and AVSEEK_FLAG_BYTE) <> 0 then
          set_clock(@ivs.extclk, NaN, 0)
        else
          set_clock(@ivs.extclk, seek_target / AV_TIME_BASE, 0);
        ivs.flush_req := 0; // hack
      end;
      // hack: set/reset some status
      ivs.IOEOFLog := 0;
      ivs.IOERRLog := 0;
      ivs.ReachEOF := 0;
      ivs.seek_done := 1; // signal to flush pictq
      FSeekEvent.SetEvent;
      if ivs.video_stream < 0 then
        FSeeking := False;
      // hack end
      ivs.seek_req := 0;
      ivs.queue_attachments_req := 1;
      eof := False;
//      if ivs.paused <> 0 then
//        StepToNextFrame;
    end
    // hack: for flush
    else if ivs.flush_req <> 0 then
    begin
      if ivs.audio_stream >= 0 then
      begin
        packet_queue_flush(@ivs.audioq);
        packet_queue_start(@ivs.audioq);
        ivs.audio_pkt_temp.size := 0; // hack: skip ivs.audio_pkt_temp when seek or flush
      end;
      if ivs.subtitle_stream >= 0 then
      begin
        packet_queue_flush(@ivs.subtitleq);
        packet_queue_start(@ivs.subtitleq);
      end;
      if ivs.video_stream >= 0 then
      begin
        ivs.seek_flushed := 0; // hack
        packet_queue_flush(@ivs.videoq);
        packet_queue_start(@ivs.videoq);
        FPictEvent.ResetEvent; // hack
      end;
      set_clock(@ivs.extclk, AV_NOPTS_VALUE, 0);
      ivs.flush_req := 0; // hack
      ivs.seek_done := 1; // hack: signal to flush pictq
    end;
    // hack end
    if ivs.queue_attachments_req <> 0 then
    begin
      if Assigned(ivs.video_st) and ((ivs.video_st.disposition and AV_DISPOSITION_ATTACHED_PIC) <> 0) then
      begin
        ret := av_copy_packet(@copy_pkt, @ivs.video_st.attached_pic);
        if ret < 0 then
          goto fail;
        packet_queue_put(@ivs.videoq, @copy_pkt);
        packet_queue_put_nullpacket(@ivs.videoq, ivs.video_stream);
      end;
      ivs.queue_attachments_req := 0;
    end;

    (* if the queue are full, no need to read more *)
    if (Finfinite_buffer < 1) and
       (ivs.audioq.size + ivs.videoq.size + ivs.subtitleq.size > MAX_QUEUE_SIZE) or
      (((ivs.audioq.nb_packets    > MIN_FRAMES) or (ivs.audio_stream    < 0) or (ivs.audioq.abort_request    <> 0)) and
       ((ivs.videoq.nb_packets    > MIN_FRAMES) or (ivs.video_stream    < 0) or (ivs.videoq.abort_request    <> 0) or
                                                  ((ivs.video_st.disposition and AV_DISPOSITION_ATTACHED_PIC) <> 0)) and
       ((ivs.subtitleq.nb_packets > MIN_FRAMES) or (ivs.subtitle_stream < 0) or (ivs.subtitleq.abort_request <> 0))) then
    begin
      (* wait 10 ms *)
      SDL_LockMutex(wait_mutex);
      SDL_CondWaitTimeout(ivs.continue_read_thread, wait_mutex, 10);
      SDL_UnlockMutex(wait_mutex);
      Continue;
    end;
(*
    if (!is->paused &&
        (!is->audio_st || is->audio_finished == is->audioq.serial) &&
        (!is->video_st || (is->video_finished == is->videoq.serial && is->pictq_size == 0))) {
        if (loop != 1 && (!loop || --loop)) {
            stream_seek(is, start_time != AV_NOPTS_VALUE ? start_time : 0, 0, 0);
        } else if (autoexit) {
            ret = AVERROR_EOF;
            goto fail;
        }
    }
*)
    if eof then
    begin
      if ivs.video_stream >= 0 then
      begin
        packet_queue_put_nullpacket(@ivs.videoq, ivs.video_stream);
        FPictEvent.SetEvent; // hack
      end;
      if ivs.audio_stream >= 0 then
        packet_queue_put_nullpacket(@ivs.audioq, ivs.audio_stream);
      Sleep(10);
      //if ivs.audioq.size + ivs.videoq.size + ivs.subtitleq.size = 0 then
      if (ivs.audioq.nb_packets <= 1) and (ivs.videoq.nb_packets <= 1) and (ivs.subtitleq.nb_packets <= 1) then
        ivs.ReachEOF := 1;  // hack
      eof := False;
      Continue;
    end;

    // read frame packet, return 0 if OK, < 0 on error or end of file
    ivs.Reading := 1; // hack
    try
      FLastRead := av_gettime();  // hack: for read timeout
      ret := av_read_frame(ic, pkt);
      // hack: break immediately
      if ivs.abort_request <> 0 then
      begin
        if ret >= 0 then
          av_free_packet(pkt);
        Break;
      end;
      // hack end
    finally
      ivs.Reading := 0; // hack
    end;
    if ret < 0 then
    begin
      // hack: for picture
      if ivs.video_stream >= 0 then
        FPictEvent.SetEvent;
      // hack end
{
      if (ret == AVERROR_EOF || url_feof(ic->pb))
          eof = 1;
      if (ic->pb && ic->pb->error)
          break;
}
      // hack: eof and error processing
      if ret = AVERROR_EAGAIN then
      begin // again
        Sleep(10);
        if Assigned(ic.pb) then
        begin
          ic.pb.eof_reached := 0;
          ic.pb.error := 0;
        end;
      end
      else if (ret = AVERROR_EOF) or (ret = AVERROR_EPIPE) then
      begin // eof
        eof := True;
        if (ivs.IsImage2 = 0) and (ivs.IOEOFLog = 0) then
        begin
          ivs.IOEOFLog := 1;
          FFLogger.Log(Self, llInfo, Format('reach end of file: %s', [ivs.filename]));
        end;
        if Assigned(ic.pb) then
          ic.pb.error := 0;
      end
      else if Assigned(ic.pb) and (ic.pb.error = AVERROR_EAGAIN) then
      begin // again
        Sleep(10);
        ic.pb.eof_reached := 0;
        ic.pb.error := 0;
      end
      else if url_feof(ic.pb) <> 0 then
      begin // check eof
        if FCheckIOEOF then
        begin
          eof := True;
          if (ivs.IsImage2 = 0) and (ivs.IOEOFLog = 0) then
          begin
            ivs.IOEOFLog := 1;
            FFLogger.Log(Self, llInfo, Format('reach end of file: %s', [ivs.filename]));
          end;
          if Assigned(ic.pb) then
            ic.pb.error := 0;
        end
        else if Assigned(ic.pb) then
        begin
          ic.pb.eof_reached := 0;
          ic.pb.error := 0;
        end;
      end
      else
      begin
        // error
        if (ivs.IsImage2 = 0) and (ivs.IOERRLog = 0) then
        begin
          ivs.IOERRLog := 1;
          DoErrLog(Format('error #%d while reading file: %s', [ret, ivs.filename]));
        end;
        // some files always return -1 without error when reach end of file
        if (ret = -1) and FNegativeOneAsEOF then // and (ivs.audioq.size + ivs.videoq.size + ivs.subtitleq.size = 0) then
        begin
          eof := True; // ivs.ReachEOF := 1;
          if Assigned(ic.pb) then
            ic.pb.error := 0;
        end;
      end;

      if Assigned(ic.pb) and (ic.pb.error <> 0) then
      begin // check error
        if FCheckIOERR then
          Break
        else
        begin
          ic.pb.eof_reached := 0;
          ic.pb.error := 0;
        end;
      end;
      // hack end

      SDL_LockMutex(wait_mutex);
      SDL_CondWaitTimeout(ivs.continue_read_thread, wait_mutex, 10);
      SDL_UnlockMutex(wait_mutex);
      Continue;
    end;

{
    /* check if packet is in play range specified by user, then queue, otherwise discard */
    stream_start_time = ic->streams[pkt->stream_index]->start_time;
    pkt_in_play_range = duration == AV_NOPTS_VALUE ||
            (pkt->pts - (stream_start_time != AV_NOPTS_VALUE ? stream_start_time : 0)) *
            av_q2d(ic->streams[pkt->stream_index]->time_base) -
            (double)(start_time != AV_NOPTS_VALUE ? start_time : 0) / 1000000
            <= ((double)duration / 1000000);
}
    // put packet to queue
    if pkt.stream_index = ivs.audio_stream then
      packet_queue_put(@ivs.audioq, pkt)
    else if (pkt.stream_index = ivs.video_stream) and
      ((ivs.video_st.disposition and AV_DISPOSITION_ATTACHED_PIC) = 0) then
      packet_queue_put(@ivs.videoq, pkt)
    else if pkt.stream_index = ivs.subtitle_stream then
      packet_queue_put(@ivs.subtitleq, pkt)
    else
      av_free_packet(pkt);
  end;

  ivs.seek_paused := 0; // hack: stop refresh for seek paused
  FLastRead := High(Int64); // hack: for read timeout
  (* wait until the end *)
  while ivs.abort_request = 0 do
    Sleep(100);

  ret := 0;

fail:
  // hack: open status, failed
  if ivs.FileOpened <> 1 then
    ivs.FileOpened := -1;
  // hack end

  // hack: disable interrupting
  FLastRead := High(Int64);
  if Assigned(ic) then
    ic.interrupt_callback.callback := nil;
  FVideoStateCB := nil;
  // hack end

  (* close each stream *)
  if ivs.audio_stream >= 0 then
    stream_component_close(ivs, ivs.audio_stream);
  if ivs.video_stream >= 0 then
    stream_component_close(ivs, ivs.video_stream);
  if ivs.subtitle_stream >= 0 then
    stream_component_close(ivs, ivs.subtitle_stream);

  // close file handle
  FDecoder.FileHandle := nil; // hack: decoder
  FAVFormatContext := nil;
  if Assigned(ivs.ic) then
    avformat_close_input(@ivs.ic);

  if ret <> 0 then
  begin
    PushQuitEvent(ivs);
    Sleep(10);  // hack
  end;
  SDL_DestroyMutex(wait_mutex);

  // hack: open status
  if ivs.FileOpened = -1 then
  begin
    ivs.FileOpened := -2;
    if ivs.wait_for_stream_opened = 0 then
      DoReleaseResourceOnFailed(ivs);
    if FTriggerEventInMainThread then
      MySynchronize(DoOpenFailed)
    else
      DoOpenFailed;
  end;
  // hack end
end;

// create read thread to open stream of the input file
function TCustomPlayer.stream_open(const filename: TPathFileName;
  iformat: PAVInputFormat; APaused, AWait: Boolean): Boolean;
  procedure FreeVideoState;
  var
    ivs: PVideoState;
  begin
    ivs := FVideoState;
    if Assigned(ivs) then
    begin
      //stream_close(ivs);
      FVideoState := nil;
      FVideoStateCB := nil;
      av_free(ivs);
      //SDL_Quit;
    end;
  end;
var
  ivs: PVideoState;
begin
  FreeVideoState; // hack: ensure to free the current ivs
  Result := False;

  // malloc VideoState
  ivs := av_mallocz(SizeOf(TVideoState));
  if not Assigned(ivs) then
  begin
    DoErrLog('av_mallocz() failed.', True);
    Exit;
  end;

  ivs.Owner := Self; // hack: set VideoState's owner

{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
  ivs.yuv01 := Fyuv01;
  ivs.yuv45 := Fyuv45;
{$IFEND}

  // hack: open paused
  if APaused then
  begin
    ivs.paused := 1;
    ivs.open_paused := 1;
    ivs.step := 0;
  end;
  // hack end

  // copy filename and format
  //av_strlcpy(ivs.filename, filename, SizeOf(ivs.filename));
  if Length(filename) > 0 then
    Move(filename[1], ivs.filename[0], Length(filename) * SizeOf({$IFDEF FPC}Char{$ELSE}WideChar{$ENDIF}));
  ivs.iformat := iformat;

  // TODO: remove?
  ivs.ytop := 0;
  ivs.xleft := 0;

  (* start video display *)
  // mutex for video
  ivs.pictq_mutex := SDL_CreateMutex();
  ivs.pictq_cond := SDL_CreateCond();

  // mutex for subtitle
  ivs.subpq_mutex := SDL_CreateMutex();
  ivs.subpq_cond := SDL_CreateCond();

  packet_queue_init(@ivs.videoq);
  packet_queue_init(@ivs.audioq);
  packet_queue_init(@ivs.subtitleq);

  ivs.continue_read_thread := SDL_CreateCond();

  init_clock(@ivs.vidclk, @ivs.videoq.serial);
  init_clock(@ivs.audclk, @ivs.audioq.serial);
  init_clock(@ivs.extclk, @ivs.extclk.serial);
  ivs.audio_clock_serial := -1;
  ivs.audio_last_serial := -1;

  // sync mode
  ivs.av_sync_type := _Tav_sync_type(Fav_sync_type);
  ivs.extclk.speed := FPlaybackSpeed; // hack

  // hack
  ivs.wait_for_stream_opened := Ord(AWait);
  ivs.open_in_caller_thread := Ord(FOpenInCallerThread);
  if FOpenInCallerThread then
  begin
    if do_open_stream(ivs) < 0 then
    begin
      DoReleaseResourceOnFailed(ivs);
      Exit;
    end;
  end;
  // hack end

  // create read thread
  ivs.read_tid := SDL_CreateThread({$IFDEF FPC}@{$ENDIF}read_thread, ivs);

  if not Assigned(ivs.read_tid) then
  begin
    // create thread failed
    DoErrLog('SDL_CreateThread() failed.', True);
    DoReleaseResourceOnFailed(ivs); // hack: release resource
  end
  else if AWait then
  begin
    // hack: wait while opening file
    while ivs.FileOpened = 0 do
    begin
      if GetCurrentThreadID = MainThreadID then
      begin
        CheckSynchronize;
        MyProcessMessages;
      end;
      Sleep(10);
    end;
    // hack end

    // hack: open OK or failed
    if ivs.FileOpened > 0 then
    begin // open file OK
      FVideoState := ivs;
      Result := True;
    end
    else
    begin // open file failed
      while ivs.FileOpened = -1 do
      begin
        if GetCurrentThreadID = MainThreadID then
        begin
          CheckSynchronize;
          MyProcessMessages;
        end;
        Sleep(10);
      end;
      DoReleaseResourceOnFailed(ivs);
    end;
    // hack end
  end
  else
    Result := True;
end;

procedure TCustomPlayer.DoReleaseResourceOnFailed(ivs: PVideoState);
begin
  // hack: ensure to release resource
  packet_queue_destroy(@ivs.videoq);
  packet_queue_destroy(@ivs.audioq);
  packet_queue_destroy(@ivs.subtitleq);
  SDL_DestroyMutex(ivs.pictq_mutex);
  SDL_DestroyCond(ivs.pictq_cond);
  SDL_DestroyMutex(ivs.subpq_mutex);
  SDL_DestroyCond(ivs.subpq_cond);
  SDL_DestroyCond(ivs.continue_read_thread);
  // hack end
  av_free(ivs);
end;

// cycle stream channel
procedure TCustomPlayer.stream_cycle_channel(ivs: PVideoState; codec_type: TAVMediaType);
var
  start_index, stream_index: Integer;
  old_index: Integer;
  st: PAVStream;
  p: PAVProgram;
  nb_streams: Integer;
label
  the_end;
begin
  p := nil;
  nb_streams := ivs.ic.nb_streams;
  if codec_type = AVMEDIA_TYPE_VIDEO then
  begin
    start_index := ivs.last_video_stream;
    old_index := ivs.video_stream;
  end
  else if codec_type = AVMEDIA_TYPE_AUDIO then
  begin
    start_index := ivs.last_audio_stream;
    old_index := ivs.audio_stream;
  end
  else
  begin
    start_index := ivs.last_subtitle_stream;
    old_index := ivs.subtitle_stream;
  end;
  stream_index := start_index;

  if (codec_type <> AVMEDIA_TYPE_VIDEO) and (ivs.video_stream <> -1) then
  begin
    p := av_find_program_from_stream(ivs.ic, nil, ivs.video_stream);
    if Assigned(p) then
    begin
      nb_streams := p.nb_stream_indexes;
      start_index := 0;
      while start_index < nb_streams do
        if Integer(PPtrIdx(p.stream_index, start_index)) = stream_index then
          Break;
      if start_index = nb_streams then
        start_index := -1;
      stream_index := start_index;
    end;
  end;

  while True do
  begin
    Inc(stream_index);
    if stream_index >= nb_streams then
    begin
      if codec_type = AVMEDIA_TYPE_SUBTITLE then
      begin
        stream_index := -1;
        ivs.last_subtitle_stream := -1;
        goto the_end;
      end;
      if start_index = -1 then
        Exit;
      stream_index := 0;
    end;
    if stream_index = start_index then
      Exit;
    if Assigned(p) then
      st := PPtrIdx(ivs.ic.streams, PPtrIdx(p.stream_index, stream_index))
    else
      st := PPtrIdx(ivs.ic.streams, stream_index);
    if st.codec.codec_type = codec_type then
    begin
      (* check that parameters are OK *)
      case codec_type of
        AVMEDIA_TYPE_AUDIO:
          if (st.codec.sample_rate <> 0) and (st.codec.channels <> 0) then
            goto the_end;
        AVMEDIA_TYPE_VIDEO,
        AVMEDIA_TYPE_SUBTITLE:
          goto the_end;
      end;
    end;
  end;
the_end:
  if Assigned(p) and (stream_index <> -1) then
    stream_index := PPtrIdx(p.stream_index, stream_index);
  stream_component_close(ivs, old_index);
  stream_component_open(ivs, stream_index);
end;

// change stream channel
function TCustomPlayer.stream_change_channel(ivs: PVideoState; codec_type: TAVMediaType; stream_index: Integer): Boolean;
var
  old_index: Integer;
  st: PAVStream;
label
  the_end;
begin
  Result := False;

  // old stream index
  if codec_type = AVMEDIA_TYPE_VIDEO then
    old_index := ivs.video_stream
  else if codec_type = AVMEDIA_TYPE_AUDIO then
    old_index := ivs.audio_stream
  else
    old_index := ivs.subtitle_stream;

  // check old stream index
  if old_index < 0 - Ord(codec_type = AVMEDIA_TYPE_SUBTITLE) then
  begin
    DoErrLog('the current stream is invalid.', True);
    Exit;
  end;

  // check new stream index
  if (stream_index < 0 - Ord(codec_type = AVMEDIA_TYPE_SUBTITLE)) or
    (stream_index >= Integer(ivs.ic.nb_streams)) then
  begin
    DoErrLog('the stream index is invalid.', True);
    Exit;
  end;

  // stream not changed
  if stream_index = old_index then
  begin
    Result := True;
    Exit;
  end;

  if stream_index < 0 then
  begin
    Assert(codec_type = AVMEDIA_TYPE_SUBTITLE);
    // disable subtitle
    stream_index := -1;
    goto the_end;
  end;

  // check media type
  st := PPtrIdx(ivs.ic.streams, stream_index);
  if st.codec.codec_type <> codec_type then
  begin
    DoErrLog('the stream type is not matched.', True);
    Exit;
  end;

  (* check that parameters are OK *)
  case codec_type of
    AVMEDIA_TYPE_AUDIO:
      if (st.codec.sample_rate <> 0) and (st.codec.channels <> 0) then
        goto the_end
      else
      begin
        DoErrLog('the audio stream is invalid.', True);
        Exit;
      end;
    AVMEDIA_TYPE_VIDEO,
    AVMEDIA_TYPE_SUBTITLE:
      goto the_end;
  else
    DoErrLog('the stream type is invalid.', True);
    Exit;
  end;

the_end:
  stream_component_close(ivs, old_index);
  stream_component_open(ivs, stream_index);
  Result := True;
end;

(*
static void toggle_full_screen(VideoState *is)
{
#if defined(__APPLE__) && SDL_VERSION_ATLEAST(1, 2, 14)
    /* OS X needs to reallocate the SDL overlays */
    int i;
    for (i = 0; i < VIDEO_PICTURE_QUEUE_SIZE; i++)
        is->pictq[i].reallocate = 1;
#endif
    is_full_screen = !is_full_screen;
    video_open(is, 1, NULL);
}

static void toggle_audio_display(VideoState *is)
{
    int bgcolor = SDL_MapRGB(screen->format, 0x00, 0x00, 0x00);
    int next = is->show_mode;
    do {
        next = (next + 1) % SHOW_MODE_NB;
    } while (next != is->show_mode && (next == SHOW_MODE_VIDEO && !is->video_st || next != SHOW_MODE_VIDEO && !is->audio_st));
    if (is->show_mode != next) {
        fill_rectangle(screen,
                    is->xleft, is->ytop, is->width, is->height,
                    bgcolor, 1);
        is->force_refresh = 1;
        is->show_mode = next;
    }
}
*)

procedure TCustomPlayer.refresh_loop_wait_event(ivs: PVideoState; event: PSDL_Event);
var
  remaining_time: Double;
begin
  remaining_time := 0.0;
  SDL_PumpEvents();
  while SDL_PeepEvents(event, 1, SDL_GETEVENT, SDL_ALLEVENTS) = 0 do
  begin
    if remaining_time > 0.0 then
      av_usleep(Round(remaining_time * 1000000.0));
    remaining_time := REFRESH_RATE;
    if (ivs.show_mode <> SHOW_MODE_NONE) and ((ivs.paused = 0) or (ivs.force_refresh <> 0) or
      (ivs.seek_paused <> 0) or (ivs.open_paused <> 0)) then  // hack
    begin
      LockData;
      try
        video_refresh(ivs, @remaining_time);
      finally
        UnlockData;
      end;
    end;
    SDL_PumpEvents();
  end;
end;

(* handle an event sent by the GUI *)
procedure TCustomPlayer.event_loop;
var
  dummy: array[0..21] of Byte; // Thank Charlie Wolfe for this suggestion
  event: TSDL_Event;
  ivs: PVideoState;
  w: Integer;
begin
  dummy[0] := 0; // stop compiler warning
  FLooping := True;
  while True do
  begin
    refresh_loop_wait_event(FVideoState, @event);

    LockData;
    try
      ivs := FVideoState;
      if not Assigned(ivs) then
      begin
        do_exit;
        Break;
      end;

      case event.type_ of
        SDL_VIDEOEXPOSE: // Screen needs to be redrawn
          ivs.force_refresh := 1;

        SDL_VIDEORESIZE: // User resized video mode
          begin
            //UpdateScreenPosition;
            if event.resize.w > 16383 then
              w := 16383
            else
              w := event.resize.w;
            FUpdateRectLock.Acquire;    // hack
            try
              Fscreen := SDL_SetVideoMode(w, event.resize.h, 0,
                                  SDL_HWSURFACE or SDL_RESIZABLE or SDL_ASYNCBLIT or SDL_HWACCEL);
            finally
              FUpdateRectLock.Release;  // hack
            end;
            if not Assigned(Fscreen) then
            begin
              FFLogger.Log(Self, llFatal, 'Failed to set video mode');
              do_exit;
              Break;
            end;
            Fscreen_width := Fscreen.w;
            Fscreen_height := Fscreen.h;
            ivs.width := Fscreen.w;
            ivs.height := Fscreen.h;
{$IFDEF NEED_KEY}
            if Round(Now * 24 * 60) mod 3 = 0 then
              _CK5(FLic);
{$ENDIF}
            ivs.no_background := 0; // hack: fill background
            ivs.force_refresh := 1;
          end;

        // hack: aspect processing
        FF_ASPECT_EVENT:
          ivs.force_refresh := 1;
        // hack end

        SDL_QUITEV, // User-requested quit
        FF_QUIT_EVENT:
          begin
            do_exit;
            Break;
          end;

        FF_ALLOC_EVENT:
          alloc_picture(ivs);
      end;
    finally
      UnlockData;
    end;
  end;
end;

{ TPlayThread }

constructor TPlayThread.Create(AOwner: TCustomPlayer);
begin
  inherited Create(False);
  Self.FreeOnTerminate := True;
  FOwner := AOwner;
end;

procedure TPlayThread.Execute;
begin
  FOwner.FStopEvent.ResetEvent;
  try
{$IFDEF NEED_IDE}
    if not PHPF{INIDE2} then
  {$IFDEF NEED_YUV}
      FOwner.FVideoState.yuv23 := 1;
  {$ELSE}
      Exit;
  {$ENDIF}
{$ENDIF}
    FOwner.DoState(psPlay); // start to play
    try
      FOwner.event_loop;   // main loop
    except on E: Exception do
      begin
        FFLogger.Log(FOwner, llFatal, 'PlayThread Exception: ' + E.Message);
        FOwner.do_exit;
      end;
    end;
    FOwner.DoState(psStop); // playing stoped
  finally
    FOwner.FStopEvent.SetEvent;
  end;
end;

{ TEventThread }

constructor TEventThread.Create(AOwner: TCustomPlayer);
begin
  inherited Create(False);
  FOwner := AOwner;
end;

procedure TEventThread.Execute;
var
  LEvent: TEventItem;
  LStop: Boolean;
begin
  LStop := False;
  while not Terminated do
    with FOwner do
    begin
      PopupEvent(@LEvent);

      case LEvent.EventType of
        etPosition:
          begin
            FEventPTS := LEvent.Position;
            if FTriggerEventInMainThread then
              MySynchronize(CallDoPosition)
            else
              CallDoPosition;
          end;
        etState:
          begin
            FEventState := LEvent.State;
            if FTriggerEventInMainThread then
              MySynchronize(CallDoState)
            else
              CallDoState;
            if LEvent.State = psStop then
            begin
              LStop := True;
              Break;
            end;
          end;
        etStop:
            Break;
      end;
      //FPlayEvent.Event.WaitFor(INFINITE);
      while FPlayEvent.Event.WaitFor(100) = wrTimeout do
        if Terminated then
          Break;
    end;
  if not LStop then
    with FOwner do
    begin
      FEventState := psStop;
      if FTriggerEventInMainThread then
        MySynchronize(CallDoState)
      else
        CallDoState;
    end;
  Terminate;
end;

{ TCustomPlayer }

constructor TCustomPlayer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FObjectInstance := MakeObjectInstance(WndProc);
  FHijackWndProc := True;
  FHijackCursor := True;
  FScreenWndProc := nil;
  FSDLWndProc := nil;
  FSDLLoader := TSDLLoader.Create;
  FAutoLoadSDL := True;
  FUpdateRectLock := TCriticalSection.Create;
  FDisplayRectLock := TCriticalSection.Create;
  FOptions := TFFOptions.Create;

{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
  Fyuv45 := 1;
{$IFEND}
  FDecoder := TFFDecoder.Create(nil);
  FDecoder.ParentKey(Self);

  Fis_full_screen := False;
  Faudio_disable := False;
  Fvideo_disable := False;
  Fsubtitle_disable := False;
  Fdisplay_disable := False;
  Fdefault_width := 640;
  Fdefault_height := 480;
  Fscreen_width := 0;
  Fscreen_height := 0;
  FAspectRatio := 0;
  FAudioVolume := SDL_MIX_MAXVOLUME;
  FShowMode := smNone;
  FMute := False;
  FTriggerEventInMainThread := True;
  FAudioDriver := adDefault;
  FVideoDriver := vdDefault;
  FCheckIOEOF := True;
  FCheckIOERR := True;
  FNegativeOneAsEOF := True;
  Fdeinterlace := False;

  FDataLock := TMutex.Create();
  FSeekEvent := TEvent.Create(nil, True, True, '');
  FPictEvent := TEvent.Create(nil, True, True, '');
  FStopEvent := TEvent.Create(nil, True, True, '');
  FPlayEvent.Lock := TMutex.Create();
  FPlayEvent.Event := TEvent.Create(nil, True, False, '');
  FEventThread := nil;

  FAudioHook := False;
  FRGBConverter := TFormatConverter.Create;
  FHookConverter := TFormatConverter.Create;
  FVideoHook := False;
  FFrameHook := False;

  // init
  Fvfilters := '';
  Fafilters := '';

  (* options specified by the user *)
  Ffile_iformat := nil;
  Finput_filename := '';
//  Fshow_status := 0;
  Fav_sync_type := stAudio;
  FOpenInCallerThread := True;
  FPlaybackSpeed := 1.0;
  FEnableAudioSpeed := True;
  Fworkaround_bugs := 1;
  Ffast := False;
  Fgenpts := False;
  Flowres := 0;
  Ferror_concealment := 3;
  Fdecoder_reorder_pts := -1;
  Fframedrop := -1;
  Finfinite_buffer := -1;
  Frdftspeed := 0.02;
  FBackColorR := 0;
  FBackColorG := 0;
  FBackColorB := 0;
  FWaveColorR := $FF;
  FWaveColorG := $FF;
  FWaveColorB := $FF;

  Fsws_flags := SWS_BICUBIC;
  FLoading := False;
  FUseAudioPosition := False;
  ResetFlags;
end;

destructor TCustomPlayer.Destroy;
begin
  Self.OnPosition := nil;
  Self.OnState := nil;
  Self.OnAudioHook := nil;
  Self.OnVideoHook := nil;
  Self.OnFrameHook := nil;
  Stop(True);
  ClearEvents;
  if Assigned(FEventThread) then
  begin
    FEventThread.Terminate;
    FEventThread.Free;
    FEventThread := nil;
  end;
  FOptions.Free;
  FreeAndNil(FDecoder);
  FRGBConverter.Free;
  FHookConverter.Free;
  FSeekEvent.Free;
  FPictEvent.Free;
  FStopEvent.Free;
  FPlayEvent.Lock.Free;
  FPlayEvent.Event.Free;
  FDataLock.Free;
  FreeObjectInstance(FObjectInstance);
  FSDLLoader.Free;
  FDisplayRectLock.Free;
  FUpdateRectLock.Free;
  inherited Destroy;
end;

procedure TCustomPlayer.SetLicenseKey(const AKey: AnsiString);
begin
{$IFDEF NEED_KEY}
  FLicKey := AKey;
  FKey := LoadKey(FLicKey, FLic);
{$ENDIF}
end;

procedure TCustomPlayer.ResetFlags;
begin
  Fscreen := nil;
  FState := psStop;
  FLastPTS := AV_NOPTS_VALUE;
  FCurrentPTS := -1;
  FillChar(Fwanted_stream[AVMEDIA_TYPE_UNKNOWN], SizeOf(Fwanted_stream), $FF);
  Fseek_by_bytes := -1;
  FFrameWidth := 0;
  FFrameHeight := 0;
  if not FLoading then
  begin
    Ffile_iformat := nil;
    Fstart_time := AV_NOPTS_VALUE;
    FPlayTime := AV_NOPTS_VALUE;
    FRepeatType := rtRewind;
    FVerticalFlip := False;
    Faudio_codec_name := '';
    Fvideo_codec_name := '';
    Fsubtitle_codec_name := '';
    if FFLoader.Loaded(CPlayerLibraries) then
      FOptions.init_opts;
  end;
  FSeekEvent.SetEvent;
  FSeeking := False;
  // TODO 1: more flags?
end;

function TCustomPlayer.LockData(AWaitTime: DWORD): TWaitResult;
begin
  Result := FDataLock.WaitFor(AWaitTime);
end;

procedure TCustomPlayer.UnlockData;
begin
  FDataLock.Release;
end;

// popup event
procedure TCustomPlayer.PopupEvent(AEvent: PEventItem);
begin
  with FPlayEvent do
  begin
    Lock.WaitFor(INFINITE);
    try
      // if event queue not empty
      if Header <> Tailer then
      begin
        // copy header event content
        AEvent^ := Events[Header];
        FillChar(Events[Header], SizeOf(Events[Header]), 0);
        // drop header event
        if Header = High(Events) then
          Header := 0
        else
          Inc(Header);
      end
      else
        // return etNone event
        AEvent.EventType := etNone;

      // if queue empty then reset event
      if Header = Tailer then
        Event.ResetEvent;
    finally
      Lock.Release;
    end;
  end;
end;

function TailerIndex(ATailer, AHigh: Integer): Integer; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  //(ATailer - 1 + AHigh + 1) mod (AHigh + 1)
  Result := (ATailer + AHigh) mod (AHigh + 1);
end;

// push event
procedure TCustomPlayer.PushEvent(AEvent: PEventItem);
begin
  with FPlayEvent do
  begin
    Lock.WaitFor(INFINITE);
    try
      // if queue empty, or new event type
      if (Header = Tailer) or (Events[TailerIndex(Tailer, High(Events))].EventType <> AEvent.EventType) then
      begin
        // appand event to event queue
        if Tailer = High(Events) then
          Tailer := 0
        else
          Inc(Tailer);
        // if event queue full
        if Header = Tailer then
        begin
          // drop header event
          if Header = High(Events) then
            Header := 0
          else
            Inc(Header);
        end;
      end;
      // save tailer event content
      Events[TailerIndex(Tailer, High(Events))] := AEvent^;
      // new event available
      Event.SetEvent;
    finally
      Lock.Release;
    end;
  end;
end;

procedure TCustomPlayer.ClearEvents;
begin
  with FPlayEvent do
  begin
    Lock.WaitFor(INFINITE);
    try
      Header := 0;
      Tailer := 0;
      FillChar(Events[0], SizeOf(Events), 0);
      Event.SetEvent;
    finally
      Lock.Release;
    end;
  end;
end;

function TCustomPlayer.opt_default(const opt, arg: string): Boolean;
begin
  // check libav
  if not FFLoader.Loaded(CPlayerLibraries) then
  begin
    DoErrLog('FFmpeg libraries not loaded.', True);
    Result := False;
    Exit;
  end;
  Result := FOptions.opt_default(opt, arg) = 0;
  if not Result then
    FLastErrMsg := GOptionError;
end;

function TCustomPlayer.DefaultOptions(AOptions: AnsiString): Boolean;
  function parse_options(argc: Integer; argv: PPAnsiChar): Boolean;
  var
    opt: PAnsiChar;
    optindex: Integer;
  begin
    Result := True;
    (* perform system-dependent conversions for arguments list *)
    //prepare_app_arguments(&argc, &argv);

    (* parse options *)
    optindex := 0;
    while optindex < argc do
    begin
      opt := PPtrIdx(argv, optindex);
      Inc(optindex);
      if (opt^ = '-') and ((opt + 1)^ <> #0) then
      begin
        Inc(opt);
        if not opt_default(string(opt), string(PPtrIdx(argv, optindex))) then
          Result := False;
        Inc(optindex);
      end
      else
        av_log(nil, AV_LOG_ERROR, 'Invalid option found while parsing options, ignore'#10);
    end;
  end;

var
  p: PAnsiChar;
  cmdstart: PAnsiChar;
  numargs, numchars: Integer;
  argc: Integer;
  argv: PPAnsiChar;
begin
  if AOptions = '' then
  begin
    Result := True;
    Exit;
  end;
  FFLogger.Log(Self, llInfo, 'ParseOptions: ' + string(AOptions));
  cmdstart := PAnsiChar(AOptions);
  (* first find out how much space is needed to store args *)
  parse_cmdline(cmdstart, nil, nil, @numargs, @numchars);
  (* allocate space for argv[] vector and strings *)
  GetMem(p, numargs * SizeOf(PAnsiChar) + numchars * SizeOf(AnsiChar));
  (* store args and argv ptrs in just allocated block *)
  parse_cmdline(cmdstart, PPAnsiChar(p), p + numargs * SizeOf(PAnsiChar), @numargs, @numchars);
  (* set argv and argc *)
  argc := numargs - 1;
  argv := PPAnsiChar(p);
  try
    Result := parse_options(argc, argv);
  finally
    FreeMem(p);
  end;
end;

function  TCustomPlayer.AVLibLoaded: Boolean;
begin
  Result := FFLoader.Loaded(CPlayerLibraries) and (not FAutoLoadSDL or FSDLLoader.Loaded);
end;

function  TCustomPlayer.LoadAVLib(const APath: TPathFileName; AAutoLoadSDL: Boolean): Boolean;
begin
  if not (csDesigning in ComponentState) then
  begin
    FFLoader.LibraryPath := APath;
    Result := FFLoader.Load(CPlayerLibraries);
    if not Result then
      FLastErrMsg := FFLoader.LastErrMsg
    else
    begin
      FOptions.init_opts;
      FAutoLoadSDL := AAutoLoadSDL;
      if AAutoLoadSDL then
        Result := LoadSDLLib(APath);
      FFLoader.Load(libSoundTouch);
    end;
  end
  else
    Result := True;
end;

procedure TCustomPlayer.UnloadAVLib;
begin
  FFLoader.Unload(CPlayerLibraries);
  if FAutoLoadSDL then
    FSDLLoader.Unload;
  FFLoader.Unload(libSoundTouch);
end;

function TCustomPlayer.SDLLibLoaded: Boolean;
begin
  Result := FSDLLoader.Loaded;
end;

function TCustomPlayer.LoadSDLLib(const APath, AFile: TPathFileName): Boolean;
begin
  Result := FSDLLoader.Load(APath, AFile);
  if Result then
    SDLFixupStubs
  else
  begin
    SDLUnfixStubs;
    FLastErrMsg := FSDLLoader.LastErrMsg;
  end;
end;

procedure TCustomPlayer.UnloadSDLLib;
begin
  FSDLLoader.Unload;
end;

procedure TCustomPlayer.SDLFixupStubs;
begin
  SDL_Init              := FSDLLoader.SDL_Init;
  SDL_Quit              := FSDLLoader.SDL_Quit;
  SDL_getenv            := FSDLLoader.SDL_getenv;
  SDL_putenv            := FSDLLoader.SDL_putenv;
  SDL_GetError          := FSDLLoader.SDL_GetError;
  SDL_OpenAudio         := FSDLLoader.SDL_OpenAudio;
  SDL_PauseAudio        := FSDLLoader.SDL_PauseAudio;
  SDL_CloseAudio        := FSDLLoader.SDL_CloseAudio;
  SDL_MixAudio          := FSDLLoader.SDL_MixAudio;
  SDL_PumpEvents        := FSDLLoader.SDL_PumpEvents;
  SDL_PeepEvents        := FSDLLoader.SDL_PeepEvents;
  SDL_PushEvent         := FSDLLoader.SDL_PushEvent;
  SDL_EventState        := FSDLLoader.SDL_EventState;
  SDL_GetVideoInfo      := FSDLLoader.SDL_GetVideoInfo;
  SDL_SetVideoMode      := FSDLLoader.SDL_SetVideoMode;
  SDL_UpdateRect        := FSDLLoader.SDL_UpdateRect;
  SDL_WM_SetCaption     := FSDLLoader.SDL_WM_SetCaption;
  SDL_MapRGB            := FSDLLoader.SDL_MapRGB;
  SDL_FillRect          := FSDLLoader.SDL_FillRect;
  SDL_CreateYUVOverlay  := FSDLLoader.SDL_CreateYUVOverlay;
  SDL_LockYUVOverlay    := FSDLLoader.SDL_LockYUVOverlay;
  SDL_UnlockYUVOverlay  := FSDLLoader.SDL_UnlockYUVOverlay;
  SDL_DisplayYUVOverlay := FSDLLoader.SDL_DisplayYUVOverlay;
  SDL_FreeYUVOverlay    := FSDLLoader.SDL_FreeYUVOverlay;
  SDL_CreateMutex       := FSDLLoader.SDL_CreateMutex;
  SDL_LockMutex         := FSDLLoader.SDL_LockMutex;
  SDL_UnlockMutex       := FSDLLoader.SDL_UnlockMutex;
  SDL_DestroyMutex      := FSDLLoader.SDL_DestroyMutex;
  SDL_CreateCond        := FSDLLoader.SDL_CreateCond;
  SDL_DestroyCond       := FSDLLoader.SDL_DestroyCond;
  SDL_CondSignal        := FSDLLoader.SDL_CondSignal;
  SDL_CondWaitTimeout   := FSDLLoader.SDL_CondWaitTimeout;
  SDL_CondWait          := FSDLLoader.SDL_CondWait;
{$IFNDEF FPC}
  SDL_CreateThread      := FSDLLoader.SDL_CreateThread;
  SDL_WaitThread        := FSDLLoader.SDL_WaitThread;
{$ENDIF}
  SDL_AudioDriverName   := FSDLLoader.SDL_AudioDriverName;
  SDL_VideoDriverName   := FSDLLoader.SDL_VideoDriverName;
end;

procedure TCustomPlayer.SDLUnfixStubs;
begin
  @SDL_Init                 := nil;
  @SDL_Quit                 := nil;
  @SDL_getenv               := nil;
  @SDL_putenv               := nil;
  @SDL_GetError             := nil;
  @SDL_OpenAudio            := nil;
  @SDL_PauseAudio           := nil;
  @SDL_CloseAudio           := nil;
  @SDL_MixAudio             := nil;
  @SDL_PumpEvents           := nil;
  @SDL_PeepEvents           := nil;
  @SDL_PushEvent            := nil;
  @SDL_EventState           := nil;
  @SDL_GetVideoInfo         := nil;
  @SDL_SetVideoMode         := nil;
  @SDL_UpdateRect           := nil;
  @SDL_MapRGB               := nil;
  @SDL_FillRect             := nil;
  @SDL_CreateYUVOverlay     := nil;
  @SDL_LockYUVOverlay       := nil;
  @SDL_UnlockYUVOverlay     := nil;
  @SDL_DisplayYUVOverlay    := nil;
  @SDL_FreeYUVOverlay       := nil;
  @SDL_CreateMutex          := nil;
  @SDL_LockMutex            := nil;
  @SDL_UnlockMutex          := nil;
  @SDL_DestroyMutex         := nil;
  @SDL_CreateCond           := nil;
  @SDL_DestroyCond          := nil;
  @SDL_CondSignal           := nil;
  @SDL_CondWaitTimeout      := nil;
  @SDL_CondWait             := nil;
{$IFNDEF FPC}
  @SDL_CreateThread         := nil;
  @SDL_WaitThread           := nil;
{$ENDIF}
  @SDL_AudioDriverName      := nil;
  @SDL_VideoDriverName      := nil;
end;

// hijack wndproc
procedure TCustomPlayer.WndProc(var Message: TMessage);
begin
  with Message do
    case Msg of
      WM_CLOSE: Result := 0; // avoid Alt + F4
      WM_LBUTTONDOWN,
      WM_LBUTTONUP,
      WM_MBUTTONDOWN,
      WM_MBUTTONUP,
      WM_RBUTTONDOWN,
      WM_RBUTTONUP:
        begin
          // set focus to screen control
          SetFocus(HWND(FScreenHandle));
          Result := CallWindowProc(FScreenWndProc, HWND(FScreenHandle), Msg, wParam, lParam);
        end;
      WM_ACTIVATE:
        begin
          CallWindowProc(FSDLWndProc, HWND(FScreenHandle), Msg, wParam, lParam);
          Result := CallWindowProc(FScreenWndProc, HWND(FScreenHandle), Msg, wParam, lParam);
        end;
      WM_SETCURSOR:
        begin
          if FHijackCursor then
            Result := CallWindowProc(FSDLWndProc, HWND(FScreenHandle), Msg, wParam, lParam)
          else
            Result := CallWindowProc(FScreenWndProc, HWND(FScreenHandle), Msg, wParam, lParam);
        end;
      WM_WINDOWPOSCHANGED,
      WM_QUERYNEWPALETTE,
      WM_PALETTECHANGED:
        Result := CallWindowProc(FSDLWndProc, HWND(FScreenHandle), Msg, wParam, lParam);
      WM_PAINT:
        begin
          FUpdateRectLock.Acquire;
          try
            if Assigned(FVideoState) and (FVideoState.paused <> 0) then
            begin
              Result := CallWindowProc(FSDLWndProc, HWND(FScreenHandle), Msg, wParam, lParam);
              CallWindowProc(FSDLWndProc, HWND(FScreenHandle), WM_ERASEBKGND, wParam, lParam);
            end
            else
              Result := CallWindowProc(FSDLWndProc, HWND(FScreenHandle), Msg, wParam, lParam);
          finally
            FUpdateRectLock.Release;
          end;
        end;
      WM_ERASEBKGND:
        begin
          Result := CallWindowProc(FSDLWndProc, HWND(FScreenHandle), Msg, wParam, lParam);
//          Result := CallWindowProc(FScreenWndProc, HWND(FScreenHandle), Msg, wParam, lParam);
        end;
    else
      Result := CallWindowProc(FScreenWndProc, HWND(FScreenHandle), Msg, wParam, lParam);
    end;
end;

// init SDL subsystems
function TCustomPlayer.DoSDLInit(AScreenHandle: HWND): Boolean;
const
  SDL_AUDIODRIVER = 'SDL_AUDIODRIVER';
  SDL_VIDEODRIVER = 'SDL_VIDEODRIVER';
  CAudioDriver: array[TAudioDriver] of PAnsiChar = (nil, 'dsound', 'waveout');
  CVideoDriver: array[TVideoDriver] of PAnsiChar = (nil, 'directx', 'windib');
  dummy_videodriver: PAnsiChar = 'dummy';
  // SDL_WINDOWID: For X11 or Win32, contains the ID number of the window to
  //    be used by SDL instead of creating its own window. Either in decimal
  //    or in hex (prefixed by 0x).
  SDL_WINDOWID = 'SDL_WINDOWID';
var
  LScreenWndProc: TFNWndProc;
  P: array[0..255] of AnsiChar;
  flags: Integer;
begin
  try
    SDL_Quit;
  except
  end;
  // audio driver and video driver
  SetEnvironmentVariableA(SDL_AUDIODRIVER, CAudioDriver[FAudioDriver]);
  if Fdisplay_disable then
    (* For the event queue, we always need a video driver. *)
    SetEnvironmentVariableA(SDL_VIDEODRIVER, dummy_videodriver)
  else
    SetEnvironmentVariableA(SDL_VIDEODRIVER, CVideoDriver[FVideoDriver]);
  if (AScreenHandle > 0) and not Fdisplay_disable then
  begin
    // render video on the custom window
    SetEnvironmentVariableA(SDL_WINDOWID, PAnsiChar(AnsiString(IntToStr(AScreenHandle))));
    // save screen wndproc
    LScreenWndProc := TFNWndProc(GetWindowLong(AScreenHandle, GWL_WNDPROC));
  end
  else
    LScreenWndProc := nil; {stop compiler warning}
  // init SDL subsystems
  flags := SDL_INIT_VIDEO or SDL_INIT_AUDIO or SDL_INIT_TIMER;
  if Faudio_disable then
    flags := flags and not SDL_INIT_AUDIO;
  Result := SDL_Init(flags) = 0;
  if (AScreenHandle > 0) and not Fdisplay_disable then
  begin
    if not Result then
    begin
      // init SDL subsystems again
      my_snprintf(P, 255, 'SDL_WINDOWID=%u', AScreenHandle);
      SDL_putenv(P);
      Result := SDL_Init(flags) = 0;
    end;
    if not Result then
    begin
      // init SDL subsystems again
      my_snprintf(P, 255, 'SDL_WINDOWID=%ld', AScreenHandle);
      SDL_putenv(P);
      Result := SDL_Init(flags) = 0;
    end;
    // clear custom window handle
    SetEnvironmentVariable(SDL_WINDOWID, nil);
  end;
  if Result then
  begin
    // show audio driver
    if SDL_AudioDriverName(P, SizeOf(P)) <> nil then
      FFLogger.Log(Self, llInfo, 'using audio driver: %s', [string(P)]);
    // show video driver
    if SDL_VideoDriverName(P, SizeOf(P)) <> nil then
      FFLogger.Log(Self, llInfo, 'using video driver: %s', [string(P)]);
    if (AScreenHandle > 0) and not Fdisplay_disable then
    begin
      // screen wndproc
      FScreenWndProc := LScreenWndProc;
      FSDLWndProc := TFNWndProc(GetWindowLong(AScreenHandle, GWL_WNDPROC));
      if FHijackWndProc then
        SetWindowLong(AScreenHandle, GWL_WNDPROC, Longint(FObjectInstance));
    end;

    // TODO 0: init SDL event state
    SDL_EventState(SDL_ACTIVEEVENT, SDL_IGNORE);
    SDL_EventState(SDL_MOUSEMOTION, SDL_IGNORE);
    SDL_EventState(SDL_SYSWMEVENT, SDL_IGNORE);
    SDL_EventState(SDL_USEREVENT, SDL_IGNORE);
  end
  else
  begin
{$IFDEF VCL_XE2_OR_ABOVE}
    DoErrLog(System.SysUtils.Format('Could not initialize SDL with ScreenHandle(%u): %s',
{$ELSE}
    DoErrLog(SysUtils.Format('Could not initialize SDL with ScreenHandle(%u): %s',
{$ENDIF}
      [AScreenHandle, SDL_GetError()]), True);
  end;
end;

function TCustomPlayer._TryOpen(const AFileName: TPathFileName;
  AScreenHandle: {$IFDEF BCB}Pointer{$ELSE}HWND{$ENDIF};
  APaused, AWait: Boolean): Boolean;
var
  vi: PSDL_VideoInfo;
begin
  Result := False;

  if FTryOpen then
  begin
    DoErrLog('Current trying open is not completed.', True);
    Exit;
  end;

  // check libav
  if not FFLoader.Loaded(CPlayerLibraries) then
  begin
    DoErrLog('FFmpeg libraries not loaded.', True);
    Exit;
  end;

  // check sdl
  if not SDLLibLoaded then
  begin
    DoErrLog('SDL not loaded.', True);
    Exit;
  end;

  av_opt_get_int(FOptions.sws_opts, 'sws_flags', 0, @Fsws_flags);

{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
  Fyuv01 := 1;
{$IFEND}

{$IFDEF NEED_IDE}
  if not ISDP{INIDE} then
  {$IFDEF NEED_YUV}
    Fyuv01 := 0;
  {$ELSE}
    raise Exception.Create(CDemoOnly);
  {$ENDIF}
  if not PNGF{INIDE1} then
  {$IFDEF NEED_YUV}
    Fyuv01 := 0;
  {$ELSE}
    Exit;
  {$ENDIF}
{$ENDIF}

{$IFDEF NEED_KEY}
  NeedKey(FLicKey);
  if not FKey then
    Exit;
{$ENDIF}

  // stop current playing
  FLoading := True; // indicate to don't reset some flags
  Stop(True);
  FLoading := False;
  FillChar(FDisplayRect, SizeOf(TRect), 0);

  if Assigned(FEventThread) then
  begin
    FEventThread.Terminate;
    FEventThread.Free;
    FEventThread := nil;
  end;
  ClearEvents;
  FLastPTS := AV_NOPTS_VALUE;

  if GetCurrentThreadID = MainThreadID then
  begin
    Sleep(10);
    CheckSynchronize;
    MyProcessMessages;
    Sleep(10);
  end;

{$IFDEF NEED_IDE}
  if not ISDP{INIDE} or not INTD{INIDE5} then
    CheckShowAbout;
{$ELSE}
{$IFDEF NEED_ABOUT}
    CheckShowAbout;
{$ENDIF}
{$ENDIF}

  SDLLock.Acquire;
  try
    if not DoSDLInit(HWND(AScreenHandle)) then
      Exit;
  finally
    SDLLock.Release;
  end;

  // init options
  if Fdisplay_disable then
    Fvideo_disable := True
  else
  begin
    vi := SDL_GetVideoInfo();
    if Assigned(vi) then
    begin
      Ffs_screen_width := vi.current_w;
      Ffs_screen_height := vi.current_h;
    end
    else
    begin
      Ffs_screen_width := 0;
      Ffs_screen_height := 0;
    end;
  end;

  // init flush packet
  av_init_packet(@Fflush_pkt);
  Fflush_pkt.data := PByte(@Fflush_pkt);

  // open stream of the input file
  FTryOpen := True;
  if stream_open(AFileName, Ffile_iformat, APaused, AWait) then
  begin
    Finput_filename := AFileName;
    FScreenHandle := AScreenHandle;
    if AWait then
      DoStreamOpened;
    Result := True;
  end
  else
  begin
    // open file failed
    FTryOpen := False;
    do_exit;
    SDL_Quit;
  end;

  // reset options
  FOptions.init_opts;
end;

procedure TCustomPlayer.DoStreamOpened;
begin
  // open file OK
  FDecoder.FileHandle := FVideoState.ic;

  // particularly used for DirectDraw
  FillChar(FScreenPos, SizeOf(TWindowPos), 0);
{$IFDEF FPC}
  FScreenPos._hwnd := HWND(FScreenHandle);
{$ELSE}
  FScreenPos.hwnd := HWND(FScreenHandle);
{$ENDIF}
  FScreenPos.flags := SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER;

  // do file open event
  if FTriggerEventInMainThread then
    MySynchronize(DoFileOpen)
  else
    DoFileOpen;

{$IFDEF NEED_HASH}
  Randomize;
  if (FVideoState.FileDuration < 0) or (FVideoState.FileDuration > 1000000 * (60 * 5 + Random(60))) then
    StartHash;
{$ENDIF}
{$IFDEF NEED_KEY}
  if Fvfilters <> '' then
    _CK3(FLic)
  else if Length(Finput_filename) > 20 then
    _CK4(FLic);
{$ENDIF}

  // create event thread
  FEventThread := TEventThread.Create(Self);

  // create play thread
  FLooping := False;
  TPlayThread.Create(Self);
  while not FLooping do
    Sleep(10);

{$IFDEF NEED_KEY}
  if FKey then
  begin
    if Round(Now) mod 2 = 0 then
    begin
      if not _CKF(FLic, CFPlayer) then
      begin
        FLicKey := '';
        FKey := False;
      end;
    end
    else
      _CKP(FLic, {$IFDEF ACTIVEX}CPActiveX{$ELSE}CPFFVCL{$ENDIF});
  end;
{$ENDIF}
  FTryOpen := False;
end;

// open the media file to play, render on the custom window specified by handle
function TCustomPlayer.Open(const AFileName: TPathFileName;
  AScreenHandle: {$IFDEF BCB}Pointer{$ELSE}HWND{$ENDIF};
  APaused: Boolean): Boolean;
begin
  Result := _TryOpen(AFileName, AScreenHandle, APaused, True);
end;

procedure TCustomPlayer.TryOpen(const AFileName: TPathFileName;
  AScreenHandle: {$IFDEF BCB}Pointer{$ELSE}HWND{$ENDIF};
  APaused: Boolean);
begin
  _TryOpen(AFileName, AScreenHandle, APaused, False);
end;

// do stop
procedure TCustomPlayer.Stop(AWaitForStop: Boolean);

  procedure WaitForStop;
  var
    LCounter: Integer;
  begin
    LCounter := 1;
    while FStopEvent.WaitFor(100) = wrTimeout do
    begin
      if GetCurrentThreadID = MainThreadID then
      begin
        CheckSynchronize;
        MyProcessMessages;
      end;
      if not Assigned(FVideoState) then
        Break;
      if LockData(100) = wrTimeout then
        Continue;
      Inc(LCounter);
      try
        if not Assigned(FVideoState) then
          Break;

        if (LCounter > 10) and (FVideoState.Reading <> 0) then
        begin
          // maybe av_read_frame() not return
          do_exit;
          Break;
        end;

        if LCounter > 20 then
        begin
          do_exit;
          Break;
        end;

        PushQuitEvent(FVideoState);
      finally
        UnlockData;
      end;
    end;
    FStopEvent.WaitFor(INFINITE);
  end;
begin
  if Assigned(FVideoState) then
  begin
    if FVideoState.paused <> 0 then
      stream_toggle_pause(FVideoState);
    FVideoState.step := 0;

    PushQuitEvent(FVideoState);

    if AWaitForStop then
      WaitForStop;

{$IFDEF NEED_IDE}
    if not INTD{INIDE5} then
  {$IFDEF NEED_YUV}
      Fyuv45 := 0;
  {$ELSE}
      Halt;
  {$ENDIF}
{$ENDIF}
  end
  else
  begin
    FLastRead := 0;
    if Assigned(FVideoStateCB) then
      FVideoStateCB.abort_request := 1;
  end;
end;

// do file open event
procedure TCustomPlayer.DoFileOpen;
var
  w, h: Integer;
  R: TRect;
begin
  if Assigned(FVideoState) and Assigned(FOnFileOpen) then
  begin
    if Assigned(FVideoState.video_st) and (FVideoState.video_st.codec.width > 0) then
    begin
      w := FVideoState.video_st.codec.width;
      h := FVideoState.video_st.codec.height;
    end
    else
    begin
      w := -1;
      h := -1;
    end;

    if FVideoState.IsImage2 <> 0 then
      FOnFileOpen(Self, 0, w, h, Fscreen_width, Fscreen_height)
    else
      FOnFileOpen(Self, FVideoState.FileDuration, w, h, Fscreen_width, Fscreen_height);
  end;
  if (HWND(FScreenHandle) > 0) and ((Fscreen_width = 0) or (Fscreen_height = 0)) then
  begin
    GetClientRect(HWND(FScreenHandle), R);
    Fscreen_width := R.Right - R.Left;
    Fscreen_height := R.Bottom - R.Top;
  end;
  //UpdateScreenPosition;
end;

procedure TCustomPlayer.DoOpenFailed;
begin
  if Assigned(FOnOpenFailed) then
    FOnOpenFailed(Self);
  FTryOpen := False;
end;

procedure TCustomPlayer.UpdateDisplayRect(R: PSDL_Rect);
begin
  if (FDisplayRect.Left <> R.x) or (FDisplayRect.Top <> R.y) or
    (FDisplayRect.Right <> R.x + R.w) or (FDisplayRect.Bottom <> R.y + R.h) then
  begin
    FDisplayRectLock.Acquire;
    try
      FDisplayRect.Left := R.x;
      FDisplayRect.Top := R.y;
      FDisplayRect.Right := R.x + R.w;
      FDisplayRect.Bottom := R.y + R.h;
    finally
      FDisplayRectLock.Release;
    end;
  end;
end;

function TCustomPlayer.DisplayToActualRect(ADisplayRect: TRect): TRect;
var
  T: Integer;
begin
  if not Assigned(FVideoState) then
  begin
    FillChar(Result, SizeOf(TRect), 0);
    Exit;
  end;
  Result := ADisplayRect;
  // adjust top->bottom, left->right
  if Result.Top > Result.Bottom then
  begin
    T := Result.Top;
    Result.Top := Result.Bottom;
    Result.Bottom := T;
  end;
  if Result.Left > Result.Right then
  begin
    T := Result.Left;
    Result.Left := Result.Right;
    Result.Right := T;
  end;
  FDisplayRectLock.Acquire;
  try
    // trim flow
    if Result.Left < FDisplayRect.Left then
      Result.Left := FDisplayRect.Left;
    if Result.Right > FDisplayRect.Right then
      Result.Right := FDisplayRect.Right;
    if Result.Top < FDisplayRect.Top then
      Result.Top := FDisplayRect.Top;
    if Result.Bottom > FDisplayRect.Bottom then
      Result.Bottom := FDisplayRect.Bottom;
    // pan
    Dec(Result.Left, FDisplayRect.Left);
    Dec(Result.Right, FDisplayRect.Left);
    Dec(Result.Top, FDisplayRect.Top);
    Dec(Result.Bottom, FDisplayRect.Top);
    // scale
    if (FDisplayRect.Right > FDisplayRect.Left) and (FFrameWidth > 0) then
    begin
      Result.Left := Result.Left * FFrameWidth div (FDisplayRect.Right - FDisplayRect.Left);
      Result.Right := Result.Right * FFrameWidth div (FDisplayRect.Right - FDisplayRect.Left);
    end;
    if (FDisplayRect.Bottom > FDisplayRect.Top) and (FFrameHeight > 0) then
    begin
      Result.Top := Result.Top * FFrameHeight div (FDisplayRect.Bottom - FDisplayRect.Top);
      Result.Bottom := Result.Bottom * FFrameHeight div (FDisplayRect.Bottom - FDisplayRect.Top);
    end;
  finally
    FDisplayRectLock.Release;
  end;
end;

procedure TCustomPlayer.CallBeforeFindStreamInfo;
begin
  if Assigned(FOnBeforeFindStreamInfo) then
    FOnBeforeFindStreamInfo(Self, FAVFormatContext);
end;

// let SDL update screen position, particularly used for DirectDraw
procedure TCustomPlayer.UpdateScreenPosition;
begin
  if Assigned(FVideoState) and (HWND(FScreenHandle) > 0) and Assigned(FSDLWndProc)
    {and (FVideoDriver = vdDirectDraw)} then
    CallWindowProc(FSDLWndProc, HWND(FScreenHandle),
      WM_WINDOWPOSCHANGED, 0, Integer(@FScreenPos));
end;

// call do position event in main thread
procedure TCustomPlayer.CallDoPosition;
begin
  if Assigned(FOnPosition) then
    FOnPosition(Self, FEventPTS);
end;

// do position event
procedure TCustomPlayer.DoPosition;
var
  clock: Double;
  pts: Int64;
  LEvent: TEventItem;
begin
  if Assigned(FVideoState) and (FVideoState.IsImage2 = 0){ and Assigned(FOnPosition)} then
  begin
    {
    if (get_master_sync_type(FVideoState) = AV_SYNC_EXTERNAL_CLOCK) and (FVideoState.extclk.speed <> 1) then
    begin
      FVideoState.extclk.check_serial := False;
      clock := get_clock(@FVideoState.extclk);
      FVideoState.extclk.check_serial := True;
      if IsNaN(clock) then
        pts := 0
      else
        pts := Round(clock * AV_TIME_BASE) - FVideoState.StartTime;
    end
    else
    }
    if Assigned(FVideoState.video_st) and
      (not Assigned(FVideoState.audio_st) or ((FVideoState.pictq_total_size > 1) and (not FUseAudioPosition or
      ((get_master_sync_type(FVideoState) = AV_SYNC_EXTERNAL_CLOCK) and (FVideoState.extclk.speed <> 1))))) then
    begin
      FVideoState.vidclk.check_serial := False;
      clock := get_clock(@FVideoState.vidclk);
      FVideoState.vidclk.check_serial := True;
      if IsNaN(clock) then
        pts := 0
      else
        pts := Round(clock * AV_TIME_BASE) - FVideoState.StartTime;
    end
    else if Assigned(FVideoState.audio_st) then
    begin
      FVideoState.audclk.check_serial := False;
      clock := get_clock(@FVideoState.audclk);
      FVideoState.audclk.check_serial := True;
      if IsNaN(clock) then
        pts := 0
      else
        pts := Round(clock * AV_TIME_BASE) - FVideoState.StartTime;
      if (FVideoState.AudioDuration > 0) and (pts >= FVideoState.AudioDuration) and (pts < FVideoState.FileDuration) then
        pts := FVideoState.FileDuration;
    end
    else
      Exit;

    FCurrentPTS := pts;

    if (FVideoState.FileDuration > 0) and (pts >= FVideoState.FileDuration) then
    begin
      pts := FVideoState.FileDuration;
      if pts <> FLastPTS then
        FLastPTS := 0;
    end;

    if (FLastPTS = AV_NOPTS_VALUE) or (Abs(pts - FLastPTS) > 20000) then
    begin
      FLastPTS := pts;
      if Assigned(FOnPosition) then
      begin
        LEvent.EventType := etPosition;
        LEvent.Position := pts;
        PushEvent(@LEvent);
      end;
    end;

    with FVideoState^ do
      if (IsDevice = 0) and (EndEventDone = 0) and (ReachEOF <> 0) then
      begin
        if Assigned(video_st) then
          EndEventDone := 1;
        DoState(psEnd);
      end;

    if FPlayTime <> AV_NOPTS_VALUE then
    begin
      if ((Fstart_time <> AV_NOPTS_VALUE) and (pts >= FPlayTime + Fstart_time)) or
        ((Fstart_time = AV_NOPTS_VALUE) and (pts >= FPlayTime)) then
        case FRepeatType of
          rtLoop:
            if Fstart_time <> AV_NOPTS_VALUE then
              Seek(Fstart_time)
            else
              Seek(0, [sfAny]);
          rtPause:
            Pause;
          rtRewind:
            begin
              Pause;
              if Fstart_time <> AV_NOPTS_VALUE then
                Seek(Fstart_time)
              else
                Seek(0, [sfAny]);
            end;
          rtStop: Stop;
        end;
    end;
  end;
end;

{$IFDEF ACTIVEX}
procedure TCustomPlayer.CallAudioHook;
begin
  if FAudioHook and Assigned(FOnAudioHook) and Assigned(FVideoState) then
    with FVideoState.audio_tgt do
      FOnAudioHook(Self, FAudioHookPTS, FAudioHookData, FAudioHookSize, freq, channels);
end;

procedure TCustomPlayer.CallVideoHook;
begin
  if FVideoHook and Assigned(FOnVideoHook) then
    FOnVideoHook(Self, FHookConverter.DIB, FVideoHookPTS, FVideoHookUpdate);
end;

procedure TCustomPlayer.CallFrameHook;
begin
  if FFrameHook and Assigned(FOnFrameHook) then
    FOnFrameHook(Self, FFrameHookPict, AV_PIX_FMT_YUV420P, FFrameHookWidth, FFrameHookHeight, FFrameHookPTS);
end;
{$ENDIF}

// do audio hook event
procedure TCustomPlayer.DoAudioHook(APTS: Double; AData: PByte; ASize: Integer);
begin
  if FAudioHook and Assigned(FOnAudioHook) and Assigned(FVideoState) then
{$IFDEF ACTIVEX}
  begin
    FAudioHookPTS := Round(APTS * AV_TIME_BASE) - FVideoState.StartTime;
    FAudioHookData := AData;
    FAudioHookSize := ASize;
    MySynchronize(CallAudioHook);
  end;
{$ELSE}
    with FVideoState.audio_tgt do
      FOnAudioHook(Self, Round(APTS * AV_TIME_BASE) - FVideoState.StartTime, AData, ASize, freq, channels);
{$ENDIF}
end;

// do video hook event
function TCustomPlayer.DoVideoHook(src_picture, dest_picture: PAVPicture;
  src_pix_fmt, dest_pix_fmt: TAVPixelFormat;
  width, height: Integer; pts: Double): Boolean;
{$IFNDEF ACTIVEX}
var
  LUpdate: Boolean;
{$ENDIF}
begin
  Result := False;
  if not FVideoHook or not Assigned(FOnVideoHook) then
    Exit;

  // convert picture to bitmap
  if not FHookConverter.PictureToRGB(src_picture, src_pix_fmt, width, height{$IFDEF ACTIVEX}, False{$ENDIF}) then
  begin
    FFLogger.Log(Self, llError, FHookConverter.LastErrMsg);
    Exit;
  end;

  // do video hook
  try
{$IFDEF ACTIVEX}
    FVideoHookPTS := Round(pts * AV_TIME_BASE) - FVideoState.StartTime;
    FVideoHookUpdate := True;
    MySynchronize(CallVideoHook);
    if not FVideoHookUpdate then
      Exit;
{$ELSE}
    LUpdate := True;
    FHookConverter.Bitmap.Canvas.Lock;
    try
      // TODO: do we need FTriggerEventInMainThread/MySynchronize?
      FOnVideoHook(Self, FHookConverter.Bitmap, Round(pts * AV_TIME_BASE) - FVideoState.StartTime, LUpdate);
    finally
      FHookConverter.Bitmap.Canvas.Unlock;
    end;
    if not LUpdate then
      Exit;
{$ENDIF}
  except on E: Exception do
    begin
      FFLogger.Log(Self, llError, 'Error occurs OnVideoHook: ' + E.Message);
      Exit;
    end;
  end;

{$IFNDEF ACTIVEX}
  // copy bitmap back to RGB picture
  FHookConverter.BitmapToRGB;
{$ENDIF}

  // transfer RGB picture to dest format
  if not FHookConverter.RGBToPicture(dest_picture, dest_pix_fmt, width, height) then
    FFLogger.Log(Self, llError, FHookConverter.LastErrMsg)
  else
    Result := True;
end;

// do frame hook event
procedure TCustomPlayer.DoFrameHook(pict: PAVPicture; pix_fmt: TAVPixelFormat;
  width, height: Integer; pts: Double);
begin
  if FFrameHook and Assigned(FOnFrameHook) then
    try
{$IFDEF ACTIVEX}
      FFrameHookPict := pict;
      FFrameHookWidth := width;
      FFrameHookHeight := height;
      FFrameHookPTS := Round(pts * AV_TIME_BASE) - FVideoState.StartTime;
      MySynchronize(CallFrameHook);
{$ELSE}
      FOnFrameHook(Self, pict, pix_fmt, width, height, Round(pts * AV_TIME_BASE) - FVideoState.StartTime);
{$ENDIF}
    except on E: Exception do
      FFLogger.Log(Self, llError, 'Error occurs OnFrameHook: ' + E.Message);
    end;
end;

// do log event
procedure TCustomPlayer.DoErrLog(const AErrMsg: string; ASetErrMsg: Boolean);
begin
  FFLogger.Log(Self, llError, AErrMsg);
  if ASetErrMsg then
    FLastErrMsg := AErrMsg;
end;

// call do state event in main thread
procedure TCustomPlayer.CallDoState;
begin
  if Assigned(FOnPlayState) then
    FOnPlayState(Self, FEventState);
end;

// do state event
procedure TCustomPlayer.DoState(APlayState: TPlayState);
var
  LEvent: TEventItem;
begin
  FState := APlayState;
  if Assigned(FOnPlayState) then
  begin
    LEvent.EventType := etState;
    LEvent.State := APlayState;
    PushEvent(@LEvent);
  end
  else if APlayState = psStop then
  begin
    LEvent.EventType := etStop;
    PushEvent(@LEvent);
  end;
{$IFDEF NEED_IDE}
  if APlayState = psEnd then
    if not PHFF{INIDE3} then
  {$IFDEF NEED_YUV}
      FVideoState.yuv23 := 1;
  {$ELSE}
      Halt;
  {$ENDIF}
{$ENDIF}
end;

// do pause
procedure TCustomPlayer.Pause;
begin
  // TODO: do we need lock?
  if Assigned(FVideoState) and (FVideoState.paused = 0) then
  begin
    stream_toggle_pause(FVideoState);
    FVideoState.step := 0;
    DoState(psPause);
{$IFDEF NEED_IDE}
    if not ZQIP{INIDE4} then
  {$IFDEF NEED_YUV}
      FVideoState.yuv45 := 0;
  {$ELSE}
      Halt;
  {$ENDIF}
{$ENDIF}
  end;
end;

// do resume
procedure TCustomPlayer.Resume;
begin
  // TODO: do we need lock?
  if Assigned(FVideoState) and (FVideoState.paused <> 0) then
  begin
{$IFDEF NEED_KEY}
    _CK1(FLic);
{$ENDIF}
    stream_toggle_pause(FVideoState);
    FVideoState.step := 0;
    DoState(psResume);
  end;
end;

// toggle pause
procedure TCustomPlayer.TogglePause;
begin
  if Assigned(FVideoState) then
  begin
{$IFDEF NEED_KEY}
    _CK2(FLic);
{$ENDIF}
    stream_toggle_pause(FVideoState);
    FVideoState.step := 0;
    if FVideoState.paused <> 0 then
      DoState(psPause)
    else
      DoState(psResume);
  end;
end;

// toggle audio display, show audio waves
procedure TCustomPlayer.ToggleAudioDisplay;
begin
  if Assigned(FVideoState) then
    ShowMode := TShowMode((Ord(FVideoState.show_mode) + 1) mod Ord(SHOW_MODE_NB));
end;

// step to next frame
procedure TCustomPlayer.StepToNextFrame;
var
  Lstep: Boolean;
begin
  if Assigned(FVideoState) then
  begin
    // hack: sanity reset status
    FVideoState.open_paused := 0;
    FVideoState.seek_paused := 0;
    // hack end
    (* if the stream is paused, resume it first, then step *)
    if FVideoState.paused <> 0 then
      stream_toggle_pause(FVideoState);
    Lstep := FVideoState.step <> 0;
    FVideoState.step := 1;
    if not Lstep then
      DoState(psStep);
  end;
end;

// do seek by timestamp, microseconds
procedure TCustomPlayer.Seek(const APTS: Int64; ASeekFlags: TSeekFlags; AWaitForSeekEnd: Boolean);
var
  pts: Int64;
begin
  // TODO: do we need lock?
  if Assigned(FVideoState) and (APTS <> AV_NOPTS_VALUE) then
  begin
    if sfByte in ASeekFlags then
      stream_seek(FVideoState, APTS, 0, ASeekFlags, AWaitForSeekEnd)
    else
    begin
      if (APTS > FVideoState.ic.duration) and (FVideoState.ic.duration > 0) then
        pts := FVideoState.ic.duration
      else
        pts := APTS;
      //if (FVideoState.ic.start_time <> AV_NOPTS_VALUE) and (pts < FVideoState.ic.start_time) then
      //  pts := FVideoState.ic.start_time;
      if (FVideoState.ic.start_time <> AV_NOPTS_VALUE) and (FVideoState.ic.start_time <> 0) then
      begin
        pts := FVideoState.ic.start_time + pts;
        if APTS = 0 then
          Dec(pts, Round(FVideoState.frame_delay / 2 * AV_TIME_BASE));
      end;
      stream_seek(FVideoState, pts, 0, ASeekFlags, AWaitForSeekEnd);
    end;
  end;
end;

// do seek by relative value (backward/forward), seconds
procedure TCustomPlayer.Seek(const ADelta: Double; ASeekFlags: TSeekFlags; AWaitForSeekEnd: Boolean);
var
  p, LDelta: Double;
begin
  // TODO: do we need lock?
  if Assigned(FVideoState) then
  begin
    if sfByte in ASeekFlags then
    begin
      if FVideoState.ic.bit_rate <> 0 then
        LDelta := ADelta * FVideoState.ic.bit_rate / 8.0
      else
        LDelta := ADelta * 180000.0;
      p := avio_tell(FVideoState.ic.pb) + LDelta;
      stream_seek(FVideoState, Round(p), Round(LDelta), ASeekFlags, AWaitForSeekEnd);
    end
    else
    begin
      if Assigned(FVideoState.video_st) then
        p := get_clock(@FVideoState.vidclk)
      else
        p := get_master_clock(FVideoState);
      if IsNan(p) then
        p := FVideoState.seek_pos div AV_TIME_BASE;
      p := p + ADelta;
      stream_seek(FVideoState, Round(p * AV_TIME_BASE), Round(ADelta * AV_TIME_BASE), ASeekFlags, AWaitForSeekEnd);
    end;
  end;
end;

// Send a command to one or more filter instances.
function TCustomPlayer.SendFilterCommand(fg: PAVFilterGraph; target, cmd, arg: string; flags: Integer): Boolean;
{$IFDEF CONFIG_AVFILTER}
var
  ret: Integer;
  argv: PAnsiChar;
  response: array[0..4095] of AnsiChar;
{$ENDIF}
begin
{$IFDEF CONFIG_AVFILTER}
  if arg <> '' then
    argv := PAnsiChar(AnsiString(arg))
  else
    argv := nil;
  FFLogger.Log(Self, llVerbose, 'Sending filter command target:%s cmd:%s arg:%s flags:%d', [target, cmd, arg, flags]);
  ret := avfilter_graph_send_command(fg,
    PAnsiChar(AnsiString(target)), PAnsiChar(AnsiString(cmd)), argv, response, SizeOf(response), flags);
  if (ret < 0) or (string(response) <> '') then
    FFLogger.Log(Self, llInfo, 'Command reply: ret:%d response:%s', [ret, string(response)]);
  if ret < 0 then
  begin
    DoErrLog(print_error('avfilter_graph_send_command() failed', ret), True);
    Result := False;
  end
  else
    Result := True;
{$ELSE}
  DoErrLog('filter is not available', True);
  Result := False;
{$ENDIF}
end;

function TCustomPlayer.SendVideoFilterCommand(target, cmd, arg: string; flags: Integer): Boolean;
begin
  // TODO: do we need lock?
  if Assigned(FVideoState) and Assigned(FVideoState.FilterGraph) then
    Result := SendFilterCommand(FVideoState.FilterGraph, target, cmd, arg, flags)
  else
  begin
    DoErrLog('filter is not available', True);
    Result := False;
  end;
end;

function TCustomPlayer.SendAudioFilterCommand(target, cmd, arg: string; flags: Integer): Boolean;
begin
  // TODO: do we need lock?
  if Assigned(FVideoState) and Assigned(FVideoState.agraph) then
    Result := SendFilterCommand(FVideoState.agraph, target, cmd, arg, flags)
  else
  begin
    DoErrLog('filter is not available', True);
    Result := False;
  end;
end;

// Queue a command to one or more filter instances.
function TCustomPlayer.QueueFilterCommand(fg: PAVFilterGraph; target, cmd, arg: string; flags: Integer; pts: Double): Boolean;
{$IFDEF CONFIG_AVFILTER}
var
  ret: Integer;
  argv: PAnsiChar;
{$ENDIF}
begin
{$IFDEF CONFIG_AVFILTER}
  if arg <> '' then
    argv := PAnsiChar(AnsiString(arg))
  else
    argv := nil;
  FFLogger.Log(Self, llVerbose, 'Queueing filter command target:%s cmd:%s arg:%s time:%f flags:%d', [target, cmd, arg, pts, flags]);
  ret := avfilter_graph_queue_command(fg,
    PAnsiChar(AnsiString(target)), PAnsiChar(AnsiString(cmd)), argv, flags, pts);
  if ret < 0 then
  begin
    DoErrLog(print_error('avfilter_graph_queue_command() failed', ret), True);
    Result := False;
  end
  else
    Result := True;
{$ELSE}
  DoErrLog('avfilter is not available', True);
  Result := False;
{$ENDIF}
end;

function TCustomPlayer.QueueVideoFilterCommand(target, cmd, arg: string; flags: Integer; pts: Double): Boolean;
begin
  // TODO: do we need lock?
  if Assigned(FVideoState) and Assigned(FVideoState.FilterGraph) then
    Result := QueueFilterCommand(FVideoState.FilterGraph, target, cmd, arg, flags, pts)
  else
  begin
    DoErrLog('filter is not available', True);
    Result := False;
  end;
end;

function TCustomPlayer.QueueAudioFilterCommand(target, cmd, arg: string; flags: Integer; pts: Double): Boolean;
begin
  // TODO: do we need lock?
  if Assigned(FVideoState) and Assigned(FVideoState.agraph) then
    Result := QueueFilterCommand(FVideoState.agraph, target, cmd, arg, flags, pts)
  else
  begin
    DoErrLog('filter is not available', True);
    Result := False;
  end;
end;

// flush packet queue
procedure TCustomPlayer.FlushQueue;
begin
  if Assigned(FVideoState) then
    FVideoState.flush_req := 1;
end;

// return current frame with bitmap format
function TCustomPlayer.CurrentFrame: {$IFDEF ACTIVEX}PBitmap{$ELSE}TBitmap{$ENDIF};
var
  pts: Int64;
begin
  Result := CurrentFrame(pts);
end;

function TCustomPlayer.CurrentFrame(var APTS: Int64): {$IFDEF ACTIVEX}PBitmap{$ELSE}TBitmap{$ENDIF};
  procedure ZeroBitmap(ABitmap: TBitmap);
  begin
    ABitmap.Width := 0;
    ABitmap.Height := 0;
  end;
  procedure BlackBitmap(ABitmap: TBitmap);
  begin
    if Assigned(FVideoState) and Assigned(FVideoState.video_st) then
    begin
      ABitmap.Width := FVideoState.video_st.codec.width;
      ABitmap.Height := FVideoState.video_st.codec.height;
      ABitmap.Canvas.Lock;
      try
        ABitmap.Canvas.Brush.Color := clBlack;
        ABitmap.Canvas.FillRect(ABitmap.Canvas.ClipRect);
      finally
        ABitmap.Canvas.Unlock;
      end;
    end
    else
      ZeroBitmap(ABitmap);
  end;
var
  vp: PVideoPicture;
  pict: TAVPicture;
begin
{$IFDEF ACTIVEX}
  Result := nil;
{$ELSE}
  BlackBitmap(FRGBConverter.Bitmap);
  Result := FRGBConverter.Bitmap;
{$ENDIF}
  if Assigned(FVideoState) and Assigned(FVideoState.video_st) then
  begin
    vp := @FVideoState.pictq[FVideoState.pictq_cindex];
    APTS := Round(vp.pts * AV_TIME_BASE) - FVideoState.StartTime;
    if Assigned(vp.bmp) then
    begin
      SDL_LockYUVOverlay(vp.bmp);

      pict.data[0] := PByte(vp.bmp.pixels^);
      pict.data[1] := PPtrIdx(vp.bmp.pixels, 2);
      pict.data[2] := PPtrIdx(vp.bmp.pixels, 1);

      pict.linesize[0] := vp.bmp.pitches^;
      pict.linesize[1] := PPtrIdx(vp.bmp.pitches, 2);
      pict.linesize[2] := PPtrIdx(vp.bmp.pitches, 1);

      if FRGBConverter.PictureToRGB(@pict, AV_PIX_FMT_YUV420P, vp.width, vp.height{$IFDEF ACTIVEX},False{$ENDIF}) then
{$IFDEF ACTIVEX}
        Result := FRGBConverter.DIB
{$ENDIF}
      else
{$IFNDEF ACTIVEX}
        ZeroBitmap(FRGBConverter.Bitmap)
{$ENDIF};

      SDL_UnlockYUVOverlay(vp.bmp);
    end;
  end
  else
    APTS := -1;
end;

// return current video stream index
function TCustomPlayer.GetVideoStream: Integer;
begin
  if Assigned(FVideoState) then
    Result := FVideoState.video_stream
  else
    Result := -1;
end;

// get video hook bits pixel
function TCustomPlayer.GetVideoHookBitsPixel: Integer;
begin
  Assert(FRGBConverter.BitsPixel = FHookConverter.BitsPixel);
  Result := FRGBConverter.BitsPixel;
end;

// set video hook bits pixel
procedure TCustomPlayer.SetVideoHookBitsPixel(const Value: Integer);
begin
  FRGBConverter.BitsPixel := Value;
  FHookConverter.BitsPixel := Value;
end;

// set current video stream index
procedure TCustomPlayer.SetVideoStream(const Value: Integer);
begin
  if Assigned(FVideoState) and (Value <> FVideoState.video_stream) then
    stream_change_channel(FVideoState, AVMEDIA_TYPE_VIDEO, Value);
end;

// return current audio stream index
function TCustomPlayer.GetAudioStream: Integer;
begin
  if Assigned(FVideoState) then
    Result := FVideoState.audio_stream
  else
    Result := -1;
end;

// set aspect ratio
procedure TCustomPlayer.SetAspectRatio(const Value: Single);
begin
  if FAspectRatio <> Value then
  begin
    FAspectRatio := Value;
    if Assigned(FVideoState) then
      PushAspectEvent(FVideoState);
  end;
end;

// set current audio stream index
procedure TCustomPlayer.SetAudioStream(const Value: Integer);
begin
  if Assigned(FVideoState) and (Value <> FVideoState.audio_stream) then
    stream_change_channel(FVideoState, AVMEDIA_TYPE_AUDIO, Value);
end;

procedure TCustomPlayer.Setav_sync_type(const Value: Tav_sync_type);
begin
  Fav_sync_type := Value;
  if Assigned(FVideoState) then
  begin
    FVideoState.av_sync_type := _Tav_sync_type(Fav_sync_type);
    FVideoState.av_sync_type_ok := 0;
  end;
end;

procedure TCustomPlayer.SetPlaybackSpeed(const Value: Double);
begin
  FPlaybackSpeed := Value;
  if Assigned(FVideoState) then
    FVideoState.extclk.speed := FPlaybackSpeed;
end;

function TCustomPlayer.GetBackColor: Cardinal;
begin
  Result := FBackColorR or (FBackColorG shl 8) or (FBackColorB shl 16);
end;

procedure TCustomPlayer.SetBackColor(const Value: Cardinal);
begin
  FBackColorR := Byte(Value);
  FBackColorG := Byte(Value shr 8);
  FBackColorB := Byte(Value shr 16);
  if Assigned(FVideoState) then
  begin
    FVideoState.no_background := 0;
    FVideoState.force_refresh := 1;
  end;
end;

function TCustomPlayer.GetWaveColor: Cardinal;
begin
  Result := FWaveColorR or (FWaveColorG shl 8) or (FWaveColorB shl 16);
end;

procedure TCustomPlayer.SetWaveColor(const Value: Cardinal);
begin
  FWaveColorR := Byte(Value);
  FWaveColorG := Byte(Value shr 8);
  FWaveColorB := Byte(Value shr 16);
end;

// return current subtitle stream index
function TCustomPlayer.GetSubtitleStream: Integer;
begin
  if Assigned(FVideoState) then
    Result := FVideoState.subtitle_stream
  else
    Result := -1;
end;

// set current subtitle stream index
procedure TCustomPlayer.SetSubtitleStream(const Value: Integer);
begin
  if Assigned(FVideoState) and (Value <> FVideoState.subtitle_stream) then
    stream_change_channel(FVideoState, AVMEDIA_TYPE_SUBTITLE, Value);
end;

{$IFDEF FPC}
function TCustomPlayer.Get_wanted_stream_audio: Integer;
begin
  Result := Fwanted_stream[TAVMediaType(AVMEDIA_TYPE_AUDIO)];
end;

procedure TCustomPlayer.Set_wanted_stream_audio(const Value: Integer);
begin
  Fwanted_stream[TAVMediaType(AVMEDIA_TYPE_AUDIO)] := Value;
end;

function TCustomPlayer.Get_wanted_stream_video: Integer;
begin
  Result := Fwanted_stream[TAVMediaType(AVMEDIA_TYPE_VIDEO)];
end;

procedure TCustomPlayer.Set_wanted_stream_video(const Value: Integer);
begin
  Fwanted_stream[TAVMediaType(AVMEDIA_TYPE_VIDEO)] := Value;
end;

function TCustomPlayer.Get_wanted_stream_subtitle: Integer;
begin
  Result := Fwanted_stream[TAVMediaType(AVMEDIA_TYPE_SUBTITLE)];
end;

procedure TCustomPlayer.Set_wanted_stream_subtitle(const Value: Integer);
begin
  Fwanted_stream[TAVMediaType(AVMEDIA_TYPE_SUBTITLE)] := Value;
end;
{$ENDIF}

function TCustomPlayer.Get_wanted_stream(const Index: Integer): Integer;
begin
  Result := Fwanted_stream[TAVMediaType(Index)];
end;

procedure TCustomPlayer.Set_wanted_stream(const Index, Value: Integer);
begin
  Fwanted_stream[TAVMediaType(Index)] := Value;
end;

procedure TCustomPlayer.SetShowMode(const Value: TShowMode);
begin
  FShowMode := Value;
  if Assigned(FVideoState) then
  begin
    FVideoState.show_mode := _TShowMode(FShowMode);
    if Assigned(Fscreen) and not Fdisplay_disable then
      with FVideoState^ do
        fill_rectangle(Fscreen, xleft, ytop, width, height,
                       SDL_MapRGB(Fscreen.format, FBackColorR, FBackColorG, FBackColorB), 1);
    FVideoState.force_refresh := 1;
  end;
end;

procedure TCustomPlayer.SetStartTime(const Value: Int64);
begin
  if Fstart_time <> Value then
  begin
    Fstart_time := Value;
    if Value <> AV_NOPTS_VALUE then
      Seek(Value);
  end;
end;

// return format
function TCustomPlayer.GetForceFormat: string;
begin
  if Assigned(Ffile_iformat) then
    Result := string(Ffile_iformat.name)
  else
    Result := '';
end;

// set format
procedure TCustomPlayer.SetForceFormat(const Value: string);
var
  file_iformat: PAVInputFormat;
begin
  if Value = '' then
  begin
    Ffile_iformat := nil;
    Exit;
  end;

  // check libav
  if not FFLoader.Loaded(CPlayerLibraries) then
  begin
    DoErrLog('FFmpeg libraries not loaded.', True);
    Exit;
  end;

  file_iformat := av_find_input_format(PAnsiChar(AnsiString(Value)));
  if not Assigned(file_iformat) then
{$IFDEF ACTIVEX}
  begin
    DoErrLog(Format('Unknown input format: %s', [Value]), True);
    Exit;
  end;
{$ELSE}
    raise Exception.CreateFmt('Unknown input format: %s', [Value]);
{$ENDIF}
  Ffile_iformat := file_iformat;
end;

// get paused
function TCustomPlayer.GetPaused: Boolean;
begin
  if Assigned(FVideoState) and (FVideoState.paused = 0) then
    Result := False
  else
    Result := True;
end;

// get audio and video queue size
function TCustomPlayer.GetQueueSize: Integer;
begin
  if Assigned(FVideoState) then
    Result := FVideoState.audioq.size + FVideoState.videoq.size
  else
    Result := -1;
end;

{
initialization
  GDebuger.Open;
finalization
}

end.
