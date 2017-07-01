(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is unit of FFEncoder(old name is FFmpegVCL).
 * Created by CodeCoolie@CNSW 2008/04/16 -> $Date:: 2013-11-20 #$
 *)

unit FFEncode;

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
    {$ELSE}
      FMX.Types,
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

{$IFDEF USES_LICKEY}
  LicenseKey,
{$ENDIF}

  libavcodec,
  libavutil_pixfmt,
  libavutil_samplefmt,
  FFBaseComponent,
  FFDecode,
  FFmpegOpt,
  FFmpeg,
  FFUtils,
  MyUtils;

{$IFDEF POSIX}
const
  tpNormal = 0;
{$ENDIF}

type
  PInputOptions = ^TInputOptions;
  TInputOptions = record
    // input filename/url
    FileName: TPathFileName;
    // parameters compatible with ffmpeg command line except -i -pre -benchmark -timelimit
    Options: AnsiString;
    // presets format: name1=value1<CRLF>name2=value2<CRLF>...nameN=valueN<CRLF>
    //  delimiter: <CRLF> -> <Carriage Return Line Feed> -> #13#10
    Presets: AnsiString;
    // used for your special purpose
    Tag: Integer;
    Data: Pointer;
  end;

  POutputOptions = ^TOutputOptions;
  TOutputOptions = record
    // output filename/url
    FileName: TPathFileName;
    // parameters compatible with ffmpeg command line except -i -pre -benchmark -timelimit
    Options: AnsiString;
    // presets format: name1=value1<CRLF>name2=value2<CRLF>...nameN=valueN<CRLF>
    //  delimiter: <CRLF> -> <Carriage Return Line Feed> -> #13#10
    Presets: AnsiString;
    // whether enable OnAudioInputHook event
    AudioInputHook: Boolean;
    // whether enable OnAudioOutputHook event
    AudioOutputHook: Boolean;
    // whether enable OnVideoInputHook event
    VideoInputHook: Boolean;
    // whether enable OnVideoOutputHook event
    VideoOutputHook: Boolean;
    // specifies the number of adjacent color bits on each plane needed to define a pixel.
    // one of (8, 15[555, BI_RGB], 16[565, BI_BITFIELDS], 24, 32), default to 32
    VideoHookBitsPixel: Integer;
    // whether enable OnFrameInputHook event
    FrameInputHook: Boolean;
    // whether enable OnFrameOutputHook event
    FrameOutputHook: Boolean;
    // join all input files to this one output file
    Join: Boolean;
    // used for your special purpose
    Tag: Integer;
    Data: Pointer;
  end;

  TFFmpeg = class(TCustomFFmpeg)
  private
    FDecoders: array of TFFDecoder;
    FInputOptions: array of PInputOptions;
    FOutputOptions: array of POutputOptions;
{$IFDEF ACTIVEX}
    FInputParameters: array of WideString;
    FOutputParameters: array of WideString;
{$ENDIF}

    function GetDecoder(FileIndex: Integer): TFFDecoder;
    function GetInputOptions(FileIndex: Integer): TInputOptions;
    procedure SetInputOptions(FileIndex: Integer; const Value: TInputOptions);
    function GetOutputOptions(FileIndex: Integer): TOutputOptions;
    procedure SetOutputOptions(FileIndex: Integer; const Value: TOutputOptions);
    function GetInputCount: Integer;
{$IFDEF ACTIVEX}
    function GetInputParameters(FileIndex: Integer): WideString;
    procedure SetInputParameters(FileIndex: Integer; const Value: WideString);
    function GetOutputParameters(FileIndex: Integer): WideString;
    procedure SetOutputParameters(FileIndex: Integer; const Value: WideString);
{$ENDIF}
  protected
    FParent: TFFBaseComponent;

    procedure ClearInputOptions(FileIndex: Integer);
    procedure ClearOutputOptions(FileIndex: Integer);

    property Decoders[FileIndex: Integer]: TFFDecoder read GetDecoder;
    property InputOptions[FileIndex: Integer]: TInputOptions read GetInputOptions write SetInputOptions;
    property OutputOptions[FileIndex: Integer]: TOutputOptions read GetOutputOptions write SetOutputOptions;
  public
    constructor Create; override;
    destructor Destroy; override;

    property InputCount: Integer read GetInputCount;
{$IFDEF ACTIVEX}
    property InputParameters[FileIndex: Integer]: WideString read GetInputParameters write SetInputParameters;
    property OutputParameters[FileIndex: Integer]: WideString read GetOutputParameters write SetOutputParameters;
{$ENDIF}
  end;

  TFFmpegList = class
  private
    FList: TList;

    function Get(Index: Integer): TFFmpeg;
    function GetCount: Integer;
  protected
    function Add(Item: TFFmpeg): Integer;
    procedure Clear;
    procedure Delete(Index: Integer);
    procedure Exchange(Index1, Index2: Integer);
    function First: TFFmpeg;
    function IndexOf(Item: TFFmpeg): Integer;
    function Last: TFFmpeg;
    function Remove(Item: TFFmpeg): Integer;

    procedure Pause;
    procedure Resume;
    procedure Stop(AWaitForStop: Boolean);
    procedure SetPreview(AValue: Boolean);
    procedure SetPreviewBitmap(AValue: Boolean);

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TFFmpeg read Get; default;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  // PCR - Program Clock Reference
  // STC - System Time Clock
  // SCR - System Clock Reference
  // PTS - Presentation Time Stamp
  // DTS - Decode Time Stamp

  TAVSampleFormat = libavutil_samplefmt.TAVSampleFormat;

  TAudioHookEvent = procedure(Sender: TObject; ATaskIndex: Integer;
    const APTS: Int64; ASample: PByte;
    ASize, ASampleRate, AChannels: Integer; ASampleFormat: TAVSampleFormat) of object;

  PHookInfo = ^THookInfo;
  THookInfo = record
    TaskIndex: Integer;     // index of converting tasks
    Bitmap: {$IFDEF ACTIVEX}PBitmap{$ELSE}TBitmap{$ENDIF};
                            // bitmap filled with the original video picture, you can save it,
                            //  or change it by drawing text or image on bitmap.Canvas,
                            //  but you must NOT change the size and the PixelFormat of the bitmap!
    FrameNumber: Integer;   // frame index number, first is 1 not 0
    PTS: Int64;             // presentation time stamp of current picture, in microseconds
    Update: Boolean;        // whether update the bitmap back to original video picture, default True
    StopHook: Boolean;      // whether stop video hook, if true then VideoHook event will not
                            //  be triggered with this file, default False
  end;
  // only triggered with OutputOptions.VideoInputHook/VideoOutputHook = True
  TVideoHookEvent = procedure(Sender: TObject; AHookInfo: PHookInfo) of object;

  PFrameHookInfo = ^TFrameHookInfo;
  TFrameHookInfo = record
    TaskIndex: Integer;     // index of converting tasks
    FrameNumber: Integer;   // frame index number, first is 1 not 0
    Picture: PAVPicture;
    PixFmt: TAVPixelFormat;
    Width: Integer;
    Height: Integer;
    PTS: Int64;             // presentation time stamp of current picture, in microseconds
  end;
  // only triggered with OutputOptions.FrameInputHook/FrameOutputHook = True
  TFrameHookEvent = procedure(Sender: TObject; AHookInfo: PFrameHookInfo) of object;

  TPreviewInfo = record
    TaskIndex: Integer;     // index of converting tasks
    Bitmap: TBitmap;        // bitmap filled with the target video picture, you can save it,
                            //  or paint it on any canvas(or any other control) which you want.
    FrameNumber: Integer;   // frame index number, first is 1 not 0
    PTS: Int64;             // presentation time stamp of current picture, in microseconds
  end;
  // only triggered with property PreviewBitmap = True
  TPreviewBitmapEvent = procedure(Sender: TObject; const APreviewInfo: TPreviewInfo) of object;

  PProgressInfo = ^TProgressInfo;
  TProgressInfo = record
    TaskIndex: Integer;     // index of converting tasks
    FileIndex: Integer;     // index of input files in the current task
    FrameNumber: Integer;   // current frame number
    FPS: Integer;           // video converting speed, frames per second, not valid when only audio output
    Quality: Single;        // quality
    BitRate: Single;        // bitrate
    CurrentSize: Int64;     // current output file size in bytes
    CurrentDuration: Int64; // current duration time in microsecond
    TotalDuration: Int64;   // total output duration time in microsecond
  end;
  TProgressEvent = procedure(Sender: TObject; AProgressInfo: PProgressInfo) of object;

  TTerminateInfo = record
    TaskIndex: Integer;     // index of converting tasks, (-1) means all tasks are terminated
    Finished: Boolean;      // True means converted success, False means converting broken
    Exception: Boolean;     // True means Exception occured, False please ignore
    ExceptionMsg: string;   // Exception message
  end;
  TTerminateEvent = procedure(Sender: TObject; const ATerminateInfo: TTerminateInfo) of object;

  TCustomEncoder = class(TFFBaseComponent)
  private
    FLastErrMsg: string;
    FData: Pointer;

    FHaltOnInvalidOption: Boolean;
    FPreview: Boolean;
    FPreviewBitmap: Boolean;
    FProgressInterval: Integer;
    {$WARN SYMBOL_PLATFORM OFF}
    FThreadPriority: TThreadPriority;
    FTriggerEventInMainThread: Boolean;
    FSender: TObject;
    FAVFormatContext: PAVFormatContext;

    FProgressInfo: TProgressInfo;
    FTerminateInfo: TTerminateInfo;
    FPreviewInfo: TPreviewInfo;
    FVideoHookInfo: THookInfo;
    FFrameHookInfo: TFrameHookInfo;

    FOnInputAudioHook: TAudioHookEvent;
    FOnOutputAudioHook: TAudioHookEvent;
    FOnBeforeFindStreamInfo: TBeforeFindStreamInfoEvent;
    FOnInputVideoHook: TVideoHookEvent;
    FOnOutputVideoHook: TVideoHookEvent;
    FOnPreviewBitmap: TPreviewBitmapEvent;
    FOnProgress: TProgressEvent;
    FOnTerminate: TTerminateEvent;
    FOnInputFrameHook: TFrameHookEvent;
    FOnOutputFrameHook: TFrameHookEvent;

    function GetDecoders(TaskIndex, FileIndex: Integer): TFFDecoder;
    function GetFFmpegs(Index: Integer): TFFmpeg;
    function GetInputFiles(TaskIndex, FileIndex: Integer): PAVFormatContext;
    function GetInputOptions(TaskIndex, FileIndex: Integer): TInputOptions;
    function GetOutputFiles(TaskIndex, FileIndex: Integer): PAVFormatContext;
    function GetOutputOptions(TaskIndex, FileIndex: Integer): TOutputOptions;
    function GetTasksCount: Integer;

    procedure SetPreview(const Value: Boolean);
    procedure SetPreviewBitmap(const Value: Boolean);
    procedure SetProgressInterval(const Value: Integer);
    function GetInputCount(TaskIndex: Integer): Integer;
  protected
    FAudioHookLock: TCriticalSection;
    FPreviewLock: TCriticalSection;
    FProgressLock: TCriticalSection;
    FTerminateLock: TCriticalSection;
    FVideoHookLock: TCriticalSection;
    FFrameHookLock: TCriticalSection;
    FFindStreamLock: TCriticalSection;
    FThreadTerminated: {$IFDEF FPC}BOOL{$ELSE}Boolean{$ENDIF};

    FDecoder: TFFDecoder;
    FFFmpegList: TFFmpegList;

    FCompleteTasks: Integer;
    FCurrentTask: Integer;
    FPendingTasks: Integer;
    FTerminated: Boolean;
    FThreadMode: Boolean;
    FWorking: Boolean;
    FPaused: Boolean;

    procedure CheckWorking(const AOperation: string);
    procedure StartNext;
{$IFDEF ACTIVEX}
    procedure CallInputVideoHook;
    procedure CallOutputVideoHook;
    procedure CallInputFrameHook;
    procedure CallOutputFrameHook;
{$ENDIF}
    procedure DoInputAudioHook(Sender: TObject; const APTS: Int64; ASample: PByte;
      ASize, ASampleRate, AChannels: Integer; ASampleFormat: TAVSampleFormat);
    procedure DoOutputAudioHook(Sender: TObject; const APTS: Int64; ASample: PByte;
      ASize, ASampleRate, AChannels: Integer; ASampleFormat: TAVSampleFormat);
    procedure CallBeforeFindStreamInfo;
    procedure DoBeforeFindStreamInfo(Sender: TObject; ic: PAVFormatContext);
    procedure DoInputVideoHook(Sender: TObject; ABitmap: {$IFDEF ACTIVEX}PBitmap{$ELSE}TBitmap{$ENDIF};
      AFrameNumber: Integer; const APTS: Int64; var AUpdate, AStopHook: Boolean); virtual;
    procedure DoOutputVideoHook(Sender: TObject; ABitmap: {$IFDEF ACTIVEX}PBitmap{$ELSE}TBitmap{$ENDIF};
      AFrameNumber: Integer; const APTS: Int64; var AUpdate, AStopHook: Boolean); virtual;
    procedure DoInputFrameHook(Sender: TObject; APicture: PAVPicture; APixFmt: TAVPixelFormat;
      AFrameNumber, AWidth, AHeight: Integer; const APTS: Int64); virtual;
    procedure DoOutputFrameHook(Sender: TObject; APicture: PAVPicture; APixFmt: TAVPixelFormat;
      AFrameNumber, AWidth, AHeight: Integer; const APTS: Int64); virtual;
    procedure CallPreviewBitmap;
    procedure DoPreviewBitmap(Sender: TObject; ABitmap: TBitmap;
      AFrameNumber: Integer; const APTS: Int64); virtual;
    procedure CallProgress;
    procedure DoProgress(Sender: TObject; AFileIndex, AFrameNumber, AFPS: Integer;
      const AQuality, ABitRate: Single; const ACurrentSize, ACurrentDuration, ATotalDuration: Int64); virtual;
    procedure DoTerminate(Sender: TObject); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetLicenseKey(AKey: AnsiString);

    function AVLibLoaded: Boolean;
    function LoadAVLib(const APath: TPathFileName): Boolean;
    procedure UnloadAVLib;

    function AddTask(const AFileName: TPathFileName; AOptions: PInputOptions = nil): Integer; overload;
    function AddTask(const AFileName: TPathFileName; AOptions, APresets: AnsiString): Integer; overload;
    function AddTask(AStream: TStream; APrivateData: AnsiString; AOptions: PInputOptions = nil): Integer; overload;
    function AddTask(AStream: TStream; APrivateData, AOptions, APresets: AnsiString): Integer; overload;
    function AddInput(ATaskIndex: Integer; const AFileName: TPathFileName; AOptions: PInputOptions = nil): Integer; overload;
    function AddInput(ATaskIndex: Integer; const AFileName: TPathFileName; AOptions, APresets: AnsiString): Integer; overload;
    function AddInput(ATaskIndex: Integer; AStream: TStream; APrivateData: AnsiString; AOptions: PInputOptions = nil): Integer; overload;
    function AddInput(ATaskIndex: Integer; AStream: TStream; APrivateData, AOptions, APresets: AnsiString): Integer; overload;
    function SetOutput(ATaskIndex: Integer; const AFileName: TPathFileName; AOptions: POutputOptions = nil): Integer; overload;
    function SetOutput(ATaskIndex: Integer; const AFileName: TPathFileName; AOptions, APresets: AnsiString): Integer; overload;
    function SetOutput(ATaskIndex: Integer; AStream: TStream; APrivateData: AnsiString; AOptions: POutputOptions = nil): Integer; overload;
    function SetOutput(ATaskIndex: Integer; AStream: TStream; APrivateData, AOptions, APresets: AnsiString): Integer; overload;

    function InitTask(ATaskIndex: Integer): Boolean;
    function SendFilterCommand(ATaskIndex: Integer; target, cmd, arg: string; flags: Integer): Boolean;
    function QueueFilterCommand(ATaskIndex: Integer; target, cmd, arg: string; flags: Integer; pts: Double): Boolean;

    procedure ClearTasks;
    procedure Exchange(ATaskIndex1, ATaskIndex2: Integer);
    procedure RemoveTask(ATaskIndex: Integer);
    function GetTaskIndex(AFFmpeg: TFFmpeg): Integer;

    procedure Start(AThreadCount: Integer = 0);
    procedure Pause;
    procedure Resume;
    procedure Stop(AWaitForStop: Boolean = True);

    property Decoder: TFFDecoder read FDecoder;
    property Decoders[TaskIndex, FileIndex: Integer]: TFFDecoder read GetDecoders;
    property FFmpegs[TaskIndex: Integer]: TFFmpeg read GetFFmpegs;

    property InputCount[TaskIndex: Integer]: Integer read GetInputCount;
    property InputFiles[TaskIndex, FileIndex: Integer]: PAVFormatContext read GetInputFiles;
    property InputOptions[TaskIndex, FileIndex: Integer]: TInputOptions read GetInputOptions;
    property LastErrMsg: string read FLastErrMsg{$IFDEF ACTIVEX} write FLastErrMsg{$ENDIF};
    property OutputFiles[TaskIndex, FileIndex: Integer]: PAVFormatContext read GetOutputFiles;
    property OutputOptions[TaskIndex, FileIndex: Integer]: TOutputOptions read GetOutputOptions;
    property TasksCount: Integer read GetTasksCount;

    property HaltOnInvalidOption: Boolean read FHaltOnInvalidOption write FHaltOnInvalidOption default True;
    property Preview: Boolean read FPreview write SetPreview default False;
    property PreviewBitmap: Boolean read FPreviewBitmap write SetPreviewBitmap default False;
    property ProgressInterval: Integer read FProgressInterval write SetProgressInterval default CReportInterval;
    property Terminated: Boolean read FTerminated;
    property ThreadPriority: TThreadPriority read FThreadPriority write FThreadPriority default tpNormal;
    property TriggerEventInMainThread: Boolean read FTriggerEventInMainThread write FTriggerEventInMainThread default True;
    property UserData: Pointer read FData write FData;
    property Working: Boolean read FWorking;
    property Paused: Boolean read FPaused;

    property OnAudioInputHook: TAudioHookEvent read FOnInputAudioHook write FOnInputAudioHook;
    property OnAudioOutputHook: TAudioHookEvent read FOnOutputAudioHook write FOnOutputAudioHook;
    property OnBeforeFindStreamInfo: TBeforeFindStreamInfoEvent read FOnBeforeFindStreamInfo write FOnBeforeFindStreamInfo;
    property OnPreviewBitmap: TPreviewBitmapEvent read FOnPreviewBitmap write FOnPreviewBitmap;
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    property OnTerminate: TTerminateEvent read FOnTerminate write FOnTerminate;
    property OnVideoInputHook: TVideoHookEvent read FOnInputVideoHook write FOnInputVideoHook;
    property OnVideoOutputHook: TVideoHookEvent read FOnOutputVideoHook write FOnOutputVideoHook;
    property OnFrameInputHook: TFrameHookEvent read FOnInputFrameHook write FOnInputFrameHook;
    property OnFrameOutputHook: TFrameHookEvent read FOnOutputFrameHook write FOnOutputFrameHook;
  end;

  TFFEncoder = class(TCustomEncoder)
  published
    property Preview;
    property PreviewBitmap;
    property ProgressInterval;
    property ThreadPriority;
    property TriggerEventInMainThread;

    property OnAudioInputHook;
    property OnAudioOutputHook;
    property OnBeforeFindStreamInfo;
    property OnPreviewBitmap;
    property OnProgress;
    property OnTerminate;
    property OnVideoInputHook;
    property OnVideoOutputHook;
    property OnFrameInputHook;
    property OnFrameOutputHook;
  end;

