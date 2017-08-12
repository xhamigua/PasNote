//------------------------------------------------------------------------------
//
//      ���windows����  ��Ӳ����ȡ
//
//                                                 @2015-03-06 ����
//------------------------------------------------------------------------------

//{$INCLUDE '..\TypeDef.inc'}
unit UWindows;
interface
uses
  Windows, SysUtils ,Nb30, Classes ,ShlObj, ActiveX, ComObj;
type
  TProcedure=procedure;
  WStr= WideString;


//��ʾˢ��������HzΪ��λ��
function GetDisplayFrequency: Integer;stdcall;
//��ȡ��һ��IDEӲ�̵����к�
function GetIdeSerialNumber: pchar;stdcall;
//cpuƵ��
function GetCPUSpeed: Double;stdcall;
//����������
function GetCPUType: WStr; stdcall;
//CPUƵ��
function GetComputerBasicFrequency: WStr;stdcall;
//CPU��Ʒ��Ϣ
function GetCPUinfo: WStr; stdcall;
//��ȡcpu��ΨһID
function GETCPUID:WStr;stdcall;
//���CPU
function GetCPU(): WStr; stdcall;
//��ü������  (����1)
function GetPCName(): WStr; stdcall;
//��ȡ���������(����2)
function GetHostName: WStr; stdcall;
//����û���
function GetPCUser(): WStr; stdcall;
//�ж�ϵͳ�Ƿ���64λϵͳ
function IsWin64: Boolean; stdcall;
//���Ի�ò���ϵͳ
function GetOS(): WStr; stdcall;
//��������ϵͳ�汾��Ϣ
function GetOsVersion: WStr; stdcall;
//��ü�����ֱ���
function GetResolucion(): WStr; stdcall;
//��ȡ��������Ϣ �����Ը��ݲ�ͬ��Ҫ����ִ���
function GetAdaPterInfo(lana: Ansichar; Scon: integer): WStr;stdcall;
//��ȡMAC��ַ
function GetMac(Scon: Integer): WStr; stdcall;
//������ݷ�ʽ
function CreateShortcut(Exe:string; Lnk:string = ''; Dir:string = '';ID:Integer = -1):Boolean;stdcall;
//���������
function GetDrivers:TStrings;stdcall;
//����ϵͳʱ��Ϊָ��ʱ��
procedure SetCurrTime(Dt: TDateTime); stdcall;
//��ջ���վ
procedure ClearRecycley;stdcall;
//����Ctrl+Alt+DEL
procedure SetCtrlAltDel(ff:Boolean);stdcall;
//
function GetUptime(): String; stdcall;
//
function GetTamanioDiscos(): String; stdcall;
//
function Kernel32Handle(): HMODULE;



implementation
uses
  Registry;

function GetDisplayFrequency: Integer; stdcall;
// ����������ص���ʾˢ��������HzΪ��λ��
var
  DeviceMode: TDeviceMode;
begin
  EnumDisplaySettings(nil, Cardinal(-1), DeviceMode);
  Result := DeviceMode.dmDisplayFrequency;
end;

function GetIdeSerialNumber : pchar;stdcall;
const IDENTIFY_BUFFER_SIZE = 512;
type
  TIDERegs = packed record
    bFeaturesReg     : BYTE; // Used for specifying SMART "commands".
    bSectorCountReg  : BYTE; // IDE sector count register
    bSectorNumberReg : BYTE; // IDE sector number register
    bCylLowReg       : BYTE; // IDE low order cylinder value
    bCylHighReg      : BYTE; // IDE high order cylinder value
    bDriveHeadReg    : BYTE; // IDE drive/head register
    bCommandReg      : BYTE; // Actual IDE command.
    bReserved        : BYTE; // reserved for future use.  Must be zero.
  end;
  TSendCmdInParams = packed record
    // Buffer size in bytes
    cBufferSize  : DWORD;
    // Structure with drive register values.
    irDriveRegs  : TIDERegs;
    // Physical drive number to send command to (0,1,2,3).
    bDriveNumber : BYTE;
    bReserved    : Array[0..2] of Byte;
    dwReserved   : Array[0..3] of DWORD;
    bBuffer      : Array[0..0] of Byte;  // Input buffer.
  end;
  TIdSector = packed record
    wGenConfig                 : Word;
    wNumCyls                   : Word;
    wReserved                  : Word;
    wNumHeads                  : Word;
    wBytesPerTrack             : Word;
    wBytesPerSector            : Word;
    wSectorsPerTrack           : Word;
    wVendorUnique              : Array[0..2] of Word;
    sSerialNumber              : Array[0..19] of CHAR;
    wBufferType                : Word;
    wBufferSize                : Word;
    wECCSize                   : Word;
    sFirmwareRev               : Array[0..7] of Char;
    sModelNumber               : Array[0..39] of Char;
    wMoreVendorUnique          : Word;
    wDoubleWordIO              : Word;
    wCapabilities              : Word;
    wReserved1                 : Word;
    wPIOTiming                 : Word;
    wDMATiming                 : Word;
    wBS                        : Word;
    wNumCurrentCyls            : Word;
    wNumCurrentHeads           : Word;
    wNumCurrentSectorsPerTrack : Word;
    ulCurrentSectorCapacity    : DWORD;
    wMultSectorStuff           : Word;
    ulTotalAddressableSectors  : DWORD;
    wSingleWordDMA             : Word;
    wMultiWordDMA              : Word;
    bReserved                  : Array[0..127] of BYTE;
  end;
  PIdSector = ^TIdSector;
  TDriverStatus = packed record
    // ���������صĴ�����룬�޴��򷵻�0
    bDriverError : Byte;
    // IDE����Ĵ��������ݣ�ֻ�е�bDriverError Ϊ SMART_IDE_ERROR ʱ��Ч
    bIDEStatus   : Byte;
    bReserved    : Array[0..1] of Byte;
    dwReserved   : Array[0..1] of DWORD;
  end;
  TSendCmdOutParams = packed record
    // bBuffer�Ĵ�С
    cBufferSize  : DWORD;
    // ������״̬
    DriverStatus : TDriverStatus;
    // ���ڱ�������������������ݵĻ�������ʵ�ʳ�����cBufferSize����
    bBuffer      : Array[0..0] of BYTE;
  end;
  var hDevice : THandle;
      cbBytesReturned : DWORD;
      ptr : PChar;
      SCIP : TSendCmdInParams;
      aIdOutCmd : Array [0..(SizeOf(TSendCmdOutParams)+IDENTIFY_BUFFER_SIZE-1)-1] of Byte;
      IdOutCmd  : TSendCmdOutParams absolute aIdOutCmd;
  procedure ChangeByteOrder( var Data; Size : Integer );
  var ptr : PChar;
      i : Integer;
      c : Char;
  begin
    ptr := @Data;
    for i := 0 to (Size shr 1)-1 do begin
      c := ptr^;
      ptr^ := (ptr+1)^;
      (ptr+1)^ := c;
      Inc(ptr,2);
    end;
 end;
