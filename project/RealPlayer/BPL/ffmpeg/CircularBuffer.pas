(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of circular buffer.
 * Created by CodeCoolie@CNSW 2012/03/10 -> $Date:: 2013-06-04 #$
 *)

unit CircularBuffer;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  {$IFDEF POSIX}
    Posix.UniStd,
  {$ENDIF POSIX}
  System.Classes,
  System.SyncObjs;
{$ELSE}
  Windows,
  Classes,
  SyncObjs;
{$ENDIF}

type
  TCircularBuffer = class
  private
    FMemory: Pointer;
    FCapacity: Integer;
    FHead: Integer;
    FTail: Integer;
    FWriteCount: Integer;
    FReadCount: Integer;
    FLock: TCriticalSection;
    FDataEvent: TEvent;
    FSpaceEvent: TEvent;
    FAutoGrow: Boolean;
    FAutoGrowMax: Integer;
    FWaitForData: Boolean;
    FWaitForSpace: Boolean;
    FEndOfWriting: Boolean;
    FTerminated: Boolean;

    function _IsEmpty: Boolean;
    function _DataSize: Integer;
    function _SpaceSize: Integer;
    function _Realloc(var NewCapacity: Integer): Pointer;
    procedure _SetCapacity(NewCapacity: Integer);
    procedure SetCapacity(NewCapacity: Integer);
  public
    constructor Create; overload;
    constructor Create(ACapacity: Integer); overload;
    destructor Destroy; override;

    procedure InitBuffer(NewCapacity: Integer);
    procedure FreeBuffer;
    procedure Reset;
    procedure EndWriting;
    procedure Terminate;
    function IsEmpty: Boolean;
    function IsFull: Boolean;
    function DataSize: Integer;
    function Discard(Count: Integer): Integer;
    function SpaceSize: Integer;
    function Read(var Buffer; Count: Integer): Integer;
    function Write(const Buffer; Count: Integer): Integer;

    property Capacity: Integer read FCapacity write SetCapacity;
    property AutoGrow: Boolean read FAutoGrow write FAutoGrow;
    property AutoGrowMax: Integer read FAutoGrowMax write FAutoGrowMax;
    property WaitForData: Boolean read FWaitForData write FWaitForData;
    property WaitForSpace: Boolean read FWaitForSpace write FWaitForSpace;
    property ReadCount: Integer read FReadCount;
    property WriteCount: Integer read FWriteCount;
    property EndOfWriting: Boolean read FEndOfWriting;
    property Terminated: Boolean read FTerminated;
  end;

  TCircularBufferStream = class(TStream)
  private
    FBuffer: TCircularBuffer;
    FSize: Integer;
    FPosition: Integer;
  protected
{$IFNDEF VER140} // Delphi 6
    function GetSize: Int64; override;
{$ENDIF}
    procedure SetSize(NewSize: Integer); override;
  public
    constructor Create; overload;
    constructor Create(ACapacity: Integer); overload;
    destructor Destroy; override;

    function Write(const Buffer; Count: Integer): Integer; override;
    function Read(var Buffer; Count: Integer): Integer; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;

    property Buffer: TCircularBuffer read FBuffer;
  end;

implementation

{ TCircularBuffer }

const
  MemoryAlign     = $2000;    // 8192, 8 KB, Must be a power of 2
  DefaultCapacity = $100000;  // 1024 * 1024, 1 MB
  AutoMaxCapacity = $1000000; // 1024 * 1024 * 16, 16 MB

constructor TCircularBuffer.Create;
begin
  Create(DefaultCapacity);
end;

constructor TCircularBuffer.Create(ACapacity: Integer);
begin
  inherited Create;
  FAutoGrow := True;
  FAutoGrowMax := AutoMaxCapacity;
  FWaitForData := True;
  FWaitForSpace := True;
  FLock := TCriticalSection.Create;
  FDataEvent := TEvent.Create(nil, True, False, '');
  FSpaceEvent := TEvent.Create(nil, True, False, '');
  InitBuffer(ACapacity);
end;

destructor TCircularBuffer.Destroy;
begin
  FreeBuffer;
  FDataEvent.Free;
  FSpaceEvent.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TCircularBuffer.InitBuffer(NewCapacity: Integer);
begin
  SetCapacity(NewCapacity);
  Reset;
end;

procedure TCircularBuffer.FreeBuffer;
begin
  Terminate;
  SetCapacity(0);
end;

procedure TCircularBuffer.Reset;
begin
  FLock.Acquire;
  try
    FHead := 0;
    FTail := 0;
    FWriteCount := 0;
    FReadCount := 0;
    FEndOfWriting := False;
    FTerminated := False;
    //FDataEvent.SetEvent;
    FSpaceEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