procedure InitInputOptions(P: PInputOptions);
procedure InitOutputOptions(P: POutputOptions);

implementation

uses
  FFLoad,
  FFLog;

{$IFDEF NEED_IDE}
  {$I Z_INIDE.inc}
{$ENDIF}

procedure InitInputOptions(P: PInputOptions);
begin
  with P^ do
  begin
    FileName := '';
    Options := '';
    Presets := '';
    Tag := 0;
    Data := nil;
  end;
end;

procedure InitOutputOptions(P: POutputOptions);
begin
  with P^ do
  begin
    FileName := '';
    Options := '';
    Presets := '';
    AudioInputHook := False;
    AudioOutputHook := False;
    VideoInputHook := False;
    VideoOutputHook := False;
    VideoHookBitsPixel := 32;
    FrameInputHook := False;
    FrameOutputHook := False;
    Join := False;
    Tag := 0;
    Data := nil;
  end;
end;

{ TFFmpeg }

constructor TFFmpeg.Create;
begin
  inherited Create;
  FParent := nil;
end;

destructor TFFmpeg.Destroy;
var
  I: Integer;
begin
  Self.OnInputAudioHook := nil;
  Self.OnOutputAudioHook := nil;
  Self.OnPreviewBitmap := nil;
  Self.OnProgress := nil;
  Self.OnTerminate := nil;
  Self.OnInputVideoHook := nil;
  Self.OnOutputVideoHook := nil;
  for I := 0 to High(FDecoders) do
    if Assigned(FDecoders[I]) then
      FreeAndNil(FDecoders[I]);
  for I := 0 to High(FInputOptions) do
    if Assigned(FInputOptions[I]) then
    begin
      InitInputOptions(FInputOptions[I]);
      Dispose(FInputOptions[I]);
      FInputOptions[I] := nil;
    end;
  for I := 0 to High(FOutputOptions) do
  begin
    if Assigned(FOutputOptions[I]) then
    begin
      InitOutputOptions(FOutputOptions[I]);
      Dispose(FOutputOptions[I]);
      FOutputOptions[I] := nil;
    end;
  end;
  SetLength(FDecoders, 0);
  SetLength(FInputOptions, 0);
  SetLength(FOutputOptions, 0);
{$IFDEF ACTIVEX}
  SetLength(FInputParameters, 0);
  SetLength(FOutputParameters, 0);
{$ENDIF}
  inherited Destroy;
