unit USqlData;
//{$INCLUDE '..\TypeDef.inc'}
interface
uses
  classes, ADODB, UFile, UCommon, USocket, XMLIntf, XMLDoc,
  superxmlparser, superobject;
type
  TQry = TADOQuery;
  Tcoon = TADOConnection;

//测试打开数据库和连接数据库(仅供ACCE和MSsql数据库)
function DOpenDB(isTmp:Boolean;VAR Cnnp:Tcoon;stype:Integer=0):Boolean;stdcall;
//将数据表转为json
function DReadGrid(var DataCnn:Tcoon;sSql: string): string;stdcall;
//读取一个值
function DReadoneKey(var DataCnn:Tcoon;sSql: string;num:Integer): string;stdcall;
//读取一列值
function DReadoneRow(var DataCnn:Tcoon;sSql: string; num: Integer): TStrings;stdcall;
//xml拆分为组
function XmlToTstrings(XmlFile: string):TStrings;stdcall;
//流xml拆分为组
function XmlStreamToTstrings(mStream: TStream):TStrings;stdcall;
//Json拆分为组
function JsonToTstrings(sJson:string):TStrings; stdcall;

implementation

function DOpenDB(isTmp:Boolean;VAR Cnnp:Tcoon;stype:Integer):Boolean;stdcall;
//stype 为0是access 1是mssql
var
  DataCnnp: Tcoon;
begin
  Result := False;
  if not CheckOffline then
  begin
    ShowBox('系统网络有问题');
    Exit;
  end;
  case stype of
  0:  begin
        if isTmp then
        begin
          try   // 临时测试数据库连接
            DataCnnp := Tcoon.Create(nil);
            try
              DataCnnp.Connected:=False;
              DataCnnp.LoginPrompt := False;
              DataCnnp.Provider := 'Microsoft.Jet.OLEDB.4.0';
              DataCnnp.ConnectionString := 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source='+
              ReadINI('ZNBMs','Database','ESB.mdb')+';Persist Security Info=False;';
              DataCnnp.Mode := cmShareDenyNone;
              DataCnnp.Connected := True;
              if DataCnnp.Connected then
              begin
                Result := True;
                ShowBox('连接成功');
              end;
            except
              Result := False;
              ShowBox('数据库连接错误,请检查设置!');
              Exit;
            end;
          finally
            DataCnnp.Free;
          end;
        end else begin
          Try
            Cnnp.Connected:=False;
            Cnnp.LoginPrompt := False;
            Cnnp.Provider := 'Microsoft.Jet.OLEDB.4.0';
            Cnnp.ConnectionString := 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source='+
            ReadINI('ZNBMs','Database','ESB.mdb')+';Persist Security Info=False;';
            Cnnp.Mode := cmShareDenyNone;
            Cnnp.Connected := True;
            if Cnnp.Connected then
            begin
              Result := True;
            end;
          Except
            Result := False;
            ShowBox('数据库连接错误,请检查设置!');
            Exit;
          end;
        end;
      end;
  1:  begin
        if isTmp then
        begin
          try   // 临时测试数据库连接
            DataCnnp := Tcoon.Create(nil);
            try
              DataCnnp.Connected:=False;
              DataCnnp.LoginPrompt := False;
              DataCnnp.ConnectionString:='Provider=SQLOLEDB.1;Persist Security Info=True;'+
              'Data Source='+ ReadINI('ZNBMs','DBServer','127.0.0.1')+        //数据源
              ';Initial Catalog='+ReadINI('ZNBMs','Database', 'tmdata')+      //数据库名
              ';User ID='+ReadINI('ZNBMs','User', 'tmtest')+                  //用户名
              ';Password='+ ReadINI('ZNBMs','Password', 'tmtest');            //密码
              DataCnnp.Connected := True;
              if DataCnnp.Connected then
              begin
                Result := True;
                ShowBox('连接成功');
              end;
            except
              Result := False;
              ShowBox('数据库连接错误,请检查设置!');
              Exit;
            end;
          finally
            DataCnnp.Free;
          end;
        end else begin
          try
            Cnnp.Connected:=False;
            Cnnp.LoginPrompt := False;
            Cnnp.Provider := 'SQLOLEDB.1';
            Cnnp.ConnectionString:= 'Provider=SQLOLEDB.1;Persist Security Info=True'+
            ';Data Source='+                                   //数据源
            ReadINI('ZNBMs','DBServer','127.0.0.1')+
            ';Initial Catalog='+                               //数据库名
            ReadINI('ZNBMs','Database', 'tmdata')+
            ';User ID='+                                       //用户名
            ReadINI('ZNBMs','User', 'tmtest')+
            ';Password='+                                      //密码
            ReadINI('ZNBMs','Password', 'tmtest');
            Cnnp.Connected := True;
            if Cnnp.Connected then
            begin
              Result := True;
            end;
          Except
            Result := False;
            ShowBox('数据库连接错误,请检查设置!');
            Exit;
          end;
        end;
      end
  else
    ShowBox('error');
  end;
