//------------------------------------------------------------------------------
//
//      �ļ����ַ�����ز���
//
//
//------------------------------------------------------------------------------
unit UFile;
interface
uses
  Windows, StrUtils, SysUtils, Forms, IniFiles, Classes, Types, ShellApi;

type
  WStr= WideString;
  pStr= String;

//��ini�ļ� �����ַ�
function ReadINI(node,code,value:WStr):WStr;cdecl;
//��ini�ļ� ����int
function RINIInt(node,code,value:WStr):Integer;cdecl;
//��ini�ļ� ����bool
function RINIBool(node,code,value:WStr):Boolean;cdecl;
//дINI�ļ�
function WriteINI(node,code,value:WStr):Boolean;cdecl;
//��ȡ������(0������1��ǰ·��)
function GetExePath(code:Integer=0):WStr; cdecl;
//text���浽pFile�ļ�
function SaveText(text,pFile:WStr):Boolean;cdecl;
//�ַ�������Ϊ�ļ� StrToFile(str,'c:\a.dat')
function StrToFile(mString:WStr;mFileName:TFileName):Boolean;cdecl;
//��ȡ�ļ�Ϊ16���Ƶ��ַ���
function ReadFileToHex(FileName: WStr): WStr;cdecl;
//��ȡ�ļ�Ϊ10���Ƶ��ַ���
function ReadFileToTen(FileName: WStr): WStr;cdecl;
//��ȡ�ı��ļ���string
function TextFileToStr(FileName: WStr): WStr;cdecl;
//��ȡ�ļ���string
function FileToString(mFileName:TFileName):WStr;cdecl;
//��ת�ַ�str
function StreamToStr(mStream:TStream):WStr;cdecl;
//�ڴ���ת�ַ�str
function StreamGOStr(mStream:TMemoryStream):WStr;cdecl;
//�ַ��浽����
function StrToStream(mString:WStr;const mStream:TStream):Boolean;cdecl;
//�ļ�������
function ByteStreamF(FileName: WStr):TByteDynArray;cdecl;
//���ж�ȡlen�ַ�������(c++)
function StreamToStrCPP(const mStream: TStream; len: integer): AnsiString;cdecl;
//���ַ�д������ȥ(c++)
function StrToStreamCPP(const mStream: TStream; Value: AnsiString):Boolean;cdecl;
//�ӵ�����[���ݿⳣ��]
function QStr(const S: WStr): WStr;cdecl;
//ȡǰ��n���ַ�
function GetAgoN(const tmp:WStr;n:Integer=1):WStr;cdecl;
//ȡ����n���ַ�
function GetLastN(const tmp:WStr;n:Integer=1):WStr;cdecl;
//ȥ��ǰ��n���ַ�
function GetNotAgoN(const tmp:WStr;n:Integer=1):WStr;cdecl;
//ȥ������n������
function GetNotLastN(const tmp:WStr;n:Integer=1):WStr;cdecl;
//��(a,b,c,d)����תΪTStringList��
function RegExprType(str:string):TStrings;cdecl;
//����ֵ��0��1֮�䣬0��ʾ�����ƣ�1��ʾ��ȫ���ơ�
function StrSimilar(const Str1, Str2: pStr; ICase: Boolean=False): Double;cdecl;
//DelphiתC++ char*
function StringToChar(const str:WStr):PAnsiChar;cdecl;
//C++ char*תdelphi string
function CharToString(const str:PAnsiChar):WStr;cdecl;
//����ļ�·������\ // �Ƿ��б�� �Ƿ���˫��
function CheckPathOK(Tpath: pStr;Topen:Boolean=True;Ttwo:Boolean=False):pStr;cdecl;
//ɾ������
function DelPathDir(const mpath:pStr):Boolean;cdecl;
//ɾ������tname���ļ���
function DelPathDirEX(const mpath:pStr;tname:pStr='.svn'):TStrings;cdecl;
//����·�����kname���˵�����[0�ݹ�ȫ��,1�ݹ��ļ���,2�ݹ��ļ�,3��ǰ�ļ���,4��ǰ�ļ�]
function GetDirFiles(path:pStr;idtype:integer=0; kname:pStr=''):TStrings;cdecl;
//ȫ·������[idtype 0��ǰ·��1������չ��]
function ReFileName(const OldName,NewName,ty:pStr;idtype:Integer=0):pStr;cdecl;
//�ͷ���Դ (dll�в����ͷ�exe����Դ)
function ExtractRes(ResType, ResName, ResNewName: string): boolean;cdecl;






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
    0:Result:= ChangeFileExt(ExtractFileName(ParamStr(0)),'');  //��ȡ������(������չ��)
    1:Result:= extractfilepath(ParamStr(0));                    //��ȡ��ǰ·��
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
{   �����ַ������浽�ļ��Ƿ�ɹ�   }
var
  vFileChar:  file of Char;
  I: Integer;