begin
  Result := ''; // ��������򷵻ؿմ�
  if SysUtils.Win32Platform=VER_PLATFORM_WIN32_NT then begin// Windows NT, Windows 2000
      // ��ʾ! �ı����ƿ���������������������ڶ����������� '\\.\PhysicalDrive1\'
      hDevice := CreateFile( '\\.\PhysicalDrive0', GENERIC_READ or GENERIC_WRITE,
        FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0 );
  end else // Version Windows 95 OSR2, Windows 98
    hDevice := CreateFile( '\\.\SMARTVSD', 0, 0, nil, CREATE_NEW, 0, 0 );
    if hDevice=INVALID_HANDLE_VALUE then Exit;
   try
    FillChar(SCIP,SizeOf(TSendCmdInParams)-1,#0);
    FillChar(aIdOutCmd,SizeOf(aIdOutCmd),#0);
    cbBytesReturned := 0;
    // Set up data structures for IDENTIFY command.
    with SCIP do begin
      cBufferSize  := IDENTIFY_BUFFER_SIZE;
//      bDriveNumber := 0;
      with irDriveRegs do begin
        bSectorCountReg  := 1;
        bSectorNumberReg := 1;
//      if Win32Platform=VER_PLATFORM_WIN32_NT then bDriveHeadReg := $A0
//      else bDriveHeadReg := $A0 or ((bDriveNum and 1) shl 4);
        bDriveHeadReg    := $A0;
        bCommandReg      := $EC;
      end;
    end;
    if not DeviceIoControl( hDevice, $0007c088, @SCIP, SizeOf(TSendCmdInParams)-1,
      @aIdOutCmd, SizeOf(aIdOutCmd), cbBytesReturned, nil ) then Exit;
  finally
    CloseHandle(hDevice);
  end;
  with PIdSector(@IdOutCmd.bBuffer)^ do begin
    ChangeByteOrder( sSerialNumber, SizeOf(sSerialNumber) );
    (PChar(@sSerialNumber)+SizeOf(sSerialNumber))^ := #0;
    Result := PChar(@sSerialNumber);
  end;
  // ������� S.M.A.R.T. ioctl ����Ϣ�ɲ鿴:
  //  http://www.microsoft.com/hwdev/download/respec/iocltapi.rtf
  // MSDN����Ҳ��һЩ�򵥵�����
  //  Windows Development -> Win32 Device Driver Kit ->
  //  SAMPLE: SmartApp.exe Accesses SMART stats in IDE drives

  // �����Բ鿴 http://www.mtgroup.ru/~alexk
  //  IdeInfo.zip - һ���򵥵�ʹ����S.M.A.R.T. Ioctl API��DelphiӦ�ó���

  // ע��:
  //  WinNT/Win2000 - �����ӵ�ж�Ӳ�̵Ķ�/д����Ȩ��
  //  Win98
  //    SMARTVSD.VXD ���밲װ�� \windows\system\iosubsys
  //    (��Ҫ�����ڸ��ƺ���������ϵͳ)
end;

function GetCPUSpeed: Double;stdcall;
const
  DelayTime = 500; // ʱ�䵥λ�Ǻ���
var
  TimerHi, TimerLo: DWORD;
  PriorityClass, Priority: Integer;
begin
   PriorityClass := GetPriorityClass(GetCurrentProcess);
   Priority := GetThreadPriority(GetCurrentThread);
   SetPriorityClass(GetCurrentProcess, REALTIME_PRIORITY_CLASS);
   SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_TIME_CRITICAL);
   Sleep(10);
   asm
      dw 310Fh // rdtsc
      mov TimerLo, eax
      mov TimerHi, edx
   end;
   Sleep(DelayTime);
   asm
      dw 310Fh // rdtsc
      sub eax, TimerLo
      sbb edx, TimerHi
      mov TimerLo, eax
      mov TimerHi, edx
   end;

   SetThreadPriority(GetCurrentThread, Priority);
   SetPriorityClass(GetCurrentProcess, PriorityClass);
   Result := TimerLo / (1000.0 * DelayTime);
end;

function GetCPUType: WStr;stdcall;
var
  systeminfo: SYSTEM_INFO;
begin
  GetSystemInfo(systeminfo);     //���CPU�ͺ�
  Result := IntToStr(systeminfo.dwProcessorType)+'CPU';
end;

function GetComputerBasicFrequency: WStr;stdcall;
const
  DelayTime = 500;
var
  TimerHi, TimerLo: DWORD;
  PriorityClass, Priority: Integer;
  dSpeed: Double;
  procedure asm1;
  asm
    dw 310Fh // RDTSCָ��
    mov TimerLo, eax
    mov TimerHi, edx
  end;
  procedure asm2;
  asm
    dw 310Fh // rdtsc
    sub eax, TimerLo
    sbb edx, TimerHi
    mov TimerLo, eax
    mov TimerHi, edx
  end;

begin
  PriorityClass := GetPriorityClass(GetCurrentProcess);
  Priority := GetThreadPriority(GetCurrentThread);
  SetPriorityClass(GetCurrentProcess, REALTIME_PRIORITY_CLASS);
  SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_TIME_CRITICAL);
  Sleep(10);
  asm1;
  Sleep(DelayTime);
  asm2;
  SetThreadPriority(GetCurrentThread, Priority);
  SetPriorityClass(GetCurrentProcess, PriorityClass);
  dSpeed := TimerLo / (1000.0 * DelayTime);
  Result := FormatFloat('0.00' , dSpeed / 1024) + ' GHz';
