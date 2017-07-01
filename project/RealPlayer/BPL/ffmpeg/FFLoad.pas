(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of libraries loader.
 * Created by CodeCoolie@CNSW 2008/12/20 -> $Date:: 2013-11-27 #$
 *)

unit FFLoad;

interface

{$I CompilerDefines.inc}

{$I _LicenseDefines.inc}

{$IFDEF MSWINDOWS}
  {$DEFINE MSVCRT_DLL}
{$ENDIF}
{$IFDEF POSIX}
  {$UNDEF MSVCRT_DLL}
{$ENDIF}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  {$IFDEF POSIX}
    System.Types, // for DWORD
  {$ENDIF}
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
{$ELSE}
  Windows,
  SysUtils,
  Classes,
  SyncObjs,
{$ENDIF}

{$IFDEF USES_LICKEY}
  LicenseKey,
{$ENDIF}

  AVCodecStubs,
  AVDeviceStubs,
  AVFilterStubs,
  AVFormatStubs,
  AVUtilStubs,
  SwResampleStubs,
  SwScaleStubs,
  SoundTouchStubs,
  MyUtilStubs,

  MyUtils;

type
  TLibrary = (avCodec, avDevice, avFilter, avFormat, avUtil, swResample, swScale, myUtil, libSoundTouch);
  TLibraries = set of TLibrary;

  TFFLoader = class
  private
    FInstallLogger: Boolean;
    function GetLastErrMsg: string;
    function GetLibraryPath: TPathFileName;
    procedure SetLibraryPath(const Value: TPathFileName);
    function GetLibraryName(Index: TLibrary): TPathFileName;
    procedure SetLibraryName(Index: TLibrary; const Value: TPathFileName);
  public
    constructor Create;
    function Load(ALibrary: TLibrary): Boolean; overload;
    function Load(ALibraries: TLibraries): Boolean; overload;
    function Loaded(ALibrary: TLibrary): Boolean; overload;
    function Loaded(ALibraries: TLibraries): Boolean; overload;
    procedure CheckLibAV(ALibraries: TLibraries);
    procedure Unload(ALibrary: TLibrary); overload;
    procedure Unload(ALibraries: TLibraries); overload;

    property LastErrMsg: string read GetLastErrMsg;
    property LibraryPath: TPathFileName read GetLibraryPath write SetLibraryPath;
    property LibraryNames[Index: TLibrary]: TPathFileName read GetLibraryName write SetLibraryName;
    property InstallLogger: Boolean read FInstallLogger write FInstallLogger;
  end;

var
  // global instance of TFFLoader
  FFLoader: TFFLoader = nil;

const
  CAllLibraries    : TLibraries = [avCodec, avDevice, avFilter, avFormat, avUtil, swResample, swScale, myUtil, libSoundTouch];
  CDecoderLibraries: TLibraries = [avCodec,                     avFormat, avUtil, swResample, swScale, myUtil];
  CEncoderLibraries: TLibraries = [avCodec, avDevice, avFilter, avFormat, avUtil, swResample, swScale, myUtil];
  CPlayerLibraries : TLibraries = [avCodec, avDevice, avFilter, avFormat, avUtil, swResample, swScale, myUtil];

implementation

uses
  libavcodec,
  FFLog,
  UnicodeProtocol;

type
  TFixupProc = procedure(const ALibName: TPathFileName; const AHandle: THandle);
  TUnfixProc = procedure;

  TLibraryItem = record
    Lib: TLibrary;
    Name: TPathFileName;
    SysLib: Boolean;
    Version: Integer;
    Fixup: TFixupProc;
    Unfix: TUnfixProc;
  end;

  TLibraryStatus = record
    Lib: TLibrary;
    Name: TPathFileName;
    Handle: THandle;
    Fixuped: Boolean;
  end;

{$I libversion.inc}
{$IFDEF NEED_HASH}
  {$IFDEF ACTIVEX}
    {$I VersionX.inc}
  {$ELSE}
    {$I Version.inc}
  {$ENDIF}
{$ENDIF}

