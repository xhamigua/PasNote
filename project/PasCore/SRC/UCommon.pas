unit UCommon;
interface
uses
  Windows, SysUtils, Forms, Dialogs, StrUtils,
  Classes;

type
  pStr= String;

//显示测试字符对话框
procedure ShowBox(txt:pStr); cdecl;
//显示测试数字对话框
procedure ShowBoxNum(txt:Int64); cdecl;
//警告错误对话框
procedure EShowBox(txt:pStr);cdecl;
//提示对话框
function TShowBox(txt:pStr):Boolean;cdecl;
//显示输入框
function SInputBox(msg:string;var str1:string):Boolean;cdecl;
//打开对话框
function OpenDlg(strdefault:pStr):pStr;cdecl;
//打开保存对话框 [初始路径,保存名,类型]
function SaveDlg(sPath,sName,sType:pStr):pStr;cdecl;
//写日志
function writeWorkLog(sqlstr: pStr):Boolean;cdecl;
  

implementation

procedure ShowBox(txt:pStr);cdecl;
begin
  Application.MessageBox(PChar(txt), '提示', MB_OK);
end;

procedure ShowBoxNum(txt:Int64); cdecl;
begin
  Application.MessageBox(PChar(IntToStr(txt)), '提示', MB_OK);
end;

procedure EShowBox(txt:pStr);cdecl;
begin
  Application.MessageBox(PChar(txt), '警告!', MB_ICONERROR);
end;

function TShowBox(txt:pStr):Boolean;cdecl;
begin
  if Application.MessageBox(PChar(txt),
  '提示!',MB_YESNO + MB_ICONQUESTION) =6 then
    Result:= True
  else
    Result:=False;
end;

function SInputBox(msg:string;var str1:string):Boolean;cdecl;
begin
  Result:=InputQuery('提示!', msg, str1);
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
    open.InitialDir:= strdefault; //初始路径
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

function writeWorkLog(sqlstr: pStr):Boolean;cdecl;
  function GetSTR(stmp:TDateTime):pStr;
  var
    tmp:pStr;
  begin
    tmp:=DateToStr(stmp);
    tmp:=StringReplace(tmp, '/', '', [rfReplaceAll]); // 去掉/
    Result := StringReplace(tmp, '\', '', [rfReplaceAll]); // 去掉\
  end;
var
  filev: TextFile;
  ss: pStr;
begin
//  if closelog then Exit;
  sqlstr:=DateTimeToStr(Now)+' Log: '+sqlstr;

  DateToStr(now);
  ss:=ExtractFilePath(ParamStr(0))+'log\'+GetSTR(now)+'.Log';
  ForceDirectories(ExtractFilePath(ParamStr(0))+'log\');
  if FileExists(ss) then
  begin
    AssignFile(filev, ss);
    append(filev);
    writeln(filev, sqlstr);
  end else begin
    AssignFile(filev, ss);
    ReWrite(filev);
    writeln(filev, sqlstr);
  end;
  CloseFile(filev);
  Result := true;
end;






exports
writeWorkLog    {$IFDEF CDLE}name 'OxU00000001'{$ENDIF},
SInputBox       {$IFDEF CDLE}name 'OxU00000002'{$ENDIF},
OpenDlg         {$IFDEF CDLE}name 'OxU00000003'{$ENDIF},
SaveDlg         {$IFDEF CDLE}name 'OxU00000004'{$ENDIF},
ShowBox         {$IFDEF CDLE}name 'OxU00000005'{$ENDIF},
ShowBoxNum      {$IFDEF CDLE}name 'OxU00000006'{$ENDIF},
EShowBox        {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
TShowBox        {$IFDEF CDLE}name 'OxU00000008'{$ENDIF};


end.