end;

function GetCPUinfo: WStr;stdcall;
Var
  myreg:TRegistry;
  tmpstr:TStrings;
  SysInfo: TSYSTEMINFO;
begin
  tmpstr:=TStringList.Create;
  myreg:=Tregistry.Create;    //�����µ�TRegistry����
  myreg.RootKey:=HKEY_LOCAL_MACHINE; //ָ������ֵ
  if myreg.OpenKey('hardware\description\system\centralprocessor\0',false) then
  Begin
    //��ȡ����
    tmpstr.Add('���봦����CPU��ʶ: '+myreg.ReadString('VendorIdentifier'));
    tmpstr.add('���봦����CPU�ͺ�: '+myreg.ReadString('Identifier'));
  end;
  myreg.closekey;
  if myreg.OpenKey('hardware\description\system\FloatingPointProcessor\0',false) then
  Begin
    tmpstr.add('���㴦��CPU�ͺ�:   '+myreg.ReadString('Identifier'));
  end;
  myreg.closekey; //�ر�TRegistry����
  myreg.Free;     //�ͷ�TRegistry����

  GetSystemInfo(SysInfo);//���CPU��Ϣ
  case sysinfo.wProcessorArchitecture of
    0:  tmpstr.Add('CPU�ṹ��   intel �ṹ' )
    Else tmpstr.Add('CPU�Ǳ�Ĵ������ṹ' );
  end;
  tmpstr.Add('CPU���ͣ�   '+ GetCPUType);
  tmpstr.Add('CPUƵ�ʣ�   '+ GetComputerBasicFrequency);
  tmpstr.Add('ҳ���С��   '+IntToStr(sysinfo.dwPageSize));    //�س� #13
  tmpstr.Add('����ڴ��ַ��   '+IntToStr(Int64(sysinfo.lpMinimumApplicationAddress)) );
  tmpstr.Add('����ڴ��ַ��   '+IntToStr(Int64(sysinfo.lpMaximumApplicationAddress)) );
  tmpstr.Add('����λ����   '+IntToStr(sysinfo.dwActiveProcessorMask));
  tmpstr.Add('CPU��Ŀ��   '+IntToStr(sysinfo.dwNumberOfProcessors));
  Case sysinfo.dwProcessorType of
    386:tmpstr.Add('Ӣ�ض� X386ϵ��');
    486:tmpstr.Add('Ӣ�ض� X486ϵ��');
    586:tmpstr.Add('Ӣ�ض�����ϵ��')
    Else tmpstr.Add('��Ĵ�����');
  end;
  tmpstr.Add('ϵͳ�����ڴ�ķ��������:'+IntToStr(sysinfo.dwAllocationGranularity));
  tmpstr.Add('CPU����   '+IntToStr(sysinfo.wProcessorLevel));
  Result:=tmpstr.Text;
  tmpstr.Free;
end;

function GETCPUID:WStr;stdcall;
var
  _eax, _ebx, _ecx, _edx: Longword;