//下面是老版本的算法
//function TSQL.OpenDB(str: Boolean): Boolean;
//var
//  DataCnnp: Tcoon;
//begin
//  Result := False; // 默认为真
//  if not CheckOffline then
//  begin
//    ShowBox('系统网络有问题');
//    Exit;
//  end;
//  IF str THEN
//  begin
//    try   // 临时测试数据库连接
//      DataCnnp := Tcoon.Create(nil);
//      try
//        DataCnnp.Connected:=False;
//        DataCnnp.LoginPrompt := False;
//        {$IFDEF AECC}
//        {$IFDEF LibDll}
//        if not FileExists('ESB.mdb') then TResourceStream.Create(Hinstance, 'datRes', 'exefile').SavetoFile('ESB.mdb');
//        {$ELSE}
//        if not FileExists('ESB.mdb') then ExtractRes('exefile','datRes','ESB.mdb');  //判断数据库存在;
//        {$ENDIF}
//        DataCnnp.Provider := 'Microsoft.Jet.OLEDB.4.0';
//        DataCnnp.ConnectionString := 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source='+
//        ReadINI('ZNBMs','Database','ESB.mdb')+';Persist Security Info=False;';
//        DataCnnp.Mode := cmShareDenyNone;
//        {$ELSE}
//        DataCnnp.ConnectionString:='Provider=SQLOLEDB.1;Persist Security Info=True;'+
//        'Data Source='+ ReadINI('ZNBMs','DBServer','127.0.0.1')+        //数据源
//        ';Initial Catalog='+ReadINI('ZNBMs','Database', 'tmdata')+      //数据库名
//        ';User ID='+ReadINI('ZNBMs','User', 'tmtest')+                  //用户名
//        ';Password='+ ReadINI('ZNBMs','Password', 'tmtest');            //密码
//        {$ENDIF}
//        DataCnnp.Connected := True;
//        if DataCnnp.Connected then
//        begin
//          Result := True;
//          ShowBox('连接成功');
//        end;
//      except
//        Result := False;
//        ShowBox('数据库连接错误,请检查设置!');
//        Exit;
//      end;
//    finally
//      DataCnnp.Free;
//    end;
//  end else begin
//    Try
//      DataCnn.Connected:=False;
//      DataCnn.LoginPrompt := False;
//      {$IFDEF AECC}
//      {$IFDEF LibDll}
//      if not FileExists('ESB.mdb') then TResourceStream.Create(Hinstance, 'datRes', 'exefile').SavetoFile('ESB.mdb');
//      {$ELSE}
//      if not FileExists('ESB.mdb') then ExtractRes('exefile','datRes','ESB.mdb');  //判断数据库存在;
//      {$ENDIF}
//      DataCnn.Provider := 'Microsoft.Jet.OLEDB.4.0';
//      DataCnn.ConnectionString := 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source='+
//      ReadINI('ZNBMs','Database','ESB.mdb')+';Persist Security Info=False;';
//      DataCnn.Mode := cmShareDenyNone;
//      {$ELSE}
//      DataCnn.Provider := 'SQLOLEDB.1';
//      DataCnn.ConnectionString:= 'Provider=SQLOLEDB.1;Persist Security Info=True'+
//      ';Data Source='+                                   //数据源
//      ReadINI('ZNBMs','DBServer','127.0.0.1')+
//      ';Initial Catalog='+                               //数据库名
//      ReadINI('ZNBMs','Database', 'tmdata')+
//      ';User ID='+                                       //用户名
//      ReadINI('ZNBMs','User', 'tmtest')+
//      ';Password='+                                      //密码
//      ReadINI('ZNBMs','Password', 'tmtest');
//      {$ENDIF}
//      DataCnn.Connected := True;
//      if DataCnn.Connected then
//      begin
//        Result := True;
//        SqlOK:= true;     //Application.MessageBox('数据库连接ok', '提示', MB_OK);
//      end;
//    Except
//      Result := False;
//      ShowBox('数据库连接错误,请检查设置!');
//      Exit;
//    end;
//  end;
//end;

end;

function DReadGrid(var DataCnn:Tcoon;sSql: string): string;stdcall;
var
  oQry: TQry;
  I, J: Integer;
  skey,sTMP:string;
