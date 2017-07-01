//------------------------------------------------------------------------------
//
//      文件和字符的相关操作
//
//
//------------------------------------------------------------------------------
unit UFile;
interface
uses
  Windows, StrUtils, SysUtils, IniFiles, Classes, Types, ShellApi;

type
  WStr= WideString;
  pStr= String;

//读ini文件 返回字符
function ReadINI(node,code,value:WStr):WStr;cdecl;
//读ini文件 返回int
function RINIInt(node,code,value:WStr):Integer;cdecl;
//读ini文件 返回bool
function RINIBool(node,code,value:WStr):Boolean;cdecl;
//写INI文件
function WriteINI(node,code,value:WStr):Boolean;cdecl;
//获取程序名(0程序名1当前路径)
function GetExePath(code:Integer=0):WStr; cdecl;
//text保存到pFile文件
function SaveText(text,pFile:WStr):Boolean;cdecl;
//字符串保持为文件 StrToFile(str,'c:\a.dat')
function StrToFile(mString:WStr;mFileName:TFileName):Boolean;cdecl;
//读取文件为16进制到字符串
function ReadFileToHex(FileName: WStr): WStr;cdecl;
//读取文件为10进制到字符串
function ReadFileToTen(FileName: WStr): WStr;cdecl;
//读取文本文件到string
function TextFileToStr(FileName: WStr): WStr;cdecl;
//读取文件到string
function FileToString(mFileName:TFileName):WStr;cdecl;
//流转字符str
function StreamToStr(mStream:TStream):WStr;cdecl;
//内存流转字符str
function StreamGOStr(mStream:TMemoryStream):WStr;cdecl;
//字符存到流中
function StrToStream(mString:WStr;const mStream:TStream):Boolean;cdecl;
//文件生成流
function ByteStreamF(FileName: WStr):TByteDynArray;cdecl;
//流中读取len字符串出来(c++)
function StreamToStrCPP(const mStream: TStream; len: integer): AnsiString;cdecl;
//将字符写入流中去(c++)
function StrToStreamCPP(const mStream: TStream; Value: AnsiString):Boolean;cdecl;
//加单引号[数据库常用]
function QStr(const S: WStr): WStr;cdecl;
//取前面n个字符
function GetAgoN(const tmp:WStr;n:Integer=1):WStr;cdecl;
//取后面n个字符
function GetLastN(const tmp:WStr;n:Integer=1):WStr;cdecl;
//去掉前面n个字符
function GetNotAgoN(const tmp:WStr;n:Integer=1):WStr;cdecl;
//去掉后面n个符号
function GetNotLastN(const tmp:WStr;n:Integer=1):WStr;cdecl;
//返回值在0到1之间，0表示不相似，1表示完全相似。
function StrSimilar(const Str1, Str2: pStr; ICase: Boolean=False): Double;cdecl;
//Delphi转C++ char*
function StringToChar(const str:WStr):PAnsiChar;cdecl;
//C++ char*转delphi string
function CharToString(const str:PAnsiChar):WStr;cdecl;
//检查文件路径最后的\ // 是否加斜线 是否用双线
function CheckPathOK(Tpath: pStr;Topen:Boolean=True;Ttwo:Boolean=False):pStr;cdecl;


implementation

function ReadINI(node, code,value: WStr): WStr;cdecl;
var
  cfgfile: TIniFile;
begin
//  cfgfile := TIniFile.Create(extractfilepath(ParamStr(0)) + 'Cfg.ini');
  cfgfile := TIniFile.Create(extractfilepath(ParamStr(0)) + GetExePath() +'.ini');
  Result := cfgfile.ReadString(node, code, value);
  cfgfile.Free;
end;

function RINIInt(node,code,value:WStr):Integer;cdecl;
begin
  Result:=StrToInt(ReadINI(node,code,value));
end;

function RINIBool(node,code,value:WStr):Boolean;cdecl;
var
  cfgfile: TIniFile;
  tmp:Integer;
begin
  cfgfile := TIniFile.Create(extractfilepath(ParamStr(0)) + GetExePath() +'.ini');
  tmp := StrToInt(cfgfile.ReadString(node, code, value));
  case tmp of
    0:Result := False;
    1:Result := True;
  end;
  cfgfile.Free;