procedure TCircularBuffer.EndWriting;
begin
  FLock.Acquire;
  try
    FEndOfWriting := True;
    FDataEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

procedure TCircularBuffer.Terminate;
begin
  FLock.Acquire;
  try
    FTerminated := True;
    FDataEvent.SetEvent;
    FSpaceEvent.SetEvent;
  finally
    FLock.Release;
  end;
  // sleep for safety
{$IFDEF MSWINDOWS}
  Sleep(10);
{$ENDIF}
{$IFDEF POSIX}
  usleep(10 * 1000);
{$ENDIF}
end;

function TCircularBuffer.IsEmpty: Boolean;
begin
  FLock.Acquire;
  try
    Result := _IsEmpty;
  finally
    FLock.Release;
  end;
end;

function TCircularBuffer.IsFull: Boolean;
begin
  FLock.Acquire;
  try
    Result := ((FTail + 1) mod FCapacity) = FHead;
  finally
    FLock.Release;
  end;
end;

function TCircularBuffer.DataSize: Integer;
begin
  FLock.Acquire;
  try
    Result := _DataSize;
  finally
    FLock.Release;
  end;
end;

function TCircularBuffer.SpaceSize: Integer;
begin
  FLock.Acquire;
  try
    Result := _SpaceSize;
  finally
    FLock.Release;
  end;
end;

function TCircularBuffer._IsEmpty: Boolean;
begin
  Result := FHead = FTail;
end;

function TCircularBuffer._DataSize: Integer;
begin
  Result := (FCapacity + FTail - FHead) mod FCapacity;
end;

function TCircularBuffer._SpaceSize: Integer;
begin
  Result := (FCapacity + FHead - FTail - 1) mod FCapacity;
end;

function TCircularBuffer.Discard(Count: Integer): Integer;
begin
  if FTerminated then
  begin
    Result := -1;
    Exit;
  end;

  FLock.Acquire;
  try
    if Count > _DataSize then
      Count := _DataSize;
    FHead := (FHead + Count) mod FCapacity;
    //Inc(FReadCount, Count);
    Result := Count;
    FSpaceEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

function TCircularBuffer.Read(var Buffer; Count: Integer): Integer;
begin
{$IF Defined(VER150)} // Delphi 7
  Result := 0; // stop compiler warning
{$IFEND}

  while not FTerminated do
  begin
    FLock.Acquire;
    try
      if not _IsEmpty then
        Break
      else if FEndOfWriting then
      begin
        Result := -1;
        Exit;
      end
      else
        FDataEvent.ResetEvent;
    finally
      FLock.Release;
    end;

    if FWaitForData then
    begin
      if FDataEvent.WaitFor(INFINITE) <> wrSignaled then
      begin
        Result := -1;
        Exit;
      end;
    end
    else
    begin
      Result := 0;
      Exit;
    end;
  end;

  if FTerminated then
  begin
    Result := -1;
    Exit;
  end;

  FLock.Acquire;
  try
    if Count > _DataSize then
      Count := _DataSize;
    if Count < FCapacity - FHead then
      Move((PAnsiChar(FMemory) + FHead)^, Buffer, Count)
    else
    begin
      Move((PAnsiChar(FMemory) + FHead)^, Buffer, FCapacity - FHead);
      Move(FMemory^, (PAnsiChar(@Buffer) + FCapacity - FHead)^, Count - (FCapacity - FHead));
    end;
    FHead := (FHead + Count) mod FCapacity;
    Inc(FReadCount, Count);
    Result := Count;
    FSpaceEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

function CalculateNewCapacity(ACapacity, ASpaceSize, ANewCount: Integer): Integer;
var
  Delta: Integer;
begin
  repeat
    if ACapacity > 64 then
      Delta := ACapacity div 4
    else
      if ACapacity > 8 then
        Delta := 16
      else
        Delta := 4;
    Inc(ACapacity, Delta);
  until Delta > ANewCount - ASpaceSize;
  Result := ACapacity;
end;