const
  CLibraries: array[TLibrary] of TLibraryItem = (
                  (
                    Lib: avCodec;
                    Name: 'avcodec';
                    SysLib: False;
                    Version: LIBAVCODEC_VERSION_MAJOR;
                    Fixup: AVCodecFixupStubs;
                    Unfix: AVCodecUnfixStubs;
                  ),
                  (
                    Lib: avDevice;
                    Name: 'avdevice';
                    SysLib: False;
                    Version: LIBAVDEVICE_VERSION_MAJOR;
                    Fixup: AVDeviceFixupStubs;
                    Unfix: AVDeviceUnfixStubs;
                  ),
                  (
                    Lib: avFilter;
                    Name: 'avfilter';
                    SysLib: False;
                    Version: LIBAVFILTER_VERSION_MAJOR;
                    Fixup: AVFilterFixupStubs;
                    Unfix: AVFilterUnfixStubs;
                  ),
                  (
                    Lib: avFormat;
                    Name: 'avformat';
                    SysLib: False;
                    Version: LIBAVFORMAT_VERSION_MAJOR;
                    Fixup: AVFormatFixupStubs;
                    Unfix: AVFormatUnfixStubs;
                  ),
                  (
                    Lib: avUtil;
                    Name: 'avutil';
                    SysLib: False;
                    Version: LIBAVUTIL_VERSION_MAJOR;
                    Fixup: AVUtilFixupStubs;
                    Unfix: AVUtilUnfixStubs;
                  ),
                  (
                    Lib: swResample;
                    Name: 'swresample';
                    SysLib: False;
                    Version: LIBSWRESAMPLE_VERSION_MAJOR;
                    Fixup: SwResampleFixupStubs;
                    Unfix: SwResampleUnfixStubs;
                  ),
                  (
                    Lib: swScale;
                    Name: 'swscale';
                    SysLib: False;
                    Version: LIBSWSCALE_VERSION_MAJOR;
                    Fixup: SwScaleFixupStubs;
                    Unfix: SwScaleUnfixStubs;
                  ),
                  (
                    Lib: myUtil;
{$IFDEF MSVCRT_DLL}
                    Name: 'msvcrt';
                    SysLib: True;
{$ELSE}
                    Name: 'myutil';
                    SysLib: False;
{$ENDIF}
                    Version: -1;
                    Fixup: MyUtilFixupStubs;
                    Unfix: MyUtilUnfixStubs;
                  ),
                  (
                    Lib: libSoundTouch;
                    Name: 'SoundTouch';
                    SysLib: False;
                    Version: -1;
                    Fixup: SoundTouchFixupStubs;
                    Unfix: SoundTouchUnfixStubs;
                  )
                );

type
  PMyMutex = ^TMyMutex;
  TMyMutex = record
    ID: PPointer;
    Mutex: TMutex;
    Next: PMyMutex;
  end;

var
  FDisableMutex: Boolean = False;
  FMutex: PMyMutex = nil;
  FLock: TCriticalSection;
  FLastErrMsg: string = '';
  FLibraryPath: TPathFileName = '';
  FLibraries: array[TLibrary] of TLibraryStatus = (
                  (Lib: avCodec;    Name: ''; Handle: 0; Fixuped: False;),
                  (Lib: avDevice;   Name: ''; Handle: 0; Fixuped: False;),
                  (Lib: avFilter;   Name: ''; Handle: 0; Fixuped: False;),
                  (Lib: avFormat;   Name: ''; Handle: 0; Fixuped: False;),
                  (Lib: avUtil;     Name: ''; Handle: 0; Fixuped: False;),
                  (Lib: swResample; Name: ''; Handle: 0; Fixuped: False;),
                  (Lib: swScale;    Name: ''; Handle: 0; Fixuped: False;),
                  (Lib: myUtil;     Name: ''; Handle: 0; Fixuped: False;),
                  (Lib: libSoundTouch; Name: ''; Handle: 0; Fixuped: False;)
                );

