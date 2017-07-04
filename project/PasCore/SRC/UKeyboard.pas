//------------------------------------------------------------------------------
//
//      ���̵Ĳ���ģ��
//
//                                                 @2015-03-06 ����
//------------------------------------------------------------------------------
{$INCLUDE '..\TypeDef.inc'}
unit UKeyboard;
interface
uses
  windows, messages ;

procedure HookOn; cdecl;                   //��¼����(�ȼ��Ļ�ȡ)
procedure HookOff; cdecl;
FUNCTION  FeHookLoad():Boolean;cdecl;      //���ΰ���
FUNCTION  FeHookUnload():Boolean;cdecl;

type
  KBDLLHOOKSTRUCT = record
    vkCode: DWORD;
    scanCode: DWORD;
    flags: DWORD;
    time: DWORD;
    dwExtraInfo: DWORD; END;
  PKBDLLHOOKSTRUCT = ^KBDLLHOOKSTRUCT;

const
  WM_HOOKKEY = WM_USER + $1000;
  LLKHF_ALTDOWN  = KF_ALTDOWN shr 8;   //hook����ʹ��
  WH_KEYBOARD_LL = 13;                 //hook����ʹ��

var
  HookDeTeclado     : HHook;
  FileMapHandle     : THandle;
  PViewInteger      : ^Integer;
  hhkNTKeyboard: HHOOK =0;            //hook����ʹ��

implementation

function CallBackDelHook(Code:Integer;wParam:WPARAM;lParam:LPARAM):LRESULT;stdcall;
begin
  if code=HC_ACTION then
  begin
    FileMapHandle:=OpenFileMapping(FILE_MAP_READ,False,'DelphiTestHook');
    if FileMapHandle<>0 then
    begin
      PViewInteger:=MapViewOfFile(FileMapHandle,FILE_MAP_READ,0,0,0);
      PostMessage(PViewInteger^,WM_HOOKKEY,wParam,lParam);
      UnmapViewOfFile(PViewInteger);
      CloseHandle(FileMapHandle);
    end;
  end;
  Result := CallNextHookEx(HookDeTeclado, Code, wParam, lParam)
end;

procedure HookOn; cdecl;
begin
  HookDeTeclado:=SetWindowsHookEx(WH_KEYBOARD, CallBackDelHook, HInstance , 0);
end;

procedure HookOff;  cdecl;
begin
  UnhookWindowsHookEx(HookDeTeclado);
end;


//------------------���̴�����-Hook-----------------------------------------------------------------------
FUNCTION LowLevelKeyboardFunc(nCode:INTEGER; w_Param:WPARAM; l_Param:LPARAM): LRESULT; stdcall;
VAR
  boolKey: Boolean;
  p: PKBDLLHOOKSTRUCT;
CONST   VK_SLEEP = $5F;
        VK_POWER = $5E;
