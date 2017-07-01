(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of some utils.
 * Created by CodeCoolie@CNSW 2008/09/27 -> $Date:: 2013-11-18 #$
 *)

unit MyUtils;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  {$IFDEF POSIX}
    Posix.Dlfcn,
    System.Types, // for DWORD
  {$ENDIF}
  System.SysUtils,
  {$IFDEF VCL_XE4_OR_ABOVE}
    System.AnsiStrings, // StrLen
  {$ENDIF}
  System.Classes;
{$ELSE}
{$IF Defined(VER140) or Defined(VER150) or Defined(VER170) or Defined(VER180) or Defined(VER185) Or Defined(FPC)} // Delphi 6, 7, 2005, 2006, 2007, FPC
  SyncObjs,
{$IFEND}
  Windows, SysUtils, Classes;
{$ENDIF}

type
{$IFDEF UNICODE}
  TPathFileName = type string;
{$ELSE}
  {$IFDEF FPC}
  TPathFileName = type UTF8String;
  {$ELSE}
  TPathFileName = type WideString;
  {$ENDIF}
{$ENDIF}

{$IF Defined(VER140) or Defined(VER150) or Defined(VER170) or Defined(VER180) or Defined(VER185) Or Defined(FPC)} // Delphi 6, 7, 2005, 2006, 2007, FPC
  THandleObjectX = class(TSynchroObject)
  protected
    FHandle: THandle;
    FLastError: Integer;
    FUseCOMWait: Boolean;
  public
    { Specify UseCOMWait to ensure that when blocked waiting for the object
      any STA COM calls back into this thread can be made. }
    constructor Create(UseCOMWait: Boolean = False);
    destructor Destroy; override;
  public
    function WaitFor(Timeout: LongWord): TWaitResult; virtual;
    property LastError: Integer read FLastError;
    property Handle: THandle read FHandle;
  end;

  TSemaphore = class(THandleObjectX)
  public
    constructor Create(UseCOMWait: Boolean = False); overload;
    constructor Create(SemaphoreAttributes: PSecurityAttributes; AInitialCount, AMaximumCount: Integer; const Name: string; UseCOMWait: Boolean = False); overload;
    constructor Create(DesiredAccess: LongWord; InheritHandle: Boolean; const Name: string; UseCOMWait: Boolean = False); overload;
    procedure Acquire; override;
    procedure Release; overload; override;
    function Release(AReleaseCount: Integer): Integer; reintroduce; overload;
  end;
{$IFEND}

{$IF Defined(VER140) or Defined(VER150) or Defined(FPC)} // Delphi 6, 7, FPC
  TMutex = class(THandleObjectX)
  public
    constructor Create(UseCOMWait: Boolean = False); overload;
    constructor Create(MutexAttributes: PSecurityAttributes; InitialOwner: Boolean; const Name: string; UseCOMWait: Boolean = False); overload;
    constructor Create(DesiredAccess: LongWord; InheritHandle: Boolean; const Name: string; UseCOMWait: Boolean = False); overload;
    procedure Acquire; override;
    procedure Release; override;
  end;
{$IFEND}

{$IF Not Defined(UNICODE) And Not Defined(FPC)}
{$IFDEF BCB}
{$EXTERNALSYM IncludeTrailingPathDelimiter}
{$EXTERNALSYM ExtractFilePath}
{$EXTERNALSYM ExtractFileName}
{$EXTERNALSYM FileExists}
{$ENDIF}
function IncludeTrailingPathDelimiter(const S: string): string; overload;
function IncludeTrailingPathDelimiter(const S: WideString): WideString; overload;
function ExtractFilePath(const FileName: string): string; overload;
function ExtractFilePath(const FileName: WideString): WideString; overload;
function ExtractFileName(const FileName: string): string; overload;
function ExtractFileName(const FileName: WideString): WideString; overload;
function FileExists(const FileName: string): Boolean; overload;
function FileExists(const FileName: WideString): Boolean; overload;
{$IFEND}
function GetFileSize(const AFileName: TPathFileName): Int64;
function ExeName: TPathFileName;
function ExePath: TPathFileName;
function ExeFile: TPathFileName;

function Fetch(var AInput: string; const ADelimiter: string;
  const ADelete: Boolean = True): string;
function FileSizeToStr(ASize: Int64): string;
{$IFDEF MSWINDOWS}
function DateTimeOffset: TDateTime;
function UnixToDateTimeEx(const AValue: Int64): TDateTime;
function LogDateTime(const ADateTime: TDateTime; const AFormat: string): string;
function CountTimeTickEx: string;
{$ENDIF}
function MyStrLen(const Str: PAnsiChar): Cardinal; {$IFDEF USE_INLINE}inline;{$ENDIF}
function MySAR(AValue: Integer; AShift: Byte): Integer; {$IFDEF USE_INLINE}inline;{$ENDIF}

function MyLoadLibrary(const APath, AFile: TPathFileName; var AError: DWORD): THandle;
procedure FixupStub(const ALibFile: TPathFileName; const AHandle: THandle;
  const AName: AnsiString; var VStub: Pointer; ASilence: Boolean = False);
