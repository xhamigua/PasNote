//------------------------------------------------------------------------------
//
//      相关windows操作  和硬件读取
//
//                                                 @2015-03-06 阿甘
//------------------------------------------------------------------------------

//{$INCLUDE '..\TypeDef.inc'}
unit UWindows;
interface
uses
  Windows, SysUtils ,Nb30, Classes ,ShlObj, ActiveX, ComObj;
type
  TProcedure=procedure;
  WStr= WideString;


//显示刷新率是以Hz为单位的
function GetDisplayFrequency: Integer;stdcall;
//获取第一个IDE硬盘的序列号
function GetIdeSerialNumber: pchar;stdcall;
//cpu频率
function GetCPUSpeed: Double;stdcall;
//处理器类型
function GetCPUType: WStr; stdcall;
//CPU频率
function GetComputerBasicFrequency: WStr;stdcall;
//CPU产品信息
function GetCPUinfo: WStr; stdcall;
//获取cpu的唯一ID
function GETCPUID:WStr;stdcall;
//获得CPU
function GetCPU(): WStr; stdcall;
//获得计算机名  (方法1)
function GetPCName(): WStr; stdcall;
//获取计算机名称(方法2)
function GetHostName: WStr; stdcall;
//获得用户名
function GetPCUser(): WStr; stdcall;
//判断系统是否是64位系统
function IsWin64: Boolean; stdcall;
//初略获得操作系统
function GetOS(): WStr; stdcall;
//完整操作系统版本信息
function GetOsVersion: WStr; stdcall;
//获得计算机分辨率
function GetResolucion(): WStr; stdcall;
//获取适配器信息 （可以根据不同需要输出字串）
function GetAdaPterInfo(lana: Ansichar; Scon: integer): WStr;stdcall;
//获取MAC地址
function GetMac(Scon: Integer): WStr; stdcall;
//创建快捷方式
function CreateShortcut(Exe:string; Lnk:string = ''; Dir:string = '';ID:Integer = -1):Boolean;stdcall;
//获得驱动器
function GetDrivers:TStrings;stdcall;
//更新系统时间为指定时间
procedure SetCurrTime(Dt: TDateTime); stdcall;
//清空回收站
procedure ClearRecycley;stdcall;
//控制Ctrl+Alt+DEL
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
// 这个函数返回的显示刷新率是以Hz为单位的
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
    // 驱动器返回的错误代码，无错则返回0
    bDriverError : Byte;
    // IDE出错寄存器的内容，只有当bDriverError 为 SMART_IDE_ERROR 时有效
    bIDEStatus   : Byte;
    bReserved    : Array[0..1] of Byte;
    dwReserved   : Array[0..1] of DWORD;
  end;
  TSendCmdOutParams = packed record
    // bBuffer的大小
    cBufferSize  : DWORD;
    // 驱动器状态
    DriverStatus : TDriverStatus;
    // 用于保存从驱动器读出的数据的缓冲区，实际长度由cBufferSize决定
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
  Result := ''; // 如果出错则返回空串
  if SysUtils.Win32Platform=VER_PLATFORM_WIN32_NT then begin// Windows NT, Windows 2000
      // 提示! 改变名称可适用于其它驱动器，如第二个驱动器： '\\.\PhysicalDrive1\'
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
  // 更多关于 S.M.A.R.T. ioctl 的信息可查看:
  //  http://www.microsoft.com/hwdev/download/respec/iocltapi.rtf
  // MSDN库中也有一些简单的例子
  //  Windows Development -> Win32 Device Driver Kit ->
  //  SAMPLE: SmartApp.exe Accesses SMART stats in IDE drives

  // 还可以查看 http://www.mtgroup.ru/~alexk
  //  IdeInfo.zip - 一个简单的使用了S.M.A.R.T. Ioctl API的Delphi应用程序

  // 注意:
  //  WinNT/Win2000 - 你必须拥有对硬盘的读/写访问权限
  //  Win98
  //    SMARTVSD.VXD 必须安装到 \windows\system\iosubsys
  //    (不要忘记在复制后重新启动系统)
end;