begin
  {$I-}
  {$IFDEF VER150}
  //D7 ���ڲ���
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
{   ���ش��ļ������ַ���   }
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
{   ���ڴ���ת�����ַ���   }
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
{   ���ؽ��ַ������浽�ڴ����Ƿ�ɹ�   }
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

  //����2
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

function RegExprType(str:string):TStrings;cdecl;
begin
  Result:=TStringList.Create;
  ExtractStrings([','],[],{$IFDEF VER150}pchar(str){$ELSE}PWideChar(str){$ENDIF},Result);
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
begin      //���Ŀ¼�������Ƿ���'\'
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

  {  ���������㷨
  if Topen then
  begin              //����б��
    if Ttwo then
    begin
      if Copy(Tpath,Length(Tpath)-1,2)<>'\\'then Result:=Tpath+'\\' else Result:=Tpath;
    end else begin
      if Copy(Tpath,Length(Tpath),1)<>'\'then Result:=Tpath+'\' else  Result:=Tpath;
    end;
  end else begin     //ȥ��б��
    if Ttwo then
    begin
      if Copy(Tpath,Length(Tpath)-1,2)='\\'then Result:=Copy(Tpath,1,Length(Tpath)-2) else Result:=Tpath;
    end else begin
      if Copy(Tpath,Length(Tpath),1)='\'then Result:=Copy(Tpath,1,Length(Tpath)-1) else Result:=Tpath;
    end;
  end;
  }
end;

function DeleteFile(const FileName: pStr;kill:Boolean=False): Boolean;stdcall;
begin
  if kill then
  begin
    //��ȥ������
//    FileSetAttr(PChar(FileName),0);
    setFileAttributes(PChar(FileName),0);
//    setFileAttributes(PChar(FileName),(not faSysFile));
//    setFileAttributes(PChar(FileName),((not faReadOnly)and(not faSysFile)));
  end;
  {$IFDEF MSWINDOWS}
    Result := Windows.DeleteFile(PChar(FileName));
  {$ENDIF}
  {$IFDEF LINUX}
    Result := unlink(PChar(FileName)) <> -1;
  {$ENDIF}
end;

function DelPathDir(const mpath:pStr):Boolean;cdecl;
var
  sr:TSearchRec;
  sPath,sFile:pStr;
begin
  //���Ŀ¼�������Ƿ���'\'
  if Copy(mpath,Length(mpath),1)<>'\' then
    sPath:=mpath+'\'
  else
    sPath:=mpath;
  //------------------------------------------------------------------
  if FindFirst(sPath+'*.*',faAnyFile,sr)=0 then
  begin
    repeat
      sFile:=Trim(sr.Name);
      if sFile='.' then Continue;
      if sFile='..' then Continue;
      sFile:=sPath+sr.Name;
      if(sr.Attr and faDirectory)<>0 then
        DelPathDir(sFile)       //�ݹ�
      else if(sr.Attr and faAnyFile)=sr.Attr then
        DeleteFile(sFile);    //ɾ���ļ�
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
  RemoveDir(sPath);

end;

function DelPathDirEX(const mpath:pStr;tname:pStr='.svn'):TStrings;cdecl;
var
  fpath,s: pStr;
  fs: TsearchRec;