procedure LoadVariable(const ALibFile: TPathFileName; const AHandle: THandle;
  const AName: AnsiString; VStub: PPointer; ASilence: Boolean = False);

procedure parse_cmdline(cmdstart: PAnsiChar; argv: PPAnsiChar; args: PAnsiChar;
  numargs, numchars: PInteger);

procedure MyProcessMessages;
procedure MySynchronize(Method: TThreadMethod);
{$IFDEF FPC}
function SysErrorMessage(ErrorCode: Integer): string;
{$ENDIF}

var
  GEnabledSynchronize: Boolean = True;

implementation

{$IF Defined(VER140) or Defined(VER150) or Defined(VER170) or Defined(VER180) or Defined(VER185) Or Defined(FPC)} // Delphi 6, 7, 2005, 2006, 2007, FPC

type
  TCoWaitForMultipleHandlesProc = function (dwFlags: DWORD; dwTimeOut: DWORD;
    cHandles: LongWord; var Handles; var lpdwIndex: DWORD): HRESULT; stdcall;

var
  CoWaitForMultipleHandlesProc: TCoWaitFormultipleHandlesProc;

threadvar
  OleThreadWnd: HWND;

const
  OleThreadWndClassName = 'OleMainThreadWndClass'; //do not localize
  COWAIT_WAITALL = $00000001;
  COWAIT_ALERTABLE = $00000002;
  {$EXTERNALSYM HWND_MESSAGE}
  HWND_MESSAGE = HWND(-3);
  { This operation returned because the timeout period expired. }
  RPC_E_TIMEOUT = HRESULT($8001011F);
  {$EXTERNALSYM RPC_E_TIMEOUT}

function GetOleThreadWindow: HWND;
var
  ChildWnd: HWND;
  ParentWnd: HWND;
begin
  if (OleThreadWnd = 0) or not IsWindow(OleThreadWnd) then
  begin
    if (Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion >= 5) then
      ParentWnd := HWND_MESSAGE
    else
      ParentWnd := 0;
    ChildWnd := 0;
    repeat
      OleThreadWnd := FindWindowEx(ParentWnd, ChildWnd, OleThreadWndClassName, nil);
      ChildWnd := OleThreadWnd;
    until (OleThreadWnd = 0) or (GetWindowThreadProcessId(OleThreadWnd, nil) = GetCurrentThreadId);
  end;
  Result := OleThreadWnd;
end;

function InternalCoWaitForMultipleHandles(dwFlags: DWORD; dwTimeOut: DWORD;
  cHandles: LongWord; var Handles; var lpdwIndex: DWORD): HRESULT; stdcall;
var
  WaitResult: DWORD;
  OleThreadWnd: HWnd;
  Msg: TMsg;
begin
  WaitResult := 0; // supress warning
  OleThreadWnd := GetOleThreadWindow;
  if OleThreadWnd <> 0 then
    while True do
    begin
      WaitResult := MsgWaitForMultipleObjectsEx(cHandles, Handles, dwTimeOut, QS_ALLEVENTS, dwFlags);
      if WaitResult = WAIT_OBJECT_0 + cHandles then
      begin
        if PeekMessage(Msg, OleThreadWnd, 0, 0, PM_REMOVE) then
        begin
          TranslateMessage(Msg);
          DispatchMessage(Msg);
        end;
      end else
        Break;
    end
  else
    WaitResult := WaitForMultipleObjectsEx(cHandles, @Handles,
      dwFlags and COWAIT_WAITALL <> 0, dwTimeOut, dwFlags and COWAIT_ALERTABLE <> 0);
  if WaitResult = WAIT_TIMEOUT then
    Result := RPC_E_TIMEOUT
  else if WaitResult = WAIT_IO_COMPLETION then
    Result := RPC_S_CALLPENDING
  else
  begin
    Result := S_OK;
    if (WaitResult >= WAIT_ABANDONED_0) and (WaitResult < WAIT_ABANDONED_0 + cHandles) then
      lpdwIndex := WaitResult - WAIT_ABANDONED_0
    else
      lpdwIndex := WaitResult - WAIT_OBJECT_0;
  end;
end;

function CoWaitForMultipleHandles(dwFlags: DWORD; dwTimeOut: DWORD;
  cHandles: LongWord; var Handles; var lpdwIndex: DWORD): HRESULT;

  procedure LookupProc;
  var
    Ole32Handle: HMODULE;
  begin
    Ole32Handle := GetModuleHandle('ole32.dll'); //do not localize
    if Ole32Handle <> 0 then
      CoWaitForMultipleHandlesProc := GetProcAddress(Ole32Handle, 'CoWaitForMultipleHandles'); //do not localize
    if not Assigned(CoWaitForMultipleHandlesProc) then
      CoWaitForMultipleHandlesProc := InternalCoWaitForMultipleHandles;
  end;

begin
  if not Assigned(CoWaitForMultipleHandlesProc) then
    LookupProc;
  Result := CoWaitForMultipleHandlesProc(dwFlags, dwTimeOut, cHandles, Handles, lpdwIndex)
end;

{ THandleObjectX }

constructor THandleObjectX.Create(UseComWait: Boolean);
begin
  inherited Create;
  FUseCOMWait := UseCOMWait;
