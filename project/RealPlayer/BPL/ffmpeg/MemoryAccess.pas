(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * Adapter of MemoryAccess
 * Created by CodeCoolie@CNSW 2008/09/23 -> $Date:: 2012-12-15 #$
 *)

unit MemoryAccess;

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
  libavformat_url,

  MemoryProtocol,
  FFBaseComponent;

type
  TMemoryAccessAdapter = class(TFFBaseComponent)
  private
    FStream: TCustomEventStream;
    FData: Pointer;
    function GetFlags: Integer;
    function GetOnClose: TNotifyEvent;
    function GetOnOpen: TStreamOpenEvent;
    function GetOnRead: TStreamReadEvent;
    function GetOnSeek: TStreamSeekEvent;
    function GetOnWrite: TStreamWriteEvent;
    function GetOpened: Boolean;
    function GetPrivateData: string;
    function GetURLContext: PURLContext;
    procedure SetOnClose(const Value: TNotifyEvent);
    procedure SetOnOpen(const Value: TStreamOpenEvent);
    procedure SetOnRead(const Value: TStreamReadEvent);
    procedure SetOnSeek(const Value: TStreamSeekEvent);
    procedure SetOnWrite(const Value: TStreamWriteEvent);
    function GetTriggerEventInMainThread: Boolean;
    procedure SetTriggerEventInMainThread(const Value: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Stream: TCustomEventStream read FStream;
    property Opened: Boolean read GetOpened;
    property URLContext: PURLContext read GetURLContext;
    property PrivateData: string read GetPrivateData;
    property Flags: Integer read GetFlags;
    property UserData: Pointer read FData write FData;
  published
    property TriggerEventInMainThread: Boolean read GetTriggerEventInMainThread write SetTriggerEventInMainThread default True;
    property OnOpen: TStreamOpenEvent read GetOnOpen write SetOnOpen;
    property OnClose: TNotifyEvent read GetOnClose write SetOnClose;
    property OnRead: TStreamReadEvent read GetOnRead write SetOnRead;
    property OnWrite: TStreamWriteEvent read GetOnWrite write SetOnWrite;
    property OnSeek: TStreamSeekEvent read GetOnSeek write SetOnSeek;
  end;

implementation

{ TMemoryAccessAdapter }

constructor TMemoryAccessAdapter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStream := TCustomEventStream.Create;
  FStream.TriggerEventInMainThread := True;
end;

destructor TMemoryAccessAdapter.Destroy;
begin
  if Assigned(FStream) then
    FreeAndNil(FStream);
  inherited Destroy;
end;

function TMemoryAccessAdapter.GetFlags: Integer;
begin
  Result := FStream.Flags;
end;

function TMemoryAccessAdapter.GetOnClose: TNotifyEvent;
begin
  Result := FStream.OnClose;
end;

function TMemoryAccessAdapter.GetOnOpen: TStreamOpenEvent;
begin
  Result := FStream.OnOpen;
end;

function TMemoryAccessAdapter.GetOnRead: TStreamReadEvent;
begin
  Result := FStream.OnRead;
end;

function TMemoryAccessAdapter.GetOnSeek: TStreamSeekEvent;
begin
  Result := FStream.OnSeek;
end;

function TMemoryAccessAdapter.GetOnWrite: TStreamWriteEvent;
begin
  Result := FStream.OnWrite;
end;

function TMemoryAccessAdapter.GetOpened: Boolean;
begin
  Result := FStream.Opened;
end;

function TMemoryAccessAdapter.GetPrivateData: string;
begin
  Result := FStream.PrivateData;
end;

function TMemoryAccessAdapter.GetTriggerEventInMainThread: Boolean;
begin
  Result := FStream.TriggerEventInMainThread;
end;

function TMemoryAccessAdapter.GetURLContext: PURLContext;
begin
  Result := FStream.URLContext;
end;

procedure TMemoryAccessAdapter.SetOnClose(const Value: TNotifyEvent);
begin
  FStream.OnClose := Value;
end;

procedure TMemoryAccessAdapter.SetOnOpen(const Value: TStreamOpenEvent);
begin
  FStream.OnOpen := Value;
end;

procedure TMemoryAccessAdapter.SetOnRead(const Value: TStreamReadEvent);
begin
  FStream.OnRead := Value;
end;

procedure TMemoryAccessAdapter.SetOnSeek(const Value: TStreamSeekEvent);
begin
  FStream.OnSeek := Value;
end;

procedure TMemoryAccessAdapter.SetOnWrite(const Value: TStreamWriteEvent);
begin
  FStream.OnWrite := Value;
end;

procedure TMemoryAccessAdapter.SetTriggerEventInMainThread(const Value: Boolean);
begin
  FStream.TriggerEventInMainThread := Value;
end;

end.