function loop():TStrings;
begin
  Result:=TStringList.Create;
  if (fs.Name<>'.')and(fs.Name<>'..') then
  if (fs.Attr and faDirectory)=faDirectory then
  begin
    if (tname='') or (fs.Name=tname) then
    begin
      Result.Add(mpath+'\'+fs.Name);
      DelPathDir(mpath+'\'+fs.Name);
    end else begin
      Result.AddStrings(DelPathDirEX(mpath+'\'+fs.Name,mpath));
    end;
  end;
end;
begin
  fpath:=mpath+'\*.*';
  Result:=TStringList.Create;
  if FindFirst(fpath,faAnyFile,fs)=0 then
  begin
    Result.AddStrings(loop());
    while findnext(fs)=0 do
    begin
      Result.AddStrings(loop());
    end;
  end;
  Findclose(fs);
end;

function GetDirFiles(path:pStr;idtype:integer=0; kname:pStr=''):TStrings;cdecl;
var
  fpath,s: pStr;
  fs: TsearchRec;
  icount,i,JPG: Integer;

  function LoopD():TStrings;
  begin
    Result:=TStringList.Create;
    if (fs.Name<>'.')and(fs.Name<>'..') then
      if (fs.Attr and faDirectory)=faDirectory then
        Result.AddStrings(GetDirFiles(path+'\'+fs.Name,2,kname))
      else if RightStr(fs.Name,JPG)=kname then
        begin
          Result.Add(fs.Name);
          //writeWorkLog(path+'\'+fs.Name);
        end;
  end;
begin
  case idtype of
     0: begin      //����ȫ�ݹ�
          fpath:=CheckPathOK(path)+'*.*';
          Result:=TStringList.Create;
          if FindFirst(fpath,faAnyFile,fs)=0 then
          begin
            if (fs.Name<>'.')and(fs.Name<>'..') then
            if (fs.Attr and faDirectory)=faDirectory then
              Result.AddStrings( GetDirFiles(path+'\'+fs.Name,0,kname))
            else
              Result.add(fs.Name);//Result.add(strpas(strupper(pchar(fs.Name))) );
            while findnext(fs)=0 do
            begin
              if (fs.Name<>'.')and(fs.Name<>'..') then
              if (fs.Attr and faDirectory)=faDirectory then
                Result.AddStrings( GetDirFiles(path+'\'+fs.Name,0,kname) )
              else begin
                Result.add(fs.Name);
              end;
            end;
            Application.ProcessMessages;
          end;
          Findclose(fs); 
        end;
     1: begin      //�����ļ����µ��ļ����б� �ݹ��ļ���
          fpath:=path+'\*.*';
          Result:=TStringList.Create;
          if FindFirst(fpath,faAnyFile,fs)=0 then
          begin
            if (fs.Name<>'.')and(fs.Name<>'..') then
            if (fs.Attr and faDirectory)=faDirectory then
            begin
              if (kname='') or (fs.Name=kname) then Result.Add(fs.Name);
              Result.AddStrings(GetDirFiles(path+'\'+fs.Name,1,kname))
            end;

            while findnext(fs)=0 do
            begin
              if (fs.Name<>'.')and(fs.Name<>'..') then
              if (fs.Attr and faDirectory)=faDirectory then
              Begin
                if (kname='') or (fs.Name=kname) then Result.Add(fs.Name);
                Result.AddStrings( GetDirFiles(path+'\'+fs.Name,1,kname))
              End;
            end;
          end;
          Findclose(fs);
        end;
     2: begin
          fpath:=CheckPathOK(path)+'*.*';          //fpath:=path+'\*.*';
          JPG:=Length(kname);
          Result:=TStringList.Create;
          if FindFirst(fpath,faAnyFile,fs)=0 then
          begin
            Result.AddStrings(LoopD());
            while findnext(fs)=0 do
            begin
              Result.AddStrings(LoopD());
            end;
            Application.ProcessMessages;
          end;
          Findclose(fs);
        end;
     3: begin     //�����ļ����µ��ļ����б�
          fpath:=path+'\*.*';
          Result:=TStringList.Create;
          if FindFirst(fpath,faAnyFile,fs)=0 then
          begin
            if (fs.Name<>'.')and(fs.Name<>'..') then
              if (fs.Attr and faDirectory)=faDirectory then
                Result.Add(fs.Name);

              while findnext(fs)=0 do
              begin
                if (fs.Name<>'.')and(fs.Name<>'..') then
                  if (fs.Attr and faDirectory)=faDirectory then
                    Result.Add(fs.Name);
              end;
          end;
          Findclose(fs);
        end;
     4: begin     //������ǰ�ļ���
          //ChDir(path); //���õ�ǰ·��Ϊ����Ŀ¼
          //���Ŀ¼�������Ƿ���'\'
          fpath:=CheckPathOK(path);
        //  if Copy(path,Length(path),1)<>'\'then
        //    sPath:=path+'\'
        //  else
        //    sPath:=path;

          JPG := FindFirst(fpath+'*'+kname, faAnyFile, fs); //����*.xxx
          Result:=TStringList.Create;
          while JPG = 0 do
          begin
            Inc(icount);
            Result.Add(fs.Name);
            JPG := FindNext(fs);
          end;
        end;
  end;
end;

function ReFileName(const OldName,NewName,ty:pStr;idtype:Integer=0):pStr;cdecl;
var
  tmp,tpath:pStr;
begin
  result:='';
  case idtype of
  0:  begin
        //�������ļ�����չ����Ϊָ������չ�� ChangeFileExtName('d:\123.wmv','.wav') ����Ϊ d:\123.wav
        {           //���� c:\abc\def.gh
        ExtractFileDir        ����        ������������·��    c:\abc
        ExtractFileExt        ����        �����ļ��ĺ�׺      .gh
        ExtractFileName       ����        �����ļ���          def.gh
        ExtractFilePath       ����        ����ָ���ļ���·��  c:\abc\
        }
        tmp:=ExtractFileExt(OldName);
        result:=Copy(OldName,1,Pos(tmp,OldName)-1)+NewName;
      end;
  1:  begin
        //newname:=StringReplace(newname, '.', '', [rfReplaceAll]); // ȥ��.
        if not FileExists(oldname) then
        begin
          Application.MessageBox('�ļ�������!', '��ʾ', MB_OK);
          Exit;
        end;
        tmp:=ExtractFileExt(oldname);     //�õ���׺��
        tpath:= ExtractFilePath(oldname); //�õ�·��
        Try
          RenameFile(oldname,tpath+newname+tmp);
          Exit;
        except
          Application.MessageBox('error!', '��ʾ', MB_OK);
        End;
      end;
  2:  begin
        if ty='' then
        begin
          if not FileExists(oldname) then
          begin
            Application.MessageBox('�ļ�������!', '��ʾ', MB_OK);
            Exit;
          end;
          Try
            RenameFile(oldname,newname);
            Exit;
          except
            Application.MessageBox('error!', '��ʾ', MB_OK);
          End;
        end;

        Try
          CheckPathOK(Tpath);
          if not FileExists(Tpath+oldname) then
          begin
            Application.MessageBox('�ļ�������!', '��ʾ', MB_OK);
            Exit;
          end;
          RenameFile(Tpath+oldname,Tpath+newname);
          Exit;
        except
          Application.MessageBox('error!', '��ʾ', MB_OK);
        End;
      end;
  end;
end;

function ExtractRes(ResType, ResName, ResNewName: string): boolean;cdecl;
var
  Res: TResourceStream;
begin
  try
    Res := TResourceStream.Create(Hinstance, Resname, Pchar(ResType));
    try
      Res.SavetoFile(ResNewName);
      Result := true;
    finally
      Res.Free;
    end;
  except
    Result := false;
  end;
end;




exports
ReadINI                 {$IFDEF CDLE}name 'OxU00000001'{$ENDIF},
RINIInt                 {$IFDEF CDLE}name 'OxU00000002'{$ENDIF},
RINIBool                {$IFDEF CDLE}name 'OxU00000003'{$ENDIF},
WriteINI                {$IFDEF CDLE}name 'OxU00000004'{$ENDIF},
GetExePath              {$IFDEF CDLE}name 'OxU00000005'{$ENDIF},
SaveText                {$IFDEF CDLE}name 'OxU00000006'{$ENDIF},
StrToFile               {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
ReadFileToHex           {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
ReadFileToTen           {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
TextFileToStr           {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
FileToString            {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
StreamToStr             {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
StreamGOStr             {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
StrToStream             {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
ByteStreamF             {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
StreamToStrCPP          {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
StrToStreamCPP          {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
QStr                    {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
GetAgoN                 {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
GetLastN                {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
GetNotAgoN              {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
GetNotLastN             {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
RegExprType             {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
StrSimilar              {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
StringToChar            {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
CharToString            {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
CheckPathOK             {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
DelPathDir              {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
DelPathDirEX            {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
GetDirFiles             {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
ReFileName              {$IFDEF CDLE}name 'OxU00000007'{$ENDIF},
ExtractRes              {$IFDEF CDLE}name 'OxU00000008'{$ENDIF};



end.