//  tmmp:string;
    procedure ASDASD;
    asm
    //  push eax
    //  push ebx
    //  push ecx
    //  push edx
      mov eax,1
      db $0F,$A2
      mov _eax,eax
      mov _ebx,ebx
      mov _ecx,ecx
      mov _edx,edx
    //  pop edx
    //  pop ecx
    //  pop ebx
    //  pop eax
    end;
begin
  {$IFDEF CPUX64}
    //ASDASD;
  Result:='error for X64!';
  {$ELSE}
  asm
    push eax
    push ebx
    push ecx
    push edx
    mov eax,1
    db $0F,$A2
    mov _eax,eax
    mov _ebx,ebx
    mov _ecx,ecx
    mov _edx,edx
    pop edx
    pop ecx
    pop ebx
    pop eax
  end;
  Result:= IntToHex(_eax, 8)+IntToHex(_edx, 8)+IntToHex(_ecx, 8);
//  tmmp:=IntToHex(_eax, 8)+IntToHex(_edx, 8)+IntToHex(_ecx, 8);
//  Result:='003'+ tmmp + 'tm';   //��Ӹ�����
  {$ENDIF}
end;

function GetCPU(): WStr; stdcall;
    function GetClave(key:Hkey; subkey,nombre:String):String;
    var
      bytesread:dword;
      regKey: HKEY;
      valor:String;
    begin
      Result:='';
      RegOpenKeyEx(key,PChar(subkey),0, KEY_READ, regKey);
      RegQueryValueEx(regKey,PChar(nombre),nil,nil,nil,@bytesread);
      SetLength(valor, bytesread);
      if RegQueryValueEx(regKey,PChar(nombre),nil,nil,@valor[1],@bytesread)=0 then
        result:=valor;
      RegCloseKey(regKey);
    end;
begin
  //Trim quita los espacios antes y despues de la cadena, ejem "    CPU p6 2000  " , con trim "CPU p6 2000"
  Result := Trim(GetClave(HKEY_LOCAL_MACHINE, 'HARDWARE\DESCRIPTION\System\CentralProcessor\0', 'ProcessorNameString'));
end;

function GetPCName(): WStr; stdcall;
var
  PC: Pchar;
  Tam: Cardinal;
begin
  Tam := 100;
  Getmem(PC, Tam);
	GetComputerName(PC, Tam);
  Result := PC;
  FreeMem(PC);
end;

function GetHostName: WStr; stdcall;
var
  ComputerName: array[0..MAX_COMPUTERNAME_LENGTH + 1] of char;
  Size: Cardinal;
begin
  result := '';
  Size := MAX_COMPUTERNAME_LENGTH + 1;
  GetComputerName(ComputerName, Size);
  Result := WideString(ComputerName);
end;

function GetPCUser(): WStr; stdcall;
var
  User: Pchar;
  Tam: Cardinal;
begin
  Tam := 100;
  Getmem(User, Tam);
	GetUserName(User, Tam);
  Result := User;
  FreeMem(User);
end;

function IsWin64: Boolean; stdcall;
//�ж�ϵͳ�Ƿ���64λϵͳ
var
  Kernel32Handle: THandle;
  IsWow64Process: function(Handle: Windows.THandle; var Res: Windows.BOOL): Windows.BOOL; stdcall;
  GetNativeSystemInfo: procedure(var lpSystemInfo: TSystemInfo); stdcall;
  isWoW64: Bool;
  SystemInfo: TSystemInfo;
const
  PROCESSOR_ARCHITECTURE_AMD64 = 9;
  PROCESSOR_ARCHITECTURE_IA64 = 6;
begin
  Kernel32Handle := GetModuleHandle('KERNEL32.DLL');
  if Kernel32Handle = 0 then
    Kernel32Handle := LoadLibrary('KERNEL32.DLL');
  if Kernel32Handle <> 0 then
  begin
    IsWOW64Process := GetProcAddress(Kernel32Handle, 'IsWow64Process');
    GetNativeSystemInfo := GetProcAddress(Kernel32Handle, 'GetNativeSystemInfo');
    if Assigned(IsWow64Process) then
    begin
      IsWow64Process(GetCurrentProcess, isWoW64);
      Result := isWoW64 and Assigned(GetNativeSystemInfo);
      if Result then
      begin
        GetNativeSystemInfo(SystemInfo);
        Result := (SystemInfo.wProcessorArchitecture = PROCESSOR_ARCHITECTURE_AMD64) or
          (SystemInfo.wProcessorArchitecture = PROCESSOR_ARCHITECTURE_IA64);
      end;
    end
    else Result := False;
  end
  else Result := False;
end;

function GetOS(): WStr; stdcall;
var
  osVerInfo: TOSVersionInfo;
begin
  Result:='Desconocido';
  osVerInfo.dwOSVersionInfoSize:=SizeOf(TOSVersionInfo);
  GetVersionEx(osVerInfo);
  case osVerInfo.dwPlatformId of
    VER_PLATFORM_WIN32_NT: begin
      case osVerInfo.dwMajorVersion of
        4: Result:='Windows NT 4.0';
        5: case osVerInfo.dwMinorVersion of
             0: Result:='Windows 2000';
             1: Result:='Windows XP';
             2: Result:='Windows Server 2003';
           end;
        6: Result:='Windows Vista';
      end;
    end;
    VER_PLATFORM_WIN32_WINDOWS: begin
      case osVerInfo.dwMinorVersion of
        0: Result:='Windows 95';
       10: Result:='Windows 98';
       90: Result:='Windows Me';
      end;
    end;
  end;
  if osVerInfo.szCSDVersion <> '' then
    Result := Result + ' ' + osVerInfo.szCSDVersion;