end;

function TFFmpeg.GetDecoder(FileIndex: Integer): TFFDecoder;
begin
  if FileIndex > High(FDecoders) then
    SetLength(FDecoders, FileIndex + 1);
  if not Assigned(FDecoders[FileIndex]) then
  begin
    FDecoders[FileIndex] := TFFDecoder.Create(nil);
    FDecoders[FileIndex].ParentKey(FParent);
  end;
  Result := FDecoders[FileIndex];
end;

function TFFmpeg.GetInputCount: Integer;
begin
  Result := Fnb_input_files;
end;

function TFFmpeg.GetInputOptions(FileIndex: Integer): TInputOptions;
begin
  if FileIndex > High(FInputOptions) then
    SetLength(FInputOptions, FileIndex + 1);
  if not Assigned(FInputOptions[FileIndex]) then
  begin
    New(FInputOptions[FileIndex]);
    InitInputOptions(FInputOptions[FileIndex]);
  end;
  Result := FInputOptions[FileIndex]^;
end;

procedure TFFmpeg.SetInputOptions(FileIndex: Integer; const Value: TInputOptions);
begin
  if FileIndex > High(FInputOptions) then
    SetLength(FInputOptions, FileIndex + 1);
  if not Assigned(FInputOptions[FileIndex]) then
  begin
    New(FInputOptions[FileIndex]);
    InitInputOptions(FInputOptions[FileIndex]);
  end;
  FInputOptions[FileIndex]^ := Value;
end;