end;

destructor THandleObjectX.Destroy;
begin
  CloseHandle(FHandle);
  inherited Destroy;
end;

function THandleObjectX.WaitFor(Timeout: LongWord): TWaitResult;
var
  Index: DWORD;
begin
  if FUseCOMWait then
  begin
    case CoWaitForMultipleHandles(0, TimeOut, 1, FHandle, Index) of
      S_OK: Result := wrSignaled;
      RPC_S_CALLPENDING,
      RPC_E_TIMEOUT: Result := wrTimeout;
    else
      Result := wrError;
      FLastError := GetLastError;
    end;
  end else
  begin
    case WaitForSingleObject(Handle, Timeout) of
      WAIT_ABANDONED: Result := wrAbandoned;
      WAIT_OBJECT_0: Result := wrSignaled;
      WAIT_TIMEOUT: Result := wrTimeout;
      WAIT_FAILED:
        begin
          Result := wrError;
          FLastError := GetLastError;
        end;
    else
      Result := wrError;
    end;
  end;
end;

{ TSemaphore }

procedure TSemaphore.Acquire;
begin
  if WaitFor(INFINITE) = wrError then
    RaiseLastOSError;
end;

constructor TSemaphore.Create(UseCOMWait: Boolean);
begin
  Create(nil, 1, 1, '', UseCOMWait);
end;

constructor TSemaphore.Create(DesiredAccess: LongWord; InheritHandle: Boolean;
  const Name: string; UseCOMWait: Boolean);
var
  lpName: PChar;
begin
  inherited Create(UseCOMWait);
  if Name <> '' then
    lpName := PChar(Name)
  else
    lpName := nil;
  FHandle := OpenSemaphore(DesiredAccess, InheritHandle, lpName);
  if FHandle = 0 then
    RaiseLastOSError;
end;

function TSemaphore.Release(AReleaseCount: Integer): Integer;
begin
  if not ReleaseSemaphore(FHandle, AReleaseCount, @Result) then
    RaiseLastOSError;
end;

constructor TSemaphore.Create(SemaphoreAttributes: PSecurityAttributes;
  AInitialCount, AMaximumCount: Integer; const Name: string; UseCOMWait: Boolean);
var
  lpName: PChar;
begin
  inherited Create(UseCOMWait);
  if Name <> '' then
    lpName := PChar(Name)
  else
    lpName := nil;
  FHandle := CreateSemaphore(SemaphoreAttributes, AInitialCount, AMaximumCount, lpName);
  if FHandle = 0 then
    RaiseLastOSError;
end;

procedure TSemaphore.Release;
begin
  if not ReleaseSemaphore(FHandle, 1, nil) then
    RaiseLastOSError;
end;

{$IFEND}

{$IF Defined(VER140) or Defined(VER150) or Defined(FPC)} // Delphi 6, 7, FPC

{ TMutex }

procedure TMutex.Acquire;
begin
  if WaitFor(INFINITE) = wrError then
    RaiseLastOSError;
end;

constructor TMutex.Create(UseCOMWait: Boolean);
begin
  Create(nil, False, '', UseCOMWait);
end;

constructor TMutex.Create(MutexAttributes: PSecurityAttributes;
  InitialOwner: Boolean; const Name: string; UseCOMWait: Boolean);
var
  lpName: PChar;
begin
  inherited Create(UseCOMWait);
  if Name <> '' then
    lpName := PChar(Name)
  else
    lpName := nil;
  FHandle := CreateMutex(MutexAttributes, InitialOwner, lpName);
  if FHandle = 0 then
    RaiseLastOSError;
end;

constructor TMutex.Create(DesiredAccess: LongWord; InheritHandle: Boolean;
  const Name: string; UseCOMWait: Boolean);
var
  lpName: PChar;
begin
  inherited Create(UseCOMWait);
  if Name <> '' then
    lpName := PChar(Name)
  else
    lpName := nil;
  FHandle := OpenMutex(DesiredAccess, InheritHandle, lpName);
  if FHandle = 0 then
    RaiseLastOSError;
end;

procedure TMutex.Release;
begin
  if not ReleaseMutex(FHandle) then
    RaiseLastOSError;
end;
{$IFEND}

{$IFDEF FPC}
function FormatMessageA(dwFlags     : DWORD;
                        lpSource    : Pointer;
                        dwMessageId : DWORD;
                        dwLanguageId: DWORD;
                        lpBuffer    : PCHAR;
                        nSize       : DWORD;
                        Arguments   : Pointer): DWORD; stdcall;external 'kernel32' name 'FormatMessageA';

function SysErrorMessage(ErrorCode: Integer): string;
var
  MsgBuffer: array[0..Format_Message_Max_Width_Mask] of Char;
  Len: Integer;
  Temp: AnsiString;