begin
  Result := ''; // 默认返回空
  oQry := TQry.Create(nil);
  try
    oQry.Connection := DataCnn;
    try
      oQry.Close;
      oQry.SQL.Clear;
      oQry.SQL.Add(sSql);
      oQry.Open;
      for J := 1 to oQry.RecordCount do       //      while not(oQry.Eof) do
      begin
        skey:='';
        for I := 0 to oQry.FieldCount-1 do
        begin
          skey:= skey+''''+oQry.Fields[I].FieldName +''':'''+ oQry.Fields[I].AsString+'''';
          if I<>(oQry.FieldCount-1) then skey:=skey+',';
        end;
        sTMP:=sTMP+'{'+skey+'}';
        if J<>(oQry.RecordCount) then sTMP:=sTMP+',';
        oQry.Next;
      end;
      Result:= '['+sTMP+']';
    except
    end;
  finally
    oQry.Free;
  end;
end;

function DReadoneKey(var DataCnn:Tcoon;sSql: string;num:Integer): string;stdcall;
var
  oQry: TQry;
begin
  oQry := TQry.Create(nil);
  try
    oQry.Connection := DataCnn;
    try
      oQry.Close;
      oQry.SQL.Clear;
      oQry.SQL.Add(sSql);
      oQry.Open;
      Result := oQry.Fields[num].AsString;    //第几个字段
    except
      Result := '';
    end;
  finally
    oQry.Free;
  end;
end;

function DReadoneRow(var DataCnn:Tcoon;sSql: string; num: Integer): TStrings;stdcall;
var
  oQry: TQry;
  I: Integer;
begin
  Result:=TStringList.Create;
  oQry := TQry.Create(nil);
  try
    oQry.Connection := DataCnn;
    try
      oQry.Close;
      oQry.SQL.Clear;
      oQry.SQL.Add(sSql);
      oQry.Open;
      while not(oQry.Eof) do
      begin
        Result.Add(oQry.Fields[num].AsString);    //第几个字段
        oQry.Next;
//        ShowBox(Result.text);
      end;
    except
      Result.Text := ''; // 默认返回空
    end;
  finally
    oQry.Free;
  end;
end;

function XmlToTstrings(XmlFile: string):TStrings;
var
  FXmlDoc, Fsave: IXMLDocument;
  RootNode, root: IXMLNode;
  I: Integer;
begin
  Result:=TStringList.Create;
  FXmlDoc := TXMLDocument.Create(nil);
  FXmlDoc.LoadFromFile(XmlFile);
  RootNode := FXmlDoc.DocumentElement;
  for I := 0 to RootNode.ChildNodes.Count - 1 do
  begin
    Fsave:= NewXMLDocument(); // 实例化创建
    Fsave.Encoding := 'utf-8';
    root := Fsave.AddChild('root');
    root.ChildNodes.Add(RootNode.ChildNodes[I]);
    Result.Add(Fsave.XML.Text);
//    Fsave.SaveToFile( 'c:/'+inttostr(I)+'asd.txt');
  end;
end;

function XmlStreamToTstrings(mStream: TStream):TStrings;
var
  FXmlDoc, Fsave: IXMLDocument;
  RootNode, root: IXMLNode;
  I: Integer;
begin
  Result:=TStringList.Create;
  try
    FXmlDoc := TXMLDocument.Create(nil);
    FXmlDoc.LoadFromStream(mStream);
    RootNode := FXmlDoc.DocumentElement;
    for I := 0 to RootNode.ChildNodes.Count - 1 do
    begin
      Fsave:= NewXMLDocument(); // 实例化创建
      Fsave.Encoding := 'utf-8';
      root := Fsave.AddChild('root');
      root.ChildNodes.Add(RootNode.ChildNodes[I]);
      Result.Add(Fsave.XML.Text);                                                 //    Fsave.SaveToFile( 'c:/'+inttostr(I)+'asd.txt');
    end;
  except
    Result.Text:='';
  end;
end;

function JsonToTstrings(sJson:string):TStrings;
var
  vJson,vItem: ISuperObject;
begin
  {$IFNDEF VER150}
  if sJson='[]' then Exit;
  Result:=TStringList.Create;
  //写数据
  vJson := SO('{"root":'+sJson+'}');
  for vItem in vJson['root'] do
  begin
//    ShowBox(vItem.AsString);
    Result.Add(vItem.AsString);
  end;
  {$ENDIF}
end;



exports
DOpenDB               {$IFDEF CDLE}NAME 'OxQCL000001'{$ENDIF},
DReadGrid             {$IFDEF CDLE}NAME 'OxQCL000002'{$ENDIF},
DReadoneKey           {$IFDEF CDLE}NAME 'OxQCL000003'{$ENDIF},
DReadoneRow           {$IFDEF CDLE}NAME 'OxQCL000004'{$ENDIF},
XmlToTstrings         {$IFDEF CDLE}NAME 'OxQCL000005'{$ENDIF},
XmlStreamToTstrings   {$IFDEF CDLE}NAME 'OxQCL000006'{$ENDIF},
JsonToTstrings        {$IFDEF CDLE}NAME 'OxQCL000007'{$ENDIF};


end.