function TFFmpeg.GetOutputOptions(FileIndex: Integer): TOutputOptions;
begin
  if FileIndex > High(FOutputOptions) then
    SetLength(FOutputOptions, FileIndex + 1);
  if not Assigned(FOutputOptions[FileIndex]) then
  begin
    New(FOutputOptions[FileIndex]);
    InitOutputOptions(FOutputOptions[FileIndex]);
  end;
  Result := FOutputOptions[FileIndex]^;
end;

procedure TFFmpeg.SetOutputOptions(FileIndex: Integer; const Value: TOutputOptions);
begin
  if FileIndex > High(FOutputOptions) then
    SetLength(FOutputOptions, FileIndex + 1);
  if not Assigned(FOutputOptions[FileIndex]) then
  begin
    New(FOutputOptions[FileIndex]);
    InitOutputOptions(FOutputOptions[FileIndex]);
  end;
  FOutputOptions[FileIndex]^ := Value;
end;

procedure TFFmpeg.ClearInputOptions(FileIndex: Integer);
begin
  if FileIndex > High(FInputOptions) then
    SetLength(FInputOptions, FileIndex + 1);
  if Assigned(FInputOptions[FileIndex]) then
    InitInputOptions(FInputOptions[FileIndex]);
end;

procedure TFFmpeg.ClearOutputOptions(FileIndex: Integer);
begin
  if FileIndex > High(FOutputOptions) then
    SetLength(FOutputOptions, FileIndex + 1);
  if Assigned(FOutputOptions[FileIndex]) then
    InitOutputOptions(FOutputOptions[FileIndex]);
end;

{$IFDEF ACTIVEX}
function TFFmpeg.GetInputParameters(FileIndex: Integer): WideString;
begin
  if FileIndex > High(FInputParameters) then
    SetLength(FInputParameters, FileIndex + 1);
  Result := FInputParameters[FileIndex];
end;

procedure TFFmpeg.SetInputParameters(FileIndex: Integer; const Value: WideString);
begin
  if FileIndex > High(FInputParameters) then
    SetLength(FInputParameters, FileIndex + 1);
  FInputParameters[FileIndex] := Value;
end;

function TFFmpeg.GetOutputParameters(FileIndex: Integer): WideString;
begin
  if FileIndex > High(FOutputParameters) then
    SetLength(FOutputParameters, FileIndex + 1);
  Result := FOutputParameters[FileIndex];
end;

procedure TFFmpeg.SetOutputParameters(FileIndex: Integer; const Value: WideString);
begin
  if FileIndex > High(FOutputParameters) then
    SetLength(FOutputParameters, FileIndex + 1);
  FOutputParameters[FileIndex] := Value;
end;
{$ENDIF}

{ TFFmpegList }

constructor TFFmpegList.Create;
begin
  FList := TList.Create;
end;

destructor TFFmpegList.Destroy;
begin
  Clear;
  FreeAndNil(FList);
  inherited;
end;

function TFFmpegList.Add(Item: TFFmpeg): Integer;
begin
  Result := FList.Add(Item);
end;

procedure TFFmpegList.Clear;
var
  I: Integer;
begin
  with FList do
  begin
    for I := 0 to Count - 1 do
      TObject(Items[I]).Free;
    Clear;
  end;
end;

procedure TFFmpegList.Delete(Index: Integer);
begin
  with FList do
  begin
    TObject(Items[Index]).Free;
    Delete(Index);
  end;
end;

procedure TFFmpegList.Exchange(Index1, Index2: Integer);
begin
  FList.Exchange(Index1, Index2);
end;

function TFFmpegList.First: TFFmpeg;
begin
  Result := FList.First;
end;

function TFFmpegList.Get(Index: Integer): TFFmpeg;
begin
  Result := FList.Items[Index];
end;

function TFFmpegList.IndexOf(Item: TFFmpeg): Integer;
begin
  Result := FList.IndexOf(Item);
end;

function TFFmpegList.Last: TFFmpeg;
begin
  Result := FList.Last;
end;

function TFFmpegList.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TFFmpegList.Remove(Item: TFFmpeg): Integer;
begin
  Result := IndexOf(Item);
  if Result >= 0 then
    Delete(Result);
end;

procedure TFFmpegList.Pause;
var
  I: Integer;
begin
  with FList do
    for I := 0 to Count - 1 do
      TFFmpeg(Items[I]).Pause;
end;

procedure TFFmpegList.Resume;
var
  I: Integer;
begin
  with FList do
    for I := 0 to Count - 1 do
      TFFmpeg(Items[I]).Resume;
end;

procedure TFFmpegList.Stop(AWaitForStop: Boolean);
var
  I: Integer;
begin
  with FList do
    for I := 0 to Count - 1 do
      TFFmpeg(Items[I]).StopAndDoTerminate(AWaitForStop);
end;

procedure TFFmpegList.SetPreview(AValue: Boolean);
var
  I: Integer;
  LPostHooks: TPostHooks;
begin
  with FList do
    for I := 0 to Count - 1 do
    begin
      LPostHooks := TFFmpeg(Items[I]).PostHooks;
      if AValue then
        Include(LPostHooks, phPreview)
      else
        Exclude(LPostHooks, phPreview);
      TFFmpeg(Items[I]).PostHooks := LPostHooks;
    end;
end;

procedure TFFmpegList.SetPreviewBitmap(AValue: Boolean);
var
  I: Integer;
  LPostHooks: TPostHooks;
begin
  with FList do
    for I := 0 to Count - 1 do
    begin
      LPostHooks := TFFmpeg(Items[I]).PostHooks;
      if AValue then
        Include(LPostHooks, phBitmap)
      else
        Exclude(LPostHooks, phBitmap);
      TFFmpeg(Items[I]).PostHooks := LPostHooks;
    end;
end;

{ TCustomEncoder }

constructor TCustomEncoder.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FAudioHookLock := TCriticalSection.Create;
  FPreviewLock := TCriticalSection.Create;
  FProgressLock := TCriticalSection.Create;
  FTerminateLock := TCriticalSection.Create;
  FVideoHookLock := TCriticalSection.Create;
  FFrameHookLock := TCriticalSection.Create;
  FFindStreamLock := TCriticalSection.Create;

  FDecoder := TFFDecoder.Create(nil);
  FDecoder.ParentKey(Self);
  FFFmpegList := TFFmpegList.Create;

  FCompleteTasks := 0;
  FCurrentTask := -1;
  FPendingTasks := 0;
  FTerminated := False;
  FThreadMode := False;
  FWorking := False;
  FPaused := False;

  FHaltOnInvalidOption := True;
  FPreview := False;
  FPreviewBitmap := False;
  FProgressInterval := CReportInterval;
  FThreadPriority := tpNormal;
  FTriggerEventInMainThread := True;
end;

destructor TCustomEncoder.Destroy;
begin
  Self.OnAudioInputHook := nil;
  Self.OnAudioOutputHook := nil;
  Self.OnPreviewBitmap := nil;
  Self.OnProgress := nil;
  Self.OnTerminate := nil;
  Self.OnVideoInputHook := nil;
  Self.OnVideoOutputHook := nil;
  Self.OnFrameInputHook := nil;
  Self.OnFrameOutputHook := nil;
  FAudioHookLock.Free;
  FPreviewLock.Free;
  FProgressLock.Free;
  FTerminateLock.Free;
  FVideoHookLock.Free;
  FFrameHookLock.Free;
  FFindStreamLock.Free;
  FreeAndNil(FFFmpegList);
  FreeAndNil(FDecoder);
  inherited Destroy;
end;

function TCustomEncoder.AVLibLoaded: Boolean;
begin
  Result := FFLoader.Loaded(CEncoderLibraries);
end;

function TCustomEncoder.LoadAVLib(const APath: TPathFileName): Boolean;
begin
  if not (csDesigning in ComponentState) then
  begin
    FFLoader.LibraryPath := APath;
    Result := FFLoader.Load(CEncoderLibraries);
    if not Result then
      FLastErrMsg := FFLoader.LastErrMsg;
  end
  else
    Result := True;
end;

procedure TCustomEncoder.UnloadAVLib;
begin
  FFLoader.Unload(CEncoderLibraries);
end;

