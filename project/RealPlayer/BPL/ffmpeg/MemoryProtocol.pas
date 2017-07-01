(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * Memory I/O protocol
 * Using stream object as input/output handle
 * Created by CodeCoolie@CNSW 2008/09/21 -> $Date:: 2013-03-11 #$
 *)
(*
 * filename format: "memory:<integer value of stream object>[:other user private data]"
 *)

unit MemoryProtocol;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.SysUtils,
  System.Classes,
{$ELSE}
  SysUtils,
  Classes,
{$ENDIF}

  libavformat_avio,
  libavformat_url;

type
  PMemoryContext = ^TMemoryContext;
  TMemoryContext = record
    Context: PURLContext;
    Stream: TStream;
    Flags: Integer;
  end;

  TStreamOpenEvent = function(Sender: TObject; AURLContext: Pointer;
    const APrivateData: string; AFlags: Integer): Boolean of object;
{$IF Defined(VER140) or Defined(BCB)} // Delphi 6.0 or BCB
  TStreamReadEvent = function(Sender: TObject; Buffer: PByte; Count: Longint): Longint of object;
  TStreamWriteEvent = function(Sender: TObject; Buffer: PByte; Count: Longint): Longint of object;
{$ELSE}
  TStreamReadEvent = function(Sender: TObject; var Buffer; Count: Longint): Longint of object;
  TStreamWriteEvent = function(Sender: TObject; const Buffer; Count: Longint): Longint of object;
{$IFEND}
  TStreamSeekEvent = function(Sender: TObject; const Offset: Int64; Origin: TSeekOrigin): Int64 of object;

  TCustomEventStream = class(TStream)
  private
    FOpened: Boolean;
    FURLContext: PURLContext;
    FPrivateData: string;
    FFlags: Integer;
    FTriggerEventInMainThread: Boolean;
    FOnOpen: TStreamOpenEvent;
    FOnClose: TNotifyEvent;
    FOnRead: TStreamReadEvent;
    FOnWrite: TStreamWriteEvent;
    FOnSeek: TStreamSeekEvent;
    FOnOpenResult: Integer;
    FOnReadResult: Longint;
    FOnReadBuffer: PByte;
    FOnReadCount: Longint;
    FOnSeekResult: Int64;
    FOnSeekOffset: Int64;
    FOnSeekOrigin: TSeekOrigin;
    FOnWriteResult: Longint;
    FOnWriteBuffer: PByte;
    FOnWriteCount: Longint;
    procedure CallOpen;
    procedure CallClose;
    procedure CallRead;
    procedure CallSeek;
    procedure CallWrite;
  protected
    function Open(AURLContext: Pointer; const APrivateData: string; AFlags: Integer): Integer;
    procedure Close;
  public
    constructor Create;
    destructor Destroy; override;

    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;

    property Opened: Boolean read FOpened;
    property URLContext: PURLContext read FURLContext;
    property PrivateData: string read FPrivateData;
    property Flags: Integer read FFlags;
    property TriggerEventInMainThread: Boolean read FTriggerEventInMainThread write FTriggerEventInMainThread;
    property OnOpen: TStreamOpenEvent read FOnOpen write FOnOpen;
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
    property OnRead: TStreamReadEvent read FOnRead write FOnRead;
    property OnWrite: TStreamWriteEvent read FOnWrite write FOnWrite;
    property OnSeek: TStreamSeekEvent read FOnSeek write FOnSeek;
  end;

  TEventStream = class(TCustomEventStream);

function register_memory_protocol(ASilence: Boolean = False): Boolean;

implementation

uses
  AVUtilStubs,
  MyUtils,
  FFUtils,
  UnicodeProtocol;

{ TCustomEventStream }

constructor TCustomEventStream.Create;
begin
  FTriggerEventInMainThread := True;
end;

destructor TCustomEventStream.Destroy;
begin
  FOnOpen := nil;
  FOnClose := nil;
  FOnRead := nil;
  FOnWrite := nil;
  FOnSeek := nil;
end;

procedure TCustomEventStream.CallOpen;
begin
  if Assigned(FOnOpen) then
  begin
    if FOnOpen(Self, FURLContext, FPrivateData, FFlags) then
      FOnOpenResult := 0
    else
      FOnOpenResult := -1;
  end
  else
    FOnOpenResult := 0;
end;

function TCustomEventStream.Open(AURLContext: Pointer; const APrivateData: string; AFlags: Integer): Integer;
begin
  FURLContext := AURLContext;
  FPrivateData := APrivateData;
  FFlags := AFlags;
  if FTriggerEventInMainThread then
    MySynchronize(CallOpen)
  else
    CallOpen;
  Result := FOnOpenResult;
  FOpened := Result = 0;
end;

procedure TCustomEventStream.CallClose;
begin
  if Assigned(FOnClose) then
    FOnClose(Self);
end;

procedure TCustomEventStream.Close;
begin
  if FTriggerEventInMainThread then
    MySynchronize(CallClose)
  else
    CallClose;
  FOpened := False;
end;

procedure TCustomEventStream.CallRead;
begin
  if Assigned(FOnRead) then
{$IF Defined(VER140) or Defined(BCB)} // Delphi 6.0 or BCB
    FOnReadResult := FOnRead(Self, FOnReadBuffer, FOnReadCount)
{$ELSE}
    FOnReadResult := FOnRead(Self, FOnReadBuffer^, FOnReadCount)
{$IFEND}
  else
    FOnReadResult := -1;