function TCircularBuffer.Write(const Buffer; Count: Integer): Integer;
begin
  while not FTerminated do
  begin
    FLock.Acquire;
    try
      if Count > _SpaceSize then
      begin
        if FAutoGrow and (FCapacity < FAutoGrowMax) or (Count >= FCapacity) then
        begin
          //_SetCapacity(FCapacity + Count - _SpaceSize);
          _SetCapacity(CalculateNewCapacity(FCapacity, _SpaceSize, Count));
          Break;
        end
        else
          FSpaceEvent.ResetEvent;
      end
      else
        Break;
    finally
      FLock.Release;
    end;

    if FWaitForSpace then
    begin
      if FSpaceEvent.WaitFor(INFINITE) <> wrSignaled then
      begin
        Result := -1;
        Exit;
      end;
    end
    else
    begin
      Result := 0;
      Exit;
    end;
  end;

  if FTerminated then
  begin
    Result := -1;
    Exit;
  end;

  FLock.Acquire;
  try
    if Count < FCapacity - FTail then
      Move(Buffer, (PAnsiChar(FMemory) + FTail)^, Count)
    else
    begin
      Move(Buffer, (PAnsiChar(FMemory) + FTail)^, FCapacity - FTail);
      Move((PAnsiChar(@Buffer) + FCapacity - FTail)^, FMemory^, Count - (FCapacity - FTail));
    end;
    FTail := (FTail + Count) mod FCapacity;
    Inc(FWriteCount, Count);
    Result := Count;
    FDataEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

procedure TCircularBuffer.SetCapacity(NewCapacity: Integer);
begin
  FLock.Acquire;
  try
    _SetCapacity(NewCapacity);
  finally
    FLock.Release;
  end;
end;

procedure TCircularBuffer._SetCapacity(NewCapacity: Integer);
begin
  FMemory := _Realloc(NewCapacity);
  FCapacity := NewCapacity;
end;

function TCircularBuffer._Realloc(var NewCapacity: Integer): Pointer;
begin
  Assert(NewCapacity >= 0);
  if NewCapacity > 0 then
    NewCapacity := (NewCapacity + (MemoryAlign - 1)) and not (MemoryAlign - 1);
  Result := FMemory;
  if NewCapacity <> FCapacity then
  begin
    if NewCapacity = 0 then
    begin
      FreeMem(FMemory);
      Result := nil;
      FHead := 0;
      FTail := 0;
    end
    else
    begin
      if FCapacity = 0 then
        GetMem(Result, NewCapacity)
      else
      begin
        ReallocMem(Result, NewCapacity);
        // defragment to preserve current data
        if (NewCapacity > FCapacity) and (FHead > FTail) then
        begin
          if FTail = 0 then
            FTail := FCapacity
          else if (NewCapacity - FCapacity) > FTail then
          begin
            Move(Result^, (PAnsiChar(Result) + FCapacity)^, FTail);
            FTail := FCapacity + FTail;
          end
          else
          begin
            Move(Result^, (PAnsiChar(Result) + FCapacity)^, NewCapacity - FCapacity);
            Move((PAnsiChar(Result) + NewCapacity - FCapacity)^, Result^, FTail - (NewCapacity - FCapacity));
            FTail := FTail - (NewCapacity - FCapacity);
          end;
        end;
      end;
      if FHead > NewCapacity - 1 then
        FHead := NewCapacity - 1;
      if FTail > NewCapacity - 1 then
        FTail := NewCapacity - 1;
    end;
  end;
end;

{ TCircularBufferStream }

constructor TCircularBufferStream.Create;
begin
  Create(DefaultCapacity);
end;

constructor TCircularBufferStream.Create(ACapacity: Integer);
begin
  inherited Create;
  FBuffer := TCircularBuffer.Create(ACapacity);
end;

destructor TCircularBufferStream.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

{$IFNDEF VER140} // Delphi 6
function TCircularBufferStream.GetSize: Int64;
begin
  Result := FSize;
end;
{$ENDIF}

procedure TCircularBufferStream.SetSize(NewSize: Integer);
begin
  FSize := NewSize;
  if FPosition > NewSize then
    Seek(0, soFromEnd);
end;

function TCircularBufferStream.Read(var Buffer; Count: Integer): Integer;
begin
{
  if (FPosition >= 0) and (Count >= 0) then
  begin
    Result := FSize - FPosition;
    if Result > 0 then
    begin
      if Result > Count then
        Result := Count;
      Result := FBuffer.Read(Buffer, Result);
      if Result > 0 then
        Inc(FPosition, Result);
      Exit;
    end;
  end;
  Result := 0;
}
  Result := FBuffer.Read(Buffer, Count);
end;

function TCircularBufferStream.Write(const Buffer; Count: Integer): Integer;
var
  Pos: Longint;
begin
  if (FPosition >= 0) and (Count >= 0) then
  begin
    Pos := FPosition + Count;
    if Pos > 0 then
    begin
      if Pos > FSize then
        FSize := Pos;
      Result := FBuffer.Write(Buffer, Count);
      if Result > 0 then
        Inc(FPosition, Result);
      Exit;
    end;
  end;
  Result := 0;
end;

function TCircularBufferStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  case Origin of
    soBeginning: FPosition := Offset;
    soCurrent: Inc(FPosition, Offset);
    soEnd: FPosition := FSize + Offset;
  end;
  Result := FPosition;
end;

end.