procedure TCustomEncoder.SetLicenseKey(AKey: AnsiString);
begin
{$IFDEF NEED_KEY}
  FLicKey := AKey;
  FKey := LoadKey(FLicKey, FLic);
{$ENDIF}
end;

function TCustomEncoder.GetDecoders(TaskIndex, FileIndex: Integer): TFFDecoder;
begin
  Result := FFFmpegList.Items[TaskIndex].FDecoders[FileIndex];
end;

function TCustomEncoder.GetFFmpegs(Index: Integer): TFFmpeg;
begin
  Result := FFFmpegList.Items[Index];
end;

function TCustomEncoder.GetInputCount(TaskIndex: Integer): Integer;
begin
  Result := FFFmpegList.Items[TaskIndex].Fnb_input_files;
end;

function TCustomEncoder.GetInputFiles(TaskIndex, FileIndex: Integer): PAVFormatContext;
begin
  Result := PPtrIdx(FFFmpegList.Items[TaskIndex].Finput_files, FileIndex).ctx;
end;

function TCustomEncoder.GetInputOptions(TaskIndex, FileIndex: Integer): TInputOptions;
begin
  Result := FFFmpegList.Items[TaskIndex].InputOptions[FileIndex];
end;

function TCustomEncoder.GetOutputFiles(TaskIndex, FileIndex: Integer): PAVFormatContext;
begin
  Result := FFFmpegList.Items[TaskIndex].Get_output_files(FileIndex);
end;

function TCustomEncoder.GetOutputOptions(TaskIndex, FileIndex: Integer): TOutputOptions;
begin
  Result := FFFmpegList.Items[TaskIndex].OutputOptions[FileIndex];
end;

function TCustomEncoder.GetTasksCount: Integer;
begin
  Result := FFFmpegList.Count;
end;

procedure TCustomEncoder.SetPreview(const Value: Boolean);
begin
  FFFmpegList.SetPreview(Value);
  FPreview := Value;
end;

procedure TCustomEncoder.SetPreviewBitmap(const Value: Boolean);
begin
  FFFmpegList.SetPreviewBitmap(Value);
  FPreviewBitmap := Value;
end;

procedure TCustomEncoder.SetProgressInterval(const Value: Integer);
begin
  if Value > 100 then
    FProgressInterval := Value
  else
    FProgressInterval := 100;
end;

procedure TCustomEncoder.CheckWorking(const AOperation: string);
begin
  if FWorking then
    raise Exception.CreateFmt('Cannot %s while working.', [AOperation]);
end;

function TCustomEncoder.AddTask(const AFileName: TPathFileName;
  AOptions: PInputOptions): Integer;
var
  F: TFFmpeg;
  LPostHooks: TPostHooks;
  LOptions, LPresets: AnsiString;
  optctx: TOptionsContext;
begin
  if not AVLibLoaded then
    raise Exception.Create('FFmpeg libraries not loaded.');
  CheckWorking('AddTask');
  F := TFFmpeg.Create;
  try
    F.InitOptionDef;
    F.OnBeforeFindStreamInfo := Self.DoBeforeFindStreamInfo;
    F.OnPreviewBitmap := Self.DoPreviewBitmap;
    F.FParent := Self;
{$IFDEF NEED_KEY}
    F.FLic := FLic;
{$ENDIF}

    LPostHooks := F.PostHooks;
    if FPreview then
      Include(LPostHooks, phPreview)
    else
      Exclude(LPostHooks, phPreview);
    if FPreviewBitmap then
      Include(LPostHooks, phBitmap)
    else
      Exclude(LPostHooks, phBitmap);
    F.PostHooks := LPostHooks;
    F.FLastErrMsg := '';
    F.HaltOnInvalidOption := FHaltOnInvalidOption;
    F.FReadTimeout := FReadTimeout;
    F.FWriteTimeout := FWriteTimeout;

    if AOptions <> nil then
    begin
      if AOptions.FileName = '' then
        AOptions.FileName := AFileName;
      F.InputOptions[F.Fnb_input_files] := AOptions^;
      LOptions := AOptions.Options;
      LPresets := AOptions.Presets;
    end
    else
    begin
      F.ClearInputOptions(F.Fnb_input_files);
      LOptions := '';
      LPresets := '';
    end;

    F.init_options(@optctx);
    try
      Result := F.open_input_file(@optctx, LOptions, LPresets, AFileName);
    finally
      F.uninit_options(@optctx);
    end;

    if Result >= 0 then
    begin
      F.Decoders[F.Fnb_input_files - 1].FileHandle := PPtrIdx(F.Finput_files, F.Fnb_input_files - 1).ctx;
      F.OnProgress := Self.DoProgress;
      F.OnTerminate := Self.DoTerminate;
      Result := FFFmpegList.Add(F);
    end
    else
    begin
      FLastErrMsg := F.LastErrMsg;
      F.Free;
    end;
  except on E: Exception do
    begin
      Result := -1;
      FLastErrMsg := E.Message;
      F.Free;
    end;
  end;
end;

function TCustomEncoder.AddTask(const AFileName: TPathFileName;
  AOptions, APresets: AnsiString): Integer;
var
  IO: TInputOptions;
begin
  InitInputOptions(@IO);
  IO.FileName := AFileName;
  IO.Options := AOptions;
  IO.Presets := APresets;
  Result := AddTask(AFileName, @IO);
end;

function TCustomEncoder.AddTask(AStream: TStream; APrivateData: AnsiString;
  AOptions: PInputOptions): Integer;
begin
  Result := AddTask(Format('memory:%d:%s', [Integer(AStream), APrivateData]), AOptions);
end;

function TCustomEncoder.AddTask(AStream: TStream; APrivateData, AOptions, APresets: AnsiString): Integer;
begin
  Result := AddTask(Format('memory:%d:%s', [Integer(AStream), APrivateData]), AOptions, APresets);
end;

function TCustomEncoder.AddInput(ATaskIndex: Integer;
  const AFileName: TPathFileName; AOptions: PInputOptions): Integer;
var
  F: TFFmpeg;
  LOptions, LPresets: AnsiString;
  optctx: TOptionsContext;
begin
  CheckWorking('AddInput');
  F := FFFmpegList.Items[ATaskIndex];
  try
    F.FLastErrMsg := '';
    F.HaltOnInvalidOption := FHaltOnInvalidOption;
    F.FReadTimeout := FReadTimeout;
    F.FWriteTimeout := FWriteTimeout;

    if AOptions <> nil then
    begin
      if AOptions.FileName = '' then
        AOptions.FileName := AFileName;
      F.InputOptions[F.Fnb_input_files] := AOptions^;
      LOptions := AOptions.Options;
      LPresets := AOptions.Presets;
    end
    else
    begin
      F.ClearInputOptions(F.Fnb_input_files);
      LOptions := '';
      LPresets := '';
    end;

    F.init_options(@optctx);
    try
      Result := F.open_input_file(@optctx, LOptions, LPresets, AFileName);
    finally
      F.uninit_options(@optctx);
    end;

    if Result >= 0 then
      F.Decoders[F.Fnb_input_files - 1].FileHandle := PPtrIdx(F.Finput_files, F.Fnb_input_files - 1).ctx
    else
    begin
      F.ClearInputOptions(F.Fnb_input_files);
      FLastErrMsg := F.LastErrMsg;
    end;
  except on E: Exception do
    begin
      Result := -1;
      FLastErrMsg := E.Message;
    end;
  end;
end;

function TCustomEncoder.AddInput(ATaskIndex: Integer;
  const AFileName: TPathFileName; AOptions, APresets: AnsiString): Integer;
var
  IO: TInputOptions;
begin
  InitInputOptions(@IO);
  IO.FileName := AFileName;
  IO.Options := AOptions;
  IO.Presets := APresets;
  Result := AddInput(ATaskIndex, AFileName, @IO);
end;

function TCustomEncoder.AddInput(ATaskIndex: Integer; AStream: TStream; APrivateData: AnsiString; AOptions: PInputOptions): Integer;
begin
  Result := AddInput(ATaskIndex,
    Format('memory:%d:%s', [Integer(AStream), APrivateData]), AOptions);