end;

function TCustomEventStream.Read(var Buffer; Count: Integer): Longint;
begin
  FOnReadBuffer := @Buffer;
  FOnReadCount := Count;
  if FTriggerEventInMainThread then
    MySynchronize(CallRead)
  else
    CallRead;
  Result := FOnReadResult;
end;

procedure TCustomEventStream.CallSeek;
begin
  if Assigned(FOnSeek) then
    FOnSeekResult := FOnSeek(Self, FOnSeekOffset, FOnSeekOrigin)
  else
    FOnSeekResult := -1;
end;

function TCustomEventStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  FOnSeekOffset := Offset;
  FOnSeekOrigin := Origin;
  if FTriggerEventInMainThread then
    MySynchronize(CallSeek)
  else
    CallSeek;
  Result := FOnSeekResult;
end;

procedure TCustomEventStream.CallWrite;
begin
  if Assigned(FOnWrite) then
{$IF Defined(VER140) or Defined(BCB)} // Delphi 6.0 or BCB
    FOnWriteResult := FOnWrite(Self, FOnWriteBuffer, FOnWriteCount)
{$ELSE}
    FOnWriteResult := FOnWrite(Self, FOnWriteBuffer^, FOnWriteCount)
{$IFEND}
  else
    FOnWriteResult := -1;
end;

function TCustomEventStream.Write(const Buffer; Count: Integer): Longint;
begin
  FOnWriteBuffer := @Buffer;
  FOnWriteCount := Count;
  if FTriggerEventInMainThread then
    MySynchronize(CallWrite)
  else
    CallWrite;
  Result := FOnWriteResult;
end;

{ memory protocol }

function memory_open(h: PURLContext; const filename: PAnsiChar; flags: Integer): Integer; cdecl;
var
  s: string;
  st: TStream;
  ctx: PMemoryContext;
begin
  // filename format: "memory:<integer value of stream object>[:other user private data]"
  // extract <integer value of stream object>
  s := Trim(delphi_filename(filename));
  s := Copy(s, Pos(':', s) + 1, MaxInt);
  if Pos(':', s) > 0 then
    s := Copy(s, 1, Pos(':', s) - 1);
  st := TStream(StrToInt(s));
  // extract [:other user private data]
  s := Trim(delphi_filename(filename));
  s := Copy(s, Pos(':', s) + 1, MaxInt);
  if Pos(':', s) > 0 then
    s := Copy(s, Pos(':', s) + 1, MaxInt)
  else
    s := '';

  if not Assigned(st) then
    Result := -1
  else if st is TCustomEventStream then
    Result := (st as TCustomEventStream).Open(h, s, flags)
  else
    Result := 0;

  if Result = 0 then
  begin
    ctx := av_malloc(SizeOf(TMemoryContext));
    ctx.Context := h;
    ctx.Stream := st;
    ctx.Flags := flags;
    h.priv_data := ctx;
  end;
end;

function memory_read(h: PURLContext; buf: PAnsiChar; size: Integer): Integer; cdecl;
var
  ctx: PMemoryContext;
begin
  ctx := h.priv_data;
  if (ctx.Flags <> AVIO_FLAG_READ) and (ctx.Flags <> AVIO_FLAG_READ_WRITE) then
  begin
    //errno = EBADF;
    Result := -1;
  end
  else
    Result := ctx.Stream.Read(buf^, size);
end;

function memory_write(h: PURLContext; const buf: PAnsiChar; size: Integer): Integer; cdecl;
var
  ctx: PMemoryContext;
begin
  ctx := h.priv_data;
  if (ctx.Flags <> AVIO_FLAG_WRITE) and (ctx.Flags <> AVIO_FLAG_READ_WRITE) then
  begin
    //errno = EBADF;
    Result := -1;
  end
  else
    Result := ctx.Stream.Write(buf^, size);
end;

function memory_seek(h: PURLContext; pos: Int64; whence: Integer): Int64; cdecl;
begin
  if whence = {AVSEEK_SIZE}$10000 then
  begin
    Result := PMemoryContext(h.priv_data).Stream.Size
  end
  else
    Result := PMemoryContext(h.priv_data).Stream.Seek(pos, TSeekOrigin(whence));
end;

function memory_close(h: PURLContext): Integer; cdecl;
var
  ctx: PMemoryContext;
begin
  ctx := h.priv_data;
  if ctx.Stream is TCustomEventStream then
    (ctx.Stream as TCustomEventStream).Close;
  av_free(ctx);
  Result := 0;
end;

var
  memory_protocol: TURLProtocol = (
    name: 'memory';
    url_open: memory_open;
    url_read: memory_read;
    url_write: memory_write;
    url_seek: memory_seek;
    url_close: memory_close;
    next: nil;
    url_read_pause: nil;
    url_read_seek: nil;
  );

function register_memory_protocol(ASilence: Boolean): Boolean;
begin
  Result := RegisterProtocol(@memory_protocol);
  if not Result and not ASilence then
    raise Exception.Create('Failed to register memory protocol. It requires several private APIs of ffmpeg libraries.');
end;

end.
