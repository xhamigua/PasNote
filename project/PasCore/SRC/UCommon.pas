//------------------------------------------------------------------------------
//
//        �����㷨ģ��
//
//                                                 @2015-04-16 ����
//------------------------------------------------------------------------------
unit UCommon;
interface
uses
  Windows, SysUtils, Forms, Dialogs, StrUtils,
  Classes;

type
  pStr= String;


//д��־
function LogFun(str: pStr;const mfile:pStr='app.log'):Boolean;cdecl;
//��ʾ�����ַ��Ի���
procedure ShowBox(txt:pStr); cdecl;
//��ʾ�������ֶԻ���
procedure ShowBoxNum(txt:Int64); cdecl;
//�������Ի���
procedure EShowBox(txt:pStr);cdecl;
//��ʾ�Ի���
function TShowBox(txt:pStr):Boolean;cdecl;
//��ʾ�����
function SInputBox(msg:string;var str1:string):Boolean;cdecl;
//�򿪶Ի���
function OpenDlg(strdefault:pStr):pStr;cdecl;
//�򿪱���Ի��� [��ʼ·��,������,����]
function SaveDlg(sPath,sName,sType:pStr):pStr;cdecl;



implementation

function LogFun(str: pStr;const mfile:pStr='app.log'):Boolean;cdecl;
  function GetSTR(stmp:TDateTime):pStr;
  var
    tmp:pStr;
  begin
    tmp:=DateToStr(stmp);
    tmp:=StringReplace(tmp, '/', '', [rfReplaceAll]); // ȥ��/
    Result := StringReplace(tmp, '\', '', [rfReplaceAll]); // ȥ��\
  end;
var
  filev: TextFile;
  ss: pStr;
begin
//  if closelog then Exit;
  str:=DateTimeToStr(Now)+' Log: '+str;

  DateToStr(now);
  //ss:=ExtractFilePath(ParamStr(0))+'log\'+GetSTR(now)+'.Log';
  ss:=ExtractFilePath(ParamStr(0))+'log\'+ mfile;
  ForceDirectories(ExtractFilePath(ParamStr(0))+'log\');
  if FileExists(ss) then
  begin
    AssignFile(filev, ss);
    append(filev);
    writeln(filev, str);
  end else begin
    AssignFile(filev, ss);
    ReWrite(filev);
    writeln(filev, str);
  end;
  CloseFile(filev);
  Result := true;
end;

procedure ShowBox(txt:pStr);cdecl;
begin
  Application.MessageBox(PChar(txt), '��ʾ', MB_OK);
end;

procedure ShowBoxNum(txt:Int64); cdecl;
begin
  Application.MessageBox(PChar(IntToStr(txt)), '��ʾ', MB_OK);
end;

procedure EShowBox(txt:pStr);cdecl;
begin
  Application.MessageBox(PChar(txt), '����!', MB_ICONERROR);
end;

function TShowBox(txt:pStr):Boolean;cdecl;
begin
  if Application.MessageBox(PChar(txt),
  '��ʾ!',MB_YESNO + MB_ICONQUESTION) =6 then
    Result:= True
  else
    Result:=False;
end;

function SInputBox(msg:string;var str1:string):Boolean;cdecl;
begin
  Result:=InputQuery('��ʾ!', msg, str1);
  if trim(str1)='' then
    Result:=False;
end;

function OpenDlg(strdefault:pStr):pStr;cdecl;
var
  open:TOpenDialog;
begin
  open:=TOpenDialog.Create(nil);
  if strdefault='' then
    open.InitialDir:=extractfilepath(ParamStr(0))
  else
    open.InitialDir:= strdefault; //��ʼ·��
  if open.Execute() then
  begin
    if Length(open.FileName)<1 then
      Result:=''
    else
      Result:= open.FileName
  end;
  open.Free;
end;

function SaveDlg(sPath,sName,sType:pStr):pStr;cdecl;
var
  save1:TSaveDialog;
begin
  save1:=TSaveDialog.Create(nil);
  save1.FileName := sName;
  save1.Filter := sType;//'xml|*.xml';
  save1.InitialDir := sPath;
  if save1.Execute then
  begin
    if Length(save1.FileName)<1 then
      Result:=''
    else
      Result:= save1.FileName;
  end;
  save1.Free;
end;





exports
LogFun          {$IFDEF CDLE}name 'OxU00000001'{$ENDIF},
ShowBox         {$IFDEF CDLE}name 'OxU00000002'{$ENDIF},
ShowBoxNum      {$IFDEF CDLE}name 'OxU00000003'{$ENDIF},
EShowBox        {$IFDEF CDLE}name 'OxU00000004'{$ENDIF},
TShowBox        {$IFDEF CDLE}name 'OxU00000005'{$ENDIF},
SInputBox       {$IFDEF CDLE}name 'OxU00000006'{$ENDIF},
OpenDlg         {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
SaveDlg         {$IFDEF CDLE}name 'OxU00000008'{$ENDIF};


end.
