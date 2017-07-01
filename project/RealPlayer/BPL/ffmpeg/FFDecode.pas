(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is unit of FFDecoder(old name is AVProbe).
 * Created by CodeCoolie@CNSW 2008/07/11 -> $Date:: 2013-11-20 #$
 *)
{
  function Seek(const APTS: Int64; ASeekFlags: TSeekFlags = []): Boolean;
    if sfByte in ASeekFlags then
      APTS: Position in bytes, its bound is 0 to size of the file.
    else
      APTS: Presentation Time Stamp in microsecond, its bound is 0 to
        total duration of the file.
    ASeekFlags: TSeekFlags = set of TSeekFlag
      sfBackward: // seek backward
      sfByte:     // seeking based on position in bytes
      sfAny:      // seek to any frame, even non key-frames

  function Decode(AStreamIndex: Integer = -1): Boolean;
  function DecodeNextKeyFrame(AStreamIndex: Integer = -1): Boolean;
  function DecodePreviousFrame(AStreamIndex: Integer = -1): Boolean;
  function DecodePreviousKeyFrame(AStreamIndex: Integer = -1): Boolean;
    AStreamIndex: special video stream to decode, must be set as video stream's index.
      -1 means using the first video stream.
    if Decode() successfully, use property FrameInfo to get the information.
    NOTICE: after Decode() call, the position will change to next frame.

  function CopyToBitmap(ABitmap: TBitmap): Boolean;
    if Decode() successfully, copy the decoded frame picture to ABtimap.
  function GetBitmapPtr: PBitmap;
    if Decode() successfully, return the pointer of the BITMAP structure which
      defines the type, width, height, color format, and bit values of a bitmap.

  function ReadAudio(ABuffer: PByte; ACount: Integer; AStreamIndex: Integer = -1): Integer;
    ABuffer: copy audio data to this buffer.
    ACount: desire audio data size, it should be not great than the ABuffer size.
    AStreamIndex: special audio stream to decode, must be set as audio stream's index.
      -1 means using the first audio stream.
    Return: the actual audio data size, or -1 on error or EOF.
    NOTICE: if ABuffer is nil, return the audio data size only without reading.
}

unit FFDecode;

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
  {$IFDEF FFFMX}
    {$IFDEF VCL_XE5_OR_ABOVE}
      FMX.Graphics,
    {$ENDIF}
    FMX.Types,
    System.Types,
    System.UITypes,
    {$IFDEF VCL_XE3_OR_ABOVE}
      System.UIConsts, // for claXXX
    {$ENDIF}
  {$ELSE}
    Vcl.Graphics,
  {$ENDIF}
  System.SyncObjs,
{$ELSE}
  Windows,
  SysUtils,
  Classes,
  Graphics,
  SyncObjs,
{$ENDIF}

{$IFDEF BCB}
  BCBTypes,
{$ENDIF}

  FFBaseComponent,
  FFUtils,
  MyUtils,
  CircularBuffer,

{$IFDEF USES_LICKEY}
  LicenseKey,
{$ENDIF}

  libavcodec,
  AVCodecStubs,

  libavformat,
  AVFormatStubs,

  libavutil,
  libavutil_dict,
  libavutil_error,
  libavutil_frame,
  libavutil_log,
  libavutil_pixfmt,
  libavutil_rational,
  libavutil_samplefmt,
  AVUtilStubs,
  libswresample,
  SwResampleStubs,
  libswscale,
  MyUtilStubs;

type

  TFileStreamInfo = record
    StartTime: Int64;
    Duration: Int64;
    BitRate: Integer;
    Year: Integer;
    Track: Integer;
{$IF Defined(BCB)} // C++Builder
    Title: array[0..255] of AnsiChar;
    Author: array[0..255] of AnsiChar;
    Copyright: array[0..255] of AnsiChar;
    Comment: array[0..255] of AnsiChar;
    Album: array[0..255] of AnsiChar;
    Genre: array[0..255] of AnsiChar;
{$ELSE}
    Title: string;
    Author: string;
    Copyright: string;
    Comment: string;
    Album: string;
    Genre: string;
{$IFEND}
  end;

  TAudioStreamInfo = record
{$IF Defined(BCB)} // C++Builder
    Language: array[0..31] of AnsiChar;
    CodecName: array[0..63] of AnsiChar;
{$ELSE}
    Language: string;
    CodecName: string;
{$IFEND}
    StartTime: Int64;
    StartTimeScaled: Int64;
    Duration: Int64;
    DurationScaled: Int64;
    BitRate: Integer;
    Channels: Integer;
    SampleRate: Integer;
    SampleFormat: TAVSampleFormat;
  end;

  TVideoStreamInfo = record
{$IF Defined(BCB)} // C++Builder
    Language: array[0..31] of AnsiChar;
    CodecName: array[0..63] of AnsiChar;
{$ELSE}
    Language: string;
    CodecName: string;
{$IFEND}
    StartTime: Int64;
    StartTimeScaled: Int64;
    Duration: Int64;
    DurationScaled: Int64;
    BitRate: Integer;
    Height: Integer;
    Width: Integer;
    SampleAspectRatio: Single;
    DisplayAspectRatio: Single;
    SAR: TAVRational;
    DAR: TAVRational;
    PixFmt: TAVPixelFormat;
    FrameRate: TAVRational;
  end;

  TSubtitleStreamInfo = record
{$IF Defined(BCB)} // C++Builder
    Language: array[0..31] of AnsiChar;
    CodecName: array[0..63] of AnsiChar;
{$ELSE}
    Language: string;
    CodecName: string;
{$IFEND}
  end;

{$IFDEF NEED_KEY}
  TFFBaseComponentFake = class(TFFBaseComponent);
{$ENDIF}

  TCustomDecoder = class(TFFBaseComponent)
  private
    FFileHandle: PAVFormatContext;
    FOptions: TFFOptions;
    FOwnHandle: Boolean;
    FLastErrMsg: string;
    FForceFormat: string;
    FFileSize: Int64;
    FStreamCount: Integer;
    FProgramCount: Integer;
    FAudioStreamCount: Integer;
    FVideoStreamCount: Integer;
    FSubtitleStreamCount: Integer;
    FFirstAudioStreamIndex: Integer;
    FFirstVideoStreamIndex: Integer;
    FFirstSubtitleStreamIndex: Integer;
    FTriggerEventInMainThread: Boolean;
    FLastRead: Int64;
    FOnBeforeFindStreamInfo: TBeforeFindStreamInfoEvent;

{$IFDEF NEED_KEY}
    FParent: TFFBaseComponentFake;
{$ENDIF}

    procedure CheckLibAV;
    procedure DoErrLog(ALogLevel: Integer; const AErrMsg: string); overload;
    procedure DoErrLog(ALogLevel: Integer; const AErrMsg: string;
      const Args: array of const); overload;
    function GetAudioStreamInfo: TAudioStreamInfo;
    function GetAudioStreamInfos(Index: Integer): TAudioStreamInfo;
    function GetFileInfoText: string;
    function GetFileName: TPathFileName;
    function GetFileStreamInfo: TFileStreamInfo;
    function GetFormatLongName: string;
    function GetFormatName: string;
    function GetSubtitleStreamInfo: TSubtitleStreamInfo;
    function GetSubtitleStreamInfos(Index: Integer): TSubtitleStreamInfo;
    function GetVideoStreamInfo: TVideoStreamInfo;
    function GetVideoStreamInfos(Index: Integer): TVideoStreamInfo;
    function GetProgrames(Index: Integer): TAVProgram;
  protected
    procedure CallBeforeFindStreamInfo;
    procedure RefreshStreamsInfo; virtual;
    procedure SetFileHandle(Value: PAVFormatContext); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetLicenseKey(const AKey: AnsiString);
    procedure ParentKey(AParent: TFFBaseComponent); // internal used only

    function AVLibLoaded: Boolean;
    function LoadAVLib(const APath: TPathFileName): Boolean;
    procedure UnloadAVLib;

    function LoadFile(const AFileName: TPathFileName; const AFormatName: string = ''): Boolean;
    procedure CloseFile; virtual;
    function opt_default(const opt, arg: string): Boolean;
    function DefaultOptions(AOptions: AnsiString): Boolean;

    function IsAudioStream(AStreamIndex: Integer): Boolean;
    function IsVideoStream(AStreamIndex: Integer): Boolean;
    function IsSubtitleStream(AStreamIndex: Integer): Boolean;

    property FileHandle: PAVFormatContext read FFileHandle write SetFileHandle;
    property FileName: TPathFileName read GetFileName;
    property FileSize: Int64 read FFileSize;
    property ForceFormat: string read FForceFormat;
    property FormatName: string read GetFormatName;
    property FormatLongName: string read GetFormatLongName;

    property StreamCount: Integer read FStreamCount;
    property ProgramCount: Integer read FProgramCount;
    property Programs[Index: Integer]: TAVProgram read GetProgrames;

    property AudioStreamCount: Integer read FAudioStreamCount;
    property VideoStreamCount: Integer read FVideoStreamCount;
    property SubtitleStreamCount: Integer read FSubtitleStreamCount;

    property FileStreamInfo: TFileStreamInfo read GetFileStreamInfo;
    property AudioStreamInfos[Index: Integer]: TAudioStreamInfo read GetAudioStreamInfos;
    property VideoStreamInfos[Index: Integer]: TVideoStreamInfo read GetVideoStreamInfos;
    property SubtitleStreamInfos[Index: Integer]: TSubtitleStreamInfo read GetSubtitleStreamInfos;

    property FileInfoText: string read GetFileInfoText;
    property FirstAudioStreamIndex: Integer read FFirstAudioStreamIndex;
    property FirstVideoStreamIndex: Integer read FFirstVideoStreamIndex;
    property FirstSubtitleStreamIndex: Integer read FFirstSubtitleStreamIndex;
    property FirstAudioStreamInfo: TAudioStreamInfo read GetAudioStreamInfo;
    property FirstVideoStreamInfo: TVideoStreamInfo read GetVideoStreamInfo;
    property FirstSubtitleStreamInfo: TSubtitleStreamInfo read GetSubtitleStreamInfo;

    property LastErrMsg: string read FLastErrMsg{$IFDEF ACTIVEX} write FLastErrMsg{$ENDIF};
  published
    property TriggerEventInMainThread: Boolean read FTriggerEventInMainThread
      write FTriggerEventInMainThread default True;
    property OnBeforeFindStreamInfo: TBeforeFindStreamInfoEvent read FOnBeforeFindStreamInfo write FOnBeforeFindStreamInfo;
  end;

  TDecodeType = (dtBoth, dtVideo, dtAudio);
  TDecodeResult = (drVideo, drAudio, drError);

  TFrameInfo = record
    PixFmt: TAVPixelFormat;
    Width: Integer;
    Height: Integer;
    IsKeyFrame: Boolean;
    PictureType: TAVPictureType;
    PTS: Int64;
    OriginalDTS: Int64;
    OriginalPTS: Int64;
    StreamIndex: Integer;
    Position: Int64;
    Ready: Boolean;
    Picture: TAVPicture;
    Buffer: PByte;
    Size: Integer;
  end;

  // for decoding audio
  TWaveInfo = record
    Channels: Integer;
    SampleRate: Integer;
    SampleFormat: TAVSampleFormat;
    BytesPerSample: Integer;
    BytesPerSecond: Integer;
    PTS: Int64;
    OriginalDTS: Int64;
    OriginalPTS: Int64;
    StreamIndex: Integer;
    Ready: Boolean;
    Buffer: PByte;
    Size: Integer;
    Duration: Int64;
  end;

  // internal used only
  PAudioParam = ^TAudioParam;
  TAudioParam = record
    freq: Integer;
    channels: Integer;
    channel_layout: Int64;
    fmt: TAVSampleFormat;
    swr_ctx: PSwrContext;
    st_idx: Integer;
  end;

  TFFDecoder = class(TCustomDecoder)
  private
    FVideoCodec: PAVCodecContext;
    FFormatConv: TFormatConverter;
    FSeekIndex: Integer;
    FDesireVideoIndex: Integer;
    FFrameRate: TAVRational;
    FDeinterlace: Boolean;
    FDeintSize: Integer;
    FDeintBuf: PByte;
    FEOF: Boolean;
    FEOFpkt: Boolean;
    FPicture: TFrameInfo;
    FLastPTS: Int64;

    // for decoding audio
    FWaveInfo: TWaveInfo;
    FDesireAudioChannels: Integer;
    FDesireAudioSampleRate: Integer;
    FDesireAudioSampleFormat: TAVSampleFormat;
    FDesireChannelLayout: Int64;
    FDesireAudioIndex: Integer;
    FAudioCodec: PAVCodecContext;
    FAudioDecodedFrame: TAVFrame;
    FAudioBuffer: PByte;
    FAudioSize: Integer;
    FResampledBuffer: PByte;
    FResampledSize: Integer;
    FAudioParam: TAudioParam;
    FRemainsAudioSize: Integer;