function GetCPUSpeed: Double;stdcall;
const
  DelayTime = 500; // 时间单位是毫秒
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
  GetSystemInfo(systeminfo);     //获得CPU型号
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
    dw 310Fh // RDTSC指令
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
  myreg:=Tregistry.Create;    //建立新的TRegistry变量
  myreg.RootKey:=HKEY_LOCAL_MACHINE; //指定根键值
  if myreg.OpenKey('hardware\description\system\centralprocessor\0',false) then
  Begin
    //读取数据
    tmpstr.Add('中央处理器CPU标识: '+myreg.ReadString('VendorIdentifier'));
    tmpstr.add('中央处理器CPU型号: '+myreg.ReadString('Identifier'));
  end;
  myreg.closekey;
  if myreg.OpenKey('hardware\description\system\FloatingPointProcessor\0',false) then
  Begin
    tmpstr.add('浮点处理CPU型号:   '+myreg.ReadString('Identifier'));
  end;
  myreg.closekey; //关闭TRegistry变量
  myreg.Free;     //释放TRegistry变量

  GetSystemInfo(SysInfo);//获得CPU信息
  case sysinfo.wProcessorArchitecture of
    0:  tmpstr.Add('CPU结构：   intel 结构' )
    Else tmpstr.Add('CPU是别的处理器结构' );
  end;
  tmpstr.Add('CPU类型：   '+ GetCPUType);
  tmpstr.Add('CPU频率：   '+ GetComputerBasicFrequency);
  tmpstr.Add('页面大小：   '+IntToStr(sysinfo.dwPageSize));    //回车 #13
  tmpstr.Add('最低内存地址：   '+IntToStr(Int64(sysinfo.lpMinimumApplicationAddress)) );
  tmpstr.Add('最高内存地址：   '+IntToStr(Int64(sysinfo.lpMaximumApplicationAddress)) );
  tmpstr.Add('遮罩位数：   '+IntToStr(sysinfo.dwActiveProcessorMask));
  tmpstr.Add('CPU数目：   '+IntToStr(sysinfo.dwNumberOfProcessors));
  Case sysinfo.dwProcessorType of
    386:tmpstr.Add('英特尔 X386系列');
    486:tmpstr.Add('英特尔 X486系列');
    586:tmpstr.Add('英特尔奔腾系列')
    Else tmpstr.Add('别的处理器');
  end;
  tmpstr.Add('系统虚拟内存的分配间隔宽度:'+IntToStr(sysinfo.dwAllocationGranularity));
  tmpstr.Add('CPU级别：   '+IntToStr(sysinfo.wProcessorLevel));
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
//  Result:='003'+ tmmp + 'tm';   //添加干扰码
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
//判断系统是否是64位系统
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
      //完整操作系统版本信息
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
  windows.GetSystemInfo(sysInfo); //系统信息
  try
    if (GetOSVersionInfo(info) = false) then exit;
    case info.dwMajorVersion of //主版本
      4:
        begin
          case info.dwMinorVersion of //次版本
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
//获取适配器信息 （可以根据不同需要输出字串）
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
//获取MAC
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
{函数说明:}
{第一个参数是要建立快捷方式的文件, 这是必须的; 其他都是可选参数}
{第二个参数是快捷方式名称, 缺省使用参数一的文件名}
{第三个参数是指定目的文件夹, 缺省目的是桌面; 如果有第四个参数, 该参数将被忽略}
{第四个参数是用常数的方式指定目的文件夹; 该系列常数定义在 ShlObj 单元, CSIDL_ 打头}
{测试 1: 把当前程序在桌面上建立快捷方式}
//CreateShortcut(Application.ExeName);
{测试 2: 在桌面上建立快捷方式, 同时指定快捷方式名称}
//CreateShortcut(Application.ExeName, 'NewLinkName');
{测试 3: 在 C:\ 下建立快捷方式}
//CreateShortcut(Application.ExeName, '', 'C:\');
{测试 3: 在开始菜单的程序文件夹下建立快捷方式}
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

  //注意低版本的初始化
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
end; {CreateShortcut 函数结束}

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
//更新系统时间为指定时间
var mytime: TSystemTime;
begin
  DateTimeToSystemTime(dt, mytime);
  SetLocalTime(myTime);
end;

procedure ClearRecycley;stdcall;
//----------清空回收站----------------------------------------------------------
const
  SHERB_NOCONFIRMATION = $00000001;
  SHERB_NOPROGRESSUI = $00000002;
  SHERB_NOSOUND = $00000004;
type
  TSHEmptyRecycleBin = function (Wnd: HWND;
  LPCTSTR: PChar;
  DWORD: Word): integer; stdcall;
var
  hDesktop:THandle;               //清空回收站用
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
  Selectobject(hdc_desk,CreateFont(20,16,0,0,2,0,0,0,0,0,0,0,0,'微软雅黑'));
  LibHandle := LoadLibrary(PChar('Shell32.dll'));
  if LibHandle <> 0 then
    @SHEmptyRecycleBin := GetProcAddress(LibHandle, 'SHEmptyRecycleBinA')
  else
  begin
    //MessageDlg('Failed to load Shell32.dll.', mtError, [mbOK], 0);
    TextOut(hdc_desk,0,0,'清空回收站失败！     ',14);
    ReleaseDC(hDesktop,hdc_desk) ;
    Exit;
  end;

  if @SHEmptyRecycleBin <> nil then
  SHEmptyRecycleBin(0,'',SHERB_NOCONFIRMATION or SHERB_NOPROGRESSUI or SHERB_NOSOUND);

  FreeLibrary(LibHandle);
  @SHEmptyRecycleBin := nil;
  //GetCursorPos(pt_cur);
  //MessageBox(0,'','',0);
  TextOut(hdc_desk,0,0,'清空回收站成功！    ',14);
  MoveToEx(hdc_desk,42,50,nil);
  LineTo(hdc_desk,50,34);
  Sleep(100);
  LineTo(hdc_desk,83,87);
  Sleep(100);
  LineTo(hdc_desk,174,20);
  //SendMessage(hDeskTop,$000F,hdc_desk,0);

  ReleaseDC(hDesktop,hdc_desk) ;
  //结束
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
                WriteInteger('DisableTaskMgr',1); //任务管理
                WriteInteger('DisableLockWorkstation',1);//用户锁定计算机
                WriteInteger('DisableChangePassword',1);//用户更改口令
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
                WriteInteger('NoChangeStartMenu',1); //开始菜单
                WriteInteger('NoClose',1); // 关闭系统菜单
                WriteInteger('NoLogOff',1);//注销菜单
                WriteInteger('NoRun',1);//运行菜单
                WriteInteger('NoSetFolders',1);//设置菜单
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
  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, NiL, NiL); //刷新系统
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
///XP/Vista/WIN7以及X86/X64 通吃
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