end;

function TCustomEncoder.AddInput(ATaskIndex: Integer; AStream: TStream; APrivateData, AOptions, APresets: AnsiString): Integer;
begin
  Result := AddInput(ATaskIndex,
    Format('memory:%d:%s', [Integer(AStream), APrivateData]), AOptions, APresets);
end;

function TCustomEncoder.SetOutput(ATaskIndex: Integer;
  const AFileName: TPathFileName; AOptions: POutputOptions): Integer;
var
  F: TFFmpeg;
  LJoin: Boolean;
  LOptions, LPresets: AnsiString;
  S: string;
  optctx: TOptionsContext;
begin
  CheckWorking('SetOutput');
  F := FFFmpegList.Items[ATaskIndex];
  try
    F.FLastErrMsg := '';
    F.HaltOnInvalidOption := FHaltOnInvalidOption;
    F.FReadTimeout := FReadTimeout;
    F.FWriteTimeout := FWriteTimeout;

    if AOptions <> nil then
    begin
      if AOptions.FileName = '' then
        AOptions.FileName := AFileName;
      F.OutputOptions[F.Fnb_output_files] := AOptions^;

      if AOptions.AudioInputHook then
        F.OnInputAudioHook := Self.DoInputAudioHook;
      if AOptions.AudioOutputHook then
        F.OnOutputAudioHook := Self.DoOutputAudioHook;

      if AOptions.VideoInputHook then
        F.OnInputVideoHook := Self.DoInputVideoHook;
      if AOptions.VideoOutputHook then
        F.OnOutputVideoHook := Self.DoOutputVideoHook;
{$IFNDEF FFFMX}
      F.VideoHookBitsPixel := AOptions.VideoHookBitsPixel;
{$ENDIF}

      if AOptions.FrameInputHook then
        F.OnInputFrameHook := Self.DoInputFrameHook;
      if AOptions.FrameOutputHook then
        F.OnOutputFrameHook := Self.DoOutputFrameHook;

      LOptions := AOptions.Options;
      LPresets := AOptions.Presets;

      LJoin := AOptions.Join;
    end
    else
    begin
      F.ClearOutputOptions(F.Fnb_output_files);
      LOptions := '';
      LPresets := '';
      LJoin := False;
    end;

    F.init_options(@optctx);
    try
      S := ' ' + string(LOptions) + ' ';
      S := StringReplace(S, ' -audioinputhook ', ' -AudioInputHook ', [rfReplaceAll, rfIgnoreCase]);
      S := StringReplace(S, ' -audiooutputhook ', ' -AudioOutputHook ', [rfReplaceAll, rfIgnoreCase]);
      S := StringReplace(S, ' -videoinputhook ', ' -VideoInputHook ', [rfReplaceAll, rfIgnoreCase]);
      S := StringReplace(S, ' -videooutputhook ', ' -VideoOutputHook ', [rfReplaceAll, rfIgnoreCase]);
      S := StringReplace(S, ' -frameinputhook ', ' -FrameInputHook ', [rfReplaceAll, rfIgnoreCase]);
      S := StringReplace(S, ' -frameoutputhook ', ' -FrameOutputHook ', [rfReplaceAll, rfIgnoreCase]);
      S := StringReplace(S, ' -join ', ' -Join ', [rfReplaceAll, rfIgnoreCase]);
      LOptions := AnsiString(Trim(S));
      Result := F.open_output_file(@optctx, LOptions, LPresets, AFileName, LJoin);
    finally
      F.uninit_options(@optctx);
    end;

    if Result < 0 then
    begin
      FLastErrMsg := F.LastErrMsg;
      F.ClearOutputOptions(F.Fnb_output_files);
    end;
  except on E: Exception do
    begin
      Result := -1;
      FLastErrMsg := E.Message;
      if F.FLastErrMsg <> '' then
        FLastErrMsg := F.FLastErrMsg + sLineBreak + FLastErrMsg;
      Exit;
    end;
  end;
end;

function TCustomEncoder.SetOutput(ATaskIndex: Integer;
  const AFileName: TPathFileName; AOptions, APresets: AnsiString): Integer;
var
  OO: TOutputOptions;
  S: string;
begin
  S := ' ' + LowerCase(string(AOptions)) + ' ';
  InitOutputOptions(@OO);
  OO.AudioInputHook :=  Pos(' -audioinputhook ',  S) > 0;
  OO.AudioOutputHook := Pos(' -audiooutputhook ', S) > 0;
  OO.VideoInputHook :=  Pos(' -videoinputhook ',  S) > 0;
  OO.VideoOutputHook := Pos(' -videooutputhook ', S) > 0;
  OO.FrameInputHook :=  Pos(' -frameinputhook ',  S) > 0;
  OO.FrameOutputHook := Pos(' -frameoutputhook ', S) > 0;
  OO.Join :=            Pos(' -join ',            S) > 0;
  OO.Options := AOptions;
  OO.Presets := APresets;
  Result := SetOutput(ATaskIndex, AFileName, @OO);
end;

function TCustomEncoder.SetOutput(ATaskIndex: Integer;
  AStream: TStream; APrivateData: AnsiString; AOptions: POutputOptions): Integer;
begin
  Result := SetOutput(ATaskIndex,
    Format('memory:%d:%s', [Integer(AStream), APrivateData]), AOptions);
end;

function TCustomEncoder.SetOutput(ATaskIndex: Integer;
  AStream: TStream; APrivateData, AOptions, APresets: AnsiString): Integer;
begin
  Result := SetOutput(ATaskIndex,
    Format('memory:%d:%s', [Integer(AStream), APrivateData]), AOptions, APresets);
end;

function TCustomEncoder.InitTask(ATaskIndex: Integer): Boolean;
begin
  Result := FFFmpegList.Items[ATaskIndex].do_transcode_init;
end;

function TCustomEncoder.SendFilterCommand(ATaskIndex: Integer; target, cmd, arg: string; flags: Integer): Boolean;
begin
  Result := InitTask(ATaskIndex) and FFFmpegList.Items[ATaskIndex].SendFilterCommand(target, cmd, arg, flags);
end;

function TCustomEncoder.QueueFilterCommand(ATaskIndex: Integer; target, cmd, arg: string; flags: Integer; pts: Double): Boolean;
begin
  Result := InitTask(ATaskIndex) and FFFmpegList.Items[ATaskIndex].QueueFilterCommand(target, cmd, arg, flags, pts);
end;

procedure TCustomEncoder.ClearTasks;
begin
  if FWorking and not FTerminated then
    raise Exception.Create('Cannot ClearTasks while working.');
  FFFmpegList.Clear;
  FLastErrMsg := '';
  FCompleteTasks := 0;
  FCurrentTask := -1;
  FPendingTasks := 0;
  FTerminated := False;
  FThreadMode := False;
  FWorking := False;
  FPaused := False;
end;

procedure TCustomEncoder.Exchange(ATaskIndex1, ATaskIndex2: Integer);
begin
  CheckWorking('Exchange');
  FFFmpegList.Exchange(ATaskIndex1, ATaskIndex2);
end;

procedure TCustomEncoder.RemoveTask(ATaskIndex: Integer);
begin
  CheckWorking('RemoveTask');
  FFFmpegList.Delete(ATaskIndex);
end;

function TCustomEncoder.GetTaskIndex(AFFmpeg: TFFmpeg): Integer;
begin
  Result := FFFmpegList.IndexOf(AFFmpeg);
end;

procedure TCustomEncoder.Start(AThreadCount: Integer);
var
  I: Integer;