{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
    Fyuv01: Integer;
    Fyuv23: Integer;
    Fyuv45: Integer;
{$IFEND}

    function CheckHandle: Boolean;
    function CanSeek: Boolean;
    function SelectVideoStreamIndex(AStreamIndex: Integer): Integer;
    function OpenVideoDecoder(AStreamIndex: Integer): PAVCodecContext;
    procedure DuplicatePicture(APicture: PAVFrame; APacket: PAVPacket);
    procedure ResetPicture;
    function GetPosition: Int64;
{$IFNDEF FFFMX}
    function GetBitmapBitsPixel: Integer;
    procedure SetBitmapBitsPixel(const Value: Integer);
{$ENDIF}

    // for decoding audio
    function SelectAudioStreamIndex(AStreamIndex: Integer): Integer;
    function OpenAudioDecoder(AStreamIndex: Integer): PAVCodecContext;
    procedure ResetWaveInfo;
    function DoDecodeVideo(ACodec: PAVCodecContext; APacket: PAVPacket): Integer;
    function DoDecodeAudio(AAudioParam: PAudioParam; ACodec: PAVCodecContext; APacket: PAVPacket): Integer;
    procedure CloseAudioResampler(swr_ctx: PPSwrContext); overload;
    procedure CloseAudioResampler; overload; virtual;
    function DoAudioResample(data_offset: Integer; AFrame: PAVFrame; AAudioParam: PAudioParam): Integer;
    procedure SetDesireAudioChannels(const Value: Integer);
    procedure SetDesireAudioSampleFormat(const Value: TAVSampleFormat);
    procedure SetDesireAudioSampleRate(const Value: Integer);
  protected
    procedure RefreshStreamsInfo; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure CloseFile; override;

    function Seek(const APTS: Int64; ASeekFlags: TSeekFlags = []): Boolean; virtual;
    function Decode(AStreamIndex: Integer = -1): Boolean; overload;
    function Decode(AType: TDecodeType): TDecodeResult; overload;
    function DecodeNextKeyFrame(AStreamIndex: Integer = -1): Boolean;
    function DecodePreviousFrame(AStreamIndex: Integer = -1): Boolean;
    function DecodePreviousKeyFrame(AStreamIndex: Integer = -1): Boolean;
    function CopyToBitmap(ABitmap: TBitmap): Boolean;
{$IFDEF MSWINDOWS}
    function GetBitmapPtr: PBitmap;
{$ENDIF}

    function DecodeAudio(AStreamIndex: Integer = -1): Boolean;
    function ReadAudio(ABuffer: PByte; ACount: Integer; AStreamIndex: Integer = -1): Integer;

{$IFNDEF FFFMX}
    // specifies the number of adjacent color bits on each plane needed to define a pixel.
    // one of (8, 15[555, BI_RGB], 16[565, BI_BITFIELDS], 24, 32), default to 32
    property BitmapBitsPixel: Integer read GetBitmapBitsPixel write SetBitmapBitsPixel;
{$ENDIF}
    property Deinterlace: Boolean read FDeinterlace write FDeinterlace;
    property EOF: Boolean read FEOF;
    property FrameInfo: TFrameInfo read FPicture;
    property Position: Int64 read GetPosition;

    property WaveInfo: TWaveInfo read FWaveInfo;
    property DesireAudioChannels: Integer read FDesireAudioChannels write SetDesireAudioChannels;
    property DesireAudioSampleRate: Integer read FDesireAudioSampleRate write SetDesireAudioSampleRate;
    property DesireAudioSampleFormat: TAVSampleFormat read FDesireAudioSampleFormat write SetDesireAudioSampleFormat;
  end;

  TAudioDecoder = class;

  TDecoderThread = class(TThread)
  private
    FDecoder: TAudioDecoder;
  protected
    procedure Execute; override;
  public
    constructor Create(ADecoder: TAudioDecoder);
  end;

  TAudioDecoder = class(TFFDecoder)
  private
    FAudioCodecs: array of PAVCodecContext;
    FAudioParams: array of TAudioParam;
    FThread: TDecoderThread;
    FNoSleep: Boolean;
    FBroken: Boolean;
    FSeekReq: Boolean;
    FSeekPTS: Int64;
    FSeekFlags: TSeekFlags;
    FSeekResult: Boolean;
    FCurrentPTS: Int64;
    FPTSThreshold: Int64;
    FDataSignal: TEvent;
    FSeekSignal: TEvent;
    FBuffer: PByte;
    FBufSize: Integer;
    FBuffers: array of TCircularBuffer;
    procedure CloseAudioResampler; override;
    function OpenAudioDecoder2(AStreamIndex: Integer): PAVCodecContext;
    function DoDecode: Boolean;
    function QuerySize: Integer;
    function WaitData(MinSize: Integer = 1): Integer;
    function DoSeek(ASize: Integer; APTS: Int64): Integer;
    function DurationToBytes(ADuration: Int64): Integer;
    function BytesToDuration(ABytes: Integer): Int64;
  protected
    procedure ExcudeDecode;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure CloseFile; override;

    // ANoSleep: don't call Sleep() while looping in decoding thread
    procedure DoStart(ANoSleep: Boolean = True);
    procedure DoStop;

    function Seek(const APTS: Int64; ASeekFlags: TSeekFlags = []): Boolean; override;
    function DoReadCombined(ABuffer: PByte; ACount: Integer): Integer; overload;
    function DoReadCombined(ABuffer: PByte; ACount: Integer; APTS, ADuration: Int64): Integer; overload;
    function DoReadMixed(ABuffer: PByte; ACount: Integer): Integer; overload;
    function DoReadMixed(ABuffer: PByte; ACount: Integer; APTS, ADuration: Int64): Integer; overload;

    property PTSThreshold: Int64 read FPTSThreshold write FPTSThreshold;
  end;

implementation

uses
  FFLoad,
  FFLog,
  UnicodeProtocol;

{$IFDEF NEED_IDE}
  {$I Z_INIDE.inc}
{$ENDIF}

{$IFDEF ACTIVEX}
  {$I VersionX.inc}
{$ELSE}
  {$I Version.inc}
{$ENDIF}

const
  CFileNotLoaded = 'file not loaded.';

{ TCustomDecoder }

constructor TCustomDecoder.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
{$IFDEF NEED_KEY}
  FParent := TFFBaseComponentFake(Self);
{$ENDIF}
  FFileHandle := nil;
  FOwnHandle := False;
  FTriggerEventInMainThread := True;
  FOptions := TFFOptions.Create;
  RefreshStreamsInfo;
end;

destructor TCustomDecoder.Destroy;
begin
  CloseFile;
  FOptions.Free;
  inherited Destroy;
end;

procedure TCustomDecoder.ParentKey(AParent: TFFBaseComponent);
begin
{$IFDEF NEED_KEY}
  if AParent <> nil then
    FParent := TFFBaseComponentFake(AParent);
{$ENDIF}
end;

procedure TCustomDecoder.SetLicenseKey(const AKey: AnsiString);
begin
{$IFDEF NEED_KEY}
  FParent := TFFBaseComponentFake(Self);
  FLicKey := AKey;
  FKey := LoadKey(FLicKey, FLic);
{$ENDIF}
end;

procedure TCustomDecoder.CallBeforeFindStreamInfo;
begin
  if Assigned(FOnBeforeFindStreamInfo) then
    FOnBeforeFindStreamInfo(Self, FFileHandle);
end;

procedure TCustomDecoder.DoErrLog(ALogLevel: Integer; const AErrMsg: string);
begin
  FLastErrMsg := AErrMsg;
  FFLogger.Log(Self, IntToLogLevel(ALogLevel), FLastErrMsg);
end;

procedure TCustomDecoder.DoErrLog(ALogLevel: Integer; const AErrMsg: string;
  const Args: array of const);
begin
  FLastErrMsg := Format(AErrMsg, Args);
  FFLogger.Log(Self, IntToLogLevel(ALogLevel), FLastErrMsg);
end;

procedure TCustomDecoder.CloseFile;
begin
  FForceFormat := '';
  if Assigned(FFileHandle) then
  begin
    if FOwnHandle then
      avformat_close_input(@FFileHandle);
    FFileHandle := nil;
  end;
  RefreshStreamsInfo;
end;

function TCustomDecoder.opt_default(const opt, arg: string): Boolean;
begin
  // check libav
  if not FFLoader.Loaded(CDecoderLibraries) then
  begin
    DoErrLog(AV_LOG_ERROR, 'FFmpeg libraries not loaded.');
    Result := False;
    Exit;
  end;
  Result := FOptions.opt_default(opt, arg) = 0;
end;

function TCustomDecoder.DefaultOptions(AOptions: AnsiString): Boolean;
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

procedure TCustomDecoder.RefreshStreamsInfo;
var
  I: Integer;
begin
  FFileSize := -1;
  FStreamCount := -1;
  FProgramCount := -1;
  FAudioStreamCount := -1;
  FVideoStreamCount := -1;
  FSubtitleStreamCount := -1;
  FFirstAudioStreamIndex := -1;
  FFirstVideoStreamIndex := -1;
  FFirstSubtitleStreamIndex := -1;
  if Assigned(FFileHandle) then
  begin
    if Assigned(FFileHandle.iformat) and ((FFileHandle.iformat.flags and AVFMT_NOFILE) <> 0) then
      FFileSize := 0
    else
    begin
      FFileSize := avio_size(FFileHandle.pb);
      if FFileSize < 0 then
        FFileSize := 0;
    end;
    if (FFileSize <= 0) and (FileExists(delphi_filename(FFileHandle.filename))) then
      FFileSize := MyUtils.GetFileSize(delphi_filename(FFileHandle.filename));
    FStreamCount := FFileHandle.nb_streams;
    FProgramCount := FFileHandle.nb_programs;
    FAudioStreamCount := 0;
    FVideoStreamCount := 0;
    FSubtitleStreamCount := 0;
    for I := 0 to Integer(FFileHandle.nb_streams) - 1 do
    begin
      case PPtrIdx(FFileHandle.streams, I)^.codec.codec_type of
        AVMEDIA_TYPE_AUDIO:
          begin
            Inc(FAudioStreamCount);
            if FFirstAudioStreamIndex = -1 then
              FFirstAudioStreamIndex := I;
          end;
        AVMEDIA_TYPE_Video:
          begin
            Inc(FVideoStreamCount);
            if FFirstVideoStreamIndex = -1 then
              FFirstVideoStreamIndex := I;
          end;
        AVMEDIA_TYPE_SUBTITLE:
          begin
            Inc(FSubtitleStreamCount);
            if FFirstSubtitleStreamIndex = -1 then
              FFirstSubtitleStreamIndex := I;
          end;
      end;
    end;
  end;
end;

{$IF Defined(BCB)} // C++Builder
procedure MyGetMetaValue(AMeta: PAVDictionary; Buffer: PAnsiChar; Size: Integer; AName: AnsiString);
var
  S: AnsiString;
begin
  FillChar(Buffer^, Size, 0);
  S := AnsiString(GetMetaValue(AMeta, AName));
  if Length(S) < Size then
    StrPCopy(Buffer, S)
  else
    StrPLCopy(Buffer, S, Size - 1);
end;

procedure MyGetCodecName(codec: PAVCodecContext; Buffer: PAnsiChar; Size: Integer);
var
  S: AnsiString;
begin
  FillChar(Buffer^, Size, 0);
  S := AnsiString(GetCodecName(codec));
  if Length(S) < Size then
    StrPCopy(Buffer, S)
  else
    StrPLCopy(Buffer, S, Size - 1);
end;
{$IFEND}

function TCustomDecoder.GetFileStreamInfo: TFileStreamInfo;
begin
  with Result do
    if Assigned(FFileHandle) then
    begin
      StartTime := FFileHandle.start_time;
      if FFileHandle.duration <> AV_NOPTS_VALUE then
        Duration := FFileHandle.duration
      else
        Duration := -1;
      BitRate := FFileHandle.bit_rate;
      Year := StrToIntDef(GetMetaValue(FFileHandle.metadata, 'year'), 0);
      Track := StrToIntDef(GetMetaValue(FFileHandle.metadata, 'track'), 0);
{$IF Defined(BCB)} // C++Builder
      MyGetMetaValue(FFileHandle.metadata, Title, SizeOf(Title), 'title'); {Do not Localize}
      MyGetMetaValue(FFileHandle.metadata, Author, SizeOf(Author), 'author'); {Do not Localize}
      MyGetMetaValue(FFileHandle.metadata, Copyright, SizeOf(Copyright), 'copyright'); {Do not Localize}
      MyGetMetaValue(FFileHandle.metadata, Comment, SizeOf(Comment), 'comment'); {Do not Localize}
      MyGetMetaValue(FFileHandle.metadata, Album, SizeOf(Album), 'album'); {Do not Localize}
      MyGetMetaValue(FFileHandle.metadata, Genre, SizeOf(Genre), 'genre'); {Do not Localize}
{$ELSE}
      Title := GetMetaValue(FFileHandle.metadata, 'title'); {Do not Localize}
      Author := GetMetaValue(FFileHandle.metadata, 'author'); {Do not Localize}
      Copyright := GetMetaValue(FFileHandle.metadata, 'copyright'); {Do not Localize}
      Comment := GetMetaValue(FFileHandle.metadata, 'comment'); {Do not Localize}
      Album := GetMetaValue(FFileHandle.metadata, 'album'); {Do not Localize}
      Genre := GetMetaValue(FFileHandle.metadata, 'genre'); {Do not Localize}
{$IFEND}
    end
    else
    begin
      StartTime := AV_NOPTS_VALUE;
      Duration := -1;
      BitRate := -1;
      Year := -1;
      Track := -1;
      Title := '';
      Author := '';
      Copyright := '';
      Comment := '';
      Album := '';
      Genre := '';
      DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
    end;
end;

function TCustomDecoder.GetAudioStreamInfo: TAudioStreamInfo;
begin
  Result := GetAudioStreamInfos(-1);
end;

function TCustomDecoder.GetAudioStreamInfos(Index: Integer): TAudioStreamInfo;
var
  LCodec: PAVCodecContext;
begin
  with Result do
  begin
    Language := '';
    CodecName := '';
    StartTime := -1;
    StartTimeScaled := -1;
    Duration := -1;
    DurationScaled := -1;
    BitRate := -1;
    Channels := -1;
    SampleRate := -1;
    SampleFormat := AV_SAMPLE_FMT_NONE;
  end;
  if Assigned(FFileHandle) then
  begin
    // check stream index
    if Index < 0 then
    begin // auto choose first audio stream
      Index := FFirstAudioStreamIndex;
      if Index < 0 then
      begin
        DoErrLog(AV_LOG_ERROR, 'no audio stream.');
        Exit;
      end;
    end
    else if Index >= Integer(FFileHandle.nb_streams) then
    begin // stream index is invalid
      DoErrLog(AV_LOG_ERROR, Format('stream index #%d is invalid.', [Index]));
      Exit;
    end;
    LCodec := PPtrIdx(FFileHandle.streams, Index)^.codec;
    if LCodec.codec_type <> AVMEDIA_TYPE_AUDIO then
    begin // stream index is not audio stream
      DoErrLog(AV_LOG_ERROR, Format('stream #%d is not audio stream.', [Index]));
      Exit;
    end;
    with Result do
    begin
{$IF Defined(BCB)} // C++Builder
      MyGetMetaValue(PPtrIdx(FFileHandle.streams, Index)^.metadata, Language, SizeOf(Language), 'language');  {Do not Localize}
      MyGetCodecName(LCodec, CodecName, SizeOf(CodecName));
{$ELSE}
      Language := GetMetaValue(PPtrIdx(FFileHandle.streams, Index)^.metadata, 'language');  {Do not Localize}
      CodecName := GetCodecName(LCodec);
{$IFEND}
      StartTime := PPtrIdx(FFileHandle.streams, Index)^.start_time;
      with PPtrIdx(FFileHandle.streams, Index)^.time_base do
      begin
        if den = 0 then
          den := num;
        if den = 0 then
          den := 1;
      end;
      if StartTime <> AV_NOPTS_VALUE then
        StartTimeScaled := av_rescale_q(StartTime, PPtrIdx(FFileHandle.streams, Index)^.time_base, AV_TIME_BASE_Q);
      Duration := PPtrIdx(FFileHandle.streams, Index)^.duration;
      if Duration <> AV_NOPTS_VALUE then
        DurationScaled := av_rescale_q(Duration, PPtrIdx(FFileHandle.streams, Index)^.time_base, AV_TIME_BASE_Q);
      BitRate := LCodec.bit_rate;
      Channels := LCodec.channels;
      SampleRate := LCodec.sample_rate;
      SampleFormat := LCodec.sample_fmt;
    end;
  end
  else
    DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
end;

function TCustomDecoder.GetVideoStreamInfo: TVideoStreamInfo;
begin
  Result := GetVideoStreamInfos(-1);
end;

function TCustomDecoder.GetVideoStreamInfos(Index: Integer): TVideoStreamInfo;
var
  LCodec: PAVCodecContext;
  st: PAVStream;
begin
  with Result do
  begin
    Language := '';
    CodecName := '';
    StartTime := -1;
    StartTimeScaled := -1;
    Duration := -1;
    DurationScaled := -1;
    BitRate := -1;
    Height := -1;
    Width := -1;
    SampleAspectRatio := -1;
    DisplayAspectRatio := -1;
    SAR.num := 0;
    SAR.den := 1;
    DAR.num := 0;
    DAR.den := 1;
    PixFmt := AV_PIX_FMT_NONE;
    FrameRate.num := 0;
    FrameRate.den := 1;
  end;
  if Assigned(FFileHandle) then
  begin
    // check stream index
    if Index < 0 then
    begin // auto choose first video stream
      Index := FFirstVideoStreamIndex;
      if Index < 0 then
      begin
        DoErrLog(AV_LOG_ERROR, 'no video stream.');
        Exit;
      end;
    end
    else if Index >= Integer(FFileHandle.nb_streams) then
    begin // stream index is invalid
      DoErrLog(AV_LOG_ERROR, Format('stream index #%d is invalid.', [Index]));
      Exit;
    end;
    LCodec := PPtrIdx(FFileHandle.streams, Index)^.codec;
    if LCodec.codec_type <> AVMEDIA_TYPE_VIDEO then
    begin // stream index is not video stream
      DoErrLog(AV_LOG_ERROR, Format('stream #%d is not video stream.', [Index]));
      Exit;
    end;
    with Result do
    begin
{$IF Defined(BCB)} // C++Builder
      MyGetMetaValue(PPtrIdx(FFileHandle.streams, Index)^.metadata, Language, SizeOf(Language), 'language');  {Do not Localize}
      MyGetCodecName(LCodec, CodecName, SizeOf(CodecName));
{$ELSE}
      Language := GetMetaValue(PPtrIdx(FFileHandle.streams, Index)^.metadata, 'language');  {Do not Localize}
      CodecName := GetCodecName(LCodec);
{$IFEND}
      StartTime := PPtrIdx(FFileHandle.streams, Index)^.start_time;
      with PPtrIdx(FFileHandle.streams, Index)^.time_base do
      begin
        if den = 0 then
          den := num;
        if den = 0 then
          den := 1;
      end;
      if StartTime <> AV_NOPTS_VALUE then
        StartTimeScaled := av_rescale_q(StartTime, PPtrIdx(FFileHandle.streams, Index)^.time_base, AV_TIME_BASE_Q);
      Duration := PPtrIdx(FFileHandle.streams, Index)^.duration;
      if Duration <> AV_NOPTS_VALUE then
        DurationScaled := av_rescale_q(Duration, PPtrIdx(FFileHandle.streams, Index)^.time_base, AV_TIME_BASE_Q);
      BitRate := LCodec.bit_rate;
      Height := LCodec.height;
      Width := LCodec.width;
      st := PPtrIdx(FFileHandle.streams, Index);
      if st.sample_aspect_ratio.num <> 0 then
        SAR := st.sample_aspect_ratio
      else
        SAR := LCodec.sample_aspect_ratio;
      SampleAspectRatio := av_q2d(SAR);
      if SAR.num <> 0 then
      begin
        av_reduce(@DAR.num, @DAR.den, LCodec.width * SAR.num, LCodec.height * SAR.den, 1024 * 1024);
        DisplayAspectRatio := av_q2d(DAR);
      end;
      PixFmt := LCodec.pix_fmt;
      if (PPtrIdx(FFileHandle.streams, Index)^.avg_frame_rate.den <> 0) and (PPtrIdx(FFileHandle.streams, Index)^.avg_frame_rate.num <> 0) then
        FrameRate := PPtrIdx(FFileHandle.streams, Index)^.avg_frame_rate
      else
        FrameRate := PPtrIdx(FFileHandle.streams, Index)^.r_frame_rate;
    end;
  end
  else
    DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
end;

function TCustomDecoder.GetSubtitleStreamInfo: TSubtitleStreamInfo;
begin
  Result := GetSubtitleStreamInfos(-1);
end;

function TCustomDecoder.GetSubtitleStreamInfos(Index: Integer): TSubtitleStreamInfo;
var
  LCodec: PAVCodecContext;
begin
  with Result do
  begin
    Language := '';
    CodecName := '';
  end;
  if Assigned(FFileHandle) then
  begin
    // check stream index
    if Index < 0 then
    begin // auto choose first subtitle stream
      Index := FFirstSubtitleStreamIndex;
      if Index < 0 then
      begin
        DoErrLog(AV_LOG_ERROR, 'no subtitle stream.');
        Exit;
      end;
    end
    else if Index >= Integer(FFileHandle.nb_streams) then
    begin // stream index is invalid
      DoErrLog(AV_LOG_ERROR, Format('stream index #%d is invalid.', [Index]));
      Exit;
    end;
    LCodec := PPtrIdx(FFileHandle.streams, Index)^.codec;
    if LCodec.codec_type <> AVMEDIA_TYPE_SUBTITLE then
    begin // stream index is not subtitle stream
      DoErrLog(AV_LOG_ERROR, Format('stream #%d is not subtitle stream.', [Index]));
      Exit;
    end;
    with Result do
    begin
{$IF Defined(BCB)} // C++Builder
      MyGetMetaValue(PPtrIdx(FFileHandle.streams, Index)^.metadata, Language, SizeOf(Language), 'language');  {Do not Localize}
      MyGetCodecName(LCodec, CodecName, SizeOf(CodecName));
{$ELSE}
      Language := GetMetaValue(PPtrIdx(FFileHandle.streams, Index)^.metadata, 'language');  {Do not Localize}
      CodecName := GetCodecName(LCodec);
{$IFEND}
    end;
  end
  else
    DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
end;

function TCustomDecoder.GetProgrames(Index: Integer): TAVProgram;
begin
  with Result do
  begin
    id := -1;
    flags := -1;
    discard := AVDISCARD_NONE;
    stream_index := nil;
    nb_stream_indexes := 0;
  end;
  if Assigned(FFileHandle) then
  begin
    if FFileHandle.nb_programs = 0 then
    begin
      DoErrLog(AV_LOG_ERROR, 'no program found.');
      Exit;
    end;
    // check stream index
    if (Index < 0) or (Index >= Integer(FFileHandle.nb_programs)) then
    begin // stream index is invalid
      DoErrLog(AV_LOG_ERROR, Format('program index #%d is invalid.', [Index]));
      Exit;
    end;
    Result := PPtrIdx(FFileHandle.programs, Index)^;
  end
  else
    DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
end;

(****** TODO: check from libavformat/utils.c print_fps() **************)
function print_fps(d: Double; postfix: string): string;
var
  v: Int64;
begin
  v := Round{lrintf}(d * 100);
  if (v mod 100) <> 0 then
    Result := Format(', %3.2f %s', [d, postfix])
  else if (v mod (100 * 1000)) <> 0 then
    Result := Format(', %1.0f %s', [d, postfix])
  else
    Result := Format(', %1.0fk %s', [d / 1000, postfix]);
end;

(****** TODO: check from libavformat/utils.c dump_metadata() **************)
procedure dump_metadata(SL: TStrings; m: PAVDictionary; const indent: string);
var
  tag: PAVDictionaryEntry;
  p: PAnsiChar;
  tmp: array[0..255] of AnsiChar;
  len, len1: Cardinal;
  S: string;
begin
  if Assigned(m) and not ((av_dict_count(m) = 1) and Assigned(av_dict_get(m, 'language', nil, 0))) then
  begin
    SL.Add(indent + 'Metadata:');
    tag := nil;
    while True do
    begin
      tag := av_dict_get(m, '', tag, AV_DICT_IGNORE_SUFFIX);
      if not Assigned(tag) then
        Break;
      if my_strcmp('language', tag.key) <> 0 then
      begin
        p := tag.value;
        S := Format('%s  %-16s: ', [indent, string(tag.key)]);
        while p^ <> #0 do
        begin
          len := my_strcspn(p, #$8#$a#$b#$c#$d); // "\x8\xa\xb\xc\xd"
          if SizeOf(tmp) < len + 1 then
            len1 := SizeOf(tmp)
          else
            len1 := len + 1;
          av_strlcpy(tmp, p, len1);
          S := S + string(tmp);
          Inc(p, len);
          if p^ = #$d then
            S := S + ' ';
          if p^ = #$a then
          begin
            SL.Add(S);
            S := Format('%s  %-16s: ', [indent, '']);
          end;
          if p^ <> #0 then
            Inc(p);
        end;
        SL.Add(S);
      end;
    end;
  end;
end;

function StartTimeToStr(start_time: Int64; time_base: TAVRational): string;
var
  secs, us: Integer;
begin
  if start_time <> AV_NOPTS_VALUE then
  begin
    if av_cmp_q(time_base, AV_TIME_BASE_Q) <> 0 then
      start_time := av_rescale_q(start_time, time_base, AV_TIME_BASE_Q);
    secs := start_time div AV_TIME_BASE;
    us := Abs(start_time mod AV_TIME_BASE);
    Result := Format('%d.%.6d', [secs, us{av_rescale(us, 1000000, AV_TIME_BASE)}]);
  end
  else
    Result := '';
end;

(****** TODO: check from libavformat/utils.c dump_stream_format() **************)
(* "user interface" functions *)
procedure dump_stream_format(SL: TStrings; ic: PAVFormatContext; i: Integer);
var
  buf: array[0..255] of AnsiChar;
  flags: Integer;
  st: PAVStream;
  g: Integer;
  lang: PAVDictionaryEntry;
  S: string;
  display_aspect_ratio: TAVRational;
begin
  flags := ic.iformat.flags;
  st := PPtrIdx(ic.streams, i);
  g := av_gcd(st.time_base.num, st.time_base.den);
  if g = 0 then // hack
    g := 1;
  lang := av_dict_get(st.metadata, 'language', nil, 0);
  FillChar(buf[0], SizeOf(buf), 0);
  avcodec_string(buf, SizeOf(buf), st.codec, 0);
  S := Format('  Stream #%d', [i]);
  (* the pid is an important information, so we display it *)
  (* XXX: add a generic system *)
  if (flags and AVFMT_SHOW_IDS) <> 0 then
    S := S + LowerCase(Format('[0x%x]', [st.id]));
  if Assigned(lang) then
    S := S + Format('(%s)', [string(lang.value)]);
  //S := S + Format(', %d', [st.codec_info_nb_frames]);
  S := S + Format(', %d/%d', [st.time_base.num div g, st.time_base.den div g]);
  S := S + ': ' + string(buf);
  if (st.sample_aspect_ratio.num <> 0) and // default
     (av_cmp_q(st.sample_aspect_ratio, st.codec.sample_aspect_ratio) <> 0) then
  begin
    av_reduce(@display_aspect_ratio.num, @display_aspect_ratio.den,
              st.codec.width * st.sample_aspect_ratio.num,
              st.codec.height * st.sample_aspect_ratio.den,
              1024 * 1024);
    S := S + Format(', SAR %d:%d DAR %d:%d',
              [st.sample_aspect_ratio.num, st.sample_aspect_ratio.den,
                display_aspect_ratio.num, display_aspect_ratio.den]);
  end;
  // video
  if st.codec.codec_type = AVMEDIA_TYPE_VIDEO then
  begin
    if (st.avg_frame_rate.den <> 0) and (st.avg_frame_rate.num <> 0) then
      S := S + print_fps(av_q2d(st.avg_frame_rate), 'fps');
    if (st.r_frame_rate.den <> 0) and (st.r_frame_rate.num <> 0) then
      S := S + print_fps(av_q2d(st.r_frame_rate), 'tbr');
    if (st.time_base.den <> 0) and (st.time_base.num <> 0) then
      S := S + print_fps(1 /av_q2d(st.time_base), 'tbn');
    if (st.codec.time_base.den <> 0) and (st.codec.time_base.num <> 0) then
      S := S + print_fps(1 / av_q2d(st.codec.time_base), 'tbc');
  end;
  // disposition
  if (st.disposition and AV_DISPOSITION_DEFAULT) <> 0 then
    S := S + ' (default)';
  if (st.disposition and AV_DISPOSITION_DUB) <> 0 then
    S := S + ' (dub)';
  if (st.disposition and AV_DISPOSITION_ORIGINAL) <> 0 then
    S := S + ' (original)';
  if (st.disposition and AV_DISPOSITION_COMMENT) <> 0 then
    S := S + ' (comment)';
  if (st.disposition and AV_DISPOSITION_LYRICS) <> 0 then
    S := S + ' (lyrics)';
  if (st.disposition and AV_DISPOSITION_KARAOKE) <> 0 then
    S := S + ' (karaoke)';
  if (st.disposition and AV_DISPOSITION_FORCED) <> 0 then
    S := S + ' (forced)';
  if (st.disposition and AV_DISPOSITION_HEARING_IMPAIRED) <> 0 then
    S := S + ' (hearing impaired)';
  if (st.disposition and AV_DISPOSITION_VISUAL_IMPAIRED) <> 0 then
    S := S + ' (visual impaired)';
  if (st.disposition and AV_DISPOSITION_CLEAN_EFFECTS) <> 0 then
    S := S + ' (clean effects)';
  // start time
  if st.start_time <> AV_NOPTS_VALUE then
    S := S + ', start: ' + StartTimeToStr(st.start_time, st.time_base);
  // duration
  if st.duration <> AV_NOPTS_VALUE then
    S := S + ', duration: ' + DurationToStr(st.duration, st.time_base);
  SL.Add(S);
  dump_metadata(SL, st.metadata, '  ');
end;

(****** TODO: check from libavformat/utils.c av_dump_format() **************)
procedure DumpFormat(SL: TStrings; ic: PAVFormatContext);
var
  i: Integer;
  printed: array of Boolean;
  S: string;
  ch: PAVChapter;
  j, k, total: Integer;
  name: PAVDictionaryEntry;
  file_size: Int64;
begin
  if ic.nb_streams > 0 then
  begin
    SetLength(printed, ic.nb_streams);
    FillChar(printed[0], Length(printed), 0);
  end
  else
    printed := nil;

  // file name
  SL.Add(Format('File Name: %s', [delphi_filename(ic.filename)]));
  // format name
  SL.Add(Format('Format Name: %s', [ic.iformat.name]));
  // format long name
  if Assigned(ic.iformat.long_name) then
    SL.Add(Format('Format Long Name: %s', [ic.iformat.long_name]));
  (* get the file size, if possible *)
  if Assigned(ic.iformat) and ((ic.iformat.flags and AVFMT_NOFILE) <> 0) then
    file_size := 0
  else
  begin
    file_size := avio_size(ic.pb);
    if file_size < 0 then
      file_size := 0;
  end;
  if (file_size <= 0) and (FileExists(delphi_filename(ic.filename))) then
    S := FileSizeToStr(MyUtils.GetFileSize(delphi_filename(ic.filename)))
  else
    S := FileSizeToStr(file_size);
  SL.Add(Format('File Size: %s', [S]));

  // metadata
  dump_metadata(SL, ic.metadata, '');

  // duration
  S := 'Duration: ' + DurationToStr(ic.duration);
  // start time
  if ic.start_time <> AV_NOPTS_VALUE then
    S := S + ', start: ' + StartTimeToStr(ic.start_time, AV_TIME_BASE_Q);
  // bitrate
  S := S + ', bitrate: ';
  if ic.bit_rate > 0 then
    S := S + Format('%d kb/s', [ic.bit_rate div 1000])
  else
    S := S + 'N/A';

  SL.Add(S);

  // chapters
  for i := 0 to Integer(ic.nb_chapters) - 1 do
  begin
    ch := PPtrIdx(ic.chapters, i);
    S := Format('Chapter #%d: ', [i]);
    S := S + Format('start %.6f, ', [ch.start * av_q2d(ch.time_base)]);
    S := S + Format('end %.6f', [ch.eend * av_q2d(ch.time_base)]);
    SL.Add(S);
    dump_metadata(SL, ch.metadata, '  ');
  end;

  // programs
  if ic.nb_programs <> 0 then
  begin
    total := 0;
    for j := 0 to Integer(ic.nb_programs) - 1 do
    begin
      name := av_dict_get(PPtrIdx(ic.programs, j).metadata, 'name', nil, 0);
      if Assigned(name) then
        S := string(name.value)
      else
        S := '';
      SL.Add(Format('Program %d %s', [PPtrIdx(ic.programs, j).id, S]));
      dump_metadata(SL, PPtrIdx(ic.programs, j).metadata, '  ');
      for k := 0 to Integer(PPtrIdx(ic.programs, j).nb_stream_indexes) - 1 do
      begin
        dump_stream_format(SL, ic, PPtrIdx(PPtrIdx(ic.programs, j).stream_index, k));
        printed[PPtrIdx(PPtrIdx(ic.programs, j).stream_index, k)] := True;
      end;
      Inc(total, PPtrIdx(ic.programs, j).nb_stream_indexes);
    end;
    if total < Integer(ic.nb_streams) then
      SL.Add('No Program');
  end;

  // all other streams
  for i := 0 to Integer(ic.nb_streams) - 1 do
    if not printed[i] then
      dump_stream_format(SL, ic, i);

  SetLength(printed, 0);
end;

function TCustomDecoder.GetFileInfoText: string;
var
  SL: TStringList;
begin
  if Assigned(FFileHandle) then
  begin
    SL := TStringList.Create;
    try
      DumpFormat(SL, FFileHandle);
      Result := SL.Text;
    finally
      SL.Free;
    end;
  end
  else
  begin
    DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
    Result := '';
  end;
end;

function TCustomDecoder.GetFileName: TPathFileName;
begin
  if Assigned(FFileHandle) then
    Result := delphi_filename(FFileHandle.filename)
  else
  begin
    DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
    Result := '';
  end;
end;

function TCustomDecoder.GetFormatLongName: string;
begin
  if Assigned(FFileHandle) then
    Result := string(FFileHandle.iformat.long_name)
  else
  begin
    DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
    Result := '';
  end;
end;

function TCustomDecoder.GetFormatName: string;
begin
  if Assigned(FFileHandle) then
    Result := string(FFileHandle.iformat.name)
  else
  begin
    DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
    Result := '';
  end;
end;

function TCustomDecoder.IsAudioStream(AStreamIndex: Integer): Boolean;
begin
  Result := False;
  if Assigned(FFileHandle) then
  begin
    if (AStreamIndex < 0) or (AStreamIndex >= Integer(FFileHandle.nb_streams)) then
      // stream index is invalid
      DoErrLog(AV_LOG_ERROR, Format('stream index #%d is invalid.', [AStreamIndex]))
    else
      Result := PPtrIdx(FFileHandle.streams, AStreamIndex)^.codec.codec_type = AVMEDIA_TYPE_AUDIO;
  end
  else
    DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
end;

function TCustomDecoder.IsVideoStream(AStreamIndex: Integer): Boolean;
begin
  Result := False;
  if Assigned(FFileHandle) then
  begin
    if (AStreamIndex < 0) or (AStreamIndex >= Integer(FFileHandle.nb_streams)) then
      // stream index is invalid
      DoErrLog(AV_LOG_ERROR, Format('stream index #%d is invalid.', [AStreamIndex]))
    else
      Result := PPtrIdx(FFileHandle.streams, AStreamIndex)^.codec.codec_type = AVMEDIA_TYPE_VIDEO;
  end
  else
    DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
end;

function TCustomDecoder.IsSubtitleStream(AStreamIndex: Integer): Boolean;
begin
  Result := False;
  if Assigned(FFileHandle) then
  begin
    if (AStreamIndex < 0) or (AStreamIndex >= Integer(FFileHandle.nb_streams)) then
      // stream index is invalid
      DoErrLog(AV_LOG_ERROR, Format('stream index #%d is invalid.', [AStreamIndex]))
    else
      Result := PPtrIdx(FFileHandle.streams, AStreamIndex)^.codec.codec_type = AVMEDIA_TYPE_SUBTITLE;
  end
  else
    DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
end;

function read_interrupt_callback(opaque: Pointer): Integer; cdecl;
begin
  //if TObject(opaque) is TCustomDecoder then
    with TObject(opaque) as TCustomDecoder do
    begin
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

function TCustomDecoder.LoadFile(const AFileName: TPathFileName; const AFormatName: string): Boolean;
var
  LInputFormat: PAVInputFormat;
  LRet: Integer;
  t: PAVDictionaryEntry;
  opts: PPAVDictionary;
  orig_nb_streams: Integer;
  I: Integer;
begin
  CheckLibAV;

  Result := False;

{$IFDEF NEED_HASH}
  if Assigned(FFileHandle) then
  begin
    Randomize;
    if (FFileHandle.duration < 0) or (FFileHandle.duration > 1000000 * (60 * 5 + Random(60))) then
      StartHash;
  end;
{$ENDIF}

  CloseFile;

{$IFDEF NEED_IDE}
  if not ISDP{INIDE} or not INTD{INIDE5} then
    CheckShowAbout;
{$ELSE}
{$IFDEF NEED_ABOUT}
    CheckShowAbout;
{$ENDIF}
{$ENDIF}
{$IFDEF NEED_KEY}
  NeedKey(FParent.FLicKey);
  if not FParent.FKey then
    Exit;
{$ENDIF}

  if FOptions.sws_opts = nil then
    FOptions.init_opts;

  // force input format
  if AFormatName <> '' then
  begin
    LInputFormat := av_find_input_format(PAnsiChar(AnsiString(AFormatName)));
    if not Assigned(LInputFormat) then
    begin
      DoErrLog(AV_LOG_ERROR, 'Unknown input format: %s', [AFormatName]);
      FOptions.init_opts;
      CloseFile;
      Exit;
    end;
  end
  else
    LInputFormat := nil;

  FFileHandle := avformat_alloc_context;
  with FFileHandle.interrupt_callback do
  begin
    callback := read_interrupt_callback;
    opaque := Self;
  end;
  FOwnHandle := True;

  FLastRead := av_gettime();
  LRet := avformat_open_input(@FFileHandle, ffmpeg_filename(AFileName), LInputFormat, @FOptions.format_opts);
  if LRet < 0 then
  begin
    // fail to open input file
    FLastErrMsg := print_error(AFileName, LRet);
    FOptions.init_opts;
    CloseFile;
    Exit;
  end;

  t := av_dict_get(FOptions.format_opts, '', nil, AV_DICT_IGNORE_SUFFIX);
  while Assigned(t) do
  begin
    FFLogger.Log(Self, llError, 'Option %s not found, ignored.', [string(t.key)]);
    t := av_dict_get(FOptions.format_opts, '', t, AV_DICT_IGNORE_SUFFIX);
  end;

  FFileHandle.flags := FFileHandle.flags or AVFMT_FLAG_NONBLOCK;
//  FFileHandle.flags := FFileHandle.flags or AVFMT_FLAG_GENPTS;

  if Assigned(FOnBeforeFindStreamInfo) then
  begin
    if FTriggerEventInMainThread then
      MySynchronize(CallBeforeFindStreamInfo)
    else
      CallBeforeFindStreamInfo;
  end;

  //av_dict_set(@FOptions.codec_opts, 'request_channels', '2', 0);

  opts := setup_find_stream_info_opts(FFileHandle, FOptions.codec_opts);
  orig_nb_streams := FFileHandle.nb_streams;

  // try to find stream info of input file
  FLastRead := av_gettime();
  LRet := avformat_find_stream_info(FFileHandle, opts);
  if LRet < 0 then
  begin
    FLastErrMsg := Format('%s: could not find codec parameters', [AFileName]);
    FOptions.init_opts;
    CloseFile;
    Exit;
  end;
  for i := 0 to orig_nb_streams - 1 do
    av_dict_free(PtrIdx(opts, i));
  av_freep(@opts);

  if Assigned(FFileHandle.pb) then
  begin
    FFileHandle.pb.eof_reached := 0;
    FFileHandle.pb.error := 0;
  end;

  RefreshStreamsInfo;

  if Self is TFFDecoder then
  begin
    LRet := av_get_int(FOptions.sws_opts, 'sws_flags', nil);
    if LRet >= 0 then
      (Self as TFFDecoder).FFormatConv.sws_flags := LRet;
  end;

  FOptions.init_opts;

  FForceFormat := AFormatName;

{$IFDEF NEED_HASH}
  if Round(Now * 24 * 60) mod 7 = 0 then
    StartSum;
{$ENDIF}

  Result := True;
{$IFDEF NEED_KEY}
  if FParent.FKey then
    if Round(Now) mod 2 = 0 then
    begin
      if not _CKF(FParent.FLic, CFDecoder) then
      begin
        FParent.FKey := False;
        FParent.FLicKey := '';
      end;
    end
    else
      _CKP(FParent.FLic, {$IFDEF ACTIVEX}CPActiveX{$ELSE}CPFFVCL{$ENDIF});
{$ENDIF}
end;

procedure TCustomDecoder.SetFileHandle(Value: PAVFormatContext);
begin
  if FFileHandle <> Value then
  begin
    CheckLibAV;
    CloseFile;
    FOwnHandle := False;
    FFileHandle := Value;
    RefreshStreamsInfo;
  end;
end;

procedure TCustomDecoder.CheckLibAV;
begin
  FFLoader.CheckLibAV(CDecoderLibraries);
end;

function TCustomDecoder.AVLibLoaded: Boolean;
begin
  Result := FFLoader.Loaded(CDecoderLibraries);
end;

function TCustomDecoder.LoadAVLib(const APath: TPathFileName): Boolean;
begin
  FFLoader.LibraryPath := APath;
  Result := FFLoader.Load(CDecoderLibraries);
  if not Result then
    FLastErrMsg := FFLoader.LastErrMsg
  else
    FOptions.init_opts;
end;

procedure TCustomDecoder.UnloadAVLib;
begin
  FFLoader.Unload(CDecoderLibraries);
end;

{ TFFDecoder }

constructor TFFDecoder.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFormatConv := TFormatConverter.Create;
  FDeinterlace := False;
  FDeintSize := 0;
  FDeintBuf := nil;

  FDesireAudioChannels := 2;
  FDesireAudioSampleRate := 44100;
  FDesireAudioSampleFormat := AV_SAMPLE_FMT_S16;

{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
  Fyuv01 := 1;
  Fyuv45 := 1;
{$IFEND}
end;

destructor TFFDecoder.Destroy;
begin
  if Assigned(FPicture.Buffer) then
  begin
    if Assigned(av_free) then
      av_free(FPicture.Buffer);   // XXX memory leak if LibAV have been unloaded
    FPicture.Buffer := nil;
  end;
  FFormatConv.Free;

  if Assigned(FAudioBuffer) then
  begin
    if Assigned(av_free) then
      av_free(FAudioBuffer);      // XXX memory leak if LibAV have been unloaded
    FAudioBuffer := nil;
  end;
  if Assigned(av_freep) then
    av_freep(@FResampledBuffer);  // XXX memory leak if LibAV have been unloaded
  if Assigned(FDeintBuf) then
  begin
    if Assigned(av_free) then
      av_free(FDeintBuf);         // XXX memory leak if LibAV have been unloaded
    FDeintBuf := nil;
  end;

  inherited Destroy;
end;

procedure TFFDecoder.CloseFile;
begin
  FSeekIndex := -1;
  FDesireVideoIndex := -1;
  FFrameRate.num := 0;
  FFrameRate.den := 0;
  FEOF := False;
  FEOFpkt := False;
  ResetPicture;
  FLastPTS := AV_NOPTS_VALUE;

  FDesireAudioIndex := -1;
  ResetWaveInfo;
  FRemainsAudioSize := 0;

  FAudioParam.channels := -1;
  FAudioParam.freq := -1;
  FAudioParam.fmt := AV_SAMPLE_FMT_NONE;
  FAudioParam.channel_layout := 0;
  FAudioParam.st_idx := -1;
  CloseAudioResampler(@FAudioParam.swr_ctx);

{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
  if not ZQIP{INIDE4} or not INTD{INIDE5} then
    Fyuv45 := 0;
{$IFEND}

  if Assigned(FVideoCodec) then
  begin
    avcodec_close(FVideoCodec);
    FVideoCodec := nil;
  end;

  if Assigned(FAudioCodec) then
  begin
    avcodec_close(FAudioCodec);
    FAudioCodec := nil;
  end;

  inherited CloseFile;
end;

procedure TFFDecoder.RefreshStreamsInfo;
begin
  inherited RefreshStreamsInfo;
{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
  if not ISDP{INIDE} or not PNGF{INIDE1} then
    Fyuv01 := 0;
{$IFEND}
end;

procedure TFFDecoder.ResetPicture;
begin
  with FPicture do
  begin
    if PTS <> AV_NOPTS_VALUE then
      FLastPTS := PTS;
    PixFmt := AV_PIX_FMT_NONE;
    Width := -1;
    Height := -1;
    IsKeyFrame := False;
    PictureType := AV_PICTURE_TYPE_NONE;
    PTS := AV_NOPTS_VALUE;
    OriginalDTS := AV_NOPTS_VALUE;
    OriginalPTS := AV_NOPTS_VALUE;
    StreamIndex := -1;
    Position := -1;
    Ready := False;
  end;
end;

procedure TFFDecoder.ResetWaveInfo;
begin
  with FWaveInfo do
  begin
    Channels := FDesireAudioChannels;
    SampleRate := FDesireAudioSampleRate;
    SampleFormat := FDesireAudioSampleFormat;
    if Assigned(av_get_bytes_per_sample) then
    begin
      BytesPerSample := av_get_bytes_per_sample(FDesireAudioSampleFormat);
      BytesPerSecond := FDesireAudioSampleRate * FDesireAudioChannels * BytesPerSample{ * 1000000 div AV_TIME_BASE};
    end
    else
    begin
      BytesPerSample := 0;
      BytesPerSecond := 0;
    end;
    PTS := AV_NOPTS_VALUE;
    OriginalDTS := AV_NOPTS_VALUE;
    OriginalPTS := AV_NOPTS_VALUE;
    StreamIndex := -1;
    Ready := False;
    Buffer := nil;
    Size := 0;
    Duration := AV_NOPTS_VALUE;
  end;
end;

procedure TFFDecoder.CloseAudioResampler(swr_ctx: PPSwrContext);
begin
  if Assigned(swr_ctx^) then
  begin
    swr_free(swr_ctx);
    swr_ctx^ := nil;
  end;
end;

procedure TFFDecoder.CloseAudioResampler;
begin
  CloseAudioResampler(@FAudioParam.swr_ctx);
end;

function TFFDecoder.GetPosition: Int64;
begin
  if not Assigned(FFileHandle) then
  begin
    DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
    Result := -1;
  end
  else if not Assigned(FFileHandle.pb) then
  begin
    DoErrLog(AV_LOG_WARNING, 'cannot get position');
    Result := -1;
  end
  else
    Result := avio_tell(FFileHandle.pb);
end;

function TFFDecoder.CheckHandle: Boolean;
begin
  if not Assigned(FFileHandle) then
  begin
    DoErrLog(AV_LOG_WARNING, CFileNotLoaded);
    Result := False;
    Exit;
  end
  else if not FOwnHandle then
  begin
    DoErrLog(AV_LOG_WARNING, 'file cannot be seeked, handle is readonly.');
{$IFNDEF ACTIVEX}
    raise Exception.Create(FLastErrMsg);
{$ENDIF}
  end;
  Result := True;
end;

function TFFDecoder.CanSeek: Boolean;
begin
  // check handle
  if not CheckHandle then
  begin
    Result := False;
    Exit;
  end;

  if SameText(string(FFileHandle.iformat.name), 'image2') then {Do not Localize}
  begin
    // "image2" format cannot to be seeked
    DoErrLog(AV_LOG_INFO, '"image2" format cannot to be seeked.');
    Result := False;
    Exit;
  end;

  Result := True;
end;

function TFFDecoder.Seek(const APTS: Int64; ASeekFlags: TSeekFlags): Boolean;
const
  Caller = 'Seek()';
var
  LPTS: Int64;
  LStartTime: Int64;
  LRet: Integer;
begin
  // check to seek
  if not CanSeek then
  begin
    Result := False;
    Exit;
  end;

  if Assigned(FFileHandle.pb) then
    FFLogger.Log(Self, llDebug, '%s.%s: current position %d bytes', [Self.ClassName, Caller, avio_tell(FFileHandle.pb)]);

  LPTS := APTS;
  if (APTS = 0) and (FFrameRate.den <> 0) and IsVideoStream(FSeekIndex) then
    Dec(LPTS, GetFrameInterval(FFrameRate) div 2);

  if not (sfByte in ASeekFlags) then
  begin
    if FSeekIndex >= 0 then
    begin
      // use special stream's time_base rescale the pts timestamp
      LPTS := av_rescale_q(LPTS, AV_TIME_BASE_Q, PPtrIdx(FFileHandle.streams, FSeekIndex)^.time_base);
      LStartTime := PPtrIdx(FFileHandle.streams, FSeekIndex)^.start_time
    end
    else
      LStartTime := FFileHandle.start_time;
    // increment pts timestamp with start_time offset
    if LStartTime <> AV_NOPTS_VALUE then
      Inc(LPTS, LStartTime);
  end;

  // Flush buffers, should be called when seeking or when switching to a different stream.
  if Assigned(FVideoCodec) then
    avcodec_flush_buffers(FVideoCodec);
  if Assigned(FAudioCodec) then
    avcodec_flush_buffers(FAudioCodec);

  // reset flags
  FEOF := False;
  FEOFpkt := False;
  ResetPicture;
  ResetWaveInfo;

  // do seek
  if Assigned(FFileHandle.iformat) and Assigned(FFileHandle.iformat.read_seek2) then
  begin
    LRet := avformat_seek_file(FFileHandle, FSeekIndex, Low(Int64), LPTS, High(Int64), MakeSeekFlags(ASeekFlags));
    if LRet < 0 then
    begin
      // try seek again with or without AVSEEK_FLAG_BACKWARD
      if sfBackward in ASeekFlags then
        LRet := avformat_seek_file(FFileHandle, FSeekIndex, Low(Int64), LPTS, High(Int64), MakeSeekFlags(ASeekFlags - [sfbackward]))
      else
        LRet := avformat_seek_file(FFileHandle, FSeekIndex, Low(Int64), LPTS, High(Int64), MakeSeekFlags(ASeekFlags + [sfbackward]))
    end;
  end
  else
  begin
    LRet := av_seek_frame(FFileHandle, FSeekIndex, LPTS, MakeSeekFlags(ASeekFlags));
    if LRet < 0 then
    begin
      if MakeSeekFlags(ASeekFlags) and AVSEEK_FLAG_BACKWARD = 0 then
        LRet := av_seek_frame(FFileHandle, FSeekIndex, LPTS, MakeSeekFlags(ASeekFlags) or AVSEEK_FLAG_BACKWARD)
      else
        LRet := av_seek_frame(FFileHandle, FSeekIndex, LPTS, MakeSeekFlags(ASeekFlags) and not AVSEEK_FLAG_BACKWARD);
    end;
  end;

  if LRet < 0 then
  begin
    if sfByte in ASeekFlags then
      DoErrLog(AV_LOG_ERROR, Format('%s.%s: could not seek to position %d bytes', [Self.ClassName, Caller, APTS]))
    else
      DoErrLog(AV_LOG_ERROR, Format('%s.%s: could not seek to position %0.3f seconds', [Self.ClassName, Caller, APTS / AV_TIME_BASE]));
    Result := False;
  end
  else
    Result := True;

  if Assigned(FFileHandle.pb) then
    FFLogger.Log(Self, llDebug, '%s.%s: seek to position %d bytes', [Self.ClassName, Caller, avio_tell(FFileHandle.pb)]);

{
  if Assigned(FFileHandle.pb) and (FFileHandle.pb.eof_reached <> 0) then
  begin
    if Result then
      DoErrLog(AV_LOG_INFO, 'stream eof reached.');
    Result := False;
    FEOF := True;
  end;
}
end;

function TFFDecoder.SelectVideoStreamIndex(AStreamIndex: Integer): Integer;
var
  LStreamIndex: Integer;
begin
  // check handle
  if not CheckHandle then
  begin
    Result := -1;
    Exit;
  end;

  // check stream index
  if AStreamIndex < 0 then
  begin
    if FDesireVideoIndex >= 0 then
      // use last stream index
      LStreamIndex := FDesireVideoIndex
    else if FFirstVideoStreamIndex >= 0 then
      // use first video stream
      LStreamIndex := FFirstVideoStreamIndex
    else
    begin
      // no video stream
      DoErrLog(AV_LOG_ERROR, 'no video stream.');
      Result := -1;
      Exit;
    end;
  end
  else if AStreamIndex >= Integer(FFileHandle.nb_streams) then
  begin // stream index is invalid
    DoErrLog(AV_LOG_ERROR, Format('stream index #%d is invalid.', [AStreamIndex]));
    Result := -1;
    Exit;
  end
  else if PPtrIdx(FFileHandle.streams, AStreamIndex)^.codec.codec_type <> AVMEDIA_TYPE_VIDEO then
  begin // stream index is not video stream
    DoErrLog(AV_LOG_ERROR, Format('stream #%d is not video stream.', [AStreamIndex]));
    Result := -1;
    Exit;
  end
  else
    LStreamIndex := AStreamIndex;

  // save last stream index
  if FDesireVideoIndex <> LStreamIndex then
  begin
    ResetPicture;
    with PPtrIdx(FFileHandle.streams, LStreamIndex)^ do
    begin
      if (avg_frame_rate.num <> 0) and (avg_frame_rate.den <> 0) then
        FFrameRate := avg_frame_rate
      else if (codec.time_base.num <> r_frame_rate.den) or (codec.time_base.den <> r_frame_rate.num * codec.ticks_per_frame) then
      begin
        FFLogger.Log(Self, llInfo,
          Format('Seems stream %d codec frame rate differs from container frame rate: %2.2f (%d/%d) -> %2.2f (%d/%d)',
                  [LStreamIndex, codec.time_base.den / codec.time_base.num, codec.time_base.den, codec.time_base.num,
                   r_frame_rate.num / r_frame_rate.den, r_frame_rate.num, r_frame_rate.den]));
        FFrameRate := r_frame_rate;
      end
      else
      begin
        FFrameRate.num := codec.time_base.den;
        FFrameRate.den := codec.time_base.num;
      end;
    end;
  end;
  FDesireVideoIndex := LStreamIndex;
  FSeekIndex := FDesireVideoIndex;
  Result := LStreamIndex;
end;

function TFFDecoder.SelectAudioStreamIndex(AStreamIndex: Integer): Integer;
var
  LStreamIndex: Integer;
begin
  // check handle
  if not CheckHandle then
  begin
    Result := -1;
    Exit;
  end;

  // check stream index
  if AStreamIndex < 0 then
  begin
    if FDesireAudioIndex >= 0 then
      // use last stream index
      LStreamIndex := FDesireAudioIndex
    else if FFirstAudioStreamIndex >= 0 then
      // use first audio stream
      LStreamIndex := FFirstAudioStreamIndex
    else
    begin
      // no audio stream
      DoErrLog(AV_LOG_ERROR, 'no audio stream.');
      Result := -1;
      Exit;
    end;
  end
  else if AStreamIndex >= Integer(FFileHandle.nb_streams) then
  begin // stream index is invalid
    DoErrLog(AV_LOG_ERROR, Format('stream index #%d is invalid.', [AStreamIndex]));
    Result := -1;
    Exit;
  end
  else if PPtrIdx(FFileHandle.streams, AStreamIndex)^.codec.codec_type <> AVMEDIA_TYPE_AUDIO then
  begin // stream index is not audio stream
    DoErrLog(AV_LOG_ERROR, Format('stream #%d is not audio stream.', [AStreamIndex]));
    Result := -1;
    Exit;
  end
  else
    LStreamIndex := AStreamIndex;

  // save last stream index
  if FDesireAudioIndex <> LStreamIndex then
  begin
    ResetWaveInfo;
    CloseAudioResampler(@FAudioParam.swr_ctx);
  end;
  FDesireAudioIndex := LStreamIndex;
  FSeekIndex := FDesireAudioIndex;
  Result := LStreamIndex;
end;

procedure TFFDecoder.SetDesireAudioChannels(const Value: Integer);
begin
  if FDesireAudioChannels <> Value then
  begin
    FDesireAudioChannels := Value;
    FDesireChannelLayout := 0;
    ResetWaveInfo;
    CloseAudioResampler;
  end;
end;

procedure TFFDecoder.SetDesireAudioSampleFormat(const Value: TAVSampleFormat);
begin
  if FDesireAudioSampleFormat <> Value then
  begin
    FDesireAudioSampleFormat := Value;
    ResetWaveInfo;
    CloseAudioResampler;
  end;
end;

procedure TFFDecoder.SetDesireAudioSampleRate(const Value: Integer);
begin
  if FDesireAudioSampleRate <> Value then
  begin
    FDesireAudioSampleRate := Value;
    ResetWaveInfo;
    CloseAudioResampler;
  end;
end;

{$IFNDEF FFFMX}
function TFFDecoder.GetBitmapBitsPixel: Integer;
begin
  Result := FFormatConv.BitsPixel;
end;

procedure TFFDecoder.SetBitmapBitsPixel(const Value: Integer);
begin
  FFormatConv.BitsPixel := Value;
end;
{$ENDIF}

function TFFDecoder.OpenVideoDecoder(AStreamIndex: Integer): PAVCodecContext;
var
  st: PAVStream;
  LCodec: PAVCodecContext;
  LDecoder: PAVCodec;
  opts: PAVDictionary;
begin
  st := PPtrIdx(FFileHandle.streams, AStreamIndex);
  // check frame size of codec
  LCodec := st^.codec;
  Assert(LCodec.codec_type = AVMEDIA_TYPE_VIDEO);
  if (LCodec.width = 0) or (LCodec.height = 0) then
  begin // sanity check
    DoErrLog(AV_LOG_ERROR, 'frame size of codec is invalid.');
    Result := nil;
    Exit;
  end;

  // avoid multithreading issue of log callback in some codecs
  LCodec.thread_count := 1;

  // reuse last decoder
  if LCodec = FVideoCodec then
  begin
    Result := FVideoCodec;
    Exit;
  end;

  // close last decoder
  if Assigned(FVideoCodec) then
  begin
    avcodec_close(FVideoCodec);
    FVideoCodec := nil;
  end;

  // find decoder
  LDecoder := avcodec_find_decoder(LCodec.codec_id);
  if not Assigned(LDecoder) then
  begin // codec not found
    DoErrLog(AV_LOG_ERROR, Format('Unsupported codec (id=%d) for input file stream #%d',
            [Ord(LCodec.codec_id), AStreamIndex]));
    Result := nil;
    Exit;
  end;

  // open decoder
  opts := filter_codec_opts(FOptions.codec_opts, LCodec.codec_id, FFileHandle, st, LDecoder);
  if avcodec_open2(LCodec, LDecoder, @opts) < 0 then
  begin // codec open failed
    DoErrLog(AV_LOG_ERROR, Format('Error while opening codec for input file stream #%d',
            [AStreamIndex]));
    Result := nil;
    Exit;
  end;

  // save last codec
  FVideoCodec := LCodec;
  Result := LCodec;
end;

function TFFDecoder.OpenAudioDecoder(AStreamIndex: Integer): PAVCodecContext;
var
  st: PAVStream;
  LCodec: PAVCodecContext;
  LDecoder: PAVCodec;
  opts: PAVDictionary;
begin
  st := PPtrIdx(FFileHandle.streams, AStreamIndex);
  // check codec
  LCodec := st^.codec;
  Assert(LCodec.codec_type = AVMEDIA_TYPE_AUDIO);

  // reuse last decoder
  if LCodec = FAudioCodec then
  begin
    Result := FAudioCodec;
    Exit;
  end;

  // close last decoder
  if Assigned(FAudioCodec) then
  begin
    avcodec_close(FAudioCodec);
    FAudioCodec := nil;
  end;

  // find decoder
  LDecoder := avcodec_find_decoder(LCodec.codec_id);
  if not Assigned(LDecoder) then
  begin // codec not found
    DoErrLog(AV_LOG_ERROR, Format('Unsupported codec (id=%d) for input file stream #%d',
            [Ord(LCodec.codec_id), AStreamIndex]));
    Result := nil;
    Exit;
  end;

  // open decoder
  opts := filter_codec_opts(FOptions.codec_opts, LCodec.codec_id, FFileHandle, st, LDecoder);
  //LCodec.request_channels := FDesireAudioChannels;
  if avcodec_open2(LCodec, LDecoder, @opts) < 0 then
  begin // codec open failed
    DoErrLog(AV_LOG_ERROR, Format('Error while opening codec for input file stream #%d',
            [AStreamIndex]));
    Result := nil;
    Exit;
  end;

  // save last codec
  FAudioCodec := LCodec;
  Result := LCodec;
end;

procedure TFFDecoder.DuplicatePicture(APicture: PAVFrame; APacket: PAVPacket);
var
  LSize: Integer;
  LPTS: Int64;
  LGuessPTS: Int64;
begin
  // malloc memory for new picture
  LSize := avpicture_get_size(FVideoCodec.pix_fmt, FVideoCodec.width, FVideoCodec.height);
  if LSize > FPicture.Size then
  begin
    if Assigned(FPicture.Buffer) then
      av_free(FPicture.Buffer);
    FPicture.Buffer := av_malloc(LSize);
    FPicture.Size := LSize;
  end;

  // set picture information
  with FPicture do
  begin
    PixFmt := FVideoCodec.pix_fmt;
    Width := FVideoCodec.width;
    Height := FVideoCodec.height;
    IsKeyFrame := APicture.key_frame = 1;
  end;
  // picture type
  FPicture.PictureType := APicture.pict_type;
  // pts rescaled
  if (APacket.dts = AV_NOPTS_VALUE) and (APicture.reordered_opaque <> AV_NOPTS_VALUE) then
    LPTS := APicture.reordered_opaque
  else if APacket.dts <> AV_NOPTS_VALUE then
    LPTS := APacket.dts
  else
    LPTS := APacket.pts;
  if (LPTS = AV_NOPTS_VALUE) and FEOFpkt and (FLastPTS <> AV_NOPTS_VALUE) and (FPicture.PTS <> AV_NOPTS_VALUE) then
    LGuessPTS := FPicture.PTS + FPicture.PTS - FLastPTS
  else
    LGuessPTS := AV_NOPTS_VALUE;
  if FPicture.PTS <> AV_NOPTS_VALUE then
    FLastPTS := FPicture.PTS;
  if LPTS <> AV_NOPTS_VALUE then
  begin
    if PPtrIdx(FFileHandle.streams, FDesireVideoIndex)^.start_time <> AV_NOPTS_VALUE then
      Dec(LPTS, PPtrIdx(FFileHandle.streams, FDesireVideoIndex)^.start_time);
    FPicture.PTS := av_rescale_q(LPTS, PPtrIdx(FFileHandle.streams, FDesireVideoIndex)^.time_base, AV_TIME_BASE_Q);
    FFLogger.Log(Self, llDebug, 'decode PTS: %0.3f', [FPicture.PTS / AV_TIME_BASE]);
  end
  else
    FPicture.PTS := LGuessPTS;
  // original dts and pts
  FPicture.OriginalDTS := APacket.dts;
  FPicture.OriginalPTS := APacket.pts;
  // stream index
  FPicture.StreamIndex := APacket.stream_index;
  // position in file
  FPicture.Position := APacket.pos;

  // copy picture buffer
  with FPicture do
  begin
    avpicture_fill(@Picture, Buffer, PixFmt, Width, Height);
    av_picture_copy(@Picture, PAVPicture(APicture), PixFmt, Width, Height);
{$IFDEF NEED_YUV}
    if PixFmt = AV_PIX_FMT_YUV420P then
  {$IFDEF NEED_IDE}
      if (Fyuv01 <> 1) or (Fyuv23 <> 0) or (Fyuv45 <> 1) then
  {$ENDIF}
      WriteYUV(@Picture, Height);
{$ENDIF}
  end;

  FPicture.Ready := True;
end;

function TFFDecoder.DoDecodeVideo(ACodec: PAVCodecContext; APacket: PAVPacket): Integer;
var
  LPicture: TAVFrame;
  LRet: Integer;
  LGotPicture: Integer;
  LFinalFrame: PAVFrame;
  LDeintFrame: TAVFrame;
  LDeintSize: Integer;
  procedure ASM1;
  asm
    emms; // maybe a bug missing call emms in function avpicture_deinterlace()
  end;
begin
  (* XXX: allocate picture correctly *)
  avcodec_get_frame_defaults(@LPicture);

  // decode video frame
  ACodec.reordered_opaque := APacket.pts;
  LRet := avcodec_decode_video2(ACodec, @LPicture, @LGotPicture, APacket);
  if (LRet < 0) or (LGotPicture = 0) then
  begin
    // decode error, or no picture yet
    if LRet < 0 then
      Result := LRet
    else
      Result := 0;
    Exit;
  end;

{ $DEFINE DEBUG_FRAME_INFO}
{$IFDEF DEBUG_FRAME_INFO}
  FFLogger.Log(Self, llInfo, 'pkt.st_idx=%d, dts=%d, pts=%d, flags=%d, pict_type=%d(%s)',
    [APacket.stream_index, APacket.dts, APacket.pts, APacket.flags, Ord(LPicture.pict_type), AVPictureTypeCaption(LPicture.pict_type)]);
  Result := 0;
{$ELSE}
  FFLogger.Log(Self, llDebug, 'pkt.st_idx=%d, dts=%d, pts=%d, flags=%d, pict_type=%d(%s)',
    [APacket.stream_index, APacket.dts, APacket.pts, APacket.flags, Ord(LPicture.pict_type), AVPictureTypeCaption(LPicture.pict_type)]);

  // deinterlacing support
  if not FDeinterlace then
    LFinalFrame := @LPicture
  else
  begin
    // malloc buffer
    with ACodec^ do
      LDeintSize := avpicture_get_size(pix_fmt, width, height);
    if not Assigned(FDeintBuf) then
    begin
      FDeintBuf := av_malloc(LDeintSize);
      FDeintSize := LDeintSize;
    end
    else if FDeintSize < LDeintSize then
    begin
      av_free(FDeintBuf);
      FDeintBuf := av_malloc(LDeintSize);
      FDeintSize := LDeintSize;
    end;

    if not Assigned(FDeintBuf) then
    begin
      FFLogger.Log(Self, llError, 'deinterlace buffer malloc error.');
      FDeinterlace := False;
      LFinalFrame := @LPicture;
    end
    else
    begin
      // deinterlacing
      LFinalFrame := @LDeintFrame;
      Move(LPicture, LFinalFrame^, SizeOf(TAVFrame));
      with ACodec^ do
      begin
        avpicture_fill(PAVPicture(LFinalFrame), FDeintBuf, pix_fmt, width, height);
        if avpicture_deinterlace(PAVPicture(LFinalFrame), PAVPicture(@LPicture), pix_fmt, width, height) < 0 then
        begin
          ASM1;
          (* if error, do not deinterlace *)
          FFLogger.Log(Self, llError, 'deinterlacing failed.');
          FDeinterlace := False;
          LFinalFrame := @LPicture;
        end
        else
          ASM1;
      end;
    end;
  end;

  // duplicate picture
  DuplicatePicture(LFinalFrame, APacket);
  Result := 1;
{$ENDIF}
end;

function TFFDecoder.Decode(AStreamIndex: Integer): Boolean;
const
  Caller = 'Decode() for video';
var
  LStreamIndex: Integer;
  LCodec: PAVCodecContext;
  LPacket: TAVPacket;
  LRet: Integer;
begin
  Result := False;

  // select stream index
  LStreamIndex := SelectVideoStreamIndex(AStreamIndex);
  if LStreamIndex < 0 then
    Exit;

  // use cached picture for image2 format
  if FPicture.Ready and SameText(string(FFileHandle.iformat.name), 'image2') then {Do not Localize}
  begin
    Result := True;
    Exit;
  end;

  // eof
  if FEOF and FEOFpkt then
  begin
    DoErrLog(AV_LOG_INFO, '%s.%s: stream eof reached.', [Self.ClassName, Caller]);
    Exit;
  end;

{$IFDEF NEED_KEY}
  if Round(Now * 24 * 60) mod 3 = 0 then
    _CK3(FParent.FLic)
  else if (Length(delphi_filename(FFileHandle.FileName)) > 20) or (FForceFormat <> '') then
    _CK1(FParent.FLic);
{$ENDIF}

  // open decoder
  LCodec := OpenVideoDecoder(LStreamIndex);
  if not Assigned(LCodec) then
    Exit;

  // read packet and decode frame
  repeat
    // try to read video packet
    repeat
      // after calling av_read_frame(), handle position will change, so next call will read next frame
      FLastRead := av_gettime();
      LRet := av_read_frame(FFileHandle, @LPacket);
      if LRet < 0 then
      begin
        if LRet = -11{AVERROR_EAGAIN} then
        begin
          DoErrLog(AV_LOG_INFO, '%s.%s: no data, please try again.', [Self.ClassName, Caller]);
          Exit;
        end
        else if FEOFpkt then
        begin
          if (LRet = AVERROR_EPIPE) or (LRet = AVERROR_EOF) or (url_feof(FFileHandle.pb) <> 0) then
          begin
            DoErrLog(AV_LOG_INFO, '%s.%s: stream eof reached.', [Self.ClassName, Caller]);
            FEOF := True;
          end
          else
            DoErrLog(AV_LOG_INFO, Format('%s.%s: unknown error #%d.', [Self.ClassName, Caller, LRet]));
          Exit;
        end;
        (* EOF handling *)
        FEOFpkt := True;
        av_init_packet(@LPacket);
        LPacket.stream_index := LStreamIndex;
        LPacket.data := nil;
        LPacket.size := 0;
      end;

      // it's video packet we want
      if LPacket.stream_index = LStreamIndex then
      begin
{ $DEFINE DEBUG_PACKET_INFO}
{$IFDEF DEBUG_PACKET_INFO}
        FFLogger.Log(Self, llInfo, 'pkt.st_idx=%d, dts=%d, pts=%d, flags=%d',
          [LPacket.stream_index, LPacket.dts, LPacket.pts, LPacket.flags]);
        av_free_packet(@LPacket);
        Continue;
{$ELSE}
        Break;
{$ENDIF}
      end;

      av_free_packet(@LPacket)
    until False;

    LRet := DoDecodeVideo(LCodec, @LPacket);
    av_free_packet(@LPacket);

    if LRet <= 0 then
      Continue
    else
      Break;
  until False;
  Result := True;
end;

function TFFDecoder.DoDecodeAudio(AAudioParam: PAudioParam; ACodec: PAVCodecContext; APacket: PAVPacket): Integer;
var
  total_data_size: Integer;
  avpkt: TAVPacket;
  got_output: Integer;
  LRet: Integer;
  LPTS: Int64;
begin
  ResetWaveInfo;

  total_data_size := 0;
  avpkt := APacket^;

  if FEOFpkt then
    got_output := 1
  else
    got_output := 0;

  while (avpkt.size > 0) or (FEOFpkt and (got_output <> 0)) do
  begin
    if (avpkt.size <> 0) and (avpkt.size <> APacket.size) then
      FFLogger.Log(Self, llWarning,
          Format('Multiple frames in a packet from stream %d', [APacket.stream_index]));

    avcodec_get_frame_defaults(@FAudioDecodedFrame);
    LRet := avcodec_decode_audio4(ACodec, @FAudioDecodedFrame, @got_output, @avpkt);
    if LRet < 0 then
    begin
      FFLogger.Log(Self, llError,
        print_error(Format('Error while decoding audio stream #%d', [APacket.stream_index]), LRet));
      Break;
    end;

    // touch data and size only if not EOF
    if Assigned(avpkt.data) then
    begin
      Inc(avpkt.data, LRet);
      Dec(avpkt.size, LRet);
    end;

    if got_output = 0 then
      Continue;

    AAudioParam.st_idx := APacket.stream_index;
    LRet := DoAudioResample(total_data_size, @FAudioDecodedFrame, AAudioParam);
    if LRet < 0 then
    begin
      Result := LRet;
      Exit;
    end;
    Inc(total_data_size, LRet);
  end;

  if total_data_size <= 0 then
  begin
    // no decoded data
    Result := 0;
    Exit;
  end;

{ $DEFINE DEBUG_FRAME_INFO}
{$IFDEF DEBUG_FRAME_INFO}
  FFLogger.Log(Self, llInfo, 'pkt.st_idx=%d, dts=%d, pts=%d, flags=%d, samples data size=%d',
    [APacket.stream_index, APacket.dts, APacket.pts, APacket.flags, total_data_size]);
  Result := 0;
{$ELSE}
//  FFLogger.Log(Self, llDebug, 'pkt.st_idx=%d, dts=%d, pts=%d, flags=%d, samples data size=%d',
//    [APacket.stream_index, APacket.dts, APacket.pts, APacket.flags, total_data_size]);

  with FWaveInfo do
  begin
    // pts rescaled
    if APacket.dts <> AV_NOPTS_VALUE then
      LPTS := APacket.dts
    else
      LPTS := APacket.pts;
    if LPTS <> AV_NOPTS_VALUE then
    begin
      if PPtrIdx(FFileHandle.streams, APacket.stream_index)^.start_time <> AV_NOPTS_VALUE then
        Dec(LPTS, PPtrIdx(FFileHandle.streams, APacket.stream_index)^.start_time);
      PTS := av_rescale_q(LPTS, PPtrIdx(FFileHandle.streams, APacket.stream_index)^.time_base, AV_TIME_BASE_Q);
//      FFLogger.Log(Self, llDebug, 'decode PTS: %0.3f', [PTS / AV_TIME_BASE]);
    end
    else
      PTS := AV_NOPTS_VALUE;
    // original dts and pts
    OriginalDTS := APacket.dts;
    OriginalPTS := APacket.pts;
    StreamIndex := APacket.stream_index;
    Ready := True;
    Duration := Round(Size * AV_TIME_BASE / BytesPerSample / FDesireAudioSampleRate / FDesireAudioChannels);
  end;
  Result := 1;
{$ENDIF}
end;

function TFFDecoder.Decode(AType: TDecodeType): TDecodeResult;
const
  Caller = 'Decode() for video and/or audio';
var
  // both
  LPacket: TAVPacket;
  LRet: Integer;
  // video
  LVideoStreamIndex: Integer;
  LVideoCodec: PAVCodecContext;
  // audio
  LAudioStreamIndex: Integer;
  LAudioCodec: PAVCodecContext;
begin
  Result := drError;

  // select stream index
  if AType in [dtBoth, dtVideo] then
    LVideoStreamIndex := SelectVideoStreamIndex(-1)
  else
    LVideoStreamIndex := -1;
  if AType in [dtBoth, dtAudio] then
    LAudioStreamIndex := SelectAudioStreamIndex(-1)
  else
    LAudioStreamIndex := -1;
  if (LVideoStreamIndex < 0) and (LAudioStreamIndex < 0) then
    Exit;

  // eof
  if FEOF and FEOFpkt then
  begin
    DoErrLog(AV_LOG_INFO, '%s.%s: stream eof reached.', [Self.ClassName, Caller]);
    Exit;
  end;

{$IFDEF NEED_KEY}
  if Round(Now * 24 * 60) mod 3 = 0 then
    _CK3(FParent.FLic)
  else if (Length(delphi_filename(FFileHandle.FileName)) > 20) or (FForceFormat <> '') then
    _CK1(FParent.FLic);
{$ENDIF}

  // open video decoder
  if LVideoStreamIndex >= 0 then
  begin
    LVideoCodec := OpenVideoDecoder(LVideoStreamIndex);
    if not Assigned(LVideoCodec) then
      Exit;
  end
  else
    LVideoCodec := nil; {stop compiler warning}

  // open audio decoder
  if LAudioStreamIndex >= 0 then
  begin
    LAudioCodec := OpenAudioDecoder(LVideoStreamIndex);
    if not Assigned(LAudioCodec) then
      Exit;
  end
  else
    LAudioCodec := nil; {stop compiler warning}

  // read packet and decode frame
  repeat
    // try to read packet
    repeat
      // after calling av_read_frame(), handle position will change, so next call will read next frame
      FLastRead := av_gettime();
      LRet := av_read_frame(FFileHandle, @LPacket);
      if LRet < 0 then
      begin
        if LRet = -11{AVERROR_EAGAIN} then
        begin
          DoErrLog(AV_LOG_INFO, '%s.%s: no data, please try again.', [Self.ClassName, Caller]);
          Exit;
        end
        else if FEOFpkt then
        begin
          if (LRet = AVERROR_EPIPE) or (LRet = AVERROR_EOF) or (url_feof(FFileHandle.pb) <> 0) then
          begin
            DoErrLog(AV_LOG_INFO, '%s.%s: stream eof reached.', [Self.ClassName, Caller]);
            FEOF := True;
          end
          else
            DoErrLog(AV_LOG_INFO, Format('%s.%s: unknown error #%d.', [Self.ClassName, Caller, LRet]));
          Exit;
        end;
        (* EOF handling *)
        FEOFpkt := True;
        av_init_packet(@LPacket);
        LPacket.stream_index := LVideoStreamIndex; // TODO: how about audio
        LPacket.data := nil;
        LPacket.size := 0;
      end;

      // it's the packet we want
      if (LPacket.stream_index = LVideoStreamIndex) or (LPacket.stream_index = LAudioStreamIndex) then
      begin
{ $DEFINE DEBUG_PACKET_INFO}
{$IFDEF DEBUG_PACKET_INFO}
        FFLogger.Log(Self, llInfo, 'pkt.st_idx=%d, dts=%d, pts=%d, flags=%d',
          [LPacket.stream_index, LPacket.dts, LPacket.pts, LPacket.flags]);
        av_free_packet(@LPacket);
        Continue;
{$ELSE}
        Break;
{$ENDIF}
      end;

      av_free_packet(@LPacket)
    until False;

    if LPacket.stream_index = LVideoStreamIndex then  // video packet
    begin
      LRet := DoDecodeVideo(LVideoCodec, @LPacket);
      if LRet > 0 then
        Result := drVideo
      else if LRet < 0 then
        LRet := 0;
    end
    else if LPacket.stream_index = LAudioStreamIndex then // audio packet
    begin
      LRet := DoDecodeAudio(@FAudioParam, LAudioCodec, @LPacket);
      if LRet > 0 then
        Result := drAudio;
    end
    else
      LRet := -1;
    av_free_packet(@LPacket);

    if LRet <> 0 then
      Break;
  until False;
end;

function TFFDecoder.DecodeNextKeyFrame(AStreamIndex: Integer): Boolean;
var
  LStreamIndex: Integer;
  LDelta: Int64;
begin
  // select stream index
  LStreamIndex := SelectVideoStreamIndex(AStreamIndex);
  if LStreamIndex < 0 then
  begin
    Result := False;
    Exit;
  end;

  // calculate interval between two frames
  LDelta := GetFrameInterval(FFrameRate);

  // initialize seek_to_pts as next frame pts to seek to the next key-frame
  if FPicture.PTS > 0 then
    Result := Seek(FPicture.PTS + LDelta) // TODO: force seek flags
  else
    Result := Seek(LDelta);               // TODO: force seek flags

  // decode the frame
  if Result then
    Result := Decode(LStreamIndex);
end;

function TFFDecoder.DecodePreviousFrame(AStreamIndex: Integer): Boolean;
var
  LStreamIndex: Integer;
  LDelta: Int64;
  LPTS: Int64;
  LLastPTS: Int64;
  LTargetPTS: Int64;
begin
  // select stream index
  LStreamIndex := SelectVideoStreamIndex(AStreamIndex);
  if LStreamIndex < 0 then
  begin
    Result := False;
    Exit;
  end;

  // calculate interval between two frames
  LDelta := GetFrameInterval(FFrameRate);

  // approximate pts
  if FPicture.PTS <> AV_NOPTS_VALUE then
  begin
    LPTS := FPicture.PTS - 2 * LDelta;
    LLastPTS := FPicture.PTS;
  end
  else if FLastPTS <> AV_NOPTS_VALUE then
  begin
    LPTS := FLastPTS - 2 * LDelta;
    LLastPTS := FLastPTS;
  end
  else
  begin
    LPTS := 0 - 2 * LDelta;
    LLastPTS := 0;
  end;

  LTargetPTS := AV_NOPTS_VALUE;

  // decode previous key-frame
  if DecodePreviousKeyFrame(LStreamIndex) then
  begin
    repeat
      // if the frame is the one we desire
      if FPicture.PTS > LPTS then
      begin
        Result := True;
        Exit;
      end;
      // decode next frame
      if not Decode(LStreamIndex) then
        Break;
      if FPicture.PTS < LLastPTS then
        LTargetPTS := FPicture.PTS;
      if FPicture.PTS = LLastPTS then
        if DecodePreviousKeyFrame(LStreamIndex) then
        begin
          if LTargetPTS <> AV_NOPTS_VALUE then
          begin
            repeat
              if not Decode(LStreamIndex) then
                Break;
              if FPicture.PTS >= LTargetPTS then
                Break;
            until False;
          end;
          Result := TRue;
          Exit;
        end;
    until False;
  end;

  Result := False;
end;

function TFFDecoder.DecodePreviousKeyFrame(AStreamIndex: Integer): Boolean;
var
  LStreamIndex: Integer;
  LDelta: Int64;
  LPTS: Int64;
  LPos: Int64;
  LBeforeSeekPos: Int64;
  LAfterSeekPos: Int64;
  LLastSeekPos: Int64;
  N: Integer;
begin
  // select stream index
  LStreamIndex := SelectVideoStreamIndex(AStreamIndex);
  if LStreamIndex < 0 then
  begin
    Result := False;
    Exit;
  end;

  // calculate interval between two frames
  LDelta := GetFrameInterval(FFrameRate);

  // current pts
  if FPicture.PTS <> AV_NOPTS_VALUE then
    LPTS := FPicture.PTS
  else if FLastPTS <> AV_NOPTS_VALUE then
    LPTS := FLastPTS
  else if FFileHandle.duration <> AV_NOPTS_VALUE then
    LPTS := FFileHandle.duration
  else
    LPTS := 0; // TODO: duration

  // current position
  if Assigned(FFileHandle.pb) then
    LPos := avio_tell(FFileHandle.pb)
  else
    LPos := -1;
  LBeforeSeekPos := -1;
  LAfterSeekPos := -1;
  LLastSeekPos := -2;

  N := 1;
  repeat
    if Assigned(FFileHandle.pb) then
      LBeforeSeekPos := avio_tell(FFileHandle.pb);

    // initialize seek_to_pts as previous N frame pts to seek to the previous key-frame
    Seek(LPTS - LDelta * N, [sfBackward]); // TODO: force seek flags

    // check last position to improve performance
    if Assigned(FFileHandle.pb) then
    begin
      LAfterSeekPos := avio_tell(FFileHandle.pb);
      if (LAfterSeekPos >= LPos) and (LPos > 0) and
        (LAfterSeekPos <> LBeforeSeekPos) then // position may not change after seek in some formats
      begin
        if LPTS >= LDelta * N then
        begin
          Inc(N);
          Continue;
        end;
      end;
      if LLastSeekPos = -1 then
        LLastSeekPos := LAfterSeekPos
      else if (LLastSeekPos > 0) and (LAfterSeekPos >= LLastSeekPos) then
      begin
        if LPTS >= LDelta * N then
        begin
          Inc(N);
          Continue;
        end;
      end;
    end;

    if LLastSeekPos = -2 then
      LLastSeekPos := -1;

    // try to decode the frame
    if Decode(LStreamIndex) then
    begin
      // if the frame is the one we desire
      if (FPicture.PTS < LPTS) or (FPicture.PTS <= 0) or
        ((FPicture.PTS = LPTS) and (LPTS < LDelta * N)) then
      begin
        Result := True;
        Exit;
      end;
      if (FPicture.PTS >= LPTS) and (LAfterSeekPos < LLastSeekPos) then
        LLastSeekPos := -1;
    end
    else if (LPTS < LDelta * N) or FEOF then
    begin
      FLastErrMsg := 'Could not seek to the previous key-frame. ' + FLastErrMsg;
      Break;
    end;
    Inc(N);
  until (False);
  Result := False;
end;

{$IFDEF NEED_YUV}
procedure MaskPicture(ABitmap: TBitmap);
begin
{$IFDEF FFFMX}
  with ABitmap.Canvas do
  begin
    if BeginScene then
      try
        Font.Style := [TFontStyle.fsBold];
        Font.Family := 'Tahoma';
        Font.Size := 14;
        Fill.Kind := TBrushKind.bkSolid;
        Fill.Color := claWhite;
        FillText(RectF(3, 0, 3 + TextWidth(SComponents), TextHeight(SComponents)),
                  SComponents, False, 1, [], TTextAlign.taLeading, TTextAlign.taCenter);
        FillText(RectF(3 + (TextWidth(SComponents) - TextWidth(SWebSiteE)) / 2, TextHeight(SComponents),
                  3 + (TextWidth(SComponents) + TextWidth(SWebSiteE)) / 2, TextHeight(SComponents) + TextHeight(SWebSiteE)),
                  SWebSiteE, False, 1, [], TTextAlign.taLeading, TTextAlign.taCenter);
      finally
        EndScene;
      end;
  end;
{$ELSE}
  with ABitmap.Canvas.Font do
  begin
    Color := clWhite;
    Style := [fsBold];
    Name := 'Tahoma';
    Size := 14;
  end;
  with ABitmap.Canvas do
  begin
    Brush.Style := bsClear;
    TextOut(3, 0, SComponents);
    TextOut(3 + (TextWidth(SComponents) - TextWidth(SWebSiteE)) div 2, TextHeight(SComponents), SWebSiteE);
  end;
{$ENDIF}
end;
{$ENDIF}

function TFFDecoder.CopyToBitmap(ABitmap: TBitmap): Boolean;
begin
  if not FPicture.Ready then
  begin
    DoErrLog(AV_LOG_ERROR, 'picture not ready, please decode first');
    Result := False;
    Exit;
  end;

  with FPicture do
    Result := FFormatConv.PictureToRGB(@Picture, PixFmt, Width, Height);

  if Result then
  begin
{$IFDEF NEED_YUV}
    if FPicture.PixFmt <> AV_PIX_FMT_YUV420P then
  {$IFDEF NEED_IDE}
      if (Fyuv01 <> 1) or (Fyuv23 <> 0) or (Fyuv45 <> 1) then
  {$ENDIF}
      MaskPicture(FFormatConv.Bitmap);
{$ENDIF}
    ABitmap.Assign(FFormatConv.Bitmap);
{$IFDEF NEED_KEY}
    if Round(Now) mod 2 = 0 then
      _CK2(FParent.FLic)
    else
      _CK4(FParent.FLic);
{$ENDIF}
  end
  else
  begin
    ABitmap.Width := FPicture.Width;
    ABitmap.Height := FPicture.Height;
{$IFDEF FFFMX}
    ABitmap.Canvas.Fill.Color := claBlack;
    ABitmap.Canvas.Fill.Kind := TBrushKind.bkSolid;
    ABitmap.Canvas.FillRect(RectF(0, 0, FPicture.Width, FPicture.Height),
                            0, 0, [], 0);
{$ELSE}
    ABitmap.Canvas.Brush.Color := clBlack;
    ABitmap.Canvas.Brush.Style := bsSolid;
    ABitmap.Canvas.FillRect(ABitmap.Canvas.ClipRect);
{$ENDIF}
    DoErrLog(AV_LOG_ERROR, FFormatConv.LastErrMsg);
  end;
{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
  if not PHPF{INIDE2} or not PHFF{INIDE3} then
    Fyuv23 := 1;
{$IFEND}
end;

{$IFDEF MSWINDOWS}
function TFFDecoder.GetBitmapPtr: PBitmap;
begin
  if not FPicture.Ready then
  begin
    DoErrLog(AV_LOG_ERROR, 'picture not ready, please decode first');
    Result := nil;
    Exit;
  end;

  with FPicture do
    if FFormatConv.PictureToRGB(@Picture, PixFmt, Width, Height, False) then
      Result := FFormatConv.DIB
    else
    begin
      DoErrLog(AV_LOG_ERROR, FFormatConv.LastErrMsg);
      Result := nil;
    end;

{$IF Defined(NEED_IDE) And Defined(NEED_YUV)}
  if not PHPF{INIDE2} or not PHFF{INIDE3} then
    Fyuv23 := 1;
{$IFEND}
end;
{$ENDIF}

function TFFDecoder.DoAudioResample(data_offset: Integer; AFrame: PAVFrame; AAudioParam: PAudioParam): Integer;
var
  source_layout: Int64;
  out_buf: PPByte;
  out_count: Integer;
  out_size: Integer;
  decoded_data_size: Integer;
  decoded_data: PByte;
begin
  if (AFrame.channel_layout <> 0) and (AFrame.channels = av_get_channel_layout_nb_channels(AFrame.channel_layout)) then
    source_layout := AFrame.channel_layout
  else
    source_layout := av_get_default_channel_layout(AFrame.channels);
  if (AAudioParam.channel_layout <> source_layout) or
     (AAudioParam.channels       <> AFrame.channels) or
     (AAudioParam.freq           <> AFrame.sample_rate) or
     (AAudioParam.fmt            <> TAVSampleFormat(AFrame.format)) then
  begin
    if AAudioParam.channels <> -1 then
    begin
      FFLogger.Log(Self, llInfo,
          'Audio stream #%d frame changed from %d Hz %s %d channels to %d Hz %s %d channels',
          [AAudioParam.st_idx, AAudioParam.freq, string(av_get_sample_fmt_name(AAudioParam.fmt)), AAudioParam.channels,
           AFrame.sample_rate, string(av_get_sample_fmt_name(TAVSampleFormat(AFrame.format))), AFrame.channels]);
      CloseAudioResampler(@AAudioParam.swr_ctx);
    end;
    AAudioParam.channel_layout := source_layout;
    AAudioParam.channels       := AFrame.channels;
    AAudioParam.freq           := AFrame.sample_rate;
    AAudioParam.fmt            := TAVSampleFormat(AFrame.format);
  end;

  // resample or reformat
  if FDesireChannelLayout = 0 then
    FDesireChannelLayout := av_get_default_channel_layout(FDesireAudioChannels);
  if (FDesireChannelLayout     <> AAudioParam.channel_layout) or
     (FDesireAudioChannels     <> AAudioParam.channels) or
     (FDesireAudioSampleRate   <> AAudioParam.freq) or
     (FDesireAudioSampleFormat <> AAudioParam.fmt) then
  begin
    if not Assigned(AAudioParam.swr_ctx) then
    begin
      AAudioParam.swr_ctx := swr_alloc_set_opts(nil,
                            FDesireChannelLayout, FDesireAudioSampleFormat, FDesireAudioSampleRate,
                            AAudioParam.channel_layout, AAudioParam.fmt, AAudioParam.freq,
                            0, nil);
      if Assigned(AAudioParam.swr_ctx) and (swr_init(AAudioParam.swr_ctx) < 0) then
      begin
        FFLogger.Log(Self, llFatal, 'swr_init() failed');
        CloseAudioResampler(@AAudioParam.swr_ctx);
      end;

      if not Assigned(AAudioParam.swr_ctx) then
      begin
        DoErrLog(AV_LOG_ERROR, Format('Can not resample %d Hz %s %d channels to %d Hz %s %d channels',
                [AFrame.sample_rate, string(av_get_sample_fmt_name(TAVSampleFormat(AFrame.format))), AFrame.channels,
                 FDesireAudioSampleRate, string(av_get_sample_fmt_name(FDesireAudioSampleFormat)), FDesireAudioChannels]));
        Result := -1;
        Exit;
      end;
      FFLogger.Log(Self, llInfo, 'need resample %d Hz %s %d channels to %d Hz %s %d channels',
              [AFrame.sample_rate, string(av_get_sample_fmt_name(TAVSampleFormat(AFrame.format))), AFrame.channels,
               FDesireAudioSampleRate, string(av_get_sample_fmt_name(FDesireAudioSampleFormat)), FDesireAudioChannels]);
    end;

    out_buf := @FResampledBuffer;
    out_count := Int64(AFrame.nb_samples) * FDesireAudioSampleRate div AFrame.sample_rate + 256;
    out_size := av_samples_get_buffer_size(nil, FDesireAudioChannels, out_count, FDesireAudioSampleFormat, 0);
    av_fast_malloc(@FResampledBuffer, @FResampledSize, out_size);
    if not Assigned(FResampledBuffer) then
    begin
      DoErrLog(AV_LOG_ERROR, 'av_fast_malloc() failed');
      Result := AVERROR_ENOMEM;
      Exit;
    end;
    decoded_data_size := swr_convert(AAudioParam.swr_ctx, out_buf, out_count, AFrame.extended_data, AFrame.nb_samples);
    if decoded_data_size < 0 then
    begin
      DoErrLog(AV_LOG_ERROR, print_error('swr_convert() failed', decoded_data_size));
      Result := decoded_data_size;
      Exit;
    end;
    if decoded_data_size = out_count then
    begin
      DoErrLog(AV_LOG_ERROR, 'warning: audio buffer is probably too small');
      swr_init(AAudioParam.swr_ctx);
    end;
    decoded_data_size := decoded_data_size * FDesireAudioChannels * av_get_bytes_per_sample(FDesireAudioSampleFormat);
    decoded_data := FResampledBuffer;
  end
  else
  begin
    decoded_data_size := av_samples_get_buffer_size(nil, AFrame.channels,
                                                    AFrame.nb_samples,
                                                    TAVSampleFormat(AFrame.format), 1);
    decoded_data := AFrame.data[0];
  end;

  if (FAudioBuffer = nil) or (FAudioSize < data_offset + decoded_data_size) then
  begin
    FAudioSize := data_offset + decoded_data_size;
    FAudioBuffer := av_realloc(FAudioBuffer, FAudioSize);
  end;
  Move(decoded_data^, PByte(Integer(FAudioBuffer) + data_offset)^, decoded_data_size);

  FWaveInfo.Buffer := FAudioBuffer;
  FWaveInfo.Size := data_offset + decoded_data_size;
  Result := decoded_data_size;
end;

function TFFDecoder.DecodeAudio(AStreamIndex: Integer): Boolean;
const
  Caller = 'DecodeAudio()';
var
  LStreamIndex: Integer;
  LCodec: PAVCodecContext;
  LPacket: TAVPacket;
  LRet: Integer;
begin
  Result := False;

  // select stream index
  LStreamIndex := SelectAudioStreamIndex(AStreamIndex);
  if LStreamIndex < 0 then
    Exit;

  // eof
  if FEOF and FEOFpkt then
  begin
    DoErrLog(AV_LOG_INFO, '%s.%s: stream eof reached.', [Self.ClassName, Caller]);
    Exit;
  end;

{$IFDEF NEED_KEY}
  if Round(Now * 24 * 60) mod 3 = 0 then
    _CK3(FParent.FLic)
  else if (Length(delphi_filename(FFileHandle.FileName)) > 20) or (FForceFormat <> '') then
    _CK1(FParent.FLic);
{$ENDIF}

  // open decoder
  LCodec := OpenAudioDecoder(LStreamIndex);
  if not Assigned(LCodec) then
    Exit;

  // reset for decoding video
  FLastPTS := AV_NOPTS_VALUE;

  // read packet and decode frame
  repeat
    // try to read audio packet
    repeat
      // after calling av_read_frame(), handle position will change, so next call will read next frame
      FLastRead := av_gettime();
      LRet := av_read_frame(FFileHandle, @LPacket);
      if LRet < 0 then
      begin
        if LRet = -11{AVERROR_EAGAIN} then
        begin
          DoErrLog(AV_LOG_INFO, '%s.%s: no data, please try again.', [Self.ClassName, Caller]);
          Exit;
        end
        else if FEOFpkt then
        begin
          if (LRet = AVERROR_EPIPE) or (LRet = AVERROR_EOF) or (url_feof(FFileHandle.pb) <> 0) then
          begin
            DoErrLog(AV_LOG_INFO, '%s.%s: stream eof reached.', [Self.ClassName, Caller]);
            FEOF := True;
          end
          else
            DoErrLog(AV_LOG_INFO, Format('%s.%s: unknown error #%d.', [Self.ClassName, Caller, LRet]));
          Exit;
        end;
        (* EOF handling *)
        FEOFpkt := True;
        av_init_packet(@LPacket);
        LPacket.stream_index := LStreamIndex;
        LPacket.data := nil;
        LPacket.size := 0;
      end;

      // it's audio packet we want
      if LPacket.stream_index = LStreamIndex then
      begin
{ $DEFINE DEBUG_PACKET_INFO}
{$IFDEF DEBUG_PACKET_INFO}
        FFLogger.Log(Self, llInfo, 'pkt.st_idx=%d, dts=%d, pts=%d, flags=%d',
          [LPacket.stream_index, LPacket.dts, LPacket.pts, LPacket.flags]);
        av_free_packet(@LPacket);
        Continue;
{$ELSE}
        Break;
{$ENDIF}
      end;

      av_free_packet(@LPacket)
    until False;

    LRet := DoDecodeAudio(@FAudioParam, LCodec, @LPacket);
    av_free_packet(@LPacket);

    if LRet <> 0 then
    begin
      if LRet > 0 then
        Result := True;
      Break;
    end;
  until False;
end;

function TFFDecoder.ReadAudio(ABuffer: PByte; ACount, AStreamIndex: Integer): Integer;
begin
  if FRemainsAudioSize <= 0 then
  begin
    if not DecodeAudio(AStreamIndex) then
    begin
      Result := -1;
      Exit;
    end;
    FRemainsAudioSize := FWaveInfo.Size;
  end;

  Assert(FRemainsAudioSize > 0);

  if ACount > FRemainsAudioSize then
    Result := FRemainsAudioSize
  else
    Result := ACount;

  if Assigned(ABuffer) then
  begin
    Move(PByte(Integer(FWaveInfo.Buffer) + FWaveInfo.Size - FRemainsAudioSize)^, ABuffer^, Result);
    Dec(FRemainsAudioSize, Result);
  end;
end;

{ TDecoderThread }

constructor TDecoderThread.Create(ADecoder: TAudioDecoder);
begin
  inherited Create(False);
  FDecoder := ADecoder;
end;

procedure TDecoderThread.Execute;
begin
  FDecoder.ExcudeDecode;
end;

{ TAudioDecoder }

function TAudioDecoder.OpenAudioDecoder2(AStreamIndex: Integer): PAVCodecContext;
var
  st: PAVStream;
  LCodec: PAVCodecContext;
  LDecoder: PAVCodec;
  opts: PAVDictionary;
  I: Integer;
begin
  st := PPtrIdx(FFileHandle.streams, AStreamIndex);
  // check codec
  LCodec := st^.codec;
  Assert(LCodec.codec_type = AVMEDIA_TYPE_AUDIO);

  if High(FAudioCodecs) < 0 then
  begin
    SetLength(FAudioCodecs, FStreamCount);
    for I := 0 to High(FAudioCodecs) do
      FAudioCodecs[I] := nil;
  end;

  // reuse last decoder
  if LCodec = FAudioCodecs[AStreamIndex] then
  begin
    Result := FAudioCodecs[AStreamIndex];
    Exit;
  end;

  Assert(FAudioCodecs[AStreamIndex] = nil);

  // find decoder
  LDecoder := avcodec_find_decoder(LCodec.codec_id);
  if not Assigned(LDecoder) then
  begin // codec not found
    DoErrLog(AV_LOG_ERROR, Format('Unsupported codec (id=%d) for input file stream #%d',
            [Ord(LCodec.codec_id), AStreamIndex]));
    Result := nil;
    Exit;
  end;

  // open decoder
  opts := filter_codec_opts(FOptions.codec_opts, LCodec.codec_id, FFileHandle, st, LDecoder);
  //LCodec.request_channels := FDesireAudioChannels;
  if avcodec_open2(LCodec, LDecoder, @opts) < 0 then
  begin // codec open failed
    DoErrLog(AV_LOG_ERROR, Format('Error while opening codec for input file stream #%d',
            [AStreamIndex]));
    Result := nil;
    Exit;
  end;

  // save last codec
  FAudioCodecs[AStreamIndex] := LCodec;
  Result := LCodec;
end;

function TAudioDecoder.DoDecode: Boolean;
const
  Caller = 'DoDecode()';
var
  LCodec: PAVCodecContext;
  LPacket: TAVPacket;
  LRet: Integer;
begin
  if FAudioStreamCount <= 1 then
  begin
    Result := DecodeAudio();
    Exit;
  end;

  Result := False;

  // eof
  if FEOF and FEOFpkt then
  begin
    DoErrLog(AV_LOG_INFO, '%s.%s: stream eof reached.', [Self.ClassName, Caller]);
    Exit;
  end;

{$IFDEF NEED_KEY}
  if Round(Now * 24 * 60) mod 3 = 0 then
    _CK3(FParent.FLic)
  else if (Length(delphi_filename(FFileHandle.FileName)) > 20) or (FForceFormat <> '') then
    _CK1(FParent.FLic);
{$ENDIF}

  // reset for decoding video
  FLastPTS := AV_NOPTS_VALUE;

  // read packet and decode frame
  repeat
    // try to read audio packet
    repeat
      // after calling av_read_frame(), handle position will change, so next call will read next frame
      FLastRead := av_gettime();
      LRet := av_read_frame(FFileHandle, @LPacket);
      if LRet < 0 then
      begin
        if LRet = -11{AVERROR_EAGAIN} then
        begin
          DoErrLog(AV_LOG_INFO, '%s.%s: no data, please try again.', [Self.ClassName, Caller]);
          Exit;
        end
        else if FEOFpkt then
        begin
          if (LRet = AVERROR_EPIPE) or (LRet = AVERROR_EOF) or (url_feof(FFileHandle.pb) <> 0) then
          begin
            DoErrLog(AV_LOG_INFO, '%s.%s: stream eof reached.', [Self.ClassName, Caller]);
            FEOF := True;
          end
          else
            DoErrLog(AV_LOG_INFO, Format('%s.%s: unknown error #%d.', [Self.ClassName, Caller, LRet]));
          Exit;
        end;
        (* EOF handling *)
        FEOFpkt := True;
        av_init_packet(@LPacket);
        LPacket.stream_index := FWaveInfo.StreamIndex;
        LPacket.data := nil;
        LPacket.size := 0;
      end;

      // it's audio packet we want
      if IsAudioStream(LPacket.stream_index) then
      begin
{ $DEFINE DEBUG_PACKET_INFO}
{$IFDEF DEBUG_PACKET_INFO}
        FFLogger.Log(Self, llInfo, 'pkt.st_idx=%d, dts=%d, pts=%d, flags=%d',
          [LPacket.stream_index, LPacket.dts, LPacket.pts, LPacket.flags]);
        av_free_packet(@LPacket);
        Continue;
{$ELSE}
        Break;
{$ENDIF}
      end;

      av_free_packet(@LPacket)
    until False;

    // open decoder
    LCodec := OpenAudioDecoder2(LPacket.stream_index);
    if not Assigned(LCodec) then
      Exit;

    LRet := DoDecodeAudio(@FAudioParams[LPacket.stream_index], LCodec, @LPacket);
    av_free_packet(@LPacket);

    if LRet <> 0 then
    begin
      if LRet > 0 then
        Result := True;
      Break;
    end;
  until False;
end;

constructor TAudioDecoder.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPTSThreshold := 100000; // 0.1 second
  FBroken := True;
  FBuffer := nil;
  FBufSize := 0;
  FDataSignal := TEvent.Create(nil, True, True, ''); // manual reset, start signaled
  FSeekSignal := TEvent.Create(nil, True, True, ''); // manual reset, start signaled
end;

destructor TAudioDecoder.Destroy;
begin
  inherited Destroy;
  FDataSignal.SetEvent;
  FDataSignal.Free;
  FSeekSignal.SetEvent;
  FSeekSignal.Free;
  if Assigned(FBuffer) then
  begin
    FreeMem(FBuffer);
    FBuffer := nil;
    FBufSize := 0;
  end;
end;

procedure TAudioDecoder.CloseAudioResampler;
var
  I: Integer;
begin
  inherited CloseAudioResampler;
  for I := 0 to High(FAudioParams) do
    CloseAudioResampler(@FAudioParams[I].swr_ctx);
end;

procedure TAudioDecoder.CloseFile;
begin
  DoStop;
  inherited CloseFile;
end;

function TAudioDecoder.Seek(const APTS: Int64; ASeekFlags: TSeekFlags): Boolean;
var
  I: Integer;
begin
  if not FBroken then
  begin
    FSeekSignal.ResetEvent;
    FSeekResult := False;
    FSeekPTS := APTS;
    FSeekFlags := ASeekFlags;
    for I := 0 to High(FBuffers) do
      FBuffers[I].Reset;
    FSeekReq := True;
    FSeekSignal.WaitFor(INFINITE);
    Result := FSeekResult and not FBroken;
  end
  else
    Result := False;
end;

procedure TAudioDecoder.DoStart(ANoSleep: Boolean);
var
  I: Integer;
begin
  DoStop;
  Assert((FFileHandle <> nil) and FOwnHandle);
  Assert(High(FBuffers) < 0);
  // MixAudio() supports unsigned 8 bits, signed 16 bits and signed 32 bits audio format
  if not (FDesireAudioSampleFormat in [AV_SAMPLE_FMT_U8, AV_SAMPLE_FMT_S16, AV_SAMPLE_FMT_S32]) then
    Self.DesireAudioSampleFormat := AV_SAMPLE_FMT_S16;
  SetLength(FBuffers, FStreamCount);
  for I := 0 to High(FBuffers) do
  begin
    FBuffers[I] := TCircularBuffer.Create;
    // TODO: buffer setting
    FBuffers[I].WaitForData := False;
  end;
  Assert(High(FAudioParams) < 0);
  SetLength(FAudioParams, FStreamCount);
  for I := 0 to High(FAudioParams) do
  begin
    FAudioParams[I].channels := -1;
    FAudioParams[I].freq := -1;
    FAudioParams[I].fmt := AV_SAMPLE_FMT_NONE;
    FAudioParams[I].channel_layout := 0;
    FAudioParams[I].swr_ctx := nil;
  end;
  FNoSleep := ANoSleep;
  FBroken := False;
  FCurrentPTS := AV_NOPTS_VALUE;
  FThread := TDecoderThread.Create(Self);
end;

procedure TAudioDecoder.DoStop;
var
  I: Integer;
begin
  FBroken := True;
  FSeekReq := False;
  FDataSignal.SetEvent;
  FSeekSignal.SetEvent;
  for I := 0 to High(FBuffers) do
    FBuffers[I].Terminate;
  if Assigned(FThread) then
  begin
    FThread.Free;
    FThread := nil;
  end;
  for I := 0 to High(FAudioCodecs) do
  begin
    if Assigned(FAudioCodecs[I]) then
    begin
      avcodec_close(FAudioCodecs[I]);
      FAudioCodecs[I] := nil;
    end;
  end;
  SetLength(FAudioCodecs, 0);
  for I := 0 to High(FBuffers) do
    FBuffers[I].Free;
  SetLength(FBuffers, 0);
  for I := 0 to High(FAudioParams) do
  begin
    FAudioParams[I].channels := -1;
    FAudioParams[I].freq := -1;
    FAudioParams[I].fmt := AV_SAMPLE_FMT_NONE;
    FAudioParams[I].channel_layout := 0;
    FAudioParams[I].st_idx := -1;
    CloseAudioResampler(@FAudioParams[I].swr_ctx);
  end;
  SetLength(FAudioParams, 0);
end;

procedure TAudioDecoder.ExcudeDecode;
var
  I: Integer;
begin
  while not FBroken do
    try
      if FSeekReq then
      begin
        // Flush buffers, should be called when seeking or when switching to a different stream.
        try
          for I := 0 to High(FAudioCodecs) do
            if Assigned(FAudioCodecs[I]) then
              avcodec_flush_buffers(FAudioCodecs[I]);
          for I := 0 to High(FBuffers) do
            FBuffers[I].Reset;
          FCurrentPTS := AV_NOPTS_VALUE;
          FSeekIndex := -1;
          FSeekResult := inherited Seek(FSeekPTS, FSeekFlags);
          FSeekReq := False;
        finally
          FSeekSignal.SetEvent;
        end;
      end
      else if FEOF and FEOFpkt then
        Sleep(100)
      else if DoDecode and not FBroken then
      begin
        if FCurrentPTS = AV_NOPTS_VALUE then
          FCurrentPTS := FWaveInfo.PTS;
        FBuffers[FWaveInfo.StreamIndex].Write(FWaveInfo.Buffer^, FWaveInfo.Size);
      end;
      // mysterious! avoid av_freep() exception when calling avcodec_decode_audio4()
      // raised exception class $C0000005 with message 'access violation at xxx: read of address yyy'.
      if not FNoSleep then
        Sleep(1);
    finally
      FDataSignal.SetEvent;
    end;
end;

function TAudioDecoder.QuerySize: Integer;
var
  I: Integer;
  LSize: Integer;
begin
  Result := 0;
  for I := 0 to High(FBuffers) do
    if IsAudioStream(I) then
    begin
      LSize := FBuffers[I].DataSize;
      if LSize = 0 then
      begin
        Result := 0;
        Exit;
      end
      else if Result = 0 then
        Result := LSize
      else if LSize < Result then
        Result := LSize;
    end;
end;

function TAudioDecoder.WaitData(MinSize: Integer): Integer;
var
  LSize: Integer;
begin
  LSize := QuerySize;
  repeat
    if (FEOF and FEOFpkt) or  // eof
      FBroken then            // broken
      Break
    else
    begin
      FDataSignal.ResetEvent;
      FDataSignal.WaitFor(INFINITE);
      LSize := QuerySize;
    end;
  until LSize >= MinSize;
  Result := LSize;
end;

function TAudioDecoder.DoSeek(ASize: Integer; APTS: Int64): Integer;
var
  LSize: Integer;
  LDelta: Integer;
  I: Integer;
begin
  LSize := ASize;
  if (FCurrentPTS = AV_NOPTS_VALUE) and (LSize = 0) then
    LSize := WaitData;

  if (FCurrentPTS <> AV_NOPTS_VALUE) and (Abs(APTS - FCurrentPTS) > FPTSThreshold) then
  begin
    if APTS < FCurrentPTS then
    begin
      // seek backward
      Seek(APTS, [sfBackward]);
      LSize := WaitData;
    end
    else
    begin
      LDelta := DurationToBytes(APTS - FCurrentPTS);
      if LDelta > LSize then
      begin
        // seek forward
        Seek(APTS);
        LSize := WaitData;
      end
      else
      begin
        // skip data
        for I := 0 to High(FBuffers) do
          if IsAudioStream(I) then
            FBuffers[I].Discard(LDelta);
        FCurrentPTS := APTS;
        LSize := QuerySize;
      end;
    end;
  end;
  Result := LSize;
end;

function TAudioDecoder.DurationToBytes(ADuration: Int64): Integer;
begin
  Assert(ADuration > 0);
  Result := Round(ADuration * FDesireAudioSampleRate * FDesireAudioChannels / AV_TIME_BASE) * FWaveInfo.BytesPerSample;
end;

function TAudioDecoder.BytesToDuration(ABytes: Integer): Int64;
begin
  Assert(ABytes > 0);
  Result := Round(ABytes * AV_TIME_BASE / FWaveInfo.BytesPerSample / FDesireAudioChannels / FDesireAudioSampleRate);
end;

function TAudioDecoder.DoReadCombined(ABuffer: PByte; ACount: Integer): Integer;
begin
  Result := DoReadCombined(ABuffer, ACount, AV_NOPTS_VALUE, 0);
end;

function TAudioDecoder.DoReadCombined(ABuffer: PByte; ACount: Integer; APTS, ADuration: Int64): Integer;
var
  LCount: Integer;
  LSize: Integer;
  I: Integer;
  J: Integer;
  K: Integer;
begin
  if FBroken or (FAudioStreamCount < 1) then
  begin
    Result := -1;
    Exit;
  end;

  Assert(FWaveInfo.BytesPerSample <> 0);

  // align
  ACount := ACount div FWaveInfo.BytesPerSample div FDesireAudioChannels div FAudioStreamCount
                    *  FWaveInfo.BytesPerSample  *  FDesireAudioChannels  *  FAudioStreamCount;

  if ADuration <= 0 then
    LCount := ACount
  else
    // calculate data count according desire duration
    LCount := DurationToBytes(ADuration) * FAudioStreamCount;

  if ACount > LCount then
    Result := LCount
  else
    Result := ACount;

  LSize := QuerySize;

  // seek
  if APTS <> AV_NOPTS_VALUE then
    LSize := DoSeek(LSize, APTS);

  if LSize * FAudioStreamCount < Result then
  begin
    if not Assigned(ABuffer) then // query data size only
      Result := LSize * FAudioStreamCount
    else
    begin
      if ADuration <= 0 then  // do not care duration
        LSize := WaitData
      else
        LSize := WaitData(Result div FAudioStreamCount);
      if LSize * FAudioStreamCount < Result then
        Result := LSize * FAudioStreamCount;
    end;
  end;

  // align
  Result := Result div FWaveInfo.BytesPerSample div FDesireAudioChannels div FAudioStreamCount
                    *  FWaveInfo.BytesPerSample  *  FDesireAudioChannels  *  FAudioStreamCount;

  if Assigned(ABuffer) and (Result > 0) then
  begin
    // alloc buffer
    if not Assigned(FBuffer) then
    begin
      FBufSize := Result div FAudioStreamCount;
      GetMem(FBuffer, FBufSize);
    end
    else if FBufSize < Result div FAudioStreamCount then
    begin
      FBufSize := Result div FAudioStreamCount;
      ReallocMem(FBuffer, FBufSize);
    end;
    // fill silence sample
    if FDesireAudioSampleFormat = AV_SAMPLE_FMT_U8 then
    begin
      FillChar(ABuffer^, Result, 128);
      FillChar(FBuffer^, Result div FAudioStreamCount, 128);
    end
    else
    begin
      FillChar(ABuffer^, Result, 0);
      FillChar(FBuffer^, Result div FAudioStreamCount, 0);
    end;
    // read and then combine audio samples
    J := 0;
    for I := 0 to High(FBuffers) do
      if IsAudioStream(I) then
      begin
        if FAudioStreamCount > 1 then
        begin
          // read audio samples
          LCount := FBuffers[I].Read(FBuffer^, Result div FAudioStreamCount);
          // combine multiple streams into one single stream
          for K := 0 to LCount div FWaveInfo.BytesPerSample div FDesireAudioChannels - 1 do
            Move(PByte(Integer(FBuffer) + K * FWaveInfo.BytesPerSample * FDesireAudioChannels)^,
                 PByte(Integer(ABuffer) + (K * FAudioStreamCount + J) * FWaveInfo.BytesPerSample * FDesireAudioChannels)^,
                 FWaveInfo.BytesPerSample * FDesireAudioChannels);
          // TODO: sanity check remaining samples
          if LCount mod (FWaveInfo.BytesPerSample * FDesireAudioChannels) <> 0 then
            FFLogger.Log(Self, llError, 'TODO: LCount=%d, Result=%d, FWaveInfo.BytesPerSample * FDesireAudioChannels=%d',
                        [LCount, Result, FWaveInfo.BytesPerSample * FDesireAudioChannels]);
        end
        else
          Result := FBuffers[I].Read(ABuffer^, Result);
        Inc(J);
      end;
    // increase PTS
    if FCurrentPTS <> AV_NOPTS_VALUE then
      Inc(FCurrentPTS, BytesToDuration(Result div FAudioStreamCount));
  end;
end;

function TAudioDecoder.DoReadMixed(ABuffer: PByte; ACount: Integer): Integer;
begin
  Result := DoReadMixed(ABuffer, ACount, AV_NOPTS_VALUE, 0);
end;

function TAudioDecoder.DoReadMixed(ABuffer: PByte; ACount: Integer; APTS, ADuration: Int64): Integer;
var
  LCount: Integer;
  LSize: Integer;
  I: Integer;
begin
  if FBroken or (FAudioStreamCount < 1) then
  begin
    Result := -1;
    Exit;
  end;

  Assert(FWaveInfo.BytesPerSample <> 0);

  // align
  ACount := ACount div FWaveInfo.BytesPerSample div FDesireAudioChannels
                    *  FWaveInfo.BytesPerSample  *  FDesireAudioChannels;

  if ADuration <= 0 then
    LCount := ACount
  else
    // calculate data count according desire duration
    LCount := DurationToBytes(ADuration);

  if ACount > LCount then
    Result := LCount
  else
    Result := ACount;

  LSize := QuerySize;

  // seek
  if APTS <> AV_NOPTS_VALUE then
    LSize := DoSeek(LSize, APTS);

  if LSize < Result then
  begin
    if not Assigned(ABuffer) then // query data size only
      Result := LSize
    else
    begin
      if ADuration <= 0 then  // do not care duration
        LSize := WaitData
      else
        LSize := WaitData(Result);
      if LSize < Result then
        Result := LSize;
    end;
  end;

  // align
  Result := Result div FWaveInfo.BytesPerSample div FDesireAudioChannels
                    *  FWaveInfo.BytesPerSample  *  FDesireAudioChannels;

  if Assigned(ABuffer) and (Result > 0) then
  begin
    // alloc buffer
    if not Assigned(FBuffer) then
    begin
      FBufSize := Result;
      GetMem(FBuffer, FBufSize);
    end
    else if FBufSize < Result then
    begin
      FBufSize := Result;
      ReallocMem(FBuffer, FBufSize);
    end;
    // fill silence sample
    if FDesireAudioSampleFormat = AV_SAMPLE_FMT_U8 then
    begin
      FillChar(ABuffer^, Result, 128);
      FillChar(FBuffer^, Result, 128);
    end
    else
    begin
      FillChar(ABuffer^, Result, 0);
      FillChar(FBuffer^, Result, 0);
    end;
    // read and then mix audio samples
    for I := 0 to High(FBuffers) do
      if IsAudioStream(I) then
      begin
        if FAudioStreamCount > 1 then
        begin
          // read audio samples
          LCount := FBuffers[I].Read(FBuffer^, Result);
          // mix multiple streams into one single stream
          case FDesireAudioSampleFormat of
            AV_SAMPLE_FMT_U8:   MixAudioU8 (FBuffer^, ABuffer^, LCount);
            AV_SAMPLE_FMT_S16:  MixAudioS16(FBuffer^, ABuffer^, LCount);
            AV_SAMPLE_FMT_S32:  MixAudioS32(FBuffer^, ABuffer^, LCount);
          else
            raise Exception.Create('Never occur');
          end;
        end
        else
          Result := FBuffers[I].Read(ABuffer^, Result);
      end;
    // increase PTS
    if FCurrentPTS <> AV_NOPTS_VALUE then
      Inc(FCurrentPTS, BytesToDuration(Result));
  end;
end;

end.