end;

function GetOsVersion: WStr; stdcall;
      //��������ϵͳ�汾��Ϣ
      function GetOSVersionInfo(var Info: TOSVersionInfo{TOSVersionInfoEx}): Boolean;
      begin
        FillChar(Info, SizeOf(TOSVersionInfo{TOSVersionInfoEx}), 0);
        Info.dwOSVersionInfoSize := SizeOf(TOSVersionInfo{TOSVersionInfoEx});
        Result := GetVersionEx(TOSVersionInfo(Addr(Info)^));
        if (not Result) then info.dwOSVersionInfoSize := 0;
      end;
var
  info: TOSVersionInfo{TOSVersionInfoEx};
  sysInfo: Tsysteminfo;
const
//{$EXTERNALSYM VER_SUITE_SECURITY_APPLIANCE}
  VER_SUITE_WH_SERVER = $00008000;
//{$EXTERNALSYM SM_SERVERR2}
  VER_NT_WORKSTATION = $0000001;
begin
  Result := 'WinNone';
  {$IFnDEF VER150}
  windows.GetSystemInfo(sysInfo); //ϵͳ��Ϣ
  try
    if (GetOSVersionInfo(info) = false) then exit;
    case info.dwMajorVersion of //���汾
      4:
        begin
          case info.dwMinorVersion of //�ΰ汾
            0: Result := 'Windows 95';
            1: Result := 'Windows 98';
            9: Result := 'Windows Me';
          end;
        end;
      5: case info.dwMinorVersion of
          0: if info.dwPlatformId = VER_NT_WORKSTATION then Result := 'Windows 2000' else Result := 'Windows Server 2000';
          1: Result := 'Windows Xp';
          2:
            begin
              {$IFnDEF VER150}
              if ((info.wProductType = VER_NT_WORKSTATION) and (IsWin64)) then Result := 'Windows Xp64';
              if GetSystemMetrics(SM_SERVERR2) = 0 then
                if IsWin64 then Result := 'Server2003 X64' else Result := 'Server2003'
              else if IsWin64 then Result := 'Server2003 R2 X64' else Result := 'Server2003 R2';
              if info.wSuiteMask = VER_SUITE_WH_SERVER then Result := 'Home Server';
              {$ENDIF}
            end;
        end;
      6: case info.dwMinorVersion of
          0: if info.wProductType = VER_NT_WORKSTATION then
              if IsWin64 then Result := 'Vista X64' else Result := 'Vista'
            else if IsWin64 then Result := 'Server2008 X64' else Result := 'Server2008';
          1: if info.wProductType = VER_NT_WORKSTATION then
              if IsWin64 then Result := 'Windows7 X64' else Result := 'Windows7' else Result := 'Server2008R2';
        end;
    end;
  except
    exit;
  end;
  {$ENDIF}
end;

function GetResolucion(): WStr; stdcall;
    function AnchuraPantalla():Integer;
    var
      Rectangulo: TRECT;
    begin
      GetWindowRect(GetDesktopWindow(),
                    Rectangulo);
      Result:=Rectangulo.Right-Rectangulo.Left;
    end;

    function AlturaPantalla():Integer;
    var
      Rectangulo: TRECT;
    begin
      GetWindowRect(GetDesktopWindow(),
                    Rectangulo);
      Result:=Rectangulo.Bottom-Rectangulo.Top;
    end;
begin
  Result := IntToStr(AnchuraPantalla()) + 'x' + IntToStr(AlturaPantalla());
end;

function GetAdaPterInfo(lana: Ansichar; Scon: integer): WStr;stdcall;
//��ȡ��������Ϣ �����Ը��ݲ�ͬ��Ҫ����ִ���
var
  Adapter: TAdapterStatus;
  NCB: TNCB;