begin
  CheckWorking('StartTask');
{$IFDEF NEED_IDE}
  if not ISDP{INIDE} or not INTD{INIDE5} then
    CheckShowAbout;
{$ELSE}
{$IFDEF NEED_ABOUT}
    CheckShowAbout;
{$ENDIF}
{$ENDIF}
{$IFDEF NEED_KEY}
  NeedKey(FLicKey);
  if not FKey then
  begin
    DoTerminate(nil);
    Exit;
  end;
  if (AThreadCount > 0) and (FFFmpegList.Count > 2) then
    _CK4(FLic);
{$ENDIF}
  FCompleteTasks := 0;
  FCurrentTask := 0;
  FPendingTasks := FFFmpegList.Count;
  FTerminated := False;
  FThreadMode := AThreadCount > 0;
  FWorking := True;
  FPaused := False;

  I := AThreadCount;
  while FPendingTasks > 0 do
  begin
    StartNext;
    if not FThreadMode then
      Continue;
    Dec(I);
    if I <= 0 then
      Break;
  end;
{$IFDEF NEED_KEY}
  if FKey then
  begin
    if Round(Now) mod 2 = 0 then
    begin
      if not _CKF(FLic, CFEncoder) then
      begin
        FLicKey := '';
        FKey := False;
      end;
    end
    else
      _CKP(FLic, {$IFDEF ACTIVEX}CPActiveX{$ELSE}CPFFVCL{$ENDIF});
  end;
{$ENDIF}
end;

procedure TCustomEncoder.Pause;
begin
  if FWorking and not FPaused then
  begin
    FFFmpegList.Pause;
    FPaused := True;
  end;
end;

procedure TCustomEncoder.Resume;
begin
  if FWorking and FPaused then
  begin
    FFFmpegList.Resume;
    FPaused := False;
  end;
end;

procedure TCustomEncoder.Stop(AWaitForStop: Boolean);
begin
  FPendingTasks := 0;
  if FWorking then
    FFFmpegList.Stop(AWaitForStop);
end;

procedure TCustomEncoder.StartNext;
var
  LThread: TThread;
begin
  if FPendingTasks > 0 then
  begin
    Dec(FPendingTasks);
    with FFFmpegList.Items[FCurrentTask] do
    begin
      ReportInterval := FProgressInterval * 1000; // milliseconds -> microseconds
      if FThreadMode then
      begin
        LThread := StartConvert(FThreadMode, FThreadPriority);
        if Assigned(LThread) then
{$WARN SYMBOL_DEPRECATED OFF}
          LThread.Resume;
{$WARN SYMBOL_DEPRECATED ON}
      end
      else
        StartConvert(FThreadMode, FThreadPriority);
    end;
    Inc(FCurrentTask);
  end;
end;

procedure TCustomEncoder.DoInputAudioHook(Sender: TObject; const APTS: Int64; ASample: PByte;
  ASize, ASampleRate, AChannels: Integer; ASampleFormat: TAVSampleFormat);
begin
  if Assigned(FOnInputAudioHook) then
  begin
    FAudioHookLock.Acquire;
    try
      FOnInputAudioHook(Self, FFFmpegList.IndexOf(Sender as TFFmpeg),
        APTS, ASample, ASize, ASampleRate, AChannels, ASampleFormat);
    finally
      FAudioHookLock.Release;
    end;
  end;
end;

procedure TCustomEncoder.DoOutputAudioHook(Sender: TObject; const APTS: Int64; ASample: PByte;
  ASize, ASampleRate, AChannels: Integer; ASampleFormat: TAVSampleFormat);
begin
  if Assigned(FOnOutputAudioHook) then
  begin
    FAudioHookLock.Acquire;
    try
      FOnOutputAudioHook(Self, FFFmpegList.IndexOf(Sender as TFFmpeg),
        APTS, ASample, ASize, ASampleRate, AChannels, ASampleFormat);
    finally
      FAudioHookLock.Release;
    end;
  end;
end;

procedure TCustomEncoder.CallBeforeFindStreamInfo;
begin
  if Assigned(FOnBeforeFindStreamInfo) then
    FOnBeforeFindStreamInfo(FSender, FAVFormatContext);
end;

procedure TCustomEncoder.DoBeforeFindStreamInfo(Sender: TObject; ic: PAVFormatContext);
begin
  if Assigned(FOnBeforeFindStreamInfo) then
  begin
    FFindStreamLock.Acquire;
    try
      FSender := Sender;
      FAVFormatContext := ic;
      if FTriggerEventInMainThread then
        MySynchronize(CallBeforeFindStreamInfo)
      else
        CallBeforeFindStreamInfo;
    finally
      FFindStreamLock.Release;
    end;
  end;
end;

{$IFDEF ACTIVEX}
procedure TCustomEncoder.CallInputVideoHook;
begin
  if Assigned(FOnInputVideoHook) then
    FOnInputVideoHook(Self, @FVideoHookInfo);
end;

procedure TCustomEncoder.CallOutputVideoHook;
begin
  if Assigned(FOnOutputVideoHook) then
    FOnOutputVideoHook(Self, @FVideoHookInfo);
end;

procedure TCustomEncoder.CallInputFrameHook;
begin
  if Assigned(FOnInputFrameHook) then
    FOnInputFrameHook(Self, @FFrameHookInfo);
end;

procedure TCustomEncoder.CallOutputFrameHook;
begin
  if Assigned(FOnOutputFrameHook) then
    FOnOutputFrameHook(Self, @FFrameHookInfo);
end;
{$ENDIF}

procedure TCustomEncoder.DoInputVideoHook(Sender: TObject; ABitmap: {$IFDEF ACTIVEX}PBitmap{$ELSE}TBitmap{$ENDIF};
  AFrameNumber: Integer; const APTS: Int64; var AUpdate, AStopHook: Boolean);
begin
  if Assigned(FOnInputVideoHook) then
  begin
    FVideoHookLock.Acquire;
    try
      with FVideoHookInfo do
      begin
        TaskIndex := FFFmpegList.IndexOf(Sender as TFFmpeg);
        Bitmap := ABitmap;
        FrameNumber := AFrameNumber;
        PTS := APTS;
        Update := AUpdate;
        StopHook := AStopHook;
      end;
{$IFDEF ACTIVEX}
      MySynchronize(CallInputVideoHook);
{$ELSE}
{$IFDEF FFFMX}
      ABitmap.Canvas.BeginScene;
{$ELSE}
      ABitmap.Canvas.Lock;
{$ENDIF}
      try
        // TODO: do we need FTriggerEventInMainThread/MySynchronize?
        FOnInputVideoHook(Self, @FVideoHookInfo);
      finally
{$IFDEF FFFMX}
        ABitmap.Canvas.EndScene;
{$ELSE}
        ABitmap.Canvas.Unlock;
{$ENDIF}
      end;
{$ENDIF}
      with FVideoHookInfo do
      begin
        AUpdate := Update;
        AStopHook := StopHook;
      end;
    finally
      FVideoHookLock.Release;
    end;
  end;
end;

procedure TCustomEncoder.DoOutputVideoHook(Sender: TObject; ABitmap: {$IFDEF ACTIVEX}PBitmap{$ELSE}TBitmap{$ENDIF};
  AFrameNumber: Integer; const APTS: Int64; var AUpdate, AStopHook: Boolean);
begin
  if Assigned(FOnOutputVideoHook) then
  begin
    FVideoHookLock.Acquire;
    try
      with FVideoHookInfo do
      begin
        TaskIndex := FFFmpegList.IndexOf(Sender as TFFmpeg);
        Bitmap := ABitmap;
        FrameNumber := AFrameNumber;
        PTS := APTS;
        Update := AUpdate;
        StopHook := AStopHook;
      end;
{$IFDEF ACTIVEX}
      MySynchronize(CallOutputVideoHook);
{$ELSE}
{$IFDEF FFFMX}
      ABitmap.Canvas.BeginScene;
{$ELSE}
      ABitmap.Canvas.Lock;
{$ENDIF}
      try
        // TODO: do we need FTriggerEventInMainThread/MySynchronize?
        FOnOutputVideoHook(Self, @FVideoHookInfo);
      finally
{$IFDEF FFFMX}
        ABitmap.Canvas.EndScene;
{$ELSE}
        ABitmap.Canvas.Unlock;
{$ENDIF}
      end;
{$ENDIF}
      with FVideoHookInfo do
      begin
        AUpdate := Update;
        AStopHook := StopHook;
      end;
    finally
      FVideoHookLock.Release;
    end;
  end;