function FetchMutex(ID: PPointer): PMyMutex;
var
  P: PMyMutex;
begin
  FLock.Acquire;
  try
    if not Assigned(PMyMutex(ID^)) then
    begin
      New(P);
      PMyMutex(ID^) := P;
      P.ID := ID;
      P.Mutex := nil;
      P.Next := FMutex;
      FMutex := P;
    end;

    Assert(PMyMutex(ID^).ID = ID);
    Result := PMyMutex(ID^);
  finally
    FLock.Release;
  end;
end;

procedure DeleteMutex(AMutex: PMyMutex);
var
  P: PMyMutex;
begin
  FLock.Acquire;
  try
    Assert(FMutex <> nil);
    if FMutex = AMutex then
      FMutex := AMutex.Next
    else
    begin
      P := FMutex;
      while P.Next <> AMutex do
        P := P.Next;
      Assert(P <> nil);
      P.Next := AMutex.Next;
    end;
    P := AMutex;
    P.ID^ := nil;
    if P.Mutex <> nil then
    begin
      P.Mutex.Free;
      P.Mutex := nil;
    end;
    Dispose(P);
  finally
    FLock.Release;
  end;
end;

procedure FreeMutex;
var
  P: PMyMutex;
begin
  while Assigned(FMutex) do
  begin
    P := FMutex;
    if P.Mutex <> nil then
    begin
      P.Mutex.Free;
      P.Mutex := nil;
    end;
    FMutex := P.Next;
    Dispose(P);
  end;
end;

function ff_lockmgr_cb(mutex: PPointer; op: TAVLockOp): Integer; cdecl;
var
  P: PMyMutex;
begin
  if FDisableMutex then
  begin
    Result := 0;
    Exit;
  end;
(*
   switch(op) {
      case AV_LOCK_CREATE:
          *mtx = SDL_CreateMutex();
          if(!*mtx)
              return 1;
          return 0;
      case AV_LOCK_OBTAIN:
          return !!SDL_LockMutex(*mtx);
      case AV_LOCK_RELEASE:
          return !!SDL_UnlockMutex(*mtx);
      case AV_LOCK_DESTROY:
          SDL_DestroyMutex(*mtx);
          return 0;
   }
   return 1;
*)
  P := FetchMutex(mutex);
  case op of
    AV_LOCK_CREATE:
      begin
        if P.Mutex <> nil then
        begin
          // error, mutex already exist
          FFLogger.Log(nil, llError, '[lock manager] error, mutex [%d] already exist.', [Integer(P.Mutex)]);
          Result := -1;
        end
        else
        begin
          // create mutex, with initial value signaled
          P.Mutex := TMutex.Create();
          if P.Mutex = nil then
          begin
            // error, failed to create mutex
            FFLogger.Log(nil, llError, '[lock manager] error, failed to create mutex: %s.',
                          [SysErrorMessage(GetLastError)]);
            Result := -1;
          end
          else
          begin
            FFLogger.Log(nil, llDebug, '[lock manager] mutex [%d] created.', [Integer(P.Mutex)]);
            Result := 0
          end;
        end;
      end;
    AV_LOCK_OBTAIN:
      begin
        if P.Mutex = nil then
        begin
          // error, mutex not available
          FFLogger.Log(nil, llError, '[lock manager] error, mutex not available.');
          Result := -1;
        end
        else if P.Mutex.WaitFor(INFINITE) = wrError then
        begin
          // error, could not wait on mutex
          FFLogger.Log(nil, llError, '[lock manager] error, could not wait on mutex [%d]: %s.',
                        [Integer(P.Mutex), SysErrorMessage(GetLastError)]);
          Result := -1;
        end
        else
        begin
          FFLogger.Log(nil, llDebug, '[lock manager] mutex [%d] obtained.', [Integer(P.Mutex)]);
          Result := 0;
        end;
      end;
    AV_LOCK_RELEASE:
      begin
        if P.Mutex = nil then
        begin
          // error, mutex not available
          FFLogger.Log(nil, llError, '[lock manager] error, mutex not available.');
          Result := -1;
        end
        else
        begin
          try
            P.Mutex.Release;
            FFLogger.Log(nil, llDebug, '[lock manager] mutex [%d] release.', [Integer(P.Mutex)]);
            Result := 0;
          except on E: Exception do
            begin
              // error, could not release mutex
              FFLogger.Log(nil, llError, '[lock manager] error, could not release mutex [%d]: %s.',
                            [Integer(P.Mutex), E.Message]);
              Result := -1;
            end;
          end;
        end;
      end;
    AV_LOCK_DESTROY:
      begin
        if P.Mutex = nil then
        begin
          // error, mutex not available
          FFLogger.Log(nil, llError, '[lock manager] error, mutex not available.');
          Result := -1;
        end
        else
        begin
          // destroy mutex
          FFLogger.Log(nil, llDebug, '[lock manager] mutex [%d] destroyed.', [Integer(P.Mutex)]);
          P.Mutex.Free;
          P.Mutex := nil;
          Result := 0;
        end;
        DeleteMutex(P);
      end
  else
        // never occur
        FFLogger.Log(nil, llError, '[lock manager] error, invalid mutex operation %d.', [Ord(op)]);
        Result := -1;
  end;