end;

function WriteINI(node,code,value:WStr):Boolean;cdecl;
var
  filename:WStr;
  cfgfile:Tinifile;
begin
  filename:=ExtractFilePath(Paramstr(0))+GetExePath() +'.ini';
  cfgfile:=tinifile.Create(filename);
  cfgfile.WriteString(node,code,value);
  cfgfile.Free;
  Result := True;
end;

function GetExePath(code:Integer):WStr; cdecl;
begin
  case code of
    0:Result:= ChangeFileExt(ExtractFileName(ParamStr(0)),'');  //获取程序名(不带扩展名)
    1:Result:= extractfilepath(ParamStr(0));                    //获取当前路径
  end;
end;

function SaveText(text,pFile:WStr):Boolean;cdecl;
var
  str:TStrings;
begin
  str:=TStringList.Create;
  str.Text:=text;
  str.SaveToFile(pFile);
  str.Free;
  Result:= True;
end;

function StrToFile(mString:WStr;mFileName:TFileName):Boolean;cdecl;
{   返回字符串保存到文件是否成功   }
var
  vFileChar:  file of Char;
  I: Integer;
begin
  {$I-}
  {$IFDEF VER150}
  //D7 现在不行
  {$ELSE}
  AssignFile(vFileChar,mFileName);
  Rewrite(vFileChar);
  for I := 1 to Length(mString) do Write(vFileChar,mString[I]);
  CloseFile(vFileChar);
  {$ENDIF}
  {$I+}
  Result:=(IOResult=0) and (mFileName<>'');
end;

function ReadFileToHex(FileName: WStr): WStr;cdecl;
var
  b: Byte;
begin
  Result := '';
  if not FileExists(FileName) then Exit;
  with TMemoryStream.Create do
  begin
    LoadFromFile(FileName);
    Position := 0;
    while Position < Size do
    begin
      ReadBuffer(b, 1);
      Result := Result + Format('%.2x', [b]);
    end;
    Trim(Result);
    Free;
  end;
end;

function ReadFileToTen(FileName: WStr): WStr;cdecl;
var
  mMem :TMemoryStream;
  txt: WStr;
begin
  mMem := TMemoryStream.Create;
  mMem.LoadFromFile(FileName);
  SetLength(txt, mMem.size);
  mMem.Position := 0;
  mMem.Read(Pointer(txt)^,mMem.size) ;
  Result:= txt;
  mMem.Free;
end;

function TextFileToStr(FileName: WStr): WStr;cdecl;
var
  sd:TStrings;
begin
  Result:='';
  if Length(FileName)<1 then Exit;
  sd:=TStringList.Create;
  try
    sd.LoadFromFile(FileName);
    Result:=sd.Text;
  except
    Exit;
  end;
end;

function FileToString(mFileName:TFileName):WStr;cdecl;
{   返回从文件载入字符串   }
var
  vFileChar:file of Char;
  vChar:Char;
begin
  Result:='';
{$I-}
  AssignFile(vFileChar,mFileName);
  Reset(vFileChar);
  while not Eof(vFileChar) do
  begin
    Read(vFileChar,vChar);
    Result:=Result+vChar;
  end;
  CloseFile(vFileChar);
{$I+}
end;

function StreamToStr(mStream:TStream):WStr;cdecl;
{   将内存流转换成字符串   }
var
  I:Integer;
begin
  Result:='';
  if not Assigned(mStream) then  Exit;
  SetLength(Result,mStream.Size);
  for I:=0 to Pred(mStream.Size) do
  try
    mStream.Position:=I;
    mStream.Read(Result[Succ(I)],1);
  except
    Result:='';
  end;
end;

function StreamGOStr(mStream: TMemoryStream):WStr;cdecl;
var
  charBuffer: PAnsiChar;
  //wew: TStringStream;
begin
  SetLength(Result, mStream.Size);
  GetMem(charBuffer, mStream.Size);
  Move(PAnsiChar(mStream.Memory)^, charBuffer^, mStream.Size);
  Result := PChar(charBuffer);
  FreeMem(charBuffer);
end;

function StrToStream(mString:WStr;const mStream:TStream):Boolean; cdecl;
{   返回将字符串保存到内存流是否成功   }
var
  I:Integer;