end;

procedure TCustomEncoder.DoInputFrameHook(Sender: TObject; APicture: PAVPicture;
  APixFmt: TAVPixelFormat; AFrameNumber, AWidth, AHeight: Integer;
  const APTS: Int64);
begin
  if Assigned(FOnInputFrameHook) then
  begin
    FFrameHookLock.Acquire;
    try
      with FFrameHookInfo do
      begin
        TaskIndex := FFFmpegList.IndexOf(Sender as TFFmpeg);
        Picture := APicture;
        PixFmt := APixFmt;
        FrameNumber := AFrameNumber;
        Width := AWidth;
        Height := AHeight;
        PTS := APTS;
      end;
{$IFDEF ACTIVEX}
      MySynchronize(CallInputFrameHook);
{$ELSE}
      // TODO: do we need FTriggerEventInMainThread/MySynchronize?
      FOnInputFrameHook(Self, @FFrameHookInfo);
{$ENDIF}
    finally
      FFrameHookLock.Release;
    end;
  end;
end;

procedure TCustomEncoder.DoOutputFrameHook(Sender: TObject; APicture: PAVPicture;
  APixFmt: TAVPixelFormat; AFrameNumber, AWidth, AHeight: Integer;
  const APTS: Int64);
begin
  if Assigned(FOnOutputFrameHook) then
  begin
    FFrameHookLock.Acquire;
    try
      with FFrameHookInfo do
      begin
        TaskIndex := FFFmpegList.IndexOf(Sender as TFFmpeg);
        Picture := APicture;
        PixFmt := APixFmt;
        FrameNumber := AFrameNumber;
        Width := AWidth;
        Height := AHeight;
        PTS := APTS;
      end;
{$IFDEF ACTIVEX}
      MySynchronize(CallOutputFrameHook);
{$ELSE}
      // TODO: do we need FTriggerEventInMainThread/MySynchronize?
      FOnOutputFrameHook(Self, @FFrameHookInfo);
{$ENDIF}
    finally
      FFrameHookLock.Release;
    end;
  end;
end;

procedure TCustomEncoder.CallPreviewBitmap;
begin
  if Assigned(FOnPreviewBitmap) then
    FOnPreviewBitmap(Self, FPreviewInfo);
end;

procedure TCustomEncoder.DoPreviewBitmap(Sender: TObject; ABitmap: TBitmap;
  AFrameNumber: Integer; const APTS: Int64);
begin
  if Assigned(FOnPreviewBitmap) then
  begin
    FPreviewLock.Acquire;
    try
      with FPreviewInfo do
      begin
        TaskIndex := FFFmpegList.IndexOf(Sender as TFFmpeg);
        Bitmap := ABitmap;
        FrameNumber := AFrameNumber;
        PTS := APTS;
      end;
      if FTriggerEventInMainThread then
        MySynchronize(CallPreviewBitmap)
      else
        CallPreviewBitmap;
    finally
      FPreviewLock.Release;
    end;
  end;
end;

procedure TCustomEncoder.CallProgress;
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self, @FProgressInfo);
end;

procedure TCustomEncoder.DoProgress(Sender: TObject;
  AFileIndex, AFrameNumber, AFPS: Integer; const AQuality, ABitRate: Single;
  const ACurrentSize, ACurrentDuration, ATotalDuration: Int64);
begin
  if Assigned(FOnProgress) then
  begin
    FProgressLock.Acquire;
    try
      with FProgressInfo do
      begin
        TaskIndex := FFFmpegList.IndexOf(Sender as TFFmpeg);
        FileIndex := AFileIndex;
        FrameNumber := AFrameNumber;
        FPS := AFPS;
        Quality := AQuality;
        BitRate := ABitRate;
        CurrentSize := ACurrentSize;
        CurrentDuration := ACurrentDuration;
        TotalDuration := ATotalDuration;
      end;
      if FTriggerEventInMainThread then
        MySynchronize(CallProgress)
      else
        CallProgress;
    finally
      FProgressLock.Release;
    end;
  end;
end;

type
  TDoTerminateThread = class(TThread)
  private
    FOnTerminate: TTerminateEvent;
    FSender: TObject;
    FTerminateInfo: TTerminateInfo;
    FThreadTerminated: {$IFDEF FPC}PBOOL{$ELSE}PBoolean{$ENDIF};
    FCheckThreadTerminated: Boolean;
    FTriggerEventInMainThread: Boolean;
  protected
    procedure CallTerminate;
    procedure Execute; override;
  public
    constructor Create(AOnTerminate: TTerminateEvent;
      ASender: TObject; ATerminateInfo: TTerminateInfo;
      AThreadTerminated: {$IFDEF FPC}PBOOL{$ELSE}PBoolean{$ENDIF}; ACheckThreadTerminated, ATriggerEventInMainThread: Boolean);
  end;

procedure TCustomEncoder.DoTerminate(Sender: TObject);
  procedure AllFinished;
  begin
    FTerminated := True;
    if Assigned(FOnTerminate) then
    begin
      with FTerminateInfo do
      begin
        TaskIndex := -1;
        Finished := True;
        Exception := False;
        ExceptionMsg := '';
      end;
      if not FThreadMode and FWorking then
        FOnTerminate(Self, FTerminateInfo)
      else
        TDoTerminateThread.Create(FOnTerminate, Self, FTerminateInfo, @FThreadTerminated, True, FTriggerEventInMainThread);
    end;
  end;
begin
  FTerminateLock.Acquire;
  try
    FThreadTerminated := True;
    if not Assigned(Sender) then
    begin
      AllFinished;
      Exit;
    end;

    if Assigned(FOnTerminate) then
    begin
      with Sender as TFFmpeg do
      begin
        FTerminateInfo.TaskIndex := FFFmpegList.IndexOf(Sender as TFFmpeg);
        FTerminateInfo.Finished := Finished;
        FTerminateInfo.Exception := FatalException;
        FTerminateInfo.ExceptionMsg := FatalMessage;
        if not FThreadMode and FWorking then
          FOnTerminate(Self, FTerminateInfo)
        else
        begin
          FThreadTerminated := False;
          TDoTerminateThread.Create(FOnTerminate, Self, FTerminateInfo, @FThreadTerminated, False, FTriggerEventInMainThread);
        end;
      end;
    end;

    Inc(FCompleteTasks);

    if FPendingTasks > 0 then
    begin
      if FThreadMode then
        StartNext;
    end
    else if FCompleteTasks >= FFFmpegList.Count then
      AllFinished;
  finally
    FTerminateLock.Release;
  end;
end;

{ TDoTerminateThread }

constructor TDoTerminateThread.Create(AOnTerminate: TTerminateEvent;
  ASender: TObject; ATerminateInfo: TTerminateInfo;
  AThreadTerminated: {$IFDEF FPC}PBOOL{$ELSE}PBoolean{$ENDIF}; ACheckThreadTerminated, ATriggerEventInMainThread: Boolean);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FOnTerminate := AOnTerminate;
  FSender := ASender;
  FTerminateInfo := ATerminateInfo;
  FThreadTerminated := AThreadTerminated;
  FCheckThreadTerminated := ACheckThreadTerminated;
{$IFDEF ACTIVEX}
  FTriggerEventInMainThread := True;
{$ELSE}
  FTriggerEventInMainThread := ATriggerEventInMainThread;
{$ENDIF}
end;

procedure TDoTerminateThread.CallTerminate;
begin
  if Assigned(FOnTerminate) then
    FOnTerminate(FSender, FTerminateInfo);
end;

procedure TDoTerminateThread.Execute;
begin
  if FCheckThreadTerminated then
    while not FThreadTerminated^ do
      Sleep(10);
  try
    if Assigned(FOnTerminate) then
      if FTriggerEventInMainThread then
        Synchronize(CallTerminate)
      else
        FOnTerminate(FSender, FTerminateInfo);
  finally
    FThreadTerminated^ := True;
  end;
end;

end.