end;

{ TFFLoader }

constructor TFFLoader.Create;
begin
  FInstallLogger := True;
end;

function TFFLoader.GetLastErrMsg: string;
begin
  Result := FLastErrMsg;
end;

function TFFLoader.GetLibraryPath: TPathFileName;
begin
  Result := FLibraryPath;
end;

procedure TFFLoader.SetLibraryPath(const Value: TPathFileName);
begin
  FLibraryPath := Value;
end;

function TFFLoader.GetLibraryName(Index: TLibrary): TPathFileName;
const
{$IFDEF MSWINDOWS}
  CExtDLL = '.dll';
{$ENDIF}
{$IFDEF POSIX}
  CExtDLL = '.dylib';
{$ENDIF}
begin
  Result := FLibraries[Index].Name;
  if Result = '' then
  begin
    Result := CLibraries[Index].Name;
    if CLibraries[Index].Version >= 0 then
{$IFDEF MSWINDOWS}
      Result := Result + '-' + IntToStr(CLibraries[Index].Version);
{$ENDIF}
{$IFDEF POSIX}
      Result := Result + '.' + IntToStr(CLibraries[Index].Version);
    Result := 'lib' + Result;
{$ENDIF}
    Result := Result + CExtDLL;
  end;
end;

procedure TFFLoader.SetLibraryName(Index: TLibrary; const Value: TPathFileName);
begin
  Unload(Index);
  FLibraries[Index].Name := Value;
end;

function TFFLoader.Load(ALibrary: TLibrary): Boolean;
var
  LPath: TPathFileName;
  LFile: TPathFileName;
  LHandle: THandle;
  LErrorCode: DWORD;