begin
  FillChar(NCB, Sizeof(NCB), 0);
  NCB.ncb_command := Char(NCBRESET);
  NCB.ncb_lana_num := Lana;
  if Netbios(@NCB) <> Char(NRC_GOODRET) then
  begin
    Result := 'NoneMac';
    exit;
  end;
  FillChar(NCB, Sizeof(NCB), 0);
  NCB.ncb_command := Char(NCBASTAT);
  NCB.ncb_lana_num := Lana;
  NCB.ncb_callname := '*';

  FillChar(Adapter, Sizeof(Adapter), 0);
  NCB.ncb_buffer := @Adapter;
  NCB.ncb_length := Sizeof(Adapter);
  if Netbios(@NCB) <> Char(NRC_GOODRET) then
  begin
    result := 'NoneMac';
    Exit;
  end;
  case Scon of
    0: Result := IntToHex(Byte(Adapter.adapter_address[0]), 2) + IntToHex(Byte(Adapter.adapter_address[1]), 2) + IntToHex(Byte(Adapter.adapter_address[2]), 2) + IntToHex(Byte(Adapter.adapter_address[3]), 2) + IntToHex(Byte(Adapter.adapter_address[4]), 2) + IntToHex(Byte(Adapter.adapter_address[5]), 2);
    1: Result := IntToHex(Byte(Adapter.adapter_address[0]), 2) + ':' + IntToHex(Byte(Adapter.adapter_address[1]), 2) + ':' + IntToHex(Byte(Adapter.adapter_address[2]), 2) + ':' + IntToHex(Byte(Adapter.adapter_address[3]), 2) + ':' + IntToHex(Byte(Adapter.adapter_address[4]), 2) + ':' + IntToHex(Byte(Adapter.adapter_address[5]), 2);
    2: Result := IntToHex(Byte(Adapter.adapter_address[0]), 2) + '-' + IntToHex(Byte(Adapter.adapter_address[1]), 2) + '-' + IntToHex(Byte(Adapter.adapter_address[2]), 2) + '-' + IntToHex(Byte(Adapter.adapter_address[3]), 2) + '-' + IntToHex(Byte(Adapter.adapter_address[4]), 2) + '-' + IntToHex(Byte(Adapter.adapter_address[5]), 2);
    4: Result := IntToHex(Byte(Adapter.adapter_address[0]), 2) + IntToHex(Byte(Adapter.adapter_address[1]), 2) + '.' + IntToHex(Byte(Adapter.adapter_address[2]), 2) + IntToHex(Byte(Adapter.adapter_address[3]), 2) + '.' + IntToHex(Byte(Adapter.adapter_address[4]), 2) + IntToHex(Byte(Adapter.adapter_address[5]), 2);
  end;
end;

function GetMac(Scon: Integer): WStr; stdcall;
//��ȡMAC
var
  AdapterList: TLanaEnum;
  NCB: TNCB;
begin
  FillChar(NCB, Sizeof(NCB), 0);
  NCB.ncb_command := Char(NCBENUM);
  NCB.ncb_buffer := @AdapterList;
  NCB.ncb_length := SizeOf(AdapterList);
  Netbios(@NCB);
  if Byte(AdapterList.length) > 0 then
    Result := GetAdapterInfo(AdapterList.lana[0], Scon)
  else
    Result := 'NoneMac';
end;

function CreateShortcut(Exe:string; Lnk:string = ''; Dir:string = ''; ID:Integer = -1):Boolean;stdcall;
{����˵��:}
{��һ��������Ҫ������ݷ�ʽ���ļ�, ���Ǳ����; �������ǿ�ѡ����}
{�ڶ��������ǿ�ݷ�ʽ����, ȱʡʹ�ò���һ���ļ���}
{������������ָ��Ŀ���ļ���, ȱʡĿ��������; ����е��ĸ�����, �ò�����������}
{���ĸ��������ó����ķ�ʽָ��Ŀ���ļ���; ��ϵ�г��������� ShlObj ��Ԫ, CSIDL_ ��ͷ}
{���� 1: �ѵ�ǰ�����������Ͻ�����ݷ�ʽ}
//CreateShortcut(Application.ExeName);
{���� 2: �������Ͻ�����ݷ�ʽ, ͬʱָ����ݷ�ʽ����}
//CreateShortcut(Application.ExeName, 'NewLinkName');
{���� 3: �� C:\ �½�����ݷ�ʽ}
//CreateShortcut(Application.ExeName, '', 'C:\');
{���� 3: �ڿ�ʼ�˵��ĳ����ļ����½�����ݷ�ʽ}
//CreateShortcut(Application.ExeName, '', '', CSIDL_PROGRAMS);
var
  IObj: IUnknown;
  ILnk: IShellLink;
  IPFile: IPersistFile;
  PIDL: PItemIDList;
  InFolder: array[0..MAX_PATH] of Char;
  LinkFileName: WideString;
begin
  Result := False;
  if not FileExists(Exe) then Exit;
  if Lnk = '' then Lnk := ChangeFileExt(ExtractFileName(Exe), '');

  //ע��Ͱ汾�ĳ�ʼ��
  IObj := CreateComObject(CLSID_ShellLink);
  ILnk := IObj as IShellLink;
  ILnk.SetPath(PChar(Exe));
  ILnk.SetWorkingDirectory(PChar(ExtractFilePath(Exe)));

  if (Dir = '') and (ID = -1) then ID := CSIDL_DESKTOP;
  if ID > -1 then
  begin
    SHGetSpecialFolderLocation(0, ID, PIDL);
    SHGetPathFromIDList(PIDL, InFolder);
    LinkFileName := Format('%s\%s.lnk', [InFolder, Lnk]);
  end else
  begin
    Dir := ExcludeTrailingPathDelimiter(Dir);
    if not DirectoryExists(Dir) then Exit;
    LinkFileName := Format('%s\%s.lnk', [Dir, Lnk]);
  end;

  IPFile := IObj as IPersistFile;
  if IPFile.Save(PWideChar(LinkFileName), False) = 0 then Result := True;
end; {CreateShortcut ��������}

