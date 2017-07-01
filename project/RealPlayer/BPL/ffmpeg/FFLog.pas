(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of ffmpeg logger.
 * Created by CodeCoolie@CNSW 2009/07/31 -> $Date:: 2013-11-18 #$
 *)

unit FFLog;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  {$IFDEF POSIX}
    FMX.Dialogs,
    Posix.Unistd, // DeleteFile -> unlink
  {$ENDIF}
  System.SysUtils,
  {$IFDEF VCL_XE4_OR_ABOVE}
    System.AnsiStrings, // StrLen
  {$ENDIF}
  System.Classes,
  System.SyncObjs,
  System.Math,
{$ELSE}
  Windows,
  SysUtils,
  Classes,
  SyncObjs,
  Math,
{$ENDIF}

  libavutil_log,
  MyUtils,
  AVUtilStubs,
  MyUtilStubs,
  FFBaseComponent;

type
  // refer to libavutil_log.pas or ffmpeg's (libavutil)log.h
  TLogLevel = (
    llQuiet,
    (**
     * Something went really wrong and we will crash now.
     *)
    llPanic,
    (**
     * Something went wrong and recovery is not possible.
     * For example, no header was found for a format which depends
     * on headers or an illegal combination of parameters is used.
     *)
    llFatal,
    (**
     * Something went wrong and cannot losslessly be recovered.
     * However, not all future data is affected.
     *)
    llError,
    (**
     * Something somehow does not look correct. This may or may not
     * lead to problems. An example would be the use of '-vstrict -2'.
     *)
    llWarning,
    llInfo,
    llVerbose,
    (**
     * Stuff which is only useful for libav* developers.
     *)
    llDebug
  );

  TLogEvent = procedure(Sender: TObject; AThreadID: Integer; // THandle;
    ALogLevel: TLogLevel; const ALogMsg: string) of object;

  TLogInfo = record
    Sender: TObject;
    ThreadID: THandle;
    LogLevel: TLogLevel;
    LogMsg: string;
  end;

  TFFLogger = class(TFFBaseComponent)
  private
    FAutoCreated: Boolean;
    FSkip: Boolean;
    FActive: Boolean;
    FTriggerEventInMainThread: Boolean;
    FLogFlags: Integer;
    FLogLevel: TLogLevel;
    FLogInfo: TLogInfo;
    FOnLog: TLogEvent;

    procedure UpdateSkip;
    procedure CallLogEvent;
    procedure CallLogToFile;
    procedure UpdateAVLogFlags;
    procedure UpdateAVLogLevel;
    procedure AVLog(AThreadID: THandle; ALogLevel: Integer; const ALogMsg: string);
    procedure SetLogFlags(const Value: Integer);
    procedure SetLogLevel(const Value: TLogLevel);
    function GetLogFile: string;
    function GetLogToFile: Boolean;
    procedure SetLogFile(const Value: string);
    procedure SetLogToFile(const Value: Boolean);
    procedure SetOnLog(const Value: TLogEvent);
    procedure SetActive(const Value: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure InstallAVLogCallback;
    procedure Log(Sender: TObject; ALogLevel: TLogLevel; const ALogMsg: string); overload;
    procedure Log(Sender: TObject; ALogLevel: TLogLevel; const AFormat: string;
      const Args: array of const); overload;
    procedure OptLogLevel(const arg: string);
    procedure ClearLogFile;
    property LogFlags: Integer read FLogFlags write SetLogFlags;
  published
    property Active: Boolean read FActive write SetActive default True;
    property LogLevel: TLogLevel read FLogLevel write SetLogLevel default llInfo;
    property LogFile: string read GetLogFile write SetLogFile;
    property LogToFile: Boolean read GetLogToFile write SetLogToFile default False;
    property TriggerEventInMainThread: Boolean read FTriggerEventInMainThread
      write FTriggerEventInMainThread default True;
    property OnLog: TLogEvent read FOnLog write SetOnLog;
  end;

// TLogLevel to Integer
function LogLevelToInt(ALogLevel: TLogLevel): Integer;
// Integer to TLogLevel
function IntToLogLevel(ALogLevel: Integer): TLogLevel;
function FFLogger: TFFLogger;

implementation

type
  PLogItem = ^TLogItem;
  TLogItem = record
    ThreadID: THandle;
    LogMsg: string;
    Next: PLogItem;
  end;

  TLogList = class
  private
    FHeader: PLogItem;
    FLock: TCriticalSection;

    procedure ClearLocked;
    function GetItem(AThreadID: THandle): PLogItem;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
  end;

var
  GLogLock: TCriticalSection = nil;
  GLogFile: string = '';
  GLogToFile: Boolean = False;
  GLogFileStream: TFileStream = nil;
  GFFLogger: TFFLogger = nil;
  GAVLogLevel: Integer = AV_LOG_INFO;
  GLogList: TLogList;
  GCallbackLock: TCriticalSection;
  GAVLogFlags: Integer = AV_LOG_SKIP_REPEATED;
  GPreviousLog: string = '';
  GLogCount: Integer = 0;

// TLogLevel to Integer
function LogLevelToInt(ALogLevel: TLogLevel): Integer;
begin
  Result := (Ord(ALogLevel) - 1) * 8;
end;

// Integer to TLogLevel
function IntToLogLevel(ALogLevel: Integer): TLogLevel;
var
  LLogLevel: Integer;
begin
  LLogLevel := ALogLevel div 8 + 1;
  if LLogLevel < Ord(Low(TLogLevel)) then
    Result := Low(TLogLevel)
  else if LLogLevel >= Ord(High(TLogLevel)) then
    Result := High(TLogLevel)
  else
    Result := TLogLevel(LLogLevel);
end;

// return global FFLogger
function FFLogger: TFFLogger;
begin
  if not Assigned(GFFLogger) then
  begin
    GFFLogger := TFFLogger.Create(nil);
    GFFLogger.FAutoCreated := True;
  end;
  Result := GFFLogger;
end;

// av_log() callback
procedure AVLogCallback(AReporter: Pointer; ALogLevel: Integer; const fmt: PAnsiChar; vl: PAnsiChar); cdecl;
const
  CDeltaSize = 2048;
var
  LBuffer: array[0..CDeltaSize-1] of AnsiChar;
  PItem: PLogItem;
  S: string;
  PBuffer: PAnsiChar;
  PBufferLen: Integer;
  PBuffer2: PAnsiChar;
  PBuffer2Size: Integer;
  LParent: PPAVClass;
begin
  // skip needless log
  if ALogLevel > GAVLogLevel then
    Exit;

  GCallbackLock.Acquire;
  try
    if FFLogger.FSkip then
      Exit;

    // find the last unfinished log item
{$IFDEF MSWINDOWS}
    PItem := GLogList.GetItem(GetCurrentThreadId);
{$ENDIF}
{$IFDEF POSIX}
    PItem := GLogList.GetItem(TThread.CurrentThread.ThreadID);
{$ENDIF}
    // clear buffer
    FillChar(LBuffer, SizeOf(LBuffer), 0);

    PBuffer := @LBuffer[0];

    // reporter info
    if Assigned(AReporter) and (PItem.LogMsg = '') then
    begin
      if PPAVClass(AReporter)^^.parent_log_context_offset <> 0 then
      begin
        LParent := PPPAVClass(PAnsiChar(AReporter) + PPAVClass(AReporter)^^.parent_log_context_offset)^;
        if Assigned(LParent) and Assigned(LParent^) then
        begin
          my_snprintf(PBuffer, SizeOf(LBuffer), '[%s @ %p] ', LParent^^.item_name(LParent), LParent);
          Inc(PBuffer, MyStrLen(PBuffer));
        end;
      end;
      my_snprintf(PBuffer, SizeOf(LBuffer) - (Integer(PBuffer) - Integer(@LBuffer[0])), '[%s @ %p] ',
                  PPAVClass(AReporter)^^.item_name(AReporter), AReporter);
      Inc(PBuffer, MyStrLen(PBuffer));
    end;

    // copy this log msg to the buffer
    if ((fmt <> '%s') or (vl^ <> #0)) and
      (my_vsnprintf(PBuffer, SizeOf(LBuffer) - (Integer(PBuffer) - Integer(@LBuffer[0])), fmt, vl) < 0) then
    begin
      // clear previous buffer
      FillChar(PBuffer^, SizeOf(LBuffer) - (Integer(PBuffer) - Integer(@LBuffer[0])), 0);
      PBuffer := @LBuffer[0];
      PBufferLen := MyStrLen(PBuffer);

      // buffer size is not enough, increase size
      PBuffer2Size := PBufferLen + CDeltaSize + CDeltaSize + 1;
      GetMem(PBuffer2, PBuffer2Size);
      FillChar(PBuffer2^, PBuffer2Size, 0);
      while my_vsnprintf(PBuffer2 + PBufferLen, PBuffer2Size - PBufferLen - 1, fmt, vl) < 0 do
      begin
        // buffer size is not enough, increase size
        FreeMem(PBuffer2);
        Inc(PBuffer2Size, CDeltaSize);
        GetMem(PBuffer2, PBuffer2Size);
        FillChar(PBuffer2^, PBuffer2Size, 0);
      end;

      // copy reporter info
      Move(PBuffer^, PBuffer2^, PBufferLen);

      // convert PAnsiChar to string
      SetString(S, PBuffer2, MyStrLen(PBuffer2));

      // don't forget to free memory
      FreeMem(PBuffer2);
    end
    else
    begin
      // convert PAnsiChar to string
      PBuffer := @LBuffer[0];
      SetString(S, PBuffer, MyStrLen(PBuffer));
    end;

    // check repeat
    if ((GAVLogFlags and AV_LOG_SKIP_REPEATED) <> 0) and
      (S <> '') and (S[Length(S)] = #10) and (S = GPreviousLog) then
    begin
      Inc(GLogCount);
      Exit;
    end;
    if GLogCount > 1 then
      FFLogger.AVLog(PItem.ThreadID, ALogLevel,
        Format('    Last message repeated %d times', [GLogCount]));
    GLogCount := 0;
    if (GAVLogFlags and AV_LOG_SKIP_REPEATED) <> 0 then
    begin
      GPreviousLog := S;
      UniqueString(GPreviousLog);
    end;

    // append log msg
    PItem.LogMsg := PItem.LogMsg + S;
    UniqueString(S);

    // push the log
    while Pos(#10, PItem.LogMsg) > 0 do
    begin
      UniqueString(PItem.LogMsg);
      S := Fetch(PItem.LogMsg, #10);
      FFLogger.AVLog(PItem.ThreadID, ALogLevel, S);
    end;
    UniqueString(PItem.LogMsg);
  finally
    GCallbackLock.Release;
  end;
end;

{ TLogList }

constructor TLogList.Create;
begin
  FLock := TCriticalSection.Create;
  FHeader := nil;
end;

destructor TLogList.Destroy;
begin
  FLock.Acquire;
  try
    ClearLocked;
  finally
    FLock.Release;
    FLock.Free;
  end;
end;

procedure TLogList.Clear;
begin
  FLock.Acquire;
  try
    ClearLocked;
  finally
    FLock.Release;
  end;
end;

procedure TLogList.ClearLocked;
var
  P: PLogItem;
begin
  while Assigned(FHeader) do
  begin
    P := FHeader;
    FHeader := FHeader.Next;
    P.LogMsg := ''; // free the string
    Dispose(P);
  end;
end;

function TLogList.GetItem(AThreadID: THandle): PLogItem;
var
  P: PLogItem;
begin
  // find the item required
  P := FHeader;
  while Assigned(P) do
  begin
    if P.ThreadID = AThreadID then
    begin
      Result := P;
      Exit;
    end;
    P := P.Next;
  end;

  // no item found, create a new item and insert it to the list as header
  New(Result);
  Result.ThreadID := AThreadID;
  Result.LogMsg := '';
  Result.Next := FHeader;
  FHeader := Result;
end;

{ TFFLogger }

constructor TFFLogger.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoCreated := False;
  FSkip := True;
  FActive := True;
  if Assigned(GFFLogger) and GFFLogger.FAutoCreated then
    FreeAndNil(GFFLogger);
{$IFNDEF ACTIVEX}
  if not (csDesigning in ComponentState) then
    Assert(not Assigned(GFFLogger), 'Allow creating only one instance of TFFLogger.')
  else if Assigned(GFFLogger) then
{$IFDEF MSWINDOWS}
    MessageBox(0, 'Allow creating only one instance of TFFLogger.', 'warning', 0);
{$ENDIF}
{$IFDEF POSIX}
    ShowMessage('Allow creating only one instance of TFFLogger.');
{$ENDIF}
{$ENDIF}
  FTriggerEventInMainThread := True;
  FLogFlags := GAVLogFlags;
  FLogLevel := IntToLogLevel(GAVLogLevel);
  GFFLogger := Self;
end;

destructor TFFLogger.Destroy;
begin
  if GFFLogger = Self then
    GFFLogger := nil;
  if Assigned(GLogFileStream) then
    FreeAndNil(GLogFileStream);
  inherited Destroy;
end;

function TFFLogger.GetLogFile: string;
begin
  Result := GLogFile;
end;

function TFFLogger.GetLogToFile: Boolean;
begin
  Result := GLogToFile;
end;

procedure TFFLogger.InstallAVLogCallback;
begin
  Assert(Assigned(av_log_set_callback));
  Assert(Assigned(av_log_set_level));
  av_log_set_callback(AVLogCallback);
  UpdateAVLogFlags; // ensure to set log flags
  UpdateAVLogLevel; // ensure to set log level
end;

procedure TFFLogger.UpdateAVLogFlags;
begin
  GAVLogFlags := FLogFlags;
  if Assigned(av_log_set_flags) then
    av_log_set_flags(GAVLogFlags);
end;

procedure TFFLogger.UpdateAVLogLevel;
begin
  if Assigned(av_log_set_level) then
  begin
    GAVLogLevel := LogLevelToInt(FLogLevel);
    av_log_set_level(GAVLogLevel);
  end;
end;

procedure TFFLogger.UpdateSkip;
begin
  FSkip := not FActive or (not Assigned(FOnLog) and (not GLogToFile or (GLogFile = '')));
end;

procedure TFFLogger.SetActive(const Value: Boolean);
begin
  GLogLock.Acquire;
  try
    FActive := Value;
    UpdateSkip;
  finally
    GLogLock.Release;
  end;
end;

procedure TFFLogger.SetLogFile(const Value: string);
begin
  GLogLock.Acquire;
  try
    if Value <> GLogFile then
    begin
      GLogFile := Value;
      if Assigned(GLogFileStream) then
        FreeAndNil(GLogFileStream);
      UpdateSkip;
    end;
  finally
    GLogLock.Release;
  end;
end;

procedure TFFLogger.SetLogFlags(const Value: Integer);
begin
  if FLogFlags <> Value then
  begin
    FLogFlags := Value;
    UpdateAVLogFlags;
  end;
end;

procedure TFFLogger.SetLogLevel(const Value: TLogLevel);
begin
  if FLogLevel <> Value then
  begin
    FLogLevel := Value;
    UpdateAVLogLevel;
  end;
end;

procedure TFFLogger.SetLogToFile(const Value: Boolean);
begin
  GLogLock.Acquire;
  try
    if Value <> GLogToFile then
    begin
      GLogToFile := Value;
      if Assigned(GLogFileStream) then
        FreeAndNil(GLogFileStream);
      UpdateSkip;
    end;
  finally
    GLogLock.Release;
  end;
end;

procedure TFFLogger.SetOnLog(const Value: TLogEvent);
begin
  GLogLock.Acquire;
  try
    FOnLog := Value;
    UpdateSkip;
  finally
    GLogLock.Release;
  end;
end;

procedure TFFLogger.OptLogLevel(const arg: string);
var
  LLogLevel: Integer;
begin
  if SameText(arg, 'quiet') then
    LLogLevel := AV_LOG_QUIET
  else if SameText(arg, 'panic') then
    LLogLevel := AV_LOG_PANIC
  else if SameText(arg, 'fatal') then
    LLogLevel := AV_LOG_FATAL
  else if SameText(arg, 'error') then
    LLogLevel := AV_LOG_ERROR
  else if SameText(arg, 'warning') then
    LLogLevel := AV_LOG_WARNING
  else if SameText(arg, 'info') then
    LLogLevel := AV_LOG_INFO
  else if SameText(arg, 'verbose') then
    LLogLevel := AV_LOG_VERBOSE
  else if SameText(arg, 'debug') then
    LLogLevel := AV_LOG_DEBUG
  else
    LLogLevel := StrToInt(arg);
  SetLogLevel(IntToLogLevel(LLogLevel));
end;

procedure TFFLogger.CallLogEvent;
begin
  //if not Assigned(FOnLog) then Exit;
  with FLogInfo do
    FOnLog(Sender, ThreadID, LogLevel, LogMsg);
end;

function LogDateTime(const ADateTime: TDateTime; const AFormat: string): string;
begin
  DateTimeToString(Result, AFormat, ADateTime);
end;

procedure TFFLogger.CallLogToFile;
const
  SLogLevel: array[TLogLevel] of string = (
    'Quiet', 'Panic', 'Fatal', 'Error', 'Warning', 'Info', 'Verbose', 'Debug');
var
  S: AnsiString;
  T: TDateTime;
begin
  //if not GLogToFile or (GLogFile = '') then Exit;
  if not Assigned(GLogFileStream) then
  begin
    if FileExists(GLogFile) then
    begin
      GLogFileStream := TFileStream.Create(GLogFile, fmOpenWrite or fmShareDenyWrite);
      GLogFileStream.Seek(0, soEnd);
    end
    else
      GLogFileStream := TFileStream.Create(GLogFile, fmCreate or fmShareDenyWrite);
  end;
  if Assigned(GLogFileStream) then
  begin
    T := Now;
    while IsNan(T) do
    begin
      // mysterious
      T := Now;
      LogDateTime(0, 'hh:nn:ss zzz ');
    end;
    with FLogInfo do
      S := AnsiString(Format('%s [%.8x] %s: %s'#13#10, [LogDateTime(T, 'hh:nn:ss zzz'), ThreadID, SLogLevel[LogLevel], LogMsg]));
    GLogFileStream.Write(S[1], Length(S));
  end;
end;

procedure TFFLogger.ClearLogFile;
begin
  GLogLock.Acquire;
  try
    if Assigned(GLogFileStream) then
      GLogFileStream.Size := 0
    else if (GLogFile <> '') and FileExists(GLogFile) then
{$IFDEF VCL_XE2_OR_ABOVE}
      System.SysUtils.DeleteFile(GLogFile);
{$ELSE}
      SysUtils.DeleteFile(GLogFile);
{$ENDIF}
  finally
    GLogLock.Release;
  end;
end;

procedure TFFLogger.AVLog(AThreadID: THandle; ALogLevel: Integer; const ALogMsg: string);
begin
  if FSkip then
    Exit;
  GLogLock.Acquire;
  try
    // log content
    with FLogInfo do
    begin
      Sender := Self;
      ThreadID := AThreadID;
      LogLevel := IntToLogLevel(ALogLevel);
      LogMsg := ALogMsg;
    end;
    // log event
    if Assigned(FOnLog) then
    begin
      if TriggerEventInMainThread then
        MySynchronize(CallLogEvent)
      else
        CallLogEvent;
    end;
    // log to file
    if GLogToFile and (GLogFile <> '') then
      CallLogToFile
  finally
    GLogLock.Release;
  end;
end;

procedure TFFLogger.Log(Sender: TObject; ALogLevel: TLogLevel; const ALogMsg: string);
begin
  if FSkip or (ALogLevel > FLogLevel) then
    Exit;
  GLogLock.Acquire;
  try
    // log content
    FLogInfo.Sender := Sender;
    with FLogInfo do
    begin
{$IFDEF MSWINDOWS}
      ThreadID := GetCurrentThreadId;
{$ENDIF}
{$IFDEF POSIX}
      ThreadID := TThread.CurrentThread.ThreadID;
{$ENDIF}
      LogLevel := ALogLevel;
      LogMsg := ALogMsg;
    end;
    // log event
    if Assigned(FOnLog) then
    begin
      if TriggerEventInMainThread then
        MySynchronize(CallLogEvent)
      else
        CallLogEvent;
    end;
    // log to file
    if GLogToFile and (GLogFile <> '') then
      CallLogToFile;
  finally
    GLogLock.Release;
  end;
end;

procedure TFFLogger.Log(Sender: TObject; ALogLevel: TLogLevel;
  const AFormat: string; const Args: array of const);
begin
  if FSkip or (ALogLevel > FLogLevel) then
    Exit;
  GLogLock.Acquire;
  try
    // log content
    FLogInfo.Sender := Sender;
    with FLogInfo do
    begin
{$IFDEF MSWINDOWS}
      ThreadID := GetCurrentThreadId;
{$ENDIF}
{$IFDEF POSIX}
      ThreadID := TThread.CurrentThread.ThreadID;
{$ENDIF}
      LogLevel := ALogLevel;
      LogMsg := Format(AFormat, Args);
    end;
    // log event
    if Assigned(FOnLog) then
    begin
      if TriggerEventInMainThread then
        MySynchronize(CallLogEvent)
      else
        CallLogEvent;
    end;
    // log to file
    if GLogToFile and (GLogFile <> '') then
      CallLogToFile;
  finally
    GLogLock.Release;
  end;
end;

initialization
  GLogList := TLogList.Create;
  GCallbackLock := TCriticalSection.Create;
  GLogLock := TCriticalSection.Create;

finalization
  GCallbackLock.Free;
  FreeAndNil(GLogList);
  if Assigned(GFFLogger) and GFFLogger.FAutoCreated then
    FreeAndNil(GFFLogger);
  GLogLock.Free;

end.