BEGIN
  boolKey:=false;
  IF nCode = HC_ACTION THEN
    BEGIN
    CASE w_Param OF
      WM_KEYDOWN, WM_SYSKEYDOWN, WM_KEYUP, WM_SYSKEYUP:
      BEGIN
      p := PKBDLLHOOKSTRUCT(l_Param);
      //---------!-~------------------------------------------------
      IF ((GetAsyncKeyState(VK_RBUTTON) and $8000)<>0) THEN   boolKey:=true;
      IF (CHAR(p.vkCode)>='!')AND (CHAR(p.vkCode)<='~') AND
         ((GetKeyState(VK_CONTROL) and $8000)<>0) THEN  boolKey:=true;
      IF (p.vkCode=VK_SPACE) AND
         ((GetKeyState(VK_CONTROL) and $8000)<>0)  THEN  boolKey:=true;
      //---------F1-F12 ----------------------------------------------
      IF (p.vkCode=VK_F1) or (p.vkCode=VK_F2) or (p.vkCode=VK_F3)or
         (p.vkCode=VK_F4) or (p.vkCode=VK_F5) or (p.vkCode=VK_F6) or
         (p.vkCode=VK_F7) or (p.vkCode=VK_F8) or (p.vkCode=VK_F9) or
         (p.vkCode=VK_F10) or (p.vkCode=VK_F11) or (p.vkCode=VK_F12) THEN boolKey:=true;
      IF ((p.vkCode=VK_F1) or (p.vkCode=VK_F2) or (p.vkCode=VK_F3)or
         (p.vkCode=VK_F4) or (p.vkCode=VK_F5) or (p.vkCode=VK_F6) or
         (p.vkCode=VK_F7) or (p.vkCode=VK_F8) or (p.vkCode=VK_F9) or
         (p.vkCode=VK_F10) or (p.vkCode=VK_F11) or (p.vkCode=VK_F12)) AND
         (((GetKeyState(VK_MENU) and $8000)<>0) or ((GetKeyState(VK_CONTROL) and $8000)<>0) or ((GetKeyState(VK_SHIFT)and$8000)<>0) ) THEN boolKey:=true;
      //-------ϵͳ�ȼ�---------------------------------------------
      //WIN(Left or Right)+APPS
      IF (p.vkCode=VK_LWIN)OR(p.vkCode=VK_RWIN)OR(p.vkCode=VK_APPS) THEN boolKey:=true;
      //CTRL+ALT+DEL
      IF ((p.vkCode=VK_DELETE) and ((p.flags and LLKHF_ALTDOWN) <> 0) and ((GetKeyState(VK_CONTROL) and $8000) <> 0))  THEN boolKey:=true;
      //CTRL+ESC
      IF (p.vkCode=VK_ESCAPE) and ((GetKeyState(VK_CONTROL) and $8000) <> 0)   THEN boolKey:=true;
      //ALT+TAB
      IF (p.vkCode=VK_TAB)    and ((GetAsyncKeyState(VK_MENU) and $8000)<>0)  THEN boolKey:=true;
      //ALT+ESC
      IF (p.vkCode=VK_ESCAPE) and ((p.flags and LLKHF_ALTDOWN) <> 0)   THEN boolKey:=true;
      //CTRL+ENTER
      IF (p.vkCode=VK_RETURN) and ((GetKeyState(VK_CONTROL) and $8000) <> 0) THEN boolKey:=true;
      //CTRL+ALT+ENTR
      IF (p.vkCode=VK_RETURN) and ((GetKeyState(VK_CONTROL) and $8000) <> 0) THEN boolKey:=true;
      //CTRL+ALT+DEL
      IF (p.vkCode=VK_RETURN) and ((p.flags and LLKHF_ALTDOWN) <> 0) and ((GetKeyState(VK_CONTROL) and $8000) <> 0)  THEN boolKey:=true;

      //POWER
      IF (p.vkCode=VK_POWER)  THEN boolKey:=true;       //ע��
      //SLEEP
      IF (p.vkCode=VK_SLEEP)  THEN boolKey:=true;
      //-------------------------------------------------------------------------------------------------------------------------------------
      END;
    END;
    END;
  //������Щ��ϼ���������Ϣ���Լ��������뷵�� 1
  IF boolKey THEN  BEGIN  Result := 1; Exit END;
  //�����İ��������ɱ���̴߳������ˣ�
  Result := CallNextHookEx(0, nCode, w_Param, l_Param);
END;

//------------------�������Hook------------------------------------------------
FUNCTION  FeHookLoad():Boolean;cdecl;export;
BEGIN
  Result:=false;
  IF hhkNTKeyboard<>0 THEN Exit;
  hhkNTKeyboard := SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardFunc,HInstance, 0);
  IF hhkNTKeyboard<>0 THEN Result:=True;
END;

//---------------------ȡ������Hook---------------------------------------------
FUNCTION  FeHookUnload():Boolean;cdecl;export;
BEGIN
  Result:=false;
  IF  hhkNTKeyboard = 0 THEN Exit;
  UnhookWindowsHookEx(hhkNTKeyboard); // ж�ع���
  hhkNTKeyboard := 0;
  Result:=true;
END;


exports
HookOn       {$IFDEF CDLE}NAME 'OxK00000001'{$ENDIF},  //��¼����(�ȼ��Ļ�ȡ)
HookOff      {$IFDEF CDLE}NAME 'OxK00000002'{$ENDIF},
FeHookLoad   {$IFDEF CDLE}NAME 'OxK00000003'{$ENDIF},  //���ΰ���
FeHookUnload {$IFDEF CDLE}NAME 'OxK00000004'{$ENDIF};


end.