begin
  Result:=True;
  try
    mStream.Size:=0;
    mStream.Position:=0;
    for I:=1 to Length(mString) do
      mStream.Write(mString[I],1);
  except
    Result:=False;
  end;

  //方法2
  //ssm:TStringStream;
  //ssm:=TStringStream.create(s);
  //desStream.copyfrom(ssm,ssm.size);
end;

function ByteStreamF(FileName: WStr):TByteDynArray;cdecl;
var
  memstrm:Tmemorystream;
  var_byte:TByteDynArray;
begin
  try
    var_byte:=nil;
    memstrm:=tmemorystream.Create;
    memstrm.Clear;
    memstrm.LoadFromFile(FileName);
    SetLength(var_byte,memstrm.size);
    memstrm.Position:=0;
    memstrm.Read(var_byte[0],memstrm.Size);
    Result:= var_byte;
  except
    on E:exception do
    begin
      memstrm.Free;
      var_byte:=nil;
      exit;
    end;
  end;
end;

function StreamToStrCPP(const mStream: TStream; len: integer): AnsiString;cdecl;
var
  x: integer;
begin
  Setlength(Result, Len);
  x := mStream.read(Pchar(Result)^, Len);
  SetLength(Result, x);
end;

function StrToStreamCPP(const mStream: TStream; Value: AnsiString):Boolean;cdecl;
begin
  mStream.Write(PChar(Value)^, Length(Value));
  Result:=True;
end;

function QStr(const S: WStr): WStr;cdecl;
var
  I: Integer;
begin
  Result := S;
  for I := Length(Result) downto 1 do
    if Result[I] = '''' then
      Insert('''', Result, I);
  Result := '''' + Result + '''';
end;

function GetAgoN(const tmp:WStr;n:Integer=1):WStr;cdecl;
var
  k,p:Integer;
begin
  k:=Length(tmp);
  p:=n;
  if n>k then p:=k;
  Result:= Copy(tmp, 1, p);
end;

function GetLastN(const tmp:WStr;n:Integer=1):WStr;cdecl;
var
  k,p:Integer;
begin
  k:=Length(tmp);
  p:=n;
  if n>k then p:=k;
  Result:=Copy(tmp, k-p+1, p);
end;

function GetNotAgoN(const tmp:WStr;n:Integer=1):WStr;cdecl;
var
  k, p:Integer;
begin
  k:=Length(tmp);
  p:=n;
  if n>k then p:=k;
  Result:=Copy(tmp, (p+1), k-p);
end;

function GetNotLastN(const tmp:WStr;n:Integer=1):WStr;cdecl;
var
  k,p:Integer;
begin
  k:=Length(tmp);
  p:=n;
  if n>k then p:=k;
  Result:=Copy(tmp, 1, k-p);
end;

function DamerauLevenshteinDistance(const Str1, Str2: string): Integer;
var
  LenStr1, LenStr2: Integer;
  I, J, T, Cost, Minimum: Integer;
  pStr1, pStr2, S1, S2: PChar;
  D, RowPrv2, RowPrv1, RowCur, Temp: PIntegerArray;
begin
  LenStr1 := Length(Str1);
  LenStr2 := Length(Str2);

  // to save some space, make sure the second index points to the shorter string
  if LenStr1 < LenStr2 then begin
    T := LenStr1;
    LenStr1 := LenStr2;
    LenStr2 := T;
    pStr1 := PChar(Str2);
    pStr2 := PChar(Str1);
  end
  else begin
    pStr1 := PChar(Str1);
    pStr2 := PChar(Str2);
  end;

  // to save some time and space, look for exact match
  while (LenStr2 <> 0) and (pStr1^ = pStr2^) do begin
    Inc(pStr1);
    Inc(pStr2);
    Dec(LenStr1);
    Dec(LenStr2);
  end;

  // when one string is empty, length of the other is the distance
  if LenStr2 = 0 then begin
    Result := LenStr1;
    Exit;
  end;

  // calculate the edit distance
  T := LenStr2 + 1;
  GetMem(D, 3 * T * SizeOf(Integer));
  FillChar(D^, 2 * T * SizeOf(Integer), 0);
  RowCur := D;
  RowPrv1 := @D[T];
  RowPrv2 := @D[2 * T];
  S1 := pStr1;

  for I := 1 to LenStr1 do begin
    Temp := RowPrv2;
    RowPrv2 := RowPrv1;
    RowPrv1 := RowCur;
    RowCur := Temp;
    RowCur[0] := I;
    S2 := pStr2;

    for J := 1 to LenStr2 do begin
      Cost := Ord(S1^ <> S2^);
      Minimum := RowPrv1[J - 1] + Cost;                 // substitution
      T := RowCur[J - 1] + 1;                           // insertion
      if T < Minimum then Minimum := T;
      T := RowPrv1[J] + 1;                              // deletion
      if T < Minimum then Minimum := T;
      if (I <> 1) and (J <> 1) and (S1^ = (S2 - 1)^) and (S2^ = (S1 - 1)^) then begin
        T := RowPrv2[J - 2] + Cost;                     // transposition
        if T < Minimum then Minimum := T;
      end;
      RowCur[J] := Minimum;
      Inc(S2);
    end;
    Inc(S1);
  end;

  Result := RowCur[LenStr2];
  FreeMem(D);
