//------------------------------------------------------------------------------
//
//      �������
//
//                                                 @2015-03-06 ����
//------------------------------------------------------------------------------
//{$INCLUDE '..\TypeDef.inc'}


unit USocket;
interface
uses
  IdIPWatch, WinInet, Windows, WinSock;
type
  //IP��ַ��ȡ����
  TaPInAddr = array[0..10] of PInAddr;
  PaPInAddr = ^TaPInAddr;

//��ȡIP
function GetLocalIp:WideString;stdcall;

function GetIP: WideString; stdcall;
//�����Ƿ����
function CheckOffline: boolean;stdcall;

implementation

function GetLocalIp:WideString;stdcall;
var
	IdIPWatch1:TIdIPWatch;
begin
	IdIPWatch1:=TIdIPWatch.Create(nil);
  IdIPWatch1.HistoryEnabled:=False;
//  IdIPWatch.Active := False;
  Result:= IdIPWatch1.LocalIP;
  IdIPWatch1.Free;
end;

function GetIP: WideString; stdcall;
//��ȡ���ؼ����IP��ַ�����Ի�ȡ����������
  function StrPas(const Str: PChar): string;
  begin
    Result := Str;
  end;
var
  phe: PHostEnt;
  pptr: PaPInAddr;
  Buffer: array[0..63] of Ansichar;
  I: Integer;
  GInitData: TWSADATA;
begin
  WSAStartup($101, GInitData);
  Result := ' ';
  GetHostName(Buffer, SizeOf(Buffer));
  phe := GetHostByName(buffer);
  if phe = nil then Exit;
  pptr := PaPInAddr(Phe^.h_addr_list);
  I := 0;
  while pptr^[I] <> nil do begin
//   if i = 0 then result := WideString(StrPas(inet_ntoa(pptr^[I]^)))
//   else result :=result + ', ' +WideString(StrPas(inet_ntoa(pptr^[I]^)));
//   Inc(I);
  end;
  WSACleanup;
end;

function CheckOffline: boolean;stdcall;
var
  ConnectState: DWORD;
  StateSize: DWORD;
begin
  ConnectState:= 0;
  StateSize:= SizeOf(ConnectState);
  result:= false;
  if InternetQueryOption(nil, INTERNET_OPTION_CONNECTED_STATE, @ConnectState, StateSize) then
  if (ConnectState and INTERNET_STATE_DISCONNECTED) <> 2 then result:= true;
end;


exports
GetLocalIp       {$IFDEF CDLE}name 'OxS00000001'{$ENDIF}, //��ȡIP
GetIP            {$IFDEF CDLE}name 'OxS00000002'{$ENDIF},
CheckOffline     {$IFDEF CDLE}name 'OxS00000003'{$ENDIF}; //�����Ƿ����

end.