begin
{$IFDEF NEED_HASH}
  if not CheckSum then
  begin
{$IFDEF MSWINDOWS}
{$IFDEF VCL_XE2_OR_ABOVE}
    if System.SysUtils.SysLocale.PriLangID = LANG_CHINESE then
{$ELSE}
    if SysUtils.SysLocale.PriLangID = LANG_CHINESE then
{$ENDIF}
      FLastErrMsg := SWebSiteC
    else
{$ENDIF}
      FLastErrMsg := SWebSiteE;
    Result := False;
    Exit;
  end;
{$ENDIF}
  if FLibraries[ALibrary].Handle = 0 then
  begin
    LFile := GetLibraryName(ALibrary);
    LPath := ExtractFilePath(LFile);
    if (LPath = '') and (FLibraryPath <> '') and not CLibraries[ALibrary].SysLib then
      LPath := IncludeTrailingPathDelimiter(FLibraryPath);
    LFile := ExtractFileName(LFile);
    LHandle := MyLoadLibrary(LPath, LFile, LErrorCode);
    if LHandle = 0 then
    begin
      FLastErrMsg := Format('Load library %s error: %s', [LPath + LFile, SysErrorMessage(LErrorCode)]);
      Result := False;
      Exit;
    end;
    FLibraries[ALibrary].Handle := LHandle;
  end;

  if not FLibraries[ALibrary].Fixuped then
  begin
    try
      CLibraries[ALibrary].Fixup(LibraryNames[ALibrary], FLibraries[ALibrary].Handle);
      FLibraries[ALibrary].Fixuped := True;
    except on E: Exception do
      FLastErrMsg := E.Message;
    end;
  end;

  if not FLibraries[ALibrary].Fixuped then
    Unload(ALibrary);

  Result := FLibraries[ALibrary].Fixuped;

  if Result and (ALibrary = avCodec) then
    av_lockmgr_register(ff_lockmgr_cb);

  if Result and (ALibrary = avUtil) and FInstallLogger then
    FFLogger.InstallAVLogCallback;

  if Result and (ALibrary = avFormat) then
    register_unicode_protocol;
end;

function TFFLoader.Load(ALibraries: TLibraries): Boolean;
var
  I: TLibrary;
begin
  Assert(ALibraries <> []);
  for I := Low(TLibrary) to High(TLibrary) do
  begin
    if I in ALibraries then
    begin
      if not Load(I) then
      begin
        Unload(ALibraries);
        Result := False;
        Exit;
      end;
    end;
  end;
  Result := True;
end;

function TFFLoader.Loaded(ALibrary: TLibrary): Boolean;
begin
  Result := (FLibraries[ALibrary].Handle <> 0) and FLibraries[ALibrary].Fixuped;
end;

function TFFLoader.Loaded(ALibraries: TLibraries): Boolean;
var
  I: TLibrary;
begin
  Assert(ALibraries <> []);
  for I := Low(TLibrary) to High(TLibrary) do
  begin
    if I in ALibraries then
    begin
      if not Loaded(I) then
      begin
        Result := False;
        Exit;
      end;
    end;
  end;
  Result := True;
end;

procedure TFFLoader.CheckLibAV(ALibraries: TLibraries);
var
  I: TLibrary;
begin
  for I := Low(TLibrary) to High(TLibrary) do
  begin
    if I in ALibraries then
      if not Loaded(I) then
        raise Exception.CreateFmt('Library %s not loaded.', [CLibraries[I].Name]);
  end;
end;

procedure TFFLoader.Unload(ALibrary: TLibrary);
begin
  if FLibraries[ALibrary].Fixuped then
  begin
    if ALibrary = avCodec then
      av_lockmgr_register(nil);
    CLibraries[ALibrary].Unfix;
    FLibraries[ALibrary].Fixuped := False;
  end;
  if FLibraries[ALibrary].Handle <> 0 then
  begin
    FreeLibrary(FLibraries[ALibrary].Handle);
    FLibraries[ALibrary].Handle := 0;
  end;
end;

procedure TFFLoader.Unload(ALibraries: TLibraries);
var
  I: TLibrary;
begin
  Assert(ALibraries <> []);
  for I := Low(TLibrary) to High(TLibrary) do
    if I in ALibraries then
      Unload(I);
end;

var
  Saved8087CW: Word;

initialization
  FLock := TCriticalSection.Create;
  FFLoader := TFFLoader.Create;
  Saved8087CW := Get8087CW; // Default8087CW;
  Set8087CW($133F); { Disable all fpu exceptions }

finalization
  Set8087CW(Saved8087CW);
  FDisableMutex := True;
  FFLoader.Unload(CAllLibraries);
  FreeMutex;
  FLock.Free;
  FreeAndNil(FFLoader);

end.