begin
  FillChar(MsgBuffer[0], SizeOf(MsgBuffer), #0);
  Len := FormatMessageA(
                 FORMAT_MESSAGE_FROM_SYSTEM or
                 FORMAT_MESSAGE_IGNORE_INSERTS or
                 FORMAT_MESSAGE_ARGUMENT_ARRAY,
                 nil,
                 ErrorCode,
                 0, //MakeLangId(LANG_NEUTRAL, SUBLANG_DEFAULT),
                 MsgBuffer,
                 SizeOf(MsgBuffer),
                 nil);
  while (Len > 0) and (MsgBuffer[Len - 1] in [#0..#32, '.']) do
  begin
    Dec(Len);
    MsgBuffer[Len] := #0;
  end;
  Temp := StrPas(MsgBuffer);
  SysErrorMessage := AnsiToUTF8(Temp);
end;
{$ENDIF}

{$IFNDEF UNICODE}
function IsLeadChar(C: AnsiChar): Boolean; overload;
begin
  Result := C in LeadBytes;
end;

function IsLeadChar(C: WideChar): Boolean; overload;
begin
  Result := (C >= #$D800) and (C <= #$DFFF);
end;

function ByteType(const S: WideString; Index: Integer): TMbcsByteType;
begin
  Result := mbSingleByte;
  if (Index > 0) and (Index <= Length(S)) and IsLeadChar(S[Index]) then
    if (S[Index] >= #$D800) and (S[Index] <= #$DBFF) then
      Result := mbLeadByte
    else
      Result := mbTrailByte;
end;

function IsPathDelimiter(const S: WideString; Index: Integer): Boolean;
begin
  Result := (Index > 0) and (Index <= Length(S)) and (S[Index] = PathDelim)
    and (ByteType(S, Index) = mbSingleByte);
end;

{$IFNDEF FPC}
function IncludeTrailingPathDelimiter(const S: string): string;
begin
  Result := SysUtils.IncludeTrailingPathDelimiter(S);
end;
{$ENDIF}

function IncludeTrailingPathDelimiter(const S: WideString): WideString;
begin
  Result := S;
  if not IsPathDelimiter(Result, Length(Result)) then
    Result := Result + PathDelim;
end;

function StrScan(const Str: PWideChar; Chr: WideChar): PWideChar;
begin
  Result := Str;
  while Result^ <> Chr do
  begin
    if Result^ = #0 then
    begin
      Result := nil;
      Exit;
    end;
    Inc(Result);
  end;
end;

function LastDelimiter(const Delimiters, S: WideString): Integer;
var
  P: PWideChar;
begin
  Result := Length(S);
  P := PWideChar(Delimiters);
  while Result > 0 do
  begin
    if (S[Result] <> #0) and (StrScan(P, S[Result]) <> nil) then
      Exit;
    Dec(Result);
  end;
end;

{$IFNDEF FPC}
function ExtractFilePath(const FileName: string): string;
begin
  Result := SysUtils.ExtractFilePath(FileName);
end;

function ExtractFilePath(const FileName: WideString): WideString;
var
  I: Integer;
begin
  I := LastDelimiter(PathDelim + DriveDelim, FileName);
  Result := Copy(FileName, 1, I);
end;

function ExtractFileName(const FileName: string): string;
begin
  Result := SysUtils.ExtractFileName(FileName);
end;

function ExtractFileName(const FileName: WideString): WideString;
var
  I: Integer;
begin
  I := LastDelimiter(PathDelim + DriveDelim, FileName);
  Result := Copy(FileName, I + 1, MaxInt);
end;

function FileExists(const FileName: string): Boolean;
begin
  Result := SysUtils.FileExists(FileName);
end;
{$ENDIF}

function FileExists(const FileName: WideString): Boolean;
var
  Code: DWORD;
begin
  Code := GetFileAttributesW(PWideChar(FileName));
  Result := (Code <> DWORD(-1)) and (FILE_ATTRIBUTE_DIRECTORY and Code = 0);
end;

function GetCurrentDir: WideString;
var
  DirBuf: array[0..MAX_PATH] of WideChar;
begin
  GetCurrentDirectoryW({SizeOf(DirBuf)} MAX_PATH + 1, DirBuf);
  Result := DirBuf;
end;

function SetCurrentDir(const Dir: WideString): Boolean;
begin
  Result := SetCurrentDirectoryW(PWideChar(Dir));
end;

function GetEnvironmentVariable(const Name: WideString): WideString;
const
  BufSize = 1024;
var
  Len: Integer;
  Buffer: array[0..BufSize - 1] of WideChar;
begin
  Result := '';
  Len := GetEnvironmentVariableW(PWideChar(Name), @Buffer, BufSize);
  if Len < BufSize then
    SetString(Result, PWideChar(@Buffer), Len)
  else
  begin
    SetLength(Result, Len - 1);
    GetEnvironmentVariableW(PWideChar(Name), PWideChar(Result), Len);
  end;
end;

(*
function UpperCase(const S: WideString): WideString;
var
  I, Len: Integer;
  DstP, SrcP: PWideChar;
  Ch: WideChar;
begin
  Len := {GetString}Length(S);
  SetLength(Result, Len);
  if Len > 0 then
  begin
    DstP := PWideChar(Pointer(Result));
    SrcP := PWideChar(Pointer(S));
    for I := Len downto 1 do
    begin
      Ch := SrcP^;
      case Ch of
        'a'..'z':
          Ch := WideChar(Word(Ch) xor $0020);
      end;
      DstP^ := Ch;
      Inc(DstP);
      Inc(SrcP);
    end;
  end;
end;
*)

type
  TSearchRec = record
    Time: Integer;
    Size: Int64;
    Attr: Integer;
    Name: WideString;
    ExcludeAttr: Integer;
    FindHandle: THandle  {platform};
    FindData: TWin32FindDataW  {platform};
  end;

function FindMatchingFile(var F: TSearchRec): Integer;
var
  LocalFileTime: TFileTime;
begin
  with F do
  begin
    while FindData.dwFileAttributes and ExcludeAttr <> 0 do
      if not FindNextFileW(FindHandle, FindData) then
      begin
        Result := GetLastError;
        Exit;
      end;
    FileTimeToLocalFileTime(FindData.ftLastWriteTime, LocalFileTime);
    FileTimeToDosDateTime(LocalFileTime, LongRec(Time).Hi,
      LongRec(Time).Lo);
    Size := FindData.nFileSizeLow or Int64(FindData.nFileSizeHigh) shl 32;
    Attr := FindData.dwFileAttributes;
    Name := FindData.cFileName;
  end;
  Result := 0;
end;

procedure FindClose(var F: TSearchRec);
begin
  if F.FindHandle <> INVALID_HANDLE_VALUE then
  begin
{$IFDEF VCL_XE2_OR_ABOVE}
    Winapi.Windows.FindClose(F.FindHandle);
{$ELSE}
    Windows.FindClose(F.FindHandle);
{$ENDIF}
    F.FindHandle := INVALID_HANDLE_VALUE;
  end;
end;

function FindFirst(const Path: WideString; Attr: Integer;
  var  F: TSearchRec): Integer;
const
{$WARN SYMBOL_PLATFORM OFF}
  faSpecial = faHidden or faSysFile or faDirectory;
{$WARN SYMBOL_PLATFORM ON}
begin
  F.ExcludeAttr := not Attr and faSpecial;
  F.FindHandle := FindFirstFileW(PWideChar(Path), F.FindData);
  if F.FindHandle <> INVALID_HANDLE_VALUE then
  begin
    Result := FindMatchingFile(F);
    if Result <> 0 then FindClose(F);
  end else
    Result := GetLastError;
end;

function ExpandFileName(const FileName: WideString): WideString;
var
  FName: PWideChar;
  Buffer: array[0..MAX_PATH - 1] of WideChar;
begin
  SetString(Result, PWideChar(@Buffer), GetFullPathNameW(PWideChar(FileName),
    {SizeOf(Buffer)}MAX_PATH, Buffer, FName));
end;
{$ENDIF}

function GetFileSize(const AFileName: TPathFileName): Int64;
var
  SearchRec: TSearchRec;
  S: {$IFDEF FPC}WideString{$ELSE}TPathFileName{$ENDIF};
begin
  S := {$IFDEF FPC}UTF8Decode(AFileName){$ELSE}AFileName{$ENDIF};
  if FileExists(S) and (FindFirst(ExpandFileName(S), faAnyFile, SearchRec) = 0) then
  begin
    Result := SearchRec.Size;
    FindClose(SearchRec);
  end
  else
    Result := -1;
end;

function ExeName: TPathFileName;
{$IFNDEF UNICODE}
var
  Buffer: array[0..MAX_PATH] of WideChar;
  {$IFDEF FPC}
  W: WideString;
  {$ENDIF}
{$ENDIF}
begin
{$IFNDEF UNICODE}
  {$IFDEF FPC}
  SetString(W, Buffer, GetModuleFileNameW(0, Buffer, {SizeOf(Buffer)}MAX_PATH + 1));
  Result := UTF8Encode(W);
  {$ELSE}
  SetString(Result, Buffer, GetModuleFileNameW(0, Buffer, {SizeOf(Buffer)}MAX_PATH + 1));
  {$ENDIF}
{$ELSE}
  Result := ParamStr(0);
{$ENDIF}
end;

function ExePath: TPathFileName;
begin
  Result := ExtractFilePath(ExeName);
end;

function ExeFile: TPathFileName;
begin
  Result := ExtractFileName(ExeName);
end;

function Fetch(var AInput: string; const ADelimiter: string; const ADelete: Boolean): string;
var
  LPos: Integer;
begin
  LPos := Pos(ADelimiter, AInput);
  if LPos <> 0 then
  begin
    Result := Copy(AInput, 1, LPos - 1);
    if ADelete then
      AInput := Copy(AInput, LPos + Length(ADelimiter), MaxInt);
  end
  else
  begin
    Result := AInput;
    if ADelete then
      AInput := '';
  end;
end;

function FileSizeToStr(ASize: Int64): string;
const
  KB = 1024;
  MB = 1024 * 1024;
  GB = 1024 * 1024 * 1024;
begin
  Result := '';
  if ASize > GB then
    Result := Format('%.2f GB', [ASize / GB])
  else if ASize > MB then
    Result := Format('%.2f MB', [ASize / MB])
  else if ASize > KB then
    Result := Format('%.2f KB', [ASize / KB])
  else
    Result := Format('%d Byte', [ASize])
end;

{$IFDEF MSWINDOWS}
function DateTimeOffset: TDateTime;
var
  TimeZoneInformation: TTimeZoneInformation;
begin
  GetTimeZoneInformation(TimeZoneInformation);
  Result := -TimeZoneInformation.Bias / (24 * 60);
end;

function UnixToDateTimeEx(const AValue: Int64): TDateTime;
begin
  Result := AValue / SecsPerDay + UnixDateDelta + DateTimeOffset;
end;

function LogDateTime(const ADateTime: TDateTime; const AFormat: string): string;
begin
  DateTimeToString(Result, AFormat, ADateTime);
end;

function CountTimeTickEx: string;
const
{$J+}
  StartTime: Int64 = 0;
{$J-}
var
  NowTime: Int64;
  Frequency: Int64;
begin
  QueryPerformanceCounter(NowTime);
  QueryPerformanceFrequency(Frequency);
  Result := IntToStr((NowTime - StartTime) * 1000000 div Frequency);
  QueryPerformanceCounter(StartTime);
end;
{$ENDIF}

function MyStrLen(const Str: PAnsiChar): Cardinal;
begin
{$IFDEF VCL_XE4_OR_ABOVE}
  Result := System.AnsiStrings.StrLen(Str);
{$ELSE}
  Result := StrLen(Str);
{$ENDIF}
end;

// Shift Arithmetic Right
function MySAR(AValue: Integer; AShift: Byte): Integer;
begin
//  if AValue < 0 then
//    Assert(-(-AValue shr AShift) = AValue div (1 shl AShift));
  if AValue < 0 then
    Result := AValue div (1 shl AShift)
  else
    Result := AValue shr AShift;
end;

function MyLoadLibrary(const APath, AFile: TPathFileName; var AError: DWORD): THandle;
var
{$IFDEF MSWINDOWS}
  LCurrPath,
{$ENDIF}
  LCurrDir, LPath, LFile: {$IFDEF FPC}WideString{$ELSE}TPathFileName{$ENDIF};
begin
  LPath := {$IFDEF FPC}UTF8Decode(APath){$ELSE}APath{$ENDIF};
  LFile := {$IFDEF FPC}UTF8Decode(AFile){$ELSE}AFile{$ENDIF};
  if (LPath <> '') and FileExists(IncludeTrailingPathDelimiter(LPath) + LFile) then
  begin
    LCurrDir := GetCurrentDir;
    SetCurrentDir(LPath);
    try
{$IFDEF MSWINDOWS}
      LCurrPath := GetEnvironmentVariable('PATH');
      if Pos(WideUpperCase(LPath), WideUpperCase(LCurrPath)) < 1 then
  {$IFDEF UNICODE}
        SetEnvironmentVariable('PATH', PChar(LPath + ';' + LCurrPath));
      Result := LoadLibraryEx(PChar(IncludeTrailingPathDelimiter(LPath) + LFile), 0, LOAD_WITH_ALTERED_SEARCH_PATH);
  {$ELSE}
        SetEnvironmentVariableW('PATH', PWideChar(LPath + ';' + LCurrPath));
      Result := LoadLibraryExW(PWideChar(IncludeTrailingPathDelimiter(LPath) + LFile), 0, LOAD_WITH_ALTERED_SEARCH_PATH);
  {$ENDIF}
{$ENDIF}
{$IFDEF POSIX}
      Result := LoadLibrary(PChar(IncludeTrailingPathDelimiter(LPath) + LFile));
{$ENDIF}
      if Result = 0 then
        AError := GetLastError;
    finally
      SetCurrentDir(LCurrDir);
    end;
  end
  else
  begin
{$IFDEF UNICODE}
    Result := LoadLibrary(PChar(LFile));
{$ELSE}
    Result := LoadLibraryW(PWideChar(LFile));
{$ENDIF}
    if Result = 0 then
      AError := GetLastError;
  end;
end;

procedure FixupStub(const ALibFile: TPathFileName; const AHandle: THandle;
  const AName: AnsiString; var VStub: Pointer; ASilence: Boolean);
begin
{$IFDEF MSWINDOWS}
  VStub := GetProcAddress(AHandle, PAnsiChar(AName));
{$ENDIF}
{$IFDEF POSIX}
  VStub := GetProcAddress(AHandle, PChar(string(AName)));
{$ENDIF}
  if not ASilence and not Assigned(VStub) then
    raise Exception.CreateFmt('Load function %s@%s error: %s', [AName, ALibFile, SysErrorMessage(GetLastError)]);
end;

procedure LoadVariable(const ALibFile: TPathFileName; const AHandle: THandle;
  const AName: AnsiString; VStub: PPointer; ASilence: Boolean = False);
begin
{$IFDEF MSWINDOWS}
  VStub^ := GetProcAddress(AHandle, PAnsiChar(AName));
{$ENDIF}
{$IFDEF POSIX}
  VStub^ := GetProcAddress(AHandle, PChar(string(AName)));
{$ENDIF}
  if not ASilence and not Assigned(VStub) then
    raise Exception.CreateFmt('Load variable %s@%s error: %s', [AName, ALibFile, SysErrorMessage(GetLastError)]);
end;

// ported from stdargv.c
(***
*static void parse_cmdline(cmdstart, argv, args, numargs, numchars)
*
*Purpose:
*    Parses the command line and sets up the argv[] array.
*    On entry, cmdstart should point to the command line,
*    argv should point to memory for the argv array, args
*    points to memory to place the text of the arguments.
*    If these are NULL, then no storing (only coujting)
*    is done.  On exit, *numargs has the number of
*    arguments (plus one for a final NULL argument),
*    and *numchars has the number of bytes used in the buffer
*    pointed to by args.
*
*Entry:
*    _TSCHAR *cmdstart - pointer to command line of the form
*        <progname><nul><args><nul>
*    _TSCHAR **argv - where to build argv array; NULL means don't
*            build array
*    _TSCHAR *args - where to place argument text; NULL means don't
*            store text
*
*Exit:
*    no return value
*    int *numargs - returns number of argv entries created
*    int *numchars - number of characters used in args buffer
*
*Exceptions:
*
*******************************************************************************)
{
"a b c" d e
  a b c
  d
  e
"ab\"c" "\\" d
  ab"c
  \
  d
a\\\b d"e f"g h
  a\\\b
  de fg
  h
a\\\"b c d
  a\"b
  c
  d
a\\\\"b c" d e
  a\\b c
  d
  e
}
{$DEFINE MBCS}
procedure parse_cmdline(cmdstart: PAnsiChar; argv: PPAnsiChar; args: PAnsiChar;
  numargs, numchars: PInteger);
const
  DQUOTECHAR = '"';
  NULCHAR = #0;
  SPACECHAR = ' ';
  TABCHAR = #9;
  SLASHCHAR = '\';
var
  p: PAnsiChar;
{$IFDEF PROCESS_PROGRAM_NAME}
  c: AnsiChar;
{$ENDIF}
  inquote: Integer;   (* 1 = inside quotes *)
  copychar: Integer;  (* 1 = copy char to *args *)
  numslash: Cardinal; (* num of backslashes seen *)
begin
  numchars^ := 0;
{$IFDEF PROCESS_PROGRAM_NAME}
  numargs^ := 1;      (* the program name at least *)
{$ELSE}
  numargs^ := 0;
{$ENDIF}

  p := cmdstart;
  (* first scan the program name, copy it, and count the bytes *)
{$IFDEF PROCESS_PROGRAM_NAME}
  if Assigned(argv) then
  begin
    //*argv++ = args;
    argv^ := args;
    Inc(argv);
  end;
{$ENDIF}

{$IFDEF PROCESS_PROGRAM_NAME}
  (* A quoted program name is handled here. The handling is much
     simpler than for other arguments. Basically, whatever lies
     between the leading double-quote and next one, or a terminal null
     character is simply accepted. Fancier handling is not required
     because the program name must be a legal NTFS/HPFS file name.
     Note that the double-quote characters are not copied, nor do they
     contribute to numchars. *)
  if p^ = DQUOTECHAR then
  begin
    (* scan from just past the first double-quote through the next
       double-quote, or up to a null, whichever comes first *)
    Inc(p);
    while (p^ <> DQUOTECHAR) and (p^ <> NULCHAR) do
    begin
{$IFDEF MBCS}
      if {ismbblead}IsLeadChar(p^) then
      begin
        Inc(numchars^);
        if Assigned(args) then
        begin
          args^ := p^;
          Inc(args);
          Inc(p);
        end;
      end;
{$ENDIF}
      Inc(numchars^);
      if Assigned(args) then
      begin
        args^ := p^;
        Inc(args);
      end;
      Inc(p);
    end;
    (* append the terminating null *)
    Inc(numchars^);
    if Assigned(args) then
    begin
      args^ := NULCHAR;
      Inc(args);
    end;

    (* if we stopped on a double-quote (usual case), skip over it *)
    if p^ = DQUOTECHAR then
      Inc(p);
  end
  else
  begin
    (* Not a quoted program name *)
    repeat
      Inc(numchars^);
      if Assigned(args) then
      begin
        args^ := p^;
        Inc(args);
      end;

      c := p^;
      Inc(p);
{$IFDEF MBCS}
      if {ismbblead}IsLeadChar(c) then
      begin
        Inc(numchars^);
        if Assigned(args) then
        begin
          args^ := p^;    (* copy 2nd byte too *)
          Inc(args);
        end;
        Inc(p); (* skip over trail byte *)
      end;
{$ENDIF}
    until (c = SPACECHAR) or (c = NULCHAR) or (c <> TABCHAR);

    if c = NULCHAR then
      Dec(p)
    else if Assigned(args) then
      (args - 1)^ := NULCHAR;
  end;
{$ENDIF}

  inquote := 0;

  (* loop on each argument *)
  while True do
  begin
    if p^ <> #0 then
      while (p^ = SPACECHAR) or (p^ = TABCHAR) do
        Inc(p);

    if p^ = NULCHAR then
      Break;            (* end of args *)

    (* scan an argument *)
    if Assigned(argv) then
    begin
      argv^ := args;        (* store ptr to arg *)
      Inc(argv);
    end;
    Inc(numargs^);

    (* loop through scanning one argument *)
    while True do
    begin
      copychar := 1;
      (* Rules: 2N backslashes + " ==> N backslashes and begin/end quote
         2N+1 backslashes + " ==> N backslashes + literal "
         N backslashes ==> N backslashes *)
      numslash := 0;
      while p^ = SLASHCHAR do
      begin
        (* count number of backslashes for use below *)
        Inc(p);
        Inc(numslash);
      end;
      if p^ = DQUOTECHAR then
      begin
        (* if 2N backslashes before, start/end quote, otherwise
            copy literally *)
        if (numslash mod 2) = 0 then
        begin
          if inquote <> 0 then
          begin
            if (p + 1) = DQUOTECHAR then
              Inc(p)    (* Double quote inside quoted string *)
            else        (* skip first quote char and copy second *)
              copychar := 0;
          end
          else
            copychar := 0;       (* don't copy quote *)

          inquote := 1 - inquote;
        end;
        numslash := numslash div 2;        (* divide numslash by two *)
      end;

      (* copy slashes *)
      while numslash <> 0 do
      begin
        Dec(numslash);
        if Assigned(args) then
        begin
          args^ := SLASHCHAR;
          Inc(args);
        end;
        Inc(numchars^);
      end;

      (* if at end of arg, break loop *)
      if (p^ = NULCHAR) or ((inquote = 0) and ((p^ = SPACECHAR) or (p^ = TABCHAR))) then
        Break;

      (* copy character into argument *)
{$IFDEF MBCS}
      if copychar <> 0 then
      begin
        if Assigned(args) then
        begin
          if {ismbblead}IsLeadChar(p^) then
          begin
            args^ := p^;
            Inc(args);
            Inc(p);
            Inc(numchars^);
          end;
          args^ := p^;
          Inc(args);
        end
        else if {ismbblead}IsLeadChar(p^) then
        begin
          Inc(p);
          Inc(numchars^);
        end;
        Inc(numchars^);
      end;
      Inc(p);
{$ELSE}
      if copychar <> 0 then
      begin
        if Assigned(args) then
        begin
          args^ := p^;
          Inc(args);
        end;
        Inc(numchars^);
      end;
      Inc(p);
{$ENDIF}
    end;

    (* null-terminate the argument *)

    if Assigned(args) then
    begin
      args^ := NULCHAR;        (* terminate string *)
      Inc(args);
    end;
    Inc(numchars^);
  end;

  (* We put one last argument in -- a null ptr *)
  if Assigned(argv) then
  begin
    argv^ := #0;
    //Inc(argv);
  end;
  Inc(numargs^);
end;

{$IFDEF MSWINDOWS}
function MyProcessMessage(var Msg: TMsg): Boolean;
var
  Unicode: Boolean;
  MsgExists: Boolean;
begin
  Result := False;
  if PeekMessage(Msg, 0, 0, 0, PM_NOREMOVE) then
  begin
{$IFDEF UNICODE}
    Unicode := (Msg.hwnd = 0) or IsWindowUnicode(Msg.hwnd);
{$ELSE}
    Unicode := (Msg.hwnd <> 0) and IsWindowUnicode(Msg.hwnd);
{$ENDIF}
    if Unicode then
      MsgExists := PeekMessageW(Msg, 0, 0, 0, PM_REMOVE)
    else
      MsgExists := PeekMessageA(Msg, 0, 0, 0, PM_REMOVE);

    if MsgExists then
    begin
      Result := True;
      if Msg.Message <> {WM_QUIT}$0012 then
      begin
        TranslateMessage(Msg);
        if Unicode then
          DispatchMessageW(Msg)
        else
          DispatchMessageA(Msg);
      end;
    end;
  end;
end;

procedure MyProcessMessages;
var
  Msg: TMsg;
begin
  while MyProcessMessage(Msg) do {loop};
end;
{$ENDIF}

{$IFDEF POSIX}
procedure MyProcessMessages;
begin
  {do nothing}
end;
{$ENDIF}

{$IFDEF VER140}
type
  TThreadEx = class(TThread)
  protected
    procedure Execute; override;
  public
    constructor Create;
  end;

constructor TThreadEx.Create;
begin
  inherited Create(False);
end;

procedure TThreadEx.Execute;
begin
  while not Terminated do
    Sleep(20);
end;

var
  FThread: TThreadEx = nil;
{$ENDIF}

procedure MySynchronize(Method: TThreadMethod);
begin
{$IFDEF MSWINDOWS}
  if GEnabledSynchronize and (GetCurrentThreadID <> MainThreadID) then
{$ENDIF}
{$IFDEF POSIX}
  if GEnabledSynchronize and (TThread.CurrentThread.ThreadID <> MainThreadID) then
{$ENDIF}
{$IFDEF VER140}
    FThread.Synchronize(Method)
{$ELSE}
    TThread.Synchronize(nil, Method)
{$ENDIF}
  else
    Method;
end;

{$IFDEF VER140}
initialization
  FThread := TThreadEx.Create;

finalization
  FThread.Terminate;
  FThread.Free;
{$ENDIF}

end.