end;

function StrSimilar(const Str1, Str2: pStr; ICase: Boolean): Double;cdecl;
var
  MaxLen: Integer;
  Distance: Integer;
begin
  Result := 1.0;

  if Length(Str1) > Length(Str2) then
    MaxLen := Length(Str1)
  else
    MaxLen := Length(Str2);

  if MaxLen <> 0 then begin
    if ICase then
      Distance := DamerauLevenshteinDistance(LowerCase(Str1), LowerCase(Str2))
    else
      Distance := DamerauLevenshteinDistance(Str1, Str2);

    Result := Result - (Distance / MaxLen);
  end;
end;

function StringToChar(const str:WideString):PAnsiChar;cdecl;
begin
  Result:=PAnsiChar(AnsiString(str));
end;

function CharToString(const str:PAnsiChar):WideString;cdecl;
begin
  Result:= str;
end;

function CheckPathOK(Tpath: pStr;Topen:Boolean=True;Ttwo:Boolean=False):pStr;cdecl;
begin      //检查目录名后面是否有'\'
  if Ttwo then
  begin
    if Copy(Tpath,Length(Tpath)-1,2)<>'\\'then
      if Topen then Result:=Tpath+'\\' else Result:=Copy(Tpath,1,Length(Tpath)-2)
    else
      Result:=Tpath;
  end else begin
    if Copy(Tpath,Length(Tpath),1)<>'\'then
      if Topen then Result:=Tpath+'\' else Result:=Copy(Tpath,1,Length(Tpath)-1)
    else
      Result:=Tpath;
  end;    

  {  下面是老算法
  if Topen then
  begin              //加上斜线
    if Ttwo then
    begin
      if Copy(Tpath,Length(Tpath)-1,2)<>'\\'then Result:=Tpath+'\\' else Result:=Tpath;
    end else begin
      if Copy(Tpath,Length(Tpath),1)<>'\'then Result:=Tpath+'\' else  Result:=Tpath;
    end;
  end else begin     //去掉斜线
    if Ttwo then
    begin
      if Copy(Tpath,Length(Tpath)-1,2)='\\'then Result:=Copy(Tpath,1,Length(Tpath)-2) else Result:=Tpath;
    end else begin
      if Copy(Tpath,Length(Tpath),1)='\'then Result:=Copy(Tpath,1,Length(Tpath)-1) else Result:=Tpath;
    end;
  end;
  }
end;

















































//exports
//writeWorkLog    {$IFDEF CDLE}name 'OxU00000001'{$ENDIF},
//SInputBox       {$IFDEF CDLE}name 'OxU00000002'{$ENDIF},
//OpenDlg         {$IFDEF CDLE}name 'OxU00000003'{$ENDIF},
//SaveDlg         {$IFDEF CDLE}name 'OxU00000004'{$ENDIF},
//ShowBox         {$IFDEF CDLE}name 'OxU00000005'{$ENDIF},
//ShowBoxNum      {$IFDEF CDLE}name 'OxU00000006'{$ENDIF},
//EShowBox        {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
//TShowBox        {$IFDEF CDLE}name 'OxU00000008'{$ENDIF};

end.