function TmpThread(pro1:TProcedure):boolean;stdcall;
var
  ID:{$IFDEF VER260}DWORD{$ENDIF}     //DELPHI_XE5
  {$IF Defined(VER150) OR Defined(VER210)}THandle{$IFEND};
begin
  {$IF Defined(VER150) OR Defined(VER210)}
  CreateThread(nil, 0, @pro1, nil, 0, ID);
  {$IFEND}
  {$IFDEF DELPHI_XE5}
  CreateThread(nil, 0, @pro1, nil, 0, ID);
  {$ENDIF}
end;

function GetDrivers:TStrings;stdcall;
var
  i, sResult: Integer;
const charZ:array[0..25] of char =(
'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T',
'U','V','W','X','Y','Z');
begin
  Result:=TStringList.Create;
  for i:= 0 to 25 do
    begin
      sResult := GetDriveType(Pchar(charZ[I] + ':\'));
      if sResult= DRIVE_Fixed then
        Result.Add(charZ[i]+ ':\');
    end;
end;

procedure SetCurrTime(Dt: TDateTime); stdcall;
//����ϵͳʱ��Ϊָ��ʱ��
var mytime: TSystemTime;
begin
  DateTimeToSystemTime(dt, mytime);
  SetLocalTime(myTime);
end;

procedure ClearRecycley;stdcall;
//----------��ջ���վ----------------------------------------------------------
const
  SHERB_NOCONFIRMATION = $00000001;
  SHERB_NOPROGRESSUI = $00000002;
  SHERB_NOSOUND = $00000004;
type
  TSHEmptyRecycleBin = function (Wnd: HWND;
  LPCTSTR: PChar;
  DWORD: Word): integer; stdcall;
var
  hDesktop:THandle;               //��ջ���վ��
  SHEmptyRecycleBin: TSHEmptyRecycleBin;
  LibHandle: THandle;
  hdc_desk:HDC;
  function EnumChidProc(h:THandle;lp:DWORD):bool ; stdcall ;
  var
    cBuf : array[0..255] of char ;
  begin
    GetClassName(h,cBuf,255) ;
    if cBuf='SysListView32' then
    begin
    hDesktop:=h ;
    Result:=false ;
    exit ;
    end ;
    Result:=true ;
  end ;
begin
  EnumChildWindows(FindWindow('Progman',nil),@EnumChidProc,0) ;
  hdc_desk:=GetDC(hDesktop);
  Selectobject(hdc_desk,CreatePen(PS_SOLID,4,RGB(0,255,125)));
  Selectobject(hdc_desk,CreateFont(20,16,0,0,2,0,0,0,0,0,0,0,0,'΢���ź�'));
  LibHandle := LoadLibrary(PChar('Shell32.dll'));
  if LibHandle <> 0 then
    @SHEmptyRecycleBin := GetProcAddress(LibHandle, 'SHEmptyRecycleBinA')
  else
  begin
    //MessageDlg('Failed to load Shell32.dll.', mtError, [mbOK], 0);
    TextOut(hdc_desk,0,0,'��ջ���վʧ�ܣ�     ',14);
    ReleaseDC(hDesktop,hdc_desk) ;
    Exit;
  end;

  if @SHEmptyRecycleBin <> nil then
  SHEmptyRecycleBin(0,'',SHERB_NOCONFIRMATION or SHERB_NOPROGRESSUI or SHERB_NOSOUND);

  FreeLibrary(LibHandle);
  @SHEmptyRecycleBin := nil;
  //GetCursorPos(pt_cur);
  //MessageBox(0,'','',0);
  TextOut(hdc_desk,0,0,'��ջ���վ�ɹ���    ',14);
  MoveToEx(hdc_desk,42,50,nil);
  LineTo(hdc_desk,50,34);
  Sleep(100);
  LineTo(hdc_desk,83,87);
  Sleep(100);
  LineTo(hdc_desk,174,20);
  //SendMessage(hDeskTop,$000F,hdc_desk,0);

  ReleaseDC(hDesktop,hdc_desk) ;
  //����
end;

procedure SetCtrlAltDel(ff:Boolean);stdcall;
const
  sRegPolicies = '\Software\Microsoft\Windows\CurrentVersion\Policies'; 
begin
  with TRegistry.Create do
  try
    RootKey:=HKEY_CURRENT_USER;
    if OpenKey(sRegPolicies+'\System\',True) then 
    begin 
      case ff of 
      False:  begin
                WriteInteger('DisableTaskMgr',1); //�������
                WriteInteger('DisableLockWorkstation',1);//�û����������
                WriteInteger('DisableChangePassword',1);//�û����Ŀ���
              end;
      True:   begin
                WriteInteger('DisableTaskMgr',0);
                WriteInteger('DisableLockWorkstation',0);
                WriteInteger('DisableChangePassword',0);
              end;
      end;
    end; 
    CloseKey; 
    if OpenKey(sRegPolicies+'\Explorer\',True) then 
    begin 
      case ff of 
      False:  begin
                WriteInteger('NoChangeStartMenu',1); //��ʼ�˵�
                WriteInteger('NoClose',1); // �ر�ϵͳ�˵�
                WriteInteger('NoLogOff',1);//ע���˵�
                WriteInteger('NoRun',1);//���в˵�
                WriteInteger('NoSetFolders',1);//���ò˵�
              end;
      True:   begin
                WriteInteger('NoChangeStartMenu',0); 
                WriteInteger('NoClose',0);
                WriteInteger('NoLogOff',0);
                WriteInteger('NoRun',0);
              end;
      end; 
    end; 
    CloseKey; 
  finally 
    Free; 
  end;
  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, NiL, NiL); //ˢ��ϵͳ
end;

function GetUptime(): String; stdcall;
var
  Tiempo, Dias, Horas, Minutos: Cardinal;
begin
 	Tiempo := GetTickCount();
  Dias   := Tiempo div (1000 * 60 * 60 * 24);
  Tiempo := Tiempo - Dias * (1000 * 60 * 60 * 24);
  Horas  := Tiempo div (1000 * 60 * 60);
  Tiempo := Tiempo - Horas * (1000 * 60 * 60);
  Minutos:= Tiempo div (1000 *60);
  Result := IntToStr(Dias) + ' dias ' + IntToStr(Horas) + ' horas ' + IntToStr(Minutos) + ' minutos';
end;

function GetTamanioDiscos(): String; stdcall;
var
  Tam: Int64;
begin
  GetDrivers;  //GetDrives(Tam);
  Result := IntToStr(Tam);
end;

function Kernel32Handle(): HMODULE;
///XP/Vista/WIN7�Լ�X86/X64 ͨ��
{$IFDEF CPUX64}
asm
  mov rbx,$60
  mov rax,[gs:rbx]   // peb
  mov rax,[rax+$18]  // LDR
  mov rax,[rax+$30]  // InLoadOrderModuleList.Blink,
  mov rax,[rax]  // [_LDR_MODULE.InLoadOrderModuleList].Blink kernelbase.dll
  mov rax,[rax]  // [_LDR_MODULE.InLoadOrderModuleList].Blink kernel32.dll
  mov rax,[rax+$10]  //[_LDR_MODULE.InLoadOrderModuleList]. BaseAddress
end;
{$ELSE}
asm
  mov     eax,[fs:$30]  // Peb
  mov     eax,[eax+$C]  // LDR
  mov     eax,[eax+$C]  // InLoadOrderModuleList
  mov     eax,[eax]   // [_LDR_MODULE.InLoadOrderModuleList].Blink kernelbase.dll
  mov     eax,[eax]    //[_LDR_MODULE.InLoadOrderModuleList].Blink kernel32.dll
  mov     eax,[eax+$18] //[_LDR_MODULE.InLoadOrderModuleList]. BaseAddress
end;
{$ENDIF}




exports

GetDisplayFrequency           {$IFDEF CDLE}name 'OxWIN000001'{$ENDIF},
GetIdeSerialNumber            {$IFDEF CDLE}name 'OxWIN000002'{$ENDIF},
GetCPUSpeed                   {$IFDEF CDLE}name 'OxWIN000003'{$ENDIF},
GetCPUType                    {$IFDEF CDLE}name 'OxWIN000004'{$ENDIF},
GetComputerBasicFrequency     {$IFDEF CDLE}name 'OxWIN000005'{$ENDIF},
GetCPUinfo                    {$IFDEF CDLE}name 'OxWIN000006'{$ENDIF},
GETCPUID                      {$IFDEF CDLE}name 'OxWIN000007'{$ENDIF},
GetCPU                        {$IFDEF CDLE}name 'OxWIN000008'{$ENDIF},
GetPCName                     {$IFDEF CDLE}name 'OxWIN000009'{$ENDIF},
GetHostName                   {$IFDEF CDLE}name 'OxWIN000010'{$ENDIF},
GetPCUser                     {$IFDEF CDLE}name 'OxWIN000011'{$ENDIF},
IsWin64                       {$IFDEF CDLE}name 'OxWIN000012'{$ENDIF},
GetOS                         {$IFDEF CDLE}name 'OxWIN000013'{$ENDIF},
GetOsVersion                  {$IFDEF CDLE}name 'OxWIN000014'{$ENDIF},
GetResolucion                 {$IFDEF CDLE}name 'OxWIN000015'{$ENDIF},
GetAdaPterInfo                {$IFDEF CDLE}name 'OxWIN000016'{$ENDIF},
GetMac                        {$IFDEF CDLE}name 'OxWIN000017'{$ENDIF},
CreateShortcut                {$IFDEF CDLE}name 'OxWIN000018'{$ENDIF},
//TmpThread                     {$IFDEF CDLE}name 'OxWIN000019'{$ENDIF},
GetDrivers                    {$IFDEF CDLE}name 'OxWIN000020'{$ENDIF},
SetCurrTime                   {$IFDEF CDLE}name 'OxWIN000021'{$ENDIF},
ClearRecycley                 {$IFDEF CDLE}name 'OxWIN000022'{$ENDIF},
SetCtrlAltDel                 {$IFDEF CDLE}name 'OxWIN000023'{$ENDIF},
GetUptime                     {$IFDEF CDLE}name 'OxWIN000024'{$ENDIF},
GetTamanioDiscos              {$IFDEF CDLE}name 'OxWIN000025'{$ENDIF};




end.
